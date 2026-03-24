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
}
