import 'package:chessiq/core/services/local_integrity_service.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _progressKey = 'puzzle_academy_progress_v2';

List<PuzzleItem> _buildDailyPuzzles(int count) {
  return List<PuzzleItem>.generate(
    count,
    (index) => PuzzleItem(
      puzzleId: 'daily_$index',
      fen: '8/8/8/8/8/8/8/8 w - - 0 1',
      moves: const <String>['e2e4'],
      rating: 1000 + index,
      gameUrl: '',
      themes: const <String>['daily'],
      openingTags: const <String>[],
    ),
    growable: false,
  );
}

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
    '1050_1100': const EloNodeProgress(
      startElo: 1050,
      endElo: 1100,
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

  test('daily challenge resumes at the first unsolved puzzle', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});

    final provider = PuzzleAcademyProvider();
    provider.debugHydrateProgress(
      PuzzleProgressModel.initial(nodes: _buildTestNodes()).copyWith(
        completedDailyPuzzleIds: const <String>{'daily_0', 'daily_1'},
      ),
    );
    provider.debugSetDailyPuzzles(_buildDailyPuzzles(5));

    expect(provider.todayDailyPuzzle?.puzzleId, 'daily_2');
    expect(provider.todayDailyPuzzleIndex, 2);
  });

  test(
    'daily challenge resumes at the last puzzle after all daily puzzles are completed',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});

      final dailyPuzzles = _buildDailyPuzzles(20);
      final provider = PuzzleAcademyProvider();
      provider.debugHydrateProgress(
        PuzzleProgressModel.initial(nodes: _buildTestNodes()).copyWith(
          completedDailyPuzzleIds: dailyPuzzles
              .map((puzzle) => puzzle.puzzleId)
              .toSet(),
        ),
      );
      provider.debugSetDailyPuzzles(dailyPuzzles);

      expect(provider.todayDailyPuzzle?.puzzleId, 'daily_19');
      expect(provider.todayDailyPuzzleIndex, 19);
    },
  );

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
        'nextNodeKey': '1050_1100',
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
      final nextNodeKey = purchase['nextNodeKey'] as String?;
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
      if (nextNodeKey != null) {
        expect(
          provider.progress.nodes[nextNodeKey]?.unlocked,
          isFalse,
          reason: 'Tuition should only unlock the first level in $semesterId',
        );
      }
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

    expect(
      reloadedProvider.progress.nodes['1050_1100']?.unlocked,
      isFalse,
      reason: 'Reloaded tuition purchase should not unlock a full semester.',
    );

    expect(reloadedProvider.progress.coins, remainingCoins);
  });

  test(
    'semester tuition cannot be bought when entry level is already unlocked',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});

      final fallbackNodes = _buildTestNodes();
      final provider = PuzzleAcademyProvider();
      provider.debugHydrateProgress(
        PuzzleProgressModel.initial(nodes: fallbackNodes).copyWith(
          coins: 12000,
          examResults: const <AcademyExamResult>[
            AcademyExamResult(
              nodeKey: '450_500',
              score: 9000,
              leaderboardScore: 9000,
              correctCount: 45,
              totalCount: 50,
              elapsedMs: 1000,
              timeLimitMs: 3600000,
              completedAtMs: 1,
            ),
            AcademyExamResult(
              nodeKey: '450_500',
              score: 9100,
              leaderboardScore: 9100,
              correctCount: 46,
              totalCount: 50,
              elapsedMs: 1000,
              timeLimitMs: 3600000,
              completedAtMs: 2,
            ),
          ],
        ),
      );

      expect(provider.isSemesterAlreadyUnlocked('tactician'), isTrue);
      expect(await provider.buySemesterTuition('tactician'), isFalse);
      expect(provider.ownsSemesterTuition('tactician'), isFalse);
      expect(provider.progress.coins, 12000);
    },
  );
}
