import 'dart:math';

import 'package:chessiq/features/analysis/models/analysis_models.dart';
import 'package:chessiq/features/vs_bot/models/bot_roster.dart';
import 'package:chessiq/features/vs_bot/models/vs_bot_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BotMoveCandidate candidate(
    String move,
    int eval,
    int rank, {
    bool isCapture = false,
    bool isCheck = false,
  }) {
    return BotMoveCandidate(
      line: EngineLine(move, eval, 14, rank),
      isCapture: isCapture,
      isCheck: isCheck,
    );
  }

  test('rex hard no longer forces the top engine move', () {
    final rex = botRoster.singleWhere((bot) => bot.id == 'rex-halfcheck');
    final policy = rex.hard.moveSelectionPolicy;

    expect(policy, isNotNull);
    expect(rex.hard.multiPv, greaterThanOrEqualTo(policy!.rankWeights.length));

    final counts = <String, int>{};
    final rng = Random(7);
    for (var i = 0; i < 200; i++) {
      final move = BotMoveSelector.pickMove(
        <BotMoveCandidate>[
          candidate('e2e4', 42, 1),
          candidate('d2d4', 36, 2, isCapture: true),
          candidate('g1f3', 30, 3),
          candidate('c2c4', 12, 4, isCheck: true),
          candidate('b1c3', -4, 5),
        ],
        policy,
        rng,
      );

      expect(move, isNotNull);
      counts.update(move!, (count) => count + 1, ifAbsent: () => 1);
    }

    expect(counts['e2e4'] ?? 0, lessThan(200));
    expect(counts['d2d4'] ?? 0, greaterThan(0));
    expect(counts.length, greaterThan(1));
  });

  test('selection policy collapses to the only safe move', () {
    final rex = botRoster.singleWhere((bot) => bot.id == 'rex-halfcheck');
    final policy = rex.hard.moveSelectionPolicy!;
    final rng = Random(13);

    for (var i = 0; i < 40; i++) {
      final move = BotMoveSelector.pickMove(
        <BotMoveCandidate>[
          candidate('e2e4', 55, 1),
          candidate('d2d4', -70, 2, isCapture: true),
          candidate('g1f3', -150, 3),
        ],
        policy,
        rng,
      );

      expect(move, 'e2e4');
    }
  });

  test('master prime hard still prefers rank one without perfection', () {
    final master = botRoster.singleWhere((bot) => bot.id == 'master-prime');
    final policy = master.hard.moveSelectionPolicy;

    expect(policy, isNotNull);
    expect(
      master.hard.multiPv,
      greaterThanOrEqualTo(policy!.rankWeights.length),
    );

    final counts = <String, int>{};
    final rng = Random(23);
    for (var i = 0; i < 300; i++) {
      final move = BotMoveSelector.pickMove(
        <BotMoveCandidate>[
          candidate('e2e4', 88, 1),
          candidate('d2d4', 84, 2),
          candidate('g1f3', 80, 3),
        ],
        policy,
        rng,
      );

      expect(move, isNotNull);
      counts.update(move!, (count) => count + 1, ifAbsent: () => 1);
    }

    expect(counts['e2e4'] ?? 0, greaterThan(counts['d2d4'] ?? 0));
    expect(counts['e2e4'] ?? 0, lessThan(300));
    expect((counts['d2d4'] ?? 0) + (counts['g1f3'] ?? 0), greaterThan(0));
  });
}
