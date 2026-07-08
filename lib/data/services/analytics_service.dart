import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around FirebaseAnalytics with typed event methods.
/// All calls are fire-and-forget — errors are swallowed so analytics
/// never crashes the app.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final _fa = FirebaseAnalytics.instance;

  /// Navigator observer — attach to GoRouter so screen views are
  /// logged automatically on every route change.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _fa);

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _log(String name,
      [Map<String, Object>? params]) async {
    try {
      await _fa.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('[Analytics] $name error: $e');
    }
  }

  // ── Screen views ───────────────────────────────────────────────────────────

  Future<void> logScreen(String screenName) async {
    try {
      await _fa.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('[Analytics] logScreen error: $e');
    }
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<void> logSignUp() async {
    try {
      await _fa.logSignUp(signUpMethod: 'email');
    } catch (e) {
      debugPrint('[Analytics] logSignUp error: $e');
    }
  }

  Future<void> logLogin() async {
    try {
      await _fa.logLogin(loginMethod: 'email');
    } catch (e) {
      debugPrint('[Analytics] logLogin error: $e');
    }
  }

  Future<void> logLogout() => _log('logout');

  Future<void> logPasswordReset() => _log('password_reset');

  // ── Recipe & cuisine ───────────────────────────────────────────────────────

  Future<void> logDishView({
    required int dishId,
    required String dishName,
    required String cuisineName,
  }) =>
      _log('dish_view', {
        'dish_id': dishId,
        'dish_name': dishName,
        'cuisine_name': cuisineName,
      });

  Future<void> logFavoriteAdded({
    required int dishId,
    required String dishName,
  }) =>
      _log('favorite_added', {
        'dish_id': dishId,
        'dish_name': dishName,
      });

  Future<void> logFavoriteRemoved({
    required int dishId,
    required String dishName,
  }) =>
      _log('favorite_removed', {
        'dish_id': dishId,
        'dish_name': dishName,
      });

  Future<void> logSearch(String query) async {
    try {
      await _fa.logSearch(searchTerm: query);
    } catch (e) {
      debugPrint('[Analytics] logSearch error: $e');
    }
  }

  Future<void> logCuisineView({
    required int cuisineId,
    required String cuisineName,
  }) =>
      _log('cuisine_view', {
        'cuisine_id': cuisineId,
        'cuisine_name': cuisineName,
      });

  Future<void> logCuisineUnlockAttempt(String cuisineName) =>
      _log('cuisine_unlock_attempt', {'cuisine_name': cuisineName});

  Future<void> logCuisineUnlockSuccess(String cuisineName) =>
      _log('cuisine_unlock_success', {'cuisine_name': cuisineName});

  // ── Onboarding funnel ──────────────────────────────────────────────────────

  Future<void> logIntroSlideView(int index) =>
      _log('intro_slide_view', {'slide_index': index});

  Future<void> logIntroSkipped(int atSlide) =>
      _log('intro_skipped', {'slide_index': atSlide});

  Future<void> logIntroCompleted() => _log('intro_completed');

  Future<void> logCuisineSelectionCompleted(int count) =>
      _log('cuisine_selection_completed', {'cuisine_count': count});
}
