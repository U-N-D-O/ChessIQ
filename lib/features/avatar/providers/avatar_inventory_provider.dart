import 'dart:math';

import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/services/local_integrity_service.dart';
import 'package:chessiq/features/avatar/models/avatar_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarInventoryProvider extends ChangeNotifier {
  AvatarInventoryProvider({Random? random}) : _random = random ?? Random();

  static const String _storeIntegrityScope = 'economy_store';
  static const String _avatarInventoryKey = 'avatar_inventory_v1';
  static const String _ownedAvatarIdsKey = 'ownedAvatarIds';
  static const String _selectedAvatarIdKey = 'selectedAvatarId';
  static const String _starterAvatarIdKey = 'starterAvatarId';
  static const String _claimedRewardKeysKey = 'claimedRewardKeys';

  final Random _random;

  bool _loaded = false;
  bool _bootstrappedStarter = false;
  Set<String> _ownedAvatarIds = <String>{};
  Set<String> _claimedRewardKeys = <String>{};
  String? _selectedAvatarId;
  String? _starterAvatarId;

  bool get loaded => _loaded;

  bool get bootstrappedStarter => _bootstrappedStarter;

  Set<String> get ownedAvatarIds => Set<String>.unmodifiable(_ownedAvatarIds);

  Set<String> get claimedRewardKeys =>
      Set<String>.unmodifiable(_claimedRewardKeys);

  AvatarCatalogEntry? get selectedAvatar => AvatarCatalog.entryFor(
    _selectedAvatarId,
  );

  AvatarCatalogEntry? get starterAvatar => AvatarCatalog.entryFor(
    _starterAvatarId,
  );

  List<AvatarCatalogEntry> get ownedAvatars => AvatarCatalog.ownedEntriesFor(
    _ownedAvatarIds,
  );

  List<AvatarCatalogEntry> get starterPool => AvatarCatalog.starterPool;

  int get ownedCount => _ownedAvatarIds.length;

  bool ownsAvatar(String avatarId) => _ownedAvatarIds.contains(avatarId);

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

    _ownedAvatarIds = _readStringSet(
      inventory[_ownedAvatarIdsKey],
      validValues: AvatarCatalog.ids,
    );
    _claimedRewardKeys = _readStringSet(inventory[_claimedRewardKeysKey]);
    _starterAvatarId = _normalizeStarterId(inventory[_starterAvatarIdKey]);
    if (_starterAvatarId != null) {
      _ownedAvatarIds.add(_starterAvatarId!);
    }
    _selectedAvatarId = _normalizeOwnedAvatarId(inventory[_selectedAvatarIdKey]);

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

    if (_selectedAvatarId == null || !_ownedAvatarIds.contains(_selectedAvatarId)) {
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
    if (!_ownedAvatarIds.contains(avatarId)) {
      return false;
    }
    if (_selectedAvatarId == avatarId) {
      return true;
    }
    _selectedAvatarId = avatarId;
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
    };

    await resolvedPrefs.setString(
      EconomyProvider.storeStateKey,
      LocalIntegrityService.wrapJson(payload, scope: _storeIntegrityScope),
    );
  }

  Set<String> _readStringSet(
    Object? rawValue, {
    Set<String>? validValues,
  }) {
    final values = (rawValue as List? ?? const <dynamic>[])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (validValues == null) {
      return values;
    }
    return values.where(validValues.contains).toSet();
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
    if (value.isEmpty || !_ownedAvatarIds.contains(value)) {
      return null;
    }
    return value;
  }

  AvatarCatalogEntry? _pickRandomAvatar(List<AvatarCatalogEntry> pool) {
    if (pool.isEmpty) {
      return null;
    }
    return pool[_random.nextInt(pool.length)];
  }

  String? _firstOwnedAvatarId() {
    final owned = ownedAvatars;
    if (owned.isEmpty) {
      return null;
    }
    return owned.first.id;
  }
}