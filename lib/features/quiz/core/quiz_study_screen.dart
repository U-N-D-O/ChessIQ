part of '../../analysis/screens/chess_analysis_page.dart';

enum _QuizStudyLayoutMode { phonePortrait, phoneLandscape, tablet }

class _QuizStudyLayoutSpec {
  const _QuizStudyLayoutSpec({
    required this.mode,
    required this.contentMaxWidth,
    required this.sectionGap,
    required this.browserHeight,
    required this.horizontalPadding,
  });

  factory _QuizStudyLayoutSpec.fromMedia(MediaQueryData media) {
    final safeHeight = media.size.height - media.padding.vertical;
    final isLandscape = media.orientation == Orientation.landscape;
    final isTablet =
        media.size.width >= 920 ||
        (media.size.width >= 760 && safeHeight >= 700);

    return _QuizStudyLayoutSpec(
      mode: isTablet
          ? _QuizStudyLayoutMode.tablet
          : isLandscape
          ? _QuizStudyLayoutMode.phoneLandscape
          : _QuizStudyLayoutMode.phonePortrait,
      contentMaxWidth: isTablet ? 1240 : 820,
      sectionGap: isTablet ? 16 : 12,
      browserHeight: isTablet
          ? min(780.0, max(560.0, safeHeight * 0.72))
          : isLandscape
          ? max(280.0, safeHeight * 0.82)
          : max(360.0, safeHeight * 0.54),
      horizontalPadding: isTablet ? 18 : 12,
    );
  }

  final _QuizStudyLayoutMode mode;
  final double contentMaxWidth;
  final double sectionGap;
  final double browserHeight;
  final double horizontalPadding;

  bool get isTablet => mode == _QuizStudyLayoutMode.tablet;
  bool get compactPhoneLayout => !isTablet;
  bool get showInlineSecondaryInfo => isTablet;
}

String _quizStudyKeyToken(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? 'item' : normalized;
}

String _quizStudyCategoryInfoMessage(_QuizScreen state) {
  final lines = <String>[
    'Each study category maps directly to the matching quiz level.',
  ];
  for (final category in QuizStudyCategory.values) {
    lines.add(
      '${state._quizStudyCategoryLabel(category)}: ${state._quizStudyCategorySubtitle(category)}.',
    );
  }
  lines.add('Library keeps the full opening browser available at any time.');
  return lines.join('\n');
}

String _quizStudyBrowserInfoMessage(
  _QuizScreen state, {
  required int familyCount,
  required int openingCount,
  required int studiedCount,
}) {
  final categoryLabel = state._quizStudyCategoryLabel(state._quizStudyCategory);
  return '$categoryLabel currently includes '
      '$familyCount opening ${familyCount == 1 ? 'family' : 'families'} and '
      '$openingCount saved ${openingCount == 1 ? 'line' : 'lines'}. '
      'You have already opened $studiedCount '
      '${studiedCount == 1 ? 'line' : 'lines'} for study. '
      'Search checks both family names and opening names.';
}

String _quizStudyLineInfoMessage(
  _QuizScreen state, {
  required EcoLine line,
  required String familyName,
  required String variationLabel,
}) {
  final studiedCount = state._quizStudyOpeningCounts[line.name] ?? 0;
  final storedMoves = line.normalizedMoves;
  final infoLines = <String>[
    'Category: ${state._quizStudyCategoryLabel(state._quizStudyCategory)}',
    'Family: $familyName',
    'Variation: $variationLabel',
    if (variationLabel != line.name) 'Opening: ${line.name}',
    'Stored moves: ${line.moveTokens.length}',
    'Times studied: $studiedCount',
  ];

  if (storedMoves.isNotEmpty) {
    infoLines
      ..add('')
      ..add(storedMoves);
  }

  return infoLines.join('\n');
}

Widget _buildQuizStudySummaryChip({
  required String label,
  required String value,
  required IconData icon,
  required Color accent,
  required _QuizAcademyPalette palette,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: palette.shell.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accent.withValues(alpha: 0.30)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: GoogleFonts.pressStart2p(
                fontSize: 8,
                color: palette.textMuted,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildQuizStudyScreen(_QuizScreen state) {
  final media = MediaQuery.of(state.context);
  final layout = _QuizStudyLayoutSpec.fromMedia(media);
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
  final categoryAccent = state._quizStudyCategoryColor(
    state._quizStudyCategory,
  );
  final categoryLabel = state._quizStudyCategoryLabel(state._quizStudyCategory);
  final detailFamilyName = selectedLine == null
      ? ''
      : state._quizStudyFamilyName(selectedLine.name);
  final detailVariationLabel = selectedLine == null
      ? ''
      : state._quizStudyVariationLabel(selectedLine, detailFamilyName);
  final pageTitle = showingDetail
      ? detailVariationLabel == detailFamilyName
            ? detailFamilyName
            : '$detailFamilyName • $detailVariationLabel'
      : 'OPENING STUDY';
  final pageSubtitle = showingDetail
      ? '$detailFamilyName • $categoryLabel'
      : '$categoryLabel category';
  final sideInset = max(
    layout.horizontalPadding,
    (media.size.width - layout.contentMaxWidth) / 2,
  );
  final contentBottomPadding = 18 + media.padding.bottom;

  final browserContent =
      layout.isTablet || layout.mode == _QuizStudyLayoutMode.phoneLandscape
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Flexible(
              flex: layout.isTablet ? 4 : 5,
              child: _buildQuizStudyMissionPanel(
                state,
                highestUnlocked: highestUnlocked,
                palette: palette,
                layout: layout,
              ),
            ),
            SizedBox(width: layout.sectionGap),
            Flexible(
              flex: 7,
              child: _buildQuizStudyLibraryPanel(
                state,
                palette: palette,
                layout: layout,
              ),
            ),
          ],
        )
      : Column(
          children: <Widget>[
            _buildQuizStudyMissionPanel(
              state,
              highestUnlocked: highestUnlocked,
              palette: palette,
              layout: layout,
            ),
            SizedBox(height: layout.sectionGap),
            _buildQuizStudyLibraryPanel(
              state,
              palette: palette,
              layout: layout,
            ),
          ],
        );

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
                  accent: categoryAccent,
                  layout: layout,
                  title: pageTitle,
                  subtitle: pageSubtitle,
                ),
                SizedBox(height: layout.sectionGap),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(bottom: contentBottomPadding),
                    children: <Widget>[
                      if (showingDetail)
                        _buildQuizStudyDetailScreen(
                          state,
                          selectedLine: selectedLine,
                          palette: palette,
                          layout: layout,
                        )
                      else
                        browserContent,
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
  required _QuizStudyLayoutSpec layout,
  required String title,
  required String subtitle,
}) {
  final useStackedLayout = layout.compactPhoneLayout;
  final compactPhoneTopBar = useStackedLayout;
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
  final titleBlock = Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: useStackedLayout
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center,
    children: <Widget>[
      Text(
        title.toUpperCase(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: useStackedLayout ? TextAlign.left : TextAlign.center,
        style: state._academyDisplayStyle(
          palette: palette,
          size: useStackedLayout ? 17 : 18,
          color: palette.text,
          weight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: useStackedLayout ? TextAlign.left : TextAlign.center,
        style: state._academyHudStyle(
          palette: palette,
          size: 12.2,
          color: palette.textMuted,
          weight: FontWeight.w700,
        ),
      ),
    ],
  );

  return state._academyPixelPanel(
    palette: palette,
    accent: showingDetail ? accent : palette.cyan,
    fillColor: palette.panelAlt,
    padding: compactPhoneTopBar
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
        : const EdgeInsets.all(10),
    child: useStackedLayout
        ? Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: state._academyHudButton(
                      palette: palette,
                      icon: showingDetail
                          ? Icons.keyboard_return_rounded
                          : Icons.arrow_back_rounded,
                      label: showingDetail ? 'BACK TO BROWSER' : 'BACK TO QUIZ',
                      accent: showingDetail ? accent : palette.text,
                      onTap: showingDetail
                          ? state._closeQuizStudyDetail
                          : state._exitQuizStudyScreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              styleButton,
              const SizedBox(width: 8),
              statsButton,
            ],
          )
        : Row(
            children: <Widget>[
              state._academyHudButton(
                palette: palette,
                icon: showingDetail
                    ? Icons.keyboard_return_rounded
                    : Icons.arrow_back_rounded,
                label: showingDetail ? 'BACK TO BROWSER' : 'BACK TO QUIZ',
                accent: showingDetail ? accent : palette.text,
                onTap: showingDetail
                    ? state._closeQuizStudyDetail
                    : state._exitQuizStudyScreen,
              ),
              const SizedBox(width: 14),
              Expanded(child: titleBlock),
              const SizedBox(width: 14),
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

Widget _buildQuizStudySearchControls(
  _QuizScreen state, {
  required _QuizAcademyPalette palette,
  required _QuizStudyLayoutSpec layout,
  required bool isLoading,
  required bool resetEnabled,
}) {
  final searchAccent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final compactLandscape =
      layout.mode == _QuizStudyLayoutMode.phoneLandscape && !layout.isTablet;

  return Row(
    key: const ValueKey<String>('quiz_study_search_controls'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        child: Container(
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
            key: ValueKey('quiz-study-search-${state._quizStudyCategory.name}'),
            initialValue: state._quizStudySearchQuery,
            enabled: !isLoading,
            onChanged: state._setQuizStudySearchQuery,
            style: state._academyHudStyle(
              palette: palette,
              size: compactLandscape ? 11.8 : 12.8,
              color: palette.text,
              weight: FontWeight.w700,
              letterSpacing: compactLandscape ? 0.45 : 0.65,
            ),
            cursorColor: searchAccent,
            decoration: InputDecoration(
              hintText: compactLandscape
                  ? 'Search openings'
                  : 'Search family or opening name',
              hintStyle: state._academyHudStyle(
                palette: palette,
                size: compactLandscape ? 11.6 : 12.4,
                color: palette.textMuted,
                weight: FontWeight.w600,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: compactLandscape ? 20 : 24,
                color: searchAccent,
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: compactLandscape ? 42 : 48,
                minHeight: compactLandscape ? 42 : 48,
              ),
              suffixIcon: isLoading
                  ? Padding(
                      padding: EdgeInsets.all(compactLandscape ? 10 : 12),
                      child: SizedBox(
                        width: compactLandscape ? 16 : 18,
                        height: compactLandscape ? 16 : 18,
                        child: CircularProgressIndicator(
                          strokeWidth: compactLandscape ? 2.0 : 2.2,
                          color: searchAccent,
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: compactLandscape ? 11 : 14,
              ),
            ),
          ),
        ),
      ),
      SizedBox(width: compactLandscape ? 8 : 10),
      if (layout.showInlineSecondaryInfo)
        state._academyHudButton(
          palette: palette,
          icon: Icons.restart_alt_rounded,
          label: 'RESET STUDIED',
          accent: palette.signal,
          onTap: resetEnabled
              ? () => unawaited(state._showQuizStudyResetDialog())
              : null,
        )
      else
        Opacity(
          opacity: resetEnabled ? 1 : 0.45,
          child: _buildQuizStudyTopIconButton(
            state,
            palette: palette,
            icon: Icons.restart_alt_rounded,
            accent: palette.signal,
            tooltip: 'Reset studied openings',
            onTap: resetEnabled
                ? () => unawaited(state._showQuizStudyResetDialog())
                : () {},
          ),
        ),
    ],
  );
}

Widget _buildQuizStudyMissionPanel(
  _QuizScreen state, {
  required QuizDifficulty highestUnlocked,
  required _QuizAcademyPalette palette,
  required _QuizStudyLayoutSpec layout,
}) {
  final selectedColor = state._quizStudyCategoryColor(state._quizStudyCategory);
  final isLoading = !state._quizStudyDataReady() && state._ecoOpeningsLoading;
  final resetEnabled = state._quizStudyTotalReps() > 0;
  final selectedStudied = state._quizStudyCategoryStudiedCount(
    state._quizStudyCategory,
  );
  final selectedTotal = state._quizStudyCategoryTotalCount(
    state._quizStudyCategory,
  );
  final selectedFamilies = state
      ._quizStudyFamilyGroups(state._quizStudyCategory)
      .length;
  final selectedCompletion = state._quizStudyCategoryCompletion(
    state._quizStudyCategory,
  );

  return state._academyPixelPanel(
    panelKey: const ValueKey<String>('quiz_study_category_panel'),
    palette: palette,
    accent: selectedColor,
    fillColor: palette.panelAlt,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        state._academyPanelHeader(
          palette: palette,
          title: 'STUDY CATEGORIES',
          subtitle: '',
          infoTitle: 'Study categories',
          infoMessage: _quizStudyCategoryInfoMessage(state),
          infoButtonKey: const ValueKey<String>('quiz_study_category_info'),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (layout.showInlineSecondaryInfo) {
              final columns = constraints.maxWidth >= 1100
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              final cardWidth =
                  (constraints.maxWidth - ((columns - 1) * 12)) / columns;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: QuizStudyCategory.values
                    .map(
                      (category) => SizedBox(
                        width: cardWidth,
                        child: _buildQuizStudyCategoryCard(
                          state,
                          category,
                          palette: palette,
                          layout: layout,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            }

            if (layout.mode == _QuizStudyLayoutMode.phoneLandscape) {
              final columns = constraints.maxWidth >= 250 ? 2 : 1;
              final cardWidth =
                  (constraints.maxWidth - ((columns - 1) * 8)) / columns;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: QuizStudyCategory.values
                    .map(
                      (category) => SizedBox(
                        width: cardWidth,
                        child: _buildQuizStudyCategoryCard(
                          state,
                          category,
                          palette: palette,
                          layout: layout,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            }

            if (layout.mode == _QuizStudyLayoutMode.phonePortrait) {
              final columns = constraints.maxWidth >= 360 ? 2 : 1;
              final cardWidth =
                  (constraints.maxWidth - ((columns - 1) * 10)) / columns;

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
                          layout: layout,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        if (layout.mode == _QuizStudyLayoutMode.phoneLandscape) ...<Widget>[
          const SizedBox(height: 10),
          _buildQuizStudySearchControls(
            state,
            palette: palette,
            layout: layout,
            isLoading: isLoading,
            resetEnabled: resetEnabled,
          ),
        ],
        if (layout.showInlineSecondaryInfo) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            key: const ValueKey<String>('quiz_study_inline_category_stats'),
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _buildQuizStudySummaryChip(
                label: 'Selected',
                value: state._quizStudyCategoryLabel(state._quizStudyCategory),
                icon: state._quizStudyCategoryIcon(state._quizStudyCategory),
                accent: selectedColor,
                palette: palette,
              ),
              _buildQuizStudySummaryChip(
                label: 'Openings',
                value: '$selectedStudied/$selectedTotal',
                icon: Icons.menu_book_outlined,
                accent: palette.emerald,
                palette: palette,
              ),
              _buildQuizStudySummaryChip(
                label: 'Families',
                value: selectedFamilies.toString(),
                icon: Icons.account_tree_outlined,
                accent: palette.cyan,
                palette: palette,
              ),
              _buildQuizStudySummaryChip(
                label: 'Quiz ladder',
                value: state._quizAcademyBracketShortName(highestUnlocked),
                icon: Icons.workspace_premium_outlined,
                accent: palette.amber,
                palette: palette,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuizStudyMeter(
            state,
            palette: palette,
            label: 'SELECTED CATEGORY COMPLETION',
            valueLabel: '${(selectedCompletion * 100).toStringAsFixed(0)}%',
            value: selectedCompletion,
            accent: selectedColor,
          ),
        ],
      ],
    ),
  );
}

Widget _buildQuizStudyCategoryCard(
  _QuizScreen state,
  QuizStudyCategory category, {
  required _QuizAcademyPalette palette,
  required _QuizStudyLayoutSpec layout,
}) {
  final selected = state._quizStudyCategory == category;
  final accent = state._quizStudyCategoryColor(category);
  final compactLandscape =
      layout.mode == _QuizStudyLayoutMode.phoneLandscape && !layout.isTablet;
  final total = state._quizStudyCategoryTotalCount(category);
  final studied = state._quizStudyCategoryStudiedCount(category);
  final completion = state._quizStudyCategoryCompletion(category);
  final reps = state._quizStudyCategoryTotalReps(category);

  if (compactLandscape) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('quiz_study_category_${category.name}'),
        onTap: () => state._setQuizStudyCategory(category),
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                  alpha: selected ? 0.18 : 0.10,
                ),
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Icon(
                state._quizStudyCategoryIcon(category),
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state._quizStudyCategoryLabel(category).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: state._academyHudStyle(
                    palette: palette,
                    size: 10.9,
                    color: palette.text,
                    weight: FontWeight.w800,
                    letterSpacing: 0.45,
                    height: 1.0,
                  ),
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: 6),
                Icon(Icons.check_circle_rounded, size: 16, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }

  return Material(
    color: Colors.transparent,
    child: InkWell(
      key: ValueKey<String>('quiz_study_category_${category.name}'),
      onTap: () => state._setQuizStudyCategory(category),
      borderRadius: BorderRadius.circular(4),
      child: Ink(
        padding: EdgeInsets.all(layout.showInlineSecondaryInfo ? 14 : 12),
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
                  width: layout.showInlineSecondaryInfo ? 40 : 36,
                  height: layout.showInlineSecondaryInfo ? 40 : 36,
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
                                size: layout.showInlineSecondaryInfo ? 18 : 15,
                                color: palette.text,
                                weight: FontWeight.w700,
                                letterSpacing: layout.showInlineSecondaryInfo
                                    ? 0.8
                                    : 0.5,
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
                        maxLines: layout.showInlineSecondaryInfo ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: state._academyHudStyle(
                          palette: palette,
                          size: layout.showInlineSecondaryInfo ? 12.2 : 10.8,
                          color: palette.textMuted,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (layout.showInlineSecondaryInfo) ...<Widget>[
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
                label: selected ? 'ACTIVE CATEGORY' : 'CATEGORY COMPLETION',
                valueLabel: '${(completion * 100).toStringAsFixed(0)}%',
                value: completion,
                accent: accent,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _buildQuizStudyLibraryPanel(
  _QuizScreen state, {
  required _QuizAcademyPalette palette,
  required _QuizStudyLayoutSpec layout,
}) {
  final isLoading = !state._quizStudyDataReady() && state._ecoOpeningsLoading;
  final compactLandscape =
      layout.mode == _QuizStudyLayoutMode.phoneLandscape && !layout.isTablet;
  final groups = isLoading
      ? const <_QuizStudyFamilyGroup>[]
      : state._quizStudyFamilyGroups(state._quizStudyCategory);
  final searchActive = state._quizStudySearchQuery.trim().isNotEmpty;
  final searchAccent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final openingCount = groups.fold<int>(
    0,
    (sum, group) => sum + group.lines.length,
  );
  final studiedCount = groups.fold<int>(
    0,
    (sum, group) =>
        sum +
        group.lines
            .where((line) => state._quizStudyCountFor(line.name) > 0)
            .length,
  );

  final resetEnabled = state._quizStudyTotalReps() > 0;

  return KeyedSubtree(
    key: state._quizStudyLibraryIndexKey,
    child: state._academyPixelPanel(
      panelKey: const ValueKey<String>('quiz_study_browser_panel'),
      palette: palette,
      accent: palette.cyan,
      fillColor: palette.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          state._academyPanelHeader(
            palette: palette,
            title: 'OPENING BROWSER',
            subtitle: compactLandscape
                ? ''
                : 'Search families and open a line to study.',
            infoTitle: 'Opening browser',
            infoMessage: _quizStudyBrowserInfoMessage(
              state,
              familyCount: groups.length,
              openingCount: openingCount,
              studiedCount: studiedCount,
            ),
            infoButtonKey: const ValueKey<String>('quiz_study_browser_info'),
          ),
          if (layout.showInlineSecondaryInfo) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              key: const ValueKey<String>('quiz_study_inline_browser_stats'),
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _buildQuizStudySummaryChip(
                  label: 'Category',
                  value: state._quizStudyCategoryLabel(
                    state._quizStudyCategory,
                  ),
                  icon: state._quizStudyCategoryIcon(state._quizStudyCategory),
                  accent: searchAccent,
                  palette: palette,
                ),
                _buildQuizStudySummaryChip(
                  label: 'Families',
                  value: groups.length.toString(),
                  icon: Icons.account_tree_outlined,
                  accent: palette.cyan,
                  palette: palette,
                ),
                _buildQuizStudySummaryChip(
                  label: 'Openings',
                  value: openingCount.toString(),
                  icon: Icons.library_books_outlined,
                  accent: palette.amber,
                  palette: palette,
                ),
                _buildQuizStudySummaryChip(
                  label: 'Studied',
                  value: studiedCount.toString(),
                  icon: Icons.menu_book_outlined,
                  accent: palette.emerald,
                  palette: palette,
                ),
              ],
            ),
          ],
          if (!compactLandscape) ...<Widget>[
            const SizedBox(height: 12),
            _buildQuizStudySearchControls(
              state,
              palette: palette,
              layout: layout,
              isLoading: isLoading,
              resetEnabled: resetEnabled,
            ),
          ],
          SizedBox(height: compactLandscape ? 8 : 14),
          SizedBox(
            height: layout.browserHeight,
            child: _buildQuizStudyFamilyListPane(
              state,
              groups: groups,
              isLoading: isLoading,
              searchActive: searchActive,
              palette: palette,
              layout: layout,
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
  required _QuizStudyLayoutSpec layout,
}) {
  return Container(
    key: const ValueKey<String>('quiz_study_browser_list'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: palette.shell,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: palette.line, width: 2),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: palette.shadow.withValues(alpha: 0.16),
          offset: const Offset(4, 4),
          blurRadius: 0,
        ),
      ],
    ),
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
                  'Loading opening browser...',
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
                  : 'No openings are available in this category yet.',
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
                        state._quizStudyExpandedFamily == group.familyName;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildQuizStudyFamilyCard(
                        state,
                        group: group,
                        expanded: expanded,
                        searchActive: searchActive,
                        palette: palette,
                        layout: layout,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
  );
}

Widget _buildQuizStudyFamilyProgressRing(
  _QuizScreen state, {
  required String familyName,
  required _QuizAcademyPalette palette,
  required double value,
  required bool compact,
}) {
  final clampedValue = value.clamp(0.0, 1.0).toDouble();
  final size = compact ? 34.0 : 40.0;

  return Container(
    key: ValueKey<String>(
      'quiz_study_family_progress_${_quizStudyKeyToken(familyName)}',
    ),
    width: size,
    height: size,
    padding: EdgeInsets.all(compact ? 3 : 4),
    decoration: BoxDecoration(
      color: palette.shell,
      shape: BoxShape.circle,
      border: Border.all(color: palette.line, width: 2),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: palette.shadow.withValues(alpha: 0.14),
          offset: const Offset(3, 3),
          blurRadius: 0,
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CircularProgressIndicator(
          value: clampedValue,
          strokeWidth: compact ? 3 : 3.6,
          backgroundColor: palette.line.withValues(alpha: 0.6),
          valueColor: AlwaysStoppedAnimation<Color>(palette.emerald),
        ),
        Center(
          child: Text(
            '${(clampedValue * 100).round()}%',
            style: state._academyHudStyle(
              palette: palette,
              size: compact ? 7.0 : 8.0,
              color: palette.text,
              weight: FontWeight.w800,
              letterSpacing: compact ? 0.1 : 0.2,
              height: 1.0,
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
  required _QuizStudyLayoutSpec layout,
}) {
  final accent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final studiedCount = state._quizStudyFamilyStudiedCount(group);
  final studyProgress = group.lines.isEmpty
      ? 0.0
      : studiedCount / group.lines.length;
  final compactFamilyCard = !layout.showInlineSecondaryInfo;
  final hasStudiedLines = studiedCount > 0;
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
            key: ValueKey<String>(
              'quiz_study_family_${_quizStudyKeyToken(group.familyName)}',
            ),
            onTap: searchActive
                ? null
                : () => state._toggleQuizStudyFamily(group.familyName),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.all(compactFamilyCard ? 12 : 14),
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
                            size: compactFamilyCard ? 15 : 16,
                            color: palette.text,
                            weight: FontWeight.w700,
                            letterSpacing: compactFamilyCard ? 0.5 : 0.7,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          layout.showInlineSecondaryInfo
                              ? '${group.lines.length} opening${group.lines.length == 1 ? '' : 's'} • $studiedCount studied'
                              : hasStudiedLines
                              ? '$studiedCount of ${group.lines.length} studied'
                              : familyHasSelection
                              ? 'Current opening family'
                              : searchActive
                              ? 'Matching family'
                              : 'Tap to see saved openings',
                          style: state._academyHudStyle(
                            palette: palette,
                            size: compactFamilyCard ? 11.4 : 12.2,
                            color: palette.textMuted,
                            weight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        if (layout.showInlineSecondaryInfo) ...<Widget>[
                          const SizedBox(height: 10),
                          _buildQuizStudyMeter(
                            state,
                            palette: palette,
                            label: 'FAMILY PROGRESS',
                            valueLabel:
                                '${(studyProgress * 100).toStringAsFixed(0)}%',
                            value: studyProgress,
                            accent: frameAccent,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildQuizStudyFamilyProgressRing(
                        state,
                        familyName: group.familyName,
                        palette: palette,
                        value: studyProgress,
                        compact: compactFamilyCard,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: frameAccent,
                      ),
                    ],
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
                    layout: layout,
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
  required _QuizAcademyPalette palette,
  required _QuizStudyLayoutSpec layout,
}) {
  final accent = state._quizStudyCategoryColor(state._quizStudyCategory);
  final selected = state._quizStudySelectedOpeningName == line.name;
  final studyCount = state._quizStudyCountFor(line.name);
  final variationLabel = state._quizStudyVariationLabel(line, familyName);

  final tile = Material(
    color: Colors.transparent,
    child: InkWell(
      key: ValueKey<String>(
        'quiz_study_variation_${_quizStudyKeyToken(line.name)}',
      ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                      if (layout.showInlineSecondaryInfo &&
                          variationLabel != line.name) ...<Widget>[
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
                    ],
                  ),
                ),
                if (!layout.showInlineSecondaryInfo) ...<Widget>[
                  const SizedBox(width: 8),
                  state._buildQuizInfoButton(
                    buttonKey: ValueKey<String>(
                      'quiz_study_variation_info_${_quizStudyKeyToken(line.name)}',
                    ),
                    title: 'Opening details',
                    message: _quizStudyLineInfoMessage(
                      state,
                      line: line,
                      familyName: familyName,
                      variationLabel: variationLabel,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: palette.textMuted),
              ],
            ),
            if (layout.showInlineSecondaryInfo) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  state._buildQuizAcademyMetricChip(
                    palette: palette,
                    label: 'MOVES',
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
                    label: selected ? 'OPEN NOW' : 'OPEN',
                    accent: selected ? accent : palette.emerald,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );

  if (selected) {
    return KeyedSubtree(key: state._quizStudyLibrarySelectionKey, child: tile);
  }

  return tile;
}

Widget _buildQuizStudyDetailHeaderPanel(
  _QuizScreen state, {
  required EcoLine selectedLine,
  required String familyName,
  required String variationLabel,
  required int studyCount,
  required _QuizAcademyPalette palette,
  required Color accent,
  required _QuizStudyLayoutSpec layout,
}) {
  return state._academyPixelPanel(
    panelKey: const ValueKey<String>('quiz_study_detail_header_panel'),
    palette: palette,
    accent: accent,
    fillColor: palette.panelAlt,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        state._academyPanelHeader(
          palette: palette,
          title: variationLabel,
          subtitle:
              '$familyName • ${state._quizStudyCategoryLabel(state._quizStudyCategory)}',
          infoTitle: 'Opening details',
          infoMessage: _quizStudyLineInfoMessage(
            state,
            line: selectedLine,
            familyName: familyName,
            variationLabel: variationLabel,
          ),
          infoButtonKey: const ValueKey<String>('quiz_study_detail_info'),
        ),
        if (layout.showInlineSecondaryInfo) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            key: const ValueKey<String>('quiz_study_inline_detail_stats'),
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _buildQuizStudySummaryChip(
                label: 'Family',
                value: familyName,
                icon: Icons.account_tree_outlined,
                accent: palette.cyan,
                palette: palette,
              ),
              _buildQuizStudySummaryChip(
                label: 'Category',
                value: state._quizStudyCategoryLabel(state._quizStudyCategory),
                icon: state._quizStudyCategoryIcon(state._quizStudyCategory),
                accent: accent,
                palette: palette,
              ),
              _buildQuizStudySummaryChip(
                label: 'Moves',
                value: selectedLine.moveTokens.length.toString(),
                icon: Icons.route_outlined,
                accent: palette.amber,
                palette: palette,
              ),
              _buildQuizStudySummaryChip(
                label: 'Studied',
                value: '${studyCount}x',
                icon: Icons.menu_book_outlined,
                accent: palette.emerald,
                palette: palette,
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _buildQuizStudyDetailScreen(
  _QuizScreen state, {
  required EcoLine selectedLine,
  required _QuizAcademyPalette palette,
  required _QuizStudyLayoutSpec layout,
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
  final detailHeader = _buildQuizStudyDetailHeaderPanel(
    state,
    selectedLine: selectedLine,
    familyName: familyName,
    variationLabel: variationLabel,
    studyCount: studyCount,
    palette: palette,
    accent: accent,
    layout: layout,
  );
  final navigatorPanel = _buildQuizStudyFamilyNavigatorPanel(
    state,
    selectedLine: selectedLine,
    familyName: familyName,
    familyLines: familyLines,
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

  return Column(
    children: <Widget>[
      detailHeader,
      SizedBox(height: layout.sectionGap),
      if (layout.isTablet)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 6, child: boardPanel),
            SizedBox(width: layout.sectionGap),
            Expanded(flex: 5, child: navigatorPanel),
          ],
        )
      else ...<Widget>[
        boardPanel,
        SizedBox(height: layout.sectionGap),
        navigatorPanel,
      ],
      if (layout.showInlineSecondaryInfo) ...<Widget>[
        SizedBox(height: layout.sectionGap),
        _buildQuizStudyStoredLinePanel(
          state,
          selectedLine: selectedLine,
          preview: preview,
          variationLabel: variationLabel,
          palette: palette,
          accent: accent,
          boardMaxWidth: boardMaxWidth,
        ),
      ],
    ],
  );
}

Widget _buildQuizStudyFamilyNavigatorPanel(
  _QuizScreen state, {
  required EcoLine selectedLine,
  required String familyName,
  required List<EcoLine> familyLines,
  required _QuizAcademyPalette palette,
  required Color accent,
}) {
  return state._academyPixelPanel(
    panelKey: const ValueKey<String>('quiz_study_detail_navigator_panel'),
    palette: palette,
    accent: accent,
    fillColor: palette.panelAlt,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        state._academyPanelHeader(
          palette: palette,
          title: 'VARIATIONS',
          subtitle: familyLines.length > 1
              ? 'Switch lines without leaving $familyName.'
              : 'This family currently stores one line in this category.',
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
              'No other saved line is grouped with this opening in ${state._quizStudyCategoryLabel(state._quizStudyCategory).toLowerCase()}.',
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
      'This opening could not be replayed into a clean preview board, but the stored line is still available in Opening Details.';

  return KeyedSubtree(
    key: state._quizStudyBoardKey,
    child: state._academyPixelPanel(
      panelKey: const ValueKey<String>('quiz_study_detail_board_panel'),
      palette: palette,
      accent: palette.cyan,
      fillColor: palette.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          state._academyPanelHeader(
            palette: palette,
            title: 'BOARD',
            subtitle: 'Replay the selected line move by move.',
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
    panelKey: const ValueKey<String>('quiz_study_detail_inline_info_panel'),
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
                          'OPENING DETAILS',
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
                              ? 'Stored notation and board status for $variationLabel. Tap to close this panel.'
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
