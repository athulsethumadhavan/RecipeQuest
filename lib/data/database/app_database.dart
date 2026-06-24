import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_seeder.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'recipe_quest.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createTables(db);
        await DatabaseSeeder.seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE cuisines ADD COLUMN thumbnail_url TEXT NOT NULL DEFAULT ""');
        }
        if (oldVersion < 3) {
          await db.execute(
              "UPDATE cuisines SET gradient_start='4A90E2', gradient_end='2F74CC' WHERE id=1");
        }
        if (oldVersion < 4) {
          await db.execute(
              'ALTER TABLE cuisines ADD COLUMN categories TEXT NOT NULL DEFAULT ""');
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    // ── cuisines ────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE cuisines (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        flag            TEXT    NOT NULL,
        description     TEXT    NOT NULL,
        gradient_start  TEXT    NOT NULL,
        gradient_end    TEXT    NOT NULL,
        thumbnail_url   TEXT    NOT NULL DEFAULT "",
        categories      TEXT    NOT NULL DEFAULT ""
      )
    ''');

    // ── dishes ──────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE dishes (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        cuisine_id        INTEGER NOT NULL,
        name              TEXT    NOT NULL,
        thumbnail_url     TEXT    NOT NULL,
        category          TEXT    NOT NULL,
        short_description TEXT    NOT NULL,
        FOREIGN KEY (cuisine_id) REFERENCES cuisines(id)
      )
    ''');

    // ── dish_details ────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE dish_details (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        dish_id          INTEGER NOT NULL UNIQUE,
        full_description TEXT    NOT NULL,
        ingredients      TEXT    NOT NULL,
        preparation      TEXT    NOT NULL,
        video_url        TEXT,
        FOREIGN KEY (dish_id) REFERENCES dishes(id)
      )
    ''');
  }

  /// Drop and re-create the DB — useful during development.
  static Future<void> reset() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'recipe_quest.db');
    await deleteDatabase(path);
    _db = null;
  }
}
