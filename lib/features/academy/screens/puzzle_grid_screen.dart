import 'dart:math';

import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/academy/screens/puzzle_node_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class PuzzleGridScreen extends StatefulWidget {
  const PuzzleGridScreen({
    super.key,
    required this.node,
    required this.heroTag,
    this.cinematicThemeEnabled = false,
  });

  final EloNodeProgress node;
  final String heroTag;
  final bool cinematicThemeEnabled;

  @override
  State<PuzzleGridScreen> createState() => _PuzzleGridScreenState();
}

enum _GridViewMode { all, actionable }

class _PuzzleGridScreenState extends State<PuzzleGridScreen> {
  late final ScrollController _scrollController;
  late final ValueNotifier<double> _scrollForce;
  double _lastScrollPosition = 0.0;
  bool _didScrollToFrontier = false;
  _GridViewMode _viewMode = _GridViewMode.all;
  static const double _gridHorizontalPadding = 32.0;
  static const double _gridSpacing = 10.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _scrollForce = ValueNotifier<double>(0.0);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position.pixels;
    final delta = position - _lastScrollPosition;
    _lastScrollPosition = position;

    final rawImpulse = (-delta / 20).clamp(-1.2, 1.2);
    final nextForce = (_scrollForce.value * 0.2) + (rawImpulse * 0.8);
    _scrollForce.value = nextForce.abs() < 0.001 ? 0.0 : nextForce;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _scrollForce.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didScrollToFrontier) return;
    _didScrollToFrontier = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final academy = context.read<PuzzleAcademyProvider>();
      final frontier = academy.frontierPuzzleIndexForNode(widget.node);
      if (frontier <= 0) return;

      final metrics = _gridMetricsForWidth(MediaQuery.sizeOf(context).width);
      final rowIndex = frontier ~/ metrics.crossAxisCount;
      final offset = max(
        0.0,
        (rowIndex * metrics.rowExtent) - (metrics.rowExtent * 0.35),
      );

      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(offset.clamp(0.0, maxScroll));
    });
  }

  @override
  Widget build(BuildContext context) {
    final academy = context.watch<PuzzleAcademyProvider>();
    final appTheme = context.watch<AppThemeProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final monochrome = appTheme.isMonochrome || widget.cinematicThemeEnabled;
    final total = academy.gridPuzzleCountForNode(widget.node);
    final frontier = academy.frontierPuzzleIndexForNode(widget.node);
    final examTarget = academy.examUnlockSolveTarget(widget.node);
    final completedCount = academy.completedPuzzleCountForNode(
      widget.node,
      academy.progress,
    );
    final remainingToExam = max(0, examTarget - completedCount);
    final examUnlocked = academy.canTakeExam(widget.node);
    final bestExam = academy.bestExamResultForNode(widget.node.key);
    final gridMetrics = _gridMetricsForWidth(MediaQuery.sizeOf(context).width);

    final infoItems = <_GridInfoItem>[
      _GridInfoItem(
        title: 'Exam Gate',
        preview: examUnlocked ? 'Unlocked' : '$remainingToExam left',
        detail:
            'Exam access for this level unlocks after $examTarget completed puzzles. Completed means solved plus skipped. Current progress is $completedCount/$examTarget.',
        tone: examUnlocked ? const Color(0xFF89DBA7) : const Color(0xFFD8B640),
        icon: Icons.workspace_premium_outlined,
      ),
      _GridInfoItem(
        title: 'Scoring',
        preview: '0.5x – 1.5x weight',
        detail:
            'Exam score is out of 10,000: 80% comes from accuracy (correct answers out of 50) and 20% from speed (time remaining when finished). That raw score is then multiplied by an ELO weight: 0.5× at ELO 450 (lowest bracket) up to 1.5× at ELO 3999 (highest bracket). Higher brackets earn more leaderboard points for the same performance. Formula: weight = 0.5 + ((bracketELO − 450) / (3999 − 450)).',
        tone: const Color(0xFF92B7E6),
        icon: Icons.query_stats_rounded,
      ),
      if (bestExam != null)
        _GridInfoItem(
          title: 'Best Exam',
          preview: '${bestExam.grade}, ${bestExam.score}',
          detail:
              'Best exam run in this node is stored for progression snapshots and ranking aggregation.',
          tone: const Color(0xFFB3D9A2),
          icon: Icons.military_tech_outlined,
        ),
    ];

    final visibleIndices = List<int>.generate(total, (index) => index)
        .where(
          (index) => _matchesMode(
            academy.tileStateForNodeIndex(widget.node, index),
            academy,
            index,
          ),
        )
        .toList(growable: false);

    final visibleFrontier = visibleIndices.contains(frontier);
    final content = Stack(
      children: [
        Positioned.fill(
          child: _GridBackdrop(
            monochrome: monochrome,
            scrollForce: _scrollForce,
            isDark: theme.brightness == Brightness.dark,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Hero(
                        tag: widget.heroTag,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.node.goldCrown
                                    ? const Color(0xFFD8B640)
                                    : const Color(0xFF6FE7FF),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.node.startElo}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.92,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Frontier #${frontier + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(
                        label: '$completedCount/$examTarget',
                        icon: Icons.verified_outlined,
                        tone: examUnlocked
                            ? const Color(0xFF89DBA7)
                            : const Color(0xFFD8B640),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ModeChip(
                        label: 'All',
                        selected: _viewMode == _GridViewMode.all,
                        icon: Icons.grid_view_rounded,
                        onTap: () {
                          setState(() => _viewMode = _GridViewMode.all);
                        },
                      ),
                      const SizedBox(width: 8),
                      _ModeChip(
                        label: 'Action Queue',
                        selected: _viewMode == _GridViewMode.actionable,
                        icon: Icons.bolt_rounded,
                        onTap: () {
                          setState(() => _viewMode = _GridViewMode.actionable);
                        },
                      ),
                      const SizedBox(width: 8),
                      _ModeChip(
                        label: 'Grid Overlay',
                        selected: false,
                        icon: Icons.open_in_full_rounded,
                        onTap: () {
                          _openGridPopup(
                            academy: academy,
                            visibleIndices: visibleIndices,
                            frontier: frontier,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: infoItems
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _InfoQuickButton(
                              item: item,
                              onTap: () => _showInfoSheet(item),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 12),
                if (!visibleFrontier && _viewMode != _GridViewMode.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _viewMode = _GridViewMode.all);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _jumpToFrontier(frontier);
                        });
                      },
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text('Show full grid and jump to frontier'),
                    ),
                  ),
                Expanded(
                  child: _buildGridView(
                    academy: academy,
                    visibleIndices: visibleIndices,
                    frontier: frontier,
                    controller: _scrollController,
                    gridMetrics: gridMetrics,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(widget.node.title),
        actions: [
          IconButton(
            tooltip: 'Jump to frontier',
            onPressed: () => _jumpToFrontier(frontier),
            icon: const Icon(Icons.navigation_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '${widget.node.solvedCount}/${widget.node.masteryTarget}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildGridView({
    required PuzzleAcademyProvider academy,
    required List<int> visibleIndices,
    required int frontier,
    required ScrollController controller,
    required _GridMetrics gridMetrics,
    bool compactTiles = false,
  }) {
    return GridView.builder(
      controller: controller,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridMetrics.crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: visibleIndices.length,
      itemBuilder: (context, visibleIndex) {
        final index = visibleIndices[visibleIndex];
        final puzzle = academy.puzzleForNodeIndex(widget.node, index);
        final tileState = academy.tileStateForNodeIndex(widget.node, index);
        final enabled =
            puzzle != null && academy.canOpenGridIndex(widget.node, index);

        return _AnimatedGridTile(
          order: visibleIndex,
          child: _GridTile(
            index: index,
            state: tileState,
            isFrontier: index == frontier,
            enabled: enabled,
            compact: compactTiles,
            onLongPress: () {
              _showTileDetails(
                index: index,
                state: tileState,
                puzzle: puzzle,
                enabled: enabled,
              );
            },
            onTap: !enabled
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PuzzleNodeScreen(
                          node: widget.node,
                          heroTag: widget.heroTag,
                          initialPuzzle: puzzle,
                          initialPuzzleIndex: index,
                          initialReviewMode:
                              tileState != PuzzleGridTileState.nextAvailable,
                          cinematicThemeEnabled: widget.cinematicThemeEnabled,
                          onExitToMap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
          ),
        );
      },
    );
  }

  Future<void> _openGridPopup({
    required PuzzleAcademyProvider academy,
    required List<int> visibleIndices,
    required int frontier,
  }) async {
    final metrics = _gridMetricsForWidth(
      MediaQuery.sizeOf(context).width,
      tileScale: 0.30,
      maxCrossAxisCount: 10,
    );
    final rowIndex = frontier ~/ metrics.crossAxisCount;
    final initialOffset = max(
      0.0,
      (rowIndex * metrics.rowExtent) - (metrics.rowExtent * 0.35),
    );
    final popupController = ScrollController(
      initialScrollOffset: initialOffset,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.88,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Grid Focus Mode',
                        style: sheetTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Frontier #${frontier + 1}',
                        style: TextStyle(
                          color: sheetTheme.colorScheme.onSurface.withValues(
                            alpha: 0.74,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildGridView(
                      academy: academy,
                      visibleIndices: visibleIndices,
                      frontier: frontier,
                      controller: popupController,
                      gridMetrics: metrics,
                      compactTiles: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    popupController.dispose();
  }

  _GridMetrics _gridMetricsForWidth(
    double viewportWidth, {
    double tileScale = 1.0,
    int? maxCrossAxisCount,
  }) {
    final gridWidth = max(220.0, viewportWidth - _gridHorizontalPadding);
    final baseCount = max(4, (gridWidth / 78).floor());
    final scale = tileScale.clamp(0.2, 1.0);
    final rawCount = max(baseCount, (baseCount / scale).round());
    final crossAxisCount = maxCrossAxisCount != null
        ? rawCount.clamp(1, maxCrossAxisCount)
        : rawCount;
    final totalSpacing = (crossAxisCount - 1) * _gridSpacing;
    final tileSize = (gridWidth - totalSpacing) / crossAxisCount;
    return _GridMetrics(
      crossAxisCount: crossAxisCount,
      rowExtent: tileSize + _gridSpacing,
    );
  }

  Future<void> _showInfoSheet(_GridInfoItem item) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, color: item.tone),
                    const SizedBox(width: 8),
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.preview,
                  style: TextStyle(
                    color: item.tone,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.detail,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _matchesMode(
    PuzzleGridTileState state,
    PuzzleAcademyProvider academy,
    int index,
  ) {
    if (_viewMode == _GridViewMode.all) {
      return true;
    }

    if (_viewMode == _GridViewMode.actionable) {
      final canOpen = academy.canOpenGridIndex(widget.node, index);
      return canOpen &&
          (state == PuzzleGridTileState.nextAvailable ||
              state == PuzzleGridTileState.skipped ||
              state == PuzzleGridTileState.replayable);
    }

    return false;
  }

  Future<void> _showTileDetails({
    required int index,
    required PuzzleGridTileState state,
    required PuzzleItem? puzzle,
    required bool enabled,
  }) async {
    final academy = context.read<PuzzleAcademyProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = _stateLabel(state);
    final frontier = academy.frontierPuzzleIndexForNode(widget.node);
    final queueDelta = index - frontier;
    final queueLabel = queueDelta < 0
        ? '${queueDelta.abs()} slots behind frontier'
        : queueDelta == 0
        ? 'Current frontier slot'
        : '$queueDelta slots ahead of frontier';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puzzle #${index + 1} • $status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  queueLabel,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rating band: ${widget.node.title} • Puzzle rating: ${puzzle?.rating ?? 'unavailable'}',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  enabled
                      ? 'This slot is runnable now. Long-term completion also contributes to the 150-puzzle exam threshold.'
                      : 'This slot is currently gated. Progress earlier frontier positions to unlock it.',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.70),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _stateLabel(PuzzleGridTileState state) {
    return switch (state) {
      PuzzleGridTileState.solved => 'Solved',
      PuzzleGridTileState.skipped => 'Skipped',
      PuzzleGridTileState.nextAvailable => 'Frontier',
      PuzzleGridTileState.replayable => 'Replayable',
      PuzzleGridTileState.locked => 'Locked',
    };
  }

  void _jumpToFrontier(int frontier) {
    if (!_scrollController.hasClients) return;
    final metrics = _gridMetricsForWidth(MediaQuery.sizeOf(context).width);
    final rowIndex = frontier ~/ metrics.crossAxisCount;
    final offset = max(
      0.0,
      (rowIndex * metrics.rowExtent) - (metrics.rowExtent * 0.35),
    );
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      offset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }
}

class _GridBackdrop extends StatefulWidget {
  const _GridBackdrop({
    required this.monochrome,
    required this.scrollForce,
    required this.isDark,
  });

  final bool monochrome;
  final ValueNotifier<double> scrollForce;
  final bool isDark;

  @override
  State<_GridBackdrop> createState() => _GridBackdropState();
}

class _GridBackdropState extends State<_GridBackdrop>
    with SingleTickerProviderStateMixin {
  late final Ticker _blueDotTicker;
  late final ValueNotifier<double> _blueDotTime;
  late Duration _blueDotLastTick;
  late final double _blueDotPhase;
  late final double _blueDotShapeSeed;
  late final double _blueDotTrajectoryNoise;
  late final double _blueDotRadius;
  double _blueDotScrollVelocity = 0.0;
  double _blueDotScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _blueDotTime = ValueNotifier<double>(0.0);
    _blueDotLastTick = Duration.zero;
    _blueDotTicker = createTicker((elapsed) {
      final delta = elapsed - _blueDotLastTick;
      _blueDotLastTick = elapsed;
      final dt = delta.inMilliseconds / 1000.0;
      _blueDotTime.value += dt;
      final impulse = widget.scrollForce.value;
      if (impulse != 0.0) {
        _blueDotScrollVelocity += impulse * 0.7;
        widget.scrollForce.value = 0.0;
      }
      _blueDotScrollVelocity *= 0.93;
      _blueDotScrollOffset += _blueDotScrollVelocity * dt;
      _blueDotScrollOffset = _blueDotScrollOffset.clamp(-1.15, 1.15);
    })..start();

    final random = Random();
    _blueDotPhase = random.nextDouble() * 2 * pi;
    _blueDotShapeSeed = random.nextDouble() * 3.2;
    _blueDotTrajectoryNoise = random.nextDouble();
    _blueDotRadius = 0.58 + random.nextDouble() * 0.12;
  }

  @override
  void dispose() {
    _blueDotTicker.dispose();
    _blueDotTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = widget.isDark;
    final baseSurface = scheme.surface;
    final gradientStart = widget.monochrome
        ? (isDark ? const Color(0xFF070707) : const Color(0xFFF8F5F0))
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: isDark ? 0.24 : 0.08),
            baseSurface,
          );
    final gradientEnd = widget.monochrome
        ? (isDark ? const Color(0xFF141414) : const Color(0xFFECE8E2))
        : Color.alphaBlend(
            scheme.secondary.withValues(alpha: isDark ? 0.18 : 0.08),
            baseSurface,
          );
    final accentTop = widget.monochrome
        ? Colors.white10
        : scheme.primary.withValues(alpha: isDark ? 0.12 : 0.16);
    final accentBottom = widget.monochrome
        ? Colors.white12
        : scheme.secondary.withValues(alpha: isDark ? 0.10 : 0.12);
    final dotColor = isDark ? const Color(0xFF5AAEE8) : const Color(0xFF6FE7FF);
    final dotShadowColor = dotColor.withValues(alpha: isDark ? 0.45 : 0.72);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentTop,
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentBottom,
              ),
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _blueDotTime,
            builder: (context, time, child) {
              return Align(
                alignment: _gridBackdropDotAlignment(
                  _blueDotPhase,
                  0.55,
                  _blueDotRadius,
                  time,
                  _blueDotTrajectoryNoise,
                  _blueDotShapeSeed,
                  _blueDotScrollOffset,
                ),
                child: child,
              );
            },
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor.withValues(alpha: 0.92),
                boxShadow: [
                  BoxShadow(
                    color: dotShadowColor,
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Alignment _gridBackdropDotAlignment(
    double phase,
    double speed,
    double radius,
    double pulse,
    double trajectoryNoise,
    double shapeSeed,
    double scrollOffset,
  ) {
    final time = pulse * 1.26 * speed + phase + shapeSeed;
    final x =
        sin(time * (1.25 + shapeSeed * 0.14)) * radius +
        sin(time * (2.6 + shapeSeed * 0.22) + 1.3 + shapeSeed * 0.9) * 0.09 +
        sin(time * (3.5 + shapeSeed * 0.35) + 2.1) * 0.035;
    final y =
        cos(time * (1.77 + shapeSeed * 0.18) + 0.4) * radius * 0.88 +
        cos(time * (2.35 + shapeSeed * 0.15) - 0.8) * 0.09 +
        sin(time * (3.5 + shapeSeed * 0.28) + 0.6) * 0.035;
    final driftX = sin(time * (0.64 + shapeSeed * 0.04) + 1.2) * 0.015;
    final driftY = cos(time * (0.71 + shapeSeed * 0.03) - 0.7) * 0.015;
    final jitterX =
        sin(
          time * (0.92 + trajectoryNoise * 0.18 + shapeSeed * 0.06) +
              trajectoryNoise * 3.7,
        ) *
        (trajectoryNoise * 0.025 + shapeSeed * 0.015);
    final jitterY =
        cos(
          time * (1.08 + trajectoryNoise * 0.22 - shapeSeed * 0.07) -
              trajectoryNoise * 2.9,
        ) *
        (trajectoryNoise * 0.025 + shapeSeed * 0.015);
    final raw = Offset(
      x + driftX + jitterX + (scrollOffset * 0.03),
      y + driftY + jitterY + (scrollOffset * 0.90),
    );
    final distance = raw.distance;
    const limit = 1.35;
    final returnFactor = distance > limit ? limit / distance : 1.0;
    return Alignment(raw.dx * returnFactor, raw.dy * returnFactor);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.tone,
  });

  final String label;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoQuickButton extends StatelessWidget {
  const _InfoQuickButton({required this.item, required this.onTap});

  final _GridInfoItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: item.tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: item.tone.withValues(alpha: 0.42)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 14, color: item.tone),
              const SizedBox(width: 6),
              Text(
                '${item.title}: ${item.preview}',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.90),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.info_outline_rounded, size: 13, color: item.tone),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use a visible cyan in dark mode, a deeper teal in light mode.
    final accentCyan = isDark
        ? const Color(0xFF6FE7FF)
        : const Color(0xFF0E7490);
    final tone = selected ? accentCyan : scheme.onSurface;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: selected
            ? accentCyan.withValues(alpha: isDark ? 0.16 : 0.12)
            : scheme.surface.withValues(alpha: isDark ? 0.28 : 0.85),
        border: Border.all(
          color: selected
              ? accentCyan.withValues(alpha: isDark ? 0.62 : 0.80)
              : scheme.outline.withValues(alpha: 0.28),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: tone.withValues(alpha: 0.92)),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: tone.withValues(alpha: selected ? 0.96 : 0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedGridTile extends StatefulWidget {
  const _AnimatedGridTile({required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  State<_AnimatedGridTile> createState() => _AnimatedGridTileState();
}

class _GridInfoItem {
  const _GridInfoItem({
    required this.title,
    required this.preview,
    required this.detail,
    required this.tone,
    required this.icon,
  });

  final String title;
  final String preview;
  final String detail;
  final Color tone;
  final IconData icon;
}

class _GridMetrics {
  const _GridMetrics({required this.crossAxisCount, required this.rowExtent});

  final int crossAxisCount;
  final double rowExtent;
}

class _AnimatedGridTileState extends State<_AnimatedGridTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delayBucket = (widget.order % 10) * 18;
    Future<void>.delayed(Duration(milliseconds: 40 + delayBucket), () {
      if (!mounted) return;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.index,
    required this.state,
    required this.isFrontier,
    required this.enabled,
    required this.compact,
    required this.onTap,
    required this.onLongPress,
  });

  final int index;
  final PuzzleGridTileState state;
  final bool isFrontier;
  final bool enabled;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (state) {
      PuzzleGridTileState.solved => const Color(0xFF9BE27C),
      PuzzleGridTileState.skipped => const Color(0xFFD8B640),
      PuzzleGridTileState.nextAvailable => const Color(0xFF6FE7FF),
      PuzzleGridTileState.replayable => const Color(0xFF89A7C7),
      PuzzleGridTileState.locked =>
        isDark ? const Color(0xFF4A5362) : const Color(0xFF8A95A6),
    };
    final tileTextColor = switch (state) {
      PuzzleGridTileState.locked =>
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.42),
      PuzzleGridTileState.nextAvailable =>
        isDark ? const Color(0xFFE9FBFF) : const Color(0xFF004455),
      _ => (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.90),
    };
    // In light mode use stronger fill alpha so tiles stand out.
    final tileAlpha = enabled ? (isDark ? 0.32 : 0.52) : (isDark ? 0.18 : 0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 7 : 16),
        boxShadow: isFrontier
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.36),
                  blurRadius: compact ? 8 : 18,
                  spreadRadius: compact ? 0 : 1,
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(compact ? 7 : 16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 7 : 16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: tileAlpha + 0.08),
                  color.withValues(alpha: tileAlpha),
                ],
              ),
              border: Border.all(
                color: color.withValues(alpha: enabled ? 0.88 : 0.45),
                width: compact ? 0.8 : (enabled ? 1.2 : 1.0),
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 9 : 16,
                  color: enabled
                      ? tileTextColor
                      : tileTextColor.withValues(alpha: 0.78),
                  shadows: const [
                    Shadow(
                      color: Color(0x7F000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
