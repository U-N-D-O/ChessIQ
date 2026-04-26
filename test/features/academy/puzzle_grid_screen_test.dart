import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/academy/screens/puzzle_grid_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _TestPuzzleAcademyProvider extends PuzzleAcademyProvider {
  _TestPuzzleAcademyProvider()
    : _progress = PuzzleProgressModel.initial(nodes: {testNode.key: testNode})
          .copyWith(
            solvedPuzzleIds: <String>{'puzzle_1', 'puzzle_2', 'puzzle_3'},
            skippedPuzzleIds: <String>{'puzzle_4'},
            examResults: const <AcademyExamResult>[
              AcademyExamResult(
                nodeKey: '450_500',
                score: 9400,
                leaderboardScore: 4700,
                correctCount: 47,
                totalCount: 50,
                elapsedMs: 182000,
                timeLimitMs: 300000,
                completedAtMs: 1730000000000,
              ),
            ],
          );

  static const EloNodeProgress testNode = EloNodeProgress(
    startElo: 450,
    endElo: 500,
    totalPuzzles: 12,
    solvedCount: 3,
    attempts: 6,
    unlocked: true,
    goldCrown: false,
    themeRewardUnlocked: false,
    speedDemon: false,
  );

  static final List<PuzzleItem> _puzzles = List<PuzzleItem>.generate(
    12,
    (index) => PuzzleItem(
      puzzleId: 'puzzle_${index + 1}',
      fen: '8/8/8/8/8/8/8/8 w - - 0 1',
      moves: const <String>['e2e4', 'e7e5'],
      rating: 450 + (index * 10),
      gameUrl: 'https://example.com/${index + 1}',
      themes: const <String>['fork'],
      openingTags: const <String>['italian-game'],
    ),
  );

  final PuzzleProgressModel _progress;

  @override
  PuzzleProgressModel get progress => _progress;

  @override
  bool get initialized => true;

  @override
  bool get isLoading => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> ensureNodePuzzlesLoadedForNode(EloNodeProgress node) async {}

  @override
  List<PuzzleItem> puzzlesForNode(EloNodeProgress node) => _puzzles;

  @override
  int examUnlockSolveTarget(EloNodeProgress node) => 6;

  @override
  bool canTakeExam(EloNodeProgress node) => false;
}

class _DeepFrontierPuzzleAcademyProvider extends PuzzleAcademyProvider {
  _DeepFrontierPuzzleAcademyProvider()
    : _progress = PuzzleProgressModel.initial(nodes: {testNode.key: testNode})
          .copyWith(
            solvedPuzzleIds: {
              for (var index = 1; index <= 151; index++) 'deep_puzzle_$index',
            },
          );

  static const EloNodeProgress testNode = EloNodeProgress(
    startElo: 450,
    endElo: 500,
    totalPuzzles: 200,
    solvedCount: 151,
    attempts: 168,
    unlocked: true,
    goldCrown: false,
    themeRewardUnlocked: false,
    speedDemon: false,
  );

  static final List<PuzzleItem> _puzzles = List<PuzzleItem>.generate(
    200,
    (index) => PuzzleItem(
      puzzleId: 'deep_puzzle_${index + 1}',
      fen: '8/8/8/8/8/8/8/8 w - - 0 1',
      moves: const <String>['e2e4', 'e7e5'],
      rating: 600 + index,
      gameUrl: 'https://example.com/deep/${index + 1}',
      themes: const <String>['fork'],
      openingTags: const <String>['italian-game'],
    ),
  );

  final PuzzleProgressModel _progress;

  @override
  PuzzleProgressModel get progress => _progress;

  @override
  bool get initialized => true;

  @override
  bool get isLoading => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> ensureNodePuzzlesLoadedForNode(EloNodeProgress node) async {}

  @override
  List<PuzzleItem> puzzlesForNode(EloNodeProgress node) => _puzzles;

  @override
  int examUnlockSolveTarget(EloNodeProgress node) => 160;

  @override
  bool canTakeExam(EloNodeProgress node) => false;
}

Future<void> _pumpPuzzleGridScreen(
  WidgetTester tester, {
  required Size size,
  PuzzleAcademyProvider? provider,
  EloNodeProgress? node,
}) async {
  final academyProvider = provider ?? _TestPuzzleAcademyProvider();
  final activeNode = node ?? _TestPuzzleAcademyProvider.testNode;
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PuzzleAcademyProvider>.value(
          value: academyProvider,
        ),
        ChangeNotifierProvider<AppThemeProvider>(
          create: (_) => AppThemeProvider(),
        ),
      ],
      child: MaterialApp(
        home: PuzzleGridScreen(node: activeNode, heroTag: 'test-grid-hero'),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _expectCompactGridIntelFlow(WidgetTester tester) async {
  const toggleKey = ValueKey<String>('puzzle_grid_compact_intel_toggle');
  const panelKey = ValueKey<String>('puzzle_grid_compact_intel_panel');
  const bodyCopyKey = ValueKey<String>('puzzle_grid_header_body_copy');

  expect(find.byKey(bodyCopyKey), findsNothing);
  expect(find.byKey(toggleKey), findsOneWidget);
  expect(find.byKey(panelKey), findsNothing);
  expect(find.text('Queue'), findsOneWidget);
  expect(find.text('Overlay'), findsOneWidget);
  expect(find.text('SCORING'), findsNothing);
  expect(find.text('EXAM GATE'), findsNothing);
  expect(find.text('BEST EXAM'), findsNothing);

  await tester.tap(find.byKey(toggleKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 220));

  expect(find.byKey(panelKey), findsOneWidget);
  expect(find.text('SCORING'), findsOneWidget);
  expect(find.text('EXAM GATE'), findsOneWidget);
  expect(find.text('BEST EXAM'), findsOneWidget);
}

void _expectCompactLandscapeControlsPromoted(WidgetTester tester) {
  final statusRect = tester.getRect(
    find.byKey(const ValueKey<String>('puzzle_grid_status_pills')),
  );
  final controlRect = tester.getRect(
    find.byKey(const ValueKey<String>('puzzle_grid_compact_top_controls')),
  );
  final allRect = tester.getRect(
    find.byKey(const ValueKey<String>('puzzle_grid_chip_all')),
  );
  final toggleRect = tester.getRect(
    find.byKey(const ValueKey<String>('puzzle_grid_compact_intel_toggle')),
  );

  expect(controlRect.top, lessThan(statusRect.bottom));
  expect(toggleRect.left, greaterThan(statusRect.center.dx));
  expect((toggleRect.top - allRect.top).abs(), lessThanOrEqualTo(2));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('puzzle grid portrait compacts intel behind fold-down', (
    tester,
  ) async {
    await _pumpPuzzleGridScreen(tester, size: const Size(390, 844));

    await _expectCompactGridIntelFlow(tester);
  });

  testWidgets('puzzle grid landscape compacts intel behind fold-down', (
    tester,
  ) async {
    await _pumpPuzzleGridScreen(tester, size: const Size(844, 390));

    _expectCompactLandscapeControlsPromoted(tester);
    await _expectCompactGridIntelFlow(tester);
  });

  testWidgets('jump to frontier keeps the deep frontier tile visible', (
    tester,
  ) async {
    final provider = _DeepFrontierPuzzleAcademyProvider();

    await _pumpPuzzleGridScreen(
      tester,
      size: const Size(390, 844),
      provider: provider,
      node: _DeepFrontierPuzzleAcademyProvider.testNode,
    );

    final gridFinder = find.byKey(const ValueKey<String>('puzzle_grid_view'));
    await tester.drag(gridFinder, const Offset(0, 2400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    await tester.tap(find.byTooltip('Jump to frontier'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final frontierTile = find.byKey(
      const ValueKey<String>('puzzle_grid_tile_152'),
    );
    expect(frontierTile, findsOneWidget);

    final gridRect = tester.getRect(gridFinder);
    final tileRect = tester.getRect(frontierTile);
    expect(tileRect.top, greaterThanOrEqualTo(gridRect.top - 1));
    expect(tileRect.bottom, lessThanOrEqualTo(gridRect.bottom + 1));

    await tester.pump(const Duration(milliseconds: 900));
  });
}
