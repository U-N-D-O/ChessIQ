import 'dart:io';

import 'package:chessiq/features/avatar/models/avatar_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all catalog avatar assets are real PNG files', () {
    const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

    for (final avatar in AvatarCatalog.items) {
      final file = File(avatar.assetPath);
      expect(file.existsSync(), isTrue, reason: avatar.assetPath);

      final bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThan(1024), reason: avatar.assetPath);
      expect(bytes.take(8), pngSignature, reason: avatar.assetPath);
    }
  });
}
