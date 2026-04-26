import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/academy/screens/puzzle_node_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestPuzzleAcademyProvider extends PuzzleAcademyProvider {
  _TestPuzzleAcademyProvider()
    : _progress = PuzzleProgressModel.initial(nodes: {testNode.key: testNode});

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

  static final List<PuzzleItem> trainingPuzzles = List<PuzzleItem>.generate(
    12,
    (index) => _buildPuzzle(
      id: 'training_${index + 1}',
      rating: 450 + (index * 5),
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
  List<PuzzleItem> puzzlesForNode(EloNodeProgress node) => trainingPuzzles;

  @override
  int examUnlockSolveTarget(EloNodeProgress node) => 6;

  @override
  bool canTakeExam(EloNodeProgress node) => false;
}

PuzzleItem _buildPuzzle({required String id, required int rating}) {
  return PuzzleItem(
    puzzleId: id,
    fen: '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',
    moves: const <String>['e2e4', 'e8e7'],
    rating: rating,
    gameUrl: 'https://example.com/$id',
    themes: const <String>['fork'],
    openingTags: const <String>['italian-game'],
  );
}

final List<PuzzleItem> _dailySequence = List<PuzzleItem>.generate(
  3,
  (index) => _buildPuzzle(id: 'daily_${index + 1}', rating: 450 + index),
);

final List<PuzzleItem> _examSequence = List<PuzzleItem>.generate(
  50,
  (index) => _buildPuzzle(id: 'exam_${index + 1}', rating: 450 + index),
);

Future<void> _pumpPuzzleNodeScreen(
  WidgetTester tester, {
  required Size size,
  required PuzzleAcademyProvider provider,
  required PuzzleNodeScreen screen,
}) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PuzzleAcademyProvider>.value(value: provider),
        ChangeNotifierProvider<AppThemeProvider>(
          create: (_) => AppThemeProvider(),
        ),
      ],
      child: MaterialApp(home: screen),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

String _textForKey(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(ValueKey<String>(key))).data ?? '';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('training compact portrait uses eval strip and keeps board wide', (
    tester,
  ) async {
    final provider = _TestPuzzleAcademyProvider();

    await _pumpPuzzleNodeScreen(
      tester,
      size: const Size(390, 844),
      provider: provider,
      screen: PuzzleNodeScreen(
        node: _TestPuzzleAcademyProvider.testNode,
        heroTag: 'training-portrait',
        initialPuzzle: _TestPuzzleAcademyProvider.trainingPuzzles.first,
        initialPuzzleIndex: 0,
      ),
    );

    expect(find.byKey(const ValueKey<String>('puzzle_node_top_bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('puzzle_node_compact_landscape_header')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('puzzle_node_compact_eval_strip')),
      findsOneWidget,
    );

    final evalStripRect = tester.getRect(
      find.byKey(const ValueKey<String>('puzzle_node_compact_eval_strip')),
    );
    final boardRect = tester.getRect(
      find.byKey(const ValueKey<String>('puzzle_node_board_square')),
    );
    final boardCardRect = tester.getRect(
      find.byKey(const ValueKey<String>('puzzle_node_board_card')),
    );
    final regretLabel = tester.widget<Text>(
      find.byKey(const ValueKey<String>('puzzle_node_regret_button_label')),
    );

    expect(evalStripRect.bottom, lessThanOrEqualTo(boardRect.top));
    expect(boardRect.width, greaterThan(boardCardRect.width - 60));
    expect(regretLabel.maxLines, 1);
  });

  testWidgets('daily compact portrait keeps the shared top bar wording', (
    tester,
  ) async {
    final provider = _TestPuzzleAcademyProvider();

    await _pumpPuzzleNodeScreen(
      tester,
      size: const Size(390, 844),
      provider: provider,
      screen: PuzzleNodeScreen(
        node: _TestPuzzleAcademyProvider.testNode,
        heroTag: 'daily-portrait',
        initialPuzzle: _dailySequence.first,
        initialPuzzleIndex: 0,
        puzzleSequence: _dailySequence,
        sequenceTitle: 'Daily Challenge',
      ),
    );

    expect(find.byKey(const ValueKey<String>('puzzle_node_top_bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('puzzle_node_compact_eval_strip')),
      findsOneWidget,
    );
    expect(
      _textForKey(tester, 'puzzle_node_header_title'),
      'Daily Challenge • 450-500',
    );
    expect(
      _textForKey(tester, 'puzzle_node_header_subtitle'),
      'Puzzle #1 of 3',
    );
  });

  testWidgets('exam compact portrait keeps the full header treatment', (
    tester,
  ) async {
    final provider = _TestPuzzleAcademyProvider();

    await _pumpPuzzleNodeScreen(
      tester,
      size: const Size(390, 844),
      provider: provider,
      screen: PuzzleNodeScreen(
        node: _TestPuzzleAcademyProvider.testNode,
        heroTag: 'exam-portrait',
        initialPuzzle: _examSequence.first,
        initialPuzzleIndex: 0,
        puzzleSequence: _examSequence,
        examMode: true,
        examDuration: const Duration(minutes: 10),
      ),
    );

    expect(find.byKey(const ValueKey<String>('puzzle_node_top_bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('puzzle_node_exam_progress_tag')),
      findsOneWidget,
    );
    expect(_textForKey(tester, 'puzzle_node_header_title'), 'Bracket 450-500 Exam');
    expect(
      _textForKey(tester, 'puzzle_node_header_subtitle'),
      'Puzzle #1 of 50 • 10m 00s left',
    );
  });

  testWidgets('training compact landscape moves header into the right rail', (
    tester,
  ) async {
    final provider = _TestPuzzleAcademyProvider();

    await _pumpPuzzleNodeScreen(
      tester,
      size: const Size(844, 390),
      provider: provider,
      screen: PuzzleNodeScreen(
        node: _TestPuzzleAcademyProvider.testNode,
        heroTag: 'training-landscape',
        initialPuzzle: _TestPuzzleAcademyProvider.trainingPuzzles.first,
        initialPuzzleIndex: 0,
      ),
    );

    expect(find.byKey(const ValueKey<String>('puzzle_node_top_bar')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('puzzle_node_compact_landscape_header')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('puzzle_node_rating_tile')), findsNothing);
    expect(find.byKey(const ValueKey<String>('puzzle_node_close_button')), findsOneWidget);
    expect(_textForKey(tester, 'puzzle_node_header_title'), '450-500');
    expect(_textForKey(tester, 'puzzle_node_header_subtitle'), '#1/12');
    expect(find.text('Elo Bracket 450-500'), findsNothing);
    expect(find.text('Puzzle #1 of 12'), findsNothing);

    final headerRect = tester.getRect(
      find.byKey(const ValueKey<String>('puzzle_node_compact_landscape_header')),
    );
    final boardRect = tester.getRect(
      find.byKey(const ValueKey<String>('puzzle_node_board_square')),
    );

    expect(headerRect.left, greaterThan(boardRect.right));
  });

  testWidgets('daily compact landscape shortens to minimal header copy', (
    tester,
  ) async {
    final provider = _TestPuzzleAcademyProvider();

    await _pumpPuzzleNodeScreen(
      tester,
      size: const Size(844, 390),
      provider: provider,
      screen: PuzzleNodeScreen(
        node: _TestPuzzleAcademyProvider.testNode,
        heroTag: 'daily-landscape',
        initialPuzzle: _dailySequence.first,
        initialPuzzleIndex: 0,
        puzzleSequence: _dailySequence,
        sequenceTitle: 'Daily Challenge',
      ),
    );

    expect(find.byKey(const ValueKey<String>('puzzle_node_top_bar')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('puzzle_node_compact_landscape_header')),
      findsOneWidget,
    );
    expect(_textForKey(tester, 'puzzle_node_header_title'), 'Daily');
    expect(_textForKey(tester, 'puzzle_node_header_subtitle'), '#1/3');
  });

  testWidgets('exam compact landscape keeps timer, tag, and bracket tile in rail', (
    tester,
  ) async {
    final provider = _TestPuzzleAcademyProvider();

    await _pumpPuzzleNodeScreen(
      tester,
      size: const Size(844, 390),
      provider: provider,
      screen: PuzzleNodeScreen(
        node: _TestPuzzleAcademyProvider.testNode,
        heroTag: 'exam-landscape',
        initialPuzzle: _examSequence.first,
        initialPuzzleIndex: 0,
        puzzleSequence: _examSequence,
        examMode: true,
        examDuration: const Duration(minutes: 10),
      ),
    );

    expect(find.byKey(const ValueKey<String>('puzzle_node_top_bar')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('puzzle_node_compact_landscape_header')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('puzzle_node_rating_tile')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('puzzle_node_exam_progress_tag')),
      findsOneWidget,
    );
    expect(_textForKey(tester, 'puzzle_node_header_title'), 'Exam');
    expect(_textForKey(tester, 'puzzle_node_header_subtitle'), '10m 00s');
    expect(find.text('0/50'), findsOneWidget);
    expect(find.text('Bracket 450-500 Exam'), findsNothing);
    expect(find.text('Puzzle #1 of 50'), findsNothing);
  });
}