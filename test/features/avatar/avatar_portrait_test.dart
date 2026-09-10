import 'package:chessiq/features/avatar/models/avatar_catalog.dart';
import 'package:chessiq/features/avatar/widgets/avatar_portrait.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders generated fallback when avatar asset is not decodable', (
    tester,
  ) async {
    const avatar = AvatarCatalogEntry(
      id: 'test-celician-mara',
      name: 'Celician Mara',
      assetPath: 'assets/avatars/missing/test-celician-mara.png',
      bucket: AvatarRarityBucket.normal,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: AvatarPortrait(avatar: avatar, size: 96)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CM'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_rounded), findsNothing);
  });
}
