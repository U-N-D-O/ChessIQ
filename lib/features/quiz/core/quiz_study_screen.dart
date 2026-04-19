part of '../../analysis/screens/chess_analysis_page.dart';

Widget _buildQuizStudyScreen(_QuizScreen state) {
  final media = MediaQuery.of(state.context);
  final theme = Theme.of(state.context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final useMonochrome =
      state.context.watch<AppThemeProvider>().isMonochrome ||
      state._isCinematicThemeEnabled;
  final isLandscape = media.orientation == Orientation.landscape;
  final quizPadding = isLandscape
      ? EdgeInsets.fromLTRB(
          16 + media.padding.left,
          12 + media.padding.top,
          16 + media.padding.right,
          16 + media.padding.bottom,
        )
      : const EdgeInsets.fromLTRB(16, 12, 16, 16);
  final lightHeaderColor = isDark ? scheme.onSurface : Colors.black;
  final highestUnlocked = state._quizAcademyProgress
      .highestUnlockedDifficulty();
  final selectedLine = state._quizStudyDetailOpen
      ? state._selectedQuizStudyLine()
      : null;
  final showingDetail = selectedLine != null;

  return Stack(
    children: [
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                const Color(0xFF6FE7FF).withValues(
                  alpha: useMonochrome
                      ? (isDark ? 0.06 : 0.08)
                      : (isDark ? 0.18 : 0.14),
                ),
                scheme.surface,
              ),
              scheme.surface,
              Color.alphaBlend(
                const Color(0xFFD8B640).withValues(
                  alpha: useMonochrome
                      ? (isDark ? 0.06 : 0.08)
                      : (isDark ? 0.14 : 0.10),
                ),
                scheme.surface,
              ),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
      Positioned.fill(child: state._buildQuizAcademyAtmosphere(useMonochrome)),
      IgnorePointer(
        child: AnimatedBuilder(
          animation: state._pulseController,
          builder: (context, child) {
            final pulse = state._menuDotTime;
            final alignment = state._botSelectorBlueDotAlignment(
              state._blueDotPhase,
              0.55,
              state._blueDotRadius,
              pulse,
              state._blueDotTrajectoryNoise,
              state._blueDotShapeSeed,
              0.0,
            );
            return Align(alignment: alignment, child: child);
          },
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD8B640).withValues(alpha: 0.92),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9E761D).withValues(alpha: 0.45),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      ListView(
        padding: quizPadding,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: showingDetail
                    ? state._closeQuizStudyDetail
                    : state._exitQuizStudyScreen,
                color: lightHeaderColor,
                icon: const Icon(Icons.arrow_back),
                tooltip: showingDetail
                    ? 'Back to study library'
                    : 'Back to opening quiz',
              ),
              const SizedBox(width: 6),
              Text(
                showingDetail ? 'Variation Study' : 'Opening Study',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: lightHeaderColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: state._openAppearanceSettings,
                color: lightHeaderColor,
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Board & Pieces',
              ),
              IconButton(
                onPressed: state._openQuizStatsSheet,
                color: lightHeaderColor,
                icon: const Icon(Icons.insights_outlined),
                tooltip: 'Performance Stats',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuizStudyMissionPanel(state, highestUnlocked: highestUnlocked),
          const SizedBox(height: 14),
          if (showingDetail)
            _buildQuizStudyDetailScreen(state, selectedLine: selectedLine)
          else
            _buildQuizStudyLibraryPanel(state),
        ],
      ),
    ],
  );
}

Widget _buildQuizStudyMissionPanel(
  _QuizScreen state, {
  required QuizDifficulty highestUnlocked,
}) {
  final theme = Theme.of(state.context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final selectedColor = state._quizStudyCategoryColor(state._quizStudyCategory);
  final selectedStudied = state._quizStudyCategoryStudiedCount(
    state._quizStudyCategory,
  );
  final selectedTotal = state._quizStudyCategoryTotalCount(
    state._quizStudyCategory,
  );
  final selectedCompletion = state._quizStudyCategoryCompletion(
    state._quizStudyCategory,
  );
  final selectedReps = state._quizStudyCategoryTotalReps(
    state._quizStudyCategory,
  );

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            const Color(0xFFD8B640).withValues(alpha: isDark ? 0.14 : 0.06),
            scheme.surface,
          ),
          Color.alphaBlend(
            const Color(0xFF5AAEE8).withValues(alpha: isDark ? 0.08 : 0.04),
            scheme.surface,
          ),
          scheme.surface,
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Opening Study Library',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  state._buildQuizInfoButton(
                    title: 'Opening Study Library',
                    message:
                        'Basic mirrors the easy quiz shelf, Advanced mirrors medium, Master mirrors hard, Grandmaster mirrors very hard, and Library stays open for the full replayable opening catalog.',
                  ),
                ],
              ),
            ),
            state._buildQuizTierToggleButton(
              expanded: state._quizStudyShelfExpanded,
              onPressed: state._toggleQuizStudyShelfExpanded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (!state._quizStudyShelfExpanded)
          _buildQuizStudyCategoryCard(state, state._quizStudyCategory)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 560
                  ? constraints.maxWidth
                  : constraints.maxWidth >= 1120
                  ? (constraints.maxWidth - 40) / 5
                  : (constraints.maxWidth - 10) / 2;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: QuizStudyCategory.values
                    .map(
                      (category) => SizedBox(
                        width: cardWidth,
                        child: _buildQuizStudyCategoryCard(state, category),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            state._buildQuizAcademyMetricChip(
              label: 'Selected Shelf',
              value: state._quizStudyCategoryLabel(state._quizStudyCategory),
              accent: selectedColor,
            ),
            state._buildQuizAcademyMetricChip(
              label: 'Study Reps',
              value: state._quizStudyTotalReps().toString(),
              accent: const Color(0xFFD8B640),
            ),
            state._buildQuizAcademyMetricChip(
              label: 'Quiz Ladder',
              value: state._quizAcademyBracketShortName(highestUnlocked),
              accent: const Color(0xFF5AAEE8),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'Selected shelf completion',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '${(selectedCompletion * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: selectedColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: selectedCompletion,
            backgroundColor: scheme.outline.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation<Color>(selectedColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedTotal <= 0
              ? 'This shelf is still waiting for replayable openings to finish loading.'
              : '$selectedStudied of $selectedTotal openings have been studied at least once in ${state._quizStudyCategoryLabel(state._quizStudyCategory).toLowerCase()}. You have logged $selectedReps study rep${selectedReps == 1 ? '' : 's'} in this shelf.',
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.72),
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

Widget _buildQuizStudyCategoryCard(
  _QuizScreen state,
  QuizStudyCategory category,
) {
  final scheme = Theme.of(state.context).colorScheme;
  final selected = state._quizStudyCategory == category;
  final accent = state._quizStudyCategoryColor(category);
  final total = state._quizStudyCategoryTotalCount(category);
  final studied = state._quizStudyCategoryStudiedCount(category);
  final completion = state._quizStudyCategoryCompletion(category);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => state._setQuizStudyCategory(category),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : scheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.72)
                : scheme.outline.withValues(alpha: 0.24),
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    state._quizStudyCategoryIcon(category),
                    color: accent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    '${(completion * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              state._quizStudyCategoryLabel(category),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state._quizStudyCategorySubtitle(category),
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.70),
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: completion,
                backgroundColor: scheme.outline.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$studied/$total openings studied',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildQuizStudyLibraryPanel(_QuizScreen state) {
  final theme = Theme.of(state.context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final isLoading = !state._quizStudyDataReady() && state._ecoOpeningsLoading;
  final groups = isLoading
      ? const <_QuizStudyFamilyGroup>[]
      : state._quizStudyFamilyGroups(state._quizStudyCategory);
  final searchActive = state._quizStudySearchQuery.trim().isNotEmpty;
  final matchingLines = groups.fold<int>(
    0,
    (sum, group) => sum + group.lines.length,
  );
  final browserHeight = min(
    820.0,
    max(520.0, MediaQuery.sizeOf(state.context).height * 0.72),
  );

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            scheme.secondary.withValues(alpha: isDark ? 0.12 : 0.04),
            scheme.surface,
          ),
          scheme.surface,
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Study Library',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            state._buildQuizInfoButton(
              title: 'Study Library',
              message:
                  'Choose a family, then open a variation on its own study screen. Search stays here so the detail view can stay focused and easy to navigate.',
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: ValueKey('quiz-study-search-${state._quizStudyCategory.name}'),
          initialValue: state._quizStudySearchQuery,
          enabled: !isLoading,
          onChanged: state._setQuizStudySearchQuery,
          decoration: InputDecoration(
            hintText: 'Search openings, variations, or moves',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  )
                : null,
            filled: true,
            fillColor: scheme.surface.withValues(alpha: 0.82),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: scheme.outline.withValues(alpha: 0.26),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: scheme.outline.withValues(alpha: 0.26),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: state
                    ._quizStudyCategoryColor(state._quizStudyCategory)
                    .withValues(alpha: 0.60),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            state._buildQuizAcademyMetricChip(
              label: 'Shelf',
              value: state._quizStudyCategoryLabel(state._quizStudyCategory),
              accent: state._quizStudyCategoryColor(state._quizStudyCategory),
            ),
            state._buildQuizAcademyMetricChip(
              label: 'Families',
              value: groups.length.toString(),
              accent: const Color(0xFF5AAEE8),
            ),
            state._buildQuizAcademyMetricChip(
              label: searchActive ? 'Matches' : 'Openings',
              value: matchingLines.toString(),
              accent: const Color(0xFFD8B640),
            ),
            state._buildQuizAcademyMetricChip(
              label: 'Studied',
              value:
                  '${state._quizStudyCategoryStudiedCount(state._quizStudyCategory)}/${state._quizStudyCategoryTotalCount(state._quizStudyCategory)}',
              accent: const Color(0xFF7EDC8A),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: browserHeight,
          child: _buildQuizStudyFamilyListPane(
            state,
            groups: groups,
            isLoading: isLoading,
            searchActive: searchActive,
          ),
        ),
      ],
    ),
  );
}

Widget _buildQuizStudyFamilyListPane(
  _QuizScreen state, {
  required List<_QuizStudyFamilyGroup> groups,
  required bool isLoading,
  required bool searchActive,
}) {
  final scheme = Theme.of(state.context).colorScheme;

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: scheme.surface.withValues(alpha: 0.66),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: scheme.outline.withValues(alpha: 0.24)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Opening Families',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            state._buildQuizInfoButton(
              title: 'Opening Families',
              message: searchActive
                  ? 'Search keeps matching families open so you can jump straight into a variation detail page.'
                  : 'Tap a family name to reveal the included lines and open any variation on its own study page.',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading bundled study library...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.68),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : groups.isEmpty
              ? Center(
                  child: Text(
                    searchActive
                        ? 'No openings matched that search.'
                        : 'No openings are available in this shelf.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.62),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                )
              : Scrollbar(
                  controller: state._quizStudyLibraryScrollController,
                  child: ListView.builder(
                    controller: state._quizStudyLibraryScrollController,
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final expanded =
                          searchActive ||
                          state._quizStudyExpandedFamily == group.familyName;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildQuizStudyFamilyCard(
                          state,
                          group: group,
                          expanded: expanded,
                          searchActive: searchActive,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );
}

Widget _buildQuizStudyFamilyCard(
  _QuizScreen state, {
  required _QuizStudyFamilyGroup group,
  required bool expanded,
  required bool searchActive,
}) {
  final scheme = Theme.of(state.context).colorScheme;
  final accent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final studiedCount = state._quizStudyFamilyStudiedCount(group);
  final familyHasSelection = group.lines.any(
    (line) => line.name == state._quizStudySelectedOpeningName,
  );

  return Container(
    decoration: BoxDecoration(
      color: familyHasSelection
          ? accent.withValues(alpha: 0.08)
          : scheme.surface.withValues(alpha: 0.54),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: familyHasSelection
            ? accent.withValues(alpha: 0.36)
            : scheme.outline.withValues(alpha: 0.20),
      ),
    ),
    child: Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: searchActive
                ? null
                : () => state._toggleQuizStudyFamily(group.familyName),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.familyName,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${group.lines.length} variation${group.lines.length == 1 ? '' : 's'} • $studiedCount studied',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.66),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (familyHasSelection)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: accent,
                      ),
                    ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.16)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                for (var index = 0; index < group.lines.length; index++) ...[
                  _buildQuizStudyVariationTile(
                    state,
                    line: group.lines[index],
                    familyName: group.familyName,
                  ),
                  if (index < group.lines.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildQuizStudyVariationTile(
  _QuizScreen state, {
  required EcoLine line,
  required String familyName,
}) {
  final scheme = Theme.of(state.context).colorScheme;
  final accent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final selected = state._quizStudySelectedOpeningName == line.name;
  final studyCount = state._quizStudyCountFor(line.name);
  final variationLabel = state._quizStudyVariationLabel(line, familyName);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => state._selectQuizStudyOpening(line),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : scheme.surface.withValues(alpha: 0.54),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.56)
                : scheme.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected
                    ? Icons.open_in_full_rounded
                    : Icons.open_in_new_rounded,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variationLabel,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (variationLabel != line.name) ...[
                    const SizedBox(height: 2),
                    Text(
                      line.name,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.66),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${line.moveTokens.length} ply • opens study page',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.56),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.24)),
              ),
              child: Text(
                'Studied ${studyCount}x',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurface.withValues(alpha: 0.42),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildQuizStudyDetailScreen(
  _QuizScreen state, {
  required EcoLine selectedLine,
}) {
  final theme = Theme.of(state.context);
  final scheme = theme.colorScheme;
  final accent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final preview = state._buildQuizStudyPreview(selectedLine);
  final familyName = state._quizStudyFamilyName(selectedLine.name);
  final familyLines = state._quizStudyFamilyLines(familyName);
  final studyCount = state._quizStudyCountFor(selectedLine.name);
  final boardMaxWidth = MediaQuery.sizeOf(state.context).width >= 1000
      ? 420.0
      : 320.0;
  final variationLabel = state._quizStudyVariationLabel(
    selectedLine,
    familyName,
  );
  final currentPly = preview?.shownPly ?? 0;
  final totalPly = preview?.totalPly ?? selectedLine.moveTokens.length;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(accent.withValues(alpha: 0.10), scheme.surface),
          scheme.surface,
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedLine.name,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dedicated study screen for this variation. Use the family navigator below to move through related lines without going back to search.',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.70),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: state._closeQuizStudyDetail,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Library'),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.42)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            state._buildQuizAcademyMetricChip(
              label: 'Family',
              value: familyName,
              accent: const Color(0xFF5AAEE8),
            ),
            state._buildQuizAcademyMetricChip(
              label: 'Variation',
              value: variationLabel,
              accent: accent,
            ),
            state._buildQuizAcademyMetricChip(
              label: 'Shelf',
              value: state._quizStudyCategoryLabel(state._quizStudyCategory),
              accent: accent,
            ),
            state._buildQuizAcademyMetricChip(
              label: 'Studied',
              value: '${studyCount}x',
              accent: const Color(0xFFD8B640),
            ),
            state._buildQuizAcademyMetricChip(
              label: 'Position',
              value: '$currentPly/$totalPly ply',
              accent: const Color(0xFF7EDC8A),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Family Navigator',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                familyLines.length > 1
                    ? 'Switch to another $familyName variation without leaving this screen.'
                    : 'This shelf currently has a single stored variation for $familyName.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.68),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (familyLines.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (
                        var index = 0;
                        index < familyLines.length;
                        index++
                      ) ...[
                        ChoiceChip(
                          label: Text(
                            state._quizStudyVariationLabel(
                              familyLines[index],
                              familyName,
                            ),
                          ),
                          selected:
                              familyLines[index].name == selectedLine.name,
                          selectedColor: accent.withValues(alpha: 0.18),
                          side: BorderSide(
                            color: familyLines[index].name == selectedLine.name
                                ? accent.withValues(alpha: 0.72)
                                : scheme.outline.withValues(alpha: 0.28),
                          ),
                          labelStyle: TextStyle(
                            color: familyLines[index].name == selectedLine.name
                                ? accent
                                : scheme.onSurface.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) =>
                              state._selectQuizStudyOpening(familyLines[index]),
                        ),
                        if (index < familyLines.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    'No sibling variations are currently grouped with this line in ${state._quizStudyCategoryLabel(state._quizStudyCategory).toLowerCase()}.',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.76),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (preview != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Board Walkthrough',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      'Ply $currentPly/$totalPly',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  currentPly == 0
                      ? 'Start position. Press forward to replay the line one move at a time with the quiz-style arrow map still visible.'
                      : preview.continuation.isEmpty
                      ? 'Final position reached. Step back or jump to the start to review the full line again.'
                      : '${preview.continuation.length} move${preview.continuation.length == 1 ? '' : 's'} remain from this position.',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.68),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: boardMaxWidth),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.30),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final reverse =
                                state._perspective == BoardPerspective.black ||
                                (state._perspective == BoardPerspective.auto &&
                                    !preview.whiteToMove);

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                state._buildQuizBoard(
                                  boardState: preview.boardState,
                                  whiteToMove: preview.whiteToMove,
                                ),
                                if (preview.continuation.isNotEmpty)
                                  AnimatedBuilder(
                                    animation: state._pulseController,
                                    builder: (context, child) => IgnorePointer(
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter: EnergyArrowPainter(
                                          lines: preview.continuation,
                                          bestEval: 0,
                                          progress:
                                              state._pulseController.value,
                                          reverse: reverse,
                                          showSequenceNumbers: true,
                                          overrideColor: const Color(
                                            0xFFB8BFC8,
                                          ),
                                          staticArrowStyle: true,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildQuizStudyReplayButton(
                        state,
                        icon: Icons.skip_previous_rounded,
                        tooltip: 'Jump to the start position',
                        onPressed: currentPly > 0
                            ? () => state._resetQuizStudyPosition(selectedLine)
                            : null,
                        accent: accent,
                      ),
                      _buildQuizStudyReplayButton(
                        state,
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Step back one move',
                        onPressed: currentPly > 0
                            ? () => state._stepQuizStudyBackward(selectedLine)
                            : null,
                        accent: accent,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          'Ply $currentPly of $totalPly',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _buildQuizStudyReplayButton(
                        state,
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'Step forward one move',
                        onPressed: currentPly < totalPly
                            ? () => state._stepQuizStudyForward(selectedLine)
                            : null,
                        accent: accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
            ),
            child: Text(
              'This opening could not be replayed into a clean preview board, but the stored line is still available below.',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.74),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        const SizedBox(height: 14),
        Text(
          'Stored line',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: state._buildMoveSequenceText(
            selectedLine.normalizedMoves,
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.82),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

Widget _buildQuizStudyReplayButton(
  _QuizScreen state, {
  required IconData icon,
  required String tooltip,
  required VoidCallback? onPressed,
  required Color accent,
}) {
  final scheme = Theme.of(state.context).colorScheme;

  return Tooltip(
    message: tooltip,
    child: IconButton.filledTonal(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: accent,
        backgroundColor: accent.withValues(alpha: 0.14),
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.26),
        disabledBackgroundColor: scheme.surface.withValues(alpha: 0.42),
        fixedSize: const Size(46, 46),
      ),
      icon: Icon(icon),
    ),
  );
}
