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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              scheme.primary.withValues(alpha: isDark ? 0.14 : 0.05),
              scheme.surface,
            ),
            Color.alphaBlend(
              scheme.secondary.withValues(alpha: isDark ? 0.10 : 0.04),
              scheme.surface,
            ),
            scheme.surface,
          ],
          stops: const [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quiz Performance',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (latest != null) ...[
                Text(
                  'Latest ${latest.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF8FD0FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              TextButton.icon(
                onPressed: onReset,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8FD0FF),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quizMetricChip(
                'Score',
                _quizScore.toString(),
                const Color(0xFFD8B640),
              ),
              _quizMetricChip(
                'Streak',
                _quizStreak.toString(),
                const Color(0xFF7EDC8A),
              ),
              _quizMetricChip(
                'Best Streak',
                _quizBestStreak.toString(),
                const Color(0xFF5AAEE8),
              ),
              _quizMetricChip(
                'Accuracy',
                '${accuracy.toStringAsFixed(1)}%',
                const Color(0xFFFFB26A),
              ),
              _quizMetricChip(
                'Avg Lines/Day',
                avgQuestionsAsked.toStringAsFixed(1),
                const Color(0xFFB49DDB),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Academy Progress',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quizMetricChip(
                'Unlocked',
                _quizAcademyBracketShortName(
                  _quizAcademyProgress.highestUnlockedDifficulty(),
                ),
                const Color(0xFF5AAEE8),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QuizTrendFilter.values.map((entry) {
              final selected = entry == filter;
              return ChoiceChip(
                label: Text(_quizTrendFilterLabel(entry)),
                selected: selected,
                selectedColor: const Color(0xFF5AAEE8).withValues(alpha: 0.22),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF5AAEE8)
                      : scheme.outline.withValues(alpha: 0.34),
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? const Color(0xFF8FD0FF)
                      : scheme.onSurface.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
                onSelected: (_) => onFilterChanged(entry),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QuizStatsDifficultyFilter.values.map((entry) {
              final selected = entry == difficultyFilter;
              return ChoiceChip(
                label: Text(_statsDifficultyFilterLabel(entry)),
                selected: selected,
                selectedColor: const Color(0xFFD8B640).withValues(alpha: 0.20),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFFD8B640)
                      : scheme.outline.withValues(alpha: 0.34),
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? const Color(0xFFFFE29A)
                      : scheme.onSurface.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                onSelected: (_) => onDifficultyFilterChanged(entry),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <int?>[7, 30, 365, null].map((entry) {
              final selected = entry == days;
              final label = entry == null
                  ? 'Max'
                  : entry == 7
                  ? '1 Week'
                  : entry == 30
                  ? '1 Month'
                  : '1 Year';
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                selectedColor: const Color(0xFF7EDC8A).withValues(alpha: 0.20),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF7EDC8A)
                      : scheme.outline.withValues(alpha: 0.34),
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? const Color(0xFFA7F0B2)
                      : scheme.onSurface.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                onSelected: (_) => onDaysChanged(entry),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          if (recentKeys.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quizMetricChip(
                  'Window Accuracy',
                  '${windowAccuracy.toStringAsFixed(1)}%',
                  const Color(0xFF5AAEE8),
                ),
                _quizMetricChip(
                  'Attempts/Day',
                  attemptsPerDay.toStringAsFixed(1),
                  const Color(0xFF7EDC8A),
                ),
                _quizMetricChip(
                  'Best Day',
                  '$bestDayLabel (${bestDayAccuracy.toStringAsFixed(0)}%)',
                  const Color(0xFFD8B640),
                ),
              ],
            ),
          if (recentKeys.isNotEmpty) const SizedBox(height: 10),
          if (series.isEmpty)
            Text(
              'Play sessions in this mode to build your accuracy trend.',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.62),
                fontSize: 11.5,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF000000)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.30),
                ),
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
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.62),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  void _showOpeningsViewedInfoDialog() {
    final eligible = _quizEligibleCount > 0
        ? _quizEligibleCount
        : _ecoOpenings.length;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Curated Opening Library'),
          content: Text(
            'We have picked $eligible lines from the complete library of ${_ecoOpenings.length} known openings. \n\nThe counter above tracks how many of these you have already explored. Can you find them all?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Let\'s go!'),
            ),
          ],
        );
      },
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
