import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cuisine_model.dart';
import '../models/dish_model.dart';
import '../models/dish_detail_model.dart';

/// All data comes directly from Supabase — no local cache.
class CuisineRepository {
  static SupabaseClient get _sb => Supabase.instance.client;

  // ── Cuisines ──────────────────────────────────────────────────────────────

  Future<List<Cuisine>> getCuisines() async {
    final rows = await _sb.from('cuisines').select().order('id');
    return rows.map((r) => Cuisine.fromMap(r)).toList();
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<String>> getCategoriesForCuisine(int cuisineId) async {
    final rows = await _sb
        .from('cuisine_categories')
        .select('categories(name)')
        .eq('cuisine_id', cuisineId);

    return rows
        .map((r) {
          final cat = r['categories'] as Map<String, dynamic>?;
          return (cat?['name'] as String?) ?? '';
        })
        .where((n) => n.isNotEmpty)
        .toList()
      ..sort();
  }

  // ── Dishes ────────────────────────────────────────────────────────────────

  Future<List<Dish>> getDishesByCuisine(int cuisineId) async {
    final rows = await _sb
        .from('dishes')
        .select('*, cuisines(name), dish_categories(categories(name))')
        .eq('cuisine_id', cuisineId)
        .order('id');
    return rows.map((r) => Dish.fromSupabase(r)).toList();
  }

  Future<List<Dish>> getAllDishes() async {
    final rows = await _sb
        .from('dishes')
        .select('*, cuisines(name), dish_categories(categories(name))')
        .order('id');
    return rows.map((r) => Dish.fromSupabase(r)).toList();
  }

  Future<Dish> getRandomDish() async {
    final rows = await _sb
        .from('dishes')
        .select('*, cuisines(name), dish_categories(categories(name))');
    if (rows.isEmpty) throw Exception('No dishes found');
    final list = List<Map<String, dynamic>>.from(rows)..shuffle();
    return Dish.fromSupabase(list.first);
  }

  /// Searches dish name, description, cuisine name, and categories client-side.
  /// With a small dataset (≤ 100 dishes) this is fast and avoids complex
  /// PostgREST cross-table OR filters.
  Future<List<Dish>> searchDishes(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final rows = await _sb
        .from('dishes')
        .select('*, cuisines(name), dish_categories(categories(name))')
        .order('name');

    return rows
        .map((r) => Dish.fromSupabase(r))
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.shortDescription.toLowerCase().contains(q) ||
            d.cuisineName.toLowerCase().contains(q) ||
            d.categories.any((c) => c.toLowerCase().contains(q)))
        .toList();
  }

  // ── Dish detail ───────────────────────────────────────────────────────────

  Future<DishDetail> getDishDetail(int dishId) async {
    final row = await _sb
        .from('dish_details')
        .select('''
          id,
          dish_id,
          full_description,
          ingredients,
          preparation,
          video_url_en,
          video_url_hi,
          video_url_ta,
          video_url_ml,
          video_url_ar,
          video_url_de,
          video_url_fr,
          video_url_es,
          video_url_it,
          video_url_zh,
          dishes(
            id,
            name,
            thumbnail_url,
            short_description,
            cuisine_id,
            cuisines(name),
            dish_categories(categories(name))
          )
        ''')
        .eq('dish_id', dishId)
        .single();
    return DishDetail.fromSupabase(row);
  }

  // ── Related dishes (same cuisine, excluding current) ─────────────────────

  Future<List<Dish>> getRelatedDishes(int dishId, int cuisineId) async {
    final rows = await _sb
        .from('dishes')
        .select('*, cuisines(name), dish_categories(categories(name))')
        .eq('cuisine_id', cuisineId)
        .neq('id', dishId);

    final list = List<Map<String, dynamic>>.from(rows)..shuffle();
    return list.take(6).map((r) => Dish.fromSupabase(r)).toList();
  }
}
