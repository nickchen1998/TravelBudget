import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/trip_dao.dart';
import '../db/expense_dao.dart';
import '../models/trip.dart';
import '../services/image_storage_service.dart';

class NetworkException implements Exception {
  const NetworkException();
}

class TripRepository {
  final TripDao _local = TripDao();
  final ExpenseDao _expenseDao = ExpenseDao();
  final _supabase = Supabase.instance.client;

  bool get _isLoggedIn => _supabase.auth.currentUser != null;
  String? get _userId => _supabase.auth.currentUser?.id;

  Future<bool> get _isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<Trip>> getAllTrips() async {
    // Local-only trips (uuid == null) are always returned from SQLite
    final allLocal = await _local.getAllTrips();
    final localOnly = allLocal.where((t) => t.uuid == null).toList();

    if (!_isLoggedIn) {
      // Not logged in: local trips only (no cloud trips to fetch)
      return localOnly;
    }

    final online = await _isOnline;
    if (!online) {
      // Offline: local trips + cached cloud trips
      return allLocal;
    }

    try {
      final memberRows = await _supabase
          .from('trip_members')
          .select('trip_id, role')
          .eq('user_id', _userId!);

      List<Trip> cloudTripsWithIds = [];

      if (memberRows.isNotEmpty) {
        final tripIds = memberRows.map((r) => r['trip_id'] as String).toList();

        final cloudRows = await _supabase
            .from('trips')
            .select()
            .inFilter('id', tripIds);

        final cloudTrips = cloudRows.map((t) {
          final role = memberRows
              .firstWhere((m) => m['trip_id'] == t['id'])['role'] as String;
          return Trip.fromSupabase(t, memberRole: role);
        }).toList();

        // Cache cloud trips to SQLite; collect with local id + memberRole
        for (final trip in cloudTrips) {
          final withLocalId = await _local.upsertFromCloud(trip);
          cloudTripsWithIds.add(withLocalId);
        }
        // Remove stale cached cloud trips
        await _local.deleteAbsent(tripIds);
      } else {
        await _local.deleteAbsent([]);
      }

      final combined = [...localOnly, ...cloudTripsWithIds];
      combined.sort((a, b) => b.startDate.compareTo(a.startDate));
      return combined;
    } catch (_) {
      return allLocal;
    }
  }

  Future<Trip?> getTripById(int id) => _local.getTripById(id);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates a new local trip in SQLite (no network required).
  Future<Trip> addTrip(Trip trip) async {
    final id = await _local.insertTrip(trip);
    return trip.copyWith(id: id);
  }

  /// Update a trip. Local trips (uuid == null) only touch SQLite.
  /// Cloud trips require network.
  Future<void> updateTrip(Trip trip) async {
    if (trip.uuid == null) {
      // Local trip — SQLite only
      await _local.updateTrip(trip);
      return;
    }

    if (!await _isOnline) throw const NetworkException();

    String? coverImageUrl = trip.coverImageUrl;
    if (trip.coverImagePath != null &&
        trip.coverImageUrl == null &&
        trip.uuid != null) {
      final uploaded = await ImageStorageService.uploadTripCover(
          trip.coverImagePath!, trip.uuid!);
      if (uploaded != null) coverImageUrl = uploaded;
    }

    final tripWithUrl =
        coverImageUrl != null ? trip.copyWith(coverImageUrl: coverImageUrl) : trip;

    await _supabase
        .from('trips')
        .update(tripWithUrl.toSupabaseMap(_userId!))
        .eq('id', trip.uuid!);

    if (trip.id != null) {
      await _local.updateTrip(tripWithUrl);
    } else {
      await _local.upsertFromCloud(tripWithUrl);
    }
  }

  /// Delete a trip. Local trips only touch SQLite. Cloud trips require network.
  Future<void> deleteTrip(int id) async {
    final trip = await _local.getTripById(id);
    if (trip?.uuid == null) {
      // Local trip — SQLite only
      await _local.deleteTrip(id);
      return;
    }
    if (!await _isOnline) throw const NetworkException();
    await _supabase.from('trips').delete().eq('id', trip!.uuid!);
    await _local.deleteTrip(id);
  }

  Future<void> deleteTripByUuid(String uuid) async {
    if (!await _isOnline) throw const NetworkException();
    await _supabase.from('trips').delete().eq('id', uuid);
    await _local.deleteTripByUuid(uuid);
  }

  Future<double> getTotalSpent(int tripId) =>
      _expenseDao.getTotalSpentByTrip(tripId);

  Future<void> clearCloudSyncFields() => _local.clearCloudSyncFields();

  Future<void> leaveTrip(String tripUuid) async {
    if (!await _isOnline) throw const NetworkException();
    final userId = _userId;
    if (userId == null) return;
    await _supabase
        .from('trip_members')
        .delete()
        .eq('trip_id', tripUuid)
        .eq('user_id', userId);
    await _local.deleteTripByUuid(tripUuid);
  }

  // ── Upload local trip to cloud ────────────────────────────────────────────

  /// Uploads a local trip (uuid == null) to Supabase.
  /// Updates the local SQLite record with the assigned uuid.
  /// Also uploads all expenses for this trip.
  Future<Trip> uploadLocalTripToCloud(Trip trip) async {
    if (!await _isOnline) throw const NetworkException();
    final userId = _userId!;

    // Insert trip to Supabase
    final data = trip.toSupabaseMap(userId);
    final result =
        await _supabase.from('trips').insert(data).select().single();
    final cloudId = result['id'] as String;

    await _supabase.from('trip_members').upsert({
      'trip_id': cloudId,
      'user_id': userId,
      'role': 'owner',
    });

    // Upload cover image if exists
    String? coverImageUrl;
    if (trip.coverImagePath != null) {
      coverImageUrl = await ImageStorageService.uploadTripCover(
          trip.coverImagePath!, cloudId);
      if (coverImageUrl != null) {
        await _supabase
            .from('trips')
            .update({'cover_image_url': coverImageUrl}).eq('id', cloudId);
      }
    }

    // Update local trip record with cloud uuid (promoted from local to cloud)
    final promoted = Trip(
      id: trip.id,
      uuid: cloudId,
      ownerId: userId,
      memberRole: 'owner',
      isDirty: false,
      syncedAt: DateTime.now().toIso8601String(),
      name: trip.name,
      budget: trip.budget,
      baseCurrency: trip.baseCurrency,
      targetCurrency: trip.targetCurrency,
      startDate: trip.startDate,
      endDate: trip.endDate,
      coverImagePath: trip.coverImagePath,
      coverImageUrl: coverImageUrl ?? trip.coverImageUrl,
      createdAt: trip.createdAt,
    );
    await _local.updateTrip(promoted);

    // Upload expenses
    if (trip.id != null) {
      await _uploadExpensesForTrip(trip.id!, cloudId, userId);
    }

    return promoted;
  }

  Future<void> _uploadExpensesForTrip(
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
}

void unawaited(Future<void> future) {
  future.catchError((_) {});
}
