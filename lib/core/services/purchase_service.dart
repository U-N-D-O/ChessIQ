import 'dart:async';

import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Product catalogue
// ---------------------------------------------------------------------------

/// All product IDs as registered in App Store Connect and Google Play Console.
///
/// Consumables grant coins; non-consumables grant permanent entitlements.
abstract final class IapProducts {
  // ── Consumables ──────────────────────────────────────────────────────────
  static const String coinPackS = 'com.qila.chessiq.coins_s';
  static const String coinPackL = 'com.qila.chessiq.coins_l';

  // ── Non-consumables ───────────────────────────────────────────────────────
  static const String resetBoardPass = 'com.qila.chessiq.reset_board_pass';
  static const String academyPass = 'com.qila.chessiq.academy_pass';

  static const int coinPackSAmount = 1500;
  static const int coinPackLAmount = 5000;

  static const Set<String> all = {
    coinPackS,
    coinPackL,
    resetBoardPass,
    academyPass,
  };

  static const Set<String> consumables = {coinPackS, coinPackL};
  static const Set<String> nonConsumables = {resetBoardPass, academyPass};
}

// ---------------------------------------------------------------------------
// PurchaseService
// ---------------------------------------------------------------------------

/// Thin wrapper around [InAppPurchase] that:
///
/// * Initialises the purchase stream once on app startup.
/// * Turns the stream-based API into Future-based calls via [buy].
/// * Delivers coins via [EconomyProvider] and records non-consumable
///   ownership in SharedPreferences under the `iap_owned_` prefix.
///
/// Call [initialize] from `main()` before [runApp], then
/// [attachEconomy] as soon as the [EconomyProvider] is created.
class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  static const String _ownedPrefix = 'iap_owned_';

  EconomyProvider? _economy;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, Completer<bool>> _pending = {};
  Map<String, ProductDetails> _products = {};
  bool _initialized = false;
  bool _storeAvailable = false;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Whether the platform billing client is reachable.
  bool get storeAvailable => _storeAvailable;

  /// Attach the [EconomyProvider] so coin delivery can happen even when
  /// purchases arrive outside of an active buy() call (e.g. on restore).
  void attachEconomy(EconomyProvider economy) => _economy = economy;

  /// Initialises the billing client, subscribes to the purchase stream, and
  /// restores any previous transactions.  Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!_isSupportedPlatform) {
      // in_app_purchase is not available on desktop/web.
      _storeAvailable = false;
      return;
    }

    _storeAvailable = await InAppPurchase.instance.isAvailable();
    if (!_storeAvailable) {
      debugPrint('IAP: billing client unavailable on this device.');
      return;
    }

    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _handleUpdates,
      onError: (Object e) => debugPrint('IAP stream error: $e'),
    );

    await _loadProducts();
    // Re-deliver any pending / previously purchased transactions.
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await InAppPurchase.instance.queryProductDetails(
        IapProducts.all,
      );
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP: products not found: ${response.notFoundIDs}');
      }
      _products = {for (final p in response.productDetails) p.id: p};
    } catch (e) {
      debugPrint('IAP product query failed: $e');
    }
  }

  /// The cached product details keyed by product ID (available after init).
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  Future<void> _handleUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliver(purchase);
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
          _pending[purchase.productID]?.complete(true);
          _pending.remove(purchase.productID);

        case PurchaseStatus.error:
          debugPrint(
            'IAP error for ${purchase.productID}: '
            '${purchase.error?.message}',
          );
          _pending[purchase.productID]?.complete(false);
          _pending.remove(purchase.productID);

        case PurchaseStatus.canceled:
          _pending[purchase.productID]?.complete(false);
          _pending.remove(purchase.productID);

        case PurchaseStatus.pending:
          // External payment pending; wait for the next stream event.
          break;
      }
    }
  }

  Future<void> _deliver(PurchaseDetails purchase) async {
    switch (purchase.productID) {
      case IapProducts.coinPackS:
        await _economy?.addCoins(IapProducts.coinPackSAmount);
      case IapProducts.coinPackL:
        await _economy?.addCoins(IapProducts.coinPackLAmount);
      case IapProducts.resetBoardPass:
        await _setOwned(IapProducts.resetBoardPass);
      case IapProducts.academyPass:
        await _setOwned(IapProducts.academyPass);
    }
  }

  Future<void> _setOwned(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_ownedPrefix$productId', true);
  }

  /// Returns true when the non-consumable [productId] has been delivered
  /// to this device (checked against SharedPreferences).
  Future<bool> isOwned(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_ownedPrefix$productId') ?? false;
  }

  /// Initiates the platform purchase flow for [productId].
  ///
  /// Returns `true` when the purchase is confirmed or restored, `false` if
  /// cancelled, errored, or the store is unavailable.
  Future<bool> buy(String productId) async {
    if (!_isSupportedPlatform) return false;
    if (!_storeAvailable) return false;
    if (_products.isEmpty) await _loadProducts();

    final productDetails = _products[productId];
    if (productDetails == null) {
      debugPrint('IAP: product not found: $productId');
      return false;
    }

    // Reuse any in-flight purchase for the same product.
    if (_pending.containsKey(productId)) {
      return _pending[productId]!.future;
    }

    final completer = Completer<bool>();
    _pending[productId] = completer;

    try {
      final param = PurchaseParam(productDetails: productDetails);
      if (IapProducts.consumables.contains(productId)) {
        await InAppPurchase.instance.buyConsumable(purchaseParam: param);
      } else {
        await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
      }
    } catch (e) {
      debugPrint('IAP buy() error: $e');
      _pending.remove(productId);
      completer.complete(false);
      return false;
    }

    return completer.future;
  }

  /// Asks the platform to re-deliver previously purchased non-consumables.
  Future<void> restorePurchases() async {
    if (!_isSupportedPlatform) return;
    if (!_storeAvailable) return;
    await InAppPurchase.instance.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
