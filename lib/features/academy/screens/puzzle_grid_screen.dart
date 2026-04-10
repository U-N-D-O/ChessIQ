import 'dart:math';
import 'dart:ui';

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

class _PuzzleGridScreenState extends State<PuzzleGridScreen> {
  late final ScrollController _scrollController;
  late final ValueNotifier<double> _scrollForce;
  double _lastScrollPosition = 0.0;
  bool _didScrollToFrontier = false;

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

      final screenWidth = MediaQuery.sizeOf(context).width;
      final gridWidth = screenWidth - 32.0;
      final crossAxisCount = max(4, (gridWidth / 78).floor());
      final spacing = 10.0;
      final totalSpacing = (crossAxisCount - 1) * spacing;
      final tileSize = (gridWidth - totalSpacing) / crossAxisCount;
      final rowIndex = frontier ~/ crossAxisCount;
      final offset = rowIndex * (tileSize + spacing);

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
    final content = Stack(
      children: [
        Positioned.fill(
          child: _GridBackdrop(
            monochrome: monochrome,
            scrollForce: _scrollForce,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          scheme.primary.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.12
                                : 0.04,
                          ),
                          scheme.surface,
                        ).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Hero(
                            tag: widget.heroTag,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color.alphaBlend(
                                        scheme.primary.withValues(alpha: 0.24),
                                        scheme.surface,
                                      ),
                                      Color.alphaBlend(
                                        scheme.secondary.withValues(
                                          alpha: 0.10,
                                        ),
                                        scheme.surface,
                                      ),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: widget.node.goldCrown
                                        ? const Color(0xFFD8B640)
                                        : scheme.primary,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${widget.node.startElo}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Elo Bracket ${widget.node.title}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Green is solved, amber is skipped, cyan is the next live puzzle, and dimmed squares stay locked until you reach them. Once you have finished 150 puzzles in this course, the course exam becomes available.',
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _LegendChip(label: 'Solved', color: Color(0xFF9BE27C)),
                    _LegendChip(label: 'Skipped', color: Color(0xFFD8B640)),
                    _LegendChip(
                      label: 'Next Available',
                      color: Color(0xFF6FE7FF),
                    ),
                    _LegendChip(label: 'Locked', color: Color(0xFF4A5362)),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: max(
                        4,
                        (MediaQuery.sizeOf(context).width / 78).floor(),
                      ),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: total,
                    itemBuilder: (context, index) {
                      final puzzle = academy.puzzleForNodeIndex(
                        widget.node,
                        index,
                      );
                      final tileState = academy.tileStateForNodeIndex(
                        widget.node,
                        index,
                      );
                      return _GridTile(
                        index: index,
                        state: tileState,
                        isFrontier: index == frontier,
                        enabled:
                            puzzle != null &&
                            academy.canOpenGridIndex(widget.node, index),
                        onTap:
                            puzzle == null ||
                                !academy.canOpenGridIndex(widget.node, index)
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
                      );
                    },
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
        title: Text('Level ${widget.node.title}'),
        actions: [
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
}

class _GridBackdrop extends StatefulWidget {
  const _GridBackdrop({required this.monochrome, required this.scrollForce});

  final bool monochrome;
  final ValueNotifier<double> scrollForce;

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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.monochrome
              ? const [Color(0xFF070707), Color(0xFF141414)]
              : const [Color(0xFF06111B), Color(0xFF0E2234)],
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
                color: widget.monochrome
                    ? Colors.white10
                    : const Color(0xFF6FE7FF).withValues(alpha: 0.12),
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
                color: widget.monochrome
                    ? Colors.white12
                    : const Color(0xFFD8B640).withValues(alpha: 0.10),
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
                color: const Color(0xFF5AAEE8).withValues(alpha: 0.92),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5AAEE8).withValues(alpha: 0.45),
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

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.index,
    required this.state,
    required this.isFrontier,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final PuzzleGridTileState state;
  final bool isFrontier;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (state) {
      PuzzleGridTileState.solved => const Color(0xFF9BE27C),
      PuzzleGridTileState.skipped => const Color(0xFFD8B640),
      PuzzleGridTileState.nextAvailable => const Color(0xFF6FE7FF),
      PuzzleGridTileState.replayable => const Color(0xFF89A7C7),
      PuzzleGridTileState.locked => const Color(0xFF4A5362),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFrontier
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.36),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color.withValues(alpha: enabled ? 0.22 : 0.12),
              border: Border.all(
                color: color.withValues(alpha: enabled ? 0.70 : 0.30),
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: enabled
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.54),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
