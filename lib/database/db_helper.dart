import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';

/// Database helper managing SQLite connection, schema creation, and table access.
class DBHelper {
  static Database? _db;

  /// Retrieve active database instance or initialize if null.
  static Future<Database> getDatabase() async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await openDatabase(
      p.join(await getDatabasesPath(), AppConstants.dbName),
      version: AppConstants.dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      },
    );
    return _db!;
  }

  /// Create required tables if they do not exist.
  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.questionsTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_level INTEGER NOT NULL DEFAULT 6,
        subject TEXT NOT NULL DEFAULT 'Mathematics',
        topic TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT NOT NULL,
        option_d TEXT NOT NULL,
        correct_option TEXT NOT NULL,
        hint TEXT,
        explanation TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.progressTable}(
        topic TEXT PRIMARY KEY,
        correct INTEGER NOT NULL DEFAULT 0,
        total INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.answerLogsTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        is_correct INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.metadataTable}(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  /// Close current database instance (useful for unit tests and reseeding).
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
