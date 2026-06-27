import '../database/app_database.dart';
import '../models/cuisine_model.dart';
import '../models/dish_model.dart';
import '../models/dish_detail_model.dart';

/// SQL fragment that returns all category names for a dish as a
/// comma-separated string in the `categories_raw` column.
const _categoriesSubquery = '''
  (SELECT GROUP_CONCAT(cat.name, ',')
   FROM dish_categories dc
   JOIN categories cat ON cat.id = dc.category_id
   WHERE dc.dish_id = d.id)  AS categories_raw
''';

class CuisineRepository {
  // ── Cuisines ──────────────────────────────────────────────────────────────

  Future<List<Cuisine>> getCuisines() async {
    final db = await AppDatabase.database;
    final rows = await db.query('cuisines', orderBy: 'id ASC');
    return rows.map(Cuisine.fromMap).toList();
  }

  // ── Categories ────────────────────────────────────────────────────────────

  /// Returns the names of all categories linked to [cuisineId] in
  /// the cuisine_categories junction table, ordered alphabetically.
  Future<List<String>> getCategoriesForCuisine(int cuisineId) async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT cat.name
      FROM categories cat
      JOIN cuisine_categories cc ON cc.category_id = cat.id
      WHERE cc.cuisine_id = ?
      ORDER BY cat.name ASC
    ''', [cuisineId]);
    return rows.map((r) => r['name'] as String).toList();
  }

  // ── Dishes ────────────────────────────────────────────────────────────────

  Future<List<Dish>> getDishesByCuisine(int cuisineId) async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT d.id, d.cuisine_id, d.name, d.thumbnail_url, d.short_description,
             c.name AS cuisine_name,
             $_categoriesSubquery
      FROM dishes d
      JOIN cuisines c ON c.id = d.cuisine_id
      WHERE d.cuisine_id = ?
      ORDER BY d.id ASC
    ''', [cuisineId]);
    return rows.map(Dish.fromMap).toList();
  }

  Future<List<Dish>> getAllDishes() async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT d.id, d.cuisine_id, d.name, d.thumbnail_url, d.short_description,
             c.name AS cuisine_name,
             $_categoriesSubquery
      FROM dishes d
      JOIN cuisines c ON c.id = d.cuisine_id
      ORDER BY d.id ASC
    ''');
    return rows.map(Dish.fromMap).toList();
  }

  Future<Dish> getRandomDish() async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT d.id, d.cuisine_id, d.name, d.thumbnail_url, d.short_description,
             c.name AS cuisine_name,
             $_categoriesSubquery
      FROM dishes d
      JOIN cuisines c ON c.id = d.cuisine_id
      ORDER BY RANDOM()
      LIMIT 1
    ''');
    if (rows.isEmpty) throw Exception('No dishes in database');
    return Dish.fromMap(rows.first);
  }

  Future<List<Dish>> searchDishes(String query) async {
    final db = await AppDatabase.database;
    final q = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery('''
      SELECT d.id, d.cuisine_id, d.name, d.thumbnail_url, d.short_description,
             c.name AS cuisine_name,
             $_categoriesSubquery
      FROM dishes d
      JOIN cuisines c ON c.id = d.cuisine_id
      WHERE LOWER(d.name) LIKE ?
         OR LOWER(c.name) LIKE ?
         OR LOWER(d.short_description) LIKE ?
         OR EXISTS (
           SELECT 1 FROM dish_categories dc2
           JOIN categories cat2 ON cat2.id = dc2.category_id
           WHERE dc2.dish_id = d.id AND LOWER(cat2.name) LIKE ?
         )
      ORDER BY d.name ASC
    ''', [q, q, q, q]);
    return rows.map(Dish.fromMap).toList();
  }

  // ── Dish detail ───────────────────────────────────────────────────────────

  Future<DishDetail> getDishDetail(int dishId) async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT
        dd.id      AS detail_id,
        dd.dish_id,
        dd.full_description,
        dd.ingredients,
        dd.preparation,
        dd.video_url_en,
        dd.video_url_hi,
        dd.video_url_ta,
        dd.video_url_ml,
        dd.video_url_ar,
        dd.video_url_de,
        dd.video_url_fr,
        dd.video_url_es,
        dd.video_url_it,
        dd.video_url_zh,
        d.name,
        d.thumbnail_url,
        d.short_description,
        c.name     AS cuisine_name,
        (SELECT GROUP_CONCAT(cat.name, ',')
         FROM dish_categories dc
         JOIN categories cat ON cat.id = dc.category_id
         WHERE dc.dish_id = d.id) AS categories_raw
      FROM dish_details dd
      JOIN dishes d   ON d.id  = dd.dish_id
      JOIN cuisines c ON c.id  = d.cuisine_id
      WHERE dd.dish_id = ?
      LIMIT 1
    ''', [dishId]);
    if (rows.isEmpty) throw Exception('Dish detail not found for id $dishId');
    return DishDetail.fromMap(rows.first);
  }

  // ── Related dishes (same cuisine, excluding current) ─────────────────────

  Future<List<Dish>> getRelatedDishes(int dishId, int cuisineId) async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT d.id, d.cuisine_id, d.name, d.thumbnail_url, d.short_description,
             c.name AS cuisine_name,
             $_categoriesSubquery
      FROM dishes d
      JOIN cuisines c ON c.id = d.cuisine_id
      WHERE d.cuisine_id = ? AND d.id != ?
      ORDER BY RANDOM()
      LIMIT 6
    ''', [cuisineId, dishId]);
    return rows.map(Dish.fromMap).toList();
  }
}
