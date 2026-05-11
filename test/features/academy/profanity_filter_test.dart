import 'package:chessiq/features/academy/data/profanity_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('containsProfanity', () {
    test('blocks a short explicit fragment embedded in a nickname', () {
      expect(containsProfanity('sexbakedcake'), isTrue);
    });

    test(
      'still allows benign names that only contain harmless short tokens',
      () {
        expect(containsProfanity('amber_knight'), isFalse);
        expect(containsProfanity('classy_player'), isFalse);
      },
    );

    test('blocks standalone profanity tokens', () {
      expect(containsProfanity('sex'), isTrue);
    });
  });
}
