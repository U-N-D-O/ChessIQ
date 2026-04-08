import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EconomyProvider extends ChangeNotifier {
  static const String storeStateKey = 'store_state_v1';
  static const String storeRewardAdLastWatchKey =
      'store_reward_ad_last_watch_v1';
  static const int academyInterstitialRewardCoins = 10;
  static const int storeRewardCoins = 120;
  static const int defaultCoins = 120;
  static const Duration storeRewardCooldown = Duration(minutes: 30);

  int _coins = defaultCoins;
  DateTime? _lastStoreRewardAdAt;
  bool _loaded = false;

  int get coins => _coins;
  bool get loaded => _loaded;
  DateTime? get lastStoreRewardAdAt => _lastStoreRewardAdAt;

  Duration get remainingStoreRewardCooldown {
    final lastWatch = _lastStoreRewardAdAt;
    if (lastWatch == null) {
      return Duration.zero;
    }
    final remaining = lastWatch
        .add(storeRewardCooldown)
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
    final changed =
        !_loaded ||
        nextCoins != _coins ||
        nextLastWatch?.millisecondsSinceEpoch !=
            _lastStoreRewardAdAt?.millisecondsSinceEpoch;

    _coins = nextCoins;
    _lastStoreRewardAdAt = nextLastWatch;
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
    final raw = prefs.getString(storeStateKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  Future<void> _persistStorePayload(
    Map<String, dynamic> Function(Map<String, dynamic>) update,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final nextPayload = update(_readStorePayload(prefs));
    await prefs.setString(storeStateKey, jsonEncode(nextPayload));
  }
}
