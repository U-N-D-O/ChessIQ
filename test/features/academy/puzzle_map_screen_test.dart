import 'package:chessiq/core/services/scoreboard_service.dart';
import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/academy/screens/puzzle_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _TestPuzzleAcademyProvider extends PuzzleAcademyProvider {
  _TestPuzzleAcademyProvider({
    this.nodesValue = _defaultNodes,
    this.examResultsValue = const <AcademyExamResult>[],
    this.scoreboardLoadedValue = true,
    this.scoreboardSyncingValue = false,
    this.scoreboardEntriesValue = const [
      LeaderboardEntry(rank: 1, handle: 'Tester', score: 9200, title: 'Novice'),
    ],
    this.lastScoreboardErrorValue,
    this.dailyPuzzleLoadingValue = false,
    this.dailyPuzzleLoadedValue = true,
    this.lastDailyPuzzleErrorValue,
    this.dailyPuzzlesValue = const <PuzzleItem>[],
    this.hasTodayDailyPuzzleValue = false,
    this.completedTodayDailyCountValue = 0,
  }) : _progress =
           PuzzleProgressModel.initial(
             nodes: {for (final node in nodesValue) node.key: node},
           ).copyWith(
             handle: 'Tester',
             country: 'US',
             examResults: examResultsValue,
             seenSemesters: {
               for (final semester in PuzzleAcademyProvider().semesters)
                 semester.id,
             },
           );

  static const List<EloNodeProgress> _defaultNodes = [
    EloNodeProgress(
      startElo: 450,
      endElo: 500,
      totalPuzzles: 500,
      solvedCount: 120,
      attempts: 140,
      unlocked: true,
      goldCrown: false,
      themeRewardUnlocked: false,
      speedDemon: false,
    ),
    EloNodeProgress(
      startElo: 500,
      endElo: 550,
      totalPuzzles: 500,
      solvedCount: 90,
      attempts: 120,
      unlocked: true,
      goldCrown: false,
      themeRewardUnlocked: false,
      speedDemon: false,
    ),
    EloNodeProgress(
      startElo: 550,
      endElo: 600,
      totalPuzzles: 500,
      solvedCount: 10,
      attempts: 24,
      unlocked: false,
      goldCrown: false,
      themeRewardUnlocked: false,
      speedDemon: false,
    ),
    EloNodeProgress(
      startElo: 600,
      endElo: 650,
      totalPuzzles: 500,
      solvedCount: 0,
      attempts: 0,
      unlocked: false,
      goldCrown: false,
      themeRewardUnlocked: false,
      speedDemon: false,
    ),
  ];

  final PuzzleProgressModel _progress;
  final List<EloNodeProgress> nodesValue;
  final List<AcademyExamResult> examResultsValue;
  final bool scoreboardLoadedValue;
  final bool scoreboardSyncingValue;
  final List<LeaderboardEntry> scoreboardEntriesValue;
  final String? lastScoreboardErrorValue;
  final bool dailyPuzzleLoadingValue;
  final bool dailyPuzzleLoadedValue;
  final String? lastDailyPuzzleErrorValue;
  final List<PuzzleItem> dailyPuzzlesValue;
  final bool hasTodayDailyPuzzleValue;
  final int completedTodayDailyCountValue;

  @override
  PuzzleProgressModel get progress => _progress;

  @override
  bool get initialized => true;

  @override
  bool get isLoading => false;

  @override
  bool get dailyPuzzleLoading => dailyPuzzleLoadingValue;

  @override
  bool get dailyPuzzleLoaded => dailyPuzzleLoadedValue;

  @override
  String? get lastDailyPuzzleError => lastDailyPuzzleErrorValue;

  @override
  bool get scoreboardLoaded => scoreboardLoadedValue;

  @override
  bool get scoreboardSyncing => scoreboardSyncingValue;

  @override
  String? get lastScoreboardError => lastScoreboardErrorValue;

  @override
  bool get shouldAskForProfile => false;

  @override
  List<LeaderboardEntry> get academyScoreboardEntries => scoreboardEntriesValue;

  @override
  List<PuzzleItem> get dailyPuzzles => dailyPuzzlesValue;

  @override
  PuzzleItem? get todayDailyPuzzle => null;

  @override
  bool get hasTodayDailyPuzzle => hasTodayDailyPuzzleValue;

  @override
  int get completedTodayDailyCount => completedTodayDailyCountValue;

  @override
  Future<void> initialize() async {}

  @override
  Future<HandleAvailabilityStatus> registerAcademyProfile({
    required String handle,
    required String country,
  }) async {
    return HandleAvailabilityStatus.available;
  }

  @override
  Future<void> refreshRemoteScoreboard({required bool national}) async {}

  @override
  PuzzleItem? featuredPuzzleForNode(EloNodeProgress node) => null;

  @override
  Future<void> ensureNodePuzzlesLoadedForNode(EloNodeProgress node) async {}
}

Future<void> _pumpPuzzleMapScreen(
  WidgetTester tester, {
  required PuzzleAcademyProvider provider,
  required Size size,
  VoidCallback onBack = _noop,
  VoidCallback onOpenOpeningQuiz = _noop,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PuzzleAcademyProvider>.value(value: provider),
        ChangeNotifierProvider<AppThemeProvider>(
          create: (_) => AppThemeProvider(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PuzzleMapScreen(
            onBack: onBack,
            onOpenOpeningQuiz: onOpenOpeningQuiz,
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

Future<void> _openExamsDashboard(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey<String>('academy_hub_card_exams')),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Academy hub phone page shows logo, top controls, and two visible pictures',
    (tester) async {
      final provider = _TestPuzzleAcademyProvider();

      await _pumpPuzzleMapScreen(
        tester,
        provider: provider,
        size: const Size(390, 844),
      );

      expect(
        find.byKey(const ValueKey<String>('academy_hub_back_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('academy_hub_logo')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('academy_hub_theme_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('academy_hub_settings_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('academy_hub_overview_badge')),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNWidgets(3));

      final examsArtFrame = find.byKey(
        const ValueKey<String>('academy_hub_art_frame_exams'),
      );
      final quizArtFrame = find.byKey(
        const ValueKey<String>('academy_hub_art_frame_quiz'),
      );
      final examsRect = tester.getRect(examsArtFrame);
      final quizRect = tester.getRect(quizArtFrame);
      final examsSize = tester.getSize(examsArtFrame);
      final quizSize = tester.getSize(quizArtFrame);

      expect(examsArtFrame, findsOneWidget);
      expect(quizArtFrame, findsOneWidget);
      expect((examsSize.width - quizSize.width).abs(), lessThan(0.1));
      expect((examsSize.height - quizSize.height).abs(), lessThan(0.1));
      expect(examsSize.width, greaterThan(360));
      expect(examsSize.height + quizSize.height, greaterThan(620));
      expect(examsRect.top, greaterThanOrEqualTo(0));
      expect(quizRect.bottom, lessThanOrEqualTo(844));
    },
  );

  testWidgets(
    'Academy hub tablet page keeps the logo, controls, and two pictures',
    (tester) async {
      final provider = _TestPuzzleAcademyProvider();

      await _pumpPuzzleMapScreen(
        tester,
        provider: provider,
        size: const Size(1024, 768),
      );

      expect(
        find.byKey(const ValueKey<String>('academy_hub_back_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('academy_hub_logo')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('academy_hub_theme_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('academy_hub_settings_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('academy_hub_overview_badge')),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNWidgets(3));

      final examsArtFrame = find.byKey(
        const ValueKey<String>('academy_hub_art_frame_exams'),
      );
      final quizArtFrame = find.byKey(
        const ValueKey<String>('academy_hub_art_frame_quiz'),
      );
      expect(
        (tester.getTopLeft(examsArtFrame).dy -
                tester.getTopLeft(quizArtFrame).dy)
            .abs(),
        lessThan(20),
      );
      expect(
        (tester.getSize(examsArtFrame).width -
                tester.getSize(quizArtFrame).width)
            .abs(),
        lessThan(0.1),
      );
      expect(
        (tester.getSize(examsArtFrame).height -
                tester.getSize(quizArtFrame).height)
            .abs(),
        lessThan(0.1),
      );
      expect(
        tester.getTopLeft(examsArtFrame).dx,
        lessThan(tester.getTopLeft(quizArtFrame).dx),
      );
    },
  );

  testWidgets('Academy exams image opens the exams dashboard', (tester) async {
    final provider = _TestPuzzleAcademyProvider();

    await _pumpPuzzleMapScreen(
      tester,
      provider: provider,
      size: const Size(1200, 900),
    );

    await _openExamsDashboard(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Puzzle Academy Exams'), findsOneWidget);
    expect(find.text('NEXT EXAM GATE'), findsOneWidget);
    expect(find.text('Puzzle Academy'), findsOneWidget);
    expect(find.text('Mastery Dashboard'), findsOneWidget);

    final firstLevel = find.text('Level 450-500');
    final secondLevel = find.text('Level 500-550');
    expect(firstLevel, findsOneWidget);
    expect(secondLevel, findsOneWidget);

    final firstOffset = tester.getTopLeft(firstLevel);
    final secondOffset = tester.getTopLeft(secondLevel);
    expect((firstOffset.dy - secondOffset.dy).abs(), lessThan(20));
    expect((firstOffset.dx - secondOffset.dx).abs(), greaterThan(40));
  });

  testWidgets(
    'Academy exams dashboard only shows an earned rank band after its solve target',
    (tester) async {
      final provider = _TestPuzzleAcademyProvider();

      await _pumpPuzzleMapScreen(
        tester,
        provider: provider,
        size: const Size(1200, 900),
      );

      await _openExamsDashboard(tester);

      expect(find.text('450-500'), findsOneWidget);
      expect(find.text('500-550'), findsNothing);
      expect(find.textContaining('500-550'), findsWidgets);
    },
  );

  testWidgets(
    'Academy exams dashboard stays open after the screen is rebuilt at a new size',
    (tester) async {
      final provider = _TestPuzzleAcademyProvider();

      await _pumpPuzzleMapScreen(
        tester,
        provider: provider,
        size: const Size(1200, 900),
      );

      await _openExamsDashboard(tester);
      expect(find.text('Puzzle Academy Exams'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await _pumpPuzzleMapScreen(
        tester,
        provider: provider,
        size: const Size(1024, 768),
      );

      expect(find.text('Puzzle Academy Exams'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('academy_hub_card_exams')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Academy exams dashboard shows overall logged exams when the active semester has none',
    (tester) async {
      final provider = _TestPuzzleAcademyProvider(
        nodesValue: const <EloNodeProgress>[
          EloNodeProgress(
            startElo: 450,
            endElo: 500,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 500,
            endElo: 550,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 550,
            endElo: 600,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 600,
            endElo: 650,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 650,
            endElo: 700,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 700,
            endElo: 750,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 750,
            endElo: 800,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 800,
            endElo: 850,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 850,
            endElo: 900,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 900,
            endElo: 950,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 950,
            endElo: 1000,
            totalPuzzles: 500,
            solvedCount: 150,
            attempts: 170,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
            startElo: 1000,
            endElo: 1050,
            totalPuzzles: 500,
            solvedCount: 20,
            attempts: 26,
            unlocked: true,
            goldCrown: false,
            themeRewardUnlocked: false,
            speedDemon: false,
          ),
          EloNodeProgress(
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
        ],
        examResultsValue: const <AcademyExamResult>[
          AcademyExamResult(
            nodeKey: '450_500',
            score: 9200,
            leaderboardScore: 9200,
            correctCount: 43,
            totalCount: 50,
            elapsedMs: 420000,
            timeLimitMs: 3600000,
            completedAtMs: 1,
          ),
        ],
      );

      await _pumpPuzzleMapScreen(
        tester,
        provider: provider,
        size: const Size(1200, 900),
      );

      await _openExamsDashboard(tester);

      expect(find.text('1 exam logged overall'), findsOneWidget);
      expect(find.text('No exams logged yet'), findsNothing);
    },
  );

  testWidgets(
    'Academy exams portrait phone collapses dashboard and stats by default',
    (tester) async {
      final provider = _TestPuzzleAcademyProvider();

      await _pumpPuzzleMapScreen(
        tester,
        provider: provider,
        size: const Size(390, 844),
      );

      await _openExamsDashboard(tester);

      expect(
        find.byKey(
          const ValueKey<String>('academy_exams_compact_appbar_title'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('academy_exams_compact_dashboard_toggle'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('academy_exams_compact_stats_toggle'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('academy_exams_compact_dashboard_panel'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('academy_exams_compact_stats_panel')),
        findsNothing,
      );
      expect(find.text('Puzzle Academy Exams'), findsNothing);
      expect(find.text('Coins 120'), findsNothing);
      expect(
        find.text(
          'Switch between worldwide and local exam standings without leaving the map.',
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('academy_exams_compact_dashboard_toggle'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(
        find.byKey(
          const ValueKey<String>('academy_exams_compact_dashboard_panel'),
        ),
        findsOneWidget,
      );
      expect(find.text('Puzzle Academy Exams'), findsOneWidget);
      expect(find.text('NEXT EXAM GATE'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('academy_exams_compact_stats_toggle'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(
        find.byKey(const ValueKey<String>('academy_exams_compact_stats_panel')),
        findsOneWidget,
      );
      expect(find.text('Coins 120'), findsOneWidget);
    },
  );

  testWidgets('Academy exams short landscape uses compact fold-down dashboard', (
    tester,
  ) async {
    final provider = _TestPuzzleAcademyProvider();

    await _pumpPuzzleMapScreen(
      tester,
      provider: provider,
      size: const Size(844, 390),
    );

    await _openExamsDashboard(tester);

    expect(
      find.byKey(const ValueKey<String>('academy_exams_compact_appbar_title')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('academy_exams_compact_dashboard_toggle'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('academy_exams_compact_stats_toggle')),
      findsOneWidget,
    );
    expect(find.text('Puzzle Academy Exams'), findsNothing);
    expect(find.text('Coins 120'), findsNothing);
    expect(
      find.text(
        'Switch between worldwide and local exam standings without leaving the map.',
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('academy_exams_compact_dashboard_toggle'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Puzzle Academy Exams'), findsOneWidget);
    expect(find.text('NEXT EXAM GATE'), findsOneWidget);
  });

  testWidgets(
    'Academy exams dashboard shows loading states while remote data is syncing',
    (tester) async {
      final provider = _TestPuzzleAcademyProvider(
        scoreboardLoadedValue: false,
        scoreboardSyncingValue: true,
        dailyPuzzleLoadingValue: true,
        dailyPuzzleLoadedValue: false,
        dailyPuzzlesValue: const <PuzzleItem>[],
        hasTodayDailyPuzzleValue: false,
        completedTodayDailyCountValue: 0,
      );

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PuzzleAcademyProvider>.value(
              value: provider,
            ),
            ChangeNotifierProvider<AppThemeProvider>(
              create: (_) => AppThemeProvider(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PuzzleMapScreen(onBack: _noop, onOpenOpeningQuiz: _noop),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(
        find.byKey(const ValueKey<String>('academy_hub_card_exams')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        find.text('Loading today\'s challenge set and your completion state.'),
        findsOneWidget,
      );
      expect(find.text('LOADING'), findsOneWidget);
      expect(
        find.text(
          'Syncing the live Academy board and preserving your selected scope.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Academy exams dashboard shows country flags on the international leaderboard',
    (tester) async {
      final provider = _TestPuzzleAcademyProvider(
        scoreboardEntriesValue: const <LeaderboardEntry>[
          LeaderboardEntry(
            rank: 1,
            handle: 'KalaallitHero',
            score: 9800,
            title: 'Oracle',
            country: 'Greenland',
          ),
        ],
      );

      await _pumpPuzzleMapScreen(
        tester,
        provider: provider,
        size: const Size(1200, 900),
      );
      await _openExamsDashboard(tester);

      expect(find.text('KalaallitHero'), findsOneWidget);
      expect(find.text('🇬🇱'), findsOneWidget);
    },
  );

  testWidgets(
    'Academy exams dashboard shows retry actions when daily and leaderboard refresh fail',
    (tester) async {
      final provider = _TestPuzzleAcademyProvider(
        lastScoreboardErrorValue:
            'Unable to load the live Academy leaderboard right now.',
        lastDailyPuzzleErrorValue:
            'Unable to load today\'s challenge set right now.',
        scoreboardEntriesValue: const <LeaderboardEntry>[],
      );

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PuzzleAcademyProvider>.value(
              value: provider,
            ),
            ChangeNotifierProvider<AppThemeProvider>(
              create: (_) => AppThemeProvider(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PuzzleMapScreen(onBack: _noop, onOpenOpeningQuiz: _noop),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(
        find.byKey(const ValueKey<String>('academy_hub_card_exams')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Daily board unavailable'), findsOneWidget);
      expect(find.text('Retry Daily Challenge'), findsOneWidget);
      expect(find.text('Leaderboard sync failed'), findsOneWidget);
      expect(find.text('Retry Leaderboard'), findsOneWidget);
    },
  );
}

void _noop() {}
