import 'package:chessiq/core/services/local_integrity_service.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _progressKey = 'puzzle_academy_progress_v2';

Map<String, EloNodeProgress> _buildTestNodes() {
  return <String, EloNodeProgress>{
    '450_500': const EloNodeProgress(
      startElo: 450,
      endElo: 500,
      totalPuzzles: 500,
      solvedCount: 0,
      attempts: 0,
      unlocked: true,
      goldCrown: false,
      themeRewardUnlocked: false,
      speedDemon: false,
    ),
    '1000_1050': const EloNodeProgress(
      startElo: 1000,
      endElo: 1050,
      totalPuzzles: 500,
      solvedCount: 0,
      attempts: 0,
      unlocked: false,
      goldCrown: false,
      themeRewardUnlocked: false,
      speedDemon: false,
    ),
    '1500_1550': const EloNodeProgress(
      startElo: 1500,
      endElo: 1550,
      totalPuzzles: 500,
      solvedCount: 0,
      attempts: 0,
      unlocked: false,
      goldCrown: false,
      themeRewardUnlocked: false,
      speedDemon: false,
    ),
    '2100_2150': const EloNodeProgress(
      startElo: 2100,
      endElo: 2150,
      totalPuzzles: 500,
      solvedCount: 0,
      attempts: 0,
      unlocked: false,
      goldCrown: false,
      themeRewardUnlocked: false,
      speedDemon: false,
    ),
    '2500_2550': const EloNodeProgress(
      startElo: 2500,
      endElo: 2550,
      totalPuzzles: 500,
      solvedCount: 0,
      attempts: 0,
      unlocked: false,
      goldCrown: false,
      themeRewardUnlocked: false,
      speedDemon: false,
    ),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('semester tuition purchases unlock entry levels and persist', () async {
    const startingCoins = 12000;
    SharedPreferences.setMockInitialValues(const <String, Object>{});

    final fallbackNodes = _buildTestNodes();
    final provider = PuzzleAcademyProvider();
    provider.debugHydrateProgress(
      PuzzleProgressModel.initial(
        nodes: fallbackNodes,
      ).copyWith(coins: startingCoins),
    );

    final purchases = <Map<String, Object>>[
      <String, Object>{
        'semesterId': 'tactician',
        'nodeKey': '1000_1050',
        'cost': 1200,
      },
      <String, Object>{
        'semesterId': 'strategist',
        'nodeKey': '1500_1550',
        'cost': 2400,
      },
      <String, Object>{
        'semesterId': 'master',
        'nodeKey': '2100_2150',
        'cost': 3600,
      },
      <String, Object>{
        'semesterId': 'grandmaster',
        'nodeKey': '2500_2550',
        'cost': 4800,
      },
    ];

    var remainingCoins = startingCoins;
    for (final purchase in purchases) {
      final semesterId = purchase['semesterId']! as String;
      final nodeKey = purchase['nodeKey']! as String;
      final cost = purchase['cost']! as int;

      final beforeNode = provider.progress.nodes[nodeKey];
      expect(beforeNode, isNotNull, reason: semesterId);
      expect(beforeNode!.unlocked, isFalse, reason: semesterId);
      expect(
        provider.requiresPreviousSemesterExamGate(beforeNode),
        isTrue,
        reason: semesterId,
      );

      expect(await provider.buySemesterTuition(semesterId), isTrue);

      remainingCoins -= cost;
      final afterNode = provider.progress.nodes[nodeKey];
      expect(afterNode, isNotNull, reason: semesterId);
      expect(provider.ownsSemesterTuition(semesterId), isTrue);
      expect(afterNode!.unlocked, isTrue, reason: semesterId);
      expect(
        provider.requiresPreviousSemesterExamGate(afterNode),
        isFalse,
        reason: semesterId,
      );
      expect(provider.progress.coins, remainingCoins);
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = LocalIntegrityService.decodeJson(
      prefs.getString(_progressKey),
      scope: 'academy_progress',
    );
    expect(saved.data, isNotNull);

    final restored = PuzzleProgressModel.fromMap(
      saved.data!,
      fallbackNodes: fallbackNodes,
    );
    final reloadedProvider = PuzzleAcademyProvider();
    reloadedProvider.debugHydrateProgress(restored);

    for (final purchase in purchases) {
      final semesterId = purchase['semesterId']! as String;
      final nodeKey = purchase['nodeKey']! as String;
      final reloadedNode = reloadedProvider.progress.nodes[nodeKey];
      expect(reloadedNode, isNotNull, reason: semesterId);
      expect(reloadedProvider.ownsSemesterTuition(semesterId), isTrue);
      expect(reloadedNode!.unlocked, isTrue, reason: semesterId);
    }

    expect(reloadedProvider.progress.coins, remainingCoins);
  });
}
