import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/expense_dao.dart';
import '../models/expense.dart';
import 'trip_repository.dart' show NetworkException;

class ExpenseRepository {
  final ExpenseDao _local = ExpenseDao();
  final _supabase = Supabase.instance.client;

  bool get _isLoggedIn => _supabase.auth.currentUser != null;
  String? get _userId => _supabase.auth.currentUser?.id;

  Future<bool> get _isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetch expenses for a trip.
  /// Cloud trips (tripUuid != null, logged in, online): fetch from Supabase + cache.
  /// Local trips or offline: read from SQLite.
  Future<List<Expense>> getExpenses(int localTripId, {String? tripUuid}) async {
    final isCloud = tripUuid != null && _isLoggedIn;

    if (!isCloud) {
      return _local.getExpensesByTripId(localTripId);
    }

    final online = await _isOnline;
    if (!online) {
      return _local.getExpensesByTripId(localTripId);
    }

    try {
      final rows = await _supabase
          .from('expenses')
          .select()
          .eq('trip_id', tripUuid)
          .order('date', ascending: false);

      final cloudExpenses =
          rows.map((r) => Expense.fromSupabase(r, localTripId)).toList();

      for (final e in cloudExpenses) {
        await _local.upsertFromCloud(e);
      }
      final keepUuids =
          cloudExpenses.map((e) => e.uuid).whereType<String>().toList();
      await _local.deleteAbsentForTrip(localTripId, keepUuids);

      return _local.getExpensesByTripId(localTripId);
    } catch (_) {
      return _local.getExpensesByTripId(localTripId);
    }
  }

  Future<double> getTotalSpentByTrip(int tripId) =>
      _local.getTotalSpentByTrip(tripId);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Add expense. Local trips (tripUuid == null): SQLite only.
  /// Cloud trips require network.
  Future<Expense> addExpense(Expense expense, {String? tripUuid}) async {
    if (tripUuid == null) {
      // Local trip — SQLite only
      final id = await _local.insertExpense(expense);
      return expense.copyWith(id: id);
    }

    if (!await _isOnline) throw const NetworkException();

    final userId = _userId!;
    final data = expense.toSupabaseMap(userId, tripUuid);
    final result =
        await _supabase.from('expenses').insert(data).select().single();
    final cloudId = result['id'] as String;

    final cloudExpense = expense.copyWith(
      uuid: cloudId,
      createdBy: userId,
      tripUuid: tripUuid,
      isDirty: false,
      syncedAt: DateTime.now().toIso8601String(),
    );

    return _local.upsertFromCloud(cloudExpense);
  }

  /// Update expense. Local trips: SQLite only. Cloud trips require network.
  Future<void> updateExpense(Expense expense, {String? tripUuid}) async {
    if (tripUuid == null || expense.uuid == null) {
      // Local trip or not yet synced — SQLite only
      if (expense.id != null) await _local.updateExpense(expense);
      return;
    }

    if (!await _isOnline) throw const NetworkException();

    await _supabase
        .from('expenses')
        .update(expense.toSupabaseMap(_userId!, tripUuid))
        .eq('id', expense.uuid!);

    if (expense.id != null) {
      await _local.updateExpense(expense);
    } else {
      await _local.upsertFromCloud(expense);
    }
  }

  /// Delete expense. Local trips: SQLite only. Cloud trips require network.
  Future<void> deleteExpense(int id, {String? expenseUuid, String? tripUuid}) async {
    if (tripUuid == null || expenseUuid == null) {
      // Local trip — SQLite only
      await _local.deleteExpense(id);
      return;
    }

    if (!await _isOnline) throw const NetworkException();
    await _supabase.from('expenses').delete().eq('id', expenseUuid);
    await _local.deleteExpense(id);
  }
}
