import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a single split entry for an expense
class SplitEntry {
  final String? id;
  final String expenseId;
  final String userId;
  final double amount;

  SplitEntry({
    this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
  });

  factory SplitEntry.fromMap(Map<String, dynamic> map) {
    return SplitEntry(
      id: map['id'] as String?,
      expenseId: map['expense_id'] as String,
      userId: map['user_id'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}

/// Represents a settlement: who owes whom
class Settlement {
  final String? id;
  final String tripId;
  final String fromUser;
  final String toUser;
  final double amount;
  final String currency;
  final bool isSettled;
  final DateTime? settledAt;

  Settlement({
    this.id,
    required this.tripId,
    required this.fromUser,
    required this.toUser,
    required this.amount,
    required this.currency,
    this.isSettled = false,
    this.settledAt,
  });

  factory Settlement.fromMap(Map<String, dynamic> map) {
    return Settlement(
      id: map['id'] as String?,
      tripId: map['trip_id'] as String,
      fromUser: map['from_user'] as String,
      toUser: map['to_user'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      isSettled: map['is_settled'] as bool? ?? false,
      settledAt: map['settled_at'] != null
          ? DateTime.parse(map['settled_at'] as String)
          : null,
    );
  }
}

/// A computed debt: fromUser owes toUser some amount
class Debt {
  final String fromUser;
  final String toUser;
  final double amount;

  Debt({
    required this.fromUser,
    required this.toUser,
    required this.amount,
  });
}

class SplitService {
  final _supabase = Supabase.instance.client;

  // ── Expense Splits CRUD ──────────────────────────────────────────────────

  /// Save splits for an expense (replaces all existing splits)
  Future<void> saveSplits(
      String expenseId, List<SplitEntry> splits) async {
    // Delete existing splits
    await _supabase
        .from('expense_splits')
        .delete()
        .eq('expense_id', expenseId);

    // Insert new splits
    if (splits.isNotEmpty) {
      await _supabase.from('expense_splits').insert(
            splits
                .map((s) => {
                      'expense_id': expenseId,
                      'user_id': s.userId,
                      'amount': s.amount,
                    })
                .toList(),
          );
    }
  }

  /// Get splits for a single expense
  Future<List<SplitEntry>> getSplitsForExpense(String expenseId) async {
    final data = await _supabase
        .from('expense_splits')
        .select()
        .eq('expense_id', expenseId);
    return (data as List).map((e) => SplitEntry.fromMap(e)).toList();
  }

  /// Get all splits for all expenses in a trip
  Future<Map<String, List<SplitEntry>>> getAllSplitsForTrip(
      String tripId) async {
    final data = await _supabase
        .from('expense_splits')
        .select('*, expenses!inner(trip_id)')
        .eq('expenses.trip_id', tripId);

    final map = <String, List<SplitEntry>>{};
    for (final row in data as List) {
      final entry = SplitEntry.fromMap(row);
      map.putIfAbsent(entry.expenseId, () => []).add(entry);
    }
    return map;
  }

  // ── Settlement Calculation ───────────────────────────────────────────────

  /// Calculate debts using greedy algorithm (minimum transfers)
  /// Returns list of "A owes B $X" entries
  List<Debt> calculateDebts(
    List<Map<String, dynamic>> expenses,
    Map<String, List<SplitEntry>> allSplits,
  ) {
    // Step 1: Calculate net balance for each person
    // Positive = overpaid (is owed money), Negative = underpaid (owes money)
    final balances = <String, double>{};

    for (final expense in expenses) {
      final expenseId = expense['uuid'] as String?;
      final paidBy = expense['paid_by'] as String?;
      final convertedAmount = expense['converted_amount'] as double?;

      if (expenseId == null || paidBy == null || convertedAmount == null) {
        continue;
      }

      final splits = allSplits[expenseId];
      if (splits == null || splits.isEmpty) continue;

      // The payer paid the full amount
      balances[paidBy] = (balances[paidBy] ?? 0) + convertedAmount;

      // Each participant owes their split amount
      for (final split in splits) {
        balances[split.userId] =
            (balances[split.userId] ?? 0) - split.amount;
      }
    }

    // Step 2: Separate into creditors (+) and debtors (-)
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    for (final entry in balances.entries) {
      if (entry.value > 0.01) {
        creditors.add(entry);
      } else if (entry.value < -0.01) {
        debtors.add(MapEntry(entry.key, -entry.value)); // Make positive
      }
    }

    // Sort: largest first for greedy matching
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    // Step 3: Greedy matching
    final debts = <Debt>[];
    var ci = 0, di = 0;
    final cAmounts = creditors.map((e) => e.value).toList();
    final dAmounts = debtors.map((e) => e.value).toList();

    while (ci < creditors.length && di < debtors.length) {
      final transfer =
          cAmounts[ci] < dAmounts[di] ? cAmounts[ci] : dAmounts[di];

      if (transfer > 0.01) {
        debts.add(Debt(
          fromUser: debtors[di].key,
          toUser: creditors[ci].key,
          amount: double.parse(transfer.toStringAsFixed(2)),
        ));
      }

      cAmounts[ci] -= transfer;
      dAmounts[di] -= transfer;

      if (cAmounts[ci] < 0.01) ci++;
      if (dAmounts[di] < 0.01) di++;
    }

    return debts;
  }

  // ── Settlement Records ───────────────────────────────────────────────────

  /// Get settlements for a trip
  Future<List<Settlement>> getSettlements(String tripId) async {
    final data = await _supabase
        .from('settlements')
        .select()
        .eq('trip_id', tripId)
        .order('created_at');
    return (data as List).map((e) => Settlement.fromMap(e)).toList();
  }

  /// Mark a debt as settled
  Future<void> markSettled(String tripId, String fromUser, String toUser,
      double amount, String currency) async {
    // Check if settlement record exists
    final existing = await _supabase
        .from('settlements')
        .select()
        .eq('trip_id', tripId)
        .eq('from_user', fromUser)
        .eq('to_user', toUser)
        .maybeSingle();

    if (existing != null) {
      await _supabase.from('settlements').update({
        'is_settled': true,
        'settled_at': DateTime.now().toIso8601String(),
        'amount': amount,
      }).eq('id', existing['id']);
    } else {
      await _supabase.from('settlements').insert({
        'trip_id': tripId,
        'from_user': fromUser,
        'to_user': toUser,
        'amount': amount,
        'currency': currency,
        'is_settled': true,
        'settled_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Unmark a settlement
  Future<void> unmarkSettled(String settlementId) async {
    await _supabase.from('settlements').update({
      'is_settled': false,
      'settled_at': null,
    }).eq('id', settlementId);
  }

  // ── Trip Members Helper ──────────────────────────────────────────────────

  /// Get trip members with display names
  Future<List<Map<String, dynamic>>> getTripMembers(String tripId) async {
    final data = await _supabase
        .from('trip_members')
        .select('user_id, role, profiles!trip_members_user_id_fkey(display_name)')
        .eq('trip_id', tripId);
    return List<Map<String, dynamic>>.from(data as List);
  }
}
