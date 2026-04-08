import '../models/trip.dart';
import 'database_helper.dart';

class TripDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertTrip(Trip trip) async {
    final db = await _dbHelper.database;
    final map = trip.toMap();
    map.remove('id');
    return await db.insert('trips', map);
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await _dbHelper.database;
    final maps = await db.query('trips', orderBy: 'start_date DESC');
    return maps.map((map) => Trip.fromMap(map)).toList();
  }

  Future<Trip?> getTripById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Trip.fromMap(maps.first);
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await _dbHelper.database;
    return await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<int> deleteTrip(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTripByUuid(String uuid) async {
    final db = await _dbHelper.database;
    await db.delete('trips', where: 'uuid = ?', whereArgs: [uuid]);
  }

  /// Demote a cloud trip to local-only: clear sync fields, mark as local-only.
  Future<void> demoteToLocal(int id) async {
    final db = await _dbHelper.database;
    await db.update('trips', {
      'uuid': null,
      'owner_id': null,
      'synced_at': null,
      'is_dirty': 0,
      'split_enabled': 0,
      'is_local_only': 1,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCloudSyncFields() async {
    final db = await _dbHelper.database;
    await db.update('trips', {
      'uuid': null,
      'owner_id': null,
      'synced_at': null,
      'is_dirty': 1,
    });
  }

  /// Upsert a trip from cloud data (match by uuid). Returns the trip with local id set.
  Future<Trip> upsertFromCloud(Trip trip) async {
    final db = await _dbHelper.database;
    final existing = await db.query('trips', where: 'uuid = ?', whereArgs: [trip.uuid]);
    if (existing.isNotEmpty) {
      final localId = existing.first['id'] as int;
      // 保留本地的 coverImagePath（雲端不帶此欄位）
      final localPath = existing.first['cover_image_path'] as String?;
      final updated = trip.copyWith(
        id: localId,
        coverImagePath: trip.coverImagePath ?? localPath,
      );
      await db.update('trips', updated.toMap(), where: 'id = ?', whereArgs: [localId]);
      return updated;
    } else {
      final map = trip.toMap();
      map.remove('id');
      final localId = await db.insert('trips', map);
      return trip.copyWith(id: localId);
    }
  }

  /// Remove locally-cached trips whose uuids are not in [keepUuids].
  Future<void> deleteAbsent(List<String> keepUuids) async {
    final db = await _dbHelper.database;
    // Only delete cached cloud trips (uuid IS NOT NULL) that are no longer in the cloud list.
    // Never delete local-only trips (uuid IS NULL).
    if (keepUuids.isEmpty) {
      await db.delete('trips', where: 'uuid IS NOT NULL');
      return;
    }
    final placeholders = List.filled(keepUuids.length, '?').join(',');
    await db.delete(
      'trips',
      where: 'uuid IS NOT NULL AND uuid NOT IN ($placeholders)',
      whereArgs: keepUuids,
    );
  }
}
