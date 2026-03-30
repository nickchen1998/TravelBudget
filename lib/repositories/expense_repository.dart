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

  /// Fetch expenses for a trip. When online, fetches from Supabase and caches.
  Future<List<Expense>> getExpenses(int localTripId, {String? tripUuid}) async {
    if (!_isLoggedIn || tripUuid == null) {
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

      // Cache to SQLite
      for (final e in cloudExpenses) {
        await _local.upsertFromCloud(e);
      }
      // Remove stale local expenses
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

  Future<Expense> addExpense(Expense expense, {String? tripUuid}) async {
    if (!await _isOnline) throw const NetworkException();

    final userId = _userId!;
    final data = expense.toSupabaseMap(userId, tripUuid ?? '');
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

  Future<void> updateExpense(Expense expense, {String? tripUuid}) async {
    if (!await _isOnline) throw const NetworkException();
    if (expense.uuid == null) return;

    await _supabase
        .from('expenses')
        .update(expense.toSupabaseMap(_userId!, tripUuid ?? ''))
        .eq('id', expense.uuid!);

    if (expense.id != null) {
      await _local.updateExpense(expense);
    } else {
      await _local.upsertFromCloud(expense);
    }
  }

  Future<void> deleteExpense(int id, {String? expenseUuid}) async {
    if (!await _isOnline) throw const NetworkException();
    if (expenseUuid != null) {
      await _supabase.from('expenses').delete().eq('id', expenseUuid);
    }
    await _local.deleteExpense(id);
  }
}
