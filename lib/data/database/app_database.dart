import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 7,
      onCreate: (db, version) async {
        // Fresh install: create schema, leave all tables empty.
        // SyncService.sync() in main.dart will populate from Supabase.
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // ── v5 schema changes (needed when upgrading from v4 or lower) ──
        if (oldVersion < 5) {
          // Add thumbnail_url to cuisines if missing (was added in v2).
          try {
            await db.execute(
                'ALTER TABLE cuisines ADD COLUMN thumbnail_url TEXT NOT NULL DEFAULT ""');
          } catch (_) {}

          // Recreate dishes without the old `category TEXT NOT NULL` column.
          try {
            await db.execute('ALTER TABLE dishes RENAME TO dishes_old');
            await db.execute('''
              CREATE TABLE dishes (
                id                INTEGER PRIMARY KEY AUTOINCREMENT,
                cuisine_id        INTEGER NOT NULL,
                name              TEXT    NOT NULL,
                thumbnail_url     TEXT    NOT NULL,
                short_description TEXT    NOT NULL,
                FOREIGN KEY (cuisine_id) REFERENCES cuisines(id)
              )
            ''');
            await db.execute('''
              INSERT INTO dishes (id, cuisine_id, name, thumbnail_url, short_description)
              SELECT id, cuisine_id, name, thumbnail_url, short_description
              FROM dishes_old
            ''');
            await db.execute('DROP TABLE dishes_old');
          } catch (_) {}

          // Add the three normalised category tables.
          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories (
              id   INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT    NOT NULL UNIQUE
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cuisine_categories (
              cuisine_id  INTEGER NOT NULL,
              category_id INTEGER NOT NULL,
              PRIMARY KEY (cuisine_id, category_id),
              FOREIGN KEY (cuisine_id)  REFERENCES cuisines(id),
              FOREIGN KEY (category_id) REFERENCES categories(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS dish_categories (
              dish_id     INTEGER NOT NULL,
              category_id INTEGER NOT NULL,
              PRIMARY KEY (dish_id, category_id),
              FOREIGN KEY (dish_id)     REFERENCES dishes(id),
              FOREIGN KEY (category_id) REFERENCES categories(id)
            )
          ''');
        }

        // ── v6: clear all hardcoded seed data ──────────────────────────────
        if (oldVersion < 6) {
          await db.delete('dish_categories');
          await db.delete('cuisine_categories');
          await db.delete('dish_details');
          await db.delete('dishes');
          await db.delete('categories');
          await db.delete('cuisines');
        }

        // ── v7: replace video_url with 9 language-specific columns ─────────
        if (oldVersion < 7) {
          for (final col in [
            'video_url_en', 'video_url_hi', 'video_url_ta', 'video_url_ml',
            'video_url_ar', 'video_url_de', 'video_url_fr', 'video_url_es',
            'video_url_it', 'video_url_zh',
          ]) {
            try {
              await db.execute(
                  'ALTER TABLE dish_details ADD COLUMN $col TEXT');
            } catch (_) {}
          }
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE cuisines (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        flag            TEXT    NOT NULL,
        description     TEXT    NOT NULL,
        gradient_start  TEXT    NOT NULL,
        gradient_end    TEXT    NOT NULL,
        thumbnail_url   TEXT    NOT NULL DEFAULT ""
      )
    ''');

    await db.execute('''
      CREATE TABLE dishes (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        cuisine_id        INTEGER NOT NULL,
        name              TEXT    NOT NULL,
        thumbnail_url     TEXT    NOT NULL,
        short_description TEXT    NOT NULL,
        FOREIGN KEY (cuisine_id) REFERENCES cuisines(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE dish_details (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        dish_id          INTEGER NOT NULL UNIQUE,
        full_description TEXT    NOT NULL,
        ingredients      TEXT    NOT NULL,
        preparation      TEXT    NOT NULL,
        video_url_en     TEXT,
        video_url_hi     TEXT,
        video_url_ta     TEXT,
        video_url_ml     TEXT,
        video_url_ar     TEXT,
        video_url_de     TEXT,
        video_url_fr     TEXT,
        video_url_es     TEXT,
        video_url_it     TEXT,
        video_url_zh     TEXT,
        FOREIGN KEY (dish_id) REFERENCES dishes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT    NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE cuisine_categories (
        cuisine_id  INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        PRIMARY KEY (cuisine_id, category_id),
        FOREIGN KEY (cuisine_id)  REFERENCES cuisines(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE dish_categories (
        dish_id     INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        PRIMARY KEY (dish_id, category_id),
        FOREIGN KEY (dish_id)     REFERENCES dishes(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');
  }

  /// Drop and re-create — use from the admin screen during development.
  static Future<void> reset() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'recipe_quest.db');
    await deleteDatabase(path);
    _db = null;
  }
}
