import 'dart:math';

import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/services/local_integrity_service.dart';
import 'package:chessiq/features/avatar/models/avatar_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarRollResult {
  const AvatarRollResult({required this.avatar, required this.bucket});

  final AvatarCatalogEntry avatar;
  final AvatarRarityBucket bucket;
}

class AvatarRewardClaimResult {
  const AvatarRewardClaimResult({
    this.alreadyClaimed = false,
    this.grantedAvatars = const <AvatarCatalogEntry>[],
  });

  final bool alreadyClaimed;
  final List<AvatarCatalogEntry> grantedAvatars;
}

class AvatarInventoryProvider extends ChangeNotifier {
  AvatarInventoryProvider({Random? random}) : _random = random ?? Random();

  static const int paidRollPrice = 200;
  static const String _storeIntegrityScope = 'economy_store';
  static const String _avatarInventoryKey = 'avatar_inventory_v1';
  static const String _ownedAvatarIdsKey = 'ownedAvatarIds';
  static const String _selectedAvatarIdKey = 'selectedAvatarId';
  static const String _starterAvatarIdKey = 'starterAvatarId';
  static const String _claimedRewardKeysKey = 'claimedRewardKeys';
  static const String _paidRollPurchaseCountKey = 'paidRollPurchaseCount';
  static const List<AvatarRarityBucket> _paidRollBuckets = <AvatarRarityBucket>[
    AvatarRarityBucket.normal,
    AvatarRarityBucket.rare,
    AvatarRarityBucket.epic,
    AvatarRarityBucket.legendary,
  ];

  final Random _random;

  bool _loaded = false;
  bool _bootstrappedStarter = false;
  Set<String> _ownedAvatarIds = <String>{};
  Set<String> _claimedRewardKeys = <String>{};
  String? _selectedAvatarId;
  String? _starterAvatarId;
  int _paidRollPurchaseCount = 0;

  bool get loaded => _loaded;

  bool get bootstrappedStarter => _bootstrappedStarter;

  Set<String> get ownedAvatarIds => Set<String>.unmodifiable(_ownedAvatarIds);

  Set<String> get claimedRewardKeys =>
      Set<String>.unmodifiable(_claimedRewardKeys);

  AvatarCatalogEntry? get selectedAvatar =>
      AvatarCatalog.entryFor(_selectedAvatarId);

  AvatarCatalogEntry? get starterAvatar =>
      AvatarCatalog.entryFor(_starterAvatarId);

  int get paidRollPurchaseCount => _paidRollPurchaseCount;

  bool get hasUnlockedStrangeReactions => _paidRollPurchaseCount > 0;

  List<AvatarCatalogEntry> get ownedAvatars =>
      AvatarCatalog.ownedEntriesFor(_ownedAvatarIds);

  List<AvatarCatalogEntry> get starterPool => AvatarCatalog.starterPool;

  List<AvatarCatalogEntry> get availablePaidRollAvatars => AvatarCatalog.items
      .where(
        (avatar) =>
            avatar.paidRollEligible && !_ownedAvatarIds.contains(avatar.id),
      )
      .toList(growable: false);

  int get availablePaidRollCount => availablePaidRollAvatars.length;

  bool get hasAvailablePaidRolls => availablePaidRollCount > 0;

  List<AvatarCatalogEntry> availablePaidRollAvatarsForBucket(
    AvatarRarityBucket bucket,
  ) {
    if (!_paidRollBuckets.contains(bucket)) {
      return const <AvatarCatalogEntry>[];
    }
    return availablePaidRollAvatars
        .where((avatar) => avatar.bucket == bucket)
        .toList(growable: false);
  }

  double currentPaidRollWeightForBucket(AvatarRarityBucket bucket) {
    if (!_paidRollBuckets.contains(bucket)) {
      return 0;
    }
    final availableBuckets = _availablePaidRollBuckets();
    final totalWeight = availableBuckets.keys.fold<double>(
      0,
      (sum, currentBucket) => sum + currentBucket.paidRollWeight,
    );
    if (totalWeight <= 0) {
      return 0;
    }
    return availableBuckets.keys.any((currentBucket) => currentBucket == bucket)
        ? (bucket.paidRollWeight / totalWeight) * 100
        : 0;
  }

  int get ownedCount => _ownedAvatarIds.length;

  bool ownsAvatar(String avatarId) {
    final canonicalId = AvatarCatalog.canonicalIdFor(avatarId);
    return canonicalId != null && _ownedAvatarIds.contains(canonicalId);
  }

  bool hasClaimedReward(String rewardKey) {
    return _claimedRewardKeys.contains(rewardKey.trim());
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final payload = _readStorePayload(prefs);
    final rawInventory = payload[_avatarInventoryKey];
    final inventory = rawInventory is Map
        ? rawInventory.cast<String, dynamic>()
        : <String, dynamic>{};

    _ownedAvatarIds = _readAvatarIdSet(inventory[_ownedAvatarIdsKey]);
    _claimedRewardKeys = _readStringSet(inventory[_claimedRewardKeysKey]);
    _starterAvatarId = _normalizeStarterId(inventory[_starterAvatarIdKey]);
    _paidRollPurchaseCount = _readNonNegativeInt(
      inventory[_paidRollPurchaseCountKey],
    );
    if (_starterAvatarId != null) {
      _ownedAvatarIds.add(_starterAvatarId!);
    }
    _selectedAvatarId = _normalizeOwnedAvatarId(
      inventory[_selectedAvatarIdKey],
    );

    var changed = false;
    _bootstrappedStarter = false;

    if (_starterAvatarId == null) {
      final starter = _pickRandomAvatar(AvatarCatalog.starterPool);
      if (starter != null) {
        _starterAvatarId = starter.id;
        _ownedAvatarIds.add(starter.id);
        _bootstrappedStarter = true;
        changed = true;
      }
    }

    if (_selectedAvatarId == null ||
        !_ownedAvatarIds.contains(_selectedAvatarId)) {
      _selectedAvatarId = _starterAvatarId ?? _firstOwnedAvatarId();
      changed = true;
    }

    _loaded = true;

    if (changed) {
      await _persistAvatarInventory(prefs: prefs);
    }

    notifyListeners();
  }

  Future<bool> selectAvatar(String avatarId) async {
    if (!_loaded) {
      await load();
    }
    final canonicalId = AvatarCatalog.canonicalIdFor(avatarId);
    if (canonicalId == null || !_ownedAvatarIds.contains(canonicalId)) {
      return false;
    }
    if (_selectedAvatarId == canonicalId) {
      return true;
    }
    _selectedAvatarId = canonicalId;
    await _persistAvatarInventory();
    notifyListeners();
    return true;
  }

  Future<bool> grantAvatar(
    String avatarId, {
    String? rewardKey,
    bool autoSelect = false,
  }) async {
    if (!_loaded) {
      await load();
    }

    final avatar = AvatarCatalog.entryFor(avatarId);
    if (avatar == null) {
      return false;
    }

    var changed = _ownedAvatarIds.add(avatar.id);
    final normalizedRewardKey = rewardKey?.trim() ?? '';
    if (normalizedRewardKey.isNotEmpty) {
      changed = _claimedRewardKeys.add(normalizedRewardKey) || changed;
    }
    if (_selectedAvatarId == null || autoSelect) {
      _selectedAvatarId = avatar.id;
      changed = true;
    }
    if (_starterAvatarId == null && avatar.starterEligible) {
      _starterAvatarId = avatar.id;
      changed = true;
    }

    if (!changed) {
      return false;
    }

    await _persistAvatarInventory();
    notifyListeners();
    return true;
  }

  Future<AvatarRollResult?> rollPaidAvatar() async {
    if (!_loaded) {
      await load();
    }

    final availableBuckets = _availablePaidRollBuckets();
    if (availableBuckets.isEmpty) {
      return null;
    }

    final bucket = _pickWeightedBucket(availableBuckets);
    if (bucket == null) {
      return null;
    }

    final pool = availableBuckets[bucket];
    if (pool == null || pool.isEmpty) {
      return null;
    }

    final avatar = pool[_random.nextInt(pool.length)];
    final changed = _ownedAvatarIds.add(avatar.id);
    if (!changed) {
      return null;
    }

    _paidRollPurchaseCount += 1;

    await _persistAvatarInventory();
    notifyListeners();
    return AvatarRollResult(avatar: avatar, bucket: bucket);
  }

  Future<AvatarRewardClaimResult> claimRewardGroup(
    Iterable<String> avatarIds, {
    required String rewardKey,
  }) async {
    if (!_loaded) {
      await load();
    }

    final normalizedRewardKey = rewardKey.trim();
    if (normalizedRewardKey.isEmpty) {
      return const AvatarRewardClaimResult();
    }
    if (_claimedRewardKeys.contains(normalizedRewardKey)) {
      return const AvatarRewardClaimResult(alreadyClaimed: true);
    }

    final grantedAvatars = <AvatarCatalogEntry>[];
    _claimedRewardKeys.add(normalizedRewardKey);
    for (final avatarId in avatarIds) {
      final avatar = AvatarCatalog.entryFor(avatarId);
      if (avatar == null) {
        continue;
      }
      if (_ownedAvatarIds.add(avatar.id)) {
        grantedAvatars.add(avatar);
      }
    }

    await _persistAvatarInventory();
    notifyListeners();
    return AvatarRewardClaimResult(grantedAvatars: grantedAvatars);
  }

  Map<String, dynamic> _readStorePayload(SharedPreferences prefs) {
    final signed = LocalIntegrityService.decodeJson(
      prefs.getString(EconomyProvider.storeStateKey),
      scope: _storeIntegrityScope,
    );
    if (signed.data == null) {
      return <String, dynamic>{};
    }
    if (signed.isSigned && !signed.isValid) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{...?signed.data};
  }

  Future<void> _persistAvatarInventory({SharedPreferences? prefs}) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    final payload = _readStorePayload(resolvedPrefs);
    final ownedAvatarIds = _ownedAvatarIds.toList()..sort();
    final claimedRewardKeys = _claimedRewardKeys.toList()..sort();
    payload[_avatarInventoryKey] = <String, dynamic>{
      _ownedAvatarIdsKey: ownedAvatarIds,
      _selectedAvatarIdKey: _selectedAvatarId,
      _starterAvatarIdKey: _starterAvatarId,
      _claimedRewardKeysKey: claimedRewardKeys,
      _paidRollPurchaseCountKey: _paidRollPurchaseCount,
    };

    await resolvedPrefs.setString(
      EconomyProvider.storeStateKey,
      LocalIntegrityService.wrapJson(payload, scope: _storeIntegrityScope),
    );
  }

  Set<String> _readStringSet(Object? rawValue, {Set<String>? validValues}) {
    final values = (rawValue as List? ?? const <dynamic>[])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (validValues == null) {
      return values;
    }
    return values.where(validValues.contains).toSet();
  }

  Set<String> _readAvatarIdSet(Object? rawValue) {
    final canonicalIds = <String>{};
    for (final value in _readStringSet(rawValue)) {
      final canonicalId = AvatarCatalog.canonicalIdFor(value);
      if (canonicalId != null) {
        canonicalIds.add(canonicalId);
      }
    }
    return canonicalIds;
  }

  int _readNonNegativeInt(Object? rawValue) {
    if (rawValue is int) {
      return rawValue < 0 ? 0 : rawValue;
    }
    if (rawValue is num) {
      final value = rawValue.floor();
      return value < 0 ? 0 : value;
    }
    if (rawValue is String) {
      final parsed = int.tryParse(rawValue.trim());
      if (parsed == null || parsed < 0) {
        return 0;
      }
      return parsed;
    }
    return 0;
  }

  String? _normalizeStarterId(Object? rawValue) {
    final value = rawValue?.toString().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    final avatar = AvatarCatalog.entryFor(value);
    if (avatar == null || !avatar.starterEligible) {
      return null;
    }
    return avatar.id;
  }

  String? _normalizeOwnedAvatarId(Object? rawValue) {
    final value = rawValue?.toString().trim() ?? '';
    final canonicalId = AvatarCatalog.canonicalIdFor(value);
    if (canonicalId == null || !_ownedAvatarIds.contains(canonicalId)) {
      return null;
    }
    return canonicalId;
  }

  AvatarCatalogEntry? _pickRandomAvatar(List<AvatarCatalogEntry> pool) {
    if (pool.isEmpty) {
      return null;
    }
    return pool[_random.nextInt(pool.length)];
  }

  Map<AvatarRarityBucket, List<AvatarCatalogEntry>>
  _availablePaidRollBuckets() {
    final buckets = <AvatarRarityBucket, List<AvatarCatalogEntry>>{};
    for (final bucket in _paidRollBuckets) {
      final available = availablePaidRollAvatarsForBucket(bucket);
      if (available.isNotEmpty) {
        buckets[bucket] = available;
      }
    }
    return buckets;
  }

  AvatarRarityBucket? _pickWeightedBucket(
    Map<AvatarRarityBucket, List<AvatarCatalogEntry>> availableBuckets,
  ) {
    final totalWeight = availableBuckets.keys.fold<double>(
      0,
      (sum, bucket) => sum + bucket.paidRollWeight,
    );
    if (totalWeight <= 0) {
      return null;
    }

    var roll = _random.nextDouble() * totalWeight;
    for (final bucket in _paidRollBuckets) {
      if (!availableBuckets.containsKey(bucket)) {
        continue;
      }
      roll -= bucket.paidRollWeight;
      if (roll <= 0) {
        return bucket;
      }
    }

    return availableBuckets.keys.lastOrNull;
  }

  String? _firstOwnedAvatarId() {
    final owned = ownedAvatars;
    if (owned.isEmpty) {
      return null;
    }
    return owned.first.id;
  }
}
