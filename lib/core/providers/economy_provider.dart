import 'dart:math';

import 'package:chessiq/core/services/economy_remote_service.dart';
import 'package:chessiq/core/services/local_integrity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EconomyProvider extends ChangeNotifier {
  static const String storeStateKey = 'store_state_v1';
  static const String _storeIntegrityScope = 'economy_store';
  static const String storeRewardAdLastWatchKey =
      'store_reward_ad_last_watch_v1';
  static const String storeRewardAdWatchCountTodayKey =
      'store_reward_ad_watch_count_today_v1';
  static const String storeRewardAdLastWatchDayKey =
      'store_reward_ad_last_watch_day_v1';
  static const String storeRewardAdMaxSeenTimeKey =
      'store_reward_ad_max_seen_time_v1';
  static const int academyInterstitialRewardCoins = 10;
  static const int storeRewardCoins = 120;
  static const int defaultCoins = 120;
  static const bool _allowLocalFallbackForTests = !kReleaseMode;

  // Progressive cooldowns: 5min, 15min, 30min, then locked until next UTC day.
  static const List<Duration> progressiveCooldowns = [
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  int _coins = defaultCoins;
  DateTime? _lastStoreRewardAdAt;
  int _watchCountToday = 0;
  String _lastWatchDay = '';
  DateTime _maxSeenDeviceTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _loaded = false;

  int get coins => _coins;
  bool get loaded => _loaded;
  DateTime? get lastStoreRewardAdAt => _lastStoreRewardAdAt;
  int get watchCountToday => _watchCountToday;
  bool get storeRewardLockedUntilTomorrow {
    final now = _trustedNow();
    _rollStoreRewardDayIfNeeded(now);
    return _watchCountToday >= 3;
  }

  Duration get _currentCooldownDuration {
    return progressiveCooldowns[_watchCountToday.clamp(
      0,
      progressiveCooldowns.length - 1,
    )];
  }

  Duration get remainingStoreRewardCooldown {
    final lastWatch = _lastStoreRewardAdAt;
    if (lastWatch == null) {
      return Duration.zero;
    }
    final now = _trustedNow();
    _rollStoreRewardDayIfNeeded(now);

    if (_watchCountToday >= 3) {
      final utcNow = now.toUtc();
      final midnight = DateTime.utc(utcNow.year, utcNow.month, utcNow.day + 1);
      final remaining = midnight.difference(utcNow);
      if (remaining.isNegative) {
        return Duration.zero;
      }
      return remaining;
    }

    final remaining = lastWatch.add(_currentCooldownDuration).difference(now);
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  bool get canClaimStoreReward => remainingStoreRewardCooldown == Duration.zero;

  Future<void> load() async {
    await refresh();
  }

  Future<void> refresh({bool notify = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _readStorePayload(prefs);
    final localCoins = max(
      0,
      (payload['coins'] as num?)?.toInt() ?? defaultCoins,
    );
    final lastWatchMs = prefs.getInt(storeRewardAdLastWatchKey);
    final localLastWatch = lastWatchMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastWatchMs);
    final maxSeenMs = prefs.getInt(storeRewardAdMaxSeenTimeKey);
    if (maxSeenMs != null) {
      _maxSeenDeviceTime = DateTime.fromMillisecondsSinceEpoch(maxSeenMs);
    }

    final trustedNow = _trustedNow();
    final todayStr = _dayStamp(trustedNow);
    final savedLastWatchDay =
        prefs.getString(storeRewardAdLastWatchDayKey) ?? '';
    var localWatchCountToday =
        prefs.getInt(storeRewardAdWatchCountTodayKey) ?? 0;
    var localLastWatchDay = savedLastWatchDay;
    if (savedLastWatchDay != todayStr && savedLastWatchDay.isNotEmpty) {
      localWatchCountToday = 0;
      localLastWatchDay = todayStr;
    } else if (savedLastWatchDay.isEmpty) {
      localLastWatchDay = todayStr;
    }

    EconomySnapshot? authoritativeSnapshot;
    try {
      authoritativeSnapshot = await EconomyRemoteService.instance.fetchState(
        migrationCoins: localCoins,
      );
    } catch (error) {
      debugPrint('Economy refresh falling back to local mirror: $error');
    }

    if (authoritativeSnapshot != null) {
      final changed = _snapshotChanged(authoritativeSnapshot);
      _applySnapshot(authoritativeSnapshot);
      await _persistLocalMirror(authoritativeSnapshot, prefs: prefs);
      if (notify && changed) {
        notifyListeners();
      }
      return;
    }

    final changed =
        !_loaded ||
        localCoins != _coins ||
        localLastWatch?.millisecondsSinceEpoch !=
            _lastStoreRewardAdAt?.millisecondsSinceEpoch ||
        localWatchCountToday != _watchCountToday ||
        localLastWatchDay != _lastWatchDay;

    _coins = localCoins;
    _lastStoreRewardAdAt = localLastWatch;
    _watchCountToday = localWatchCountToday;
    _lastWatchDay = localLastWatchDay;
    _loaded = true;

    await prefs.setInt(
      storeRewardAdMaxSeenTimeKey,
      _maxSeenDeviceTime.millisecondsSinceEpoch,
    );

    if (notify && changed) {
      notifyListeners();
    }
  }

  Future<void> replaceCoinsFromTrustedSource(
    int value, {
    bool notify = true,
  }) async {
    final normalized = max(0, value);
    final changed = !_loaded || normalized != _coins;

    _coins = normalized;
    _loaded = true;

    await _persistStorePayload((payload) {
      payload['coins'] = normalized;
      return payload;
    });

    if (notify && changed) {
      notifyListeners();
    }
  }

  Future<bool> spendCoins(int amount, {bool notify = true}) async {
    if (amount <= 0) {
      return true;
    }
    try {
      final result = await EconomyRemoteService.instance.spendCoins(amount);
      await _applyRemoteMutation(result, notify: notify);
      return result.success;
    } catch (error) {
      debugPrint('Economy spend failed: $error');
      if (_allowLocalFallbackForTests) {
        if (_coins < amount) {
          return false;
        }
        await replaceCoinsFromTrustedSource(_coins - amount, notify: notify);
        return true;
      }
      return false;
    }
  }

  Future<bool> claimAnalysisInterstitialCoins({bool notify = true}) async {
    return _claimReward(EconomyRewardKey.analysisInterstitial, notify: notify);
  }

  Future<bool> awardAcademyInterstitialCoins({bool notify = true}) async {
    return _claimReward(EconomyRewardKey.academyInterstitial, notify: notify);
  }

  Future<bool> claimAcademyExamBonusCoins({
    required String claimKey,
    bool notify = true,
  }) async {
    return _claimReward(
      EconomyRewardKey.academyExamBonus,
      claimKey: claimKey,
      notify: notify,
    );
  }

  Future<bool> claimDailyPuzzleCoins({
    required String claimKey,
    bool notify = true,
  }) async {
    return _claimReward(
      EconomyRewardKey.academyDailyPuzzle,
      claimKey: claimKey,
      notify: notify,
    );
  }

  Future<bool> claimAcademyRewardedAdCoins({bool notify = true}) async {
    return _claimReward(EconomyRewardKey.academyRewardedAd, notify: notify);
  }

  Future<bool> claimDailyChallengeCoins({
    required String claimKey,
    bool notify = true,
  }) async {
    return _claimReward(
      EconomyRewardKey.academyDailyChallenge,
      claimKey: claimKey,
      notify: notify,
    );
  }

  Future<bool> deliverPurchasedCoinPack(
    String productId, {
    required String fingerprint,
    bool notify = true,
  }) async {
    final rewardKey = switch (productId) {
      'com.qila.chessiq.coins_s' => EconomyRewardKey.purchaseCoinPackS,
      'com.qila.chessiq.coins_l' => EconomyRewardKey.purchaseCoinPackL,
      _ => null,
    };
    if (rewardKey == null) {
      return false;
    }

    try {
      final result = await EconomyRemoteService.instance.grantReward(
        rewardKey,
        fingerprint: fingerprint,
      );
      await _applyRemoteMutation(result, notify: notify);
      return result.success || result.reason == 'duplicate-delivery';
    } catch (error) {
      debugPrint('Purchase coin delivery failed: $error');
      if (_allowLocalFallbackForTests) {
        final amount = rewardKey == EconomyRewardKey.purchaseCoinPackS
            ? 1500
            : 5000;
        await replaceCoinsFromTrustedSource(_coins + amount, notify: notify);
        return true;
      }
      return false;
    }
  }

  Future<bool> claimStoreRewardAd({bool notify = true}) async {
    try {
      final result = await EconomyRemoteService.instance.claimStoreRewardAd();
      await _applyRemoteMutation(result, notify: notify);
      return result.success;
    } catch (error) {
      debugPrint('Store reward claim failed: $error');
      if (_allowLocalFallbackForTests) {
        final now = _trustedNow();
        _rollStoreRewardDayIfNeeded(now);
        if (!canClaimStoreReward) {
          return false;
        }

        _lastStoreRewardAdAt = now;
        _coins = max(0, _coins + storeRewardCoins);
        final todayStr = _dayStamp(now);
        if (_lastWatchDay != todayStr) {
          _watchCountToday = 1;
          _lastWatchDay = todayStr;
        } else {
          _watchCountToday++;
        }
        _loaded = true;
        await _persistLocalMirror(
          EconomySnapshot(
            coins: _coins,
            lastStoreRewardAdAt: _lastStoreRewardAdAt,
            watchCountToday: _watchCountToday,
            lastWatchDay: _lastWatchDay,
          ),
        );
        if (notify) {
          notifyListeners();
        }
        return true;
      }
      return false;
    }
  }

  Future<void> reset({
    int coins = 0,
    bool clearStoreRewardCooldown = false,
    bool notify = true,
  }) async {
    _coins = max(0, coins);
    _loaded = true;
    if (clearStoreRewardCooldown) {
      _lastStoreRewardAdAt = null;
    }

    await _persistStorePayload((payload) {
      payload['coins'] = _coins;
      return payload;
    });

    final prefs = await SharedPreferences.getInstance();
    if (clearStoreRewardCooldown) {
      await prefs.remove(storeRewardAdLastWatchKey);
      await prefs.remove(storeRewardAdWatchCountTodayKey);
      await prefs.remove(storeRewardAdLastWatchDayKey);
      _watchCountToday = 0;
      _lastWatchDay = '';
    } else if (_lastStoreRewardAdAt != null) {
      await prefs.setInt(
        storeRewardAdLastWatchKey,
        _lastStoreRewardAdAt!.millisecondsSinceEpoch,
      );
      await prefs.setInt(storeRewardAdWatchCountTodayKey, _watchCountToday);
      await prefs.setString(storeRewardAdLastWatchDayKey, _lastWatchDay);
    }

    _maxSeenDeviceTime = _trustedNow();
    await prefs.setInt(
      storeRewardAdMaxSeenTimeKey,
      _maxSeenDeviceTime.millisecondsSinceEpoch,
    );

    if (notify) {
      notifyListeners();
    }
  }

  bool _snapshotChanged(EconomySnapshot snapshot) {
    return !_loaded ||
        snapshot.coins != _coins ||
        snapshot.lastStoreRewardAdAt?.millisecondsSinceEpoch !=
            _lastStoreRewardAdAt?.millisecondsSinceEpoch ||
        snapshot.watchCountToday != _watchCountToday ||
        snapshot.lastWatchDay != _lastWatchDay;
  }

  void _applySnapshot(EconomySnapshot snapshot) {
    _coins = max(0, snapshot.coins);
    _lastStoreRewardAdAt = snapshot.lastStoreRewardAdAt;
    _watchCountToday = max(0, snapshot.watchCountToday);
    _lastWatchDay = snapshot.lastWatchDay;
    _loaded = true;
  }

  Future<void> _applyRemoteMutation(
    EconomyMutationResult result, {
    required bool notify,
  }) async {
    final changed = _snapshotChanged(result.snapshot);
    _applySnapshot(result.snapshot);
    await _persistLocalMirror(result.snapshot);
    if (notify && changed) {
      notifyListeners();
    }
  }

  Future<bool> _claimReward(
    EconomyRewardKey rewardKey, {
    String? claimKey,
    bool notify = true,
  }) async {
    try {
      final result = await EconomyRemoteService.instance.grantReward(
        rewardKey,
        claimKey: claimKey,
      );
      await _applyRemoteMutation(result, notify: notify);
      return result.success;
    } catch (error) {
      debugPrint('Economy reward claim failed: $error');
      if (_allowLocalFallbackForTests) {
        await replaceCoinsFromTrustedSource(
          _coins + _localRewardAmount(rewardKey),
          notify: notify,
        );
        return true;
      }
      return false;
    }
  }

  int _localRewardAmount(EconomyRewardKey rewardKey) {
    switch (rewardKey) {
      case EconomyRewardKey.analysisInterstitial:
      case EconomyRewardKey.academyInterstitial:
      case EconomyRewardKey.academyRewardedAd:
        return 10;
      case EconomyRewardKey.academyExamBonus:
        return 50;
      case EconomyRewardKey.academyDailyPuzzle:
        return 40;
      case EconomyRewardKey.academyDailyChallenge:
        return 200;
      case EconomyRewardKey.purchaseCoinPackS:
        return 1500;
      case EconomyRewardKey.purchaseCoinPackL:
        return 5000;
    }
  }

  Map<String, dynamic> _readStorePayload(SharedPreferences prefs) {
    final signed = LocalIntegrityService.decodeJson(
      prefs.getString(storeStateKey),
      scope: _storeIntegrityScope,
    );
    if (signed.data == null) {
      return <String, dynamic>{};
    }

    if (signed.isSigned && !signed.isValid) {
      return <String, dynamic>{};
    }

    return signed.data!;
  }

  Future<void> _persistStorePayload(
    Map<String, dynamic> Function(Map<String, dynamic>) update,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final nextPayload = update(_readStorePayload(prefs));
    await prefs.setString(
      storeStateKey,
      LocalIntegrityService.wrapJson(nextPayload, scope: _storeIntegrityScope),
    );
  }

  Future<void> _persistLocalMirror(
    EconomySnapshot snapshot, {
    SharedPreferences? prefs,
  }) async {
    final sharedPrefs = prefs ?? await SharedPreferences.getInstance();
    await _persistStorePayload((payload) {
      payload['coins'] = max(0, snapshot.coins);
      return payload;
    });

    if (snapshot.lastStoreRewardAdAt == null) {
      await sharedPrefs.remove(storeRewardAdLastWatchKey);
    } else {
      await sharedPrefs.setInt(
        storeRewardAdLastWatchKey,
        snapshot.lastStoreRewardAdAt!.millisecondsSinceEpoch,
      );
    }
    await sharedPrefs.setInt(
      storeRewardAdWatchCountTodayKey,
      max(0, snapshot.watchCountToday),
    );
    await sharedPrefs.setString(
      storeRewardAdLastWatchDayKey,
      snapshot.lastWatchDay,
    );
    _maxSeenDeviceTime = _trustedNow();
    await sharedPrefs.setInt(
      storeRewardAdMaxSeenTimeKey,
      _maxSeenDeviceTime.millisecondsSinceEpoch,
    );
  }

  String _dayStamp(DateTime value) {
    final utc = value.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime _trustedNow() {
    final now = DateTime.now();
    if (_maxSeenDeviceTime.isAfter(now)) {
      return _maxSeenDeviceTime;
    }
    _maxSeenDeviceTime = now;
    return now;
  }

  void _rollStoreRewardDayIfNeeded(DateTime now) {
    final today = _dayStamp(now);
    if (_lastWatchDay == today) {
      return;
    }
    _watchCountToday = 0;
    _lastWatchDay = today;
  }
}
