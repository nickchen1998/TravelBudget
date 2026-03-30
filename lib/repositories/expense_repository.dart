import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/expense_dao.dart';
import '../models/expense.dart';
import 'trip_repository.dart' show unawaited;

class ExpenseRepository {
  final ExpenseDao _local = ExpenseDao();
  final _supabase = Supabase.instance.client;

  bool get _isLoggedIn => _supabase.auth.currentUser != null;
  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<Expense>> getExpensesByTripId(int tripId) =>
      _local.getExpensesByTripId(tripId);

  Future<double> getTotalSpentByTrip(int tripId) =>
      _local.getTotalSpentByTrip(tripId);

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Expense> addExpense(Expense expense, {String? tripUuid}) async {
    final id = await _local.insertExpense(expense);
    final saved = expense.copyWith(id: id, tripUuid: tripUuid);

    if (_isLoggedIn && tripUuid != null) {
      unawaited(_pushExpenseToCloud(saved, tripUuid));
    }

    return saved;
  }

  Future<void> updateExpense(Expense expense, {String? tripUuid}) async {
    await _local.updateExpense(expense);

    if (_isLoggedIn && expense.uuid != null && tripUuid != null) {
      unawaited(_updateExpenseOnCloud(expense, tripUuid));
    }
  }

  Future<void> deleteExpense(int id, {String? expenseUuid}) async {
    await _local.deleteExpense(id);

    if (_isLoggedIn && expenseUuid != null) {
      unawaited(_supabase.from('expenses').delete().eq('id', expenseUuid));
    }
  }

  // ── Cloud sync helpers ────────────────────────────────────────────────────

  Future<void> _pushExpenseToCloud(Expense expense, String tripUuid) async {
    try {
      final userId = _userId!;
      final data = expense.toSupabaseMap(userId, tripUuid);
      final result =
          await _supabase.from('expenses').insert(data).select().single();
      final cloudId = result['id'] as String;

      if (expense.id != null) {
        await _local.updateExpense(expense.copyWith(
          uuid: cloudId,
          createdBy: userId,
          isDirty: false,
          syncedAt: DateTime.now().toIso8601String(),
        ));
      }
    } catch (_) {}
  }

  Future<void> _updateExpenseOnCloud(Expense expense, String tripUuid) async {
    try {
      await _supabase
          .from('expenses')
          .update(expense.toSupabaseMap(_userId!, tripUuid))
          .eq('id', expense.uuid!);
    } catch (_) {}
  }

  /// Pull expenses for a shared trip from Supabase (no local record)
  Future<List<Expense>> getCloudExpensesForTrip(
      String tripUuid, int localTripId) async {
    try {
      final rows = await _supabase
          .from('expenses')
          .select()
          .eq('trip_id', tripUuid)
          .order('date', ascending: false);
      return rows
          .map((r) => Expense.fromSupabase(r, localTripId))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
