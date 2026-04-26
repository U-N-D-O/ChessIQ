import 'package:chessiq/core/services/scoreboard_service.dart';
import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/analysis/screens/chess_analysis_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestPuzzleAcademyProvider extends PuzzleAcademyProvider {
  _TestPuzzleAcademyProvider()
    : _progress =
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

  @override
  PuzzleProgressModel get progress => _progress;

  @override
  bool get initialized => true;

  @override
  bool get isLoading => false;

  @override
  bool get dailyPuzzleLoading => false;

  @override
  bool get dailyPuzzleLoaded => true;

  @override
  bool get scoreboardLoaded => true;

  @override
  bool get scoreboardSyncing => false;

  @override
  bool get shouldAskForProfile => false;

  @override
  List<LeaderboardEntry> get academyScoreboardEntries =>
      const <LeaderboardEntry>[
        LeaderboardEntry(
          rank: 1,
          handle: 'Tester',
          score: 9200,
          title: 'Novice',
        ),
      ];

  @override
  List<PuzzleItem> get dailyPuzzles => const <PuzzleItem>[];

  @override
  PuzzleItem? get todayDailyPuzzle => null;

  @override
  bool get hasTodayDailyPuzzle => false;

  @override
  int get completedTodayDailyCount => 0;

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

Future<void> _pumpOpeningsAcademyLauncher(
  WidgetTester tester, {
  required Size size,
  bool monochrome = false,
}) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{
    'mute_sounds_v1': true,
    'haptics_enabled_v1': false,
  });

  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  final economy = EconomyProvider();
  await economy.refresh(notify: false);
  final academyProvider = _TestPuzzleAcademyProvider();
  final theme = AppThemeProvider();
  if (monochrome) {
    await theme.setThemeStyle(AppThemeStyle.monochrome);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppThemeProvider>.value(value: theme),
        ChangeNotifierProvider<EconomyProvider>.value(value: economy),
        ChangeNotifierProvider<PuzzleAcademyProvider>.value(
          value: academyProvider,
        ),
      ],
      child: const MaterialApp(home: ChessAnalysisPage()),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1400));

  final academy = find.text('ACADEMY');
  expect(academy, findsOneWidget);

  await tester.tap(academy);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));

  final openingStudy = find.byKey(
    const ValueKey<String>('academy_hub_card_quiz'),
  );
  expect(openingStudy, findsOneWidget);

  await tester.ensureVisible(openingStudy);
  await tester.tap(openingStudy);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1400));

  final openingsQuiz = find.byKey(
    const ValueKey<String>('quiz_academy_launcher_quiz'),
  );
  expect(openingsQuiz, findsOneWidget);
}

Future<void> _pumpOpeningsQuizSelector(
  WidgetTester tester, {
  required Size size,
  bool monochrome = false,
}) async {
  await _pumpOpeningsAcademyLauncher(
    tester,
    size: size,
    monochrome: monochrome,
  );

  final openingsQuiz = find.byKey(
    const ValueKey<String>('quiz_academy_launcher_quiz'),
  );

  await tester.scrollUntilVisible(
    openingsQuiz,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await tester.tap(openingsQuiz);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('opening academy launcher uses simple quiz and study copy', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpOpeningsAcademyLauncher(tester, size: const Size(390, 844));

    expect(find.text('INSERT COIN / CHOOSE YOUR PATH'), findsNothing);
    expect(find.textContaining('INSERT COIN'), findsNothing);
    expect(find.text('ARCADE DIRECTIVE'), findsNothing);
    expect(find.text('QUIZ CARTRIDGE'), findsNothing);
    expect(find.text('PRESS START'), findsNothing);
    expect(find.text('QUIZ OR STUDY'), findsOneWidget);
    expect(find.text('CHOOSE MODE'), findsOneWidget);
    expect(find.text('SET UP QUIZ'), findsOneWidget);
    expect(find.text('OPEN STUDY'), findsOneWidget);
    expect(find.textContaining('Quiz opens the setup screen'), findsOneWidget);
  });

  testWidgets(
    'opening quiz selector removes hero copy and hides details behind info on compact portrait',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsQuizSelector(tester, size: const Size(390, 844));

      expect(find.text('OPENINGS QUIZ ROUTES'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('quiz_setup_mode_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_setup_level_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_setup_mission_panel')),
        findsOneWidget,
      );
      final identifyCard = find.byKey(
        const ValueKey<String>('quiz_setup_mode_card_identify_opening_name'),
      );
      final completeCard = find.byKey(
        const ValueKey<String>('quiz_setup_mode_card_complete_opening_line'),
      );
      expect(identifyCard, findsOneWidget);
      expect(completeCard, findsOneWidget);
      expect(
        find.descendant(
          of: identifyCard,
          matching: find.text('Identify Opening Name'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: completeCard,
          matching: find.text('Complete Opening Line'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('choose the correct opening name'),
        findsNothing,
      );

      await tester.dragUntilVisible(
        identifyCard,
        find.byType(Scrollable).first,
        const Offset(0, 300),
      );
      await tester.pump();

      final modeRect = tester.getRect(
        find.byKey(const ValueKey<String>('quiz_setup_mode_panel')),
      );
      final levelRect = tester.getRect(
        find.byKey(const ValueKey<String>('quiz_setup_level_panel')),
      );
      final missionRect = tester.getRect(
        find.byKey(const ValueKey<String>('quiz_setup_mission_panel')),
      );
      expect(modeRect.top, lessThan(levelRect.top));
      expect(levelRect.top, lessThan(missionRect.top));

      await tester.tap(
        find.byKey(
          const ValueKey<String>('quiz_setup_mode_info_identify_opening_name'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.textContaining('choose the correct opening name'),
        findsOneWidget,
      );
      expect(find.text('CLOSE'), findsOneWidget);

      await tester.tap(find.text('CLOSE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'opening quiz selector keeps both mode cards visible on compact landscape',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsQuizSelector(tester, size: const Size(844, 390));

      expect(find.text('OPENINGS QUIZ ROUTES'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('quiz_setup_mode_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_setup_level_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_setup_mission_panel')),
        findsOneWidget,
      );
      final identifyCard = find.byKey(
        const ValueKey<String>('quiz_setup_mode_card_identify_opening_name'),
      );
      final completeCard = find.byKey(
        const ValueKey<String>('quiz_setup_mode_card_complete_opening_line'),
      );
      expect(identifyCard, findsOneWidget);
      expect(completeCard, findsOneWidget);
      expect(
        find.descendant(
          of: identifyCard,
          matching: find.text('Identify Opening Name'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: completeCard,
          matching: find.text('Complete Opening Line'),
        ),
        findsOneWidget,
      );

      final modeRect = tester.getRect(
        find.byKey(const ValueKey<String>('quiz_setup_mode_panel')),
      );
      final levelRect = tester.getRect(
        find.byKey(const ValueKey<String>('quiz_setup_level_panel')),
      );
      expect(modeRect.left, lessThan(levelRect.left));

      final identifyRect = tester.getRect(identifyCard);
      final completeRect = tester.getRect(completeCard);
      expect(identifyRect.bottom, lessThanOrEqualTo(390));
      expect(completeRect.bottom, lessThanOrEqualTo(390));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
