part of 'package:chessiq/features/academy/screens/puzzle_map_screen.dart';

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.10 : 0.04,
              ),
              scheme.surface,
            ).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.26),
                scheme.outline,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.total,
    required this.completed,
    required this.hasTodayPuzzle,
    required this.onTap,
  });

  final int total;
  final int completed;
  final bool hasTodayPuzzle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = total <= 0
        ? 0.0
        : (completed / max(1, total)).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.16 : 0.06,
                  ),
                  scheme.surface,
                ).withValues(alpha: 0.96),
                Color.alphaBlend(
                  scheme.secondary.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.10 : 0.04,
                  ),
                  scheme.surface,
                ).withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.30)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Challenge',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  !hasTodayPuzzle
                      ? 'No daily set available for today yet.'
                      : '$completed / $total solved in today\'s challenge set',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress,
                    backgroundColor: scheme.outline.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFD8B640),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: hasTodayPuzzle ? onTap : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5AAEE8),
                      foregroundColor: const Color(0xFF07131F),
                      disabledBackgroundColor: scheme.outline.withValues(
                        alpha: 0.20,
                      ),
                      disabledForegroundColor: scheme.onSurface.withValues(
                        alpha: 0.42,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      hasTodayPuzzle
                          ? "Solve Today's Puzzle"
                          : 'Check Back Later!',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.entries,
    this.title = 'Top 10 Global',
    this.emptyLabel = 'No scores yet.',
  });

  final List<LeaderboardEntry> entries;
  final String title;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _DashboardPanel(
      title: title,
      accent: const Color(0xFF6FE7FF),
      child: entries.isEmpty
          ? Text(
              emptyLabel,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
            )
          : Column(
              children: entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${entry.rank}',
                              style: const TextStyle(
                                color: Color(0xFFD8B640),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.handle,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (entry.title.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      entry.title,
                                      style: TextStyle(
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.66,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.score.toString(),
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SemesterHeader extends StatelessWidget {
  const _SemesterHeader({
    required this.semester,
    required this.progress,
    this.expanded = true,
    required this.nodeCount,
    this.onTap,
  });

  final SemesterRange semester;
  final double progress;
  final bool expanded;
  final int nodeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.10 : 0.04,
              ),
              scheme.surface,
            ).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${semester.title} • ${semester.minElo}-${semester.maxElo}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '$nodeCount Levels',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    expanded ? 'Hide' : 'Show',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: progress,
                  backgroundColor: scheme.outline.withValues(alpha: 0.22),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6FE7FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      )  );
  }
}

class _PuzzleNodeCard extends StatelessWidget {
  const _PuzzleNodeCard({
    required this.node,
    required this.compact,
    required this.heroTag,
    required this.showGhost,
    required this.onTap,
    required this.showExamButton,
    required this.completedCount,
    required this.masteryProgress,
    this.lockedRequirementText,
    this.previousSolveRequirementText,
    this.requiresPreviousSolveTarget = false,
    this.requiresPreviousSemesterExamGate = false,
    this.bestExamScore,
    this.bestExamGrade,
    this.onExamTap,
  });

  final EloNodeProgress node;
  final bool compact;
  final String heroTag;
  final bool showGhost;
  final VoidCallback? onTap;
  final bool showExamButton;
  final int completedCount;
  final double masteryProgress;
  final String? lockedRequirementText;
  final String? previousSolveRequirementText;
  final bool requiresPreviousSolveTarget;
  final bool requiresPreviousSemesterExamGate;
  final int? bestExamScore;
  final String? bestExamGrade;
  final VoidCallback? onExamTap;

  @override
  Widget build(BuildContext context) {
    final locked = !node.unlocked;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cardBase = Color.alphaBlend(
      scheme.primary.withValues(
        alpha: locked
            ? (theme.brightness == Brightness.dark ? 0.05 : 0.02)
            : (theme.brightness == Brightness.dark ? 0.11 : 0.05),
      ),
      scheme.surface,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: locked
                  ? [
                      cardBase.withValues(alpha: 0.90),
                      Color.alphaBlend(
                        scheme.primary.withValues(alpha: 0.02),
                        scheme.surface,
                      ).withValues(alpha: 0.90),
                    ]
                  : [
                      cardBase.withValues(alpha: 0.90),
                      Color.alphaBlend(
                        scheme.secondary.withValues(alpha: 0.05),
                        scheme.surface,
                      ).withValues(alpha: 0.90),
                    ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: locked
                  ? scheme.outline.withValues(alpha: 0.25)
                  : scheme.outline.withValues(alpha: 0.34),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: compact
                  ? _buildCompactContent(context, locked)
                  : _buildPortraitContent(context, locked),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContent(BuildContext context, bool locked) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _HeroBadge(
              heroTag: heroTag,
              node: node,
              locked: locked,
              gradeBadge: bestExamGrade,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${node.title}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoTag(
                        label: '${node.solvedCount}/${node.masteryTarget}',
                        accent: const Color(0xFF5AAEE8),
                      ),
                      const SizedBox(width: 6),
                      if (bestExamScore != null)
                        _InfoTag(
                          label: bestExamGrade != null
                              ? '$bestExamGrade $bestExamScore'
                              : '$bestExamScore pts',
                          accent: const Color(0xFFD8B640),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _statusCluster(),
          ],
        ),
        const SizedBox(height: 10),
        if (locked || showExamButton)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                if (requiresPreviousSolveTarget)
                  _InfoTag(
                    label: '100 solves prev',
                    accent: const Color(0xFF71B7FF),
                  ),
                if (requiresPreviousSolveTarget) const SizedBox(width: 6),
                if (requiresPreviousSemesterExamGate)
                  _InfoTag(
                    label: 'Prev sem exam',
                    accent: const Color(0xFFD8B640),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            if (showExamButton) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onExamTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD8B640),
                    side: const BorderSide(color: Color(0xFFD8B640)),
                    backgroundColor:
                        const Color(0xFFD8B640).withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Exam'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: locked
                      ? Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.28)
                      : const Color(0xFF5AAEE8),
                  foregroundColor: locked
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.70)
                      : const Color(0xFF07131F),
                ),
                child: Text(
                  locked
                      ? (previousSolveRequirementText ??
                          lockedRequirementText ??
                          'Locked')
                      : 'Train',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (locked && previousSolveRequirementText != null)
              _InfoTag(
                label: previousSolveRequirementText!,
                accent: const Color(0xFF71B7FF),
              ),
            if (locked && previousSolveRequirementText != null)
              const SizedBox(width: 6),
            if (locked && lockedRequirementText != null)
              _InfoTag(
                label: lockedRequirementText!,
                accent: const Color(0xFFD8B640),
              ),
            if (locked && lockedRequirementText != null)
              const SizedBox(width: 6),
            _InfoTag(
              label: locked ? 'Locked' : 'Training',
              accent: locked ? scheme.outline : const Color(0xFF5AAEE8),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: node.masteryProgress,
            backgroundColor: scheme.outline.withValues(alpha: 0.22),
            valueColor: AlwaysStoppedAnimation<Color>(
              node.goldCrown
                  ? const Color(0xFFD8B640)
                  : const Color(0xFF6FE7FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitContent(BuildContext context, bool locked) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _HeroBadge(
          heroTag: heroTag,
          node: node,
          locked: locked,
          gradeBadge: bestExamGrade,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Level ${node.title}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: locked
                            ? scheme.onSurface.withValues(alpha: 0.72)
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusCluster(),
                ],
              ),
              const SizedBox(height: 6),
              if (requiresPreviousSolveTarget || requiresPreviousSemesterExamGate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      if (requiresPreviousSolveTarget)
                        _InfoTag(
                          label: '100 solves prev',
                          accent: const Color(0xFF71B7FF),
                        ),
                      if (requiresPreviousSolveTarget)
                        const SizedBox(width: 6),
                      if (requiresPreviousSemesterExamGate)
                        _InfoTag(
                          label: 'Prev sem exam',
                          accent: const Color(0xFFD8B640),
                        ),
                    ],
                  ),
                ),
              if (!locked)
                Text(
                  (node.unlocked && node.startElo < 800)
                      ? '$completedCount/${node.masteryTarget} for crown'
                      : '${node.solvedCount}/${node.unlockTarget} to unlock next Level • $completedCount/${node.masteryTarget} for crown',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.66),
                    fontSize: 12,
                  ),
                ),
              if (bestExamScore != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    bestExamGrade != null
                        ? 'Best exam: $bestExamGrade ($bestExamScore)'
                        : 'Best exam score: $bestExamScore',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.68),
                      fontSize: 11.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: locked
                            ? Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.28)
                            : const Color(0xFF5AAEE8),
                        foregroundColor: locked
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.70)
                            : const Color(0xFF07131F),
                      ),
                      child: Text(locked ? 'Locked' : 'Train'),
                    ),
                  ),
                  if (showExamButton) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onExamTap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: const Color(0xFFD8B640),
                          side: const BorderSide(color: Color(0xFFD8B640)),
                          backgroundColor:
                              const Color(0xFFD8B640).withValues(alpha: 0.08),
                        ),
                        child: const Text('Exam'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: node.masteryProgress,
                  backgroundColor: scheme.outline.withValues(alpha: 0.22),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    node.goldCrown
                        ? const Color(0xFFD8B640)
                        : const Color(0xFF6FE7FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusCluster() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (node.goldCrown)
          const _Tag(
            text: 'Gold Crown',
            color: Color(0xFFD8B640),
            icon: Icons.workspace_premium,
          ),
        if (showGhost)
          const _Tag(
            text: 'Ghost',
            color: Color(0xFFB8D6F3),
            icon: Icons.history_toggle_off_rounded,
          ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.heroTag,
    required this.node,
    required this.locked,
    this.gradeBadge,
  });

  final String heroTag;
  final EloNodeProgress node;
  final bool locked;
  final String? gradeBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: locked
                  ? [
                      Color.alphaBlend(
                        scheme.primary.withValues(alpha: 0.06),
                        scheme.surface,
                      ),
                      scheme.surface,
                    ]
                  : [
                      Color.alphaBlend(
                        scheme.primary.withValues(alpha: 0.20),
                        scheme.surface,
                      ),
                      Color.alphaBlend(
                        scheme.secondary.withValues(alpha: 0.08),
                        scheme.surface,
                      ),
                    ],
            ),
            border: Border.all(
              color: node.goldCrown
                  ? const Color(0xFFD8B640)
                  : scheme.primary.withValues(alpha: 0.50),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  '${node.startElo}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (gradeBadge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDA3B3B),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                    child: Text(
                      gradeBadge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color, required this.icon});

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onBuy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.10 : 0.04,
          ),
          scheme.surface,
        ).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.66),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFFD8B640),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onBuy, child: const Text('Buy')),
        ],
      ),
    );
  }
}
