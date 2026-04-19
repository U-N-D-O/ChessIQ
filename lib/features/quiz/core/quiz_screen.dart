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

abstract class _QuizScreen extends _AnalysisPageShared {
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
      )..removeWhere((_, value) => value <= 0);
    }

    final streak = decoded['streak'];
    final bestStreak = decoded['bestStreak'];
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
      'reti opening',
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
        return 'Easy quiz shelf';
      case QuizStudyCategory.advanced:
        return 'Medium quiz shelf';
      case QuizStudyCategory.master:
        return 'Hard quiz shelf';
      case QuizStudyCategory.grandmaster:
        return 'Very hard quiz shelf';
      case QuizStudyCategory.library:
        return 'Full replayable catalog';
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
      return 'Main line';
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
          return remainder;
        }
      }
    }

    return cleanedName;
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

  int _currentViewedEligibleCount() {
    if (!_ensureQuizPoolsAvailable()) {
      return 0;
    }

    final names =
        _quizEligibleNameCache[_quizPoolKey(_quizMode, _quizDifficulty)] ??
        const <String>{};
    return _viewedGambits.where(names.contains).length;
  }

  @override
  void _markGambitViewed(String name) {
    if (name.isEmpty) return;
    if (_viewedGambits.add(name)) {
      unawaited(_saveViewedGambits());
    }
  }

  Future<void> _saveQuizStats() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'difficulty': _quizDifficulty.index,
      'studyCategory': _quizStudyCategory.index,
      'streak': _quizStreak,
      'bestStreak': _quizBestStreak,
      'totalAnswered': _quizTotalAnswered,
      'correctAnswers': _quizCorrectAnswers,
      'score': _quizScore,
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
      'academyProgress': _quizAcademyProgress.toMap(),
    };
    await prefs.setString(_quizStatsKey, jsonEncode(payload));
  }

  Future<void> _resetQuizStats() async {
    setState(() {
      _quizStudyCategory = QuizStudyCategory.basic;
      _quizStudySearchQuery = '';
      _quizStudySelectedOpeningName = null;
      _quizStudyExpandedFamily = null;
      _quizStudyOpeningCounts.clear();
      _quizStudyShownPly = 0;
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
    switch (_quizDifficulty) {
      case QuizDifficulty.easy:
        return 3;
      case QuizDifficulty.medium:
        return 4;
      case QuizDifficulty.hard:
        return 5;
      case QuizDifficulty.veryHard:
        return 5;
    }
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

  String _quizAcademyBracketDescription(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Recognize household openings, clean starter shells, and the most common practical setups.';
      case QuizDifficulty.medium:
        return 'Handle richer mainstream branches, transpositions, and broader theoretical families.';
      case QuizDifficulty.hard:
        return 'Survive sharper tournament lines where move-order accuracy and structure memory matter.';
      case QuizDifficulty.veryHard:
        return 'Work through obscure theory, rare sidelines, and long-memory recall under pressure.';
    }
  }

  String _quizAcademyBracketObjective(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Build reliable recognition of the opening names players meet most often.';
      case QuizDifficulty.medium:
        return 'Extend that recall into deeper mainstream theory and broader move-order awareness.';
      case QuizDifficulty.hard:
        return 'Convert recognition into disciplined line recall inside sharper competitive branches.';
      case QuizDifficulty.veryHard:
        return 'Finish the academy track with uncommon structures and obscure continuation memory.';
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

  double _quizPerfectSessionRatio(QuizDifficulty difficulty) {
    final required = _quizAcademyProgress.requiredPerfectSessions;
    if (required <= 0) {
      return 1.0;
    }
    return min(1.0, _quizPerfectSessionsFor(difficulty) / required);
  }

  void _syncQuizDifficultyToAcademyProgress() {
    if (_quizDifficultyUnlocked(_quizDifficulty)) {
      return;
    }
    _quizDifficulty = _quizAcademyProgress.highestUnlockedDifficulty();
  }

  String _quizAcademyMissionTitle() {
    if (_quizAcademyProgress.isTrackComplete) {
      return 'Oracle route complete';
    }

    final nextDifficulty = _quizAcademyProgress.nextDifficulty(_quizDifficulty);
    if (_quizAcademyProgress.isDifficultyCompleted(_quizDifficulty) &&
        nextDifficulty != null) {
      return '${_quizAcademyBracketShortName(nextDifficulty)} unlocked';
    }

    return 'Promotion requires perfection';
  }

  String _quizAcademyMissionBody() {
    if (_quizAcademyProgress.isTrackComplete) {
      return 'Every bracket is certified. Keep training any tier to sharpen recognition speed and long-line recall.';
    }

    final selectedDifficulty = _quizDifficulty;
    final nextDifficulty = _quizAcademyProgress.nextDifficulty(
      selectedDifficulty,
    );
    final remaining = _quizAcademyProgress.remainingPerfectSessionsFor(
      selectedDifficulty,
    );

    if (_quizAcademyProgress.isDifficultyCompleted(selectedDifficulty) &&
        nextDifficulty != null) {
      return '${_quizAcademyBracketTitle(selectedDifficulty)} is certified. Step into ${_quizAcademyBracketTitle(nextDifficulty)} when you want the next layer of theory.';
    }

    if (nextDifficulty == null) {
      return 'Bank $remaining more perfect ${_quizAcademyTierSessionLabel(selectedDifficulty, lowercase: true)} session${remaining == 1 ? '' : 's'} to finish the academy track. Every answer in the session must be correct.';
    }

    return 'Bank $remaining more perfect ${_quizAcademyTierSessionLabel(selectedDifficulty, lowercase: true)} session${remaining == 1 ? '' : 's'} to unlock ${_quizAcademyBracketTitle(nextDifficulty)}. Promotion credit only counts when the full session ends at 100% accuracy.';
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
      _quizCurriculumExpanded = false;
      _quizEligibleCount = _quizEligiblePool(
        mode: _quizMode,
        difficulty: _quizDifficulty,
      ).length;
    });
    unawaited(_saveQuizStats());
  }

  void _selectQuizAcademyTrack({
    GambitQuizMode? mode,
    required bool studyMode,
  }) {
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
      _quizStudyShelfExpanded = false;
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
      _quizStudyShelfExpanded = false;
      _quizStudySearchQuery = '';
      _quizStudyDetailOpen = false;
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

  void _toggleQuizStudyShelfExpanded() {
    setState(() {
      _quizStudyShelfExpanded = !_quizStudyShelfExpanded;
    });
  }

  void _closeQuizStudyDetail() {
    if (!_quizStudyDetailOpen) {
      return;
    }
    setState(() {
      _quizStudyDetailOpen = false;
      _quizStudyShownPly = 0;
    });
  }

  void _exitQuizStudyScreen() {
    if (!_quizStudyMode) {
      return;
    }
    setState(() {
      _quizStudyMode = false;
      _quizStudyDetailOpen = false;
      _quizStudyShownPly = 0;
    });
  }

  void _selectQuizStudyOpening(EcoLine line) {
    final familyName = _quizStudyFamilyName(line.name);
    setState(() {
      _quizStudySelectedOpeningName = line.name;
      _quizStudyExpandedFamily = familyName;
      _quizStudyDetailOpen = true;
      _quizStudyShownPly = 0;
      _quizStudyOpeningCounts[line.name] = _quizStudyCountFor(line.name) + 1;
    });
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

  void _stepQuizStudyForward(EcoLine line) {
    _setQuizStudyShownPly(line, _quizStudyShownPlyFor(line) + 1);
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

  void _openPreviousQuizReview() {
    if (_quizReviewHistory.isEmpty) return;

    setState(() {
      final nextIndex = _quizReviewIndex == null
          ? _quizReviewHistory.length - 1
          : max(0, _quizReviewIndex! - 1);
      _quizReviewIndex = nextIndex;
      _quizPlayActive = false;
      _quizPlayBoard = <String, String>{};
      _quizPlayArrowCount = 0;
      _quizFlyFrom = null;
      _quizFlyTo = null;
      _quizFlyPiece = null;
      _quizFlyProgress = 0.0;
    });
  }

  void _exitQuizReviewMode() {
    if (_quizReviewIndex == null) return;
    setState(() => _quizReviewIndex = null);
  }

  void _clearQuizRoundState() {
    _quizPrompt = '';
    _quizPromptFocus = '';
    _quizOptions = const <String>[];
    _quizFeedback = '';
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
      _quizCurriculumExpanded = false;
      _quizQuestionsTarget = 10;
      _syncQuizDifficultyToAcademyProgress();
      _resetQuizToSetupState();
      _activeSection = AppSection.gambitQuiz;
    });
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

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$difficultyLabel Locked'),
        content: Text(
          remaining <= 0
              ? '$difficultyLabel is ready, but your current academy bracket needs to refresh. Return to the setup screen and try again.'
              : 'Complete $remaining more perfect $previousLabel session${remaining == 1 ? '' : 's'} to unlock $difficultyLabel. Promotion credit only counts when the whole session finishes at 100% accuracy.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
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
      _syncQuizDifficultyToAcademyProgress();
      _quizStudyMode = false;
      _quizQuestionsTarget = 10;
      _quizSessionStarted = true;
      _quizSessionAnswered = 0;
      _quizSessionCorrect = 0;
      _quizFeedback = '';
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
        _quizPrompt = 'Not enough gambits loaded yet.';
        _quizPromptFocus = '';
        _quizOptions = const <String>[];
        _quizCorrectIndex = 0;
        _quizFeedback = '';
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
        _quizPrompt = 'Unable to build a playable quiz board for now.';
        _quizPromptFocus = '';
        _quizOptions = const <String>[];
        _quizCorrectIndex = 0;
        _quizFeedback = '';
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
      _quizMode = activeMode;
      _quizCorrectIndex = correctIndex;
      _quizFeedback = '';
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
      final to = uciMove.substring(2, 4);
      final piece = board[from];
      if (piece == null) break;

      final boardDuringFlight = Map<String, String>.from(board)..remove(from);
      final isCapture =
          board.containsKey(to) || (piece[0] == 'p' && from[0] != to[0]);
      setState(() {
        _quizPlayBoard = boardDuringFlight;
        _quizFlyFrom = from;
        _quizFlyTo = to;
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
      _quizFeedback = feedback;
      _recordQuizResult(isCorrect: isCorrect);
    });

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
      _quizFeedback = '';
      _quizPreviewContinuation = _quizMode == GambitQuizMode.guessLine
          ? _buildQuizPreviewContinuationForOption(index)
          : <EngineLine>[];
    });
  }

  void _submitSelectedQuizGuess() {
    if (_quizAnswered) return;
    if (_quizSelectedIndex < 0 || _quizSelectedIndex >= _quizOptions.length) {
      setState(() {
        _quizFeedback = 'Choose an option first, then tap Guess.';
      });
      return;
    }
    _submitQuizAnswer(_quizSelectedIndex);
  }

  Widget _buildQuizAcademySetupScreen() {
    if (_quizStudyMode) {
      return _buildQuizStudyScreen(this);
    }

    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
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
    final backDestination = _quizLaunchedFromAcademy ? 'academy' : 'menu';
    final currentPoolCount = _quizEligiblePool(
      mode: _quizMode,
      difficulty: _quizDifficulty,
    ).length;
    final viewedCount = _currentViewedEligibleCount();
    final eligibleCount = currentPoolCount > 0
        ? currentPoolCount
        : _ecoOpenings.length;
    final currentTierColor = _quizDifficultyColor(_quizDifficulty);
    final perfectCount = _quizPerfectSessionsFor(_quizDifficulty);
    final requiredCount = _quizAcademyProgress.requiredPerfectSessions;
    final canStart = currentPoolCount >= 3;
    final highestUnlocked = _quizAcademyProgress.highestUnlockedDifficulty();

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
        Positioned.fill(child: _buildQuizAcademyAtmosphere(useMonochrome)),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = _menuDotTime;
              final alignment = _botSelectorBlueDotAlignment(
                _blueDotPhase,
                0.55,
                _blueDotRadius,
                pulse,
                _blueDotTrajectoryNoise,
                _blueDotShapeSeed,
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
                  onPressed: _goToMenu,
                  color: lightHeaderColor,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to $backDestination',
                ),
                const SizedBox(width: 6),
                Text(
                  'Opening Quiz',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: lightHeaderColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _openAppearanceSettings,
                  color: lightHeaderColor,
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: 'Board & Pieces',
                ),
                IconButton(
                  onPressed: _openQuizStatsSheet,
                  color: lightHeaderColor,
                  icon: const Icon(Icons.insights_outlined),
                  tooltip: 'Performance Stats',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuizAcademyHeroCard(
              currentTierColor: currentTierColor,
              highestUnlocked: highestUnlocked,
              useMonochrome: useMonochrome,
            ),
            const SizedBox(height: 14),
            _buildQuizAcademyMissionPanel(
              currentTierColor: currentTierColor,
              perfectCount: perfectCount,
              requiredCount: requiredCount,
              viewedCount: viewedCount,
              eligibleCount: eligibleCount,
              highestUnlocked: highestUnlocked,
            ),
            const SizedBox(height: 14),
            _buildQuizAcademyCurriculumPanel(useMonochrome: useMonochrome),
            const SizedBox(height: 14),
            _buildQuizAcademyConfigurationPanel(
              currentPoolCount: currentPoolCount,
              canStart: canStart,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$viewedCount/$eligibleCount openings viewed',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.58),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                InkResponse(
                  onTap: _showOpeningsViewedInfoDialog,
                  radius: 14,
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: scheme.onSurface.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuizAcademyAtmosphere(bool useMonochrome) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-0.86, -0.86),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (useMonochrome
                            ? const Color(0xFFC5CBD3)
                            : const Color(0xFF6FE7FF))
                        .withValues(
                          alpha: useMonochrome
                              ? (isDark ? 0.06 : 0.10)
                              : (isDark ? 0.10 : 0.20),
                        ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (useMonochrome
                                ? const Color(0xFFB0B7C2)
                                : const Color(0xFF0F809D))
                            .withValues(
                              alpha: useMonochrome
                                  ? (isDark ? 0.14 : 0.18)
                                  : (isDark ? 0.22 : 0.30),
                            ),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.92, -0.72),
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (useMonochrome
                            ? const Color(0xFFD6D0C5)
                            : const Color(0xFFD8B640))
                        .withValues(
                          alpha: useMonochrome
                              ? (isDark ? 0.05 : 0.09)
                              : (isDark ? 0.08 : 0.16),
                        ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (useMonochrome
                                ? const Color(0xFFC4BCAD)
                                : const Color(0xFF9E761D))
                            .withValues(
                              alpha: useMonochrome
                                  ? (isDark ? 0.12 : 0.16)
                                  : (isDark ? 0.18 : 0.24),
                            ),
                    blurRadius: 110,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.15, 1.08),
            child: Container(
              width: 360,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color:
                    (useMonochrome
                            ? const Color(0xFF9FA9B8)
                            : const Color(0xFF31497A))
                        .withValues(alpha: isDark ? 0.08 : 0.06),
                boxShadow: [
                  BoxShadow(
                    color:
                        (useMonochrome
                                ? const Color(0xFFB8C0CB)
                                : const Color(0xFF4B7BD8))
                            .withValues(alpha: isDark ? 0.10 : 0.08),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizAcademyHeroCard({
    required Color currentTierColor,
    required QuizDifficulty highestUnlocked,
    required bool useMonochrome,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selectedRouteAccent = _quizStudyMode
        ? const Color(0xFFD8B640)
        : _quizMode == GambitQuizMode.guessName
        ? const Color(0xFF5AAEE8)
        : const Color(0xFFD8B640);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              selectedRouteAccent.withValues(
                alpha: useMonochrome
                    ? (isDark ? 0.08 : 0.10)
                    : (isDark ? 0.16 : 0.10),
              ),
              scheme.surface,
            ),
            scheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: selectedRouteAccent.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: selectedRouteAccent.withValues(alpha: isDark ? 0.12 : 0.10),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Choose Your Academy Track',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              _buildQuizInfoButton(
                title: 'Choose Your Academy Track',
                message:
                    'Keep the setup focused: identify names, finish lines, or move into a structured study library with searchable opening families.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 780;
              final cards = [
                _buildQuizAcademyRouteCard(
                  title: 'Identify Opening Name',
                  description:
                      'Recognize the opening from the position and certify each bracket with clean 10-question runs.',
                  badge: 'Quiz Route',
                  icon: Icons.badge_outlined,
                  accent: const Color(0xFF5AAEE8),
                  selected:
                      !_quizStudyMode && _quizMode == GambitQuizMode.guessName,
                  onTap: () => _selectQuizAcademyTrack(
                    mode: GambitQuizMode.guessName,
                    studyMode: false,
                  ),
                ),
                _buildQuizAcademyRouteCard(
                  title: 'Complete Opening Line',
                  description:
                      'Finish the correct continuation when the opening shell is already on the board.',
                  badge: 'Quiz Route',
                  icon: Icons.route_outlined,
                  accent: const Color(0xFFD8B640),
                  selected:
                      !_quizStudyMode && _quizMode == GambitQuizMode.guessLine,
                  onTap: () => _selectQuizAcademyTrack(
                    mode: GambitQuizMode.guessLine,
                    studyMode: false,
                  ),
                ),
                _buildQuizAcademyRouteCard(
                  title: 'Study',
                  description:
                      'Browse grouped opening families, search variations, and preview each line on the board while separate study counters track repetition.',
                  badge: 'Study Route',
                  icon: Icons.menu_book_outlined,
                  accent: const Color(0xFFE1BF57),
                  selected: _quizStudyMode,
                  onTap: () => _selectQuizAcademyTrack(studyMode: true),
                ),
              ];

              if (stacked) {
                return Column(
                  children: [
                    for (var index = 0; index < cards.length; index++) ...[
                      cards[index],
                      if (index < cards.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[2]),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuizAcademyHeroChip(
                icon: Icons.flag_outlined,
                label: 'Unlocked',
                value: _quizAcademyBracketShortName(highestUnlocked),
                accent: currentTierColor,
              ),
              _buildQuizAcademyHeroChip(
                icon: Icons.filter_9_plus_outlined,
                label: 'Set Size',
                value: 'Fixed at 10',
                accent: const Color(0xFFD8B640),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizAcademyRouteCard({
    required String title,
    required String description,
    required String badge,
    required IconData icon,
    required Color accent,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final cardColor = selected
        ? Color.alphaBlend(accent.withValues(alpha: 0.12), scheme.surface)
        : scheme.surface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.70)
                  : scheme.outline.withValues(alpha: 0.24),
              width: selected ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildQuizInfoButton(title: title, message: description),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withValues(alpha: 0.24)),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizAcademyHeroChip({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizAcademyMissionPanel({
    required Color currentTierColor,
    required int perfectCount,
    required int requiredCount,
    required int viewedCount,
    required int eligibleCount,
    required QuizDifficulty highestUnlocked,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
                child: Text(
                  _quizAcademyMissionTitle(),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildQuizInfoButton(
                title: _quizAcademyMissionTitle(),
                message: _quizAcademyMissionBody(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuizAcademyMetricChip(
                label: 'Unlocked',
                value: _quizAcademyBracketShortName(highestUnlocked),
                accent: const Color(0xFF5AAEE8),
              ),
              _buildQuizAcademyMetricChip(
                label: 'Perfect Runs',
                value: _quizAcademyProgress.totalPerfectSessions.toString(),
                accent: const Color(0xFFD8B640),
              ),
              _buildQuizAcademyMetricChip(
                label: 'Accuracy',
                value: '${_quizAccuracy().toStringAsFixed(1)}%',
                accent: const Color(0xFF7EDC8A),
              ),
              _buildQuizAcademyMetricChip(
                label: 'Visible Library',
                value: '$viewedCount/$eligibleCount',
                accent: const Color(0xFF9DB5E8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Selected bracket progress',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildQuizInfoButton(
                      title: 'Selected bracket progress',
                      message:
                          '$perfectCount of $requiredCount perfect ${_quizAcademyTierSessionLabel(_quizDifficulty, lowercase: true)} sessions banked. ${_quizAcademyBracketObjective(_quizDifficulty)}',
                    ),
                  ],
                ),
              ),
              Text(
                '$perfectCount/$requiredCount',
                style: TextStyle(
                  color: currentTierColor,
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
              value: _quizPerfectSessionRatio(_quizDifficulty),
              backgroundColor: scheme.outline.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(currentTierColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizAcademyMetricChip({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildQuizAcademyCurriculumPanel({required bool useMonochrome}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final curriculumInfo = _quizStudyMode
        ? 'Quiz routes still use the academy ladder. Each bracket needs ${_quizAcademyProgress.requiredPerfectSessions} perfect sessions before the next one opens.'
        : 'Folded by default. Expand it when you want to inspect every bracket in the ladder. Each bracket needs ${_quizAcademyProgress.requiredPerfectSessions} perfect sessions before the next one opens.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: isDark ? 0.10 : 0.03),
          scheme.surface,
        ).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
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
                      'Curriculum Ladder',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildQuizInfoButton(
                      title: 'Curriculum Ladder',
                      message: curriculumInfo,
                    ),
                  ],
                ),
              ),
              _buildQuizTierToggleButton(
                expanded: _quizCurriculumExpanded,
                onPressed: () {
                  setState(() {
                    _quizCurriculumExpanded = !_quizCurriculumExpanded;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_quizCurriculumExpanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuizAcademyTierCard(
                  difficulty: _quizDifficulty,
                  useMonochrome: useMonochrome,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuizAcademyMetricChip(
                      label: 'Active',
                      value: _quizAcademyBracketShortName(_quizDifficulty),
                      accent: _quizDifficultyColor(_quizDifficulty),
                    ),
                    _buildQuizAcademyMetricChip(
                      label: 'Unlocked',
                      value: _quizAcademyBracketShortName(
                        _quizAcademyProgress.highestUnlockedDifficulty(),
                      ),
                      accent: const Color(0xFF5AAEE8),
                    ),
                    _buildQuizAcademyMetricChip(
                      label: 'Promotion Rule',
                      value:
                          '${_quizAcademyProgress.requiredPerfectSessions} perfect runs',
                      accent: const Color(0xFFD8B640),
                    ),
                  ],
                ),
              ],
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 760;
                final cards = QuizDifficulty.values
                    .map(
                      (difficulty) => _buildQuizAcademyTierCard(
                        difficulty: difficulty,
                        useMonochrome: useMonochrome,
                      ),
                    )
                    .toList(growable: false);

                if (!twoColumns) {
                  return Column(
                    children: [
                      for (var index = 0; index < cards.length; index++) ...[
                        cards[index],
                        if (index < cards.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (
                      var rowStart = 0;
                      rowStart < cards.length;
                      rowStart += 2
                    ) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[rowStart]),
                          const SizedBox(width: 12),
                          Expanded(child: cards[rowStart + 1]),
                        ],
                      ),
                      if (rowStart + 2 < cards.length)
                        const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuizAcademyTierCard({
    required QuizDifficulty difficulty,
    required bool useMonochrome,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _quizDifficultyColor(difficulty);
    final unlocked = _quizDifficultyUnlocked(difficulty);
    final completed = _quizAcademyProgress.isDifficultyCompleted(difficulty);
    final selected = _quizDifficulty == difficulty;
    final perfectCount = _quizPerfectSessionsFor(difficulty);
    final requirement = _quizAcademyProgress.requiredPerfectSessions;
    final previousDifficulty = difficulty == QuizDifficulty.values.first
        ? null
        : QuizDifficulty.values[difficulty.index - 1];

    String statusLabel;
    Color statusColor;
    if (completed) {
      statusLabel = 'Certified';
      statusColor = const Color(0xFF7EDC8A);
    } else if (selected) {
      statusLabel = 'Active';
      statusColor = accent;
    } else if (unlocked) {
      statusLabel = 'Unlocked';
      statusColor = const Color(0xFF8FD0FF);
    } else {
      statusLabel = 'Locked';
      statusColor = scheme.onSurface.withValues(alpha: 0.62);
    }

    final footerText = unlocked
        ? '$perfectCount/$requirement perfect sessions'
        : '${_quizAcademyProgress.remainingPerfectSessionsFor(previousDifficulty!)} perfect ${_quizAcademyTierSessionLabel(previousDifficulty, lowercase: true)} sessions left';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked
            ? () => _setQuizDifficulty(difficulty)
            : () => unawaited(_showQuizDifficultyLockedDialog(difficulty)),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  accent.withValues(
                    alpha: selected
                        ? (useMonochrome ? 0.12 : 0.18)
                        : (useMonochrome ? 0.06 : 0.08),
                  ),
                  scheme.surface,
                ),
                scheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
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
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _quizAcademyBracketIcon(difficulty),
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _quizAcademyBracketShortName(difficulty),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _quizAcademyBracketDescription(difficulty),
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: unlocked ? _quizPerfectSessionRatio(difficulty) : 0.0,
                  backgroundColor: scheme.outline.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                footerText,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.74),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizAcademyConfigurationPanel({
    required int currentPoolCount,
    required bool canStart,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final routeAccent = _quizMode == GambitQuizMode.guessName
        ? const Color(0xFF5AAEE8)
        : const Color(0xFFD8B640);
    final routeIcon = _quizMode == GambitQuizMode.guessName
        ? Icons.badge_outlined
        : Icons.route_outlined;
    final routeTitle = _quizMode == GambitQuizMode.guessName
        ? 'Identify Opening Name'
        : 'Complete Opening Line';
    final routeDescription = _quizMode == GambitQuizMode.guessName
        ? 'Each run is a fixed 10-question set. You see a position, then identify the opening name.'
        : 'Each run is a fixed 10-question set. You see the opening shell, then complete the correct continuation.';
    final primaryButtonLabel = _quizMode == GambitQuizMode.guessName
        ? 'Start 10-question name drill'
        : 'Start 10-question line drill';

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
              Expanded(
                child: Text(
                  'Session Configuration',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildQuizInfoButton(
                title: 'Session Configuration',
                message:
                    'The selected route now defines the session. There is no extra setup noise here anymore. Promotion stays simple: every playable route uses 10 questions, and academy credit only counts at 100% accuracy.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: routeAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: routeAccent.withValues(alpha: 0.30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: routeAccent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(routeIcon, color: routeAccent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              routeTitle,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildQuizInfoButton(
                            title: routeTitle,
                            message: routeDescription,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuizAcademyMetricChip(
                label: 'Route',
                value: routeTitle,
                accent: routeAccent,
              ),
              _buildQuizAcademyMetricChip(
                label: 'Questions',
                value: '10 fixed',
                accent: const Color(0xFF7EDC8A),
              ),
              _buildQuizAcademyMetricChip(
                label: 'Bracket',
                value: _quizAcademyBracketShortName(_quizDifficulty),
                accent: _quizDifficultyColor(_quizDifficulty),
              ),
              _buildQuizAcademyMetricChip(
                label: 'Curated Lines',
                value: currentPoolCount.toString(),
                accent: const Color(0xFF5AAEE8),
              ),
              _buildQuizAcademyMetricChip(
                label: 'Promotion Rule',
                value: '100% finish',
                accent: const Color(0xFFD8B640),
              ),
            ],
          ),
          if (!canStart) ...[
            const SizedBox(height: 10),
            Text(
              'The selected bracket does not have enough playable lines loaded yet. Try another bracket or let the opening library finish loading.',
              style: TextStyle(
                color: const Color(0xFFFFB26A),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openQuizStatsSheet,
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('Academy Stats'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(
                            0xFF5AAEE8,
                          ).withValues(alpha: 0.45),
                        ),
                        foregroundColor: const Color(0xFF8FD0FF),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: canStart ? _startQuizSession : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(primaryButtonLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: routeAccent,
                        foregroundColor: routeAccent.computeLuminance() > 0.55
                            ? const Color(0xFF081015)
                            : Colors.white,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openQuizStatsSheet,
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('Academy Stats'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(
                            0xFF5AAEE8,
                          ).withValues(alpha: 0.45),
                        ),
                        foregroundColor: const Color(0xFF8FD0FF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canStart ? _startQuizSession : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(primaryButtonLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: routeAccent,
                        foregroundColor: routeAccent.computeLuminance() > 0.55
                            ? const Color(0xFF081015)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showQuizInfoDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInfoButton({
    required String title,
    required String message,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: message,
      child: InkResponse(
        onTap: () =>
            unawaited(_showQuizInfoDialog(title: title, message: message)),
        radius: 16,
        child: Icon(
          Icons.info_outline,
          size: 17,
          color: scheme.onSurface.withValues(alpha: 0.60),
        ),
      ),
    );
  }

  Widget _buildQuizTierToggleButton({
    required bool expanded,
    required VoidCallback onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        expanded
            ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded,
      ),
      label: Text(expanded ? 'Hide tiers' : 'Show tiers'),
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.24)),
        visualDensity: VisualDensity.compact,
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
    final isLandscape = media.orientation == Orientation.landscape;
    final quizPadding = isLandscape
        ? EdgeInsets.fromLTRB(
            16 + media.padding.left,
            12 + media.padding.top,
            16 + media.padding.right,
            16 + media.padding.bottom,
          )
        : const EdgeInsets.fromLTRB(16, 12, 16, 16);
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
    final displayedFeedback = reviewEntry?.feedback ?? _quizFeedback;
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
    final sideBySideLayout =
        isLandscape && hasQuizBoard && media.size.width >= 700;
    final quizBackground = useMonochrome
        ? (isDark ? const Color(0xFF06080D) : Colors.white)
        : scheme.surface;
    final chipBorderColor = scheme.outline.withValues(alpha: 0.34);
    final lightHeaderColor = isDark ? scheme.onSurface : Colors.black;

    if (!_quizSessionStarted) {
      return _buildQuizAcademySetupScreen();
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
      final canOpenHistory = reviewMode
          ? (_quizReviewIndex ?? 0) > 0
          : _quizReviewHistory.isNotEmpty;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            scheme.primary.withValues(alpha: isDark ? 0.12 : 0.04),
            scheme.surface,
          ).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 34,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: canOpenHistory
                          ? _openPreviousQuizReview
                          : null,
                      tooltip: 'Review previous question',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Position after $displayedShownPly ply',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: reviewMode
                        ? TextButton(
                            onPressed: _exitQuizReviewMode,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8FD0FF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Current'),
                          )
                        : Text(
                            displayedWhiteToMove
                                ? 'White to move'
                                : 'Black to move',
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.62),
                              fontSize: 10,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: maxBoardSize,
                height: maxBoardSize,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.34),
                        width: 1.2,
                      ),
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
                                      overrideColor: const Color(0xFFB8BFC8),
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
          ],
        ),
      );
    }

    List<Widget> buildQuizOptionButtons() {
      return [
        for (int i = 0; i < displayedOptions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: answersLocked
                    ? null
                    : () => _selectQuizAnswerOption(i),
                icon: answersLocked
                    ? Icon(
                        i == displayedCorrectIndex
                            ? Icons.check_circle
                            : (i == displayedSelectedIndex
                                  ? Icons.cancel
                                  : Icons.radio_button_unchecked),
                        size: 18,
                        color: i == displayedCorrectIndex
                            ? const Color(0xFF7EDC8A)
                            : (i == displayedSelectedIndex
                                  ? const Color(0xFFFF8A80)
                                  : scheme.onSurface.withValues(alpha: 0.36)),
                      )
                    : Icon(
                        i == displayedSelectedIndex
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 17,
                        color: i == displayedSelectedIndex
                            ? const Color(0xFF8FD0FF)
                            : scheme.onSurface.withValues(alpha: 0.48),
                      ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  side: BorderSide(
                    color: answersLocked && i == displayedCorrectIndex
                        ? const Color(0xFF7EDC8A).withValues(alpha: 0.7)
                        : (!answersLocked && i == displayedSelectedIndex
                              ? const Color(0xFF5AAEE8).withValues(alpha: 0.75)
                              : chipBorderColor),
                  ),
                  backgroundColor: answersLocked && i == displayedCorrectIndex
                      ? const Color(0xFF7EDC8A).withValues(alpha: 0.12)
                      : (answersLocked && i == displayedSelectedIndex
                            ? const Color(0xFFFF8A80).withValues(alpha: 0.08)
                            : (!answersLocked && i == displayedSelectedIndex
                                  ? const Color(
                                      0xFF5AAEE8,
                                    ).withValues(alpha: 0.10)
                                  : null)),
                ),
                label: displayedQuizMode == GambitQuizMode.guessLine
                    ? _buildMoveSequenceText(
                        displayedOptions[i],
                        fontSize: 14,
                        color: answersLocked && i == displayedCorrectIndex
                            ? (isDark
                                  ? const Color(0xFFE9FFF0)
                                  : const Color(0xFF143522))
                            : scheme.onSurface.withValues(alpha: 0.90),
                        fontWeight: answersLocked && i == displayedCorrectIndex
                            ? FontWeight.w800
                            : FontWeight.w600,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        displayedOptions[i],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: answersLocked && i == displayedCorrectIndex
                              ? (isDark
                                    ? const Color(0xFFE9FFF0)
                                    : const Color(0xFF143522))
                              : scheme.onSurface.withValues(alpha: 0.90),
                          fontWeight:
                              answersLocked && i == displayedCorrectIndex
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
      ];
    }

    Widget buildQuizPromptBlock() {
      if (displayedPrompt.isEmpty) {
        return const SizedBox.shrink();
      }
      final isGuessLine = displayedQuizMode == GambitQuizMode.guessLine;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: isGuessLine
              ? Color.alphaBlend(
                  const Color(
                    0xFF5AAEE8,
                  ).withValues(alpha: isDark ? 0.14 : 0.07),
                  scheme.surface,
                ).withValues(alpha: 0.95)
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: isDark ? 0.10 : 0.04),
                  scheme.surface,
                ).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isGuessLine
                ? const Color(
                    0xFF5AAEE8,
                  ).withValues(alpha: isDark ? 0.55 : 0.45)
                : scheme.outline.withValues(alpha: 0.30),
            width: isGuessLine ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isGuessLine) ...[
              Text(
                'Complete this opening line:',
                style: TextStyle(
                  color: const Color(
                    0xFF5AAEE8,
                  ).withValues(alpha: isDark ? 0.85 : 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 5),
            ],
            Text(
              displayedPrompt,
              style: TextStyle(
                color: isGuessLine
                    ? scheme.onSurface
                    : scheme.onSurface.withValues(alpha: 0.74),
                fontSize: isGuessLine ? 17 : 12,
                fontWeight: isGuessLine ? FontWeight.w800 : FontWeight.w600,
                height: isGuessLine ? 1.25 : null,
              ),
            ),
            if (displayedPromptFocus.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                displayedPromptFocus,
                style: TextStyle(
                  color: isGuessLine
                      ? const Color(0xFFFFE09E)
                      : const Color(0xFFFFD88A),
                  fontSize: isGuessLine ? 18 : 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: isGuessLine ? 0.2 : 0.0,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget buildQuizPrimaryActionButton() {
      final canSubmitGuess =
          _quizSelectedIndex >= 0 && _quizSelectedIndex < _quizOptions.length;
      return Align(
        alignment: Alignment.centerRight,
        child: reviewMode
            ? OutlinedButton.icon(
                onPressed: _exitQuizReviewMode,
                icon: const Icon(Icons.history_toggle_off_rounded),
                label: const Text('Return to Current'),
              )
            : FilledButton.icon(
                onPressed: !_quizAnswered && !canSubmitGuess
                    ? null
                    : _handleQuizPrimaryAction,
                icon: Icon(
                  !_quizAnswered
                      ? Icons.check_rounded
                      : (_quizAnswered &&
                                _quizSessionAnswered >= _quizQuestionsTarget
                            ? Icons.flag_rounded
                            : Icons.navigate_next_rounded),
                ),
                label: Text(
                  !_quizAnswered
                      ? 'Guess'
                      : (_quizSessionAnswered >= _quizQuestionsTarget
                            ? 'Finish Session'
                            : 'Next Question'),
                ),
              ),
      );
    }

    Widget buildQuizFeedbackText() {
      // High-contrast colours that read clearly on both light and dark backgrounds.
      final feedbackColor = isCorrectAnswer
          ? (isDark ? const Color(0xFF6EF08A) : const Color(0xFF2F9E44))
          : (isDark ? const Color(0xFFFFB347) : const Color(0xFFC97100));
      return Text(
        displayedFeedback,
        style: TextStyle(color: feedbackColor, fontWeight: FontWeight.w700),
      );
    }

    return Stack(
      children: [
        Container(
          color: quizBackground,
          child: Padding(
            padding: quizPadding,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _returnToQuizSetup,
                      color: lightHeaderColor,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back to Setup',
                    ),
                    Expanded(
                      child: Text(
                        '${displayedQuizMode == GambitQuizMode.guessName ? 'Guess Name' : 'Guess Line'} · ${_quizAcademyBracketShortName(_quizDifficulty)} · $_quizQuestionsTarget Q',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: _openAppearanceSettings,
                      color: lightHeaderColor,
                      icon: const Icon(Icons.palette_outlined),
                      tooltip: 'Board & Pieces',
                    ),
                    IconButton(
                      onPressed: _openQuizStatsSheet,
                      color: lightHeaderColor,
                      icon: const Icon(Icons.insights_outlined),
                      tooltip: 'Performance Stats',
                    ),
                    Text(
                      'Q ${min(_quizSessionAnswered + (_quizAnswered ? 0 : 1), _quizQuestionsTarget)}/$_quizQuestionsTarget',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (sideBySideLayout) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: LayoutBuilder(
                                builder: (context, leftConstraints) {
                                  const boardCardChromeHeight = 62.0;
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
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  buildQuizPromptBlock(),
                                  Expanded(
                                    child: ListView(
                                      children: buildQuizOptionButtons(),
                                    ),
                                  ),
                                  if (displayedFeedback.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 2,
                                        bottom: 8,
                                      ),
                                      child: buildQuizFeedbackText(),
                                    ),
                                  buildQuizPrimaryActionButton(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView(
                        children: [
                          if (hasQuizBoard) buildQuizBoardCard(),
                          if (hasQuizBoard) const SizedBox(height: 8),
                          buildQuizPromptBlock(),
                          ...buildQuizOptionButtons(),
                        ],
                      );
                    },
                  ),
                ),
                if (displayedFeedback.isNotEmpty && !sideBySideLayout)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                    child: buildQuizFeedbackText(),
                  ),
                if (!sideBySideLayout) buildQuizPrimaryActionButton(),
              ],
            ),
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
              opacity: AlwaysStoppedAnimation(0.85),
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

  void _showOpeningsViewedInfoDialog();

  Widget _buildQuizBoard({
    required Map<String, String> boardState,
    required bool whiteToMove,
  });
}
