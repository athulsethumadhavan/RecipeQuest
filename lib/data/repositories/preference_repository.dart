import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class PreferenceRepository extends ChangeNotifier {
  static const _keySelectedCuisines = 'selected_cuisine_ids';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyInitialCuisineId = 'initial_cuisine_id'; // set once, never overwritten

  static SupabaseClient get _db => Supabase.instance.client;

  // In-memory cache: reflects what is currently displayed
  // (Supabase IDs when logged in, local IDs when signed out)
  List<int> _activeIds = [];

  // ── Onboarding ──────────────────────────────────────────────────────────────

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  /// Saves the cuisine selection.
  /// The very first call (onboarding) also records the initial cuisine ID,
  /// which is the one restored on logout. Subsequent calls (editing) do not
  /// overwrite the initial choice.
  Future<void> completeOnboarding(List<int> selectedIds) async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = !(prefs.getBool(_keyOnboardingDone) ?? false);

    await prefs.setBool(_keyOnboardingDone, true);
    await prefs.setString(_keySelectedCuisines, jsonEncode(selectedIds));

    // Lock in the initial cuisine once, never overwrite
    if (isFirstTime && selectedIds.isNotEmpty) {
      await prefs.setInt(_keyInitialCuisineId, selectedIds.first);
    }

    _activeIds = selectedIds;

    if (AuthService.instance.isLoggedIn) {
      await _saveToSupabase(selectedIds);
    }

    notifyListeners();
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Returns the currently active cuisine IDs.
  /// • Logged in  → Supabase (cached after onLogin)
  /// • Logged out → SharedPreferences (initial onboarding selection)
  Future<List<int>> getSelectedCuisineIds() async {
    if (_activeIds.isNotEmpty) return _activeIds;

    if (AuthService.instance.isLoggedIn) {
      final remote = await _fetchFromSupabase();
      if (remote.isNotEmpty) {
        _activeIds = remote;
        return _activeIds;
      }
      // Logged in but no Supabase data yet → fall through to local
    }

    _activeIds = await _getLocalIds();
    return _activeIds;
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  Future<void> updateSelectedCuisineIds(List<int> selectedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedCuisines, jsonEncode(selectedIds));
    _activeIds = selectedIds;

    if (AuthService.instance.isLoggedIn) {
      await _saveToSupabase(selectedIds);
    }

    notifyListeners();
  }

  // ── Auth lifecycle ──────────────────────────────────────────────────────────

  /// Call after the user signs in.
  /// Loads their cuisines from Supabase; if none exist, uploads the local
  /// onboarding selection so new accounts start with those cuisines.
  Future<void> onLogin() async {
    final remote = await _fetchFromSupabase();
    if (remote.isNotEmpty) {
      _activeIds = remote;
    } else {
      // New account — push local onboarding selection to Supabase
      final local = await _getLocalIds();
      if (local.isNotEmpty) {
        await _saveToSupabase(local);
      }
      _activeIds = local;
    }
    notifyListeners();
  }

  /// Call after the user signs out.
  /// Reverts displayed cuisines to the single initial onboarding choice only.
  Future<void> onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    int? initialId = prefs.getInt(_keyInitialCuisineId);

    // Migration: user onboarded before this key existed — derive and save it now
    if (initialId == null) {
      final saved = await _getLocalIds();
      if (saved.isNotEmpty) {
        initialId = saved.first;
        await prefs.setInt(_keyInitialCuisineId, initialId);
      }
    }

    _activeIds = initialId != null ? [initialId] : [];
    notifyListeners();
  }

  // ── Local helpers ───────────────────────────────────────────────────────────

  Future<List<int>> _getLocalIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySelectedCuisines);
    if (raw == null) return [];
    return List<int>.from(jsonDecode(raw));
  }

  // ── Supabase helpers ────────────────────────────────────────────────────────

  Future<List<int>> _fetchFromSupabase() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('user_cuisines')
          .select('cuisine_id')
          .eq('user_id', uid);
      return (rows as List).map((r) => r['cuisine_id'] as int).toList();
    } catch (e) {
      debugPrint('[PreferenceRepo] fetchFromSupabase error: $e');
      return [];
    }
  }

  Future<void> _saveToSupabase(List<int> cuisineIds) async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return;
    try {
      // Replace all existing rows for this user
      await _db.from('user_cuisines').delete().eq('user_id', uid);
      if (cuisineIds.isEmpty) return;
      final rows = cuisineIds
          .map((id) => {'user_id': uid, 'cuisine_id': id})
          .toList();
      await _db.from('user_cuisines').insert(rows);
    } catch (e) {
      debugPrint('[PreferenceRepo] saveToSupabase error: $e');
    }
  }
}
