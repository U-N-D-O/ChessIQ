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
             nodes: {for (final node in _nodes) node.key: node},
           ).copyWith(
             handle: 'Tester',
             country: 'US',
             seenSemesters: {
               for (final semester in PuzzleAcademyProvider().semesters)
                 semester.id,
             },
           );

  static const List<EloNodeProgress> _nodes = [
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Academy hub phone page only shows back and two visible pictures',
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
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      expect(find.byIcon(Icons.storefront_outlined), findsNothing);
      expect(find.text('Choose Your Training Lane'), findsNothing);
      expect(find.byType(Image), findsNWidgets(2));

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
      expect(examsSize.height + quizSize.height, greaterThan(700));
      expect(examsRect.top, greaterThanOrEqualTo(0));
      expect(quizRect.bottom, lessThanOrEqualTo(844));
    },
  );

  testWidgets(
    'Academy hub tablet page only adds the training-lane heading above two pictures',
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
      expect(find.text('Choose Your Training Lane'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      expect(find.byIcon(Icons.storefront_outlined), findsNothing);
      expect(find.byType(Image), findsNWidgets(2));

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
      size: const Size(520, 320),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('academy_hub_card_exams')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

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
