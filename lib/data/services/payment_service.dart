import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles in-app purchases:
///   • dish_unlock      — $0.99 consumable,  unlocks a single dish
///   • cuisine_unlock   — $9.99 consumable,  unlocks a single cuisine
///   • adfree_monthly   — $0.50 subscription, removes ads for 30 days
///
/// SETUP (do once in both stores before releasing):
///   Android : Google Play Console → Monetize → In-app products / Subscriptions → Create.
///   iOS     : App Store Connect → My Apps → [App] → In-App Purchases → +.
class PaymentService {
  PaymentService._();

  // ── Product IDs ────────────────────────────────────────────────────────────
  static const String productId        = 'dish_unlock';
  static const String cuisineProductId = 'cuisine_unlock';
  static const String adFreeProductId  = 'adfree_monthly';

  static const String _adFreePrefKey = 'ad_free_expiry_ms';

  // ── State ──────────────────────────────────────────────────────────────────
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  static ProductDetails? _product;
  static ProductDetails? _cuisineProduct;
  static ProductDetails? _adFreeProduct;
  static bool _storeAvailable = false;

  /// Fires whenever the ad-free status changes (purchase, restore, expiry).
  static final ValueNotifier<bool> adFreeNotifier = ValueNotifier(false);

  static bool get isAdFree        => adFreeNotifier.value;
  static bool get isAvailable     => _storeAvailable && _product != null;
  static bool get isCuisineAvailable  => _storeAvailable && _cuisineProduct != null;
  static bool get isAdFreeAvailable   => _storeAvailable && _adFreeProduct != null;

  static String get displayPrice       => _product?.price       ?? '\$1.00';
  static String get cuisineDisplayPrice => _cuisineProduct?.price ?? '\$10.00';
  static String get adFreeDisplayPrice  => _adFreeProduct?.price  ?? '\$0.50';

  // Per-purchase callbacks
  static VoidCallback? _onSuccess;
  static VoidCallback? _onFailed;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  static Future<void> init() async {
    // Load cached ad-free status first so it's ready before async work finishes
    await _loadAdFreeStatus();

    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) {
      debugPrint('[PaymentService] Store not available on this device');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) => debugPrint('[PaymentService] Stream error: $e'),
    );

    // Query all products in one call
    final response = await _iap.queryProductDetails(
        {productId, cuisineProductId, adFreeProductId});

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
      } else if (p.id == adFreeProductId) {
        _adFreeProduct = p;
        debugPrint('[PaymentService] Ad-free product ready: ${p.price}');
      }
    }

    // Restore any existing subscription silently on launch
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ── Purchase flows ─────────────────────────────────────────────────────────

  static Future<bool> purchaseDishAccess({
    required VoidCallback onSuccess,
    required VoidCallback onFailed,
  }) async {
    if (!isAvailable) { onFailed(); return false; }
    _onSuccess = onSuccess;
    _onFailed  = onFailed;
    try {
      return await _iap.buyConsumable(
          purchaseParam: PurchaseParam(productDetails: _product!));
    } catch (e) {
      debugPrint('[PaymentService] buyConsumable error: $e');
      _clear();
      onFailed();
      return false;
    }
  }

  static Future<bool> purchaseCuisineAccess({
    required VoidCallback onSuccess,
    required VoidCallback onFailed,
  }) async {
    if (!isCuisineAvailable) { onFailed(); return false; }
    _onSuccess = onSuccess;
    _onFailed  = onFailed;
    try {
      return await _iap.buyConsumable(
          purchaseParam: PurchaseParam(productDetails: _cuisineProduct!));
    } catch (e) {
      debugPrint('[PaymentService] buyConsumable (cuisine) error: $e');
      _clear();
      onFailed();
      return false;
    }
  }

  /// Initiates the $0.50/month ad-free subscription.
  static Future<bool> purchaseAdFree({
    required VoidCallback onSuccess,
    required VoidCallback onFailed,
  }) async {
    if (!isAdFreeAvailable) { onFailed(); return false; }
    _onSuccess = onSuccess;
    _onFailed  = onFailed;
    try {
      return await _iap.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: _adFreeProduct!));
    } catch (e) {
      debugPrint('[PaymentService] buyNonConsumable (ad-free) error: $e');
      _clear();
      onFailed();
      return false;
    }
  }

  /// Restores previous purchases (use for "Restore Purchases" button).
  static Future<void> restorePurchases({
    VoidCallback? onSuccess,
    VoidCallback? onFailed,
  }) async {
    _onSuccess = onSuccess;
    _onFailed  = onFailed;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[PaymentService] restorePurchases error: $e');
      _onFailed?.call();
      _clear();
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          if (p.productID == adFreeProductId) {
            await _setAdFree();
            _onSuccess?.call();
            _clear();
          } else if (p.productID == productId || p.productID == cuisineProductId) {
            _onSuccess?.call();
            _clear();
          }
          break;

        case PurchaseStatus.error:
          debugPrint('[PaymentService] Purchase error: ${p.error?.message}');
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
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

  /// Stores ad-free expiry (31 days from now) in SharedPreferences.
  static Future<void> _setAdFree() async {
    final expiry = DateTime.now().add(const Duration(days: 31));
    final prefs  = await SharedPreferences.getInstance();
    await prefs.setInt(_adFreePrefKey, expiry.millisecondsSinceEpoch);
    adFreeNotifier.value = true;
    debugPrint('[PaymentService] Ad-free active until $expiry');
  }

  /// Reads cached ad-free expiry from SharedPreferences.
  static Future<void> _loadAdFreeStatus() async {
    final prefs   = await SharedPreferences.getInstance();
    final expiryMs = prefs.getInt(_adFreePrefKey) ?? 0;
    adFreeNotifier.value =
        DateTime.now().millisecondsSinceEpoch < expiryMs;
    debugPrint('[PaymentService] isAdFree=${adFreeNotifier.value}');
  }

  static void _clear() {
    _onSuccess = null;
    _onFailed  = null;
  }
}
