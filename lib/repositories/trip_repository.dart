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
    if (!_isLoggedIn) return _local.getAllTrips();

    final online = await _isOnline;
    if (!online) {
      return _local.getAllTrips();
    }

    try {
      final memberRows = await _supabase
          .from('trip_members')
          .select('trip_id, role')
          .eq('user_id', _userId!);

      if (memberRows.isEmpty) {
        await _local.deleteAbsent([]);
        return [];
      }

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

      // Cache cloud trips to SQLite
      for (final trip in cloudTrips) {
        await _local.upsertFromCloud(trip);
      }
      // Remove trips that no longer exist on cloud
      await _local.deleteAbsent(tripIds);

      // Return from cache so every trip has a local integer id
      final cached = await _local.getAllTrips();

      // Compute spending totals
      return cached;
    } catch (_) {
      return _local.getAllTrips();
    }
  }

  Future<Trip?> getTripById(int id) => _local.getTripById(id);

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Trip> addTrip(Trip trip) async {
    if (!await _isOnline) throw const NetworkException();

    final userId = _userId!;
    final data = trip.toSupabaseMap(userId);
    final result =
        await _supabase.from('trips').insert(data).select().single();
    final cloudId = result['id'] as String;

    await _supabase.from('trip_members').upsert({
      'trip_id': cloudId,
      'user_id': userId,
      'role': 'owner',
    });

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

    final cloudTrip = Trip(
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
      coverImageUrl: coverImageUrl,
      createdAt: trip.createdAt,
    );

    return _local.upsertFromCloud(cloudTrip);
  }

  Future<void> updateTrip(Trip trip) async {
    if (!await _isOnline) throw const NetworkException();
    if (trip.uuid == null) return;

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

    // Update local cache
    if (trip.id != null) {
      await _local.updateTrip(tripWithUrl);
    } else {
      await _local.upsertFromCloud(tripWithUrl);
    }
  }

  Future<void> deleteTrip(int id) async {
    if (!await _isOnline) throw const NetworkException();
    final trip = await _local.getTripById(id);
    if (trip?.uuid != null) {
      await _supabase.from('trips').delete().eq('id', trip!.uuid!);
    }
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
}

void unawaited(Future<void> future) {
  future.catchError((_) {});
}
