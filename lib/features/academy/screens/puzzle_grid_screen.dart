import 'dart:math';
import 'dart:ui';

import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/academy/screens/puzzle_node_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class PuzzleGridScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final academy = context.watch<PuzzleAcademyProvider>();
    final appTheme = context.watch<AppThemeProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final monochrome = appTheme.isMonochrome || cinematicThemeEnabled;
    final total = academy.gridPuzzleCountForNode(node);
    final frontier = academy.frontierPuzzleIndexForNode(node);
    final content = Stack(
      children: [
        Positioned.fill(child: _GridBackdrop(monochrome: monochrome)),
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
                            tag: heroTag,
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
                                    color: node.goldCrown
                                        ? const Color(0xFFD8B640)
                                        : scheme.primary,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${node.startElo}',
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
                                  'Elo Bracket ${node.title}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Green is solved, amber is skipped, cyan is the next live puzzle, and dimmed squares stay locked until you reach them.',
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
                      final puzzle = academy.puzzleForNodeIndex(node, index);
                      final tileState = academy.tileStateForNodeIndex(
                        node,
                        index,
                      );
                      return _GridTile(
                        index: index,
                        state: tileState,
                        isFrontier: index == frontier,
                        enabled:
                            puzzle != null &&
                            academy.canOpenGridIndex(node, index),
                        onTap:
                            puzzle == null ||
                                !academy.canOpenGridIndex(node, index)
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PuzzleNodeScreen(
                                      node: node,
                                      heroTag: heroTag,
                                      initialPuzzle: puzzle,
                                      initialPuzzleIndex: index,
                                      initialReviewMode:
                                          tileState !=
                                          PuzzleGridTileState.nextAvailable,
                                      cinematicThemeEnabled:
                                          cinematicThemeEnabled,
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
        title: Text('Level ${node.title}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '${node.solvedCount}/${node.masteryTarget}',
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

class _GridBackdrop extends StatelessWidget {
  const _GridBackdrop({required this.monochrome});

  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: monochrome
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
                color: monochrome
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
                color: monochrome
                    ? Colors.white12
                    : const Color(0xFFD8B640).withValues(alpha: 0.10),
              ),
            ),
          ),
        ],
      ),
    );
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
