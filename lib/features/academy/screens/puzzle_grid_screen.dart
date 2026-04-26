import 'dart:math';

import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/academy/screens/puzzle_node_screen.dart';
import 'package:chessiq/features/academy/widgets/puzzle_academy_surface.dart';
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
  bool _compactGridIntelExpanded = false;
  _GridMetrics? _activeGridMetrics;
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

      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_frontierScrollOffset(visibleIndex: frontier));
    });
  }

  @override
  Widget build(BuildContext context) {
    final academy = context.watch<PuzzleAcademyProvider>();
    final appTheme = context.watch<AppThemeProvider>();
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final monochrome = appTheme.isMonochrome || widget.cinematicThemeEnabled;
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final safeHeight = media.size.height - media.padding.vertical;
    final isLandscape = media.size.width > safeHeight;
    final compactLandscape = isLandscape && safeHeight <= 500;
    final compactPortrait =
        !isLandscape && (safeHeight <= 780 || media.size.width <= 430);
    final compactPhoneLayout =
        compactLandscape || compactPortrait || media.size.width <= 430;
    final pagePadding = EdgeInsets.fromLTRB(
      compactPhoneLayout ? 12 : 16,
      compactLandscape ? 8 : 12,
      compactPhoneLayout ? 12 : 16,
      compactLandscape ? 10 : 16,
    );
    final headerPadding = EdgeInsets.all(
      compactLandscape
          ? 10
          : compactPhoneLayout
          ? 12
          : 14,
    );
    final headerGap = compactLandscape
        ? 8.0
        : compactPhoneLayout
        ? 10.0
        : 12.0;
    final nodeAccent = widget.node.goldCrown ? palette.amber : palette.cyan;
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
    final statusPills = Wrap(
      key: const ValueKey<String>('puzzle_grid_status_pills'),
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusPill(
          label: 'FRONTIER ${frontier + 1}',
          icon: Icons.navigation_rounded,
          tone: nodeAccent,
          monochrome: monochrome,
          compact: compactPhoneLayout,
        ),
        _StatusPill(
          label: examUnlocked ? 'EXAM READY' : '$remainingToExam LEFT',
          icon: Icons.workspace_premium_outlined,
          tone: examUnlocked
              ? const Color(0xFF89DBA7)
              : const Color(0xFFD8B640),
          monochrome: monochrome,
          compact: compactPhoneLayout,
        ),
        if (!compactPhoneLayout && bestExam != null)
          _StatusPill(
            label: 'BEST ${bestExam.grade} ${bestExam.score}',
            icon: Icons.military_tech_outlined,
            tone: palette.amber,
            monochrome: monochrome,
            compact: compactPhoneLayout,
          ),
      ],
    );
    final compactIntelToggle = _CompactGridIntelButton(
      expanded: _compactGridIntelExpanded,
      monochrome: monochrome,
      onTap: () {
        setState(() {
          _compactGridIntelExpanded = !_compactGridIntelExpanded;
        });
      },
    );
    final modeChipChildren = <Widget>[
      _ModeChip(
        key: const ValueKey<String>('puzzle_grid_chip_all'),
        label: 'All',
        selected: _viewMode == _GridViewMode.all,
        icon: Icons.grid_view_rounded,
        monochrome: monochrome,
        compact: compactPhoneLayout,
        onTap: () {
          setState(() => _viewMode = _GridViewMode.all);
        },
      ),
      _ModeChip(
        key: const ValueKey<String>('puzzle_grid_chip_queue'),
        label: compactPhoneLayout ? 'Queue' : 'Action Queue',
        selected: _viewMode == _GridViewMode.actionable,
        icon: Icons.bolt_rounded,
        monochrome: monochrome,
        compact: compactPhoneLayout,
        onTap: () {
          setState(() => _viewMode = _GridViewMode.actionable);
        },
      ),
      _ModeChip(
        key: const ValueKey<String>('puzzle_grid_chip_overlay'),
        label: compactPhoneLayout ? 'Overlay' : 'Grid Overlay',
        selected: false,
        icon: Icons.open_in_full_rounded,
        monochrome: monochrome,
        compact: compactPhoneLayout,
        onTap: () {
          _openGridPopup(
            academy: academy,
            visibleIndices: visibleIndices,
            frontier: frontier,
            monochrome: monochrome,
          );
        },
      ),
    ];
    final modeChips = Wrap(
      key: const ValueKey<String>('puzzle_grid_mode_chips'),
      spacing: 8,
      runSpacing: 8,
      children: modeChipChildren,
    );
    final compactTopControls = Column(
      key: const ValueKey<String>('puzzle_grid_compact_top_controls'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[compactIntelToggle, modeChipChildren[0]],
        ),
        SizedBox(height: headerGap),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[modeChipChildren[1], modeChipChildren[2]],
        ),
      ],
    );
    final fullInfoButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: infoItems
          .map(
            (item) => _InfoQuickButton(
              item: item,
              monochrome: monochrome,
              onTap: () => _showInfoSheet(item),
            ),
          )
          .toList(growable: false),
    );
    final compactIntelPanel = PuzzleAcademyAnimatedSwap(
      child: _compactGridIntelExpanded
          ? Padding(
              key: const ValueKey<String>('puzzle_grid_compact_intel_panel'),
              padding: EdgeInsets.only(top: headerGap),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: infoItems
                    .map(
                      (item) => _InfoQuickButton(
                        item: item,
                        monochrome: monochrome,
                        compact: true,
                        onTap: () => _showInfoSheet(item),
                      ),
                    )
                    .toList(growable: false),
              ),
            )
          : const SizedBox(
              key: ValueKey<String>('puzzle_grid_compact_intel_collapsed'),
            ),
    );
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
            padding: pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: puzzleAcademyPanelDecoration(
                    palette: palette,
                    accent: nodeAccent,
                    radius: 10,
                  ),
                  child: Padding(
                    padding: headerPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: widget.heroTag,
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width: compactPhoneLayout ? 36 : 42,
                                  height: compactPhoneLayout ? 36 : 42,
                                  decoration: BoxDecoration(
                                    color: nodeAccent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: nodeAccent.withValues(alpha: 0.68),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${widget.node.startElo}',
                                      style: puzzleAcademyHudStyle(
                                        palette: palette,
                                        size: compactLandscape
                                            ? 10.4
                                            : compactPhoneLayout
                                            ? 11.0
                                            : 11.6,
                                        weight: FontWeight.w800,
                                        letterSpacing: 0.85,
                                        height: 1.0,
                                        color: palette.text,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.node.title} Grid',
                                    style: puzzleAcademyDisplayStyle(
                                      palette: palette,
                                      size: compactLandscape
                                          ? 15.6
                                          : compactPhoneLayout
                                          ? 16.6
                                          : 18,
                                      color: nodeAccent,
                                    ),
                                    maxLines: compactLandscape ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (!compactPhoneLayout) ...<Widget>[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Frontier #${frontier + 1} of $total. Keep the live surface minimal and open intel buttons for rules, scoring, and tile detail.',
                                      key: const ValueKey<String>(
                                        'puzzle_grid_header_body_copy',
                                      ),
                                      style: puzzleAcademyHudStyle(
                                        palette: palette,
                                        size: 11.7,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            PuzzleAcademyInfoButton(
                              title: 'Grid Intel',
                              message:
                                  'All shows every slot in the node. Action Queue only shows positions you can act on now: frontier, skipped, and replayable slots. Open tile detail on long press for specific state and queue placement.',
                              accent: nodeAccent,
                              monochromeOverride: monochrome,
                            ),
                          ],
                        ),
                        SizedBox(height: headerGap),
                        if (compactLandscape) ...<Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: statusPills),
                              const SizedBox(width: 10),
                              Expanded(child: compactTopControls),
                            ],
                          ),
                          compactIntelPanel,
                        ] else ...<Widget>[
                          statusPills,
                          SizedBox(height: headerGap),
                          if (compactPhoneLayout)
                            compactTopControls
                          else
                            modeChips,
                          if (!compactPhoneLayout) ...<Widget>[
                            SizedBox(height: headerGap),
                            fullInfoButtons,
                          ] else ...<Widget>[compactIntelPanel],
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: compactLandscape ? 8 : 12),
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
                      style: puzzleAcademyOutlinedButtonStyle(
                        palette: palette,
                        accent: palette.cyan,
                      ),
                      icon: const Icon(Icons.navigation_rounded),
                      label: Text(
                        compactPhoneLayout
                            ? 'Show full grid'
                            : 'Show full grid and jump to frontier',
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: puzzleAcademyPanelDecoration(
                      palette: palette,
                      accent: nodeAccent,
                      fillColor: palette.panel.withValues(alpha: 0.90),
                      radius: 10,
                      elevated: false,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(compactPhoneLayout ? 8 : 10),
                      child: _buildGridView(
                        academy: academy,
                        visibleIndices: visibleIndices,
                        frontier: frontier,
                        controller: _scrollController,
                        gridMetrics: gridMetrics,
                        monochrome: monochrome,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: palette.backdrop,
      appBar: AppBar(
        backgroundColor: palette.panel.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Puzzle Grid',
          style: puzzleAcademyDisplayStyle(
            palette: palette,
            size: 16,
            color: nodeAccent,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Jump to frontier',
            onPressed: () => _jumpToFrontier(
              _visibleIndexForFrontier(visibleIndices, frontier),
            ),
            icon: const Icon(Icons.navigation_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: PuzzleAcademyTag(
                label:
                    '${widget.node.solvedCount}/${widget.node.masteryTarget}',
                accent: palette.amber,
                icon: Icons.verified_outlined,
                monochromeOverride: monochrome,
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
    required bool monochrome,
    bool compactTiles = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final liveMetrics = _gridMetricsForCrossAxisCount(
          gridWidth: max(220.0, constraints.maxWidth),
          crossAxisCount: gridMetrics.crossAxisCount,
        );
        if (!compactTiles) {
          _activeGridMetrics = liveMetrics;
        }

        return GridView.builder(
          key: const ValueKey<String>('puzzle_grid_view'),
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
                key: ValueKey<String>('puzzle_grid_tile_${index + 1}'),
                index: index,
                state: tileState,
                isFrontier: index == frontier,
                enabled: enabled,
                compact: compactTiles,
                monochrome: monochrome,
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
                                  tileState !=
                                  PuzzleGridTileState.nextAvailable,
                              cinematicThemeEnabled:
                                  widget.cinematicThemeEnabled,
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
      },
    );
  }

  Future<void> _openGridPopup({
    required PuzzleAcademyProvider academy,
    required List<int> visibleIndices,
    required int frontier,
    required bool monochrome,
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.88,
          child: PuzzleAcademySheetShell(
            title: 'Grid Focus Mode',
            subtitle: 'Compact overlay for quick route scanning.',
            accent: const Color(0xFF6FE7FF),
            icon: Icons.open_in_full_rounded,
            trailing: PuzzleAcademyTag(
              label: 'FRONTIER ${frontier + 1}',
              accent: const Color(0xFF6FE7FF),
              monochromeOverride: monochrome,
            ),
            monochromeOverride: monochrome,
            child: Expanded(
              child: _buildGridView(
                academy: academy,
                visibleIndices: visibleIndices,
                frontier: frontier,
                controller: popupController,
                gridMetrics: metrics,
                monochrome: monochrome,
                compactTiles: true,
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
    return _gridMetricsForCrossAxisCount(
      gridWidth: gridWidth,
      crossAxisCount: crossAxisCount,
    );
  }

  _GridMetrics _gridMetricsForCrossAxisCount({
    required double gridWidth,
    required int crossAxisCount,
  }) {
    final totalSpacing = (crossAxisCount - 1) * _gridSpacing;
    final tileSize = (gridWidth - totalSpacing) / crossAxisCount;
    return _GridMetrics(
      crossAxisCount: crossAxisCount,
      rowExtent: tileSize + _gridSpacing,
    );
  }

  Future<void> _showInfoSheet(_GridInfoItem item) async {
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (sheetContext) {
        final palette = puzzleAcademyPalette(
          sheetContext,
          monochromeOverride: monochrome,
        );
        return PuzzleAcademySheetShell(
          title: item.title,
          subtitle: item.preview,
          accent: item.tone,
          icon: item.icon,
          monochromeOverride: monochrome,
          child: Text(
            item.detail,
            style: puzzleAcademyHudStyle(
              palette: palette,
              size: 12.1,
              weight: FontWeight.w600,
              height: 1.45,
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
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;
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
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (sheetContext) {
        final palette = puzzleAcademyPalette(
          sheetContext,
          monochromeOverride: monochrome,
        );
        final accent = switch (state) {
          PuzzleGridTileState.solved => const Color(0xFF9BE27C),
          PuzzleGridTileState.skipped => const Color(0xFFD8B640),
          PuzzleGridTileState.nextAvailable => const Color(0xFF6FE7FF),
          PuzzleGridTileState.replayable => const Color(0xFF89A7C7),
          PuzzleGridTileState.locked => palette.signal,
        };
        return PuzzleAcademySheetShell(
          title: 'Puzzle #${index + 1}',
          subtitle: status,
          accent: accent,
          icon: Icons.extension_outlined,
          monochromeOverride: monochrome,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PuzzleAcademyTag(
                    label: queueLabel.toUpperCase(),
                    accent: accent,
                    monochromeOverride: monochrome,
                  ),
                  PuzzleAcademyTag(
                    label: 'RATING ${puzzle?.rating ?? 'N/A'}',
                    accent: palette.amber,
                    monochromeOverride: monochrome,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                enabled
                    ? 'This slot is runnable now. Any solved or skipped result here still advances long-term exam unlock progress.'
                    : 'This slot is currently gated. Clear earlier frontier positions before this slot opens.',
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: 12.1,
                  weight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
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

  int _visibleIndexForFrontier(List<int> visibleIndices, int frontier) {
    final visibleIndex = visibleIndices.indexOf(frontier);
    return visibleIndex >= 0 ? visibleIndex : frontier;
  }

  double _frontierScrollOffset({required int visibleIndex}) {
    if (!_scrollController.hasClients) return 0.0;
    final metrics =
        _activeGridMetrics ??
        _gridMetricsForWidth(MediaQuery.sizeOf(context).width);
    final rowIndex = visibleIndex ~/ metrics.crossAxisCount;
    final rowOffset = rowIndex * metrics.rowExtent;
    final viewportDimension = _scrollController.position.viewportDimension;
    final leadingInset = viewportDimension <= metrics.rowExtent
        ? 0.0
        : max(
            metrics.rowExtent * 0.7,
            (viewportDimension - metrics.rowExtent) * 0.18,
          );
    final maxScroll = _scrollController.position.maxScrollExtent;
    return (rowOffset - leadingInset).clamp(0.0, maxScroll);
  }

  void _jumpToFrontier(int visibleIndex) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _frontierScrollOffset(visibleIndex: visibleIndex),
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
    required this.monochrome,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color tone;
  final bool monochrome;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: monochrome ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tone.withValues(alpha: 0.48), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 14, color: tone),
          const SizedBox(width: 6),
          Text(
            label,
            style: puzzleAcademyHudStyle(
              palette: palette,
              size: compact ? 10.0 : 10.8,
              weight: FontWeight.w800,
              letterSpacing: 0.9,
              height: 1.0,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoQuickButton extends StatelessWidget {
  const _InfoQuickButton({
    required this.item,
    required this.onTap,
    required this.monochrome,
    this.compact = false,
  });

  final _GridInfoItem item;
  final VoidCallback onTap;
  final bool monochrome;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 10,
            vertical: compact ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: item.tone.withValues(alpha: monochrome ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: item.tone.withValues(alpha: 0.52),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: compact ? 13 : 14, color: item.tone),
              const SizedBox(width: 6),
              Text(
                item.title.toUpperCase(),
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: compact ? 10.0 : 10.6,
                  weight: FontWeight.w800,
                  letterSpacing: 0.9,
                  height: 1.0,
                  color: palette.text,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline_rounded,
                size: compact ? 12 : 13,
                color: item.tone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.icon,
    required this.monochrome,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final bool monochrome;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final accentCyan = palette.cyan;
    final tone = selected ? accentCyan : palette.text;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: selected
            ? accentCyan.withValues(alpha: monochrome ? 0.20 : 0.14)
            : palette.panelAlt.withValues(alpha: monochrome ? 0.94 : 0.90),
        border: Border.all(
          color: selected
              ? accentCyan.withValues(alpha: 0.74)
              : palette.line.withValues(alpha: 0.48),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 7 : 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact ? 15 : 16,
                color: tone.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: compact ? 10.0 : 10.8,
                  weight: FontWeight.w800,
                  letterSpacing: 0.9,
                  height: 1.0,
                  color: tone.withValues(alpha: selected ? 0.96 : 0.82),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactGridIntelButton extends StatelessWidget {
  const _CompactGridIntelButton({
    required this.expanded,
    required this.monochrome,
    required this.onTap,
  });

  final bool expanded;
  final bool monochrome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );

    return OutlinedButton.icon(
      key: const ValueKey<String>('puzzle_grid_compact_intel_toggle'),
      onPressed: onTap,
      style: puzzleAcademyOutlinedButtonStyle(
        palette: palette,
        accent: palette.amber,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: Icon(
        expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        size: 18,
      ),
      label: Text(expanded ? 'HIDE INTEL' : 'MORE INTEL'),
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
    super.key,
    required this.index,
    required this.state,
    required this.isFrontier,
    required this.enabled,
    required this.compact,
    required this.monochrome,
    required this.onTap,
    required this.onLongPress,
  });

  final int index;
  final PuzzleGridTileState state;
  final bool isFrontier;
  final bool enabled;
  final bool compact;
  final bool monochrome;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final isDark = palette.isDark;
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
    final tileAlpha = enabled ? (isDark ? 0.32 : 0.52) : (isDark ? 0.18 : 0.35);
    final fillColor = Color.alphaBlend(
      color.withValues(alpha: tileAlpha),
      palette.panel,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
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
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          child: Ink(
            decoration: puzzleAcademyPanelDecoration(
              palette: palette,
              accent: color,
              fillColor: fillColor,
              borderColor: color.withValues(alpha: enabled ? 0.88 : 0.45),
              radius: compact ? 6 : 8,
              borderWidth: compact ? 1.4 : 2,
              elevated: isFrontier,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: compact ? 8.6 : 14.2,
                  weight: FontWeight.w800,
                  letterSpacing: compact ? 0.45 : 0.8,
                  height: 1.0,
                  color: enabled
                      ? tileTextColor
                      : tileTextColor.withValues(alpha: 0.78),
                  withGlow: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
