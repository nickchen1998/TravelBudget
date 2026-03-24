import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/exchange_rate.dart';
import 'database_helper.dart';

class ExpenseDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertExpense(Expense expense) async {
    final db = await _dbHelper.database;
    final map = expense.toMap();
    map.remove('id');
    return await db.insert('expenses', map);
  }

  Future<List<Expense>> getExpensesByTripId(int tripId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalSpentByTrip(int tripId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(converted_amount) as total FROM expenses WHERE trip_id = ?',
      [tripId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Rate cache methods
  Future<ExchangeRate?> getCachedRate(String base, String target) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'rate_cache',
      where: 'base_currency = ? AND target_currency = ?',
      whereArgs: [base, target],
    );
    if (maps.isEmpty) return null;
    return ExchangeRate.fromMap(maps.first);
  }

  Future<void> upsertRate(ExchangeRate rate) async {
    final db = await _dbHelper.database;
    await db.insert(
      'rate_cache',
      rate.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
