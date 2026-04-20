part of '../../analysis/screens/chess_analysis_page.dart';

Widget _buildQuizStudyScreen(_QuizScreen state) {
  final media = MediaQuery.of(state.context);
  final theme = Theme.of(state.context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final useMonochrome =
      state.context.watch<AppThemeProvider>().isMonochrome ||
      state._isCinematicThemeEnabled;
  final palette = state._academyPalette(
    scheme: scheme,
    useMonochrome: useMonochrome,
    isDark: isDark,
  );
  final highestUnlocked = state._quizAcademyProgress
      .highestUnlockedDifficulty();
  final selectedLine = state._quizStudyDetailOpen
      ? state._selectedQuizStudyLine()
      : null;
  final showingDetail = selectedLine != null;
  final shelfAccent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final shelfLabel = state._quizStudyCategoryLabel(state._quizStudyCategory);
  final shelfStudied = state._quizStudyCategoryStudiedCount(
    state._quizStudyCategory,
  );
  final shelfTotal = state._quizStudyCategoryTotalCount(
    state._quizStudyCategory,
  );
  final familyGroups = state._quizStudyFamilyGroups(state._quizStudyCategory);
  final detailFamilyName = selectedLine == null
      ? ''
      : state._quizStudyFamilyName(selectedLine.name);
  final detailVariationLabel = selectedLine == null
      ? ''
      : state._quizStudyVariationLabel(selectedLine, detailFamilyName);
  final detailStudyTitle = selectedLine == null
      ? ''
      : detailVariationLabel == detailFamilyName
      ? detailFamilyName
      : '$detailFamilyName • $detailVariationLabel';
  final sideInset = max(16.0, (media.size.width - 1200.0) / 2);
  final contentBottomPadding = 18 + media.padding.bottom;

  final marqueeBadges = showingDetail
      ? const <Widget>[]
      : <Widget>[
          state._buildQuizAcademyMetricChip(
            palette: palette,
            label: 'SHELF',
            value: shelfLabel,
            accent: shelfAccent,
            icon: state._quizStudyCategoryIcon(state._quizStudyCategory),
          ),
          state._buildQuizAcademyMetricChip(
            palette: palette,
            label: 'FAMILIES',
            value: familyGroups.length.toString(),
            accent: palette.cyan,
            icon: Icons.grid_view_rounded,
          ),
          state._buildQuizAcademyMetricChip(
            palette: palette,
            label: 'STUDIED',
            value: '$shelfStudied/$shelfTotal',
            accent: palette.amber,
            icon: Icons.auto_stories_outlined,
          ),
          state._buildQuizAcademyMetricChip(
            palette: palette,
            label: 'LADDER',
            value: state._quizAcademyBracketShortName(highestUnlocked),
            accent: palette.emerald,
            icon: Icons.workspace_premium_outlined,
          ),
        ];

  return Stack(
    children: <Widget>[
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              palette.backdrop,
              palette.shell,
              Color.alphaBlend(
                palette.boardLight.withValues(alpha: isDark ? 0.10 : 0.18),
                scheme.surface,
              ),
            ],
            stops: const <double>[0.0, 0.55, 1.0],
          ),
        ),
      ),
      Positioned.fill(child: state._academyBackdropLayer(palette: palette)),
      Positioned.fill(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sideInset),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 12),
                _buildQuizStudyTopBar(
                  state,
                  palette: palette,
                  showingDetail: showingDetail,
                  accent: shelfAccent,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(bottom: contentBottomPadding),
                    children: <Widget>[
                      state._academyMarquee(
                        palette: palette,
                        eyebrow: showingDetail
                            ? 'VARIATION STUDY'
                            : 'OPENING STUDY',
                        title: showingDetail
                            ? detailStudyTitle
                            : 'STUDY LIBRARY',
                        subtitle: showingDetail
                            ? 'Replay this line, swap sibling variations, and keep training the ${shelfLabel.toUpperCase()} shelf.'
                            : 'Browse opening families, replay stored lines, and turn quiz unlocks into durable board memory.',
                        accent: showingDetail ? shelfAccent : palette.cyan,
                        badges: marqueeBadges,
                      ),
                      const SizedBox(height: 16),
                      if (showingDetail)
                        _buildQuizStudyDetailScreen(
                          state,
                          selectedLine: selectedLine,
                          palette: palette,
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final sideBySide = constraints.maxWidth >= 1080;
                            final missionPanel = _buildQuizStudyMissionPanel(
                              state,
                              highestUnlocked: highestUnlocked,
                              palette: palette,
                            );
                            final libraryPanel = _buildQuizStudyLibraryPanel(
                              state,
                              palette: palette,
                            );

                            if (sideBySide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Flexible(flex: 4, child: missionPanel),
                                  const SizedBox(width: 16),
                                  Flexible(flex: 6, child: libraryPanel),
                                ],
                              );
                            }

                            return Column(
                              children: <Widget>[
                                missionPanel,
                                const SizedBox(height: 16),
                                libraryPanel,
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildQuizStudyTopBar(
  _QuizScreen state, {
  required _QuizAcademyPalette palette,
  required bool showingDetail,
  required Color accent,
}) {
  final backButton = state._academyHudButton(
    palette: palette,
    icon: showingDetail
        ? Icons.keyboard_return_rounded
        : Icons.arrow_back_rounded,
    label: showingDetail ? 'BACK TO LIBRARY' : 'BACK TO QUIZ',
    accent: showingDetail ? accent : palette.text,
    onTap: showingDetail
        ? state._closeQuizStudyDetail
        : state._exitQuizStudyScreen,
  );
  final styleButton = _buildQuizStudyTopIconButton(
    state,
    palette: palette,
    icon: Icons.palette_outlined,
    accent: palette.cyan,
    tooltip: 'Style',
    onTap: state._openAppearanceSettings,
  );
  final statsButton = _buildQuizStudyTopIconButton(
    state,
    palette: palette,
    icon: Icons.insights_outlined,
    accent: palette.amber,
    tooltip: 'Stats',
    onTap: state._openQuizStatsSheet,
  );

  return state._academyPixelPanel(
    palette: palette,
    accent: showingDetail ? accent : palette.cyan,
    fillColor: palette.panelAlt,
    padding: const EdgeInsets.all(10),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: backButton,
            ),
          ),
        ),
        const SizedBox(width: 10),
        styleButton,
        const SizedBox(width: 10),
        statsButton,
      ],
    ),
  );
}

Widget _buildQuizStudyTopIconButton(
  _QuizScreen state, {
  required _QuizAcademyPalette palette,
  required IconData icon,
  required Color accent,
  required String tooltip,
  required VoidCallback onTap,
}) {
  return Tooltip(
    message: tooltip,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.08),
              palette.shell,
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: accent.withValues(alpha: 0.48), width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.shadow.withValues(alpha: 0.22),
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
      ),
    ),
  );
}

Widget _buildQuizStudyMissionPanel(
  _QuizScreen state, {
  required QuizDifficulty highestUnlocked,
  required _QuizAcademyPalette palette,
}) {
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

  return state._academyPixelPanel(
    palette: palette,
    accent: selectedColor,
    fillColor: palette.panelAlt,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: state._academyPanelHeader(
                palette: palette,
                title: 'STUDY SHELVES',
                subtitle:
                    'Pick a cartridge tier, track completion, and keep the replay library synced with your quiz ladder.',
                infoTitle: 'Opening Study Library',
                infoMessage:
                    'Basic mirrors the easy quiz shelf, Advanced mirrors medium, Master mirrors hard, Grandmaster mirrors very hard, and Library stays open for the full replayable opening catalog.',
              ),
            ),
            const SizedBox(width: 12),
            state._academyHudButton(
              palette: palette,
              icon: state._quizStudyShelfExpanded
                  ? Icons.unfold_less_rounded
                  : Icons.unfold_more_rounded,
              label: state._quizStudyShelfExpanded ? 'COLLAPSE' : 'EXPAND',
              accent: selectedColor,
              onTap: state._toggleQuizStudyShelfExpanded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!state._quizStudyShelfExpanded)
          _buildQuizStudyCategoryCard(
            state,
            state._quizStudyCategory,
            palette: palette,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 600
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
                        child: _buildQuizStudyCategoryCard(
                          state,
                          category,
                          palette: palette,
                        ),
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
          children: <Widget>[
            state._buildQuizAcademyMetricChip(
              palette: palette,
              label: 'SHELF',
              value: state._quizStudyCategoryLabel(state._quizStudyCategory),
              accent: selectedColor,
              icon: state._quizStudyCategoryIcon(state._quizStudyCategory),
            ),
            state._buildQuizAcademyMetricChip(
              palette: palette,
              label: 'REPS',
              value: state._quizStudyTotalReps().toString(),
              accent: palette.amber,
              icon: Icons.repeat_rounded,
            ),
            state._buildQuizAcademyMetricChip(
              palette: palette,
              label: 'LADDER',
              value: state._quizAcademyBracketShortName(highestUnlocked),
              accent: palette.cyan,
              icon: Icons.workspace_premium_outlined,
            ),
            state._buildQuizAcademyMetricChip(
              palette: palette,
              label: 'OPENINGS',
              value: '$selectedStudied/$selectedTotal',
              accent: palette.emerald,
              icon: Icons.menu_book_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildQuizStudyMeter(
          state,
          palette: palette,
          label: 'SELECTED SHELF COMPLETION',
          valueLabel: '${(selectedCompletion * 100).toStringAsFixed(0)}%',
          value: selectedCompletion,
          accent: selectedColor,
        ),
        const SizedBox(height: 10),
        Text(
          selectedTotal <= 0
              ? 'This shelf is still waiting for replayable openings to finish loading.'
              : '$selectedStudied of $selectedTotal openings have been studied at least once in ${state._quizStudyCategoryLabel(state._quizStudyCategory).toLowerCase()}. You have logged $selectedReps study rep${selectedReps == 1 ? '' : 's'} in this shelf.',
          style: state._academyHudStyle(
            palette: palette,
            size: 12.6,
            color: palette.textMuted,
            weight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

Widget _buildQuizStudyCategoryCard(
  _QuizScreen state,
  QuizStudyCategory category, {
  required _QuizAcademyPalette palette,
}) {
  final selected = state._quizStudyCategory == category;
  final accent = state._quizStudyCategoryColor(category);
  final total = state._quizStudyCategoryTotalCount(category);
  final studied = state._quizStudyCategoryStudiedCount(category);
  final completion = state._quizStudyCategoryCompletion(category);
  final reps = state._quizStudyCategoryTotalReps(category);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => state._setQuizStudyCategory(category),
      borderRadius: BorderRadius.circular(4),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                accent.withValues(alpha: selected ? 0.16 : 0.08),
                selected ? palette.panelAlt : palette.panel,
              ),
              selected ? palette.panelAlt : palette.panel,
            ],
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? accent : palette.line,
            width: selected ? 3 : 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: (selected ? accent : palette.shadow).withValues(
                alpha: selected ? 0.18 : 0.12,
              ),
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      accent.withValues(alpha: 0.14),
                      palette.shell,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.46),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    state._quizStudyCategoryIcon(category),
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              state
                                  ._quizStudyCategoryLabel(category)
                                  .toUpperCase(),
                              style: state._academyDisplayStyle(
                                palette: palette,
                                size: 18,
                                color: palette.text,
                                weight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (selected) ...<Widget>[
                            const SizedBox(width: 8),
                            state._academyTag(
                              palette: palette,
                              label: 'ACTIVE',
                              accent: accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state._quizStudyCategorySubtitle(category),
                        style: state._academyHudStyle(
                          palette: palette,
                          size: 12.2,
                          color: palette.textMuted,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                state._buildQuizAcademyMetricChip(
                  palette: palette,
                  label: 'OPENINGS',
                  value: '$studied/$total',
                  accent: accent,
                  compact: true,
                ),
                state._buildQuizAcademyMetricChip(
                  palette: palette,
                  label: 'REPS',
                  value: reps.toString(),
                  accent: palette.amber,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuizStudyMeter(
              state,
              palette: palette,
              label: selected ? 'ACTIVE LOADOUT' : 'SHELF COMPLETION',
              valueLabel: '${(completion * 100).toStringAsFixed(0)}%',
              value: completion,
              accent: accent,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildQuizStudyLibraryPanel(
  _QuizScreen state, {
  required _QuizAcademyPalette palette,
}) {
  final isLoading = !state._quizStudyDataReady() && state._ecoOpeningsLoading;
  final groups = isLoading
      ? const <_QuizStudyFamilyGroup>[]
      : state._quizStudyFamilyGroups(state._quizStudyCategory);
  final searchActive = state._quizStudySearchQuery.trim().isNotEmpty;
  final searchAccent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final matchingLines = groups.fold<int>(
    0,
    (sum, group) => sum + group.lines.length,
  );
  final browserHeight = min(
    820.0,
    max(520.0, MediaQuery.sizeOf(state.context).height * 0.72),
  );

  return KeyedSubtree(
    key: state._quizStudyLibraryIndexKey,
    child: state._academyPixelPanel(
      palette: palette,
      accent: palette.cyan,
      fillColor: palette.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          state._academyPanelHeader(
            palette: palette,
            title: 'LIBRARY INDEX',
            subtitle:
                'Search every family in the current shelf and launch any variation on its own replay board.',
            infoTitle: 'Study Library',
            infoMessage:
                'Choose a family, then open a variation on its own study screen. Search stays here so the detail view can stay focused and easy to navigate.',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: state._academyHudButton(
              palette: palette,
              icon: Icons.restart_alt_rounded,
              label: 'RESET STUDIED',
              accent: palette.signal,
              onTap: state._quizStudyTotalReps() > 0
                  ? () => unawaited(state._showQuizStudyResetDialog())
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: palette.shell,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: searchAccent.withValues(alpha: 0.48),
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
            child: TextFormField(
              key: ValueKey(
                'quiz-study-search-${state._quizStudyCategory.name}',
              ),
              initialValue: state._quizStudySearchQuery,
              enabled: !isLoading,
              onChanged: state._setQuizStudySearchQuery,
              style: state._academyHudStyle(
                palette: palette,
                size: 12.8,
                color: palette.text,
                weight: FontWeight.w700,
                letterSpacing: 0.65,
              ),
              cursorColor: searchAccent,
              decoration: InputDecoration(
                hintText: 'Search openings, variations, or moves',
                hintStyle: state._academyHudStyle(
                  palette: palette,
                  size: 12.4,
                  color: palette.textMuted,
                  weight: FontWeight.w600,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: searchAccent),
                suffixIcon: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: searchAccent,
                          ),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              state._buildQuizAcademyMetricChip(
                palette: palette,
                label: 'SHELF',
                value: state._quizStudyCategoryLabel(state._quizStudyCategory),
                accent: searchAccent,
                icon: state._quizStudyCategoryIcon(state._quizStudyCategory),
              ),
              state._buildQuizAcademyMetricChip(
                palette: palette,
                label: 'FAMILIES',
                value: groups.length.toString(),
                accent: palette.cyan,
                icon: Icons.grid_view_rounded,
              ),
              state._buildQuizAcademyMetricChip(
                palette: palette,
                label: searchActive ? 'MATCHES' : 'OPENINGS',
                value: matchingLines.toString(),
                accent: palette.amber,
                icon: searchActive
                    ? Icons.search_rounded
                    : Icons.library_books_outlined,
              ),
              state._buildQuizAcademyMetricChip(
                palette: palette,
                label: 'STUDIED',
                value:
                    '${state._quizStudyCategoryStudiedCount(state._quizStudyCategory)}/${state._quizStudyCategoryTotalCount(state._quizStudyCategory)}',
                accent: palette.emerald,
                icon: Icons.menu_book_outlined,
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
              palette: palette,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildQuizStudyFamilyListPane(
  _QuizScreen state, {
  required List<_QuizStudyFamilyGroup> groups,
  required bool isLoading,
  required bool searchActive,
  required _QuizAcademyPalette palette,
}) {
  return state._academyPixelPanel(
    palette: palette,
    accent: palette.cyan,
    fillColor: palette.shell,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        state._academyPanelHeader(
          palette: palette,
          title: 'FAMILY GRID',
          subtitle: searchActive
              ? 'Search locks matching families open for quick jumps into a variation board.'
              : 'Flip open a family cartridge to inspect every stored line in this shelf.',
          infoTitle: 'Opening Families',
          infoMessage: searchActive
              ? 'Search keeps matching families open so you can jump straight into a variation detail page.'
              : 'Tap a family name to reveal the included lines and open any variation on its own study page.',
        ),
        const SizedBox(height: 12),
        Expanded(
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: palette.cyan,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading bundled study library...',
                        textAlign: TextAlign.center,
                        style: state._academyHudStyle(
                          palette: palette,
                          size: 13,
                          color: palette.textMuted,
                          weight: FontWeight.w700,
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
                    style: state._academyHudStyle(
                      palette: palette,
                      size: 13,
                      color: palette.textMuted,
                      weight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                )
              : Scrollbar(
                  controller: state._quizStudyLibraryScrollController,
                  child: ListView(
                    controller: state._quizStudyLibraryScrollController,
                    children: groups
                        .map((group) {
                          final expanded =
                              searchActive ||
                              state._quizStudyExpandedFamily ==
                                  group.familyName;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildQuizStudyFamilyCard(
                              state,
                              group: group,
                              expanded: expanded,
                              searchActive: searchActive,
                              palette: palette,
                            ),
                          );
                        })
                        .toList(growable: false),
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
  required _QuizAcademyPalette palette,
}) {
  final accent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final studiedCount = state._quizStudyFamilyStudiedCount(group);
  final studyProgress = group.lines.isEmpty
      ? 0.0
      : studiedCount / group.lines.length;
  final familyFullyStudied =
      group.lines.isNotEmpty && studiedCount >= group.lines.length;
  final familyHasSelection = group.lines.any(
    (line) => line.name == state._quizStudySelectedOpeningName,
  );
  final frameAccent = familyHasSelection ? accent : palette.cyan;

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.alphaBlend(
            frameAccent.withValues(alpha: familyHasSelection ? 0.14 : 0.08),
            familyHasSelection ? palette.panelAlt : palette.panel,
          ),
          familyHasSelection ? palette.panelAlt : palette.panel,
        ],
      ),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: familyHasSelection ? accent : palette.line,
        width: familyHasSelection ? 3 : 2,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: palette.shadow.withValues(alpha: 0.14),
          offset: const Offset(4, 4),
          blurRadius: 0,
        ),
      ],
    ),
    child: Column(
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: searchActive
                ? null
                : () => state._toggleQuizStudyFamily(group.familyName),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          group.familyName,
                          style: state._academyDisplayStyle(
                            palette: palette,
                            size: 16,
                            color: palette.text,
                            weight: FontWeight.w700,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${group.lines.length} variation${group.lines.length == 1 ? '' : 's'} in the ${state._quizStudyCategoryLabel(state._quizStudyCategory).toLowerCase()} shelf • $studiedCount studied${searchActive ? ' • auto-opened by search' : ''}',
                          style: state._academyHudStyle(
                            palette: palette,
                            size: 12.2,
                            color: palette.textMuted,
                            weight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (familyHasSelection) ...<Widget>[
                    const SizedBox(width: 10),
                    state._academyTag(
                      palette: palette,
                      label: 'ACTIVE',
                      accent: accent,
                    ),
                  ] else if (searchActive) ...<Widget>[
                    const SizedBox(width: 10),
                    state._academyTag(
                      palette: palette,
                      label: 'MATCH',
                      accent: palette.amber,
                    ),
                  ],
                  const SizedBox(width: 10),
                  _buildQuizStudyFamilyProgressGauge(
                    state,
                    palette: palette,
                    accent: familyFullyStudied ? palette.emerald : frameAccent,
                    progress: studyProgress,
                    completed: familyFullyStudied,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...<Widget>[
          Container(height: 2, color: palette.line.withValues(alpha: 0.55)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                for (var index = 0; index < group.lines.length; index++) ...[
                  _buildQuizStudyVariationTile(
                    state,
                    line: group.lines[index],
                    familyName: group.familyName,
                    palette: palette,
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

Widget _buildQuizStudyFamilyProgressGauge(
  _QuizScreen state, {
  required _QuizAcademyPalette palette,
  required Color accent,
  required double progress,
  required bool completed,
}) {
  final clampedProgress = progress.clamp(0.0, 1.0).toDouble();

  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: Color.alphaBlend(
        accent.withValues(alpha: completed ? 0.18 : 0.10),
        palette.shell,
      ),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: accent.withValues(alpha: 0.44), width: 2),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            value: clampedProgress,
            strokeWidth: 3.6,
            backgroundColor: palette.line.withValues(alpha: 0.32),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        completed
            ? Icon(Icons.check_rounded, size: 18, color: palette.emerald)
            : Text(
                '${(clampedProgress * 100).round()}%',
                style: state._academyHudStyle(
                  palette: palette,
                  size: 8.8,
                  color: palette.text,
                  weight: FontWeight.w800,
                  letterSpacing: 0.1,
                  height: 1.0,
                ),
              ),
      ],
    ),
  );
}

Widget _buildQuizStudyVariationTile(
  _QuizScreen state, {
  required EcoLine line,
  required String familyName,
  required _QuizAcademyPalette palette,
}) {
  final accent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final selected = state._quizStudySelectedOpeningName == line.name;
  final studyCount = state._quizStudyCountFor(line.name);
  final variationLabel = state._quizStudyVariationLabel(line, familyName);

  final tile = Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => state._selectQuizStudyOpening(line),
      borderRadius: BorderRadius.circular(4),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                accent.withValues(alpha: selected ? 0.16 : 0.08),
                selected ? palette.panelAlt : palette.panel,
              ),
              selected ? palette.panelAlt : palette.panel,
            ],
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? accent : palette.line,
            width: selected ? 3 : 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.shadow.withValues(alpha: 0.12),
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 460;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          accent.withValues(alpha: 0.14),
                          palette.shell,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.40),
                          width: 2,
                        ),
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
                        children: <Widget>[
                          Text(
                            variationLabel,
                            style: state._academyDisplayStyle(
                              palette: palette,
                              size: 15,
                              color: palette.text,
                              weight: FontWeight.w700,
                              letterSpacing: 0.65,
                            ),
                          ),
                          if (variationLabel != line.name) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              line.name,
                              style: state._academyHudStyle(
                                palette: palette,
                                size: 11.8,
                                color: palette.textMuted,
                                weight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${line.moveTokens.length} ply stored in $familyName. Opens a dedicated replay board.',
                            style: state._academyHudStyle(
                              palette: palette,
                              size: 11.4,
                              color: palette.textMuted,
                              weight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!compact) ...<Widget>[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: palette.textMuted,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    state._buildQuizAcademyMetricChip(
                      palette: palette,
                      label: 'PLY',
                      value: line.moveTokens.length.toString(),
                      accent: palette.cyan,
                      compact: true,
                    ),
                    state._buildQuizAcademyMetricChip(
                      palette: palette,
                      label: 'STUDIED',
                      value: '${studyCount}x',
                      accent: palette.amber,
                      compact: true,
                    ),
                    state._academyTag(
                      palette: palette,
                      label: selected ? 'ACTIVE BOARD' : 'OPEN BOARD',
                      accent: selected ? accent : palette.emerald,
                    ),
                  ],
                ),
                if (compact) ...<Widget>[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );

  if (selected) {
    return KeyedSubtree(key: state._quizStudyLibrarySelectionKey, child: tile);
  }

  return tile;
}

Widget _buildQuizStudyDetailScreen(
  _QuizScreen state, {
  required EcoLine selectedLine,
  required _QuizAcademyPalette palette,
}) {
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

  return LayoutBuilder(
    builder: (context, constraints) {
      final sideBySide = constraints.maxWidth >= 1040;
      final navigatorPanel = _buildQuizStudyFamilyNavigatorPanel(
        state,
        selectedLine: selectedLine,
        familyName: familyName,
        familyLines: familyLines,
        studyCount: studyCount,
        palette: palette,
        accent: accent,
      );
      final boardPanel = _buildQuizStudyBoardWalkthroughPanel(
        state,
        selectedLine: selectedLine,
        preview: preview,
        palette: palette,
        accent: accent,
        boardMaxWidth: boardMaxWidth,
      );
      final storedLinePanel = _buildQuizStudyStoredLinePanel(
        state,
        selectedLine: selectedLine,
        preview: preview,
        variationLabel: variationLabel,
        palette: palette,
        accent: accent,
        boardMaxWidth: boardMaxWidth,
      );

      if (sideBySide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 6,
              child: Column(
                children: <Widget>[
                  storedLinePanel,
                  const SizedBox(height: 16),
                  boardPanel,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 5, child: navigatorPanel),
          ],
        );
      }

      return Column(
        children: <Widget>[
          storedLinePanel,
          const SizedBox(height: 16),
          boardPanel,
          const SizedBox(height: 16),
          navigatorPanel,
        ],
      );
    },
  );
}

Widget _buildQuizStudyFamilyNavigatorPanel(
  _QuizScreen state, {
  required EcoLine selectedLine,
  required String familyName,
  required List<EcoLine> familyLines,
  required int studyCount,
  required _QuizAcademyPalette palette,
  required Color accent,
}) {
  return state._academyPixelPanel(
    palette: palette,
    accent: accent,
    fillColor: palette.panelAlt,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        state._academyPanelHeader(
          palette: palette,
          title: 'FAMILY NAVIGATOR',
          subtitle: familyLines.length > 1
              ? 'Switch to another $familyName variation without leaving this replay board.'
              : 'This shelf currently stores a single variation for $familyName.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            state._buildQuizAcademyMetricChip(
              palette: palette,
              label: 'FAMILY',
              value: familyName,
              accent: palette.cyan,
              icon: Icons.account_tree_outlined,
            ),
            state._buildQuizAcademyMetricChip(
              palette: palette,
              label: 'SHELF',
              value: state._quizStudyCategoryLabel(state._quizStudyCategory),
              accent: accent,
              icon: state._quizStudyCategoryIcon(state._quizStudyCategory),
            ),
            state._buildQuizAcademyMetricChip(
              palette: palette,
              label: 'SIBLINGS',
              value: familyLines.length.toString(),
              accent: palette.emerald,
              icon: Icons.hub_outlined,
            ),
            state._buildQuizAcademyMetricChip(
              palette: palette,
              label: 'STUDIED',
              value: '${studyCount}x',
              accent: palette.amber,
              icon: Icons.bolt_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (familyLines.length > 1)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: familyLines
                .map(
                  (line) => _buildQuizStudyFamilyChoiceChip(
                    state,
                    palette: palette,
                    label: state._quizStudyVariationLabel(line, familyName),
                    studied: state._quizStudyCountFor(line.name) > 0,
                    selected: line.name == selectedLine.name,
                    onTap: () =>
                        state._selectQuizStudyOpening(line, focusBoard: true),
                    accent: accent,
                  ),
                )
                .toList(growable: false),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.10),
                palette.shell,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: accent.withValues(alpha: 0.28),
                width: 2,
              ),
            ),
            child: Text(
              'No sibling variations are currently grouped with this line in ${state._quizStudyCategoryLabel(state._quizStudyCategory).toLowerCase()}.',
              style: state._academyHudStyle(
                palette: palette,
                size: 12.5,
                color: palette.textMuted,
                weight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildQuizStudyBoardWalkthroughPanel(
  _QuizScreen state, {
  required EcoLine selectedLine,
  required _QuizStudyPreview? preview,
  required _QuizAcademyPalette palette,
  required Color accent,
  required double boardMaxWidth,
}) {
  final currentPly = preview?.shownPly ?? 0;
  final totalPly = preview?.totalPly ?? selectedLine.moveTokens.length;
  final previewUnavailableCopy =
      'This opening could not be replayed into a clean preview board, but the stored line is still available in Move Tape.';

  return KeyedSubtree(
    key: state._quizStudyBoardKey,
    child: state._academyPixelPanel(
      palette: palette,
      accent: palette.cyan,
      fillColor: palette.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          state._academyPanelHeader(
            palette: palette,
            title: 'BOARD WALKTHROUGH',
            subtitle: selectedLine.name,
          ),
          const SizedBox(height: 14),
          if (preview != null)
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: boardMaxWidth),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.shell,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: palette.line, width: 3),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: palette.shadow.withValues(alpha: 0.18),
                          offset: const Offset(6, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final reverse =
                            state._perspective == BoardPerspective.black ||
                            (state._perspective == BoardPerspective.auto &&
                                !preview.whiteToMove);

                        return Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
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
                                      progress: state._pulseController.value,
                                      reverse: reverse,
                                      showSequenceNumbers: true,
                                      overrideColor: palette.cyan.withValues(
                                        alpha: 0.88,
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
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  palette.amber.withValues(alpha: 0.08),
                  palette.shell,
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: palette.line, width: 2),
              ),
              child: Text(
                previewUnavailableCopy,
                style: state._academyHudStyle(
                  palette: palette,
                  size: 12.6,
                  color: palette.textMuted,
                  weight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: boardMaxWidth),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildQuizStudyReplayButton(
                      state,
                      palette: palette,
                      icon: Icons.skip_previous_rounded,
                      label: 'START',
                      tooltip: 'Jump to the start position',
                      onPressed: preview != null && currentPly > 0
                          ? () => state._resetQuizStudyPosition(selectedLine)
                          : null,
                      accent: palette.amber,
                    ),
                    const SizedBox(width: 10),
                    _buildQuizStudyReplayButton(
                      state,
                      palette: palette,
                      icon: Icons.chevron_left_rounded,
                      label: 'BACK',
                      tooltip: 'Step back one move',
                      onPressed: preview != null && currentPly > 0
                          ? () => state._stepQuizStudyBackward(selectedLine)
                          : null,
                      accent: accent,
                    ),
                    const SizedBox(width: 10),
                    _buildQuizStudyReplayButton(
                      state,
                      palette: palette,
                      icon: Icons.chevron_right_rounded,
                      label: 'NEXT',
                      tooltip: 'Step forward one move',
                      onPressed: preview != null && currentPly < totalPly
                          ? () => state._stepQuizStudyForward(selectedLine)
                          : null,
                      accent: palette.cyan,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildQuizStudyStoredLinePanel(
  _QuizScreen state, {
  required EcoLine selectedLine,
  required _QuizStudyPreview? preview,
  required String variationLabel,
  required _QuizAcademyPalette palette,
  required Color accent,
  required double boardMaxWidth,
}) {
  final infoExpanded = state._quizStudyInfoExpanded;
  final currentPly = preview?.shownPly ?? 0;
  final totalPly = preview?.totalPly ?? selectedLine.moveTokens.length;
  final remainingMoves = preview?.continuation.length ?? 0;

  return state._academyPixelPanel(
    palette: palette,
    accent: palette.amber,
    fillColor: palette.panelAlt,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: state._toggleQuizStudyInfoExpanded,
            borderRadius: BorderRadius.circular(4),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  palette.amber.withValues(alpha: 0.08),
                  palette.shell,
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: palette.amber.withValues(alpha: 0.30),
                  width: 2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'MOVE TAPE',
                          style: state._academyDisplayStyle(
                            palette: palette,
                            size: 20,
                            weight: FontWeight.w700,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          infoExpanded
                              ? 'Stored notation and board status for $variationLabel. Tap to close this info panel.'
                              : 'Tap to open stored notation and board status for $variationLabel.',
                          style: state._academyHudStyle(
                            palette: palette,
                            size: 12.5,
                            color: palette.textMuted,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      state._academyTag(
                        palette: palette,
                        label: infoExpanded ? 'OPEN' : 'CLOSED',
                        accent: infoExpanded ? palette.emerald : palette.amber,
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        infoExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: infoExpanded ? palette.emerald : palette.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (infoExpanded) ...<Widget>[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: boardMaxWidth),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: <Widget>[
                  state._buildQuizAcademyMetricChip(
                    palette: palette,
                    label: 'POSITION',
                    value: '$currentPly/$totalPly',
                    accent: accent,
                    icon: Icons.memory_rounded,
                  ),
                  state._buildQuizAcademyMetricChip(
                    palette: palette,
                    label: 'TO MOVE',
                    value: preview == null
                        ? '--'
                        : (preview.whiteToMove ? 'WHITE' : 'BLACK'),
                    accent: palette.emerald,
                    icon: Icons.swap_vert_rounded,
                  ),
                  state._buildQuizAcademyMetricChip(
                    palette: palette,
                    label: 'REMAINING',
                    value: preview == null ? '--' : remainingMoves.toString(),
                    accent: palette.amber,
                    icon: Icons.route_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.10),
                palette.shell,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: accent.withValues(alpha: 0.28),
                width: 2,
              ),
            ),
            child: state._buildMoveSequenceText(
              selectedLine.normalizedMoves,
              fontSize: 13,
              color: palette.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildQuizStudyFamilyChoiceChip(
  _QuizScreen state, {
  required _QuizAcademyPalette palette,
  required String label,
  required bool studied,
  required bool selected,
  required VoidCallback onTap,
  required Color accent,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : palette.shell,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? accent : palette.line, width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.shadow.withValues(alpha: selected ? 0.18 : 0.10),
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: state._academyHudStyle(
                palette: palette,
                size: 11.8,
                color: selected ? accent : palette.text,
                weight: FontWeight.w800,
                letterSpacing: 0.7,
                height: 1.0,
              ),
            ),
            if (studied) ...<Widget>[
              const SizedBox(width: 6),
              Icon(Icons.check_rounded, size: 14, color: palette.emerald),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _buildQuizStudyReplayButton(
  _QuizScreen state, {
  required _QuizAcademyPalette palette,
  required IconData icon,
  required String label,
  required String tooltip,
  required VoidCallback? onPressed,
  required Color accent,
}) {
  return Tooltip(
    message: tooltip,
    child: state._academyHudButton(
      palette: palette,
      icon: icon,
      label: label,
      accent: accent,
      onTap: onPressed,
    ),
  );
}

Widget _buildQuizStudyMeter(
  _QuizScreen state, {
  required _QuizAcademyPalette palette,
  required String label,
  required String valueLabel,
  required double value,
  required Color accent,
}) {
  final clampedValue = value.clamp(0.0, 1.0).toDouble();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: state._academyHudStyle(
                palette: palette,
                size: 11.8,
                color: palette.text,
                weight: FontWeight.w800,
                letterSpacing: 0.75,
                height: 1.0,
              ),
            ),
          ),
          Text(
            valueLabel,
            style: state._academyHudStyle(
              palette: palette,
              size: 11.8,
              color: accent,
              weight: FontWeight.w800,
              letterSpacing: 0.75,
              height: 1.0,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        height: 16,
        decoration: BoxDecoration(
          color: palette.shell,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: palette.line, width: 2),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clampedValue,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[accent, accent.withValues(alpha: 0.74)],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
