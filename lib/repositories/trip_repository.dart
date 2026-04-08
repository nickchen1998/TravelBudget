import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/trip_dao.dart';
import '../db/expense_dao.dart';
import '../models/trip.dart';
import '../services/image_storage_service.dart';

class NetworkException implements Exception {
  const NetworkException();
}

bool _isNetworkError(Object e) =>
    e is SocketException || e is TimeoutException;

class TripLimitException implements Exception {
  const TripLimitException();
}

class HasMembersException implements Exception {
  const HasMembersException();
}

class TripRepository {
  final TripDao _local = TripDao();
  final ExpenseDao _expenseDao = ExpenseDao();
  final _supabase = Supabase.instance.client;

  bool get _isLoggedIn => _supabase.auth.currentUser != null;
  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<Trip>> getAllTrips() async {
    // Local-only trips (uuid == null) are always returned from SQLite
    final allLocal = await _local.getAllTrips();
    final localOnly = allLocal.where((t) => t.uuid == null).toList();

    if (!_isLoggedIn) {
      // Not logged in: local trips only (no cloud trips to fetch)
      return localOnly;
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
      // Cloud fetch failed — return ALL local trips (including cached cloud
      // trips) so that previously-synced trips remain visible while offline.
      allLocal.sort((a, b) => b.startDate.compareTo(a.startDate));
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

    final updateMap = tripWithUrl.toSupabaseMap(_userId!);
    updateMap.remove('id');       // don't overwrite PK
    updateMap.remove('owner_id'); // collaborators must not change owner

    // 3.1 修復：若上傳失敗導致 coverImageUrl 為 null，不覆寫雲端已有的封面 URL
    if (updateMap['cover_image_url'] == null && trip.coverImagePath != null) {
      updateMap.remove('cover_image_url');
    }

    try {
      await _supabase
          .from('trips')
          .update(updateMap)
          .eq('id', trip.uuid!);
    } catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      rethrow;
    }

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
    try {
      await _supabase.from('trips').delete().eq('id', trip!.uuid!);
    } catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      rethrow;
    }
    await _local.deleteTrip(id);
  }

  Future<void> deleteTripByUuid(String uuid) async {
    try {
      await _supabase.from('trips').delete().eq('id', uuid);
    } catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      rethrow;
    }
    await _local.deleteTripByUuid(uuid);
  }

  Future<double> getTotalSpent(int tripId) =>
      _expenseDao.getTotalSpentByTrip(tripId);

  Future<void> clearCloudSyncFields() => _local.clearCloudSyncFields();

  Future<void> leaveTrip(String tripUuid) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _supabase
          .from('trip_members')
          .delete()
          .eq('trip_id', tripUuid)
          .eq('user_id', userId);
    } catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      rethrow;
    }
    await _local.deleteTripByUuid(tripUuid);
  }

  // ── Upload local trip to cloud ────────────────────────────────────────────

  /// Uploads a local trip (uuid == null) to Supabase.
  /// Updates the local SQLite record with the assigned uuid.
  /// Also uploads all expenses for this trip.
  Future<Trip> uploadLocalTripToCloud(Trip trip) async {
    final userId = _userId!;

    // Insert trip to Supabase
    final data = trip.toSupabaseMap(userId);
    final Map<String, dynamic> result;
    try {
      result = await _supabase.from('trips').insert(data).select().single();
    } on PostgrestException catch (e) {
      if (e.details?.toString().contains('TRIP_LIMIT_EXCEEDED') == true) {
        throw const TripLimitException();
      }
      rethrow;
    } catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      rethrow;
    }
    final cloudId = result['id'] as String;

    // Insert trip_members — if this fails, delete the orphaned trip to avoid
    // accumulating ghost records that count toward the trip limit.
    try {
      await _supabase.from('trip_members').upsert({
        'trip_id': cloudId,
        'user_id': userId,
        'role': 'owner',
      });
    } catch (e) {
      // Rollback: remove the trip we just inserted
      try {
        await _supabase.from('trips').delete().eq('id', cloudId);
      } catch (_) {}
      if (_isNetworkError(e)) throw const NetworkException();
      rethrow;
    }

    // Upload cover image if exists (non-critical — don't rollback on failure)
    String? coverImageUrl;
    if (trip.coverImagePath != null) {
      try {
        coverImageUrl = await ImageStorageService.uploadTripCover(
            trip.coverImagePath!, cloudId);
        if (coverImageUrl != null) {
          await _supabase
              .from('trips')
              .update({'cover_image_url': coverImageUrl}).eq('id', cloudId);
        }
      } catch (_) {
        // Cover image upload is non-critical; continue with the upload
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
      splitEnabled: trip.splitEnabled,
      createdAt: trip.createdAt,
    );
    await _local.updateTrip(promoted);

    // Upload expenses
    if (trip.id != null) {
      await _uploadExpensesForTrip(trip.id!, cloudId, userId);
    }

    return promoted;
  }

  // ── Download cloud trip to local ──────────────────────────────────────────

  /// Converts a cloud trip back to local-only.
  /// Deletes all cloud data (trip, expenses, members, invitations, splits, settlements)
  /// and clears sync fields in local SQLite.
  /// Throws [HasMembersException] if the trip has other collaborators.
  Future<void> downloadCloudTripToLocal(Trip trip) async {
    final uuid = trip.uuid;
    final localId = trip.id;
    if (uuid == null || localId == null) return;

    // 0. Check member count — block if others are in the trip
    try {
      final members = await _supabase
          .from('trip_members')
          .select('user_id')
          .eq('trip_id', uuid);
      if (members.length > 1) throw const HasMembersException();
    } catch (e) {
      if (e is HasMembersException) rethrow;
      if (_isNetworkError(e)) throw const NetworkException();
      rethrow;
    }

    // 1. Delete cloud data (order matters for FK constraints)
    try {
      await _supabase.from('settlements').delete().eq('trip_id', uuid);
      await _supabase.from('expense_splits').delete().inFilter(
        'expense_id',
        (await _supabase.from('expenses').select('id').eq('trip_id', uuid))
            .map((e) => e['id'] as String)
            .toList(),
      );
      await _supabase.from('expenses').delete().eq('trip_id', uuid);
      await _supabase.from('trip_invitations').delete().eq('trip_id', uuid);
      await _supabase.from('trip_members').delete().eq('trip_id', uuid);
      await _supabase.from('trips').delete().eq('id', uuid);
    } catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      rethrow;
    }

    // 2. Demote local trip record
    await _local.demoteToLocal(localId);

    // 3. Clear sync fields on local expenses
    await _expenseDao.clearCloudSyncFieldsForTrip(localId);
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
