import 'dart:math';

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
  static const int academyInterstitialRewardCoins = 10;
  static const int storeRewardCoins = 120;
  static const int defaultCoins = 120;

  // Progressive cooldowns: 5min, 15min, 30min, then locked until next day
  static const List<Duration> progressiveCooldowns = [
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  int _coins = defaultCoins;
  DateTime? _lastStoreRewardAdAt;
  int _watchCountToday = 0;
  String _lastWatchDay = '';
  bool _loaded = false;

  int get coins => _coins;
  bool get loaded => _loaded;
  DateTime? get lastStoreRewardAdAt => _lastStoreRewardAdAt;
  int get watchCountToday => _watchCountToday;

  Duration get _currentCooldownDuration {
    // If already watched 3 times today, locked until tomorrow
    if (_watchCountToday >= 3) {
      return const Duration(days: 1);
    }
    // Use progressive cooldown based on watch count
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
    // Check if day has changed, reset watch count if so
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (_lastWatchDay != todayStr) {
      _watchCountToday = 0;
      _lastWatchDay = todayStr;
    }

    final remaining = lastWatch
        .add(_currentCooldownDuration)
        .difference(DateTime.now());
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
    final nextCoins = max(
      0,
      (payload['coins'] as num?)?.toInt() ?? defaultCoins,
    );
    final lastWatchMs = prefs.getInt(storeRewardAdLastWatchKey);
    final nextLastWatch = lastWatchMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastWatchMs);

    // Load watch count and last watch day
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final savedLastWatchDay =
        prefs.getString(storeRewardAdLastWatchDayKey) ?? '';
    int nextWatchCountToday =
        prefs.getInt(storeRewardAdWatchCountTodayKey) ?? 0;

    // Reset watch count if day has changed
    String nextLastWatchDay = savedLastWatchDay;
    if (savedLastWatchDay != todayStr && savedLastWatchDay.isNotEmpty) {
      nextWatchCountToday = 0;
      nextLastWatchDay = todayStr;
    } else if (savedLastWatchDay.isEmpty) {
      nextLastWatchDay = todayStr;
    }

    final changed =
        !_loaded ||
        nextCoins != _coins ||
        nextLastWatch?.millisecondsSinceEpoch !=
            _lastStoreRewardAdAt?.millisecondsSinceEpoch ||
        nextWatchCountToday != _watchCountToday;

    _coins = nextCoins;
    _lastStoreRewardAdAt = nextLastWatch;
    _watchCountToday = nextWatchCountToday;
    _lastWatchDay = nextLastWatchDay;
    _loaded = true;

    if (notify && changed) {
      notifyListeners();
    }
  }

  Future<void> setCoins(int value, {bool notify = true}) async {
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

  Future<void> addCoins(int amount, {bool notify = true}) async {
    if (amount == 0) {
      return;
    }
    await setCoins(_coins + amount, notify: notify);
  }

  Future<bool> spendCoins(int amount, {bool notify = true}) async {
    if (amount <= 0) {
      return true;
    }
    if (_coins < amount) {
      return false;
    }
    await setCoins(_coins - amount, notify: notify);
    return true;
  }

  Future<void> awardAcademyInterstitialCoins({bool notify = true}) async {
    await addCoins(academyInterstitialRewardCoins, notify: notify);
  }

  Future<bool> claimStoreRewardAd({bool notify = true}) async {
    if (!canClaimStoreReward) {
      return false;
    }

    _lastStoreRewardAdAt = DateTime.now();
    _coins = max(0, _coins + storeRewardCoins);

    // Increment watch count (reset if day changed)
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (_lastWatchDay != todayStr) {
      _watchCountToday = 1;
      _lastWatchDay = todayStr;
    } else {
      _watchCountToday++;
    }

    _loaded = true;

    await _persistStorePayload((payload) {
      payload['coins'] = _coins;
      return payload;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      storeRewardAdLastWatchKey,
      _lastStoreRewardAdAt!.millisecondsSinceEpoch,
    );
    await prefs.setInt(storeRewardAdWatchCountTodayKey, _watchCountToday);
    await prefs.setString(storeRewardAdLastWatchDayKey, _lastWatchDay);

    if (notify) {
      notifyListeners();
    }
    return true;
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
    } else if (_lastStoreRewardAdAt != null) {
      await prefs.setInt(
        storeRewardAdLastWatchKey,
        _lastStoreRewardAdAt!.millisecondsSinceEpoch,
      );
    }

    if (notify) {
      notifyListeners();
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
}
