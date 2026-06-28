import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Handles in-app purchases:
///   • dish_unlock    — $0.99 consumable, unlocks a single dish
///   • cuisine_unlock — $9.99 consumable, unlocks a single cuisine subscription
///
/// SETUP (do once in both stores before releasing):
///   On Android: Google Play Console → Monetize → In-app products → Create.
///   On iOS: App Store Connect → My Apps → [App] → In-App Purchases → +.
class PaymentService {
  PaymentService._();

  static const String productId        = 'dish_unlock';
  static const String cuisineProductId = 'cuisine_unlock';

  static final InAppPurchase _iap = InAppPurchase.instance;

  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static ProductDetails? _product;
  static ProductDetails? _cuisineProduct;
  static bool _storeAvailable = false;

  // Per-purchase callbacks
  static VoidCallback? _onSuccess;
  static VoidCallback? _onFailed;

  static bool get isAvailable => _storeAvailable && _product != null;
  static bool get isCuisineAvailable => _storeAvailable && _cuisineProduct != null;

  /// Human-readable price from the store (e.g. "$0.99"), or fallback.
  static String get displayPrice => _product?.price ?? '\$1.00';

  /// Human-readable cuisine price (e.g. "$9.99"), or fallback.
  static String get cuisineDisplayPrice => _cuisineProduct?.price ?? '\$10.00';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Call once at app start (after MobileAds / Supabase init).
  static Future<void> init() async {
    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) {
      debugPrint('[PaymentService] Store not available on this device');
      return;
    }

    // Listen to the unified purchase stream
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) => debugPrint('[PaymentService] Stream error: $e'),
    );

    // Load both product metadata in one call
    final response = await _iap.queryProductDetails({productId, cuisineProductId});
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[PaymentService] Products not found: ${response.notFoundIDs}. '
          'Check Play Console / App Store Connect.');
    }
    for (final p in response.productDetails) {
      if (p.id == productId) {
        _product = p;
        debugPrint('[PaymentService] Dish product ready: ${p.price}');
      } else if (p.id == cuisineProductId) {
        _cuisineProduct = p;
        debugPrint('[PaymentService] Cuisine product ready: ${p.price}');
      }
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ── Purchase flows ─────────────────────────────────────────────────────────

  /// Initiates the store purchase.
  /// [onSuccess] is called after a confirmed purchase — caller handles
  /// any side effects (add to favourites, navigate, etc.).
  /// [onFailed] is called on cancel or error.
  static Future<bool> purchaseDishAccess({
    required VoidCallback onSuccess,
    required VoidCallback onFailed,
  }) async {
    if (!isAvailable) {
      debugPrint('[PaymentService] Store unavailable or product not loaded');
      onFailed();
      return false;
    }

    _onSuccess = onSuccess;
    _onFailed = onFailed;

    final param = PurchaseParam(productDetails: _product!);
    try {
      return await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('[PaymentService] buyConsumable error: $e');
      _clear();
      onFailed();
      return false;
    }
  }

  /// Initiates the $10 cuisine-unlock purchase.
  static Future<bool> purchaseCuisineAccess({
    required VoidCallback onSuccess,
    required VoidCallback onFailed,
  }) async {
    if (!isCuisineAvailable) {
      debugPrint('[PaymentService] Cuisine store unavailable or product not loaded');
      onFailed();
      return false;
    }

    _onSuccess = onSuccess;
    _onFailed  = onFailed;

    final param = PurchaseParam(productDetails: _cuisineProduct!);
    try {
      return await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('[PaymentService] buyConsumable (cuisine) error: $e');
      _clear();
      onFailed();
      return false;
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != productId && p.productID != cuisineProductId) continue;

      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          _onSuccess?.call();
          _clear();
          break;

        case PurchaseStatus.error:
          debugPrint('[PaymentService] Purchase error: ${p.error?.message}');
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          _onFailed?.call();
          _clear();
          break;

        case PurchaseStatus.canceled:
          debugPrint('[PaymentService] Purchase cancelled');
          _onFailed?.call();
          _clear();
          break;

        case PurchaseStatus.pending:
          debugPrint('[PaymentService] Purchase pending...');
          break;
      }
    }
  }

  static void _clear() {
    _onSuccess = null;
    _onFailed = null;
  }
}
