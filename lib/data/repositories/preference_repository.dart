import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceRepository extends ChangeNotifier {
  static const _keySelectedCuisines = 'selected_cuisine_ids';
  static const _keyOnboardingDone = 'onboarding_done';

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> completeOnboarding(List<int> selectedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
    await prefs.setString(_keySelectedCuisines, jsonEncode(selectedIds));
    notifyListeners(); // triggers HomeViewModel to re-filter
  }

  Future<List<int>> getSelectedCuisineIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySelectedCuisines);
    if (raw == null) return [];
    return List<int>.from(jsonDecode(raw));
  }

  Future<void> updateSelectedCuisineIds(List<int> selectedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedCuisines, jsonEncode(selectedIds));
    notifyListeners();
  }
}
