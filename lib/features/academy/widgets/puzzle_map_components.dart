part of 'package:chessiq/features/academy/screens/puzzle_map_screen.dart';

TextStyle _academyHeaderStyle(
  BuildContext context, {
  required Color color,
  required bool monochrome,
  double size = 14,
  FontWeight weight = FontWeight.w800,
}) {
  final palette = puzzleAcademyPalette(context, monochromeOverride: monochrome);
  return puzzleAcademyDisplayStyle(
    palette: palette,
    size: size,
    weight: weight,
    color: color,
    letterSpacing: monochrome ? 0.24 : 0.10,
    height: 1.0,
  );
}

TextStyle _academyCompactTextStyle(
  BuildContext context, {
  required Color color,
  required bool monochrome,
  double size = 12.2,
  FontWeight weight = FontWeight.w600,
  double letterSpacing = 0.24,
  double height = 1.24,
}) {
  final palette = puzzleAcademyPalette(context, monochromeOverride: monochrome);
  return puzzleAcademyCompactStyle(
    palette: palette,
    size: size,
    weight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

ButtonStyle _academyFilledButtonStyle({
  required Color backgroundColor,
  required Color foregroundColor,
  required bool monochrome,
  Color? disabledBackgroundColor,
  Color? disabledForegroundColor,
  BorderSide? side,
  EdgeInsetsGeometry? padding,
  double radius = 16,
}) {
  return puzzleAcademyFilledButtonStyle(
    palette: PuzzleAcademyPalette(
      monochrome: monochrome,
      isDark: true,
      backdrop: Colors.transparent,
      shell: Colors.transparent,
      panel: Colors.transparent,
      panelAlt: Colors.transparent,
      line: Colors.transparent,
      shadow: Colors.black,
      text: foregroundColor,
      textMuted: foregroundColor,
      cyan: backgroundColor,
      amber: backgroundColor,
      emerald: backgroundColor,
      signal: backgroundColor,
      boardDark: Colors.transparent,
      boardLight: Colors.transparent,
    ),
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    disabledBackgroundColor: disabledBackgroundColor,
    disabledForegroundColor: disabledForegroundColor,
    side: side,
    padding: padding,
    radius: radius <= 10 ? radius : 8,
  );
}

ButtonStyle _academyOutlinedButtonStyle({
  required Color accent,
  required bool monochrome,
  EdgeInsetsGeometry? padding,
  double radius = 16,
}) {
  return puzzleAcademyOutlinedButtonStyle(
    palette: PuzzleAcademyPalette(
      monochrome: monochrome,
      isDark: true,
      backdrop: Colors.transparent,
      shell: Colors.transparent,
      panel: Colors.transparent,
      panelAlt: Colors.transparent,
      line: Colors.transparent,
      shadow: Colors.black,
      text: accent,
      textMuted: accent,
      cyan: accent,
      amber: accent,
      emerald: accent,
      signal: accent,
      boardDark: Colors.transparent,
      boardLight: Colors.transparent,
    ),
    accent: accent,
    padding: padding,
    radius: radius <= 10 ? radius : 8,
  );
}

// Theme-aware accent colours for academy widgets.
Color _accentCyan(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (context.read<AppThemeProvider>().isMonochrome) {
    return isDark ? const Color(0xFF8FD8DE) : const Color(0xFF3E7B83);
  }
  return isDark ? const Color(0xFF6FE7FF) : const Color(0xFF0E7490);
}

Color _accentGold(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (context.read<AppThemeProvider>().isMonochrome) {
    return isDark ? const Color(0xFFD8C78D) : const Color(0xFF8D7442);
  }
  return isDark ? const Color(0xFFD8B640) : const Color(0xFF9A7B0A);
}

Color _accentBlue(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (context.read<AppThemeProvider>().isMonochrome) {
    return isDark ? const Color(0xFF92B7E6) : const Color(0xFF496B93);
  }
  return isDark ? const Color(0xFF5AAEE8) : const Color(0xFF1565C0);
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.accent,
    required this.child,
    this.monochrome = false,
  });

  final String title;
  final Color accent;
  final Widget child;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    return PuzzleAcademyPanel(
      padding: const EdgeInsets.all(16),
      accent: accent,
      radius: 10,
      monochromeOverride: monochrome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PuzzleAcademySectionHeader(
            title: title,
            accent: accent,
            titleSize: 14,
            monochromeOverride: monochrome,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState({required this.accent, this.monochrome = false});

  final Color accent;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PuzzleAcademySkeletonBlock(
          width: 118,
          height: 14,
          accent: accent,
          monochromeOverride: monochrome,
        ),
        const SizedBox(height: 10),
        PuzzleAcademySkeletonParagraph(
          lines: 2,
          lineHeight: 11,
          accent: accent,
          monochromeOverride: monochrome,
        ),
        const SizedBox(height: 12),
        PuzzleAcademySkeletonBlock(
          height: 8,
          accent: accent,
          monochromeOverride: monochrome,
        ),
        const SizedBox(height: 12),
        PuzzleAcademySkeletonBlock(
          width: 144,
          height: 34,
          radius: 8,
          accent: accent,
          monochromeOverride: monochrome,
        ),
      ],
    );
  }
}

class _DashboardStateNotice extends StatelessWidget {
  const _DashboardStateNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
    this.actionLabel,
    this.onAction,
    this.monochrome = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: accent.withValues(alpha: monochrome ? 0.14 : 0.10),
                border: Border.all(
                  color: accent.withValues(alpha: monochrome ? 0.42 : 0.30),
                ),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _academyHeaderStyle(
                      context,
                      color: scheme.onSurface,
                      monochrome: monochrome,
                      size: 13.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: _academyCompactTextStyle(
                      context,
                      color: palette.textMuted,
                      monochrome: monochrome,
                      size: 12.0,
                      weight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(actionLabel!),
            style: _academyFilledButtonStyle(
              backgroundColor: accent,
              foregroundColor: theme.brightness == Brightness.dark
                  ? const Color(0xFF08141A)
                  : Colors.white,
              monochrome: monochrome,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              radius: 8,
            ),
          ),
        ],
      ],
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.total,
    required this.completed,
    required this.hasTodayPuzzle,
    required this.onTap,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.monochrome = false,
  });

  final int total;
  final int completed;
  final bool hasTodayPuzzle;
  final VoidCallback onTap;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final accentGold = _accentGold(context);
    final actionTone = _accentBlue(context);
    final progress = total <= 0
        ? 0.0
        : (completed / max(1, total)).clamp(0.0, 1.0);
    final canLaunch = hasTodayPuzzle && !isLoading && errorMessage == null;

    late final Widget content;
    if (isLoading) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PuzzleAcademySectionHeader(
            title: 'Daily Challenge',
            subtitle:
                'Loading today\'s challenge set and your completion state.',
            accent: accentGold,
            titleColor: monochrome ? accentGold : scheme.onSurface,
            subtitleColor: scheme.onSurface.withValues(alpha: 0.78),
            icon: Icons.calendar_month_rounded,
            trailing: PuzzleAcademyTag(
              label: 'LOADING',
              accent: actionTone,
              compact: true,
              monochromeOverride: monochrome,
            ),
            monochromeOverride: monochrome,
            titleSize: 15.6,
            subtitleSize: 13.0,
          ),
          const SizedBox(height: 12),
          _DashboardLoadingState(accent: accentGold, monochrome: monochrome),
        ],
      );
    } else if (errorMessage != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PuzzleAcademySectionHeader(
            title: 'Daily Challenge',
            subtitle: 'Today\'s challenge feed did not refresh cleanly.',
            accent: accentGold,
            titleColor: monochrome ? accentGold : scheme.onSurface,
            subtitleColor: scheme.onSurface.withValues(alpha: 0.78),
            icon: Icons.calendar_month_rounded,
            trailing: PuzzleAcademyTag(
              label: 'RETRY',
              accent: palette.signal,
              compact: true,
              monochromeOverride: monochrome,
            ),
            monochromeOverride: monochrome,
            titleSize: 15.6,
            subtitleSize: 13.0,
          ),
          const SizedBox(height: 12),
          _DashboardStateNotice(
            icon: Icons.wifi_off_rounded,
            title: 'Daily board unavailable',
            message: errorMessage!,
            accent: palette.signal,
            actionLabel: onRetry == null ? null : 'Retry Daily Challenge',
            onAction: onRetry,
            monochrome: monochrome,
          ),
        ],
      );
    } else if (!hasTodayPuzzle || total <= 0) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PuzzleAcademySectionHeader(
            title: 'Daily Challenge',
            subtitle: 'No fresh daily set is available at the moment.',
            accent: accentGold,
            titleColor: monochrome ? accentGold : scheme.onSurface,
            subtitleColor: scheme.onSurface.withValues(alpha: 0.78),
            icon: Icons.calendar_month_rounded,
            trailing: PuzzleAcademyTag(
              label: 'WAITING',
              accent: palette.signal,
              compact: true,
              monochromeOverride: monochrome,
            ),
            monochromeOverride: monochrome,
            titleSize: 15.6,
            subtitleSize: 13.0,
          ),
          const SizedBox(height: 12),
          _DashboardStateNotice(
            icon: Icons.hourglass_bottom_rounded,
            title: 'Waiting for the next drop',
            message:
                'Check back later for the next daily challenge set, or refresh if a new board should already be live.',
            accent: actionTone,
            actionLabel: onRetry == null ? null : 'Refresh Daily Challenge',
            onAction: onRetry,
            monochrome: monochrome,
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PuzzleAcademySectionHeader(
            title: 'Daily Challenge',
            subtitle: '$completed / $total solved in today\'s challenge set',
            accent: accentGold,
            titleColor: monochrome ? accentGold : scheme.onSurface,
            subtitleColor: scheme.onSurface.withValues(alpha: 0.78),
            icon: Icons.calendar_month_rounded,
            trailing: PuzzleAcademyTag(
              label: '$completed/$total',
              accent: actionTone,
              filled: true,
              monochromeOverride: monochrome,
            ),
            monochromeOverride: monochrome,
            titleSize: 15.6,
            subtitleSize: 13.0,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: scheme.outline.withValues(alpha: 0.22),
              valueColor: AlwaysStoppedAnimation<Color>(accentGold),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(backgroundColor: actionTone).merge(
                _academyFilledButtonStyle(
                  backgroundColor: actionTone,
                  foregroundColor: theme.brightness == Brightness.dark
                      ? const Color(0xFF07131F)
                      : Colors.white,
                  disabledBackgroundColor: scheme.outline.withValues(
                    alpha: 0.20,
                  ),
                  disabledForegroundColor: scheme.onSurface.withValues(
                    alpha: 0.42,
                  ),
                  monochrome: monochrome,
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'Solve Today\'s Puzzles',
                style: _academyCompactTextStyle(
                  context,
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF07131F)
                      : Colors.white,
                  monochrome: monochrome,
                  size: 11.8,
                  weight: FontWeight.w700,
                  height: 1.14,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return PuzzleAcademyPressable(
      onTap: canLaunch ? onTap : null,
      accent: accentGold,
      monochromeOverride: monochrome,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: puzzleAcademyPanelDecoration(
          palette: palette,
          accent: accentGold,
          fillColor: palette.panelAlt,
          radius: 10,
        ),
        child: PuzzleAcademyAnimatedSwap(
          child: KeyedSubtree(
            key: ValueKey<String>(
              isLoading
                  ? 'daily-loading'
                  : errorMessage != null
                  ? 'daily-error'
                  : !hasTodayPuzzle || total <= 0
                  ? 'daily-empty'
                  : 'daily-filled',
            ),
            child: content,
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
    this.showFlags = false,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.monochrome = false,
  });

  final List<LeaderboardEntry> entries;
  final String title;
  final String emptyLabel;
  final bool showFlags;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _DashboardPanel(
      title: title,
      accent: _accentCyan(context),
      monochrome: monochrome,
      child: PuzzleAcademyAnimatedSwap(
        child: KeyedSubtree(
          key: ValueKey<String>(
            isLoading
                ? 'leaderboard-loading'
                : errorMessage != null
                ? 'leaderboard-error'
                : entries.isEmpty
                ? 'leaderboard-empty'
                : 'leaderboard-filled',
          ),
          child: isLoading
              ? _DashboardLoadingState(
                  accent: _accentCyan(context),
                  monochrome: monochrome,
                )
              : errorMessage != null
              ? _DashboardStateNotice(
                  icon: Icons.cloud_off_rounded,
                  title: 'Leaderboard sync failed',
                  message: errorMessage!,
                  accent: _accentCyan(context),
                  actionLabel: onRetry == null ? null : 'Retry Leaderboard',
                  onAction: onRetry,
                  monochrome: monochrome,
                )
              : entries.isEmpty
              ? _DashboardStateNotice(
                  icon: Icons.emoji_events_outlined,
                  title: 'Leaderboard awaiting results',
                  message: emptyLabel,
                  accent: _accentCyan(context),
                  actionLabel: onRetry == null ? null : 'Refresh Leaderboard',
                  onAction: onRetry,
                  monochrome: monochrome,
                )
              : Column(
                  children: entries.map((entry) {
                    final countryFlag = showFlags && entry.country != null
                        ? countryFlagEmoji(entry.country!)
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(
                              '${entry.rank}',
                              style: puzzleAcademyIdentityStyle(
                                palette: puzzleAcademyPalette(
                                  context,
                                  monochromeOverride: monochrome,
                                ),
                                color: _accentGold(context),
                                size: 11.2,
                                height: 1.18,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        entry.handle,
                                        overflow: TextOverflow.ellipsis,
                                        style: _academyCompactTextStyle(
                                          context,
                                          color: scheme.onSurface,
                                          monochrome: monochrome,
                                          size: 13.8,
                                          weight: FontWeight.w700,
                                          height: 1.18,
                                        ),
                                      ),
                                    ),
                                    if (countryFlag != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Tooltip(
                                          message: entry.country!,
                                          child: Text(
                                            countryFlag,
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              height: 1.0,
                                              fontFamilyFallback: <String>[
                                                'Segoe UI Emoji',
                                                'Apple Color Emoji',
                                                'Noto Color Emoji',
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (entry.title.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      entry.title,
                                      style: _academyCompactTextStyle(
                                        context,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.68,
                                        ),
                                        monochrome: monochrome,
                                        size: 12.2,
                                        height: 1.16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                entry.score.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                textAlign: TextAlign.right,
                                style: _academyCompactTextStyle(
                                  context,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.78,
                                  ),
                                  monochrome: monochrome,
                                  size: 13.2,
                                  weight: FontWeight.w700,
                                  height: 1.12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
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
    this.monochrome = false,
  });

  final SemesterRange semester;
  final double progress;
  final bool expanded;
  final int nodeCount;
  final VoidCallback? onTap;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final accentCyan = _accentCyan(context);

    return PuzzleAcademyPressable(
      onTap: onTap,
      accent: accentCyan,
      monochromeOverride: monochrome,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: puzzleAcademyPanelDecoration(
          palette: palette,
          accent: accentCyan,
          radius: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${semester.title} • ${semester.minElo}-${semester.maxElo}',
                    style: _academyHeaderStyle(
                      context,
                      color: scheme.onSurface,
                      monochrome: monochrome,
                      size: 15.0,
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PuzzleAcademyTag(
                  label: '$nodeCount Levels',
                  accent: accentCyan,
                  compact: true,
                  monochromeOverride: monochrome,
                ),
                PuzzleAcademyTag(
                  label: '${(progress * 100).round()}% clear',
                  accent: palette.amber,
                  compact: true,
                  filled: progress >= 1.0,
                  monochromeOverride: monochrome,
                ),
                PuzzleAcademyTag(
                  label: expanded ? 'COLLAPSE' : 'EXPAND',
                  accent: scheme.outline,
                  foregroundColor: scheme.onSurface.withValues(alpha: 0.74),
                  compact: true,
                  monochromeOverride: monochrome,
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
                valueColor: AlwaysStoppedAnimation<Color>(accentCyan),
              ),
            ),
          ],
        ),
      ),
    );
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
    this.monochrome = false,
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
  final bool monochrome;
  final int? bestExamScore;
  final String? bestExamGrade;
  final VoidCallback? onExamTap;

  @override
  Widget build(BuildContext context) {
    final locked = !node.unlocked;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final cardBase = Color.alphaBlend(
      scheme.primary.withValues(
        alpha: locked
            ? (theme.brightness == Brightness.dark ? 0.05 : 0.02)
            : (theme.brightness == Brightness.dark ? 0.11 : 0.05),
      ),
      scheme.surface,
    );

    return PuzzleAcademyPressable(
      onTap: onTap,
      accent: locked ? scheme.outline : _accentBlue(context),
      monochromeOverride: monochrome,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: puzzleAcademyPanelDecoration(
          palette: palette,
          accent: locked ? scheme.outline : _accentBlue(context),
          fillColor: cardBase.withValues(alpha: locked ? 0.84 : 0.94),
          borderColor: locked
              ? scheme.outline.withValues(alpha: 0.34)
              : _accentBlue(context).withValues(alpha: 0.42),
          radius: 10,
          borderWidth: 2.5,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: compact
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final content = _buildCompactContent(context, locked);
                    if (constraints.maxHeight < 220) {
                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: content,
                      );
                    }
                    return content;
                  },
                )
              : _buildPortraitContent(context, locked),
        ),
      ),
    );
  }

  Widget _buildCompactContent(BuildContext context, bool locked) {
    final scheme = Theme.of(context).colorScheme;
    final hasStatusBadges = node.goldCrown || showGhost;

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
              monochrome: monochrome,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${node.title}',
                    style: _academyHeaderStyle(
                      context,
                      color: scheme.onSurface,
                      monochrome: monochrome,
                      size: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _InfoTag(
                        label: '${node.solvedCount}/${node.masteryTarget}',
                        accent: _accentBlue(context),
                      ),
                      if (bestExamScore != null)
                        _InfoTag(
                          label: bestExamGrade != null
                              ? '$bestExamGrade $bestExamScore'
                              : '$bestExamScore pts',
                          accent: _accentGold(context),
                          filled: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasStatusBadges) ...[
          const SizedBox(height: 6),
          _statusCluster(context),
        ],
        const SizedBox(height: 8),
        if (locked || showExamButton)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (requiresPreviousSolveTarget)
                  _InfoTag(
                    label: '100 solves prev',
                    accent: _accentBlue(context),
                  ),
                if (requiresPreviousSemesterExamGate)
                  _InfoTag(
                    label: 'Prev sem exam',
                    accent: _accentGold(context),
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
                  style:
                      OutlinedButton.styleFrom(
                        foregroundColor: _accentGold(context),
                      ).merge(
                        _academyOutlinedButtonStyle(
                          accent: _accentGold(context),
                          monochrome: monochrome,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                  child: const Text('Exam'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton(
                onPressed: onTap,
                style: _academyFilledButtonStyle(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: locked
                      ? Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.28)
                      : _accentBlue(context),
                  foregroundColor: locked
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.70)
                      : Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF07131F)
                      : Colors.white,
                  monochrome: monochrome,
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
        Align(
          alignment: Alignment.centerLeft,
          child: _InfoTag(
            label: locked ? 'Locked' : 'Training',
            accent: locked ? scheme.outline : _accentBlue(context),
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: node.masteryProgress,
            backgroundColor: scheme.outline.withValues(alpha: 0.22),
            valueColor: AlwaysStoppedAnimation<Color>(
              node.goldCrown ? _accentGold(context) : _accentCyan(context),
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
          monochrome: monochrome,
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
                      style: _academyHeaderStyle(
                        context,
                        color: locked
                            ? scheme.onSurface.withValues(alpha: 0.72)
                            : scheme.onSurface,
                        monochrome: monochrome,
                        size: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusCluster(context),
                ],
              ),
              const SizedBox(height: 6),
              if (requiresPreviousSolveTarget ||
                  requiresPreviousSemesterExamGate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      if (requiresPreviousSolveTarget)
                        _InfoTag(
                          label: '100 solves prev',
                          accent: _accentBlue(context),
                        ),
                      if (requiresPreviousSolveTarget) const SizedBox(width: 6),
                      if (requiresPreviousSemesterExamGate)
                        _InfoTag(
                          label: 'Prev sem exam',
                          accent: _accentGold(context),
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
                      style: _academyFilledButtonStyle(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: locked
                            ? Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.28)
                            : _accentBlue(context),
                        foregroundColor: locked
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.70)
                            : Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF07131F)
                            : Colors.white,
                        monochrome: monochrome,
                      ),
                      child: Text(locked ? 'Locked' : 'Train'),
                    ),
                  ),
                  if (showExamButton) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onExamTap,
                        style: _academyOutlinedButtonStyle(
                          accent: _accentGold(context),
                          monochrome: monochrome,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                        ? _accentGold(context)
                        : _accentCyan(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusCluster(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (node.goldCrown)
          _Tag(
            text: 'Gold Crown',
            color: _accentGold(context),
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
    required this.monochrome,
  });

  final String heroTag;
  final EloNodeProgress node;
  final bool locked;
  final String? gradeBadge;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );

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
                  ? _accentGold(context)
                  : scheme.primary.withValues(alpha: 0.50),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  '${node.startElo}',
                  style: puzzleAcademyCompactStyle(
                    palette: palette,
                    size: 12.0,
                    weight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.0,
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
  const _InfoTag({
    required this.label,
    required this.accent,
    this.filled = false,
  });

  final String label;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return PuzzleAcademyTag(
      label: label,
      accent: accent,
      compact: true,
      filled: filled,
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
    return PuzzleAcademyTag(
      label: text,
      accent: color,
      icon: icon,
      compact: true,
      filled: true,
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
    return PuzzleAcademyTag(
      label: '$label ${value.toUpperCase()}',
      accent: color,
      filled: true,
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
    this.actionLabel = 'Buy',
    this.enabled = true,
    this.monochrome = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onBuy;
  final String actionLabel;
  final bool enabled;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: puzzleAcademyPanelDecoration(
        palette: palette,
        accent: _accentGold(context),
        radius: 10,
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: PuzzleAcademySectionHeader(
              title: title,
              subtitle: subtitle,
              accent: _accentGold(context),
              titleColor: scheme.onSurface,
              subtitleColor: palette.textMuted,
              titleSize: 14,
              subtitleSize: 11.5,
              monochromeOverride: monochrome,
            ),
          ),
          Text(
            price,
            style: puzzleAcademyHudStyle(
              palette: palette,
              size: 11.5,
              weight: FontWeight.w800,
              color: _accentGold(context),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: enabled ? onBuy : null,
            style: _academyFilledButtonStyle(
              backgroundColor: enabled
                  ? _accentBlue(context)
                  : scheme.outline.withValues(alpha: 0.22),
              foregroundColor: enabled
                  ? theme.brightness == Brightness.dark
                        ? const Color(0xFF07131F)
                        : Colors.white
                  : scheme.onSurface.withValues(alpha: 0.62),
              monochrome: monochrome,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              radius: 8,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
