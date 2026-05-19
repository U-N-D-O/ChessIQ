enum StoreSection { general, themes }

abstract final class StoreOfferIds {
  static const String watchAdReward = 'watch_ad_reward';
  static const String coinPackS = 'coin_pack_s';
  static const String coinPackL = 'coin_pack_l';
  static const String cleanPlayPass = 'clean_play_pass';
  static const String academyTuitionPass = 'academy_tuition_pass';
  static const String themePack = 'theme_pack';
  static const String sakuraBoard = 'sakura_board';
  static const String tropicalBoard = 'tropical_board';
  static const String piecePack = 'piece_pack';
  static const String spectralPieces = 'spectral_pieces';
  static const String tuttiFruttiPieces = 'tutti_frutti_pieces';
  static const String monochromePieces = 'monochrome_pieces';
  static const String pixelArrows = 'pixel_arrows';
  static const String heavyArrows = 'heavy_arrows';
  static const String expertMode = 'expert_mode';
  static const String grandmasterMode = 'grandmaster_mode';
  static const String oracleMode = 'oracle_mode';
  static const String extraSuggestion = 'extra_suggestion';
  static const String sacrificeMode = 'sacrifice_mode';

  static const Set<String> all = <String>{
    watchAdReward,
    coinPackS,
    coinPackL,
    cleanPlayPass,
    academyTuitionPass,
    themePack,
    sakuraBoard,
    tropicalBoard,
    piecePack,
    spectralPieces,
    tuttiFruttiPieces,
    monochromePieces,
    pixelArrows,
    heavyArrows,
    expertMode,
    grandmasterMode,
    oracleMode,
    extraSuggestion,
    sacrificeMode,
  };
}

enum StoreAvailabilityKind { always, annualRange }

class StoreAvailability {
  const StoreAvailability({
    this.kind = StoreAvailabilityKind.always,
    this.startMonth,
    this.startDay,
    this.endMonth,
    this.endDay,
  });

  const StoreAvailability.always() : this();

  final StoreAvailabilityKind kind;
  final int? startMonth;
  final int? startDay;
  final int? endMonth;
  final int? endDay;

  factory StoreAvailability.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const StoreAvailability.always();
    }

    final rawKind = map['kind']?.toString().trim().toLowerCase();
    final kind = rawKind == 'annualrange' || rawKind == 'annual_range'
        ? StoreAvailabilityKind.annualRange
        : StoreAvailabilityKind.always;

    return StoreAvailability(
      kind: kind,
      startMonth: (map['startMonth'] as num?)?.toInt(),
      startDay: (map['startDay'] as num?)?.toInt(),
      endMonth: (map['endMonth'] as num?)?.toInt(),
      endDay: (map['endDay'] as num?)?.toInt(),
    );
  }

  bool isActive(DateTime now) {
    switch (kind) {
      case StoreAvailabilityKind.always:
        return true;
      case StoreAvailabilityKind.annualRange:
        final resolvedStartMonth = startMonth;
        final resolvedStartDay = startDay;
        final resolvedEndMonth = endMonth;
        final resolvedEndDay = endDay;
        if (resolvedStartMonth == null ||
            resolvedStartDay == null ||
            resolvedEndMonth == null ||
            resolvedEndDay == null) {
          return true;
        }

        final today = DateTime(now.year, now.month, now.day);
        final start = DateTime(now.year, resolvedStartMonth, resolvedStartDay);
        final end = DateTime(now.year, resolvedEndMonth, resolvedEndDay);
        if (!end.isBefore(start)) {
          return !today.isBefore(start) && !today.isAfter(end);
        }
        return !today.isBefore(start) || !today.isAfter(end);
    }
  }
}

class StoreCampaignConfig {
  const StoreCampaignConfig({
    this.enabled,
    this.title,
    this.subtitle,
    this.availability,
  });

  final bool? enabled;
  final String? title;
  final String? subtitle;
  final StoreAvailability? availability;

  factory StoreCampaignConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const StoreCampaignConfig();
    }

    return StoreCampaignConfig(
      enabled: map['enabled'] as bool?,
      title: map['title']?.toString(),
      subtitle: map['subtitle']?.toString(),
      availability: StoreAvailability.fromMap(
        map['availability'] is Map<String, dynamic>
            ? map['availability'] as Map<String, dynamic>
            : null,
      ),
    );
  }

  StoreCampaignConfig merge(StoreCampaignConfig overlay) {
    return StoreCampaignConfig(
      enabled: overlay.enabled ?? enabled,
      title: overlay.title ?? title,
      subtitle: overlay.subtitle ?? subtitle,
      availability: overlay.availability ?? availability,
    );
  }

  bool isActive(DateTime now) {
    final resolvedTitle = title?.trim() ?? '';
    if (resolvedTitle.isEmpty) {
      return false;
    }
    return (enabled ?? true) &&
        (availability ?? const StoreAvailability.always()).isActive(now);
  }
}

class StoreOfferConfig {
  const StoreOfferConfig({
    this.enabled,
    this.badge,
    this.ctaLabel,
    this.coinPrice,
    this.baseCoinPrice,
    this.coinPriceStep,
    this.availability,
  });

  final bool? enabled;
  final String? badge;
  final String? ctaLabel;
  final int? coinPrice;
  final int? baseCoinPrice;
  final int? coinPriceStep;
  final StoreAvailability? availability;

  factory StoreOfferConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const StoreOfferConfig();
    }

    return StoreOfferConfig(
      enabled: map['enabled'] as bool?,
      badge: map['badge']?.toString(),
      ctaLabel: map['ctaLabel']?.toString(),
      coinPrice: (map['coinPrice'] as num?)?.toInt(),
      baseCoinPrice: (map['baseCoinPrice'] as num?)?.toInt(),
      coinPriceStep: (map['coinPriceStep'] as num?)?.toInt(),
      availability: StoreAvailability.fromMap(
        map['availability'] is Map<String, dynamic>
            ? map['availability'] as Map<String, dynamic>
            : null,
      ),
    );
  }

  StoreOfferConfig merge(StoreOfferConfig overlay) {
    return StoreOfferConfig(
      enabled: overlay.enabled ?? enabled,
      badge: overlay.badge ?? badge,
      ctaLabel: overlay.ctaLabel ?? ctaLabel,
      coinPrice: overlay.coinPrice ?? coinPrice,
      baseCoinPrice: overlay.baseCoinPrice ?? baseCoinPrice,
      coinPriceStep: overlay.coinPriceStep ?? coinPriceStep,
      availability: overlay.availability ?? availability,
    );
  }

  bool isActive(DateTime now) {
    return (enabled ?? true) &&
        (availability ?? const StoreAvailability.always()).isActive(now);
  }
}

class StorefrontConfig {
  const StorefrontConfig({
    this.campaign,
    this.offers = const <String, StoreOfferConfig>{},
  });

  final StoreCampaignConfig? campaign;
  final Map<String, StoreOfferConfig> offers;

  factory StorefrontConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const StorefrontConfig();
    }

    final rawOffers = map['offers'];
    final offers = <String, StoreOfferConfig>{};
    if (rawOffers is Map<String, dynamic>) {
      for (final entry in rawOffers.entries) {
        if (!StoreOfferIds.all.contains(entry.key)) {
          continue;
        }
        final rawValue = entry.value;
        if (rawValue is Map<String, dynamic>) {
          offers[entry.key] = StoreOfferConfig.fromMap(rawValue);
        }
      }
    }

    final rawCampaign = map['campaign'];
    return StorefrontConfig(
      campaign: rawCampaign is Map<String, dynamic>
          ? StoreCampaignConfig.fromMap(rawCampaign)
          : null,
      offers: offers,
    );
  }

  StorefrontConfig merge(StorefrontConfig overlay) {
    final mergedOffers = <String, StoreOfferConfig>{...offers};
    for (final entry in overlay.offers.entries) {
      final current = mergedOffers[entry.key];
      mergedOffers[entry.key] = current == null
          ? entry.value
          : current.merge(entry.value);
    }

    return StorefrontConfig(
      campaign: campaign == null
          ? overlay.campaign
          : overlay.campaign == null
          ? campaign
          : campaign!.merge(overlay.campaign!),
      offers: mergedOffers,
    );
  }

  StoreOfferConfig offer(String id) {
    return offers[id] ?? const StoreOfferConfig();
  }
}
