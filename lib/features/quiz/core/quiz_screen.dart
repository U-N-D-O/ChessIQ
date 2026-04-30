part of '../../analysis/screens/chess_analysis_page.dart';

class _QuizStudyFamilyGroup {
  final String familyName;
  final List<EcoLine> lines;

  const _QuizStudyFamilyGroup({required this.familyName, required this.lines});
}

class _QuizStudyPreview {
  final Map<String, String> boardState;
  final bool whiteToMove;
  final int shownPly;
  final int totalPly;
  final List<EngineLine> continuation;

  const _QuizStudyPreview({
    required this.boardState,
    required this.whiteToMove,
    required this.shownPly,
    required this.totalPly,
    required this.continuation,
  });
}

const String _quizAcademyDisplayFontFamily = 'PixelatedElegance';
const String _quizAcademyHudFontFamily = 'PixelatedElegance';

class _QuizAcademyPalette {
  const _QuizAcademyPalette({
    required this.backdrop,
    required this.shell,
    required this.panel,
    required this.panelAlt,
    required this.line,
    required this.shadow,
    required this.text,
    required this.textMuted,
    required this.cyan,
    required this.amber,
    required this.emerald,
    required this.signal,
    required this.boardDark,
    required this.boardLight,
  });

  final Color backdrop;
  final Color shell;
  final Color panel;
  final Color panelAlt;
  final Color line;
  final Color shadow;
  final Color text;
  final Color textMuted;
  final Color cyan;
  final Color amber;
  final Color emerald;
  final Color signal;
  final Color boardDark;
  final Color boardLight;
}

class _QuizAcademySetupLayoutSpec {
  const _QuizAcademySetupLayoutSpec({
    required this.isLandscape,
    required this.compactLandscape,
    required this.compactPortrait,
    required this.tightPortrait,
    required this.compactPhoneLayout,
    required this.contentMaxWidth,
    required this.outerHorizontalPadding,
    required this.outerTopPadding,
    required this.outerBottomPadding,
    required this.sectionGap,
    required this.panelPadding,
  });

  factory _QuizAcademySetupLayoutSpec.fromMedia(MediaQueryData media) {
    final safeHeight = media.size.height - media.viewPadding.vertical;
    final isLandscape = media.orientation == Orientation.landscape;
    final compactLandscape = isLandscape && safeHeight <= 430;
    final compactPortrait = !isLandscape && safeHeight <= 780;
    final tightPortrait = !isLandscape && media.size.width <= 390;
    final compactPhoneLayout =
        compactLandscape || compactPortrait || media.size.width <= 430;

    return _QuizAcademySetupLayoutSpec(
      isLandscape: isLandscape,
      compactLandscape: compactLandscape,
      compactPortrait: compactPortrait,
      tightPortrait: tightPortrait,
      compactPhoneLayout: compactPhoneLayout,
      contentMaxWidth: isLandscape ? 1180.0 : 760.0,
      outerHorizontalPadding: compactPhoneLayout ? 12.0 : 16.0,
      outerTopPadding: compactLandscape ? 10.0 : 12.0,
      outerBottomPadding: compactLandscape ? 12.0 : 18.0,
      sectionGap: compactPhoneLayout ? 12.0 : 18.0,
      panelPadding: compactPhoneLayout ? 14.0 : 16.0,
    );
  }

  final bool isLandscape;
  final bool compactLandscape;
  final bool compactPortrait;
  final bool tightPortrait;
  final bool compactPhoneLayout;
  final double contentMaxWidth;
  final double outerHorizontalPadding;
  final double outerTopPadding;
  final double outerBottomPadding;
  final double sectionGap;
  final double panelPadding;
}

EdgeInsets _quizAcademyViewportPadding(MediaQueryData media) {
  return media.orientation == Orientation.portrait
      ? EdgeInsets.zero
      : media.padding;
}

class _QuizAcademyBackdropPainter extends CustomPainter {
  const _QuizAcademyBackdropPainter({
    required this.palette,
    required this.phase,
  });

  final _QuizAcademyPalette palette;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = palette.line.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    const cellSize = 28.0;
    final yShift = (phase * 10) % cellSize;

    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = -cellSize + yShift; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final scanPaint = Paint()..color = palette.text.withValues(alpha: 0.035);
    for (double y = 0; y <= size.height; y += 10) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scanPaint);
    }

    final starPaint = Paint()..color = palette.cyan.withValues(alpha: 0.24);
    final sparklePaint = Paint()..color = palette.amber.withValues(alpha: 0.18);
    for (var index = 0; index < 22; index++) {
      final progress = ((index * 0.11) + phase * 0.015) % 1.0;
      final x = size.width * ((index * 37 % 100) / 100);
      final y = size.height * (0.08 + progress * 0.48);
      final starSize = index.isEven ? 3.0 : 2.0;
      canvas.drawRect(
        Rect.fromLTWH(x, y, starSize, starSize),
        index % 3 == 0 ? sparklePaint : starPaint,
      );
    }

    final floorRect = Rect.fromLTWH(
      0,
      size.height * 0.72,
      size.width,
      size.height * 0.28,
    );
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = ui.Gradient.linear(
          floorRect.topCenter,
          floorRect.bottomCenter,
          <Color>[
            palette.boardDark.withValues(alpha: 0.04),
            palette.boardDark.withValues(alpha: 0.22),
          ],
        ),
    );

    final beamPaint = Paint()
      ..color = palette.boardLight.withValues(alpha: 0.14);
    for (var index = 0; index < 9; index++) {
      final progress = index / 8;
      final topY = size.height * 0.72;
      final bottomY = size.height;
      final centerX = size.width * progress;
      final halfSpreadTop = size.width * 0.02;
      final halfSpreadBottom = size.width * (0.06 + progress * 0.06);
      final path = Path()
        ..moveTo(centerX - halfSpreadTop, topY)
        ..lineTo(centerX + halfSpreadTop, topY)
        ..lineTo(centerX + halfSpreadBottom, bottomY)
        ..lineTo(centerX - halfSpreadBottom, bottomY)
        ..close();
      canvas.drawPath(path, beamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuizAcademyBackdropPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.palette != palette;
  }
}

class _QuizAcademySetupGlowPainter extends CustomPainter {
  const _QuizAcademySetupGlowPainter({
    required this.palette,
    required this.phase,
    required this.reducedEffects,
  });

  final _QuizAcademyPalette palette;
  final double phase;
  final bool reducedEffects;

  @override
  void paint(Canvas canvas, Size size) {
    final motionPhase = reducedEffects ? 0.0 : phase * pi * 2;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.08, 0),
          Offset(size.width * 0.92, size.height),
          <Color>[
            palette.cyan.withValues(alpha: 0.035),
            palette.amber.withValues(alpha: 0.018),
            palette.emerald.withValues(alpha: 0.045),
          ],
          <double>[0.0, 0.48, 1.0],
        ),
    );

    void drawAura({
      required double alignmentX,
      required double alignmentY,
      required double radiusFactor,
      required double xAmplitude,
      required double yAmplitude,
      required double speed,
      required double offset,
      required Color color,
    }) {
      final center = Offset(
        size.width * alignmentX +
            sin((motionPhase * speed) + offset) * size.width * xAmplitude,
        size.height * alignmentY +
            cos((motionPhase * speed * 0.82) + offset) *
                size.height *
                yAmplitude,
      );
      final radius = size.shortestSide * radiusFactor;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            radius,
            <Color>[
              color,
              color.withValues(alpha: color.a * 0.42),
              color.withValues(alpha: 0.0),
            ],
            <double>[0.0, 0.55, 1.0],
          ),
      );
    }

    drawAura(
      alignmentX: 0.14,
      alignmentY: 0.18,
      radiusFactor: 0.34,
      xAmplitude: 0.018,
      yAmplitude: 0.012,
      speed: 0.18,
      offset: 0.4,
      color: palette.cyan.withValues(alpha: 0.12),
    );
    drawAura(
      alignmentX: 0.82,
      alignmentY: 0.16,
      radiusFactor: 0.30,
      xAmplitude: 0.015,
      yAmplitude: 0.014,
      speed: 0.16,
      offset: 1.8,
      color: palette.amber.withValues(alpha: 0.10),
    );
    drawAura(
      alignmentX: 0.56,
      alignmentY: 0.74,
      radiusFactor: 0.42,
      xAmplitude: 0.02,
      yAmplitude: 0.01,
      speed: 0.12,
      offset: 3.2,
      color: palette.emerald.withValues(alpha: 0.08),
    );

    final cloudPaints = <Paint>[
      Paint()..color = palette.cyan.withValues(alpha: 0.055),
      Paint()..color = palette.amber.withValues(alpha: 0.045),
      Paint()..color = palette.text.withValues(alpha: 0.04),
    ];
    for (var index = 0; index < 7; index++) {
      final drift = sin((motionPhase * 0.15) + (index * 0.9)) * 10;
      final top = size.height * (0.12 + ((index % 4) * 0.12));
      final left = size.width * (0.06 + ((index * 0.14) % 0.82)) + drift;
      final width = size.width * (index.isEven ? 0.16 : 0.11);
      final height = index % 3 == 0 ? 14.0 : 10.0;
      final rect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        cloudPaints[index % cloudPaints.length],
      );
    }

    final chipPaint = Paint()..color = palette.text.withValues(alpha: 0.075);
    final sparkPaint = Paint()
      ..color = palette.boardLight.withValues(alpha: 0.08);
    for (var index = 0; index < 16; index++) {
      final baseX = size.width * ((index * 17 % 100) / 100);
      final baseY = size.height * (0.10 + ((index * 13 % 55) / 100));
      final driftX = sin((motionPhase * 0.10) + index) * 4;
      final driftY = cos((motionPhase * 0.08) + index) * 3;
      final chipSize = index % 4 == 0 ? 4.0 : 3.0;
      final rect = Rect.fromLTWH(
        baseX + driftX,
        baseY + driftY,
        chipSize,
        chipSize,
      );
      canvas.drawRect(rect, index.isEven ? chipPaint : sparkPaint);
    }

    final floorGlow = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.70,
      size.width * 0.88,
      size.height * 0.20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(floorGlow, const Radius.circular(40)),
      Paint()
        ..shader = ui.Gradient.linear(
          floorGlow.topCenter,
          floorGlow.bottomCenter,
          <Color>[
            palette.boardLight.withValues(alpha: 0.0),
            palette.boardLight.withValues(alpha: 0.05),
            palette.boardDark.withValues(alpha: 0.10),
          ],
          <double>[0.0, 0.42, 1.0],
        ),
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          <Color>[
            Colors.transparent,
            palette.shell.withValues(alpha: 0.03),
            palette.backdrop.withValues(alpha: 0.12),
          ],
          <double>[0.0, 0.72, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _QuizAcademySetupGlowPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.palette != palette ||
        oldDelegate.reducedEffects != reducedEffects;
  }
}

abstract class _QuizScreen extends _AnalysisPageShared {
  final GlobalKey _quizAcademyModePanelFocusKey = GlobalKey();
  final GlobalKey _quizStudyBoardKey = GlobalKey();
  final GlobalKey _quizStudyLibraryIndexKey = GlobalKey();
  final GlobalKey _quizStudyLibrarySelectionKey = GlobalKey();

  void _focusQuizAcademyModePanel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _quizAcademyModePanelFocusKey.currentContext;
      if (targetContext == null) return;

      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          alignment: 0.0,
        ),
      );
    });
  }

  void _focusQuizStudyBoard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _quizStudyBoardKey.currentContext;
      if (targetContext == null) return;

      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.02,
        ),
      );
    });
  }

  void _focusQuizStudyLibrarySelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _quizStudyLibrarySelectionKey.currentContext;
      if (targetContext == null) return;

      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          alignment: 0.16,
        ),
      );
    });
  }

  void _focusQuizStudyLibraryIndex({bool focusSelection = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final indexContext = _quizStudyLibraryIndexKey.currentContext;
      if (indexContext != null) {
        await Scrollable.ensureVisible(
          indexContext,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          alignment: 0.04,
        );
      }

      if (!focusSelection || !mounted) {
        return;
      }

      _focusQuizStudyLibrarySelection();
    });
  }

  @override
  void _loadQuizPrefs(SharedPreferences prefs) {
    final viewed = prefs.getStringList(_viewedGambitsKey) ?? const <String>[];
    _viewedGambits
      ..clear()
      ..addAll(viewed);

    final rawQuizStats = prefs.getString(_quizStatsKey);
    if (rawQuizStats == null || rawQuizStats.isEmpty) {
      return;
    }

    final decoded = jsonDecode(rawQuizStats);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final difficultyIndex = decoded['difficulty'];
    if (difficultyIndex is int &&
        difficultyIndex >= 0 &&
        difficultyIndex < QuizDifficulty.values.length) {
      _quizDifficulty = QuizDifficulty.values[difficultyIndex];
    }

    final studyCategoryIndex = decoded['studyCategory'];
    if (studyCategoryIndex is int &&
        studyCategoryIndex >= 0 &&
        studyCategoryIndex < QuizStudyCategory.values.length) {
      _quizStudyCategory = QuizStudyCategory.values[studyCategoryIndex];
    }

    final studyCounts = decoded['studyCounts'];
    if (studyCounts is Map) {
      _quizStudyOpeningCounts = studyCounts.map(
        (k, v) => MapEntry(k.toString(), v is num ? max(0, v.toInt()) : 0),
      );
    }

    final bestStreak = decoded['bestStreak'];
    final streak = decoded['streak'];
    final totalAnswered = decoded['totalAnswered'];
    final correctAnswers = decoded['correctAnswers'];
    final score = decoded['score'];

    if (streak is int) _quizStreak = max(0, streak);
    if (bestStreak is int) _quizBestStreak = max(0, bestStreak);
    if (totalAnswered is int) _quizTotalAnswered = max(0, totalAnswered);
    if (correctAnswers is int) {
      _quizCorrectAnswers = max(0, correctAnswers);
    }
    if (score is int) _quizScore = max(0, score);

    final daily = decoded['dailyScore'];
    if (daily is Map<String, dynamic>) {
      _quizDailyScore = daily.map(
        (k, v) => MapEntry(k, v is int ? max(0, v) : 0),
      );
    }

    final dailyAttempts = decoded['dailyAttempts'];
    if (dailyAttempts is Map<String, dynamic>) {
      _quizDailyAttempts = dailyAttempts.map(
        (k, v) => MapEntry(k, v is int ? max(0, v) : 0),
      );
    }

    final dailyCorrect = decoded['dailyCorrect'];
    if (dailyCorrect is Map<String, dynamic>) {
      _quizDailyCorrectByDay = dailyCorrect.map(
        (k, v) => MapEntry(k, v is int ? max(0, v) : 0),
      );
    }

    final nameAttempts = decoded['nameDailyAttempts'];
    if (nameAttempts is Map<String, dynamic>) {
      _quizNameDailyAttempts = nameAttempts.map(
        (k, v) => MapEntry(k, v is int ? max(0, v) : 0),
      );
    }

    final nameCorrect = decoded['nameDailyCorrect'];
    if (nameCorrect is Map<String, dynamic>) {
      _quizNameDailyCorrect = nameCorrect.map(
        (k, v) => MapEntry(k, v is int ? max(0, v) : 0),
      );
    }

    final lineAttempts = decoded['lineDailyAttempts'];
    if (lineAttempts is Map<String, dynamic>) {
      _quizLineDailyAttempts = lineAttempts.map(
        (k, v) => MapEntry(k, v is int ? max(0, v) : 0),
      );
    }

    final lineCorrect = decoded['lineDailyCorrect'];
    if (lineCorrect is Map<String, dynamic>) {
      _quizLineDailyCorrect = lineCorrect.map(
        (k, v) => MapEntry(k, v is int ? max(0, v) : 0),
      );
    }

    final questionsAsked = decoded['dailyQuestionsAsked'];
    if (questionsAsked is Map<String, dynamic>) {
      _quizDailyQuestionsAsked = questionsAsked.map(
        (k, v) => MapEntry(k, v is int ? max(0, v) : 0),
      );
    }

    void loadDiffMap(String key, void Function(Map<String, int>) setter) {
      final raw = decoded[key];
      if (raw is Map<String, dynamic>) {
        setter(raw.map((k, v) => MapEntry(k, v is int ? max(0, v) : 0)));
      }
    }

    loadDiffMap('easyDailyAttempts', (m) => _quizEasyDailyAttempts = m);
    loadDiffMap('easyDailyCorrect', (m) => _quizEasyDailyCorrect = m);
    loadDiffMap('mediumDailyAttempts', (m) => _quizMediumDailyAttempts = m);
    loadDiffMap('mediumDailyCorrect', (m) => _quizMediumDailyCorrect = m);
    loadDiffMap('hardDailyAttempts', (m) => _quizHardDailyAttempts = m);
    loadDiffMap('hardDailyCorrect', (m) => _quizHardDailyCorrect = m);
    loadDiffMap('veryHardDailyAttempts', (m) => _quizVeryHardDailyAttempts = m);
    loadDiffMap('veryHardDailyCorrect', (m) => _quizVeryHardDailyCorrect = m);

    final academyProgress = decoded['academyProgress'];
    if (academyProgress is Map) {
      _quizAcademyProgress = QuizAcademyProgress.fromMap(academyProgress);
    } else {
      _quizAcademyProgress = QuizAcademyProgress.initial();
    }

    _syncQuizDifficultyToAcademyProgress();
  }

  double _openingPopularityScore(String name) {
    final lower = name.toLowerCase();
    if (_anyKeyword(lower, const [
      'sicilian',
      'ruy lopez',
      'spanish game',
      'berlin defense',
      'berlin defence',
      'french defense',
      'french defence',
      'italian game',
      'giuoco piano',
      "queen's gambit",
      "king's indian",
      'caro-kann',
      'caro kann',
      'english opening',
      'nimzo-indian',
      'nimzo indian',
      'london system',
      'petroff',
      'petrov',
      'vienna game',
      'vienna gambit',
    ])) {
      return 0.92;
    }
    if (_anyKeyword(lower, const [
      'slav',
      'dutch',
      "queen's indian",
      'scotch game',
      'scotch gambit',
      "king's gambit",
      'grünfeld',
      'grunfeld',
      'pirc',
      'modern defense',
      'modern defence',
      'four knights',
      'catalan',
      'bogo-indian',
      'bogo indian',
      'semi-slav',
      'ponziani',
      'réti',
      'colle',
      'stonewall',
      'alapin',
      'smith-morra',
      'max lange',
      'evans gambit',
      'four knights',
    ])) {
      return 0.70;
    }
    if (_anyKeyword(lower, const [
      'alekhine',
      'benoni',
      'budapest',
      'bird',
      'scandinavian',
      'nimzowitsch',
      'nimzovich',
      'torre',
      'trompowsky',
      'benko',
      'polish',
      'hungarian',
      'latvian',
      'danish',
      'from gambit',
      'bowdler',
      'philidor',
      'owen',
      'blackmar',
      'jerome gambit',
      'center game',
    ])) {
      return 0.50;
    }
    return 0.25;
  }

  bool _anyKeyword(String lower, List<String> kws) {
    for (final kw in kws) {
      if (lower.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  bool _openingPassesDifficultyFilter(double score, QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return score >= 0.86;
      case QuizDifficulty.medium:
        return score >= 0.65 && score < 0.86;
      case QuizDifficulty.hard:
        return score >= 0.45 && score < 0.65;
      case QuizDifficulty.veryHard:
        return score < 0.45;
    }
  }

  QuizStudyCategory _quizStudyCategoryForDifficulty(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return QuizStudyCategory.basic;
      case QuizDifficulty.medium:
        return QuizStudyCategory.advanced;
      case QuizDifficulty.hard:
        return QuizStudyCategory.master;
      case QuizDifficulty.veryHard:
        return QuizStudyCategory.grandmaster;
    }
  }

  String _quizStudyPoolKey(QuizStudyCategory category) {
    return 'study:${category.name}';
  }

  String _quizStudyCategoryLabel(QuizStudyCategory category) {
    switch (category) {
      case QuizStudyCategory.basic:
        return 'Basic';
      case QuizStudyCategory.advanced:
        return 'Advanced';
      case QuizStudyCategory.master:
        return 'Master';
      case QuizStudyCategory.grandmaster:
        return 'Grandmaster';
      case QuizStudyCategory.library:
        return 'Library';
    }
  }

  String _quizStudyCategorySubtitle(QuizStudyCategory category) {
    switch (category) {
      case QuizStudyCategory.basic:
        return 'Easy study category';
      case QuizStudyCategory.advanced:
        return 'Medium study category';
      case QuizStudyCategory.master:
        return 'Hard study category';
      case QuizStudyCategory.grandmaster:
        return 'Very hard study category';
      case QuizStudyCategory.library:
        return 'Full opening library';
    }
  }

  Color _quizStudyCategoryColor(QuizStudyCategory category) {
    switch (category) {
      case QuizStudyCategory.basic:
        return _quizDifficultyColor(QuizDifficulty.easy);
      case QuizStudyCategory.advanced:
        return _quizDifficultyColor(QuizDifficulty.medium);
      case QuizStudyCategory.master:
        return _quizDifficultyColor(QuizDifficulty.hard);
      case QuizStudyCategory.grandmaster:
        return _quizDifficultyColor(QuizDifficulty.veryHard);
      case QuizStudyCategory.library:
        return const Color(0xFF5AAEE8);
    }
  }

  IconData _quizStudyCategoryIcon(QuizStudyCategory category) {
    switch (category) {
      case QuizStudyCategory.basic:
        return Icons.school_outlined;
      case QuizStudyCategory.advanced:
        return Icons.auto_stories_outlined;
      case QuizStudyCategory.master:
        return Icons.workspace_premium_outlined;
      case QuizStudyCategory.grandmaster:
        return Icons.psychology_alt_outlined;
      case QuizStudyCategory.library:
        return Icons.library_books_outlined;
    }
  }

  String _quizStudyFamilyCandidate(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      return 'Unnamed Opening';
    }

    final normalizedName = cleaned.replaceAll(RegExp(r'[–—]+'), '-');
    var splitIndex = -1;
    for (final delimiter in const [':', ',', ';', '(', ' - ']) {
      final delimiterIndex = normalizedName.indexOf(delimiter);
      if (delimiterIndex > 0 &&
          (splitIndex < 0 || delimiterIndex < splitIndex)) {
        splitIndex = delimiterIndex;
      }
    }

    final family = splitIndex > 0
        ? normalizedName.substring(0, splitIndex).trim()
        : normalizedName;

    final tokens = family
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return cleaned;
    }

    const familyTerms = <String>{
      'gambit',
      'defense',
      'defence',
      'opening',
      'openings',
      'game',
      'attack',
      'system',
      'countergambit',
      'counter-gambit',
    };

    var familyEndIndex = -1;
    for (var index = 0; index < tokens.length; index++) {
      final normalizedToken = tokens[index].toLowerCase().replaceAll(
        RegExp(r'[^a-z\-]'),
        '',
      );
      if (familyTerms.contains(normalizedToken)) {
        familyEndIndex = index;
      }
    }

    if (familyEndIndex >= 0) {
      return tokens.take(familyEndIndex + 1).join(' ');
    }

    return family;
  }

  String _quizStudyCanonicalizeFamily(String family) {
    var display = family.trim();
    if (display.isEmpty) {
      return 'Unnamed Opening';
    }

    display = display
        .replaceAll(RegExp(r'[’`´]'), "'")
        .replaceAll(RegExp(r'[–—]+'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    display = display
        .replaceAll(RegExp(r'\bDefence\b'), 'Defense')
        .replaceAll(RegExp(r'\bdefence\b'), 'defense')
        .replaceAll(RegExp(r'\bOpenings\b'), 'Opening')
        .replaceAll(RegExp(r'\bopenings\b'), 'opening')
        .replaceAll(RegExp(r"\bPetroff's\b"), "Petrov's")
        .replaceAll(RegExp(r'\bPetroff\b'), 'Petrov')
        .replaceAll(RegExp(r"\bpetroff's\b"), "petrov's")
        .replaceAll(RegExp(r'\bpetroff\b'), 'petrov');

    final normalized = display
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final aliasKey = normalized
        .replaceAll("'", '')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (aliasKey == 'sicilian defense') {
      return 'Sicilian Defense';
    }
    if (aliasKey == 'sicilian' ||
        aliasKey.startsWith('sicilian ') ||
        aliasKey.endsWith(' sicilian')) {
      return 'Sicilian';
    }
    if ({'english', 'english opening'}.contains(aliasKey)) {
      return 'English Opening';
    }
    if ({
      'queen pawn',
      'queens pawn',
      'queen pawn game',
      'queens pawn game',
      'queen pawn opening',
      'queens pawn opening',
    }.contains(aliasKey)) {
      return "Queen's Pawn Game";
    }
    if ({
      'king pawn',
      'kings pawn',
      'king pawn game',
      'kings pawn game',
      'king pawn opening',
      'kings pawn opening',
    }.contains(aliasKey)) {
      return "King's Pawn Game";
    }
    if ({
      'petrov',
      'petrov defense',
      'petrovs defense',
      'russian defense',
      'russian game',
    }.contains(aliasKey)) {
      return 'Petrov Defense';
    }
    if ({
      'caro kann',
      'caro kann defense',
      'caro kann defensive system',
    }.contains(aliasKey)) {
      return 'Caro-Kann Defense';
    }
    if ({'nimzo indian', 'nimzo indian defense'}.contains(aliasKey)) {
      return 'Nimzo-Indian Defense';
    }
    if ({'bogo indian', 'bogo indian defense'}.contains(aliasKey)) {
      return 'Bogo-Indian Defense';
    }
    if ({'queens indian', 'queens indian defense'}.contains(aliasKey)) {
      return "Queen's Indian Defense";
    }
    if ({'kings indian', 'kings indian defense'}.contains(aliasKey)) {
      return "King's Indian Defense";
    }

    return display;
  }

  String _quizStudyCanonicalFamilyKey(String family) {
    return _quizStudyCanonicalizeFamily(family).toLowerCase();
  }

  bool _quizStudyIsSystemFamily(String familyName) {
    final normalized = _quizStudyCanonicalFamilyKey(
      familyName,
    ).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    return normalized.contains('system') || normalized.contains('formation');
  }

  String _quizStudyBaseLabel(String familyName) {
    return _quizStudyIsSystemFamily(familyName) ? 'System' : 'Parent Opening';
  }

  String _quizStudyBaseLabelLower(String familyName) {
    return _quizStudyBaseLabel(familyName).toLowerCase();
  }

  String _quizStudyDisplayLineLabel(String label) {
    return label
        .replaceAll(
          RegExp(r'\bMain\s+Lines\b', caseSensitive: false),
          'Mainlines',
        )
        .replaceAll(
          RegExp(r'\bMain\s+Line\b', caseSensitive: false),
          'Mainline',
        );
  }

  String _quizStudyFamilyName(String name) {
    return _quizStudyCanonicalizeFamily(_quizStudyFamilyCandidate(name));
  }

  String? _quizStudyDerivedVariationLabel(String name, String familyName) {
    final cleaned = name.trim();
    final lower = cleaned.toLowerCase();

    if (familyName == 'Sicilian') {
      if (lower.startsWith('sicilian ') &&
          !lower.startsWith('sicilian defense')) {
        final remainder = cleaned.substring('Sicilian '.length).trim();
        if (remainder.isNotEmpty) {
          return remainder;
        }
      }
      if (lower.endsWith(' sicilian') && lower != 'sicilian') {
        final remainder = cleaned
            .substring(0, cleaned.length - ' Sicilian'.length)
            .trim();
        if (remainder.isNotEmpty) {
          return remainder;
        }
      }
    }

    return null;
  }

  String _quizStudyVariationLabel(EcoLine line, String familyName) {
    final cleanedName = line.name.trim();
    final rawFamily = _quizStudyFamilyCandidate(cleanedName);
    final canonicalFamily = _quizStudyCanonicalizeFamily(rawFamily);
    final derivedVariation = _quizStudyDerivedVariationLabel(
      cleanedName,
      familyName,
    );
    if (derivedVariation != null) {
      return derivedVariation;
    }

    if (cleanedName == familyName ||
        (_quizStudyCanonicalFamilyKey(rawFamily) ==
                _quizStudyCanonicalFamilyKey(familyName) &&
            cleanedName == rawFamily)) {
      return 'Mainline';
    }

    final familyPrefixes = <String>{familyName, rawFamily, canonicalFamily}
        .where((prefix) => prefix.trim().isNotEmpty)
        .expand(
          (prefix) => <String>[
            '$prefix: ',
            '$prefix, ',
            '$prefix - ',
            '$prefix ',
          ],
        );

    for (final prefix in familyPrefixes) {
      if (cleanedName.startsWith(prefix)) {
        final remainder = cleanedName.substring(prefix.length).trim();
        if (remainder.isNotEmpty) {
          return _quizStudyDisplayLineLabel(remainder);
        }
      }
    }

    return _quizStudyDisplayLineLabel(cleanedName);
  }

  List<EcoLine> _dedupeQuizStudyLinesByName(Iterable<EcoLine> lines) {
    final uniqueByName = <String, EcoLine>{};
    for (final line in lines) {
      uniqueByName.putIfAbsent(line.name, () => line);
    }

    final sorted = uniqueByName.values.toList()
      ..sort((a, b) {
        final familyCompare = _quizStudyFamilyName(
          a.name,
        ).toLowerCase().compareTo(_quizStudyFamilyName(b.name).toLowerCase());
        if (familyCompare != 0) {
          return familyCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return List<EcoLine>.unmodifiable(sorted);
  }

  List<EcoLine> _quizStudyPool(QuizStudyCategory category) {
    if (!_ensureQuizPoolsAvailable()) {
      return const <EcoLine>[];
    }

    return _quizStudyPoolCache[_quizStudyPoolKey(category)] ??
        const <EcoLine>[];
  }

  bool _ensureQuizPoolsAvailable() {
    if (_quizPoolsPrecomputed) {
      return true;
    }

    if (_hydratePrecomputedQuizPools()) {
      return true;
    }

    if (_ecoOpeningsLoading || _ecoLines.isEmpty) {
      return false;
    }

    _precomputeQuizEligiblePools();
    return _quizPoolsPrecomputed;
  }

  bool _quizStudyDataReady() {
    if (_quizStudyPoolCache.isNotEmpty) {
      return true;
    }

    return _ensureQuizPoolsAvailable();
  }

  String _quizPoolKey(GambitQuizMode mode, QuizDifficulty difficulty) {
    return '${mode.index}:${difficulty.index}';
  }

  ({int min, int max}) _quizTotalPlyRange(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return (min: 2, max: 8);
      case QuizDifficulty.medium:
        return (min: 6, max: 10);
      case QuizDifficulty.hard:
        return (min: 8, max: 14);
      case QuizDifficulty.veryHard:
        return (min: 10, max: 18);
    }
  }

  bool _lineWithinTotalPlyRange(EcoLine line, QuizDifficulty difficulty) {
    final range = _quizTotalPlyRange(difficulty);
    final totalPly = line.moveTokens.length;
    return totalPly >= range.min && totalPly <= range.max;
  }

  bool _lineFullyReplayable(EcoLine line) {
    if (line.moveTokens.length < 2) return false;
    var state = _initialBoardState();
    var whiteToMove = true;
    for (final token in line.moveTokens) {
      final uciMove = _resolveSanToUci(state, token, whiteToMove);
      if (uciMove == null) return false;
      state = _applyUciMove(state, uciMove);
      whiteToMove = !whiteToMove;
    }
    return true;
  }

  String? _openingNameAnnotationKey(String name) {
    final match = RegExp(
      r'(\d+\.(?:\.\.)?\s*(?:O-O-O|O-O|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](?:=[QRBN])?[+#]?)(?:\s+(?:O-O-O|O-O|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](?:=[QRBN])?[+#]?))*)',
      caseSensitive: false,
    ).firstMatch(name);
    if (match == null) return null;
    return match.group(1)?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _hasOpeningNameAnnotation(String name) {
    final key = _openingNameAnnotationKey(name);
    return key != null && key.isNotEmpty;
  }

  bool _hydratePrecomputedQuizPools() {
    final data = _precomputedQuizPoolData;
    if (data == null) {
      return false;
    }

    final rawLines = data['lines'];
    final rawPools = data['pools'];
    if (rawLines is! List || rawPools is! Map) {
      return false;
    }

    final indexedLines = <EcoLine>[];
    for (final rawLine in rawLines) {
      if (rawLine is! Map) {
        return false;
      }
      final name = rawLine['n']?.toString() ?? '';
      final normalizedMoves = rawLine['m']?.toString() ?? '';
      final isGambit = rawLine['g'] == true;
      if (name.isEmpty || normalizedMoves.isEmpty) {
        return false;
      }

      final moveTokens = normalizedMoves
          .split(' ')
          .where((token) => token.isNotEmpty)
          .toList(growable: false);
      if (moveTokens.isEmpty) {
        return false;
      }

      indexedLines.add(
        EcoLine(
          name: name,
          normalizedMoves: normalizedMoves,
          moveTokens: moveTokens,
          isGambit: isGambit,
        ),
      );
    }

    _quizEligiblePoolCache.clear();
    _quizEligibleNameCache.clear();
    _quizStudyPoolCache.clear();

    for (final entry in rawPools.entries) {
      final poolKey = entry.key.toString();
      final rawIndexes = entry.value;
      if (rawIndexes is! List) {
        return false;
      }

      final pool = <EcoLine>[];
      for (final rawIndex in rawIndexes) {
        final lineIndex = rawIndex is int
            ? rawIndex
            : rawIndex is num
            ? rawIndex.toInt()
            : -1;
        if (lineIndex < 0 || lineIndex >= indexedLines.length) {
          return false;
        }
        pool.add(indexedLines[lineIndex]);
      }

      final immutablePool = List<EcoLine>.unmodifiable(pool);
      if (poolKey.startsWith('study:')) {
        _quizStudyPoolCache[poolKey] = immutablePool;
      } else {
        _quizEligiblePoolCache[poolKey] = immutablePool;
        _quizEligibleNameCache[poolKey] = immutablePool
            .map((line) => line.name)
            .toSet();
      }
    }

    _quizPoolsPrecomputed = true;
    return true;
  }

  @override
  void _precomputeQuizEligiblePools() {
    if (_hydratePrecomputedQuizPools()) {
      return;
    }

    if (_ecoOpeningsLoading || _ecoLines.isEmpty) {
      _quizEligiblePoolCache.clear();
      _quizEligibleNameCache.clear();
      _quizStudyPoolCache.clear();
      _quizPoolsPrecomputed = false;
      return;
    }

    final allUniqueByName = <String, EcoLine>{};
    for (final line in _ecoLines) {
      allUniqueByName.putIfAbsent(line.name, () => line);
    }

    final allUniqueSortedByRarity = allUniqueByName.values.toList()
      ..sort((a, b) {
        final s = _openingPopularityScore(
          a.name,
        ).compareTo(_openingPopularityScore(b.name));
        if (s != 0) return s;
        return a.name.compareTo(b.name);
      });

    final replayableByName = <String, bool>{};
    bool isReplayable(EcoLine line) {
      return replayableByName.putIfAbsent(line.name, () {
        return _lineFullyReplayable(line);
      });
    }

    final noAnnotationReplayable = allUniqueSortedByRarity
        .where((line) => !_hasOpeningNameAnnotation(line.name))
        .where(isReplayable)
        .toList(growable: false);

    _quizEligiblePoolCache.clear();
    _quizEligibleNameCache.clear();
    _quizStudyPoolCache.clear();

    for (final difficulty in QuizDifficulty.values) {
      final ranged = noAnnotationReplayable
          .where((line) => _lineWithinTotalPlyRange(line, difficulty))
          .toList();

      var base = ranged
          .where(
            (line) => _openingPassesDifficultyFilter(
              _openingPopularityScore(line.name),
              difficulty,
            ),
          )
          .toList();

      if (difficulty == QuizDifficulty.veryHard && base.length < 250) {
        for (final line in ranged) {
          if (base.length >= 250) break;
          if (base.any((e) => e.name == line.name)) continue;
          base.add(line);
        }
      }

      final guessNamePool = List<EcoLine>.unmodifiable(base);
      final guessNameKey = _quizPoolKey(GambitQuizMode.guessName, difficulty);
      _quizEligiblePoolCache[guessNameKey] = guessNamePool;
      _quizEligibleNameCache[guessNameKey] = guessNamePool
          .map((line) => line.name)
          .toSet();

      final grouped = <String, int>{};
      for (final line in base) {
        if (line.moveTokens.length < 3) continue;
        final key = '${line.moveTokens[0]} ${line.moveTokens[1]}';
        grouped[key] = (grouped[key] ?? 0) + 1;
      }

      final guessLinePool = List<EcoLine>.unmodifiable(
        base.where((line) {
          if (line.moveTokens.length < 3) return false;
          final key = '${line.moveTokens[0]} ${line.moveTokens[1]}';
          return (grouped[key] ?? 0) >= 3;
        }),
      );
      final guessLineKey = _quizPoolKey(GambitQuizMode.guessLine, difficulty);
      _quizEligiblePoolCache[guessLineKey] = guessLinePool;
      _quizEligibleNameCache[guessLineKey] = guessLinePool
          .map((line) => line.name)
          .toSet();

      final studyCategory = _quizStudyCategoryForDifficulty(difficulty);
      _quizStudyPoolCache[_quizStudyPoolKey(studyCategory)] =
          _dedupeQuizStudyLinesByName([...guessNamePool, ...guessLinePool]);
    }

    _quizStudyPoolCache[_quizStudyPoolKey(QuizStudyCategory.library)] =
        _dedupeQuizStudyLinesByName(noAnnotationReplayable);

    _quizPoolsPrecomputed = true;
  }

  @override
  List<EcoLine> _quizEligiblePool({
    required GambitQuizMode mode,
    required QuizDifficulty difficulty,
  }) {
    if (!_ensureQuizPoolsAvailable()) {
      return const <EcoLine>[];
    }

    return _quizEligiblePoolCache[_quizPoolKey(mode, difficulty)] ??
        const <EcoLine>[];
  }

  @override
  void _markGambitViewed(String name) {
    if (_viewedGambits.add(name)) {
      unawaited(_saveViewedGambits());
    }
  }

  Future<void> _saveQuizStats() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'difficulty': _quizDifficulty.index,
      'studyCategory': _quizStudyCategory.index,
      'studyCounts': _quizStudyOpeningCounts,
      'dailyScore': _quizDailyScore,
      'dailyAttempts': _quizDailyAttempts,
      'dailyCorrect': _quizDailyCorrectByDay,
      'nameDailyAttempts': _quizNameDailyAttempts,
      'nameDailyCorrect': _quizNameDailyCorrect,
      'lineDailyAttempts': _quizLineDailyAttempts,
      'lineDailyCorrect': _quizLineDailyCorrect,
      'dailyQuestionsAsked': _quizDailyQuestionsAsked,
      'easyDailyAttempts': _quizEasyDailyAttempts,
      'easyDailyCorrect': _quizEasyDailyCorrect,
      'mediumDailyAttempts': _quizMediumDailyAttempts,
      'mediumDailyCorrect': _quizMediumDailyCorrect,
      'hardDailyAttempts': _quizHardDailyAttempts,
      'hardDailyCorrect': _quizHardDailyCorrect,
      'veryHardDailyAttempts': _quizVeryHardDailyAttempts,
      'veryHardDailyCorrect': _quizVeryHardDailyCorrect,
      'streak': _quizStreak,
      'bestStreak': _quizBestStreak,
      'totalAnswered': _quizTotalAnswered,
      'correctAnswers': _quizCorrectAnswers,
      'score': _quizScore,
      'academyProgress': _quizAcademyProgress.toMap(),
    };
    await prefs.setString(_quizStatsKey, jsonEncode(payload));
  }

  Future<void> _resetQuizStats() async {
    setState(() {
      _quizStudyCategory = QuizStudyCategory.basic;
      _quizStudySearchQuery = '';
      _quizStudyDetailOpen = false;
      _quizStudyInfoExpanded = false;
      _quizStudySelectedOpeningName = null;
      _quizStudyExpandedFamily = null;
      _quizStudyShownPly = 0;
      _quizStudyOpeningCounts.clear();
      _quizReviewHistory.clear();
      _quizReviewIndex = null;
      _quizStreak = 0;
      _quizBestStreak = 0;
      _quizTotalAnswered = 0;
      _quizCorrectAnswers = 0;
      _quizScore = 0;
      _quizDailyScore.clear();
      _quizDailyAttempts.clear();
      _quizDailyCorrectByDay.clear();
      _quizNameDailyAttempts.clear();
      _quizNameDailyCorrect.clear();
      _quizLineDailyAttempts.clear();
      _quizLineDailyCorrect.clear();
      _quizDailyQuestionsAsked.clear();
      _quizEasyDailyAttempts.clear();
      _quizEasyDailyCorrect.clear();
      _quizMediumDailyAttempts.clear();
      _quizMediumDailyCorrect.clear();
      _quizHardDailyAttempts.clear();
      _quizHardDailyCorrect.clear();
      _quizVeryHardDailyAttempts.clear();
      _quizVeryHardDailyCorrect.clear();
      _quizAcademyProgress = QuizAcademyProgress.initial();
    });
    await _saveQuizStats();
  }

  Future<void> _saveViewedGambits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _viewedGambitsKey,
      _viewedGambits.toList()..sort(),
    );
  }

  int _quizOptionCount() {
    return _quizOptionCountForDifficulty(_quizDifficulty);
  }

  int _quizOptionCountForDifficulty(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 3;
      case QuizDifficulty.medium:
        return 4;
      case QuizDifficulty.hard:
        return 4;
      case QuizDifficulty.veryHard:
        return 4;
    }
  }

  String _quizSetupDifficultyLabel(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Easy';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.hard:
        return 'Hard';
      case QuizDifficulty.veryHard:
        return 'Very Hard';
    }
  }

  String _quizSetupDifficultyDescription(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Start with common openings, shorter lines, and the fewest answer choices.';
      case QuizDifficulty.medium:
        return 'Add broader main lines, more branches, and one extra answer choice.';
      case QuizDifficulty.hard:
        return 'Expect sharper theory, tougher move orders, and deeper recall.';
      case QuizDifficulty.veryHard:
        return 'Finish with rare lines, longer recall, and the hardest answer set.';
    }
  }

  String _quizSetupDifficultyPanelMessage() {
    final levelDetails = QuizDifficulty.values
        .map(
          (difficulty) =>
              '${_quizSetupDifficultyLabel(difficulty)}: ${_quizSetupDifficultyDescription(difficulty)} (${_quizOptionCountForDifficulty(difficulty)} choices per question).',
        )
        .join('\n\n');
    return '$levelDetails\n\nUnlock the next level by finishing ${_quizAcademyProgress.requiredPerfectSessions} perfect 100% runs in the previous level.';
  }

  String _quizAcademyTierLabel(QuizDifficulty difficulty) {
    return _quizAcademyBracketShortName(difficulty);
  }

  String _quizAcademyTierSessionLabel(
    QuizDifficulty difficulty, {
    bool lowercase = false,
  }) {
    final label = '${_quizAcademyTierLabel(difficulty)} level';
    return lowercase ? label.toLowerCase() : label;
  }

  Color _quizDifficultyColor(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return const Color(0xFF7EDC8A);
      case QuizDifficulty.medium:
        return const Color(0xFFD8B640);
      case QuizDifficulty.hard:
        return const Color(0xFFFF8A80);
      case QuizDifficulty.veryHard:
        return const Color(0xFFD07EFF);
    }
  }

  String _quizAcademyBracketShortName(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Foundation';
      case QuizDifficulty.medium:
        return 'Seminar';
      case QuizDifficulty.hard:
        return 'Tournament';
      case QuizDifficulty.veryHard:
        return 'Oracle';
    }
  }

  String _quizAcademyBracketTitle(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Foundation Semester';
      case QuizDifficulty.medium:
        return 'Theory Seminar';
      case QuizDifficulty.hard:
        return 'Tournament Lab';
      case QuizDifficulty.veryHard:
        return 'Oracle Chamber';
    }
  }

  IconData _quizAcademyBracketIcon(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return Icons.school_outlined;
      case QuizDifficulty.medium:
        return Icons.menu_book_outlined;
      case QuizDifficulty.hard:
        return Icons.workspace_premium_outlined;
      case QuizDifficulty.veryHard:
        return Icons.auto_awesome_outlined;
    }
  }

  bool _quizDifficultyUnlocked(QuizDifficulty difficulty) {
    return _quizAcademyProgress.isDifficultyUnlocked(difficulty);
  }

  int _quizPerfectSessionsFor(QuizDifficulty difficulty) {
    return _quizAcademyProgress.perfectSessionsFor(difficulty);
  }

  void _syncQuizDifficultyToAcademyProgress() {
    if (_quizDifficultyUnlocked(_quizDifficulty)) {
      return;
    }
    _quizDifficulty = _quizAcademyProgress.highestUnlockedDifficulty();
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  double _quizAccuracy() {
    if (_quizTotalAnswered <= 0) return 0.0;
    return (_quizCorrectAnswers / _quizTotalAnswered) * 100.0;
  }

  String _quizTrendFilterLabel(QuizTrendFilter filter) {
    switch (filter) {
      case QuizTrendFilter.both:
        return 'Both Modes';
      case QuizTrendFilter.guessName:
        return 'Guess Name';
      case QuizTrendFilter.guessLine:
        return 'Guess Line';
    }
  }

  Map<String, int> _quizAttemptsMapForFilter(QuizTrendFilter filter) {
    switch (filter) {
      case QuizTrendFilter.both:
        return _quizDailyAttempts;
      case QuizTrendFilter.guessName:
        return _quizNameDailyAttempts;
      case QuizTrendFilter.guessLine:
        return _quizLineDailyAttempts;
    }
  }

  Map<String, int> _quizCorrectMapForFilter(QuizTrendFilter filter) {
    switch (filter) {
      case QuizTrendFilter.both:
        return _quizDailyCorrectByDay;
      case QuizTrendFilter.guessName:
        return _quizNameDailyCorrect;
      case QuizTrendFilter.guessLine:
        return _quizLineDailyCorrect;
    }
  }

  Map<String, int> _attemptsMapForFilters(
    QuizTrendFilter modeFilter,
    QuizStatsDifficultyFilter difficultyFilter,
  ) {
    if (difficultyFilter != QuizStatsDifficultyFilter.all) {
      switch (difficultyFilter) {
        case QuizStatsDifficultyFilter.easy:
          return _quizEasyDailyAttempts;
        case QuizStatsDifficultyFilter.medium:
          return _quizMediumDailyAttempts;
        case QuizStatsDifficultyFilter.hard:
          return _quizHardDailyAttempts;
        case QuizStatsDifficultyFilter.veryHard:
          return _quizVeryHardDailyAttempts;
        case QuizStatsDifficultyFilter.all:
          break;
      }
    }
    return _quizAttemptsMapForFilter(modeFilter);
  }

  Map<String, int> _correctMapForFilters(
    QuizTrendFilter modeFilter,
    QuizStatsDifficultyFilter difficultyFilter,
  ) {
    if (difficultyFilter != QuizStatsDifficultyFilter.all) {
      switch (difficultyFilter) {
        case QuizStatsDifficultyFilter.easy:
          return _quizEasyDailyCorrect;
        case QuizStatsDifficultyFilter.medium:
          return _quizMediumDailyCorrect;
        case QuizStatsDifficultyFilter.hard:
          return _quizHardDailyCorrect;
        case QuizStatsDifficultyFilter.veryHard:
          return _quizVeryHardDailyCorrect;
        case QuizStatsDifficultyFilter.all:
          break;
      }
    }
    return _quizCorrectMapForFilter(modeFilter);
  }

  String _statsDifficultyFilterLabel(QuizStatsDifficultyFilter filter) {
    switch (filter) {
      case QuizStatsDifficultyFilter.all:
        return 'All';
      case QuizStatsDifficultyFilter.easy:
        return 'Easy';
      case QuizStatsDifficultyFilter.medium:
        return 'Medium';
      case QuizStatsDifficultyFilter.hard:
        return 'Hard';
      case QuizStatsDifficultyFilter.veryHard:
        return 'Very Hard';
    }
  }

  void _trimDailyMap(Map<String, int> values, {int keepDays = 400}) {
    final keys = values.keys.toList()..sort();
    if (keys.length <= keepDays) return;
    for (final key in keys.take(keys.length - keepDays)) {
      values.remove(key);
    }
  }

  List<QuizAccuracyPoint> _buildQuizAccuracySeries(
    QuizTrendFilter filter, {
    int? days,
    QuizStatsDifficultyFilter difficultyFilter = QuizStatsDifficultyFilter.all,
  }) {
    final attempts = _attemptsMapForFilters(filter, difficultyFilter);
    final correct = _correctMapForFilters(filter, difficultyFilter);

    final keys = attempts.keys.toSet().union(correct.keys.toSet()).toList()
      ..sort();
    if (keys.isEmpty) return const <QuizAccuracyPoint>[];
    final recentKeys = (days == null || keys.length <= days)
        ? keys
        : keys.sublist(keys.length - days);

    return recentKeys
        .map((day) {
          final tries = attempts[day] ?? 0;
          final hits = correct[day] ?? 0;
          final accuracy = tries <= 0 ? 0.0 : ((hits / tries) * 100.0);
          final label = day.length >= 10 ? day.substring(5) : day;
          return QuizAccuracyPoint(
            dayLabel: label,
            value: accuracy.clamp(0.0, 100.0),
          );
        })
        .toList(growable: false);
  }

  List<QuizAccuracyPoint> _buildQuizAttemptSeries(
    QuizTrendFilter filter, {
    int? days,
    QuizStatsDifficultyFilter difficultyFilter = QuizStatsDifficultyFilter.all,
  }) {
    final attempts = _attemptsMapForFilters(filter, difficultyFilter);

    final keys = attempts.keys.toList()..sort();
    if (keys.isEmpty) return const <QuizAccuracyPoint>[];
    final recentKeys = (days == null || keys.length <= days)
        ? keys
        : keys.sublist(keys.length - days);

    return recentKeys
        .map((day) {
          final count = attempts[day] ?? 0;
          final label = day.length >= 10 ? day.substring(5) : day;
          return QuizAccuracyPoint(dayLabel: label, value: count.toDouble());
        })
        .toList(growable: false);
  }

  int _baseQuizPoints() {
    switch (_quizDifficulty) {
      case QuizDifficulty.easy:
        return 60;
      case QuizDifficulty.medium:
        return 95;
      case QuizDifficulty.hard:
        return 130;
      case QuizDifficulty.veryHard:
        return 175;
    }
  }

  String _pickQuizMessage(List<String> messages, Random random) {
    return messages[random.nextInt(messages.length)];
  }

  String _buildQuizFeedbackMessage({
    required bool isCorrect,
    required int nextStreak,
    required bool isPerfectSession,
  }) {
    final random = Random();
    final correctName = _quizOptions[_quizCorrectIndex];
    final correctMoves = _quizOptions[_quizCorrectIndex];
    final typeWord = correctName.toLowerCase().contains('gambit')
        ? 'gambit'
        : 'opening';

    if (_quizMode == GambitQuizMode.guessName) {
      if (isCorrect) {
        if (isPerfectSession) {
          return 'Flawless Identification. You have mastered every $typeWord in this set.';
        }
        if (nextStreak >= 7) {
          return _pickQuizMessage(const <String>[
            'Elite performance. 7 straight identifications.',
            'Masterful! Your opening database is extensive.',
          ], random);
        }
        if (nextStreak >= 5) {
          return _pickQuizMessage(const <String>[
            'Excellent consistency. 5 openings correctly named.',
            'High-level recall. You are in full command of the theory.',
          ], random);
        }
        if (nextStreak >= 3) {
          return _pickQuizMessage(const <String>[
            'Three-fold accuracy. You are finding a rhythm.',
            'Strong momentum. Three openingfinding a rhythm.',
            'Strong momentum. Three openings identified.',
            'Precision streak. Your focus is high.',
          ], random);
        }
        if (nextStreak >= 2) {
          return _pickQuizMessage(const <String>[
            'Two in a row. Your recall is sharpening.',
            'Consecutive accuracy. Keep it up.',
            'Double success. Your study is paying off.',
          ], random);
        }

        final message = _pickQuizMessage(const <String>[
          'Correct. Theory identified.',
          'Accurate. That is the {name}.',
          'Correct. Your opening knowledge is precise.',
          'Confirmed. This is the {name}.',
          'Correct. The position is well-recognized.',
          'Exactly. You\'ve identified the line.',
          'Correct. Book knowledge verified.',
          'Spot on. This is standard theory.',
          'Correct. You\'ve recognized the pattern.',
          'Correct. Identification successful.',
        ], random);
        return message.replaceAll('{name}', correctName);
      }

      final message = _pickQuizMessage(const <String>[
        'Incorrect. This is the {name}.',
        'Not quite. Theory indicates the {name}.',
        'Inaccurate. The correct answer is {name}.',
        'Mistake. This position arises in the {name}.',
        'Incorrect. You\'ve identified the wrong line.',
        'Wrong choice. It was actually the {name}.',
        'Negative. Correct response: {name}.',
        'Misidentified. This is the {name}.',
        'Incorrect. Review the {name} line.',
        'Error. The correct name is {name}.',
      ], random);
      return message.replaceAll('{name}', correctName);
    }

    if (isCorrect) {
      if (isPerfectSession) {
        return 'Total Theoretical Mastery. Every move was book-perfect.';
      }
      if (nextStreak >= 7) {
        return _pickQuizMessage(const <String>[
          'Grandmaster precision! 7-streak reached.',
          'Incredible vision. You are navigating the board like a pro.',
        ], random);
      }
      if (nextStreak >= 5) {
        return _pickQuizMessage(const <String>[
          'Professional grade! 5 complex lines solved.',
          'Superb calculation. You\'re out-thinking the quiz.',
        ], random);
      }
      if (nextStreak >= 3) {
        return _pickQuizMessage(const <String>[
          'Triple accuracy. You are seeing deep into the lines.',
          'A hat trick of theory! Excellent vision.',
          'Three perfect sequences. You\'re in the flow.',
        ], random);
      }
      if (nextStreak >= 2) {
        return _pickQuizMessage(const <String>[
          'Back-to-back accuracy. Your lines are clean.',
          'Two sequences solved. You\'re building an advantage.',
          'Steady progress. Your calculation is consistent.',
        ], random);
      }

      return _pickQuizMessage(const <String>[
        'Correct. The moves are theoretically sound.',
        'Accurate. You followed the main line.',
        'Correct. Sequence verified by theory.',
        'Well played. Those are the book moves.',
        'Correct. Your calculation is exact.',
        'Perfect execution of the sequence.',
        'Correct. You\'ve navigated the line correctly.',
        'Right. You avoided the deviations.',
        'Correct. Technical accuracy achieved.',
        'Precisely. The theory is handled well.',
      ], random);
    }

    final message = _pickQuizMessage(const <String>[
      'Incorrect. The main line is: {moves}',
      'Blunder. The correct sequence is: {moves}',
      'Inaccurate. Theory requires: {moves}',
      'Mistake. The intended moves were: {moves}',
      'Wrong sequence. The book move is: {moves}',
      'Incorrect. You deviated from the main line.',
      'Error. The correct continuation is: {moves}',
      'Wrong. That choice loses the initiative.',
      'Incorrect. Follow the theory: {moves}',
      'Mistake. The correct play is {moves}.',
    ], random);
    return message.replaceAll('{moves}', correctMoves);
  }

  Future<void> _triggerSuccessHaptic() async {
    await _lightHaptic();
    await Future.delayed(const Duration(milliseconds: 65));
    await _lightHaptic();
  }

  void _recordQuizResult({required bool isCorrect}) {
    final base = _baseQuizPoints();
    final modeBonus = _quizMode == GambitQuizMode.guessLine ? 20 : 0;
    final streakBonus = min(60, _quizStreak * 8);

    if (isCorrect) {
      _quizStreak += 1;
      _quizBestStreak = max(_quizBestStreak, _quizStreak);
      _quizCorrectAnswers += 1;
      _quizScore += base + modeBonus + streakBonus;
    } else {
      _quizStreak = 0;
      _quizScore = max(0, _quizScore - min(40, (base / 2).round()));
    }

    _quizTotalAnswered += 1;
    final day = _todayKey();
    _quizDailyScore[day] =
        (_quizDailyScore[day] ?? 0) + (isCorrect ? base : 10);

    _quizDailyAttempts[day] = (_quizDailyAttempts[day] ?? 0) + 1;
    if (isCorrect) {
      _quizDailyCorrectByDay[day] = (_quizDailyCorrectByDay[day] ?? 0) + 1;
    }

    if (_quizMode == GambitQuizMode.guessName) {
      _quizNameDailyAttempts[day] = (_quizNameDailyAttempts[day] ?? 0) + 1;
      if (isCorrect) {
        _quizNameDailyCorrect[day] = (_quizNameDailyCorrect[day] ?? 0) + 1;
      }
    } else {
      _quizLineDailyAttempts[day] = (_quizLineDailyAttempts[day] ?? 0) + 1;
      if (isCorrect) {
        _quizLineDailyCorrect[day] = (_quizLineDailyCorrect[day] ?? 0) + 1;
      }
    }

    _trimDailyMap(_quizDailyScore);
    _trimDailyMap(_quizDailyAttempts);
    _trimDailyMap(_quizDailyCorrectByDay);
    _trimDailyMap(_quizNameDailyAttempts);
    _trimDailyMap(_quizNameDailyCorrect);
    _trimDailyMap(_quizLineDailyAttempts);
    _trimDailyMap(_quizLineDailyCorrect);

    _recordPerDifficulty(day, isCorrect);
    unawaited(_saveQuizStats());
  }

  void _recordPerDifficulty(String day, bool isCorrect) {
    switch (_quizDifficulty) {
      case QuizDifficulty.easy:
        _quizEasyDailyAttempts[day] = (_quizEasyDailyAttempts[day] ?? 0) + 1;
        if (isCorrect) {
          _quizEasyDailyCorrect[day] = (_quizEasyDailyCorrect[day] ?? 0) + 1;
        }
      case QuizDifficulty.medium:
        _quizMediumDailyAttempts[day] =
            (_quizMediumDailyAttempts[day] ?? 0) + 1;
        if (isCorrect) {
          _quizMediumDailyCorrect[day] =
              (_quizMediumDailyCorrect[day] ?? 0) + 1;
        }
      case QuizDifficulty.hard:
        _quizHardDailyAttempts[day] = (_quizHardDailyAttempts[day] ?? 0) + 1;
        if (isCorrect) {
          _quizHardDailyCorrect[day] = (_quizHardDailyCorrect[day] ?? 0) + 1;
        }
      case QuizDifficulty.veryHard:
        _quizVeryHardDailyAttempts[day] =
            (_quizVeryHardDailyAttempts[day] ?? 0) + 1;
        if (isCorrect) {
          _quizVeryHardDailyCorrect[day] =
              (_quizVeryHardDailyCorrect[day] ?? 0) + 1;
        }
    }
    _trimDailyMap(_quizEasyDailyAttempts);
    _trimDailyMap(_quizEasyDailyCorrect);
    _trimDailyMap(_quizMediumDailyAttempts);
    _trimDailyMap(_quizMediumDailyCorrect);
    _trimDailyMap(_quizHardDailyAttempts);
    _trimDailyMap(_quizHardDailyCorrect);
    _trimDailyMap(_quizVeryHardDailyAttempts);
    _trimDailyMap(_quizVeryHardDailyCorrect);
  }

  void _setQuizDifficulty(QuizDifficulty difficulty) {
    if (!_quizDifficultyUnlocked(difficulty)) {
      unawaited(_showQuizDifficultyLockedDialog(difficulty));
      return;
    }
    if (_quizDifficulty == difficulty) return;
    setState(() {
      _quizDifficulty = difficulty;
      _quizEligibleCount = _quizEligiblePool(
        mode: _quizMode,
        difficulty: _quizDifficulty,
      ).length;
    });
    unawaited(_saveQuizStats());
  }

  void _selectQuizAcademyMode({GambitQuizMode? mode, required bool studyMode}) {
    final nextMode = mode ?? _quizMode;
    final nextEligibleCount = studyMode
        ? _quizEligibleCount
        : _quizEligiblePool(mode: nextMode, difficulty: _quizDifficulty).length;

    setState(() {
      _quizStudyMode = studyMode;
      _quizQuestionsTarget = 10;
      _quizMode = nextMode;
      _quizEligibleCount = nextEligibleCount;
      _quizStudyDetailOpen = false;
      _quizStudyShownPly = 0;
    });
  }

  int _quizStudyCountFor(String openingName) {
    return _quizStudyOpeningCounts[openingName] ?? 0;
  }

  int _quizStudyCategoryTotalCount(QuizStudyCategory category) {
    return _quizStudyPool(category).length;
  }

  int _quizStudyCategoryStudiedCount(QuizStudyCategory category) {
    var studied = 0;
    for (final line in _quizStudyPool(category)) {
      if (_quizStudyCountFor(line.name) > 0) {
        studied += 1;
      }
    }
    return studied;
  }

  double _quizStudyCategoryCompletion(QuizStudyCategory category) {
    final total = _quizStudyCategoryTotalCount(category);
    if (total <= 0) {
      return 0.0;
    }
    return _quizStudyCategoryStudiedCount(category) / total;
  }

  int _quizStudyCategoryTotalReps(QuizStudyCategory category) {
    var total = 0;
    for (final line in _quizStudyPool(category)) {
      total += _quizStudyCountFor(line.name);
    }
    return total;
  }

  int _quizStudyTotalReps() {
    return _quizStudyOpeningCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
  }

  int _quizStudyScopedReps(QuizStudyCategory? category) {
    return category == null
        ? _quizStudyTotalReps()
        : _quizStudyCategoryTotalReps(category);
  }

  int _quizStudyScopedStudiedCount(QuizStudyCategory? category) {
    return category == null
        ? _quizStudyOpeningCounts.length
        : _quizStudyCategoryStudiedCount(category);
  }

  void _resetQuizStudyProgress({QuizStudyCategory? category}) {
    setState(() {
      if (category == null) {
        _quizStudyOpeningCounts.clear();
        return;
      }

      final scopedLineNames = _quizStudyPool(
        category,
      ).map((line) => line.name).toSet();
      _quizStudyOpeningCounts.removeWhere(
        (openingName, _) => scopedLineNames.contains(openingName),
      );
    });
  }

  Future<void> _showQuizStudyResetDialog() async {
    if (_quizStudyTotalReps() <= 0) {
      return;
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final palette = _academyPalette(
      scheme: scheme,
      useMonochrome: useMonochrome,
      isDark: isDark,
    );
    QuizStudyCategory? selectedScope =
        _quizStudyCategoryTotalReps(_quizStudyCategory) > 0
        ? _quizStudyCategory
        : null;

    final selectedScopeName = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final targetLabel = selectedScope == null
                ? 'ALL CATEGORIES'
                : _quizStudyCategoryLabel(selectedScope!).toUpperCase();
            final targetStudied = _quizStudyScopedStudiedCount(selectedScope);
            final targetReps = _quizStudyScopedReps(selectedScope);
            final resetCopy = selectedScope == null
                ? 'This clears every studied opening count across all study categories and families. Progress rings and navigator checkmarks will reset.'
                : 'This clears the studied opening counts for the ${_quizStudyCategoryLabel(selectedScope!).toLowerCase()} category only. Progress rings and navigator checkmarks in that category will reset.';

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _academyPixelPanel(
                  palette: palette,
                  accent: palette.signal,
                  fillColor: palette.panel,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _academyTag(
                        palette: palette,
                        label: 'WARNING',
                        accent: palette.signal,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'RESET STUDIED OPENINGS',
                        style: _academyDisplayStyle(
                          palette: palette,
                          size: 22,
                          weight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        resetCopy,
                        style: _academyHudStyle(
                          palette: palette,
                          size: 12.8,
                          color: palette.textMuted,
                          weight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'RESET TARGET',
                        style: _academyHudStyle(
                          palette: palette,
                          size: 11.8,
                          color: palette.text,
                          weight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: palette.shell,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: palette.cyan.withValues(alpha: 0.42),
                            width: 2,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<QuizStudyCategory?>(
                            value: selectedScope,
                            isExpanded: true,
                            dropdownColor: palette.panelAlt,
                            iconEnabledColor: palette.cyan,
                            style: _academyHudStyle(
                              palette: palette,
                              size: 12.8,
                              color: palette.text,
                              weight: FontWeight.w700,
                              letterSpacing: 0.65,
                            ),
                            items: <DropdownMenuItem<QuizStudyCategory?>>[
                              DropdownMenuItem<QuizStudyCategory?>(
                                value: null,
                                child: Text(
                                  'ALL CATEGORIES',
                                  style: _academyHudStyle(
                                    palette: palette,
                                    size: 12.8,
                                    color: palette.text,
                                    weight: FontWeight.w700,
                                    letterSpacing: 0.65,
                                  ),
                                ),
                              ),
                              ...QuizStudyCategory.values.map(
                                (category) =>
                                    DropdownMenuItem<QuizStudyCategory?>(
                                      value: category,
                                      child: Text(
                                        _quizStudyCategoryLabel(
                                          category,
                                        ).toUpperCase(),
                                        style: _academyHudStyle(
                                          palette: palette,
                                          size: 12.8,
                                          color: palette.text,
                                          weight: FontWeight.w700,
                                          letterSpacing: 0.65,
                                        ),
                                      ),
                                    ),
                              ),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                selectedScope = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _buildQuizAcademyMetricChip(
                            palette: palette,
                            label: 'TARGET',
                            value: targetLabel,
                            accent: palette.cyan,
                            icon: Icons.layers_rounded,
                          ),
                          _buildQuizAcademyMetricChip(
                            palette: palette,
                            label: 'STUDIED',
                            value: targetStudied.toString(),
                            accent: palette.emerald,
                            icon: Icons.auto_stories_outlined,
                          ),
                          _buildQuizAcademyMetricChip(
                            palette: palette,
                            label: 'REPS',
                            value: targetReps.toString(),
                            accent: palette.amber,
                            icon: Icons.bolt_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Are you sure you want to continue?',
                        style: _academyHudStyle(
                          palette: palette,
                          size: 12.4,
                          color: palette.text,
                          weight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.end,
                        children: <Widget>[
                          _academyHudButton(
                            palette: palette,
                            icon: Icons.close_rounded,
                            label: 'CANCEL',
                            accent: palette.cyan,
                            onTap: () => Navigator.of(dialogContext).pop(),
                          ),
                          _academyHudButton(
                            palette: palette,
                            icon: Icons.restart_alt_rounded,
                            label: 'RESET',
                            accent: palette.signal,
                            filled: true,
                            onTap: targetReps > 0
                                ? () => Navigator.of(
                                    dialogContext,
                                  ).pop(selectedScope?.name ?? 'all')
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (selectedScopeName == null || !mounted) {
      return;
    }

    _resetQuizStudyProgress(
      category: selectedScopeName == 'all'
          ? null
          : QuizStudyCategory.values.byName(selectedScopeName),
    );
    unawaited(_saveQuizStats());
  }

  void _setQuizStudyCategory(QuizStudyCategory category) {
    if (_quizStudyCategory == category) {
      return;
    }

    final nextLines = _quizStudyPool(category);
    final nextLineNames = nextLines.map((line) => line.name).toSet();
    final nextFamilies = nextLines
        .map((line) => _quizStudyFamilyName(line.name))
        .toSet();

    setState(() {
      _quizStudyCategory = category;
      _quizStudySearchQuery = '';
      _quizStudyDetailOpen = false;
      _quizStudyInfoExpanded = false;
      _quizStudyShownPly = 0;

      if (_quizStudySelectedOpeningName != null &&
          !nextLineNames.contains(_quizStudySelectedOpeningName)) {
        _quizStudySelectedOpeningName = null;
      }
      if (_quizStudyExpandedFamily != null &&
          !nextFamilies.contains(_quizStudyExpandedFamily)) {
        _quizStudyExpandedFamily = null;
      }
    });
    unawaited(_saveQuizStats());
  }

  void _setQuizStudySearchQuery(String value) {
    if (_quizStudySearchQuery == value) {
      return;
    }
    setState(() {
      _quizStudySearchQuery = value;
      if (value.trim().isNotEmpty) {
        _quizStudyExpandedFamily = null;
      }
    });
  }

  void _toggleQuizStudyFamily(String familyName) {
    setState(() {
      _quizStudyExpandedFamily = _quizStudyExpandedFamily == familyName
          ? null
          : familyName;
    });
  }

  void _toggleQuizStudyInfoExpanded() {
    setState(() {
      _quizStudyInfoExpanded = !_quizStudyInfoExpanded;
    });
  }

  void _closeQuizStudyDetail() {
    if (!_quizStudyDetailOpen) {
      return;
    }
    setState(() {
      _quizStudyDetailOpen = false;
      _quizStudyInfoExpanded = false;
      _quizStudyShownPly = 0;
    });
    _focusQuizStudyLibraryIndex(focusSelection: true);
  }

  void _exitQuizStudyScreen() {
    if (!_quizStudyMode) {
      return;
    }
    setState(() {
      _quizStudyMode = false;
      _quizStudyDetailOpen = false;
      _quizStudyInfoExpanded = false;
      _quizStudyShownPly = 0;
    });
  }

  void _selectQuizStudyOpening(EcoLine line, {bool focusBoard = false}) {
    final familyName = _quizStudyFamilyName(line.name);
    setState(() {
      _quizStudySelectedOpeningName = line.name;
      _quizStudyExpandedFamily = familyName;
      _quizStudyDetailOpen = true;
      _quizStudyInfoExpanded = false;
      _quizStudyShownPly = 0;
      _quizStudyOpeningCounts[line.name] = _quizStudyCountFor(line.name) + 1;
    });
    if (focusBoard) {
      _focusQuizStudyBoard();
    }
    unawaited(_saveQuizStats());
  }

  int _quizStudyShownPlyFor(EcoLine line) {
    if (_quizStudySelectedOpeningName != line.name) {
      return 0;
    }

    return _quizStudyShownPly.clamp(0, line.moveTokens.length).toInt();
  }

  void _setQuizStudyShownPly(EcoLine line, int shownPly) {
    final clampedPly = shownPly.clamp(0, line.moveTokens.length).toInt();
    if (_quizStudyShownPly == clampedPly) {
      return;
    }

    setState(() {
      _quizStudyShownPly = clampedPly;
    });
  }

  void _resetQuizStudyPosition(EcoLine line) {
    _setQuizStudyShownPly(line, 0);
  }

  void _stepQuizStudyBackward(EcoLine line) {
    _setQuizStudyShownPly(line, _quizStudyShownPlyFor(line) - 1);
  }

  bool _isCaptureMoveOnBoard(Map<String, String> boardState, String uciMove) {
    if (uciMove.length < 4) {
      return false;
    }

    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final piece = boardState[from];
    if (piece == null) {
      return false;
    }

    return boardState.containsKey(to) || (piece[0] == 'p' && from[0] != to[0]);
  }

  void _stepQuizStudyForward(EcoLine line) {
    final currentPly = _quizStudyShownPlyFor(line);
    if (currentPly >= line.moveTokens.length) {
      return;
    }

    var boardState = _initialBoardState();
    var whiteToMove = true;
    for (var index = 0; index < currentPly; index++) {
      final token = line.moveTokens[index];
      final uciMove = _resolveSanToUci(boardState, token, whiteToMove);
      if (uciMove == null) {
        return;
      }
      boardState = _applyUciMove(boardState, uciMove);
      whiteToMove = !whiteToMove;
    }

    final nextUciMove = _resolveSanToUci(
      boardState,
      line.moveTokens[currentPly],
      whiteToMove,
    );
    if (nextUciMove == null) {
      return;
    }

    _setQuizStudyShownPly(line, currentPly + 1);
    unawaited(
      _playBoardMoveSound(
        isCapture: _isCaptureMoveOnBoard(boardState, nextUciMove),
      ),
    );
  }

  List<_QuizStudyFamilyGroup> _quizStudyFamilyGroups(
    QuizStudyCategory category,
  ) {
    final query = _quizStudySearchQuery.trim().toLowerCase();
    final grouped = <String, List<EcoLine>>{};

    for (final line in _quizStudyPool(category)) {
      final familyName = _quizStudyFamilyName(line.name);
      if (query.isNotEmpty) {
        final haystack = '$familyName ${line.name} ${line.normalizedMoves}'
            .toLowerCase();
        if (!haystack.contains(query)) {
          continue;
        }
      }
      grouped.putIfAbsent(familyName, () => <EcoLine>[]).add(line);
    }

    final groups = grouped.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return groups
        .map((entry) {
          entry.value.sort((a, b) {
            final variationCompare = _quizStudyVariationLabel(a, entry.key)
                .toLowerCase()
                .compareTo(
                  _quizStudyVariationLabel(b, entry.key).toLowerCase(),
                );
            if (variationCompare != 0) {
              return variationCompare;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          return _QuizStudyFamilyGroup(
            familyName: entry.key,
            lines: List<EcoLine>.unmodifiable(entry.value),
          );
        })
        .toList(growable: false);
  }

  EcoLine? _selectedQuizStudyLine() {
    final selectedName = _quizStudySelectedOpeningName;
    if (selectedName == null || selectedName.isEmpty) {
      return null;
    }

    for (final line in _quizStudyPool(_quizStudyCategory)) {
      if (line.name == selectedName) {
        return line;
      }
    }

    return null;
  }

  List<EcoLine> _quizStudyFamilyLines(String familyName) {
    final lines = _quizStudyPool(
      _quizStudyCategory,
    ).where((line) => _quizStudyFamilyName(line.name) == familyName).toList();

    lines.sort((a, b) {
      final variationCompare = _quizStudyVariationLabel(a, familyName)
          .toLowerCase()
          .compareTo(_quizStudyVariationLabel(b, familyName).toLowerCase());
      if (variationCompare != 0) {
        return variationCompare;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return List<EcoLine>.unmodifiable(lines);
  }

  int _quizStudyFamilyStudiedCount(_QuizStudyFamilyGroup group) {
    var studied = 0;
    for (final line in group.lines) {
      if (_quizStudyCountFor(line.name) > 0) {
        studied += 1;
      }
    }
    return studied;
  }

  _QuizStudyPreview? _buildQuizStudyPreview(EcoLine line) {
    final shownPly = _quizStudyShownPlyFor(line);
    var boardState = _initialBoardState();
    var whiteToMove = true;

    for (var index = 0; index < shownPly; index++) {
      final token = line.moveTokens[index];
      final uciMove = _resolveSanToUci(boardState, token, whiteToMove);
      if (uciMove == null) {
        return null;
      }
      boardState = _applyUciMove(boardState, uciMove);
      whiteToMove = !whiteToMove;
    }

    final previewBoardState = Map<String, String>.from(boardState);
    final previewWhiteToMove = whiteToMove;
    final continuation = <EngineLine>[];
    for (var index = shownPly; index < line.moveTokens.length; index++) {
      final token = line.moveTokens[index];
      final uciMove = _resolveSanToUci(boardState, token, whiteToMove);
      if (uciMove == null) {
        return null;
      }
      continuation.add(
        EngineLine(
          uciMove,
          0,
          max(1, line.moveTokens.length - index),
          continuation.length + 1,
        ),
      );
      boardState = _applyUciMove(boardState, uciMove);
      whiteToMove = !whiteToMove;
    }

    return _QuizStudyPreview(
      boardState: previewBoardState,
      whiteToMove: previewWhiteToMove,
      shownPly: shownPly,
      totalPly: line.moveTokens.length,
      continuation: List<EngineLine>.unmodifiable(continuation),
    );
  }

  void _appendQuizReviewEntry({
    required int selectedIndex,
    required String feedback,
    required bool skipped,
  }) {
    if (_quizOptions.isEmpty ||
        _quizBoardState.isEmpty ||
        _quizContinuation.isEmpty) {
      return;
    }

    _quizReviewHistory.add(
      _QuizRoundReview(
        mode: _quizMode,
        prompt: _quizPrompt,
        promptFocus: _quizPromptFocus,
        options: List<String>.from(_quizOptions),
        correctIndex: _quizCorrectIndex,
        selectedIndex: selectedIndex,
        feedback: feedback,
        boardState: Map<String, String>.from(_quizBoardState),
        continuation: List<EngineLine>.from(_quizContinuation),
        whiteToMove: _quizWhiteToMove,
        shownPly: _quizShownPly,
        skipped: skipped,
      ),
    );
  }

  void _exitQuizReviewMode() {
    if (_quizReviewIndex == null) return;
    setState(() => _quizReviewIndex = null);
  }

  void _clearQuizFeedbackOverlay() {
    _quizFeedbackOverlayTimer?.cancel();
    _quizFeedbackOverlayTimer = null;
    _quizFeedbackOverlayMessage = null;
    _quizFeedbackOverlayCorrect = null;
  }

  void _showQuizFeedbackOverlay({required String message, bool? isCorrect}) {
    _quizFeedbackOverlayTimer?.cancel();
    setState(() {
      _quizFeedbackOverlayMessage = message;
      _quizFeedbackOverlayCorrect = isCorrect;
    });
    _quizFeedbackOverlayTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(_clearQuizFeedbackOverlay);
    });
  }

  void _clearQuizRoundState() {
    _clearQuizFeedbackOverlay();
    _quizPrompt = '';
    _quizPromptFocus = '';
    _quizOptions = const <String>[];
    _quizBoardState = <String, String>{};
    _quizContinuation = <EngineLine>[];
    _quizWhiteToMove = true;
    _quizShownPly = 0;
    _quizAnswered = false;
    _quizSelectedIndex = -1;
    _quizPreviewContinuation = <EngineLine>[];
    _quizPlayActive = false;
    _quizPlayArrowCount = 0;
    _quizPlayBoard = <String, String>{};
    _quizFlyFrom = null;
    _quizFlyTo = null;
    _quizFlyPiece = null;
    _quizFlyProgress = 0.0;
    _quizReviewIndex = null;
  }

  @override
  void _resetQuizToSetupState() {
    _quizSessionStarted = false;
    _quizSessionAnswered = 0;
    _quizSessionCorrect = 0;
    _quizReviewHistory.clear();
    _clearQuizRoundState();
  }

  void _returnToQuizSetup() {
    setState(_resetQuizToSetupState);
  }

  @override
  void _openGambitQuizFromAcademy() {
    setState(() {
      _playVsBot = false;
      _selectedBot = null;
      _botThinking = false;
      _quizLaunchedFromAcademy = true;
      _quizStudyMode = false;
      _quizStudyDetailOpen = false;
      _quizQuestionsTarget = 10;
      _syncQuizDifficultyToAcademyProgress();
      _resetQuizToSetupState();
      _activeSection = AppSection.gambitQuiz;
    });
  }

  Future<void> _showQuizAcademyNoticeDialog({
    required String title,
    required String message,
    String tagLabel = 'INFO',
    String actionLabel = 'CLOSE',
    IconData icon = Icons.info_outline_rounded,
    Color? accent,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final useMonochrome =
            ctx.read<AppThemeProvider>().isMonochrome ||
            _isCinematicThemeEnabled;
        final palette = _academyPalette(
          scheme: theme.colorScheme,
          useMonochrome: useMonochrome,
          isDark: isDark,
        );
        final effectiveAccent = accent ?? palette.cyan;
        final maxDialogHeight = min(
          MediaQuery.of(ctx).size.height * 0.82,
          560.0,
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: maxDialogHeight,
            ),
            child: _academyPixelPanel(
              palette: palette,
              accent: effectiveAccent,
              fillColor: palette.panel,
              child: Scrollbar(
                child: SingleChildScrollView(
                  key: const ValueKey<String>(
                    'quiz_academy_notice_scroll_view',
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _academyTag(
                            palette: palette,
                            label: tagLabel,
                            accent: effectiveAccent,
                          ),
                          const Spacer(),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(
                                effectiveAccent.withValues(alpha: 0.12),
                                palette.panelAlt,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: effectiveAccent.withValues(alpha: 0.50),
                                width: 2,
                              ),
                            ),
                            child: Icon(icon, size: 18, color: effectiveAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title.toUpperCase(),
                        style: _academyDisplayStyle(
                          palette: palette,
                          size: 22,
                          weight: FontWeight.w700,
                          letterSpacing: 0.85,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        style: _academyHudStyle(
                          palette: palette,
                          size: 12.8,
                          color: palette.text,
                          weight: FontWeight.w600,
                          letterSpacing: 0.24,
                          height: 1.48,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _academyHudButton(
                          palette: palette,
                          icon: Icons.check_rounded,
                          label: actionLabel,
                          accent: effectiveAccent,
                          onTap: () => Navigator.of(ctx).pop(),
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showQuizDifficultyLockedDialog(
    QuizDifficulty difficulty,
  ) async {
    final previousDifficulty = QuizDifficulty.values[difficulty.index - 1];
    final remaining = _quizAcademyProgress.remainingPerfectSessionsFor(
      previousDifficulty,
    );
    final previousLabel = _quizAcademyTierSessionLabel(
      previousDifficulty,
      lowercase: true,
    );
    final difficultyLabel = _quizAcademyTierLabel(difficulty);

    await _showQuizAcademyNoticeDialog(
      title: '$difficultyLabel Locked',
      message: remaining <= 0
          ? '$difficultyLabel is ready, but your current academy bracket needs to refresh. Return to the setup screen and try again.'
          : 'Complete $remaining more perfect $previousLabel session${remaining == 1 ? '' : 's'} to unlock $difficultyLabel. Promotion credit only counts when the whole session finishes at 100% accuracy.',
      tagLabel: 'LOCKED',
      actionLabel: 'UNDERSTOOD',
      icon: Icons.lock_outline_rounded,
      accent: _quizDifficultyColor(difficulty),
    );
  }

  QuizSessionAcademyOutcome _recordQuizSessionOutcome() {
    final sessionDifficulty = _quizDifficulty;
    final accuracy = _quizSessionAnswered <= 0
        ? 0.0
        : (_quizSessionCorrect / _quizSessionAnswered) * 100.0;
    final perfectSession =
        _quizSessionAnswered > 0 && _quizSessionCorrect == _quizSessionAnswered;
    final requiredPerfectSessions =
        _quizAcademyProgress.requiredPerfectSessions;
    var nextDifficulty = _quizAcademyProgress.nextDifficulty(sessionDifficulty);
    var earnedProgressCredit = false;
    var unlockedNextDifficulty = false;
    var completedTrack = _quizAcademyProgress.isTrackComplete;
    var completedPerfectSessions = _quizAcademyProgress.perfectSessionsFor(
      sessionDifficulty,
    );

    if (perfectSession) {
      final previousProgress = completedPerfectSessions;
      final updatedProgress = _quizAcademyProgress.recordPerfectSession(
        sessionDifficulty,
      );
      completedPerfectSessions = updatedProgress.perfectSessionsFor(
        sessionDifficulty,
      );
      earnedProgressCredit = completedPerfectSessions > previousProgress;
      final difficultyCompletedNow =
          previousProgress < requiredPerfectSessions &&
          completedPerfectSessions >= requiredPerfectSessions;

      _quizAcademyProgress = updatedProgress;
      nextDifficulty = updatedProgress.nextDifficulty(sessionDifficulty);
      unlockedNextDifficulty = difficultyCompletedNow && nextDifficulty != null;
      completedTrack = updatedProgress.isTrackComplete;

      if (unlockedNextDifficulty) {
        _quizDifficulty = nextDifficulty;
      } else {
        _syncQuizDifficultyToAcademyProgress();
      }

      _quizEligibleCount = _quizEligiblePool(
        mode: _quizMode,
        difficulty: _quizDifficulty,
      ).length;
      unawaited(_saveQuizStats());
    }

    return QuizSessionAcademyOutcome(
      sessionDifficulty: sessionDifficulty,
      activeDifficultyAfterSession: _quizDifficulty,
      nextDifficulty: nextDifficulty,
      accuracy: accuracy,
      perfectSession: perfectSession,
      earnedProgressCredit: earnedProgressCredit,
      unlockedNextDifficulty: unlockedNextDifficulty,
      completedTrack: completedTrack,
      completedPerfectSessions: completedPerfectSessions,
      requiredPerfectSessions: requiredPerfectSessions,
    );
  }

  Future<void> _showQuizSessionSummaryDialog(
    QuizSessionAcademyOutcome outcome,
  ) async {
    final sessionLabel = _quizAcademyTierLabel(outcome.sessionDifficulty);
    final sessionLevelLabel = _quizAcademyTierSessionLabel(
      outcome.sessionDifficulty,
      lowercase: true,
    );
    final nextLabel = outcome.nextDifficulty == null
        ? null
        : _quizAcademyTierLabel(outcome.nextDifficulty!);

    var headline = 'Session Complete';
    var detail =
        'Finish at 100% accuracy to bank academy promotion credit for the $sessionLevelLabel bracket.';

    if (outcome.completedTrack && outcome.perfectSession) {
      headline = 'Oracle Certification Complete';
      detail =
          'You cleared the final academy bracket. Every Opening Quiz difficulty is now fully certified.';
    } else if (outcome.unlockedNextDifficulty && nextLabel != null) {
      headline = '$nextLabel Unlocked';
      detail =
          'Your perfect $sessionLabel session completed the bracket. $nextLabel is now available from the academy ladder.';
    } else if (outcome.perfectSession && outcome.earnedProgressCredit) {
      headline = 'Perfect Session Banked';
      detail =
          'Academy progress recorded for $sessionLabel. Keep chaining flawless sessions to reach the next bracket.';
    } else if (outcome.perfectSession && !outcome.earnedProgressCredit) {
      if (nextLabel != null &&
          _quizAcademyProgress.isDifficultyCompleted(
            outcome.sessionDifficulty,
          )) {
        headline = '$sessionLabel Certified';
        detail =
            '$sessionLabel is already complete. Move into $nextLabel to keep advancing through the academy track.';
      } else {
        headline = 'Session Complete';
      }
    } else if (nextLabel != null) {
      final remaining = _quizAcademyProgress.remainingPerfectSessionsFor(
        outcome.sessionDifficulty,
      );
      detail =
          'A promotion credit was not awarded. You still need $remaining perfect $sessionLevelLabel session${remaining == 1 ? '' : 's'} to unlock $nextLabel.';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        final accent = _quizDifficultyColor(outcome.sessionDifficulty);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    accent.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.20 : 0.12,
                    ),
                    scheme.surface,
                  ),
                  Color.alphaBlend(
                    scheme.primary.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.16 : 0.06,
                    ),
                    scheme.surface,
                  ),
                  scheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: accent.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.20),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.38)),
                  ),
                  child: Text(
                    _quizAcademyBracketTitle(outcome.sessionDifficulty),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  detail,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.78),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _quizSessionSummaryChip(
                      label: 'Questions',
                      value: '$_quizSessionAnswered/$_quizQuestionsTarget',
                      accent: const Color(0xFF5AAEE8),
                    ),
                    _quizSessionSummaryChip(
                      label: 'Correct',
                      value: _quizSessionCorrect.toString(),
                      accent: const Color(0xFF7EDC8A),
                    ),
                    _quizSessionSummaryChip(
                      label: 'Accuracy',
                      value: '${outcome.accuracy.toStringAsFixed(1)}%',
                      accent: const Color(0xFFD8B640),
                    ),
                    _quizSessionSummaryChip(
                      label: 'Bracket Credit',
                      value:
                          '${outcome.completedPerfectSessions}/${outcome.requiredPerfectSessions}',
                      accent: accent,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: accent.computeLuminance() > 0.55
                          ? const Color(0xFF081015)
                          : Colors.white,
                    ),
                    child: Text(
                      outcome.unlockedNextDifficulty && nextLabel != null
                          ? 'Train $nextLabel'
                          : 'Return to Academy',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quizSessionSummaryChip({
    required String label,
    required String value,
    required Color accent,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(color: accent),
            ),
          ],
        ),
      ),
    );
  }

  void _startQuizSession() {
    if (_quizStudyMode) {
      return;
    }

    setState(() {
      _clearQuizFeedbackOverlay();
      _syncQuizDifficultyToAcademyProgress();
      _quizStudyMode = false;
      _quizQuestionsTarget = 10;
      _quizSessionStarted = true;
      _quizSessionAnswered = 0;
      _quizSessionCorrect = 0;
      _quizAnswered = false;
      _quizSelectedIndex = -1;
      _quizReviewHistory.clear();
      _quizReviewIndex = null;
    });
    _startQuizRound(mode: _quizMode);
  }

  Future<void> _finishQuizSession() async {
    late QuizSessionAcademyOutcome outcome;
    setState(() {
      outcome = _recordQuizSessionOutcome();
    });

    await _showQuizSessionSummaryDialog(outcome);

    if (!mounted) return;
    setState(() {
      _resetQuizToSetupState();
    });
  }

  Future<void> _handleQuizPrimaryAction() async {
    if (_quizReviewIndex != null) {
      _exitQuizReviewMode();
      return;
    }
    if (!_quizSessionStarted) {
      _startQuizSession();
      return;
    }
    if (_quizAnswered && _quizSessionAnswered >= _quizQuestionsTarget) {
      await _finishQuizSession();
      return;
    }
    if (!_quizAnswered) {
      _submitSelectedQuizGuess();
      return;
    }
    _startQuizRound();
  }

  void _openQuizStatsSheet() {
    if (_quizStudyMode) {
      unawaited(_showQuizStudyStatsDialog());
      return;
    }

    var filter = QuizTrendFilter.both;
    int? days = 7;
    var difficultyFilter = QuizStatsDifficultyFilter.all;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10131B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final screenHeight = MediaQuery.sizeOf(ctx).height;
          return SafeArea(
            child: SizedBox(
              height: screenHeight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Close stats',
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    _buildQuizStatsCard(
                      filter: filter,
                      difficultyFilter: difficultyFilter,
                      days: days,
                      onFilterChanged: (next) {
                        setSheetState(() => filter = next);
                      },
                      onDifficultyFilterChanged: (next) {
                        setSheetState(() => difficultyFilter = next);
                      },
                      onDaysChanged: (next) {
                        setSheetState(() => days = next);
                      },
                      onReset: () async {
                        await _resetQuizStats();
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showQuizStudyStatsDialog() async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final palette = _academyPalette(
      scheme: scheme,
      useMonochrome: useMonochrome,
      isDark: isDark,
    );
    final currentCategory = _quizStudyCategory;
    final currentGroups = _quizStudyFamilyGroups(currentCategory);
    final totalFamilies = currentGroups.length;
    final completedFamilies = currentGroups
        .where(
          (group) =>
              group.lines.isNotEmpty &&
              _quizStudyFamilyStudiedCount(group) >= group.lines.length,
        )
        .length;
    final currentTotal = _quizStudyCategoryTotalCount(currentCategory);
    final currentStudied = _quizStudyCategoryStudiedCount(currentCategory);
    final currentReps = _quizStudyCategoryTotalReps(currentCategory);
    final currentCompletion = _quizStudyCategoryCompletion(currentCategory);
    final overallStudied = _quizStudyOpeningCounts.length;
    final overallReps = _quizStudyTotalReps();
    final maxDialogHeight = min(
      MediaQuery.of(context).size.height * 0.86,
      760.0,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: maxDialogHeight,
            ),
            child: _academyPixelPanel(
              palette: palette,
              accent: palette.cyan,
              fillColor: palette.panel,
              child: SingleChildScrollView(
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
                              _academyTag(
                                palette: palette,
                                label: 'PROGRESS REPORT',
                                accent: palette.cyan,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'STUDY LIBRARY STATS',
                                style: _academyDisplayStyle(
                                  palette: palette,
                                  size: 24,
                                  weight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Progress here reflects opening study shelves instead of quiz performance.',
                                style: _academyHudStyle(
                                  palette: palette,
                                  size: 12.6,
                                  color: palette.textMuted,
                                  weight: FontWeight.w600,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _academyHudButton(
                          palette: palette,
                          icon: Icons.close_rounded,
                          label: 'CLOSE',
                          accent: palette.amber,
                          onTap: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _buildQuizAcademyMetricChip(
                          palette: palette,
                          label: 'CATEGORY',
                          value: _quizStudyCategoryLabel(currentCategory),
                          accent: _quizStudyCategoryColor(currentCategory),
                          icon: _quizStudyCategoryIcon(currentCategory),
                        ),
                        _buildQuizAcademyMetricChip(
                          palette: palette,
                          label: 'OPENINGS',
                          value: '$currentStudied/$currentTotal',
                          accent: palette.emerald,
                          icon: Icons.auto_stories_outlined,
                        ),
                        _buildQuizAcademyMetricChip(
                          palette: palette,
                          label: 'FAMILIES',
                          value: '$completedFamilies/$totalFamilies',
                          accent: palette.cyan,
                          icon: Icons.account_tree_outlined,
                        ),
                        _buildQuizAcademyMetricChip(
                          palette: palette,
                          label: 'CATEGORY REPS',
                          value: currentReps.toString(),
                          accent: palette.amber,
                          icon: Icons.bolt_rounded,
                        ),
                        _buildQuizAcademyMetricChip(
                          palette: palette,
                          label: 'LIBRARY LOGGED',
                          value: overallStudied.toString(),
                          accent: palette.signal,
                          icon: Icons.grid_view_rounded,
                        ),
                        _buildQuizAcademyMetricChip(
                          palette: palette,
                          label: 'ALL REPS',
                          value: overallReps.toString(),
                          accent: palette.cyan,
                          icon: Icons.insights_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _academyPixelPanel(
                      palette: palette,
                      accent: _quizStudyCategoryColor(currentCategory),
                      fillColor: palette.panelAlt,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _academyPanelHeader(
                            palette: palette,
                            title: 'CURRENT CATEGORY',
                            subtitle:
                                '${_quizStudyCategoryLabel(currentCategory)} completion and repetition totals for the category you are currently browsing.',
                          ),
                          const SizedBox(height: 12),
                          _buildQuizStudyMeter(
                            this,
                            palette: palette,
                            label: 'CATEGORY COMPLETION',
                            valueLabel:
                                '${(currentCompletion * 100).toStringAsFixed(0)}%',
                            value: currentCompletion,
                            accent: _quizStudyCategoryColor(currentCategory),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _academyPixelPanel(
                      palette: palette,
                      accent: palette.emerald,
                      fillColor: palette.panelAlt,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _academyPanelHeader(
                            palette: palette,
                            title: 'CATEGORY BREAKDOWN',
                            subtitle:
                                'Every study category uses the same progress rules: a line counts once as studied after its first launch.',
                          ),
                          const SizedBox(height: 12),
                          for (final category
                              in QuizStudyCategory.values) ...<Widget>[
                            _buildQuizStudyMeter(
                              this,
                              palette: palette,
                              label: _quizStudyCategoryLabel(
                                category,
                              ).toUpperCase(),
                              valueLabel:
                                  '${_quizStudyCategoryStudiedCount(category)}/${_quizStudyCategoryTotalCount(category)}',
                              value: _quizStudyCategoryCompletion(category),
                              accent: _quizStudyCategoryColor(category),
                            ),
                            if (category != QuizStudyCategory.values.last)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    if (overallReps <= 0) ...<Widget>[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(
                            palette.amber.withValues(alpha: 0.10),
                            palette.shell,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: palette.amber.withValues(alpha: 0.32),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'No study reps have been logged yet. Open a variation from the library to start filling these meters.',
                          style: _academyHudStyle(
                            palette: palette,
                            size: 12.4,
                            color: palette.textMuted,
                            weight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  QuizBoardSnapshot? _buildQuizSnapshot(
    EcoLine gambit,
    GambitQuizMode mode,
    Random random,
  ) {
    final tokens = gambit.moveTokens;
    if (tokens.length < 2) return null;
    final plyRange = _quizTotalPlyRange(_quizDifficulty);
    if (tokens.length < plyRange.min || tokens.length > plyRange.max) {
      return null;
    }

    final maxPrefix = tokens.length - 1;
    final int prefix;
    if (mode == GambitQuizMode.guessLine) {
      if (tokens.length < 3) return null;
      prefix = 2;
    } else {
      int minPrefix;
      int maxHintPrefix;
      switch (_quizDifficulty) {
        case QuizDifficulty.easy:
          minPrefix = 3;
          maxHintPrefix = 7;
          break;
        case QuizDifficulty.medium:
          minPrefix = 2;
          maxHintPrefix = 6;
          break;
        case QuizDifficulty.hard:
          minPrefix = 1;
          maxHintPrefix = 4;
          break;
        case QuizDifficulty.veryHard:
          minPrefix = 1;
          maxHintPrefix = 3;
          break;
      }
      minPrefix = minPrefix.clamp(1, maxPrefix);
      final maxPrefixUsed = min(maxHintPrefix, maxPrefix);
      prefix = maxPrefixUsed <= minPrefix
          ? minPrefix
          : (minPrefix + random.nextInt(maxPrefixUsed - minPrefix + 1));
    }

    var state = _initialBoardState();
    var whiteToMove = true;

    for (int i = 0; i < prefix; i++) {
      final uciMove = _resolveSanToUci(state, tokens[i], whiteToMove);
      if (uciMove == null) return null;
      state = _applyUciMove(state, uciMove);
      whiteToMove = !whiteToMove;
    }

    final continuation = <EngineLine>[];
    var continuationState = Map<String, String>.from(state);
    var continuationWhiteToMove = whiteToMove;
    for (int i = prefix; i < tokens.length; i++) {
      final uciMove = _resolveSanToUci(
        continuationState,
        tokens[i],
        continuationWhiteToMove,
      );
      if (uciMove == null) break;
      continuation.add(
        EngineLine(
          uciMove,
          -90 * continuation.length,
          max(1, tokens.length - i),
          continuation.length + 1,
        ),
      );
      continuationState = _applyUciMove(continuationState, uciMove);
      continuationWhiteToMove = !continuationWhiteToMove;
    }

    if (continuation.isEmpty) return null;

    if (continuation.length != tokens.length - prefix) return null;

    return QuizBoardSnapshot(
      boardState: state,
      whiteToMove: whiteToMove,
      shownPly: prefix,
      continuation: continuation,
    );
  }

  void _startQuizRound({GambitQuizMode? mode}) {
    final activeMode = mode ?? _quizMode;
    final gambits = _quizEligiblePool(
      mode: activeMode,
      difficulty: _quizDifficulty,
    );
    if (gambits.length < 3) {
      setState(() {
        _clearQuizFeedbackOverlay();
        _quizPrompt = 'Not enough gambits loaded yet.';
        _quizPromptFocus = '';
        _quizOptions = const <String>[];
        _quizCorrectIndex = 0;
        _quizBoardState = <String, String>{};
        _quizContinuation = <EngineLine>[];
        _quizWhiteToMove = true;
        _quizShownPly = 0;
        _quizAnswered = false;
        _quizSelectedIndex = -1;
        _quizPreviewContinuation = <EngineLine>[];
        if (mode != null) _quizMode = mode;
      });
      return;
    }

    final random = Random();
    final candidates = List<EcoLine>.from(gambits)..shuffle(random);
    EcoLine? correct;
    QuizBoardSnapshot? snapshot;
    for (final candidate in candidates) {
      final built = _buildQuizSnapshot(candidate, activeMode, random);
      if (built == null) continue;

      if (activeMode == GambitQuizMode.guessLine) {
        if (candidate.moveTokens.length < 2) continue;
        final first = candidate.moveTokens[0];
        final second = candidate.moveTokens[1];
        final possibleOptions = gambits.where(
          (entry) =>
              entry.moveTokens.length >= 2 &&
              entry.moveTokens[0] == first &&
              entry.moveTokens[1] == second,
        );
        if (possibleOptions.length < 3) {
          continue;
        }
      }

      correct = candidate;
      snapshot = built;
      break;
    }
    if (correct == null || snapshot == null) {
      setState(() {
        _clearQuizFeedbackOverlay();
        _quizPrompt = 'Unable to build a playable quiz board for now.';
        _quizPromptFocus = '';
        _quizOptions = const <String>[];
        _quizCorrectIndex = 0;
        _quizBoardState = <String, String>{};
        _quizContinuation = <EngineLine>[];
        _quizWhiteToMove = true;
        _quizShownPly = 0;
        _quizAnswered = false;
        _quizSelectedIndex = -1;
        _quizMode = activeMode;
      });
      return;
    }

    final resolvedCorrect = correct;
    final resolvedSnapshot = snapshot;

    _markGambitViewed(resolvedCorrect.name);

    final options = <EcoLine>[resolvedCorrect];
    if (activeMode == GambitQuizMode.guessLine &&
        resolvedCorrect.moveTokens.length >= 2) {
      final first = resolvedCorrect.moveTokens[0];
      final second = resolvedCorrect.moveTokens[1];
      final linePool =
          gambits
              .where(
                (entry) =>
                    entry.name != resolvedCorrect.name &&
                    entry.moveTokens.length >= 2 &&
                    entry.moveTokens[0] == first &&
                    entry.moveTokens[1] == second,
              )
              .toList()
            ..shuffle(random);
      final targetLineOptions = min(_quizOptionCount(), linePool.length + 1);
      for (final candidate in linePool) {
        if (options.length >= targetLineOptions) break;
        options.add(candidate);
      }
    } else {
      final targetOptions = min(_quizOptionCount(), gambits.length);
      final namePool =
          gambits.where((entry) => entry.name != resolvedCorrect.name).toList()
            ..shuffle(random);
      for (final candidate in namePool) {
        if (options.length >= targetOptions) break;
        options.add(candidate);
      }
    }
    options.shuffle(random);
    final correctIndex = options.indexWhere(
      (entry) => entry.name == resolvedCorrect.name,
    );

    setState(() {
      _clearQuizFeedbackOverlay();
      _quizMode = activeMode;
      _quizCorrectIndex = correctIndex;
      _quizBoardState = Map<String, String>.from(resolvedSnapshot.boardState);
      _quizContinuation = List<EngineLine>.from(resolvedSnapshot.continuation);
      _quizWhiteToMove = resolvedSnapshot.whiteToMove;
      _quizShownPly = resolvedSnapshot.shownPly;
      _quizAnswered = false;
      _quizSelectedIndex = -1;
      _quizPreviewContinuation = <EngineLine>[];
      _quizPlayActive = false;
      _quizPlayArrowCount = 0;
      _quizPlayBoard = <String, String>{};
      _quizFlyFrom = null;
      _quizFlyTo = null;
      _quizFlyPiece = null;
      _quizFlyProgress = 0.0;
      _quizReviewIndex = null;
      if (activeMode == GambitQuizMode.guessName) {
        _quizPrompt = '';
        _quizPromptFocus = '';
        _quizOptions = options.map((entry) => entry.name).toList();
      } else {
        _quizPrompt = resolvedCorrect.name;
        _quizPromptFocus = '';
        _quizOptions = options.map((entry) => entry.normalizedMoves).toList();
      }

      final day = _todayKey();
      _quizDailyQuestionsAsked[day] = (_quizDailyQuestionsAsked[day] ?? 0) + 1;
      _trimDailyMap(_quizDailyQuestionsAsked);
    });
  }

  Offset _squareToGridOffset(String sq, double boardSize, bool reverse) {
    const inset = 2.0;
    final sqSize = (boardSize - inset * 2) / 8;
    int col = sq.codeUnitAt(0) - 97;
    int row = int.parse(sq[1]) - 1;
    if (reverse) {
      col = 7 - col;
    } else {
      row = 7 - row;
    }
    return Offset(
      inset + col * sqSize + sqSize / 2,
      inset + row * sqSize + sqSize / 2,
    );
  }

  Future<void> _startQuizPlayback() async {
    if (!mounted || _quizContinuation.isEmpty || _quizBoardState.isEmpty) {
      return;
    }
    // Keep reveal speed at 30% of the previous pace.
    const speedFactor = 0.14 / 0.30;
    final initialDelayMs = max(1, (280 * speedFactor).round());
    final stepDelayMs = max(1, (9 * speedFactor).round());
    final betweenMovesDelayMs = max(1, (225 * speedFactor).round());
    const stepCount = 36;

    await Future.delayed(Duration(milliseconds: initialDelayMs));
    if (!mounted || !_quizAnswered) return;

    var board = Map<String, String>.from(_quizBoardState);
    setState(() {
      _quizPlayBoard = Map<String, String>.from(board);
      _quizPlayArrowCount = _quizContinuation.length;
      _quizPlayActive = true;
      _quizFlyFrom = null;
      _quizFlyTo = null;
      _quizFlyPiece = null;
      _quizFlyProgress = 0.0;
    });

    for (int i = 0; i < _quizContinuation.length; i++) {
      if (!mounted || !_quizPlayActive) return;
      final uciMove = _quizContinuation[i].move;
      final from = uciMove.substring(0, 2);
      final piece = board[from];
      if (piece == null) break;

      final boardDuringFlight = Map<String, String>.from(board)..remove(from);
      final isCapture = _isCaptureMoveOnBoard(board, uciMove);
      setState(() {
        _quizPlayBoard = boardDuringFlight;
        _quizFlyFrom = from;
        _quizFlyTo = uciMove.substring(2, 4);
        _quizFlyPiece = piece;
        _quizFlyProgress = 0.0;
      });

      for (var stepIndex = 1; stepIndex <= stepCount; stepIndex++) {
        if (!mounted || !_quizPlayActive) return;
        final step = stepIndex / stepCount;
        setState(() {
          _quizFlyProgress = step;
        });
        await Future.delayed(Duration(milliseconds: stepDelayMs));
      }
      if (!mounted || !_quizPlayActive) return;

      board = _applyUciMove(board, uciMove);
      setState(() {
        _quizPlayBoard = Map<String, String>.from(board);
        _quizPlayArrowCount = i + 1;
        _quizFlyFrom = null;
        _quizFlyTo = null;
        _quizFlyPiece = null;
        _quizFlyProgress = 0.0;
      });
      unawaited(_playBoardMoveSound(isCapture: isCapture));

      if (i < _quizContinuation.length - 1) {
        await Future.delayed(Duration(milliseconds: betweenMovesDelayMs));
        if (!mounted || !_quizPlayActive) return;
      }
    }

    if (mounted) setState(() => _quizPlayActive = false);
  }

  void _submitQuizAnswer(int index) {
    if (_quizAnswered) return;
    final isCorrect = index == _quizCorrectIndex;
    final shouldShowMilestoneInterstitial = (_quizTotalAnswered + 1) % 10 == 0;
    final nextAnswered = _quizSessionAnswered + 1;
    final nextCorrect = _quizSessionCorrect + (isCorrect ? 1 : 0);
    final nextStreak = isCorrect ? _quizStreak + 1 : 0;
    final isPerfectSession =
        isCorrect &&
        nextAnswered == _quizQuestionsTarget &&
        nextCorrect == _quizQuestionsTarget;
    final feedback = _buildQuizFeedbackMessage(
      isCorrect: isCorrect,
      nextStreak: nextStreak,
      isPerfectSession: isPerfectSession,
    );

    _appendQuizReviewEntry(
      selectedIndex: index,
      feedback: feedback,
      skipped: false,
    );

    setState(() {
      _quizSelectedIndex = index;
      _quizAnswered = true;
      _quizPreviewContinuation = <EngineLine>[];
      _quizSessionAnswered += 1;
      if (isCorrect) {
        _quizSessionCorrect += 1;
      }
      _recordQuizResult(isCorrect: isCorrect);
    });
    _showQuizFeedbackOverlay(message: feedback, isCorrect: isCorrect);

    if (isCorrect) {
      if (nextStreak >= 5) {
        unawaited(_triggerSuccessHaptic());
      } else {
        unawaited(_lightHaptic());
      }
    }

    unawaited(
      _handlePostAnswerEffects(
        shouldPlayReveal:
            _quizBoardState.isNotEmpty && _quizContinuation.isNotEmpty,
        shouldShowMilestoneInterstitial: shouldShowMilestoneInterstitial,
      ),
    );
  }

  Future<void> _handlePostAnswerEffects({
    required bool shouldPlayReveal,
    required bool shouldShowMilestoneInterstitial,
  }) async {
    if (shouldPlayReveal) {
      await _startQuizPlayback();
    }
    if (shouldShowMilestoneInterstitial) {
      await _showQuizMilestoneInterstitial();
    }
  }

  Future<void> _showQuizMilestoneInterstitial() async {
    final shown = await AdService.instance.showInterstitialAd();
    if (!shown) {
      _addLog('Quiz interstitial unavailable at 10-guess milestone.');
    }
  }

  List<EngineLine> _buildQuizPreviewContinuationForOption(int optionIndex) {
    if (_quizMode != GambitQuizMode.guessLine) return const <EngineLine>[];
    if (_quizBoardState.isEmpty || _quizOptions.isEmpty) {
      return const <EngineLine>[];
    }
    if (optionIndex < 0 || optionIndex >= _quizOptions.length) {
      return const <EngineLine>[];
    }

    final tokens = _moveSequenceTokens(_quizOptions[optionIndex]);
    if (tokens.length <= _quizShownPly) return const <EngineLine>[];

    final continuation = <EngineLine>[];
    var state = Map<String, String>.from(_quizBoardState);
    var whiteToMove = _quizWhiteToMove;
    for (int i = _quizShownPly; i < tokens.length; i++) {
      final uciMove = _resolveSanToUci(state, tokens[i], whiteToMove);
      if (uciMove == null) break;
      continuation.add(
        EngineLine(
          uciMove,
          -90 * continuation.length,
          max(1, tokens.length - i),
          continuation.length + 1,
        ),
      );
      state = _applyUciMove(state, uciMove);
      whiteToMove = !whiteToMove;
    }
    return continuation;
  }

  void _selectQuizAnswerOption(int index) {
    if (_quizAnswered || _quizReviewIndex != null) return;
    setState(() {
      _quizSelectedIndex = index;
      _quizPreviewContinuation = _quizMode == GambitQuizMode.guessLine
          ? _buildQuizPreviewContinuationForOption(index)
          : <EngineLine>[];
    });
  }

  void _submitSelectedQuizGuess() {
    if (_quizAnswered) return;
    if (_quizSelectedIndex < 0 || _quizSelectedIndex >= _quizOptions.length) {
      _showQuizFeedbackOverlay(
        message: 'Choose an option first, then tap Guess.',
      );
      return;
    }
    _submitQuizAnswer(_quizSelectedIndex);
  }

  Widget _buildQuizAcademySetupScreen() {
    if (_quizStudyMode) {
      return _buildQuizStudyScreen(this);
    }

    final media = MediaQuery.of(context);
    final viewportPadding = _quizAcademyViewportPadding(media);
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
    final layout = _QuizAcademySetupLayoutSpec.fromMedia(media);
    final sideInset = max(
      layout.outerHorizontalPadding,
      (media.size.width - layout.contentMaxWidth) / 2,
    );
    final quizPadding = EdgeInsets.fromLTRB(
      sideInset + viewportPadding.left,
      layout.outerTopPadding + viewportPadding.top,
      sideInset + viewportPadding.right,
      layout.outerBottomPadding + viewportPadding.bottom,
    );
    final backAction = _quizOpeningsRoutePage
        ? _returnToQuizSelector
        : _goToMenu;
    final backTooltip = _quizOpeningsRoutePage ? 'Back to mode selector' : '';
    final pageTitle = _quizOpeningsRoutePage
        ? 'OPENINGS QUIZ'
        : 'OPENING ACADEMY';
    final pageSubtitle = _quizOpeningsRoutePage ? '' : 'QUIZ OR STUDY';
    final compactLandscapeHeader = layout.compactLandscape;
    final compactPortraitSetupHeader =
        _quizOpeningsRoutePage && layout.compactPortrait;
    final setupBackdropReducedEffects =
        media.disableAnimations || layout.compactPhoneLayout;
    final backgroundColors = _quizOpeningsRoutePage
        ? <Color>[
            Color.alphaBlend(
              palette.cyan.withValues(alpha: useMonochrome ? 0.04 : 0.16),
              palette.backdrop,
            ),
            Color.alphaBlend(
              palette.amber.withValues(alpha: useMonochrome ? 0.03 : 0.10),
              palette.shell,
            ),
            Color.alphaBlend(
              palette.emerald.withValues(alpha: useMonochrome ? 0.04 : 0.12),
              palette.panelAlt,
            ),
          ]
        : <Color>[palette.backdrop, palette.shell, palette.panelAlt];
    final currentPoolCount = _quizEligiblePool(
      mode: _quizMode,
      difficulty: _quizDifficulty,
    ).length;
    final canStart = currentPoolCount >= 3;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: backgroundColors,
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned.fill(child: _buildQuizAcademyAtmosphere(useMonochrome)),
        if (_quizOpeningsRoutePage)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _QuizAcademySetupGlowPainter(
                      palette: palette,
                      phase: setupBackdropReducedEffects
                          ? 0.0
                          : _pulseController.value,
                      reducedEffects: setupBackdropReducedEffects,
                    ),
                  );
                },
              ),
            ),
          ),
        ListView(
          padding: quizPadding,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < 780 && !compactLandscapeHeader;
                final backButton = _academyHudButton(
                  buttonKey: const ValueKey<String>(
                    'quiz_academy_header_back_button',
                  ),
                  palette: palette,
                  icon: Icons.arrow_back,
                  label: _quizOpeningsRoutePage ? 'BACK' : 'EXIT',
                  accent: palette.text,
                  onTap: backAction,
                );
                final styleButton = _buildQuizAcademyHeaderIconButton(
                  buttonKey: const ValueKey<String>(
                    'quiz_academy_header_style_button',
                  ),
                  palette: palette,
                  icon: Icons.palette_outlined,
                  accent: palette.amber,
                  tooltip: 'Style',
                  onTap: _openAppearanceSettings,
                );
                final statsButton = !_quizOpeningsRoutePage
                    ? _buildQuizAcademyHeaderIconButton(
                        buttonKey: const ValueKey<String>(
                          'quiz_academy_header_stats_button',
                        ),
                        palette: palette,
                        icon: Icons.insights_outlined,
                        accent: palette.cyan,
                        tooltip: 'Stats',
                        onTap: _openQuizStatsSheet,
                      )
                    : null;
                final actionButtons = <Widget>[
                  backButton,
                  styleButton,
                  ...?statsButton == null ? null : <Widget>[statsButton],
                ];
                final actions = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: actionButtons,
                );
                final titleBlock = Column(
                  key: const ValueKey<String>(
                    'quiz_academy_header_title_block',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pageTitle,
                      style: _academyDisplayStyle(
                        palette: palette,
                        size: compactLandscapeHeader ? 20 : 24,
                        weight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (pageSubtitle.isNotEmpty) ...<Widget>[
                      SizedBox(height: compactLandscapeHeader ? 4 : 6),
                      Text(
                        pageSubtitle,
                        style: _academyHudStyle(
                          palette: palette,
                          size: compactLandscapeHeader ? 11.2 : 12,
                          weight: FontWeight.w700,
                          letterSpacing: 0.85,
                        ),
                      ),
                    ],
                    if (!_quizOpeningsRoutePage &&
                        backTooltip.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        backTooltip,
                        style: _academyHudStyle(palette: palette, size: 11.3),
                      ),
                    ],
                  ],
                );

                return _academyPixelPanel(
                  palette: palette,
                  accent: _quizOpeningsRoutePage
                      ? _academyQuizModeAccent(palette, _quizMode)
                      : palette.cyan,
                  fillColor: palette.shell,
                  child: compactPortraitSetupHeader
                      ? Row(
                          children: <Widget>[
                            backButton,
                            const Spacer(),
                            styleButton,
                          ],
                        )
                      : compactLandscapeHeader
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            backButton,
                            const SizedBox(width: 12),
                            Expanded(child: titleBlock),
                            const SizedBox(width: 12),
                            styleButton,
                            if (statsButton != null) ...<Widget>[
                              const SizedBox(width: 8),
                              statsButton,
                            ],
                          ],
                        )
                      : stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            titleBlock,
                            const SizedBox(height: 14),
                            actions,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: titleBlock),
                            const SizedBox(width: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: actions,
                            ),
                          ],
                        ),
                );
              },
            ),
            const SizedBox(height: 16),
            if (_quizOpeningsRoutePage)
              _buildQuizAcademyModeSetupPage(
                layout: layout,
                useMonochrome: useMonochrome,
                currentPoolCount: currentPoolCount,
                canStart: canStart,
              )
            else
              _buildQuizAcademyLaunchScreen(
                useMonochrome: useMonochrome,
                isDark: isDark,
                scheme: scheme,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuizAcademyHeaderIconButton({
    Key? buttonKey,
    required _QuizAcademyPalette palette,
    required IconData icon,
    required Color accent,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        key: buttonKey,
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
              border: Border.all(
                color: accent.withValues(alpha: 0.48),
                width: 2,
              ),
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

  void _returnToQuizSelector() {
    setState(() {
      _quizOpeningsRoutePage = false;
      _quizStudyMode = false;
    });
  }

  Widget _buildQuizAcademyLaunchScreen({
    required bool useMonochrome,
    required bool isDark,
    required ColorScheme scheme,
  }) {
    final palette = _academyPalette(
      scheme: scheme,
      useMonochrome: useMonochrome,
      isDark: isDark,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final dualColumn = constraints.maxWidth >= 700;
        final quizCard = _buildQuizAcademyLauncherCard(
          cardKey: const ValueKey<String>('quiz_academy_launcher_quiz'),
          palette: palette,
          assetPath: 'assets/academy/openingsquiz.png',
          title: 'Openings Quiz',
          subtitle:
              'Choose the mode and level, then start a 10-question opening session.',
          cartridgeLabel: 'QUIZ',
          ctaLabel: 'SET UP QUIZ',
          accent: palette.cyan,
          onTap: () {
            setState(() {
              _quizOpeningsRoutePage = true;
              _quizStudyMode = false;
              _quizQuestionsTarget = 10;
              _quizStudyDetailOpen = false;
              _quizStudyShownPly = 0;
              _quizEligibleCount = _quizEligiblePool(
                mode: _quizMode,
                difficulty: _quizDifficulty,
              ).length;
            });
            _focusQuizAcademyModePanel();
          },
        );
        final studyCard = _buildQuizAcademyLauncherCard(
          cardKey: const ValueKey<String>('quiz_academy_launcher_study'),
          palette: palette,
          assetPath: 'assets/academy/openingsstudy.png',
          title: 'Openings Study',
          subtitle:
              'Open the library, browse families, and replay saved lines.',
          cartridgeLabel: 'STUDY',
          ctaLabel: 'OPEN STUDY',
          accent: palette.amber,
          onTap: () => _selectQuizAcademyMode(studyMode: true),
        );
        final selectorDeck = dualColumn
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: quizCard),
                  const SizedBox(width: 14),
                  Expanded(child: studyCard),
                ],
              )
            : Column(
                children: <Widget>[
                  quizCard,
                  const SizedBox(height: 14),
                  studyCard,
                ],
              );

        return selectorDeck;
      },
    );
  }

  Widget _buildQuizAcademyLauncherCard({
    Key? cardKey,
    required _QuizAcademyPalette palette,
    required String assetPath,
    required String title,
    required String subtitle,
    required String cartridgeLabel,
    required String ctaLabel,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final foreground = accent.computeLuminance() > 0.55
        ? const Color(0xFF081015)
        : Colors.white;
    return Material(
      key: cardKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(accent.withValues(alpha: 0.14), palette.panel),
                palette.panel,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: accent.withValues(alpha: 0.78), width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.shadow,
                offset: const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _academyTag(
                    palette: palette,
                    label: cartridgeLabel,
                    accent: accent,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    color: accent,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 168,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.58),
                    width: 2,
                  ),
                  color: palette.shell,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.asset(assetPath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title.toUpperCase(),
                style: _academyDisplayStyle(
                  palette: palette,
                  size: 22,
                  color: accent,
                  weight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: _academyHudStyle(
                  palette: palette,
                  size: 12.6,
                  color: palette.textMuted,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.90),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    ctaLabel,
                    style: _academyHudStyle(
                      palette: palette,
                      color: foreground,
                      size: 12.4,
                      weight: FontWeight.w800,
                      letterSpacing: 1.0,
                      height: 1.0,
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

  Widget _buildQuizAcademyModeSetupPage({
    required _QuizAcademySetupLayoutSpec layout,
    required bool useMonochrome,
    required int currentPoolCount,
    required bool canStart,
  }) {
    final theme = Theme.of(context);
    final palette = _academyPalette(
      scheme: theme.colorScheme,
      useMonochrome: useMonochrome,
      isDark: theme.brightness == Brightness.dark,
    );
    final modeAccent = _academyQuizModeAccent(palette, _quizMode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final splitPanels =
            constraints.maxWidth >= 980 ||
            (layout.isLandscape && constraints.maxWidth >= 740);
        final modePanel = KeyedSubtree(
          key: _quizAcademyModePanelFocusKey,
          child: _academyPixelPanel(
            panelKey: const ValueKey<String>('quiz_setup_mode_panel'),
            palette: palette,
            accent: modeAccent,
            padding: EdgeInsets.all(layout.panelPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _academyPanelHeader(
                  palette: palette,
                  title: 'QUIZ MODE',
                  subtitle: '',
                  infoTitle: 'Quiz Modes',
                  infoMessage:
                      'Identify Opening Name asks you to choose the opening name from the shown position. Complete Opening Line asks you to choose the next move in the opening line. Every session uses 10 questions.',
                  infoButtonKey: const ValueKey<String>(
                    'quiz_setup_mode_panel_info_button',
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, deckConstraints) {
                    final stacked =
                        !layout.compactLandscape &&
                        deckConstraints.maxWidth <
                            (layout.compactPhoneLayout ? 420 : 520);
                    final cards = <Widget>[
                      _buildQuizAcademyModeCard(
                        cardKey: const ValueKey<String>(
                          'quiz_setup_mode_card_identify_opening_name',
                        ),
                        infoButtonKey: const ValueKey<String>(
                          'quiz_setup_mode_info_identify_opening_name',
                        ),
                        palette: palette,
                        dense: layout.compactLandscape,
                        assetPath: 'assets/academy/quiz_name.png',
                        title: _academyQuizModeTitle(GambitQuizMode.guessName),
                        infoMessage: _academyQuizModeInfoMessage(
                          GambitQuizMode.guessName,
                        ),
                        accent: palette.cyan,
                        selected:
                            !_quizStudyMode &&
                            _quizMode == GambitQuizMode.guessName,
                        compact: layout.compactPhoneLayout,
                        onTap: () => _selectQuizAcademyMode(
                          mode: GambitQuizMode.guessName,
                          studyMode: false,
                        ),
                      ),
                      _buildQuizAcademyModeCard(
                        cardKey: const ValueKey<String>(
                          'quiz_setup_mode_card_complete_opening_line',
                        ),
                        infoButtonKey: const ValueKey<String>(
                          'quiz_setup_mode_info_complete_opening_line',
                        ),
                        palette: palette,
                        dense: layout.compactLandscape,
                        assetPath: 'assets/academy/quiz_line.png',
                        title: _academyQuizModeTitle(GambitQuizMode.guessLine),
                        infoMessage: _academyQuizModeInfoMessage(
                          GambitQuizMode.guessLine,
                        ),
                        accent: palette.amber,
                        selected:
                            !_quizStudyMode &&
                            _quizMode == GambitQuizMode.guessLine,
                        compact: layout.compactPhoneLayout,
                        onTap: () => _selectQuizAcademyMode(
                          mode: GambitQuizMode.guessLine,
                          studyMode: false,
                        ),
                      ),
                    ];

                    if (stacked) {
                      return Column(
                        children: <Widget>[
                          cards[0],
                          SizedBox(height: layout.compactPhoneLayout ? 10 : 12),
                          cards[1],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: cards[0]),
                        SizedBox(width: layout.compactPhoneLayout ? 10 : 12),
                        Expanded(child: cards[1]),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
        final levelPanel = _buildQuizAcademyLevelPanel(
          useMonochrome: useMonochrome,
          layout: layout,
        );
        final missionPanel = _buildQuizAcademyMissionPanel(
          layout: layout,
          currentPoolCount: currentPoolCount,
          canStart: canStart,
        );

        if (!splitPanels) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              modePanel,
              SizedBox(height: layout.sectionGap),
              levelPanel,
              SizedBox(height: layout.sectionGap),
              missionPanel,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: layout.compactLandscape ? 11 : 10, child: modePanel),
            SizedBox(width: layout.sectionGap),
            Expanded(
              flex: 9,
              child: Column(
                children: <Widget>[
                  levelPanel,
                  SizedBox(height: layout.sectionGap),
                  missionPanel,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuizAcademyModeCard({
    required Key cardKey,
    required Key infoButtonKey,
    required _QuizAcademyPalette palette,
    required bool dense,
    required String assetPath,
    required String title,
    required String infoMessage,
    required Color accent,
    required bool selected,
    required bool compact,
    required VoidCallback onTap,
  }) {
    final contentPadding = dense
        ? 10.0
        : compact
        ? 12.0
        : 16.0;
    final sectionGap = dense
        ? 8.0
        : compact
        ? 10.0
        : 12.0;
    final footerGap = dense
        ? 10.0
        : compact
        ? 12.0
        : 16.0;
    final helperMinHeight = dense
        ? 16.0
        : compact
        ? 18.0
        : 24.0;
    final previewHeight = dense
        ? 92.0
        : compact
        ? 132.0
        : 192.0;
    final previewInset = dense
        ? 4.0
        : compact
        ? 6.0
        : 8.0;
    final cardColor = selected
        ? Color.alphaBlend(accent.withValues(alpha: 0.18), palette.panelAlt)
        : palette.panelAlt;
    final borderColor = selected
        ? accent.withValues(alpha: 0.90)
        : palette.line;

    return Material(
      key: cardKey,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          padding: EdgeInsets.all(contentPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(accent.withValues(alpha: 0.08), cardColor),
                cardColor,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.shadow,
                offset: const Offset(5, 5),
                blurRadius: 0,
              ),
              if (selected)
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 18,
                  spreadRadius: 1,
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
                    child: Text(
                      title,
                      style: _academyDisplayStyle(
                        palette: palette,
                        size: dense
                            ? 14.0
                            : compact
                            ? 15.5
                            : 18,
                        weight: FontWeight.w700,
                        letterSpacing: dense
                            ? 0.3
                            : compact
                            ? 0.45
                            : 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildQuizInfoButton(
                    buttonKey: infoButtonKey,
                    title: title,
                    message: infoMessage,
                  ),
                ],
              ),
              SizedBox(height: sectionGap),
              Container(
                height: previewHeight,
                decoration: BoxDecoration(
                  color: palette.shell,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.58),
                    width: 2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: palette.shadow.withValues(alpha: 0.18),
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color.alphaBlend(
                                accent.withValues(alpha: 0.16),
                                palette.shell,
                              ),
                              palette.shell,
                            ],
                          ),
                          image: DecorationImage(
                            image: AssetImage(assetPath),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            opacity: selected ? 0.24 : 0.18,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(previewInset),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: <Color>[
                              palette.shell.withValues(alpha: 0.56),
                              Colors.transparent,
                              Colors.transparent,
                              palette.shell.withValues(alpha: 0.44),
                            ],
                            stops: const <double>[0.0, 0.16, 0.84, 1.0],
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              accent.withValues(alpha: 0.10),
                              Colors.transparent,
                              palette.shell.withValues(alpha: 0.54),
                            ],
                            stops: const <double>[0.0, 0.48, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.shell.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.82),
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              selected
                                  ? Icons.check_circle_outline
                                  : Icons.play_circle_outline_rounded,
                              color: accent,
                              size: dense ? 17 : 19,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: sectionGap),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _academyTag(
                    palette: palette,
                    label: selected ? 'SELECTED' : 'SELECT',
                    accent: selected ? accent : palette.textMuted,
                  ),
                ],
              ),
              SizedBox(height: footerGap),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: helperMinHeight),
                child: Text(
                  selected
                      ? 'Ready to start with this quiz mode.'
                      : 'Tap to use this quiz mode.',
                  style: _academyHudStyle(
                    palette: palette,
                    size: compact ? 11.1 : 11.6,
                    color: selected ? accent : palette.textMuted,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: sectionGap),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      selected ? 'SELECTED MODE' : 'TAP TO SELECT',
                      style: _academyHudStyle(
                        palette: palette,
                        size: 10.8,
                        color: selected ? accent : palette.textMuted,
                        weight: FontWeight.w800,
                        letterSpacing: 0.9,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_outline
                        : Icons.play_arrow_rounded,
                    color: selected ? accent : palette.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizAcademyMetricChip({
    _QuizAcademyPalette? palette,
    required String label,
    required String value,
    required Color accent,
    IconData? icon,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final effectivePalette =
        palette ??
        _academyPalette(
          scheme: theme.colorScheme,
          useMonochrome:
              context.read<AppThemeProvider>().isMonochrome ||
              _isCinematicThemeEnabled,
          isDark: theme.brightness == Brightness.dark,
        );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.40), width: 2),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: compact ? 13 : 15, color: accent),
          ],
          Text(
            '$label: $value',
            style: _academyHudStyle(
              palette: effectivePalette,
              size: compact ? 10.8 : 11.6,
              color: effectivePalette.text,
              weight: FontWeight.w800,
              letterSpacing: 0.7,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizAcademyAtmosphere(bool useMonochrome) {
    final theme = Theme.of(context);
    final palette = _academyPalette(
      scheme: theme.colorScheme,
      useMonochrome: useMonochrome,
      isDark: theme.brightness == Brightness.dark,
    );
    return _academyBackdropLayer(palette: palette);
  }

  Widget _buildQuizAcademyLevelPanel({
    required bool useMonochrome,
    required _QuizAcademySetupLayoutSpec layout,
  }) {
    final theme = Theme.of(context);
    final palette = _academyPalette(
      scheme: theme.colorScheme,
      useMonochrome: useMonochrome,
      isDark: theme.brightness == Brightness.dark,
    );

    return _academyPixelPanel(
      panelKey: const ValueKey<String>('quiz_setup_level_panel'),
      palette: palette,
      accent: _quizDifficultyColor(_quizDifficulty),
      padding: EdgeInsets.all(layout.panelPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _academyPanelHeader(
            palette: palette,
            title: 'LEVEL',
            subtitle: '',
            infoTitle: 'Quiz Levels',
            infoMessage: _quizSetupDifficultyPanelMessage(),
            infoButtonKey: const ValueKey<String>(
              'quiz_setup_level_info_button',
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 360;
              final cards = QuizDifficulty.values
                  .map(
                    (difficulty) => _buildQuizAcademyLevelCard(
                      difficulty: difficulty,
                      useMonochrome: useMonochrome,
                      compact: layout.compactPhoneLayout,
                    ),
                  )
                  .toList(growable: false);

              if (!twoColumns) {
                return Column(
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < cards.length;
                      index++
                    ) ...<Widget>[
                      cards[index],
                      if (index < cards.length - 1)
                        SizedBox(height: layout.compactPhoneLayout ? 10 : 12),
                    ],
                  ],
                );
              }

              return Column(
                children: <Widget>[
                  for (
                    var rowStart = 0;
                    rowStart < cards.length;
                    rowStart += 2
                  ) ...<Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: cards[rowStart]),
                        SizedBox(width: layout.compactPhoneLayout ? 10 : 12),
                        Expanded(child: cards[rowStart + 1]),
                      ],
                    ),
                    if (rowStart + 2 < cards.length)
                      SizedBox(height: layout.compactPhoneLayout ? 10 : 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuizAcademyLevelCard({
    required QuizDifficulty difficulty,
    required bool useMonochrome,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final palette = _academyPalette(
      scheme: theme.colorScheme,
      useMonochrome: useMonochrome,
      isDark: theme.brightness == Brightness.dark,
    );
    final accent = _quizDifficultyColor(difficulty);
    final unlocked = _quizDifficultyUnlocked(difficulty);
    final completed = _quizAcademyProgress.isDifficultyCompleted(difficulty);
    final selected = _quizDifficulty == difficulty;
    final previousDifficulty = difficulty == QuizDifficulty.values.first
        ? null
        : QuizDifficulty.values[difficulty.index - 1];

    String statusLabel;
    Color statusColor;
    if (selected) {
      statusLabel = 'Selected';
      statusColor = accent;
    } else if (completed) {
      statusLabel = 'Completed';
      statusColor = palette.emerald;
    } else if (unlocked) {
      statusLabel = 'Available';
      statusColor = palette.cyan;
    } else {
      statusLabel = 'Locked';
      statusColor = palette.textMuted;
    }

    final helperText = unlocked
        ? (selected
              ? 'Ready to start at this level.'
              : completed
              ? 'Completed already. Tap to revisit it.'
              : 'Tap to select this level.')
        : 'Unlock with ${_quizAcademyProgress.remainingPerfectSessionsFor(previousDifficulty!)} perfect ${_quizSetupDifficultyLabel(previousDifficulty)} runs.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked
            ? () => _setQuizDifficulty(difficulty)
            : () => unawaited(_showQuizDifficultyLockedDialog(difficulty)),
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(
                  accent.withValues(
                    alpha: selected
                        ? (useMonochrome ? 0.12 : 0.18)
                        : (useMonochrome ? 0.06 : 0.08),
                  ),
                  palette.panelAlt,
                ),
                palette.panelAlt,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.72) : palette.line,
              width: 3,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.shadow,
                offset: const Offset(5, 5),
                blurRadius: 0,
              ),
              if (selected)
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 128 : 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.55),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _quizAcademyBracketIcon(difficulty),
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _quizSetupDifficultyLabel(difficulty),
                            style: _academyDisplayStyle(
                              palette: palette,
                              size: compact ? 16 : 18,
                              weight: FontWeight.w700,
                              letterSpacing: compact ? 0.45 : 0.7,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _academyTag(
                            palette: palette,
                            label: statusLabel.toUpperCase(),
                            accent: statusColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      unlocked
                          ? Icons.play_arrow_rounded
                          : Icons.lock_outline_rounded,
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  helperText,
                  style: _academyHudStyle(
                    palette: palette,
                    size: compact ? 10.9 : 11.4,
                    color: unlocked && selected ? accent : palette.textMuted,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizAcademySelectionTile({
    required _QuizAcademyPalette palette,
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.10),
          palette.panelAlt,
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.42), width: 2),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: accent.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: _academyHudStyle(
                    palette: palette,
                    size: 10.5,
                    color: palette.textMuted,
                    weight: FontWeight.w800,
                    letterSpacing: 0.9,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: _academyDisplayStyle(
                    palette: palette,
                    size: 16,
                    weight: FontWeight.w700,
                    letterSpacing: 0.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizAcademyStartButton({
    required Key buttonKey,
    required _QuizAcademyPalette palette,
    required String label,
    required Color accent,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    final foreground = accent.computeLuminance() > 0.55
        ? const Color(0xFF081015)
        : Colors.white;
    final effectiveForeground = enabled
        ? foreground
        : foreground.withValues(alpha: 0.55);
    final effectiveAccent = enabled ? accent : accent.withValues(alpha: 0.46);

    return Material(
      key: buttonKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(
                  palette.boardLight.withValues(alpha: 0.18),
                  effectiveAccent,
                ),
                effectiveAccent,
              ],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: effectiveAccent.withValues(alpha: enabled ? 0.96 : 0.42),
              width: 2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.shadow.withValues(alpha: enabled ? 0.26 : 0.14),
                offset: const Offset(5, 5),
                blurRadius: 0,
              ),
              if (enabled)
                BoxShadow(
                  color: effectiveAccent.withValues(alpha: 0.20),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: effectiveForeground.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: effectiveForeground.withValues(alpha: 0.26),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 24,
                  color: effectiveForeground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'START QUIZ',
                      style: _academyHudStyle(
                        palette: palette,
                        color: effectiveForeground.withValues(alpha: 0.88),
                        size: 10.6,
                        weight: FontWeight.w800,
                        letterSpacing: 1.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      style: _academyDisplayStyle(
                        palette: palette,
                        color: effectiveForeground,
                        size: 17,
                        weight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                size: 24,
                color: effectiveForeground.withValues(alpha: 0.92),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizAcademyMissionPanel({
    required _QuizAcademySetupLayoutSpec layout,
    required int currentPoolCount,
    required bool canStart,
  }) {
    final theme = Theme.of(context);
    final palette = _academyPalette(
      scheme: theme.colorScheme,
      useMonochrome:
          context.read<AppThemeProvider>().isMonochrome ||
          _isCinematicThemeEnabled,
      isDark: theme.brightness == Brightness.dark,
    );
    final modeAccent = _academyQuizModeAccent(palette, _quizMode);
    final modeIcon = _academyQuizModeIcon(_quizMode);
    final modeTitle = _academyQuizModeTitle(_quizMode);
    final difficultyColor = _quizDifficultyColor(_quizDifficulty);

    return _academyPixelPanel(
      panelKey: const ValueKey<String>('quiz_setup_mission_panel'),
      palette: palette,
      accent: modeAccent,
      padding: EdgeInsets.all(layout.panelPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _academyPanelHeader(
            palette: palette,
            title: 'START QUIZ',
            subtitle: '',
            infoTitle: 'Quiz Session Details',
            infoMessage:
                'Every quiz uses 10 fixed questions. Selected mode: $modeTitle. Selected level: ${_quizSetupDifficultyLabel(_quizDifficulty)}. Playable lines available right now: $currentPoolCount. Academy progress only advances on a 100% perfect finish.',
            infoButtonKey: const ValueKey<String>(
              'quiz_setup_mission_info_button',
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;
              final modeSummary = _buildQuizAcademySelectionTile(
                palette: palette,
                label: 'Mode',
                value: modeTitle,
                icon: modeIcon,
                accent: modeAccent,
              );
              final levelSummary = _buildQuizAcademySelectionTile(
                palette: palette,
                label: 'Level',
                value: _quizSetupDifficultyLabel(_quizDifficulty),
                icon: _quizAcademyBracketIcon(_quizDifficulty),
                accent: difficultyColor,
              );

              if (stacked) {
                return Column(
                  children: <Widget>[
                    modeSummary,
                    const SizedBox(height: 10),
                    levelSummary,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: modeSummary),
                  const SizedBox(width: 10),
                  Expanded(child: levelSummary),
                ],
              );
            },
          ),
          if (!canStart) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.signal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: palette.signal.withValues(alpha: 0.42),
                  width: 2,
                ),
              ),
              child: Text(
                'The selected level does not have enough playable lines loaded yet. Try another level or let the opening library finish loading.',
                style: _academyHudStyle(
                  palette: palette,
                  size: 12.0,
                  color: palette.signal,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _buildQuizAcademyStartButton(
              buttonKey: const ValueKey<String>('quiz_setup_start_button'),
              palette: palette,
              label: _academyQuizModeStartLabel(_quizMode),
              accent: modeAccent,
              onTap: canStart ? _startQuizSession : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuizInfoDialog({
    required String title,
    required String message,
  }) async {
    await _showQuizAcademyNoticeDialog(
      title: title,
      message: message,
      tagLabel: 'INFO',
      actionLabel: 'CLOSE',
      icon: Icons.info_outline_rounded,
    );
  }

  Widget _buildQuizInfoButton({
    Key? buttonKey,
    required String title,
    required String message,
    double size = 28,
    double iconSize = 15,
    Color? accentOverride,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final palette = _academyPalette(
      scheme: theme.colorScheme,
      useMonochrome: useMonochrome,
      isDark: isDark,
    );
    final accent = accentOverride ?? palette.cyan;

    return Tooltip(
      key: buttonKey,
      message: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              unawaited(_showQuizInfoDialog(title: title, message: message)),
          borderRadius: BorderRadius.circular(4),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.08),
                palette.shell,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: accent.withValues(alpha: 0.46),
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.shadow.withValues(alpha: 0.14),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: iconSize,
              color: accent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizTopIconButton({
    Key? buttonKey,
    required _QuizAcademyPalette palette,
    required IconData icon,
    required Color accent,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        key: buttonKey,
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
              border: Border.all(
                color: accent.withValues(alpha: 0.48),
                width: 2,
              ),
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

  @override
  Widget _buildGambitQuizScreen() {
    final media = MediaQuery.of(context);
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
    final isLandscape = media.orientation == Orientation.landscape;
    final reviewEntry = _quizReviewIndex == null
        ? null
        : _quizReviewHistory[_quizReviewIndex!];
    final reviewMode = reviewEntry != null;
    final displayedQuizMode = reviewEntry?.mode ?? _quizMode;
    final displayedPrompt = reviewEntry?.prompt ?? _quizPrompt;
    final displayedPromptFocus = reviewEntry?.promptFocus ?? _quizPromptFocus;
    final displayedOptions = reviewEntry?.options ?? _quizOptions;
    final displayedCorrectIndex =
        reviewEntry?.correctIndex ?? _quizCorrectIndex;
    final displayedSelectedIndex =
        reviewEntry?.selectedIndex ?? _quizSelectedIndex;
    final displayedContinuation =
        reviewEntry?.continuation ?? _quizContinuation;
    final previewContinuation =
        !reviewMode &&
            !_quizAnswered &&
            displayedQuizMode == GambitQuizMode.guessLine
        ? _quizPreviewContinuation
        : const <EngineLine>[];
    final displayedWhiteToMove = reviewEntry?.whiteToMove ?? _quizWhiteToMove;
    final displayedShownPly = reviewEntry?.shownPly ?? _quizShownPly;
    final displayedBoardState = reviewMode
        ? reviewEntry.boardState
        : (_quizPlayBoard.isNotEmpty ? _quizPlayBoard : _quizBoardState);
    final answersLocked = reviewMode || _quizAnswered;
    final hasQuizBoard =
        displayedBoardState.isNotEmpty && displayedContinuation.isNotEmpty;
    final revealContinuation =
        hasQuizBoard &&
        (displayedQuizMode == GambitQuizMode.guessName ||
            answersLocked ||
            previewContinuation.isNotEmpty);
    final isCorrectAnswer =
        answersLocked && displayedSelectedIndex == displayedCorrectIndex;
    final safeHeight = media.size.height - media.padding.vertical;
    final isTabletLayout =
        media.size.width >= 920 ||
        (media.size.width >= 760 && safeHeight >= 700);
    final compactPhoneLayout = !isTabletLayout;
    final compactPortraitPlayLayout = compactPhoneLayout && !isLandscape;
    final compactLandscapePlayLayout = compactPhoneLayout && isLandscape;
    final compactPlayLayout = compactPhoneLayout;
    final wideSideBySideLayout =
        isLandscape && hasQuizBoard && media.size.width >= 920;
    final pageHorizontalPadding = compactLandscapePlayLayout
        ? 6.0
        : compactPortraitPlayLayout
        ? 8.0
        : compactPlayLayout
        ? 12.0
        : 16.0;
    final pageTopPadding = compactLandscapePlayLayout
        ? 6.0
        : compactPortraitPlayLayout
        ? 4.0
        : 12.0;
    final pageBottomPadding = compactLandscapePlayLayout ? 8.0 : 16.0;
    final viewportPadding = _quizAcademyViewportPadding(media);
    final quizPadding = EdgeInsets.fromLTRB(
      pageHorizontalPadding + viewportPadding.left,
      pageTopPadding + viewportPadding.top,
      pageHorizontalPadding + viewportPadding.right,
      pageBottomPadding + viewportPadding.bottom,
    );
    final routeAccent = _academyQuizModeAccent(palette, displayedQuizMode);
    final topToContentGap = compactLandscapePlayLayout
        ? 6.0
        : compactPortraitPlayLayout
        ? 8.0
        : 12.0;
    final contentGap = compactLandscapePlayLayout
        ? 8.0
        : compactPortraitPlayLayout
        ? 8.0
        : compactPlayLayout
        ? 10.0
        : 12.0;
    final densePanelPadding = compactLandscapePlayLayout
        ? 4.0
        : compactPortraitPlayLayout
        ? 8.0
        : compactPlayLayout
        ? 10.0
        : 12.0;
    final compactOptionSpacing = compactLandscapePlayLayout
        ? 4.0
        : compactPlayLayout
        ? 8.0
        : 10.0;
    final topPanelPadding = compactLandscapePlayLayout
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
        : compactPortraitPlayLayout
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
        : compactPlayLayout
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
        : const EdgeInsets.all(10);
    final topPanelGap = compactLandscapePlayLayout ? 4.0 : 8.0;
    final optionButtonPadding = compactLandscapePlayLayout
        ? const EdgeInsets.fromLTRB(8, 5, 8, 5)
        : compactPlayLayout
        ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
        : const EdgeInsets.fromLTRB(10, 10, 10, 10);
    final optionBadgeSize = compactLandscapePlayLayout
        ? 28.0
        : compactPlayLayout
        ? 30.0
        : 34.0;
    final questionCounter = min(
      _quizSessionAnswered + (_quizAnswered ? 0 : 1),
      _quizQuestionsTarget,
    );
    final headerTitle = reviewMode
        ? 'Round Review'
        : _academyQuizModeTitle(displayedQuizMode);
    final headerSubtitle = reviewMode
        ? 'Step through earlier answers, compare continuations, and jump back to the live round when you are ready.'
        : displayedQuizMode == GambitQuizMode.guessLine
        ? 'Tap an option to preview its continuation on the board, then lock in your answer.'
        : 'Read the board, pick the right opening name, and keep the streak moving.';
    final questionLead = displayedQuizMode == GambitQuizMode.guessLine
        ? 'Complete This Opening Line'
        : 'Name This Opening';
    final boardTitle = reviewMode ? 'Review Board' : 'Board Preview';
    final boardInstruction = reviewMode
        ? 'Compare the stored continuation with the answer you selected for this earlier round.'
        : displayedQuizMode == GambitQuizMode.guessLine
        ? 'Selecting a line previews its continuation directly on the board.'
        : 'Read the position first, then choose the matching opening name.';
    final questionInstruction = reviewMode
        ? 'Review the saved answer choices, then return to the live round when you are ready.'
        : displayedQuizMode == GambitQuizMode.guessLine
        ? 'Tap each candidate to preview its continuation on the board before you commit.'
        : 'Study the board and choose the opening name that matches it.';
    final compactStatusSummary = <String>[
      headerTitle.toUpperCase(),
      'Q $questionCounter/$_quizQuestionsTarget',
      'SCORE $_quizScore',
      'STREAK $_quizStreak',
      if (reviewMode &&
          _quizReviewIndex != null &&
          _quizReviewHistory.isNotEmpty)
        'REVIEW ${_quizReviewIndex! + 1}/${_quizReviewHistory.length}',
    ].join('  •  ');
    final quizInfoMessage = <String>[
      headerSubtitle,
      boardInstruction,
      questionInstruction,
      if (displayedPromptFocus.isNotEmpty) displayedPromptFocus,
    ].where((segment) => segment.trim().isNotEmpty).join('\n\n');
    final topFeedbackMessage = reviewMode ? null : _quizFeedbackOverlayMessage;
    final showQuizFeedbackOverlay =
        topFeedbackMessage != null && topFeedbackMessage.isNotEmpty;
    final sessionBodyStyle = _academyHudStyle(
      palette: palette,
      size: 12.7,
      weight: FontWeight.w700,
      color: palette.text,
      letterSpacing: 0.28,
    );
    final sessionDetailStyle = _academyHudStyle(
      palette: palette,
      size: 11.4,
      weight: FontWeight.w600,
      color: palette.textMuted,
      letterSpacing: 0.22,
    );

    if (!_quizSessionStarted) {
      return _buildQuizAcademySetupScreen();
    }

    Widget buildQuizTopPanel() {
      final styleButton = _buildQuizTopIconButton(
        palette: palette,
        icon: Icons.palette_outlined,
        accent: palette.cyan,
        tooltip: 'Style',
        onTap: _openAppearanceSettings,
      );
      final statsButton = _buildQuizTopIconButton(
        palette: palette,
        icon: Icons.insights_outlined,
        accent: palette.amber,
        tooltip: 'Stats',
        onTap: _openQuizStatsSheet,
      );
      final badges = <Widget>[
        _academyTag(
          palette: palette,
          label: _academyQuizModeTitle(displayedQuizMode).toUpperCase(),
          accent: routeAccent,
        ),
        if (!compactPlayLayout)
          _academyTag(
            palette: palette,
            label:
                '${_quizAcademyBracketShortName(_quizDifficulty).toUpperCase()} BRACKET',
            accent: palette.textMuted,
          ),
        _academyTag(
          palette: palette,
          label: 'Q $questionCounter/$_quizQuestionsTarget',
          accent: palette.emerald,
        ),
        _academyTag(
          palette: palette,
          label: 'SCORE $_quizScore',
          accent: palette.amber,
        ),
        _academyTag(
          palette: palette,
          label: 'STREAK $_quizStreak',
          accent: palette.cyan,
        ),
        if (reviewMode &&
            _quizReviewIndex != null &&
            _quizReviewHistory.isNotEmpty)
          _academyTag(
            palette: palette,
            label:
                'REVIEW ${_quizReviewIndex! + 1}/${_quizReviewHistory.length}',
            accent: palette.signal,
          ),
      ];

      return _academyPixelPanel(
        panelKey: const ValueKey<String>('quiz_session_top_panel'),
        palette: palette,
        accent: routeAccent,
        fillColor: palette.panelAlt,
        padding: topPanelPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _academyHudButton(
                    buttonKey: const ValueKey<String>(
                      'quiz_session_back_button',
                    ),
                    palette: palette,
                    icon: Icons.arrow_back_rounded,
                    label: compactPlayLayout ? 'BACK' : 'BACK TO SETUP',
                    accent: palette.text,
                    onTap: _returnToQuizSetup,
                  ),
                ),
                if (compactLandscapePlayLayout) ...<Widget>[
                  SizedBox(width: topPanelGap),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          key: const ValueKey<String>(
                            'quiz_session_compact_summary',
                          ),
                          compactStatusSummary,
                          maxLines: 1,
                          softWrap: false,
                          style: _academyHudStyle(
                            palette: palette,
                            size: 10.8,
                            weight: FontWeight.w700,
                            color: palette.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: topPanelGap),
                ] else if (compactPlayLayout) ...<Widget>[
                  SizedBox(width: topPanelGap),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          key: const ValueKey<String>(
                            'quiz_session_compact_summary',
                          ),
                          'Q $questionCounter/$_quizQuestionsTarget',
                          maxLines: 1,
                          softWrap: false,
                          style: _academyHudStyle(
                            palette: palette,
                            size: 11.0,
                            weight: FontWeight.w800,
                            color: palette.emerald,
                            letterSpacing: 0.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: topPanelGap),
                ] else ...<Widget>[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      headerTitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: _academyDisplayStyle(
                        palette: palette,
                        size: 17,
                        weight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                styleButton,
                SizedBox(width: topPanelGap),
                statsButton,
                SizedBox(width: topPanelGap),
                _buildQuizInfoButton(
                  buttonKey: const ValueKey<String>('quiz_session_info_button'),
                  title: headerTitle,
                  message: quizInfoMessage,
                  size: 42,
                  iconSize: 18,
                  accentOverride: routeAccent,
                ),
              ],
            ),
            if (!compactPlayLayout) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: badges),
            ],
          ],
        ),
      );
    }

    Widget buildQuizFeedbackOverlayPanel() {
      final isCorrectOverlay = _quizFeedbackOverlayCorrect;
      final accent = isCorrectOverlay == true
          ? palette.emerald
          : isCorrectOverlay == false
          ? palette.signal
          : routeAccent;
      final icon = isCorrectOverlay == true
          ? Icons.check_circle_rounded
          : Icons.info_outline_rounded;

      return Positioned.fill(
        child: _academyPixelPanel(
          panelKey: const ValueKey<String>('quiz_session_feedback_overlay'),
          palette: palette,
          accent: accent,
          fillColor: Color.alphaBlend(
            palette.shell.withValues(alpha: 0.16),
            palette.panelAlt,
          ),
          padding: topPanelPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: compactPlayLayout ? 18 : 20, color: accent),
              SizedBox(width: compactPlayLayout ? 8 : 10),
              Expanded(
                child: Text(
                  topFeedbackMessage!,
                  maxLines: compactPlayLayout ? 1 : 2,
                  softWrap: !compactPlayLayout,
                  overflow: TextOverflow.ellipsis,
                  style: _academyHudStyle(
                    palette: palette,
                    size: compactPlayLayout ? 11.2 : 11.8,
                    weight: FontWeight.w800,
                    color: palette.text,
                    letterSpacing: 0.22,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildQuizBoardCard({double? maxBoardSize}) {
      final reverse =
          _perspective == BoardPerspective.black ||
          (_perspective == BoardPerspective.auto && !displayedWhiteToMove);
      final showingLivePreview =
          !answersLocked &&
          !reviewMode &&
          displayedQuizMode == GambitQuizMode.guessLine &&
          previewContinuation.isNotEmpty;
      final visibleArrows = showingLivePreview
          ? previewContinuation
          : !answersLocked
          ? displayedContinuation
          : reviewMode
          ? displayedContinuation
          : displayedContinuation
                .take(
                  _quizPlayArrowCount == 0
                      ? displayedContinuation.length
                      : _quizPlayArrowCount,
                )
                .toList();
      final boardAccent = showingLivePreview
          ? palette.amber
          : reviewMode
          ? palette.signal
          : answersLocked
          ? (isCorrectAnswer ? palette.emerald : palette.signal)
          : routeAccent;
      final boardBadges = <Widget>[
        _academyTag(
          palette: palette,
          label: 'POSITION $displayedShownPly PLY',
          accent: boardAccent,
        ),
        _academyTag(
          palette: palette,
          label: visibleArrows.isEmpty
              ? 'POSITION ONLY'
              : '${visibleArrows.length} MOVE${visibleArrows.length == 1 ? '' : 'S'} SHOWN',
          accent: boardAccent,
        ),
        if (showingLivePreview)
          _academyTag(
            palette: palette,
            label: 'PREVIEW ACTIVE',
            accent: palette.amber,
          ),
        if (answersLocked && !reviewMode)
          _academyTag(
            palette: palette,
            label: isCorrectAnswer ? 'CORRECT LOCK-IN' : 'ANSWER LOCKED',
            accent: isCorrectAnswer ? palette.emerald : palette.signal,
          ),
      ];
      final compactBoardBadges = const <Widget>[];

      return _academyPixelPanel(
        panelKey: const ValueKey<String>('quiz_session_board_card'),
        palette: palette,
        accent: boardAccent,
        fillColor: palette.panel,
        padding: EdgeInsets.all(densePanelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!compactPlayLayout) ...<Widget>[
              Text(
                boardTitle.toUpperCase(),
                style: _academyHudStyle(
                  palette: palette,
                  size: 11.8,
                  weight: FontWeight.w800,
                  color: boardAccent,
                  letterSpacing: 0.95,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(boardInstruction, style: sessionDetailStyle),
              const SizedBox(height: 10),
            ],
            Center(
              child: SizedBox(
                key: const ValueKey<String>('quiz_session_board_square'),
                width: maxBoardSize,
                height: maxBoardSize,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.panelAlt,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: palette.line, width: 2),
                    ),
                    child: LayoutBuilder(
                      builder: (context, bc) {
                        final sqSize = bc.maxWidth / 8;
                        final pieceSize = sqSize;
                        Offset? flyFromPx, flyToPx;
                        if (_quizFlyFrom != null && _quizFlyTo != null) {
                          flyFromPx = _squareToGridOffset(
                            _quizFlyFrom!,
                            bc.maxWidth,
                            reverse,
                          );
                          flyToPx = _squareToGridOffset(
                            _quizFlyTo!,
                            bc.maxWidth,
                            reverse,
                          );
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildQuizBoard(
                              boardState: displayedBoardState,
                              whiteToMove: displayedWhiteToMove,
                            ),
                            if (revealContinuation && visibleArrows.isNotEmpty)
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) => IgnorePointer(
                                  child: CustomPaint(
                                    size: Size.infinite,
                                    painter: EnergyArrowPainter(
                                      lines: visibleArrows,
                                      bestEval: 0,
                                      progress: _pulseController.value,
                                      reverse: reverse,
                                      showSequenceNumbers: true,
                                      overrideColor: boardAccent.withValues(
                                        alpha: 0.92,
                                      ),
                                      staticArrowStyle: true,
                                    ),
                                  ),
                                ),
                              ),
                            if (!reviewMode &&
                                flyFromPx != null &&
                                flyToPx != null &&
                                _quizFlyPiece != null)
                              Positioned(
                                left:
                                    ui.lerpDouble(
                                      flyFromPx.dx,
                                      flyToPx.dx,
                                      _quizFlyProgress.clamp(0.0, 1.0),
                                    )! -
                                    (pieceSize / 2),
                                top:
                                    ui.lerpDouble(
                                      flyFromPx.dy,
                                      flyToPx.dy,
                                      _quizFlyProgress.clamp(0.0, 1.0),
                                    )! -
                                    (pieceSize / 2),
                                width: pieceSize,
                                height: pieceSize,
                                child: IgnorePointer(
                                  child: Center(
                                    child: _pieceImage(
                                      _quizFlyPiece!,
                                      width: pieceSize,
                                      height: pieceSize,
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
            if ((compactPlayLayout ? compactBoardBadges : boardBadges)
                .isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: compactPlayLayout ? compactBoardBadges : boardBadges,
              ),
            ],
          ],
        ),
      );
    }

    List<Widget> buildQuizOptionButtons() {
      if (displayedOptions.isEmpty) {
        return <Widget>[
          Text('Loading round options...', style: sessionDetailStyle),
        ];
      }

      return <Widget>[
        for (int i = 0; i < displayedOptions.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == displayedOptions.length - 1
                  ? 0
                  : compactOptionSpacing,
            ),
            child: Material(
              key: ValueKey<String>('quiz_session_option_$i'),
              color: Colors.transparent,
              child: InkWell(
                onTap: answersLocked ? null : () => _selectQuizAnswerOption(i),
                borderRadius: BorderRadius.circular(4),
                child: Ink(
                  width: double.infinity,
                  padding: optionButtonPadding,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      (answersLocked
                              ? (i == displayedCorrectIndex
                                    ? palette.emerald
                                    : (i == displayedSelectedIndex
                                          ? palette.signal
                                          : palette.line))
                              : (i == displayedSelectedIndex
                                    ? routeAccent
                                    : palette.line))
                          .withValues(
                            alpha:
                                (answersLocked && i == displayedCorrectIndex) ||
                                    i == displayedSelectedIndex
                                ? 0.18
                                : 0.08,
                          ),
                      palette.panelAlt,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: answersLocked && i == displayedCorrectIndex
                          ? palette.emerald.withValues(alpha: 0.94)
                          : answersLocked && i == displayedSelectedIndex
                          ? palette.signal.withValues(alpha: 0.86)
                          : !answersLocked && i == displayedSelectedIndex
                          ? routeAccent.withValues(alpha: 0.94)
                          : palette.line,
                      width: 2,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: palette.shadow.withValues(alpha: 0.18),
                        offset: const Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: optionBadgeSize,
                        height: optionBadgeSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(
                            (answersLocked && i == displayedCorrectIndex
                                    ? palette.emerald
                                    : answersLocked &&
                                          i == displayedSelectedIndex
                                    ? palette.signal
                                    : !answersLocked &&
                                          i == displayedSelectedIndex
                                    ? routeAccent
                                    : palette.shell)
                                .withValues(alpha: 0.22),
                            palette.panel,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: answersLocked && i == displayedCorrectIndex
                                ? palette.emerald.withValues(alpha: 0.86)
                                : answersLocked && i == displayedSelectedIndex
                                ? palette.signal.withValues(alpha: 0.76)
                                : !answersLocked && i == displayedSelectedIndex
                                ? routeAccent.withValues(alpha: 0.86)
                                : palette.line,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: _academyHudStyle(
                            palette: palette,
                            color: answersLocked && i == displayedCorrectIndex
                                ? palette.emerald
                                : answersLocked && i == displayedSelectedIndex
                                ? palette.signal
                                : !answersLocked && i == displayedSelectedIndex
                                ? routeAccent
                                : palette.text,
                            size: compactLandscapePlayLayout
                                ? 11.6
                                : compactPlayLayout
                                ? 12
                                : 13,
                            weight: FontWeight.w800,
                            letterSpacing: 0.8,
                            height: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: compactLandscapePlayLayout
                            ? 6
                            : compactPlayLayout
                            ? 8
                            : 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            displayedQuizMode == GambitQuizMode.guessLine
                                ? DefaultTextStyle.merge(
                                    style: const TextStyle(
                                      fontFamily: _quizAcademyHudFontFamily,
                                      fontFamilyFallback: <String>[
                                        'Courier New',
                                      ],
                                    ),
                                    child: _buildMoveSequenceText(
                                      displayedOptions[i],
                                      fontSize: compactPlayLayout ? 12.6 : 13.6,
                                      color: palette.text,
                                      fontWeight:
                                          answersLocked &&
                                              i == displayedCorrectIndex
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      maxLines: compactLandscapePlayLayout
                                          ? 2
                                          : compactPlayLayout
                                          ? 3
                                          : 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : Text(
                                    displayedOptions[i],
                                    maxLines: compactPlayLayout ? 2 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: _academyHudStyle(
                                      palette: palette,
                                      color: palette.text,
                                      size: compactLandscapePlayLayout
                                          ? 12.0
                                          : compactPlayLayout
                                          ? 12.6
                                          : 13.4,
                                      weight:
                                          answersLocked &&
                                              i == displayedCorrectIndex
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      letterSpacing: 0.24,
                                      height: compactLandscapePlayLayout
                                          ? 1.12
                                          : compactPlayLayout
                                          ? 1.18
                                          : 1.25,
                                    ),
                                  ),
                            if (!compactPlayLayout) ...<Widget>[
                              SizedBox(height: compactPlayLayout ? 4 : 5),
                              Text(
                                answersLocked
                                    ? i == displayedCorrectIndex
                                          ? 'Correct answer'
                                          : i == displayedSelectedIndex
                                          ? 'Your answer'
                                          : 'Reviewed option'
                                    : i == displayedSelectedIndex
                                    ? displayedQuizMode ==
                                              GambitQuizMode.guessLine
                                          ? 'Previewing'
                                          : 'Selected'
                                    : displayedQuizMode ==
                                          GambitQuizMode.guessLine
                                    ? 'Tap to preview'
                                    : 'Tap to select',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _academyHudStyle(
                                  palette: palette,
                                  color:
                                      answersLocked &&
                                          i == displayedCorrectIndex
                                      ? palette.emerald
                                      : answersLocked &&
                                            i == displayedSelectedIndex
                                      ? palette.signal
                                      : !answersLocked &&
                                            i == displayedSelectedIndex
                                      ? routeAccent
                                      : palette.textMuted,
                                  size: compactLandscapePlayLayout
                                      ? 9.8
                                      : compactPlayLayout
                                      ? 10.2
                                      : 11,
                                  weight: FontWeight.w700,
                                  letterSpacing: 0.22,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(
                        width: compactLandscapePlayLayout
                            ? 6
                            : compactPlayLayout
                            ? 8
                            : 10,
                      ),
                      Icon(
                        answersLocked
                            ? i == displayedCorrectIndex
                                  ? Icons.check_circle_rounded
                                  : i == displayedSelectedIndex
                                  ? Icons.cancel_rounded
                                  : Icons.circle_outlined
                            : i == displayedSelectedIndex
                            ? (displayedQuizMode == GambitQuizMode.guessLine
                                  ? Icons.play_circle_fill_rounded
                                  : Icons.radio_button_checked)
                            : Icons.radio_button_unchecked,
                        size: compactLandscapePlayLayout
                            ? 16
                            : compactPlayLayout
                            ? 18
                            : 20,
                        color: answersLocked && i == displayedCorrectIndex
                            ? palette.emerald
                            : answersLocked && i == displayedSelectedIndex
                            ? palette.signal
                            : !answersLocked && i == displayedSelectedIndex
                            ? routeAccent
                            : palette.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ];
    }

    Widget buildQuizPrimaryActionButton() {
      final canSubmitGuess =
          _quizSelectedIndex >= 0 && _quizSelectedIndex < _quizOptions.length;
      return _academyHudButton(
        buttonKey: const ValueKey<String>('quiz_session_primary_action'),
        palette: palette,
        icon: reviewMode
            ? Icons.history_toggle_off_rounded
            : !_quizAnswered
            ? Icons.check_rounded
            : (_quizSessionAnswered >= _quizQuestionsTarget
                  ? Icons.flag_rounded
                  : Icons.navigate_next_rounded),
        label: reviewMode
            ? 'RETURN TO CURRENT'
            : !_quizAnswered
            ? 'LOCK GUESS'
            : (_quizSessionAnswered >= _quizQuestionsTarget
                  ? 'FINISH SESSION'
                  : 'NEXT QUESTION'),
        accent: reviewMode
            ? palette.cyan
            : !_quizAnswered
            ? routeAccent
            : (_quizSessionAnswered >= _quizQuestionsTarget
                  ? palette.amber
                  : palette.emerald),
        onTap: reviewMode || _quizAnswered || canSubmitGuess
            ? _handleQuizPrimaryAction
            : null,
        filled: true,
      );
    }

    Widget buildQuizQuestionPanel({
      required bool useScrollableOptions,
      bool pinFooter = false,
    }) {
      final questionAccent = displayedQuizMode == GambitQuizMode.guessLine
          ? palette.amber
          : routeAccent;
      final selectedLabel =
          displayedSelectedIndex >= 0 &&
              displayedSelectedIndex < displayedOptions.length
          ? 'SELECTED ${String.fromCharCode(65 + displayedSelectedIndex)}'
          : answersLocked
          ? 'ROUND LOCKED'
          : displayedQuizMode == GambitQuizMode.guessLine
          ? 'PICK A LINE'
          : 'PICK A NAME';
      final optionButtons = buildQuizOptionButtons();
      final promptStyle = displayedQuizMode == GambitQuizMode.guessLine
          ? _academyDisplayStyle(
              palette: palette,
              size: compactLandscapePlayLayout
                  ? 15.5
                  : compactPlayLayout
                  ? 17
                  : (media.size.width < 420 ? 18 : 20),
              weight: FontWeight.w700,
              letterSpacing: compactPlayLayout ? 0.5 : 0.65,
            )
          : _academyHudStyle(
              palette: palette,
              size: compactPlayLayout ? 12.5 : 12.7,
              weight: FontWeight.w700,
              color: palette.text,
              letterSpacing: 0.28,
              height: compactPlayLayout ? 1.2 : 1.25,
            );

      final header = <Widget>[
        if (!compactPlayLayout) ...<Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _academyTag(
                palette: palette,
                label: questionLead.toUpperCase(),
                accent: questionAccent,
              ),
              _academyTag(
                palette: palette,
                label: selectedLabel,
                accent: displayedSelectedIndex >= 0 || answersLocked
                    ? questionAccent
                    : palette.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ] else if (displayedPrompt.isEmpty) ...<Widget>[
          Text(
            questionLead.toUpperCase(),
            style: _academyHudStyle(
              palette: palette,
              size: 11.8,
              weight: FontWeight.w800,
              color: questionAccent,
              letterSpacing: 0.85,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (displayedPrompt.isNotEmpty) ...<Widget>[
          Text(
            displayedPrompt,
            maxLines: compactLandscapePlayLayout
                ? 2
                : compactPlayLayout
                ? 3
                : 4,
            overflow: compactPlayLayout ? TextOverflow.ellipsis : null,
            style: promptStyle,
          ),
          SizedBox(
            height: compactLandscapePlayLayout
                ? 6
                : compactPlayLayout
                ? 10
                : 8,
          ),
        ],
        if (!compactPlayLayout) ...<Widget>[
          Text(questionInstruction, style: sessionBodyStyle),
          if (displayedPromptFocus.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(displayedPromptFocus, style: sessionDetailStyle),
          ],
          if (!reviewMode &&
              !_quizAnswered &&
              displayedSelectedIndex < 0) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Choose an option to enable LOCK GUESS.',
              style: _academyHudStyle(
                palette: palette,
                color: palette.signal,
                size: 11.4,
                weight: FontWeight.w700,
                letterSpacing: 0.22,
              ),
            ),
          ],
        ],
        if (!compactPlayLayout) const SizedBox(height: 14),
      ];

      final footer = <Widget>[
        if (compactPlayLayout)
          SizedBox(
            width: double.infinity,
            child: buildQuizPrimaryActionButton(),
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: buildQuizPrimaryActionButton(),
          ),
      ];

      return _academyPixelPanel(
        panelKey: const ValueKey<String>('quiz_session_question_panel'),
        palette: palette,
        accent: questionAccent,
        fillColor: palette.panel,
        padding: EdgeInsets.all(densePanelPadding),
        child: useScrollableOptions
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...header,
                  Expanded(
                    child: Scrollbar(child: ListView(children: optionButtons)),
                  ),
                  const SizedBox(height: 12),
                  ...footer,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...header,
                  ...optionButtons,
                  if (pinFooter) const Spacer(),
                  ...footer,
                ],
              ),
      );
    }

    return Stack(
      children: <Widget>[
        Positioned.fill(child: ColoredBox(color: palette.backdrop)),
        Positioned.fill(child: _academyBackdropLayer(palette: palette)),
        Padding(
          padding: quizPadding,
          child: Column(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  buildQuizTopPanel(),
                  if (showQuizFeedbackOverlay) buildQuizFeedbackOverlayPanel(),
                ],
              ),
              SizedBox(height: topToContentGap),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (wideSideBySideLayout) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            flex: 5,
                            child: LayoutBuilder(
                              builder: (context, leftConstraints) {
                                const boardCardChromeHeight = 168.0;
                                final boardSize = max(
                                  0.0,
                                  min(
                                    leftConstraints.maxWidth - 24,
                                    leftConstraints.maxHeight -
                                        boardCardChromeHeight,
                                  ),
                                );
                                return buildQuizBoardCard(
                                  maxBoardSize: boardSize,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: contentGap),
                          Expanded(
                            flex: 6,
                            child: buildQuizQuestionPanel(
                              useScrollableOptions: true,
                            ),
                          ),
                        ],
                      );
                    }

                    if (compactLandscapePlayLayout && hasQuizBoard) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            flex: 5,
                            child: LayoutBuilder(
                              builder: (context, leftConstraints) {
                                final compactBoardChromeHeight =
                                    6.0 + (densePanelPadding * 2);
                                final boardSize = max(
                                  0.0,
                                  min(
                                    leftConstraints.maxWidth -
                                        (densePanelPadding * 2) -
                                        6.0,
                                    leftConstraints.maxHeight -
                                        compactBoardChromeHeight,
                                  ),
                                );
                                return buildQuizBoardCard(
                                  maxBoardSize: boardSize,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: contentGap),
                          Expanded(
                            flex: 6,
                            child: buildQuizQuestionPanel(
                              useScrollableOptions: false,
                              pinFooter: true,
                            ),
                          ),
                        ],
                      );
                    }

                    if (compactPortraitPlayLayout) {
                      final optionCount = displayedOptions.isEmpty
                          ? _quizOptionCountForDifficulty(_quizDifficulty)
                          : displayedOptions.length;
                      final optionHeight =
                          displayedQuizMode == GambitQuizMode.guessLine
                          ? 66.0
                          : 48.0;
                      final promptHeight = displayedPrompt.isEmpty
                          ? 0.0
                          : displayedQuizMode == GambitQuizMode.guessLine
                          ? 40.0
                          : 32.0;
                      final footerAllowance =
                          displayedQuizMode == GambitQuizMode.guessLine
                          ? 100.0
                          : 88.0;
                      final estimatedQuestionHeight =
                          (densePanelPadding * 2) +
                          promptHeight +
                          (displayedPrompt.isEmpty ? 0.0 : 10.0) +
                          (optionCount * optionHeight) +
                          (max(0, optionCount - 1) * compactOptionSpacing) +
                          footerAllowance;
                      final maxQuestionHeight = max(
                        220.0,
                        constraints.maxHeight - 120.0,
                      );
                      final questionHeight = hasQuizBoard
                          ? estimatedQuestionHeight
                                .clamp(220.0, maxQuestionHeight)
                                .toDouble()
                          : constraints.maxHeight;
                      final boardAreaHeight = max(
                        0.0,
                        constraints.maxHeight -
                            questionHeight -
                            (hasQuizBoard ? contentGap : 0.0),
                      );
                      final compactBoardChromeHeight =
                          6.0 + (densePanelPadding * 2);
                      final boardSize = hasQuizBoard
                          ? max(
                              0.0,
                              min(
                                constraints.maxWidth - (densePanelPadding * 2),
                                boardAreaHeight - compactBoardChromeHeight,
                              ),
                            )
                          : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (hasQuizBoard)
                            SizedBox(
                              height: boardAreaHeight,
                              child: buildQuizBoardCard(
                                maxBoardSize: boardSize,
                              ),
                            ),
                          if (hasQuizBoard) SizedBox(height: contentGap),
                          Expanded(
                            child: buildQuizQuestionPanel(
                              useScrollableOptions: false,
                              pinFooter: true,
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView(
                      children: <Widget>[
                        if (hasQuizBoard) buildQuizBoardCard(),
                        if (hasQuizBoard) SizedBox(height: contentGap),
                        buildQuizQuestionPanel(useScrollableOptions: false),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Image.asset(
              'assets/quizcat.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              opacity: const AlwaysStoppedAnimation(0.82),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizStatsCard({
    required QuizTrendFilter filter,
    required QuizStatsDifficultyFilter difficultyFilter,
    required int? days,
    required ValueChanged<QuizTrendFilter> onFilterChanged,
    required ValueChanged<QuizStatsDifficultyFilter> onDifficultyFilterChanged,
    required ValueChanged<int?> onDaysChanged,
    required Future<void> Function() onReset,
  });

  Widget _buildQuizBoard({
    required Map<String, String> boardState,
    required bool whiteToMove,
  });
}
