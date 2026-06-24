import '../database/app_database.dart';
import '../models/cuisine_model.dart';
import '../models/dish_model.dart';
import '../models/dish_detail_model.dart';

class CuisineRepository {
  // ── Cuisines ──────────────────────────────────────────────────────────────

  Future<List<Cuisine>> getCuisines() async {
    final db = await AppDatabase.database;
    final rows = await db.query('cuisines', orderBy: 'id ASC');
    return rows.map(Cuisine.fromMap).toList();
  }

  // ── Dishes ────────────────────────────────────────────────────────────────

  Future<List<Dish>> getDishesByCuisine(int cuisineId) async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT d.*, c.name AS cuisine_name
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
      SELECT d.*, c.name AS cuisine_name
      FROM dishes d
      JOIN cuisines c ON c.id = d.cuisine_id
      ORDER BY d.id ASC
    ''');
    return rows.map(Dish.fromMap).toList();
  }

  Future<Dish> getRandomDish() async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT d.*, c.name AS cuisine_name
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
      SELECT d.*, c.name AS cuisine_name
      FROM dishes d
      JOIN cuisines c ON c.id = d.cuisine_id
      WHERE LOWER(d.name) LIKE ?
         OR LOWER(d.category) LIKE ?
         OR LOWER(c.name) LIKE ?
         OR LOWER(d.short_description) LIKE ?
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
        dd.video_url,
        d.name,
        d.thumbnail_url,
        d.category,
        d.short_description,
        c.name     AS cuisine_name
      FROM dish_details dd
      JOIN dishes d  ON d.id  = dd.dish_id
      JOIN cuisines c ON c.id = d.cuisine_id
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
      SELECT d.*, c.name AS cuisine_name
      FROM dishes d
      JOIN cuisines c ON c.id = d.cuisine_id
      WHERE d.cuisine_id = ? AND d.id != ?
      ORDER BY RANDOM()
      LIMIT 6
    ''', [cuisineId, dishId]);
    return rows.map(Dish.fromMap).toList();
  }
}
