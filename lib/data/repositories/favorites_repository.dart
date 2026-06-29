import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dish_model.dart';
import '../services/auth_service.dart';

/// Manages favourites.
///
/// • When logged in  → source of truth is Supabase `user_favorites`.
///   Changes also update the local SharedPreferences cache for instant reads.
/// • When logged out → SharedPreferences only.
///
/// On login, local favourites are automatically merged into Supabase so the
/// user never loses their pre-login picks.
class FavoritesRepository extends ChangeNotifier {
  static const String _key = 'favorites_v2';

  static SupabaseClient get _db => Supabase.instance.client;

  // In-memory id cache for synchronous isFavoriteSync checks
  Set<int> _ids = {};
  bool _loaded = false;

  // ── Public state ────────────────────────────────────────────────────────────

  /// Synchronous check — only reliable after [ensureLoaded] has completed.
  bool isFavoriteSync(int dishId) => _ids.contains(dishId);

  // ── Loading ─────────────────────────────────────────────────────────────────

  /// Loads favourites from the appropriate source and warms the in-memory cache.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _ids = (await _idSet());
    _loaded = true;
    notifyListeners();
  }

  /// Call after login to merge local favourites into Supabase, then reload.
  Future<void> onLogin() async {
    _loaded = false;
    await _mergLocalToSupabase();
    _ids = (await _idSet());
    _loaded = true;
    notifyListeners();
  }

  /// Call after logout to fall back to local-only.
  Future<void> onLogout() async {
    _loaded = false;
    _ids = (await _localIdSet());
    _loaded = true;
    notifyListeners();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<List<Dish>> getFavorites() async {
    if (AuthService.instance.isLoggedIn) {
      return _remoteGetFavorites();
    }
    return _localGetFavorites();
  }

  Future<void> addFavorite(Dish dish) async {
    if (_ids.contains(dish.id)) return;

    await _localAdd(dish);
    _ids.add(dish.id);

    if (AuthService.instance.isLoggedIn) {
      await _remoteAdd(dish);
    }

    notifyListeners();
  }

  Future<void> removeFavorite(int dishId) async {
    await _localRemove(dishId);
    _ids.remove(dishId);

    if (AuthService.instance.isLoggedIn) {
      await _remoteRemove(dishId);
    }

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

  // ── Local (SharedPreferences) ───────────────────────────────────────────────

  Future<Set<int>> _localIdSet() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return m['id'] as int;
    }).toSet();
  }

  Future<List<Dish>> _localGetFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      final map = json.decode(s) as Map<String, dynamic>;
      return Dish.fromMap(map);
    }).toList();
  }

  Future<void> _localAdd(Dish dish) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    if (raw.any((s) => (json.decode(s) as Map)['id'] == dish.id)) return;
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
  }

  Future<void> _localRemove(int dishId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return m['id'] == dishId;
    });
    await prefs.setStringList(_key, raw);
  }

  // ── Remote (Supabase) ───────────────────────────────────────────────────────

  Future<Set<int>> _remoteIdSet() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return {};
    try {
      final rows = await _db
          .from('user_favorites')
          .select('dish_id')
          .eq('user_id', uid);
      return (rows as List).map((r) => r['dish_id'] as int).toSet();
    } catch (e) {
      debugPrint('[FavoritesRepo] remoteIdSet error: $e');
      return {};
    }
  }

  Future<List<Dish>> _remoteGetFavorites() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('user_favorites')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      return (rows as List).map((r) {
        return Dish(
          id: r['dish_id'] as int,
          cuisineId: 0,
          name: r['dish_name'] ?? '',
          thumbnailUrl: r['thumbnail_url'] ?? '',
          categories: [],
          shortDescription: r['short_description'] ?? '',
          cuisineName: r['cuisine_name'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('[FavoritesRepo] remoteGetFavorites error: $e');
      return _localGetFavorites();
    }
  }

  Future<void> _remoteAdd(Dish dish) async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return;
    try {
      await _db.from('user_favorites').upsert({
        'user_id': uid,
        'dish_id': dish.id,
        'dish_name': dish.name,
        'thumbnail_url': dish.thumbnailUrl,
        'cuisine_name': dish.cuisineName,
        'short_description': dish.shortDescription,
      });
    } catch (e) {
      debugPrint('[FavoritesRepo] remoteAdd error: $e');
    }
  }

  Future<void> _remoteRemove(int dishId) async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return;
    try {
      await _db
          .from('user_favorites')
          .delete()
          .eq('user_id', uid)
          .eq('dish_id', dishId);
    } catch (e) {
      debugPrint('[FavoritesRepo] remoteRemove error: $e');
    }
  }

  // ── Merge ───────────────────────────────────────────────────────────────────

  Future<void> _mergLocalToSupabase() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return;

    final localList = await _localGetFavorites();
    if (localList.isEmpty) return;

    final rows = localList.map((d) => {
          'user_id': uid,
          'dish_id': d.id,
          'dish_name': d.name,
          'thumbnail_url': d.thumbnailUrl,
          'cuisine_name': d.cuisineName,
          'short_description': d.shortDescription,
        }).toList();

    try {
      await _db
          .from('user_favorites')
          .upsert(rows, onConflict: 'user_id,dish_id');
    } catch (e) {
      debugPrint('[FavoritesRepo] merge error: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<Set<int>> _idSet() async {
    if (AuthService.instance.isLoggedIn) {
      final remote = await _remoteIdSet();
      return remote.isNotEmpty ? remote : await _localIdSet();
    }
    return _localIdSet();
  }
}
