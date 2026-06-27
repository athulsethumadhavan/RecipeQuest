import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../repositories/preference_repository.dart';

/// Handles the $1 cuisine-unlock in-app purchase.
///
/// SETUP (do once in both stores before releasing):
///   • Product ID : `cuisine_unlock`
///   • Type       : Consumable (Android) / Consumable (iOS)
///   • Price      : $0.99 USD (or your local equivalent of ~$1)
///
/// On Android: create the product in Google Play Console →
///   Monetize → Products → In-app products → Create product.
/// On iOS: create it in App Store Connect →
///   My Apps → [Your App] → In-App Purchases → +.
class PaymentService {
  PaymentService._();

  static const String productId = 'cuisine_unlock';
  static final InAppPurchase _iap = InAppPurchase.instance;

  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static ProductDetails? _product;
  static bool _storeAvailable = false;
  static PreferenceRepository? _prefRepository;

  // Per-purchase callbacks
  static int? _pendingCuisineId;
  static VoidCallback? _onSuccess;
  static VoidCallback? _onFailed;

  static bool get isAvailable => _storeAvailable && _product != null;

  /// Human-readable price from the store (e.g. "$0.99"), or fallback.
  static String get displayPrice => _product?.price ?? '\$1.00';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Call once at app start (after MobileAds / Supabase init).
  static Future<void> init(PreferenceRepository prefRepository) async {
    _prefRepository = prefRepository;

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

    // Load the product metadata
    final response = await _iap.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
          '[PaymentService] Product "$productId" not found in store. '
          'Check Play Console / App Store Connect.');
    }
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
      debugPrint('[PaymentService] Product ready: ${_product!.price}');
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ── Purchase flow ──────────────────────────────────────────────────────────

  /// Initiates the store purchase to unlock [cuisineId].
  /// Returns false immediately if the store is not ready.
  static Future<bool> purchaseCuisineAccess({
    required int cuisineId,
    required VoidCallback onSuccess,
    required VoidCallback onFailed,
  }) async {
    if (!isAvailable) {
      debugPrint('[PaymentService] Store unavailable or product not loaded');
      onFailed();
      return false;
    }

    _pendingCuisineId = cuisineId;
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

  // ── Internal ───────────────────────────────────────────────────────────────

  static Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != productId) continue;

      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          await _unlockCuisine();
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

  static Future<void> _unlockCuisine() async {
    final id = _pendingCuisineId;
    final repo = _prefRepository;
    if (id == null || repo == null) return;

    final current = await repo.getSelectedCuisineIds();
    if (!current.contains(id)) {
      await repo.updateSelectedCuisineIds([...current, id]);
    }
  }

  static void _clear() {
    _pendingCuisineId = null;
    _onSuccess = null;
    _onFailed = null;
  }
}
