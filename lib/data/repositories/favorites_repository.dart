import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dish_model.dart';

class FavoritesRepository {
  static const String _key = 'favorites_v2';

  Future<List<Dish>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      final map = json.decode(s) as Map<String, dynamic>;
      return Dish.fromMap(map);
    }).toList();
  }

  Future<void> addFavorite(Dish dish) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    if (raw.any((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return m['id'] == dish.id;
    })) return;
    raw.add(json.encode({
      'id': dish.id,
      'cuisine_id': dish.cuisineId,
      'name': dish.name,
      'thumbnail_url': dish.thumbnailUrl,
      'category': dish.category,
      'short_description': dish.shortDescription,
      'cuisine_name': dish.cuisineName,
    }));
    await prefs.setStringList(_key, raw);
  }

  Future<void> removeFavorite(int dishId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return m['id'] == dishId;
    });
    await prefs.setStringList(_key, raw);
  }

  Future<bool> isFavorite(int dishId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.any((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return m['id'] == dishId;
    });
  }
}
