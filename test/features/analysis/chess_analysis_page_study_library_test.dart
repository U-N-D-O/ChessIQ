import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/services/scoreboard_service.dart';
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

Finder _findByValueKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
}

Future<void> _pumpOpeningsStudyLibrary(
  WidgetTester tester, {
  required Size size,
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

  final openingsHub = find.byKey(
    const ValueKey<String>('academy_hub_card_quiz'),
  );
  expect(openingsHub, findsOneWidget);

  await tester.ensureVisible(openingsHub);
  await tester.tap(openingsHub);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1400));

  final openingsStudy = find.byKey(
    const ValueKey<String>('quiz_academy_launcher_study'),
  );
  expect(openingsStudy, findsOneWidget);

  await tester.scrollUntilVisible(
    openingsStudy,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await tester.tap(openingsStudy);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1400));
}

Future<void> _openFirstVariation(WidgetTester tester) async {
  final familyCards = _findByValueKeyPrefix('quiz_study_family_');
  expect(familyCards, findsWidgets);

  final familyCard = tester.widget<InkWell>(familyCards.first);
  familyCard.onTap?.call();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  final variationTiles = _findByValueKeyPrefix('quiz_study_variation_');
  expect(variationTiles, findsWidgets);

  final variationTile = tester.widget<InkWell>(variationTiles.first);
  variationTile.onTap?.call();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets(
    'study library keeps compact portrait focused on category and browser panels',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsStudyLibrary(tester, size: const Size(390, 844));

      expect(find.text('STUDY SHELVES'), findsNothing);
      expect(find.text('LIBRARY INDEX'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('quiz_study_category_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_study_browser_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_study_inline_category_stats')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_study_inline_browser_stats')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_study_category_grandmaster')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_study_category_library')),
        findsOneWidget,
      );
      expect(find.text('OPENING STUDY'), findsNothing);
      expect(find.text('Basic category'), findsNothing);
      expect(
        find.text('Switch the opening set you want to browse.'),
        findsNothing,
      );

      await _openFirstVariation(tester);

      expect(
        find.byKey(const ValueKey<String>('quiz_study_detail_header_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_study_detail_board_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_study_detail_navigator_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('quiz_study_detail_inline_info_panel'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'study library uses side-by-side compact landscape panels without inline extras',
    (tester) async {
      const viewport = Size(844, 390);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpOpeningsStudyLibrary(tester, size: viewport);

      final categoryPanel = find.byKey(
        const ValueKey<String>('quiz_study_category_panel'),
      );
      final browserPanel = find.byKey(
        const ValueKey<String>('quiz_study_browser_panel'),
      );

      expect(categoryPanel, findsOneWidget);
      expect(browserPanel, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('quiz_study_inline_category_stats')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_study_inline_browser_stats')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_study_category_grandmaster')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quiz_study_category_library')),
        findsOneWidget,
      );
      expect(
        _findByValueKeyPrefix('quiz_study_family_progress_'),
        findsWidgets,
      );
      expect(find.text('OPENING STUDY'), findsNothing);
      expect(find.text('Basic category'), findsNothing);
      expect(
        find.text('Switch the opening set you want to browse.'),
        findsNothing,
      );

      final categoryOffset = tester.getTopLeft(categoryPanel);
      final browserOffset = tester.getTopLeft(browserPanel);
      expect(categoryOffset.dx, lessThan(browserOffset.dx));

      final searchField = find.byKey(
        const ValueKey<String>('quiz-study-search-basic'),
      );
      expect(searchField, findsOneWidget);
      final searchOffset = tester.getTopLeft(searchField);
      expect(searchOffset.dx, lessThan(browserOffset.dx));

      await _openFirstVariation(tester);

      final detailHeader = find.byKey(
        const ValueKey<String>('quiz_study_detail_header_panel'),
      );
      final boardPanel = find.byKey(
        const ValueKey<String>('quiz_study_detail_board_panel'),
      );
      final navigatorPanel = find.byKey(
        const ValueKey<String>('quiz_study_detail_navigator_panel'),
      );
      final compactFamilyLabel = find.byKey(
        const ValueKey<String>('quiz_study_compact_landscape_family_label'),
      );
      final replayControls = find.byKey(
        const ValueKey<String>('quiz_study_detail_replay_controls'),
      );

      expect(detailHeader, findsOneWidget);
      expect(boardPanel, findsOneWidget);
      expect(navigatorPanel, findsOneWidget);
      expect(compactFamilyLabel, findsOneWidget);
      expect(
        find.descendant(of: detailHeader, matching: replayControls),
        findsOneWidget,
      );
      expect(
        find.descendant(of: boardPanel, matching: replayControls),
        findsNothing,
      );
      expect(
        find.descendant(of: boardPanel, matching: find.text('BOARD')),
        findsNothing,
      );
      expect(
        find.descendant(of: navigatorPanel, matching: find.text('VARIATIONS')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: navigatorPanel,
          matching: find.textContaining('Switch lines'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('quiz_study_detail_inline_info_panel'),
        ),
        findsNothing,
      );

      _expectFinderWithinViewport(tester, detailHeader, viewport);
      _expectFinderWithinViewport(tester, boardPanel, viewport);
      _expectFinderWithinViewport(tester, navigatorPanel, viewport);

      final boardRect = tester.getRect(boardPanel);
      final detailHeaderRect = tester.getRect(detailHeader);
      final navigatorRect = tester.getRect(navigatorPanel);
      final compactFamilyRect = tester.getRect(compactFamilyLabel);
      expect(boardRect.left, lessThan(detailHeaderRect.left));
      expect(boardRect.left, lessThan(navigatorRect.left));
      expect(detailHeaderRect.top, lessThanOrEqualTo(navigatorRect.top));
      expect(compactFamilyRect.top, lessThan(detailHeaderRect.top));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('study library shows inline secondary information at iPad size', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpOpeningsStudyLibrary(tester, size: const Size(1024, 768));

    expect(
      find.byKey(const ValueKey<String>('quiz_study_inline_category_stats')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('quiz_study_inline_browser_stats')),
      findsOneWidget,
    );

    await _openFirstVariation(tester);

    expect(
      find.byKey(const ValueKey<String>('quiz_study_inline_detail_stats')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('quiz_study_detail_inline_info_panel')),
      findsOneWidget,
    );
  });
}
