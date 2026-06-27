import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';

/// Fetches all tables from Supabase and replaces local SQLite content.
/// Called once on app start; all UI reads come from local SQLite.
class SyncService {
  SyncService._();

  static SupabaseClient get _sb => Supabase.instance.client;

  // ── Column selectors ───────────────────────────────────────────────────────
  // We select only the columns that exist in our SQLite schema.
  // Supabase adds extra columns (created_at, etc.) that would cause
  // an insert error if included.

  static const _cuisinesCols    = 'id, name, flag, description, gradient_start, gradient_end, thumbnail_url';
  static const _categoriesCols  = 'id, name';
  static const _cuisineCatsCols = 'cuisine_id, category_id';
  static const _dishesCols      = 'id, cuisine_id, name, thumbnail_url, short_description';
  static const _dishDetailsCols = 'id, dish_id, full_description, ingredients, preparation, video_url_en, video_url_hi, video_url_ta, video_url_ml, video_url_ar, video_url_de, video_url_fr, video_url_es, video_url_it, video_url_zh';
  static const _dishCatsCols    = 'dish_id, category_id';

  // ── Public entry point ────────────────────────────────────────────────────

  static Future<void> sync() async {
    // 1. Fetch everything from Supabase before touching local DB.
    final cuisines    = await _fetch('cuisines',           _cuisinesCols);
    final categories  = await _fetch('categories',         _categoriesCols);
    final cuisineCats = await _fetch('cuisine_categories', _cuisineCatsCols);
    final dishes      = await _fetch('dishes',             _dishesCols);
    final dishDetails = await _fetchDishDetails();
    final dishCats    = await _fetch('dish_categories',    _dishCatsCols);

    // Nothing to do if Supabase returned empty — keep existing local data.
    if (cuisines.isEmpty && dishes.isEmpty) return;

    final db = await AppDatabase.database;

    // 2. Clear local tables in child → parent order (FK safety).
    await db.delete('dish_categories');
    await db.delete('cuisine_categories');
    await db.delete('dish_details');
    await db.delete('dishes');
    await db.delete('categories');
    await db.delete('cuisines');

    // 3. Insert remote data in parent → child order.
    await _batchInsert(db, 'cuisines',           cuisines);
    await _batchInsert(db, 'categories',          categories);
    await _batchInsert(db, 'cuisine_categories',  cuisineCats);
    await _batchInsert(db, 'dishes',              dishes);
    await _batchInsert(db, 'dish_details',        dishDetails);
    await _batchInsert(db, 'dish_categories',     dishCats);
  }

  // ── Supabase fetchers ─────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> _fetch(
      String table, String columns) async {
    final rows = await _sb.from(table).select(columns);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// dish_details.ingredients may arrive as a jsonb List from Supabase.
  /// SQLite stores it as a JSON text string — normalise here.
  static Future<List<Map<String, dynamic>>> _fetchDishDetails() async {
    final rows = await _sb.from('dish_details').select(_dishDetailsCols);
    return rows.map((row) {
      final copy = Map<String, dynamic>.from(row);
      final ingredients = copy['ingredients'];
      if (ingredients != null && ingredients is! String) {
        copy['ingredients'] = jsonEncode(ingredients);
      }
      return copy;
    }).toList();
  }

  // ── SQLite helpers ────────────────────────────────────────────────────────

  static Future<void> _batchInsert(
    Database db,
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
