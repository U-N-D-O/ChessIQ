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

Future<void> _pumpOpeningsQuizSession(
  WidgetTester tester, {
  required Size size,
  bool monochrome = false,
  String modeCardKey = 'quiz_setup_mode_card_identify_opening_name',
}) async {
  await _pumpOpeningsQuizSelector(tester, size: size, monochrome: monochrome);

  final modeCard = find.byKey(ValueKey<String>(modeCardKey));
  expect(modeCard, findsOneWidget);

  final setupScroll = find.byType(Scrollable).first;
  await tester.dragUntilVisible(modeCard, setupScroll, const Offset(0, 300));
  await tester.pump();
  await tester.tap(modeCard);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));

  final startButton = find.byKey(
    const ValueKey<String>('quiz_setup_start_button'),
  );
  expect(startButton, findsOneWidget);

  await tester.dragUntilVisible(
    startButton,
    setupScroll,
    const Offset(0, -300),
  );
  await tester.pump();
  await tester.tap(startButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1400));
}

Finder _assetImageFinder(String assetPath) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Image) {
      return false;
    }
    final provider = widget.image;
    return provider is AssetImage && provider.assetName == assetPath;
  });
}

Finder _liveQuizOptionFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('quiz_session_option_');
  });
}

void _expectFinderWithinViewport(
  WidgetTester tester,
  Finder finder,
  Size viewport,
) {
  final rect = tester.getRect(finder);
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(viewport.height));
  expect(rect.right, lessThanOrEqualTo(viewport.width));
}

void _expectAllOptionsWithinViewport(
  WidgetTester tester,
  Finder finder,
  Size viewport,
) {
  for (final element in finder.evaluate()) {
    final rect = tester.getRect(find.byWidget(element.widget));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(viewport.height));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(viewport.width));
  }
}

void _expectCompactPhoneOptionStatusLabelsHidden() {
  expect(find.text('Tap to select'), findsNothing);
  expect(find.text('Selected'), findsNothing);
  expect(find.text('Tap to preview'), findsNothing);
  expect(find.text('Previewing'), findsNothing);
  expect(find.text('Correct answer'), findsNothing);
  expect(find.text('Your answer'), findsNothing);
  expect(find.text('Reviewed option'), findsNothing);
}

void _expectCompactPhoneFeedbackOverlaySingleLine(WidgetTester tester) {
  final feedbackOverlay = find.byKey(
    const ValueKey<String>('quiz_session_feedback_overlay'),
  );
  final feedbackText = find.descendant(
    of: feedbackOverlay,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Text && widget.data != null && widget.data!.isNotEmpty,
    ),
  );

  final textWidget = tester.widget<Text>(feedbackText);
  expect(textWidget.maxLines, 1);
  expect(textWidget.softWrap, isFalse);
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
    expect(find.text('CHOOSE MODE'), findsNothing);
    expect(find.text('SET UP QUIZ'), findsOneWidget);
    expect(find.text('OPEN STUDY'), findsOneWidget);
    expect(find.text('STYLE'), findsNothing);
    expect(find.text('STATS'), findsNothing);
    expect(find.textContaining('Quiz opens the setup screen'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'opening academy launcher keeps header on one row in compact landscape',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsAcademyLauncher(tester, size: const Size(667, 375));

      final backButton = find.byKey(
        const ValueKey<String>('quiz_academy_header_back_button'),
      );
      final titleBlock = find.byKey(
        const ValueKey<String>('quiz_academy_header_title_block'),
      );
      final styleButton = find.byKey(
        const ValueKey<String>('quiz_academy_header_style_button'),
      );
      final statsButton = find.byKey(
        const ValueKey<String>('quiz_academy_header_stats_button'),
      );

      expect(backButton, findsOneWidget);
      expect(titleBlock, findsOneWidget);
      expect(styleButton, findsOneWidget);
      expect(statsButton, findsOneWidget);
      expect(find.text('STYLE'), findsNothing);
      expect(find.text('STATS'), findsNothing);

      final backRect = tester.getRect(backButton);
      final titleRect = tester.getRect(titleBlock);
      final styleRect = tester.getRect(styleButton);
      final statsRect = tester.getRect(statsButton);

      expect(backRect.right, lessThan(titleRect.left));
      expect(titleRect.right, lessThan(styleRect.left));
      expect(styleRect.right, lessThan(statsRect.left));
      expect((titleRect.top - backRect.top).abs(), lessThan(12));
      expect((styleRect.top - backRect.top).abs(), lessThan(12));
      expect((statsRect.top - backRect.top).abs(), lessThan(12));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('opening academy launcher omits the choose mode box on iPad', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpOpeningsAcademyLauncher(tester, size: const Size(1024, 768));

    expect(find.text('QUIZ OR STUDY'), findsOneWidget);
    expect(find.text('CHOOSE MODE'), findsNothing);
    expect(find.textContaining('Quiz opens the setup screen'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('quiz_academy_launcher_quiz')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('quiz_academy_launcher_study')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'opening quiz selector removes hero copy and hides details behind info on compact portrait',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsQuizSelector(tester, size: const Size(390, 844));

      expect(find.text('OPENINGS QUIZ ROUTES'), findsNothing);
      expect(find.text('OPENINGS QUIZ'), findsNothing);
      expect(find.text('MODE / LEVEL / START'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('quiz_academy_header_title_block')),
        findsNothing,
      );
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
      expect(find.text('Choose how this quiz asks the opening.'), findsNothing);
      expect(
        find.textContaining(
          'is selected. Choose the difficulty you want to start.',
        ),
        findsNothing,
      );
      expect(
        find.text('Review the selected mode and level, then begin.'),
        findsNothing,
      );
      expect(_assetImageFinder('assets/academy/quiz_name.png'), findsOneWidget);
      expect(_assetImageFinder('assets/academy/quiz_line.png'), findsOneWidget);

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

      final startButton = find.byKey(
        const ValueKey<String>('quiz_setup_start_button'),
      );
      expect(startButton, findsOneWidget);
      await tester.dragUntilVisible(
        startButton,
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      await tester.pump();
      expect(
        find.descendant(of: startButton, matching: find.text('START QUIZ')),
        findsOneWidget,
      );

      final identifyInfoButton = find.byKey(
        const ValueKey<String>('quiz_setup_mode_info_identify_opening_name'),
      );
      await tester.dragUntilVisible(
        identifyInfoButton,
        find.byType(Scrollable).first,
        const Offset(0, 300),
      );
      await tester.pump();

      await tester.tap(identifyInfoButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.textContaining('choose the correct opening name'),
        findsOneWidget,
      );
      expect(find.text('CLOSE'), findsOneWidget);

      final closeButton = find
          .ancestor(of: find.text('CLOSE'), matching: find.byType(Material))
          .last;
      await tester.ensureVisible(closeButton);
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'opening quiz level info caps hard and oracle tiers at four choices',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsQuizSelector(tester, size: const Size(390, 844));

      final levelInfoButton = find.byKey(
        const ValueKey<String>('quiz_setup_level_info_button'),
      );
      expect(levelInfoButton, findsOneWidget);

      await tester.dragUntilVisible(
        levelInfoButton,
        find.byType(Scrollable).first,
        const Offset(0, 300),
      );
      await tester.pump();

      await tester.tap(levelInfoButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.textContaining('Hard: Expect sharper theory'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Very Hard: Finish with rare lines'),
        findsOneWidget,
      );
      expect(find.textContaining('(4 choices per question).'), findsOneWidget);
      expect(find.textContaining('(5 choices per question).'), findsNothing);

      final closeButton = find
          .ancestor(of: find.text('CLOSE'), matching: find.byType(Material))
          .last;
      await tester.ensureVisible(closeButton);
      await tester.tap(closeButton);
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
      expect(find.text('MODE / LEVEL / START'), findsNothing);
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
      expect(find.text('Choose how this quiz asks the opening.'), findsNothing);
      expect(
        find.textContaining(
          'is selected. Choose the difficulty you want to start.',
        ),
        findsNothing,
      );
      expect(
        find.text('Review the selected mode and level, then begin.'),
        findsNothing,
      );

      final modeRect = tester.getRect(
        find.byKey(const ValueKey<String>('quiz_setup_mode_panel')),
      );
      final levelRect = tester.getRect(
        find.byKey(const ValueKey<String>('quiz_setup_level_panel')),
      );
      expect(modeRect.left, lessThan(levelRect.left));

      final startButton = find.byKey(
        const ValueKey<String>('quiz_setup_start_button'),
      );
      expect(startButton, findsOneWidget);
      expect(
        find.descendant(of: startButton, matching: find.text('START QUIZ')),
        findsOneWidget,
      );

      final identifyRect = tester.getRect(identifyCard);
      final completeRect = tester.getRect(completeCard);
      expect(identifyRect.bottom, lessThanOrEqualTo(390));
      expect(completeRect.bottom, lessThanOrEqualTo(390));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'opening quiz live play fits board options and action on compact portrait and moves guidance behind info',
    (tester) async {
      const viewport = Size(390, 844);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsQuizSession(tester, size: viewport);

      final boardCard = find.byKey(
        const ValueKey<String>('quiz_session_board_card'),
      );
      final boardSquare = find.byKey(
        const ValueKey<String>('quiz_session_board_square'),
      );
      final topPanel = find.byKey(
        const ValueKey<String>('quiz_session_top_panel'),
      );
      final compactSummary = find.byKey(
        const ValueKey<String>('quiz_session_compact_summary'),
      );
      final questionPanel = find.byKey(
        const ValueKey<String>('quiz_session_question_panel'),
      );
      final primaryAction = find.byKey(
        const ValueKey<String>('quiz_session_primary_action'),
      );
      final optionFinder = _liveQuizOptionFinder();

      expect(boardCard, findsOneWidget);
      expect(boardSquare, findsOneWidget);
      expect(topPanel, findsOneWidget);
      expect(compactSummary, findsOneWidget);
      expect(find.text('Q 1/10'), findsOneWidget);
      expect(questionPanel, findsOneWidget);
      expect(primaryAction, findsOneWidget);
      expect(optionFinder, findsAtLeastNWidgets(3));
      expect(optionFinder.evaluate().length, lessThanOrEqualTo(4));

      expect(tester.getSize(topPanel).height, lessThan(90.0));
      expect(tester.getRect(topPanel).top, lessThanOrEqualTo(8.0));
      expect(
        tester.getSize(boardCard).width - tester.getSize(boardSquare).width,
        lessThan(24.0),
      );
      _expectFinderWithinViewport(tester, boardCard, viewport);
      _expectFinderWithinViewport(tester, questionPanel, viewport);
      _expectFinderWithinViewport(tester, primaryAction, viewport);
      _expectAllOptionsWithinViewport(tester, optionFinder, viewport);
      expect(find.text('REVIEW LOG'), findsNothing);
      expect(find.text('LIVE ROUND'), findsNothing);
      expect(find.text('BLACK TO MOVE'), findsNothing);
      expect(find.text('WHITE TO MOVE'), findsNothing);

      expect(
        find.text(
          'Read the board, pick the right opening name, and keep the streak moving.',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Read the position first, then choose the matching opening name.',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Study the board and choose the opening name that matches it.',
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('quiz_session_option_1')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      _expectCompactPhoneOptionStatusLabelsHidden();
      _expectFinderWithinViewport(tester, primaryAction, viewport);
      _expectAllOptionsWithinViewport(tester, optionFinder, viewport);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey<String>('quiz_session_info_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.textContaining('pick the right opening name'),
        findsOneWidget,
      );
      expect(find.textContaining('matching opening name'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('quiz_academy_notice_scroll_view')),
        findsOneWidget,
      );
      expect(find.text('CLOSE'), findsOneWidget);

      await tester.tap(find.text('CLOSE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final boardRectBeforeSubmit = tester.getRect(boardCard);
      final questionRectBeforeSubmit = tester.getRect(questionPanel);
      final actionRectBeforeSubmit = tester.getRect(primaryAction);

      await tester.tap(
        find.byKey(const ValueKey<String>('quiz_session_primary_action')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      final feedbackOverlay = find.byKey(
        const ValueKey<String>('quiz_session_feedback_overlay'),
      );
      expect(feedbackOverlay, findsOneWidget);
      expect(topPanel, findsOneWidget);
      _expectFinderWithinViewport(tester, feedbackOverlay, viewport);
      final topPanelRect = tester.getRect(topPanel);
      final feedbackOverlayRect = tester.getRect(feedbackOverlay);
      expect(feedbackOverlayRect.top, closeTo(topPanelRect.top, 0.01));
      expect(feedbackOverlayRect.left, closeTo(topPanelRect.left, 0.01));
      expect(feedbackOverlayRect.width, closeTo(topPanelRect.width, 0.01));
      expect(feedbackOverlayRect.height, closeTo(topPanelRect.height, 0.01));
      _expectCompactPhoneFeedbackOverlaySingleLine(tester);
      final boardRectAfterSubmit = tester.getRect(boardCard);
      final questionRectAfterSubmit = tester.getRect(questionPanel);
      final actionRectAfterSubmit = tester.getRect(primaryAction);
      expect(
        boardRectAfterSubmit.top,
        closeTo(boardRectBeforeSubmit.top, 0.01),
      );
      expect(
        questionRectAfterSubmit.top,
        closeTo(questionRectBeforeSubmit.top, 0.01),
      );
      expect(
        actionRectAfterSubmit.top,
        closeTo(actionRectBeforeSubmit.top, 0.01),
      );
      _expectCompactPhoneOptionStatusLabelsHidden();
      _expectFinderWithinViewport(tester, primaryAction, viewport);
      _expectAllOptionsWithinViewport(tester, optionFinder, viewport);
      expect(find.text('REVIEW LOG'), findsNothing);
      expect(find.text('LIVE ROUND'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 150));

      expect(feedbackOverlay, findsNothing);
      expect(topPanel, findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'opening quiz live play fits board options and action on compact landscape',
    (tester) async {
      const viewport = Size(844, 390);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsQuizSession(tester, size: viewport);

      final boardCard = find.byKey(
        const ValueKey<String>('quiz_session_board_card'),
      );
      final boardSquare = find.byKey(
        const ValueKey<String>('quiz_session_board_square'),
      );
      final topPanel = find.byKey(
        const ValueKey<String>('quiz_session_top_panel'),
      );
      final compactSummary = find.byKey(
        const ValueKey<String>('quiz_session_compact_summary'),
      );
      final questionPanel = find.byKey(
        const ValueKey<String>('quiz_session_question_panel'),
      );
      final primaryAction = find.byKey(
        const ValueKey<String>('quiz_session_primary_action'),
      );
      final optionFinder = _liveQuizOptionFinder();

      expect(boardCard, findsOneWidget);
      expect(boardSquare, findsOneWidget);
      expect(topPanel, findsOneWidget);
      expect(compactSummary, findsOneWidget);
      expect(questionPanel, findsOneWidget);
      expect(primaryAction, findsOneWidget);
      expect(optionFinder, findsAtLeastNWidgets(3));

      expect(tester.getSize(topPanel).height, lessThan(90.0));
      expect(
        tester.getSize(boardCard).height - tester.getSize(boardSquare).height,
        lessThan(36.0),
      );
      _expectFinderWithinViewport(tester, boardCard, viewport);
      _expectFinderWithinViewport(tester, questionPanel, viewport);
      _expectFinderWithinViewport(tester, primaryAction, viewport);
      _expectAllOptionsWithinViewport(tester, optionFinder, viewport);
      expect(find.text('REVIEW LOG'), findsNothing);
      expect(find.text('LIVE ROUND'), findsNothing);
      expect(find.text('BLACK TO MOVE'), findsNothing);
      expect(find.text('WHITE TO MOVE'), findsNothing);
      expect(
        find.text(
          'Read the board, pick the right opening name, and keep the streak moving.',
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('quiz_session_option_1')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      _expectCompactPhoneOptionStatusLabelsHidden();

      final boardRectBeforeSubmit = tester.getRect(boardCard);
      final questionRectBeforeSubmit = tester.getRect(questionPanel);
      final actionRectBeforeSubmit = tester.getRect(primaryAction);

      await tester.tap(
        find.byKey(const ValueKey<String>('quiz_session_primary_action')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      final feedbackOverlay = find.byKey(
        const ValueKey<String>('quiz_session_feedback_overlay'),
      );
      expect(feedbackOverlay, findsOneWidget);
      expect(topPanel, findsOneWidget);
      _expectFinderWithinViewport(tester, feedbackOverlay, viewport);
      final topPanelRect = tester.getRect(topPanel);
      final feedbackOverlayRect = tester.getRect(feedbackOverlay);
      expect(feedbackOverlayRect.top, closeTo(topPanelRect.top, 0.01));
      expect(feedbackOverlayRect.left, closeTo(topPanelRect.left, 0.01));
      expect(feedbackOverlayRect.width, closeTo(topPanelRect.width, 0.01));
      expect(feedbackOverlayRect.height, closeTo(topPanelRect.height, 0.01));
      _expectCompactPhoneFeedbackOverlaySingleLine(tester);
      final boardRectAfterSubmit = tester.getRect(boardCard);
      final questionRectAfterSubmit = tester.getRect(questionPanel);
      final actionRectAfterSubmit = tester.getRect(primaryAction);
      expect(
        boardRectAfterSubmit.top,
        closeTo(boardRectBeforeSubmit.top, 0.01),
      );
      expect(
        questionRectAfterSubmit.top,
        closeTo(questionRectBeforeSubmit.top, 0.01),
      );
      expect(
        actionRectAfterSubmit.top,
        closeTo(actionRectBeforeSubmit.top, 0.01),
      );
      _expectCompactPhoneOptionStatusLabelsHidden();

      _expectFinderWithinViewport(tester, primaryAction, viewport);
      _expectAllOptionsWithinViewport(tester, optionFinder, viewport);
      expect(find.text('REVIEW LOG'), findsNothing);
      expect(find.text('LIVE ROUND'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 150));

      expect(feedbackOverlay, findsNothing);
      expect(topPanel, findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'opening quiz complete line keeps compact portrait option status labels hidden',
    (tester) async {
      const viewport = Size(390, 844);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsQuizSession(
        tester,
        size: viewport,
        modeCardKey: 'quiz_setup_mode_card_complete_opening_line',
      );

      final primaryAction = find.byKey(
        const ValueKey<String>('quiz_session_primary_action'),
      );
      final optionFinder = _liveQuizOptionFinder();

      expect(primaryAction, findsOneWidget);
      expect(optionFinder, findsAtLeastNWidgets(3));

      await tester.tap(
        find.byKey(const ValueKey<String>('quiz_session_option_1')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      _expectCompactPhoneOptionStatusLabelsHidden();
      _expectFinderWithinViewport(tester, primaryAction, viewport);
      _expectAllOptionsWithinViewport(tester, optionFinder, viewport);

      await tester.tap(primaryAction);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      _expectCompactPhoneOptionStatusLabelsHidden();
      _expectFinderWithinViewport(tester, primaryAction, viewport);
      _expectAllOptionsWithinViewport(tester, optionFinder, viewport);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'opening quiz complete line keeps compact landscape option status labels hidden',
    (tester) async {
      const viewport = Size(844, 390);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsQuizSession(
        tester,
        size: viewport,
        modeCardKey: 'quiz_setup_mode_card_complete_opening_line',
      );

      final primaryAction = find.byKey(
        const ValueKey<String>('quiz_session_primary_action'),
      );
      final optionFinder = _liveQuizOptionFinder();

      expect(primaryAction, findsOneWidget);
      expect(optionFinder, findsAtLeastNWidgets(3));

      await tester.tap(
        find.byKey(const ValueKey<String>('quiz_session_option_1')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      _expectCompactPhoneOptionStatusLabelsHidden();
      _expectFinderWithinViewport(tester, primaryAction, viewport);
      _expectAllOptionsWithinViewport(tester, optionFinder, viewport);

      await tester.tap(primaryAction);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      _expectCompactPhoneOptionStatusLabelsHidden();
      _expectFinderWithinViewport(tester, primaryAction, viewport);
      _expectAllOptionsWithinViewport(tester, optionFinder, viewport);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
