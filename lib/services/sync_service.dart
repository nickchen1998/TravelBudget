import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/trip_dao.dart';
import '../db/expense_dao.dart';
import '../models/expense.dart';

/// Handles first-login migration and background sync of dirty records.
class SyncService {
  final _supabase = Supabase.instance.client;
  final _tripDao = TripDao();
  final _expenseDao = ExpenseDao();

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Called once when user signs in.
  /// Pushes all local trips/expenses that haven't been synced yet.
  Future<void> syncOnLogin() async {
    final userId = _userId;
    if (userId == null) return;

    final trips = await _tripDao.getAllTrips();
    for (final trip in trips) {
      if (trip.uuid != null) continue; // already synced before

      try {
        final data = trip.toSupabaseMap(userId);
        final result =
            await _supabase.from('trips').insert(data).select().single();
        final cloudId = result['id'] as String;

        // Mark owner in trip_members
        await _supabase.from('trip_members').upsert({
          'trip_id': cloudId,
          'user_id': userId,
          'role': 'owner',
        });

        // Update local with uuid
        final updatedTrip = trip.copyWith(
          uuid: cloudId,
          ownerId: userId,
          isDirty: false,
          syncedAt: DateTime.now().toIso8601String(),
        );
        await _tripDao.updateTrip(updatedTrip);

        // Sync expenses for this trip
        if (trip.id != null) {
          await _syncExpensesForTrip(trip.id!, cloudId, userId);
        }
      } catch (_) {
        // Skip failed trips, will retry next login
      }
    }
  }

  Future<void> _syncExpensesForTrip(
      int localTripId, String cloudTripId, String userId) async {
    final expenses = await _expenseDao.getExpensesByTripId(localTripId);
    for (final expense in expenses) {
      if (expense.uuid != null) continue;

      try {
        final data = expense.toSupabaseMap(userId, cloudTripId);
        final result =
            await _supabase.from('expenses').insert(data).select().single();
        final cloudId = result['id'] as String;

        await _expenseDao.updateExpense(expense.copyWith(
          uuid: cloudId,
          createdBy: userId,
          isDirty: false,
          syncedAt: DateTime.now().toIso8601String(),
        ));
      } catch (_) {}
    }
  }

  /// Retry any locally dirty records (is_dirty = 1) that have a uuid
  /// (meaning they were previously synced but a later edit failed to push).
  Future<void> retryDirtyRecords() async {
    final userId = _userId;
    if (userId == null) return;

    // Dirty trips with uuid (update on cloud)
    final trips = await _tripDao.getAllTrips();
    for (final trip in trips) {
      if (!trip.isDirty || trip.uuid == null) continue;
      try {
        await _supabase
            .from('trips')
            .update(trip.toSupabaseMap(userId))
            .eq('id', trip.uuid!);
        await _tripDao.updateTrip(trip.copyWith(
          isDirty: false,
          syncedAt: DateTime.now().toIso8601String(),
        ));
      } catch (_) {}
    }
  }

  /// Pull remote expenses for a shared trip and upsert to local SQLite.
  Future<List<Expense>> fetchSharedTripExpenses(
      String tripUuid, int localTripId) async {
    try {
      final rows = await _supabase
          .from('expenses')
          .select()
          .eq('trip_id', tripUuid)
          .order('date', ascending: false);
      return rows.map((r) => Expense.fromSupabase(r, localTripId)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Subscribe to real-time updates for a shared trip.
  RealtimeChannel subscribeToTrip(
      String tripUuid, void Function() onUpdate) {
    return _supabase
        .channel('trip:$tripUuid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripUuid,
          ),
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }
}
