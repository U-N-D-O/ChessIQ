import 'dart:math';

import 'package:chessiq/features/avatar/models/avatar_catalog.dart';
import 'package:chessiq/features/avatar/providers/avatar_inventory_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}