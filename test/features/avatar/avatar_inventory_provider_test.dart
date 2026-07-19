import 'dart:math';

import 'package:chessiq/features/avatar/models/avatar_catalog.dart';
import 'package:chessiq/features/avatar/models/avatar_reward_catalog.dart';
import 'package:chessiq/features/avatar/providers/avatar_inventory_provider.dart';
import 'package:chessiq/features/vs_bot/models/vs_bot_models.dart';
import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/services/local_integrity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SequenceRandom implements Random {
  _SequenceRandom({
    this.doubleValues = const <double>[0],
    this.intValues = const <int>[0],
  });

  final List<double> doubleValues;
  final List<int> intValues;
  int _doubleIndex = 0;
  int _intIndex = 0;

  @override
  bool nextBool() => nextDouble() >= 0.5;

  @override
  double nextDouble() {
    final index = _doubleIndex < doubleValues.length
        ? _doubleIndex++
        : doubleValues.length - 1;
    return doubleValues[index].clamp(0.0, 0.999999999999);
  }

  @override
  int nextInt(int max) {
    final index = _intIndex < intValues.length
        ? _intIndex++
        : intValues.length - 1;
    return intValues[index] % max;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('avatar catalog totals match the current asset layout', () {
    expect(AvatarCatalog.items, hasLength(74));
    expect(
      AvatarCatalog.entriesForBucket(AvatarRarityBucket.normal),
      hasLength(24),
    );
    expect(
      AvatarCatalog.entriesForBucket(AvatarRarityBucket.rare),
      hasLength(25),
    );
    expect(
      AvatarCatalog.entriesForBucket(AvatarRarityBucket.epic),
      hasLength(12),
    );
    expect(
      AvatarCatalog.entriesForBucket(AvatarRarityBucket.legendary),
      hasLength(12),
    );
    expect(
      AvatarCatalog.entriesForBucket(AvatarRarityBucket.promo),
      hasLength(1),
    );
    expect(AvatarRewardCatalog.allVsBotRewardIds, hasLength(37));
    for (final avatarId in AvatarRewardCatalog.allVsBotRewardIds) {
      expect(AvatarCatalog.entryFor(avatarId), isNotNull);
    }
  });

  test('load bootstraps a starter avatar from the normal pool only', () async {
    final provider = AvatarInventoryProvider(random: Random(3));

    await provider.load();

    expect(provider.loaded, isTrue);
    expect(provider.bootstrappedStarter, isTrue);
    expect(provider.ownedCount, 1);
    expect(provider.starterAvatar, isNotNull);
    expect(provider.selectedAvatar, isNotNull);
    expect(provider.starterAvatar!.bucket, AvatarRarityBucket.normal);
    expect(provider.selectedAvatar!.id, provider.starterAvatar!.id);
  });

  test('selected avatar persists across provider reloads', () async {
    final firstProvider = AvatarInventoryProvider(random: Random(5));
    await firstProvider.load();

    final rareAvatar = AvatarCatalog.entriesForBucket(
      AvatarRarityBucket.rare,
    ).first;

    await firstProvider.grantAvatar(rareAvatar.id);
    await firstProvider.selectAvatar(rareAvatar.id);

    final reloadedProvider = AvatarInventoryProvider(random: Random(9));
    await reloadedProvider.load();

    expect(reloadedProvider.ownsAvatar(rareAvatar.id), isTrue);
    expect(reloadedProvider.selectedAvatar?.id, rareAvatar.id);
    expect(reloadedProvider.starterAvatar?.bucket, AvatarRarityBucket.normal);
  });

  test('load canonicalizes legacy avatar ids from saved inventory', () async {
    final legacyAvatar = AvatarCatalog.entriesForBucket(
      AvatarRarityBucket.normal,
    ).first;
    final signedPayload = LocalIntegrityService.wrapJson(<String, dynamic>{
      'avatar_inventory_v1': <String, dynamic>{
        'ownedAvatarIds': <String>[
          legacyAvatar.assetPath,
          'assets/avatars/1/AgentNova.png',
        ],
        'selectedAvatarId': legacyAvatar.assetPath,
        'starterAvatarId': legacyAvatar.assetPath,
      },
    }, scope: 'economy_store');
    SharedPreferences.setMockInitialValues(<String, Object>{
      EconomyProvider.storeStateKey: signedPayload,
    });

    final provider = AvatarInventoryProvider(random: Random(13));
    await provider.load();

    expect(provider.bootstrappedStarter, isFalse);
    expect(provider.ownsAvatar(legacyAvatar.assetPath), isTrue);
    expect(provider.ownsAvatar('assets/avatars/1/AgentNova.png'), isTrue);
    expect(provider.selectedAvatar?.id, legacyAvatar.id);
    expect(provider.starterAvatar?.id, legacyAvatar.id);
    expect(provider.ownedAvatarIds, contains(legacyAvatar.id));
    expect(provider.ownedAvatarIds, contains('rare-agent-nova'));
  });

  test('paid rolls never duplicate and never grant promo avatars', () async {
    final provider = AvatarInventoryProvider(random: Random(7));
    await provider.load();

    final seenIds = <String>{...provider.ownedAvatarIds};
    final rollCount = provider.availablePaidRollCount;

    for (var index = 0; index < rollCount; index++) {
      final result = await provider.rollPaidAvatar();
      expect(result, isNotNull);
      expect(result!.avatar.promoOnly, isFalse);
      expect(seenIds.add(result.avatar.id), isTrue);
    }

    expect(provider.availablePaidRollCount, 0);
    expect(provider.hasAvailablePaidRolls, isFalse);
    expect(await provider.rollPaidAvatar(), isNull);
  });

  test(
    'paid roll weights renormalize to remaining non-empty buckets',
    () async {
      final provider = AvatarInventoryProvider(
        random: _SequenceRandom(
          doubleValues: const <double>[0.0, 0.999],
          intValues: const <int>[0, 0],
        ),
      );
      await provider.load();

      for (final avatar in AvatarCatalog.items) {
        if (!avatar.paidRollEligible ||
            avatar.bucket == AvatarRarityBucket.legendary) {
          continue;
        }
        await provider.grantAvatar(avatar.id);
      }

      final result = await provider.rollPaidAvatar();

      expect(result, isNotNull);
      expect(result!.bucket, AvatarRarityBucket.legendary);
      expect(result.avatar.bucket, AvatarRarityBucket.legendary);
    },
  );

  test('reward groups are idempotent and skip already-owned avatars', () async {
    final provider = AvatarInventoryProvider(random: Random(11));
    await provider.load();

    final rewardIds = AvatarRewardCatalog.rewardIdsForVsBotTier(
      'mochi-gearheart',
      BotDifficulty.easy,
    );
    await provider.grantAvatar(rewardIds.first);

    final firstClaim = await provider.claimRewardGroup(
      rewardIds,
      rewardKey: AvatarRewardCatalog.rewardKeyForVsBotTier(
        'mochi-gearheart',
        BotDifficulty.easy,
      ),
    );

    expect(firstClaim.alreadyClaimed, isFalse);
    expect(firstClaim.grantedAvatars.map((avatar) => avatar.id), <String>[
      rewardIds.last,
    ]);

    final secondClaim = await provider.claimRewardGroup(
      rewardIds,
      rewardKey: AvatarRewardCatalog.rewardKeyForVsBotTier(
        'mochi-gearheart',
        BotDifficulty.easy,
      ),
    );

    expect(secondClaim.alreadyClaimed, isTrue);
    expect(secondClaim.grantedAvatars, isEmpty);
  });
}
