import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('travel_budget.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT,
        owner_id TEXT,
        synced_at TEXT,
        is_dirty INTEGER NOT NULL DEFAULT 1,
        name TEXT NOT NULL,
        budget REAL NOT NULL,
        base_currency TEXT NOT NULL,
        target_currency TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        cover_image_path TEXT,
        cover_image_url TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT,
        created_by TEXT,
        synced_at TEXT,
        is_dirty INTEGER NOT NULL DEFAULT 1,
        trip_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        converted_amount REAL,
        exchange_rate REAL,
        category TEXT NOT NULL,
        payment_method TEXT,
        note TEXT,
        receipt_image_path TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE rate_cache (
        base_currency TEXT NOT NULL,
        target_currency TEXT NOT NULL,
        rate REAL NOT NULL,
        fetched_at TEXT NOT NULL,
        PRIMARY KEY (base_currency, target_currency)
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add sync columns to trips
      await db.execute('ALTER TABLE trips ADD COLUMN uuid TEXT');
      await db.execute('ALTER TABLE trips ADD COLUMN owner_id TEXT');
      await db.execute('ALTER TABLE trips ADD COLUMN synced_at TEXT');
      await db.execute(
          'ALTER TABLE trips ADD COLUMN is_dirty INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE trips ADD COLUMN cover_image_url TEXT');

      // Add sync columns to expenses
      await db.execute('ALTER TABLE expenses ADD COLUMN uuid TEXT');
      await db.execute('ALTER TABLE expenses ADD COLUMN created_by TEXT');
      await db.execute('ALTER TABLE expenses ADD COLUMN synced_at TEXT');
      await db.execute(
          'ALTER TABLE expenses ADD COLUMN is_dirty INTEGER NOT NULL DEFAULT 1');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE expenses ADD COLUMN payment_method TEXT');
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
