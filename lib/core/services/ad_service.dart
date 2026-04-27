import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';
  static const Duration _boardResetCooldown = Duration(seconds: 90);
  static const Duration _interstitialRepeatGrace = Duration(seconds: 10);

  Future<void>? _initializationFuture;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  bool _showingInterstitial = false;
  bool _showingRewarded = false;
  DateTime? _lastBoardResetInterstitialAt;
  DateTime? _lastInterstitialPresentedAt;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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
    if (!isSupportedPlatform) {
      return Future<void>.value();
    }
    return _initializationFuture ??= _initializeInternal();
  }

  Future<bool> maybeShowBoardResetInterstitial() async {
    if (boardResetCooldownRemaining > Duration.zero ||
        interstitialRepeatGraceRemaining > Duration.zero) {
      return false;
    }

    final shown = await showInterstitialAd();
    if (shown) {
      _lastBoardResetInterstitialAt = DateTime.now();
    }
    return shown;
  }

  Future<bool> maybeShowInterstitialAvoidingBackToBack() async {
    if (interstitialRepeatGraceRemaining > Duration.zero) {
      return false;
    }
    return showInterstitialAd();
  }

  Future<bool> showInterstitialAd() async {
    await initialize();
    if (!isSupportedPlatform || _showingInterstitial) {
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      _preloadInterstitial();
      return false;
    }

    final completer = Completer<bool>();
    var wasPresented = false;

    _showingInterstitial = true;
    _interstitialAd = null;
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
        _preloadInterstitial();
        if (!completer.isCompleted) {
          completer.complete(wasPresented);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show: $error');
        ad.dispose();
        _showingInterstitial = false;
        _preloadInterstitial();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    try {
      ad.show();
    } catch (error) {
      debugPrint('Interstitial show threw: $error');
      ad.dispose();
      _showingInterstitial = false;
      _preloadInterstitial();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  Future<bool> showRewardedAd() async {
    await initialize();
    if (!isSupportedPlatform || _showingRewarded) {
      return false;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      _preloadRewarded();
      return false;
    }

    final completer = Completer<bool>();
    var rewardEarned = false;

    _showingRewarded = true;
    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingRewarded = false;
        _preloadRewarded();
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _showingRewarded = false;
        _preloadRewarded();
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
      debugPrint('Rewarded ad show threw: $error');
      ad.dispose();
      _showingRewarded = false;
      _preloadRewarded();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  Future<void> _initializeInternal() async {
    try {
      await MobileAds.instance.initialize();
    } catch (error) {
      debugPrint('AdMob initialization failed: $error');
    }

    _preloadInterstitial();
    _preloadRewarded();
  }

  void _preloadInterstitial() {
    if (!isSupportedPlatform ||
        _loadingInterstitial ||
        _interstitialAd != null) {
      return;
    }

    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          ad.setImmersiveMode(true);
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  void _preloadRewarded() {
    if (!isSupportedPlatform || _loadingRewarded || _rewardedAd != null) {
      return;
    }

    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          ad.setImmersiveMode(true);
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }
}
