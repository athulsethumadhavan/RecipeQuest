import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dish_model.dart';

class FavoritesRepository extends ChangeNotifier {
  static const String _key = 'favorites_v2';

  // In-memory cache for synchronous reads
  Set<int> _ids = {};
  bool _loaded = false;

  /// Call once before accessing [isFavoriteSync]. Safe to call multiple times.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _ids = raw.map((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return m['id'] as int;
    }).toSet();
    _loaded = true;
    notifyListeners();
  }

  /// Synchronous check — only reliable after [ensureLoaded] has completed.
  bool isFavoriteSync(int dishId) => _ids.contains(dishId);

  Future<List<Dish>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      final map = json.decode(s) as Map<String, dynamic>;
      return Dish.fromMap(map);
    }).toList();
  }

  Future<void> addFavorite(Dish dish) async {
    if (_ids.contains(dish.id)) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(json.encode({
      'id': dish.id,
      'cuisine_id': dish.cuisineId,
      'name': dish.name,
      'thumbnail_url': dish.thumbnailUrl,
      'categories_raw': dish.categories.join(','),
      'short_description': dish.shortDescription,
      'cuisine_name': dish.cuisineName,
    }));
    await prefs.setStringList(_key, raw);
    _ids.add(dish.id);
    notifyListeners();
  }

  Future<void> removeFavorite(int dishId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return m['id'] == dishId;
    });
    await prefs.setStringList(_key, raw);
    _ids.remove(dishId);
    notifyListeners();
  }

  Future<bool> isFavorite(int dishId) async {
    await ensureLoaded();
    return _ids.contains(dishId);
  }

  Future<void> toggleFavorite(Dish dish) async {
    if (_ids.contains(dish.id)) {
      await removeFavorite(dish.id);
    } else {
      await addFavorite(dish);
    }
  }
}
