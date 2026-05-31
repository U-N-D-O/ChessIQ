import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum InterstitialPlacement {
  boardReset,
  versusBotMatchStart,
  academyBreak,
  academyReturn,
  quizMilestone,
}

extension InterstitialPlacementDetails on InterstitialPlacement {
  String get label => switch (this) {
    InterstitialPlacement.boardReset => 'Board reset',
    InterstitialPlacement.versusBotMatchStart => 'Vs Bot match start',
    InterstitialPlacement.academyBreak => 'Academy break',
    InterstitialPlacement.academyReturn => 'Academy return',
    InterstitialPlacement.quizMilestone => 'Quiz milestone',
  };
}

enum RewardedPlacement { storeReward, academyBonus }

extension RewardedPlacementDetails on RewardedPlacement {
  String get label => switch (this) {
    RewardedPlacement.storeReward => 'Store reward',
    RewardedPlacement.academyBonus => 'Academy bonus',
  };
}

enum RewardedInterstitialPlacement {
  quizMilestone,
  academyExamBonus,
  dailyChallenge,
}

extension RewardedInterstitialPlacementDetails
    on RewardedInterstitialPlacement {
  String get label => switch (this) {
    RewardedInterstitialPlacement.quizMilestone => 'Quiz milestone',
    RewardedInterstitialPlacement.academyExamBonus => 'Academy exam bonus',
    RewardedInterstitialPlacement.dailyChallenge => 'Daily challenge',
  };
}

enum RewardedInterstitialShowResult {
  unavailable,
  shownWithoutReward,
  rewardEarned,
}

extension RewardedInterstitialShowResultDetails
    on RewardedInterstitialShowResult {
  bool get wasPresented => this != RewardedInterstitialShowResult.unavailable;

  bool get rewardEarned => this == RewardedInterstitialShowResult.rewardEarned;
}

class AdService {
  AdService._();

  static final AdService instance = AdService._();
  static const bool _adsDisabled = bool.fromEnvironment('ADMOB_DISABLE');
  static const bool _forceTestAds = bool.fromEnvironment(
    'ADMOB_FORCE_TEST_ADS',
  );

  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _testRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/6978759866';
  static const String _iosDefaultInterstitialAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-8366041710010578/4392988454',
  );
  static const String _iosBoardResetInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_IOS_INTERSTITIAL_BOARD_RESET_AD_UNIT_ID',
        defaultValue: 'ca-app-pub-8366041710010578/4392988454',
      );
  static const String _iosVsBotInterstitialAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_VS_BOT_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-8366041710010578/5329949968',
  );
  static const String _iosAcademyBreakInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_IOS_INTERSTITIAL_ACADEMY_BREAK_AD_UNIT_ID',
        defaultValue: 'ca-app-pub-8366041710010578/2781019694',
      );
  static const String _iosAcademyReturnInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_IOS_INTERSTITIAL_ACADEMY_RETURN_AD_UNIT_ID',
        defaultValue: 'ca-app-pub-8366041710010578/9294457153',
      );
  static const String _iosQuizMilestoneInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_IOS_INTERSTITIAL_QUIZ_MILESTONE_AD_UNIT_ID',
        defaultValue: 'ca-app-pub-8366041710010578/3746617002',
      );
  static const String _iosDefaultRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-8366041710010578/4229336921',
  );
  static const String _iosStoreRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_STORE_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-8366041710010578/4229336921',
  );
  static const String _iosAcademyRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ACADEMY_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-8366041710010578/6532562448',
  );
  static const String _iosDefaultRewardedInterstitialAdUnitId =
      String.fromEnvironment('ADMOB_IOS_REWARDED_INTERSTITIAL_AD_UNIT_ID');
  static const String _iosQuizMilestoneRewardedInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_IOS_REWARDED_INTERSTITIAL_QUIZ_MILESTONE_AD_UNIT_ID',
      );
  static const String _iosAcademyExamBonusRewardedInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_IOS_REWARDED_INTERSTITIAL_ACADEMY_EXAM_BONUS_AD_UNIT_ID',
      );
  static const String _iosDailyChallengeRewardedInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_IOS_REWARDED_INTERSTITIAL_DAILY_CHALLENGE_AD_UNIT_ID',
      );
  static const String _androidDefaultInterstitialAdUnitId =
      String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL_AD_UNIT_ID');
  static const String _androidBoardResetInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_ANDROID_INTERSTITIAL_BOARD_RESET_AD_UNIT_ID',
      );
  static const String _androidVsBotInterstitialAdUnitId =
      String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL_VS_BOT_AD_UNIT_ID');
  static const String _androidAcademyBreakInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_ANDROID_INTERSTITIAL_ACADEMY_BREAK_AD_UNIT_ID',
      );
  static const String _androidAcademyReturnInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_ANDROID_INTERSTITIAL_ACADEMY_RETURN_AD_UNIT_ID',
      );
  static const String _androidQuizMilestoneInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_ANDROID_INTERSTITIAL_QUIZ_MILESTONE_AD_UNIT_ID',
      );
  static const String _androidDefaultRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_AD_UNIT_ID',
  );
  static const String _androidStoreRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_STORE_AD_UNIT_ID',
  );
  static const String _androidAcademyRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ACADEMY_AD_UNIT_ID',
  );
  static const String _androidDefaultRewardedInterstitialAdUnitId =
      String.fromEnvironment('ADMOB_ANDROID_REWARDED_INTERSTITIAL_AD_UNIT_ID');
  static const String _androidQuizMilestoneRewardedInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_ANDROID_REWARDED_INTERSTITIAL_QUIZ_MILESTONE_AD_UNIT_ID',
      );
  static const String _androidAcademyExamBonusRewardedInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_ANDROID_REWARDED_INTERSTITIAL_ACADEMY_EXAM_BONUS_AD_UNIT_ID',
      );
  static const String _androidDailyChallengeRewardedInterstitialAdUnitId =
      String.fromEnvironment(
        'ADMOB_ANDROID_REWARDED_INTERSTITIAL_DAILY_CHALLENGE_AD_UNIT_ID',
      );
  static const Duration _boardResetCooldown = Duration(seconds: 90);
  static const Duration _interstitialRepeatGrace = Duration(seconds: 10);

  Future<void>? _initializationFuture;
  final Map<String, InterstitialAd> _interstitialAds =
      <String, InterstitialAd>{};
  final Set<String> _loadingInterstitialAdUnitIds = <String>{};
  final Map<String, RewardedAd> _rewardedAds = <String, RewardedAd>{};
  final Set<String> _loadingRewardedAdUnitIds = <String>{};
  final Map<String, RewardedInterstitialAd> _rewardedInterstitialAds =
      <String, RewardedInterstitialAd>{};
  final Set<String> _loadingRewardedInterstitialAdUnitIds = <String>{};
  bool _showingInterstitial = false;
  bool _showingRewarded = false;
  bool _showingRewardedInterstitial = false;
  DateTime? _lastBoardResetInterstitialAt;
  DateTime? _lastInterstitialPresentedAt;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isEnabled => isSupportedPlatform && !_adsDisabled;

  Duration get boardResetCooldownRemaining {
    final lastShownAt = _lastBoardResetInterstitialAt;
    if (lastShownAt == null) {
      return Duration.zero;
    }
    final remaining = lastShownAt
        .add(_boardResetCooldown)
        .difference(DateTime.now());
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  Duration get interstitialRepeatGraceRemaining {
    final lastPresentedAt = _lastInterstitialPresentedAt;
    if (lastPresentedAt == null) {
      return Duration.zero;
    }
    final remaining = lastPresentedAt
        .add(_interstitialRepeatGrace)
        .difference(DateTime.now());
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  Future<void> initialize() {
    if (!isEnabled) {
      return Future<void>.value();
    }
    return _initializationFuture ??= _initializeInternal();
  }

  Future<bool> maybeShowBoardResetInterstitial() async {
    if (boardResetCooldownRemaining > Duration.zero ||
        interstitialRepeatGraceRemaining > Duration.zero) {
      return false;
    }

    final shown = await showInterstitialAd(
      placement: InterstitialPlacement.boardReset,
    );
    if (shown) {
      _lastBoardResetInterstitialAt = DateTime.now();
    }
    return shown;
  }

  Future<bool> maybeShowInterstitialAvoidingBackToBack({
    required InterstitialPlacement placement,
  }) async {
    if (interstitialRepeatGraceRemaining > Duration.zero) {
      return false;
    }
    return showInterstitialAd(placement: placement);
  }

  Future<bool> showInterstitialAd({
    required InterstitialPlacement placement,
  }) async {
    if (!isEnabled || _showingInterstitial) {
      return false;
    }
    await initialize();

    final adUnitId = _interstitialAdUnitIdFor(placement);
    if (adUnitId == null) {
      return false;
    }

    final ad = _interstitialAds.remove(adUnitId);
    if (ad == null) {
      _preloadInterstitial(adUnitId);
      return false;
    }

    final completer = Completer<bool>();
    var wasPresented = false;

    _showingInterstitial = true;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        wasPresented = true;
        _lastInterstitialPresentedAt = DateTime.now();
      },
      onAdImpression: (_) {
        wasPresented = true;
        _lastInterstitialPresentedAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingInterstitial = false;
        _preloadInterstitial(adUnitId);
        if (!completer.isCompleted) {
          completer.complete(wasPresented);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('${placement.label} interstitial failed to show: $error');
        ad.dispose();
        _showingInterstitial = false;
        _preloadInterstitial(adUnitId);
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    try {
      ad.show();
    } catch (error) {
      debugPrint('${placement.label} interstitial show threw: $error');
      ad.dispose();
      _showingInterstitial = false;
      _preloadInterstitial(adUnitId);
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  Future<bool> showRewardedAd({required RewardedPlacement placement}) async {
    if (!isEnabled ||
        _showingInterstitial ||
        _showingRewarded ||
        _showingRewardedInterstitial) {
      return false;
    }
    await initialize();

    final adUnitId = _rewardedAdUnitIdFor(placement);
    if (adUnitId == null) {
      return false;
    }

    final ad = _rewardedAds.remove(adUnitId);
    if (ad == null) {
      _preloadRewarded(adUnitId);
      return false;
    }

    final completer = Completer<bool>();
    var rewardEarned = false;

    _showingRewarded = true;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingRewarded = false;
        _preloadRewarded(adUnitId);
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('${placement.label} rewarded ad failed to show: $error');
        ad.dispose();
        _showingRewarded = false;
        _preloadRewarded(adUnitId);
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    try {
      ad.show(
        onUserEarnedReward: (_, _) {
          rewardEarned = true;
        },
      );
    } catch (error) {
      debugPrint('${placement.label} rewarded ad show threw: $error');
      ad.dispose();
      _showingRewarded = false;
      _preloadRewarded(adUnitId);
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  Future<RewardedInterstitialShowResult> showRewardedInterstitialAd({
    required RewardedInterstitialPlacement placement,
  }) async {
    if (!isEnabled ||
        _showingInterstitial ||
        _showingRewarded ||
        _showingRewardedInterstitial) {
      return RewardedInterstitialShowResult.unavailable;
    }
    await initialize();

    final adUnitId = _rewardedInterstitialAdUnitIdFor(placement);
    if (adUnitId == null) {
      return RewardedInterstitialShowResult.unavailable;
    }

    final ad = _rewardedInterstitialAds.remove(adUnitId);
    if (ad == null) {
      _preloadRewardedInterstitial(adUnitId);
      return RewardedInterstitialShowResult.unavailable;
    }

    final completer = Completer<RewardedInterstitialShowResult>();
    var rewardEarned = false;

    _showingRewardedInterstitial = true;
    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedInterstitialAd>(
          onAdShowedFullScreenContent: (_) {
            _lastInterstitialPresentedAt = DateTime.now();
          },
          onAdImpression: (_) {
            _lastInterstitialPresentedAt = DateTime.now();
          },
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _showingRewardedInterstitial = false;
            _preloadRewardedInterstitial(adUnitId);
            if (!completer.isCompleted) {
              completer.complete(
                rewardEarned
                    ? RewardedInterstitialShowResult.rewardEarned
                    : RewardedInterstitialShowResult.shownWithoutReward,
              );
            }
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint(
              '${placement.label} rewarded interstitial failed to show: '
              '$error',
            );
            ad.dispose();
            _showingRewardedInterstitial = false;
            _preloadRewardedInterstitial(adUnitId);
            if (!completer.isCompleted) {
              completer.complete(RewardedInterstitialShowResult.unavailable);
            }
          },
        );

    try {
      ad.show(
        onUserEarnedReward: (_, _) {
          rewardEarned = true;
        },
      );
    } catch (error) {
      debugPrint('${placement.label} rewarded interstitial show threw: $error');
      ad.dispose();
      _showingRewardedInterstitial = false;
      _preloadRewardedInterstitial(adUnitId);
      if (!completer.isCompleted) {
        completer.complete(RewardedInterstitialShowResult.unavailable);
      }
    }

    return completer.future;
  }

  Future<void> _initializeInternal() async {
    if (!isEnabled) {
      return;
    }

    try {
      await MobileAds.instance.initialize();
    } catch (error) {
      debugPrint('AdMob initialization failed: $error');
    }

    final interstitialAdUnitIds = <String>{
      for (final placement in InterstitialPlacement.values)
        if (_interstitialAdUnitIdFor(placement) case final String adUnitId)
          adUnitId,
    };
    for (final adUnitId in interstitialAdUnitIds) {
      _preloadInterstitial(adUnitId);
    }

    final rewardedAdUnitIds = <String>{
      for (final placement in RewardedPlacement.values)
        if (_rewardedAdUnitIdFor(placement) case final String adUnitId)
          adUnitId,
    };
    for (final adUnitId in rewardedAdUnitIds) {
      _preloadRewarded(adUnitId);
    }

    final rewardedInterstitialAdUnitIds = <String>{
      for (final placement in RewardedInterstitialPlacement.values)
        if (_rewardedInterstitialAdUnitIdFor(placement)
            case final String adUnitId)
          adUnitId,
    };
    for (final adUnitId in rewardedInterstitialAdUnitIds) {
      _preloadRewardedInterstitial(adUnitId);
    }
  }

  String? _interstitialAdUnitIdFor(InterstitialPlacement placement) {
    final iosAdUnitId = switch (placement) {
      InterstitialPlacement.boardReset => _firstConfigured(
        _iosBoardResetInterstitialAdUnitId,
        _iosDefaultInterstitialAdUnitId,
      ),
      InterstitialPlacement.versusBotMatchStart => _firstConfigured(
        _iosVsBotInterstitialAdUnitId,
        _iosDefaultInterstitialAdUnitId,
      ),
      InterstitialPlacement.academyBreak => _firstConfigured(
        _iosAcademyBreakInterstitialAdUnitId,
        _iosDefaultInterstitialAdUnitId,
      ),
      InterstitialPlacement.academyReturn => _firstConfigured(
        _iosAcademyReturnInterstitialAdUnitId,
        _iosDefaultInterstitialAdUnitId,
      ),
      InterstitialPlacement.quizMilestone => _firstConfigured(
        _iosQuizMilestoneInterstitialAdUnitId,
        _iosDefaultInterstitialAdUnitId,
      ),
    };
    final androidAdUnitId = switch (placement) {
      InterstitialPlacement.boardReset => _firstConfigured(
        _androidBoardResetInterstitialAdUnitId,
        _androidDefaultInterstitialAdUnitId,
      ),
      InterstitialPlacement.versusBotMatchStart => _firstConfigured(
        _androidVsBotInterstitialAdUnitId,
        _androidDefaultInterstitialAdUnitId,
      ),
      InterstitialPlacement.academyBreak => _firstConfigured(
        _androidAcademyBreakInterstitialAdUnitId,
        _androidDefaultInterstitialAdUnitId,
      ),
      InterstitialPlacement.academyReturn => _firstConfigured(
        _androidAcademyReturnInterstitialAdUnitId,
        _androidDefaultInterstitialAdUnitId,
      ),
      InterstitialPlacement.quizMilestone => _firstConfigured(
        _androidQuizMilestoneInterstitialAdUnitId,
        _androidDefaultInterstitialAdUnitId,
      ),
    };

    return _resolveAdUnitId(
      formatLabel: '${placement.label} interstitial',
      testAdUnitId: _testInterstitialAdUnitId,
      iosAdUnitId: iosAdUnitId,
      androidAdUnitId: androidAdUnitId,
    );
  }

  String? _rewardedAdUnitIdFor(RewardedPlacement placement) {
    final iosAdUnitId = switch (placement) {
      RewardedPlacement.storeReward => _firstConfigured(
        _iosStoreRewardedAdUnitId,
        _iosDefaultRewardedAdUnitId,
      ),
      RewardedPlacement.academyBonus => _firstConfigured(
        _iosAcademyRewardedAdUnitId,
        _iosDefaultRewardedAdUnitId,
      ),
    };
    final androidAdUnitId = switch (placement) {
      RewardedPlacement.storeReward => _firstConfigured(
        _androidStoreRewardedAdUnitId,
        _androidDefaultRewardedAdUnitId,
      ),
      RewardedPlacement.academyBonus => _firstConfigured(
        _androidAcademyRewardedAdUnitId,
        _androidDefaultRewardedAdUnitId,
      ),
    };

    return _resolveAdUnitId(
      formatLabel: '${placement.label} rewarded',
      testAdUnitId: _testRewardedAdUnitId,
      iosAdUnitId: iosAdUnitId,
      androidAdUnitId: androidAdUnitId,
    );
  }

  String? _rewardedInterstitialAdUnitIdFor(
    RewardedInterstitialPlacement placement,
  ) {
    final iosAdUnitId = switch (placement) {
      RewardedInterstitialPlacement.quizMilestone => _firstConfigured(
        _iosQuizMilestoneRewardedInterstitialAdUnitId,
        _iosDefaultRewardedInterstitialAdUnitId,
      ),
      RewardedInterstitialPlacement.academyExamBonus => _firstConfigured(
        _iosAcademyExamBonusRewardedInterstitialAdUnitId,
        _iosDefaultRewardedInterstitialAdUnitId,
      ),
      RewardedInterstitialPlacement.dailyChallenge => _firstConfigured(
        _iosDailyChallengeRewardedInterstitialAdUnitId,
        _iosDefaultRewardedInterstitialAdUnitId,
      ),
    };
    final androidAdUnitId = switch (placement) {
      RewardedInterstitialPlacement.quizMilestone => _firstConfigured(
        _androidQuizMilestoneRewardedInterstitialAdUnitId,
        _androidDefaultRewardedInterstitialAdUnitId,
      ),
      RewardedInterstitialPlacement.academyExamBonus => _firstConfigured(
        _androidAcademyExamBonusRewardedInterstitialAdUnitId,
        _androidDefaultRewardedInterstitialAdUnitId,
      ),
      RewardedInterstitialPlacement.dailyChallenge => _firstConfigured(
        _androidDailyChallengeRewardedInterstitialAdUnitId,
        _androidDefaultRewardedInterstitialAdUnitId,
      ),
    };

    return _resolveAdUnitId(
      formatLabel: '${placement.label} rewarded interstitial',
      testAdUnitId: _testRewardedInterstitialAdUnitId,
      iosAdUnitId: iosAdUnitId,
      androidAdUnitId: androidAdUnitId,
    );
  }

  String _firstConfigured(String primary, String fallback) {
    if (primary.isNotEmpty) {
      return primary;
    }
    return fallback;
  }

  String? _resolveAdUnitId({
    required String formatLabel,
    required String testAdUnitId,
    required String iosAdUnitId,
    required String androidAdUnitId,
  }) {
    if (!isEnabled) {
      return null;
    }

    if (_forceTestAds || !kReleaseMode) {
      return testAdUnitId;
    }

    final configuredAdUnitId = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => iosAdUnitId,
      TargetPlatform.android => androidAdUnitId,
      _ => '',
    };

    if (configuredAdUnitId.isNotEmpty) {
      return configuredAdUnitId;
    }

    debugPrint(
      'Missing $formatLabel AdMob unit ID for $defaultTargetPlatform '
      'release build. Set the matching ADMOB_* dart-define.',
    );
    return null;
  }

  void _preloadInterstitial(String adUnitId) {
    if (!isEnabled ||
        _loadingInterstitialAdUnitIds.contains(adUnitId) ||
        _interstitialAds.containsKey(adUnitId)) {
      return;
    }

    _loadingInterstitialAdUnitIds.add(adUnitId);
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitialAdUnitIds.remove(adUnitId);
          ad.setImmersiveMode(true);
          final previousAd = _interstitialAds.remove(adUnitId);
          previousAd?.dispose();
          _interstitialAds[adUnitId] = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitialAdUnitIds.remove(adUnitId);
          debugPrint('Interstitial failed to load for $adUnitId: $error');
        },
      ),
    );
  }

  void _preloadRewarded(String adUnitId) {
    if (!isEnabled ||
        _loadingRewardedAdUnitIds.contains(adUnitId) ||
        _rewardedAds.containsKey(adUnitId)) {
      return;
    }

    _loadingRewardedAdUnitIds.add(adUnitId);
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewardedAdUnitIds.remove(adUnitId);
          ad.setImmersiveMode(true);
          final previousAd = _rewardedAds.remove(adUnitId);
          previousAd?.dispose();
          _rewardedAds[adUnitId] = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingRewardedAdUnitIds.remove(adUnitId);
          debugPrint('Rewarded ad failed to load for $adUnitId: $error');
        },
      ),
    );
  }

  void _preloadRewardedInterstitial(String adUnitId) {
    if (!isEnabled ||
        _loadingRewardedInterstitialAdUnitIds.contains(adUnitId) ||
        _rewardedInterstitialAds.containsKey(adUnitId)) {
      return;
    }

    _loadingRewardedInterstitialAdUnitIds.add(adUnitId);
    RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewardedInterstitialAdUnitIds.remove(adUnitId);
          ad.setImmersiveMode(true);
          final previousAd = _rewardedInterstitialAds.remove(adUnitId);
          previousAd?.dispose();
          _rewardedInterstitialAds[adUnitId] = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingRewardedInterstitialAdUnitIds.remove(adUnitId);
          debugPrint(
            'Rewarded interstitial failed to load for $adUnitId: $error',
          );
        },
      ),
    );
  }
}
