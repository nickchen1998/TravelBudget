import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/trip_dao.dart';
import '../db/expense_dao.dart';
import '../models/trip.dart';

class TripRepository {
  final TripDao _local = TripDao();
  final ExpenseDao _expenseDao = ExpenseDao();
  final _supabase = Supabase.instance.client;

  bool get _isLoggedIn => _supabase.auth.currentUser != null;
  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<Trip>> getAllTrips() async {
    final localTrips = await _local.getAllTrips();

    if (!_isLoggedIn) return localTrips;

    // Merge cloud shared trips (trips where user is a member but not owner)
    try {
      final memberRows = await _supabase
          .from('trip_members')
          .select('trip_id, role')
          .eq('user_id', _userId!);

      if (memberRows.isEmpty) return localTrips;

      final sharedTripIds =
          memberRows.map((r) => r['trip_id'] as String).toList();

      final cloudTrips = await _supabase
          .from('trips')
          .select()
          .inFilter('id', sharedTripIds);

      final sharedTrips = cloudTrips.map((t) {
        final role = memberRows
            .firstWhere((m) => m['trip_id'] == t['id'])['role'] as String;
        return Trip.fromSupabase(t, memberRole: role);
      }).toList();

      // Filter out shared trips already in local (by uuid)
      final localUuids = localTrips.map((t) => t.uuid).whereType<String>().toSet();
      final newShared =
          sharedTrips.where((t) => !localUuids.contains(t.uuid)).toList();

      return [...localTrips, ...newShared];
    } catch (_) {
      return localTrips;
    }
  }

  Future<Trip?> getTripById(int id) => _local.getTripById(id);

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Trip> addTrip(Trip trip) async {
    final id = await _local.insertTrip(trip);
    final saved = trip.copyWith(id: id);

    if (_isLoggedIn) {
      unawaited(_pushTripToCloud(saved));
    }

    return saved;
  }

  Future<void> updateTrip(Trip trip) async {
    await _local.updateTrip(trip);

    if (_isLoggedIn && trip.uuid != null) {
      unawaited(_updateTripOnCloud(trip));
    }
  }

  Future<void> deleteTrip(int id) async {
    final trip = await _local.getTripById(id);
    await _local.deleteTrip(id);

    if (_isLoggedIn && trip?.uuid != null) {
      unawaited(_supabase.from('trips').delete().eq('id', trip!.uuid!));
    }
  }

  Future<double> getTotalSpent(int tripId) =>
      _expenseDao.getTotalSpentByTrip(tripId);

  /// Clears cloud-sync fields for all locally-stored trips after account deletion.
  Future<void> clearCloudSyncFields() => _local.clearCloudSyncFields();

  // ── Cloud sync helpers ────────────────────────────────────────────────────

  Future<void> _pushTripToCloud(Trip trip) async {
    try {
      final userId = _userId!;
      final data = trip.toSupabaseMap(userId);
      final result =
          await _supabase.from('trips').insert(data).select().single();
      final cloudId = result['id'] as String;

      // Also add as owner in trip_members
      await _supabase.from('trip_members').upsert({
        'trip_id': cloudId,
        'user_id': userId,
        'role': 'owner',
      });

      // Update local uuid
      if (trip.id != null) {
        await _local.updateTrip(trip.copyWith(
          uuid: cloudId,
          ownerId: userId,
          isDirty: false,
          syncedAt: DateTime.now().toIso8601String(),
        ));
      }
    } catch (_) {
      // Will retry on next sync
    }
  }

  Future<void> _updateTripOnCloud(Trip trip) async {
    try {
      await _supabase
          .from('trips')
          .update(trip.toSupabaseMap(_userId!))
          .eq('id', trip.uuid!);
    } catch (_) {}
  }
}

void unawaited(Future<void> future) {
  future.catchError((_) {});
}
