part of '../../analysis/screens/chess_analysis_page.dart';

abstract class _QuizComponents extends _QuizScreen {
  @override
  Widget _buildQuizStatsCard({
    required QuizTrendFilter filter,
    required QuizStatsDifficultyFilter difficultyFilter,
    required int? days,
    required ValueChanged<QuizTrendFilter> onFilterChanged,
    required ValueChanged<QuizStatsDifficultyFilter> onDifficultyFilterChanged,
    required ValueChanged<int?> onDaysChanged,
    required Future<void> Function() onReset,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final palette = _academyPalette(
      scheme: scheme,
      useMonochrome: useMonochrome,
      isDark: isDark,
    );
    final accuracy = _quizAccuracy();
    final series = _buildQuizAccuracySeries(
      filter,
      days: days,
      difficultyFilter: difficultyFilter,
    );
    final amountSeries = _buildQuizAttemptSeries(
      filter,
      days: days,
      difficultyFilter: difficultyFilter,
    );
    final latest = series.isEmpty ? null : series.last.value;

    final attemptsMap = _attemptsMapForFilters(filter, difficultyFilter);
    final correctMap = _correctMapForFilters(filter, difficultyFilter);
    final dateKeys =
        attemptsMap.keys.toSet().union(correctMap.keys.toSet()).toList()
          ..sort();
    final recentKeys = (days == null || dateKeys.length <= days)
        ? dateKeys
        : dateKeys.sublist(dateKeys.length - days);

    final windowAttempts = recentKeys.fold<int>(
      0,
      (sum, key) => sum + (attemptsMap[key] ?? 0),
    );
    final windowCorrect = recentKeys.fold<int>(
      0,
      (sum, key) => sum + (correctMap[key] ?? 0),
    );
    final windowAccuracy = windowAttempts <= 0
        ? 0.0
        : (windowCorrect / windowAttempts) * 100.0;
    final attemptsPerDay = recentKeys.isEmpty
        ? 0.0
        : windowAttempts / recentKeys.length;

    String bestDayLabel = '--';
    double bestDayAccuracy = 0.0;
    for (final key in recentKeys) {
      final tries = attemptsMap[key] ?? 0;
      if (tries <= 0) continue;
      final acc = ((correctMap[key] ?? 0) / tries) * 100.0;
      if (acc >= bestDayAccuracy) {
        bestDayAccuracy = acc;
        bestDayLabel = key.length >= 10 ? key.substring(5) : key;
      }
    }

    final questionsAskedValues = _quizDailyQuestionsAsked.values.toList();
    final avgQuestionsAsked = questionsAskedValues.isEmpty
        ? 0.0
        : questionsAskedValues.reduce((a, b) => a + b) /
              questionsAskedValues.length;

    Widget buildSectionHeading(String label, Color accent) {
      return Text(
        label.toUpperCase(),
        style: _academyHudStyle(
          palette: palette,
          color: accent,
          size: 11.8,
          weight: FontWeight.w800,
          letterSpacing: 0.95,
          height: 1.0,
        ),
      );
    }

    Widget buildFilterButton({
      required String label,
      required bool selected,
      required Color accent,
      required VoidCallback onTap,
    }) {
      final effectiveAccent = selected ? accent : palette.line;
      final foreground = selected ? accent : palette.textMuted;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                effectiveAccent.withValues(alpha: selected ? 0.18 : 0.08),
                palette.panelAlt,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: effectiveAccent.withValues(alpha: selected ? 0.86 : 1),
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.shadow.withValues(alpha: 0.16),
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              label.toUpperCase(),
              style: _academyHudStyle(
                palette: palette,
                color: foreground,
                size: 11.2,
                weight: FontWeight.w800,
                letterSpacing: 0.4,
                height: 1.0,
              ),
            ),
          ),
        ),
      );
    }

    return _academyPixelPanel(
      palette: palette,
      accent: palette.amber,
      fillColor: palette.panel,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'QUIZ STATS',
                      style: _academyDisplayStyle(
                        palette: palette,
                        size: 22,
                        weight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track score, streaks, filters, and academy unlock progress from one retro dashboard.',
                      style: _academyHudStyle(
                        palette: palette,
                        size: 12.3,
                        weight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                  ],
                ),
              ),
              if (latest != null) ...[
                _academyTag(
                  palette: palette,
                  label: 'LATEST ${latest.toStringAsFixed(1)}%',
                  accent: palette.cyan,
                ),
                const SizedBox(width: 10),
              ],
              _academyHudButton(
                palette: palette,
                icon: Icons.refresh_rounded,
                label: 'RESET',
                accent: palette.signal,
                onTap: () {
                  unawaited(onReset());
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          buildSectionHeading('Session Metrics', palette.cyan),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _quizMetricChip('Score', _quizScore.toString(), palette.amber),
              _quizMetricChip(
                'Streak',
                _quizStreak.toString(),
                palette.emerald,
              ),
              _quizMetricChip(
                'Best Streak',
                _quizBestStreak.toString(),
                palette.cyan,
              ),
              _quizMetricChip(
                'Accuracy',
                '${accuracy.toStringAsFixed(1)}%',
                palette.signal,
              ),
              _quizMetricChip(
                'Avg Lines/Day',
                avgQuestionsAsked.toStringAsFixed(1),
                Color.lerp(palette.cyan, palette.amber, 0.45)!,
              ),
            ],
          ),
          const SizedBox(height: 14),
          buildSectionHeading('Academy Progress', palette.amber),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _quizMetricChip(
                'Unlocked',
                _quizAcademyBracketShortName(
                  _quizAcademyProgress.highestUnlockedDifficulty(),
                ),
                palette.cyan,
              ),
              ...QuizDifficulty.values.map(
                (difficulty) => _quizMetricChip(
                  _quizAcademyBracketShortName(difficulty),
                  '${_quizPerfectSessionsFor(difficulty)}/${_quizAcademyProgress.requiredPerfectSessions}',
                  _quizDifficultyColor(difficulty),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          buildSectionHeading('Mode Filter', palette.cyan),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: QuizTrendFilter.values
                .map(
                  (entry) => buildFilterButton(
                    label: _quizTrendFilterLabel(entry),
                    selected: entry == filter,
                    accent: palette.cyan,
                    onTap: () => onFilterChanged(entry),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          buildSectionHeading('Difficulty Filter', palette.amber),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: QuizStatsDifficultyFilter.values
                .map(
                  (entry) => buildFilterButton(
                    label: _statsDifficultyFilterLabel(entry),
                    selected: entry == difficultyFilter,
                    accent: palette.amber,
                    onTap: () => onDifficultyFilterChanged(entry),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          buildSectionHeading('Window', palette.emerald),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const <int?>[7, 30, 365, null]
                .map(
                  (entry) => buildFilterButton(
                    label: entry == null
                        ? 'Max'
                        : entry == 7
                        ? '1 Week'
                        : entry == 30
                        ? '1 Month'
                        : '1 Year',
                    selected: entry == days,
                    accent: palette.emerald,
                    onTap: () => onDaysChanged(entry),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          if (recentKeys.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _quizMetricChip(
                  'Window Accuracy',
                  '${windowAccuracy.toStringAsFixed(1)}%',
                  palette.cyan,
                ),
                _quizMetricChip(
                  'Attempts/Day',
                  attemptsPerDay.toStringAsFixed(1),
                  palette.emerald,
                ),
                _quizMetricChip(
                  'Best Day',
                  '$bestDayLabel (${bestDayAccuracy.toStringAsFixed(0)}%)',
                  palette.amber,
                ),
              ],
            ),
          if (recentKeys.isNotEmpty) const SizedBox(height: 14),
          if (series.isEmpty)
            Text(
              'Play sessions in this mode to build your accuracy trend.',
              style: _academyHudStyle(
                palette: palette,
                color: palette.textMuted,
                size: 11.6,
                weight: FontWeight.w600,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              decoration: BoxDecoration(
                color: palette.shell,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: palette.line, width: 2),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 132,
                    child: CustomPaint(
                      painter: QuizAccuracyTrendPainter(
                        accuracySeries: series,
                        amountSeries: amountSeries,
                        isDarkMode: isDark,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Blue/green line: accuracy. Gold line: attempts. Use filters and date range above to compare progress.',
                    style: _academyHudStyle(
                      palette: palette,
                      color: palette.textMuted,
                      size: 10.8,
                      weight: FontWeight.w600,
                      letterSpacing: 0.18,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _quizMetricChip(String label, String value, Color accent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final palette = _academyPalette(
      scheme: theme.colorScheme,
      useMonochrome: useMonochrome,
      isDark: isDark,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.14),
          palette.panelAlt,
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.56), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: _academyHudStyle(
              palette: palette,
              color: accent,
              size: 10.4,
              weight: FontWeight.w800,
              letterSpacing: 0.55,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: _academyHudStyle(
              palette: palette,
              color: palette.text,
              size: 12.2,
              weight: FontWeight.w700,
              letterSpacing: 0.18,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildQuizBoard({
    required Map<String, String> boardState,
    required bool whiteToMove,
  }) {
    final darkSquareColor = _darkSquareColorForTheme();
    final lightSquareColor = _lightSquareColorForTheme();
    final reverse =
        _perspective == BoardPerspective.black ||
        (_perspective == BoardPerspective.auto && !whiteToMove);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemCount: 64,
      itemBuilder: (context, i) {
        final visualFile = i % 8;
        final visualRankFromTop = i ~/ 8;
        int row, col;
        if (reverse) {
          row = i ~/ 8;
          col = 7 - i % 8;
        } else {
          row = 7 - i ~/ 8;
          col = i % 8;
        }
        final sq = '${String.fromCharCode(97 + col)}${row + 1}';
        final isDark = (row + col) % 2 == 0;
        final piece = boardState[sq];
        final showFileLabel = visualRankFromTop == 7;
        final showRankLabel = visualFile == 0;
        final labelColor = isDark ? lightSquareColor : darkSquareColor;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? darkSquareColor : lightSquareColor,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showFileLabel || showRankLabel)
                Positioned(
                  left: 3,
                  bottom: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showRankLabel)
                        Text(
                          '${row + 1}',
                          style: TextStyle(
                            fontSize: 8,
                            height: 1,
                            letterSpacing: 0.1,
                            fontWeight: FontWeight.w600,
                            color: labelColor.withValues(alpha: 0.92),
                          ),
                        ),
                      if (showFileLabel)
                        Text(
                          String.fromCharCode(97 + col),
                          style: TextStyle(
                            fontSize: 8,
                            height: 1,
                            letterSpacing: 0.1,
                            fontWeight: FontWeight.w600,
                            color: labelColor.withValues(alpha: 0.92),
                          ),
                        ),
                    ],
                  ),
                ),
              if (piece != null) Center(child: _pieceImage(piece)),
            ],
          ),
        );
      },
    );
  }
}
