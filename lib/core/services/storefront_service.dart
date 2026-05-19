import 'dart:async';
import 'dart:convert';

import 'package:chessiq/features/store/models/store_models.dart';
import 'package:chessiq/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class StorefrontService {
  StorefrontService._();

  static final StorefrontService instance = StorefrontService._();

  static const String _defaultAssetPath = 'store/default_storefront.json';
  static final Uri _remoteConfigUri = Uri.parse(
    '$kFirebaseRealtimeDatabaseUrl/storefront_public/v1.json',
  );

  Future<StorefrontConfig>? _inFlight;
  StorefrontConfig _cachedConfig = const StorefrontConfig();
  bool _hasLoaded = false;

  StorefrontConfig get currentConfig => _cachedConfig;

  Future<StorefrontConfig> fetchConfig({bool forceRefresh = false}) {
    if (!forceRefresh && _hasLoaded) {
      return Future<StorefrontConfig>.value(_cachedConfig);
    }

    return _inFlight ??= _fetchConfig();
  }

  bool isOfferActive(String offerId, {DateTime? now}) {
    return _cachedConfig.offer(offerId).isActive(now ?? DateTime.now());
  }

  String? badgeFor(String offerId, {DateTime? now}) {
    final offer = _cachedConfig.offer(offerId);
    if (!offer.isActive(now ?? DateTime.now())) {
      return null;
    }
    final badge = offer.badge?.trim();
    return badge == null || badge.isEmpty ? null : badge;
  }

  String? ctaLabelFor(String offerId, {DateTime? now}) {
    final offer = _cachedConfig.offer(offerId);
    if (!offer.isActive(now ?? DateTime.now())) {
      return null;
    }
    final label = offer.ctaLabel?.trim();
    return label == null || label.isEmpty ? null : label;
  }

  int coinPriceFor(
    String offerId,
    int fallback, {
    int? purchaseCount,
    DateTime? now,
  }) {
    final offer = _cachedConfig.offer(offerId);
    if (!offer.isActive(now ?? DateTime.now())) {
      return fallback;
    }
    final directPrice = offer.coinPrice;
    if (directPrice != null) {
      return directPrice;
    }

    final baseCoinPrice = offer.baseCoinPrice;
    if (baseCoinPrice != null) {
      final step = offer.coinPriceStep ?? 0;
      final offset = purchaseCount ?? 0;
      return baseCoinPrice + (step * offset);
    }

    return fallback;
  }

  StoreCampaignConfig? get activeCampaign {
    final campaign = _cachedConfig.campaign;
    if (campaign == null || !campaign.isActive(DateTime.now())) {
      return null;
    }
    return campaign;
  }

  Future<StorefrontConfig> _fetchConfig() async {
    try {
      final defaultConfig = await _loadDefaultConfig();
      _cachedConfig = defaultConfig;

      try {
        final response = await http
            .get(_remoteConfigUri)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final body = response.body.trim();
          if (body.isNotEmpty && body != 'null') {
            final decoded = jsonDecode(body);
            if (decoded is Map<String, dynamic>) {
              final remoteConfig = StorefrontConfig.fromMap(decoded);
              _cachedConfig = defaultConfig.merge(remoteConfig);
            }
          }
        } else {
          debugPrint(
            'Storefront config request returned ${response.statusCode}; '
            'using bundled defaults.',
          );
        }
      } catch (error) {
        debugPrint('Storefront remote config unavailable: $error');
      }

      _hasLoaded = true;
      return _cachedConfig;
    } finally {
      _inFlight = null;
    }
  }

  Future<StorefrontConfig> _loadDefaultConfig() async {
    try {
      final rawJson = await rootBundle.loadString(_defaultAssetPath);
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return StorefrontConfig.fromMap(decoded);
      }
    } catch (error) {
      debugPrint('Storefront bundled defaults unavailable: $error');
    }

    return const StorefrontConfig();
  }
}
