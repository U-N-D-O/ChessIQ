part of '../screens/chess_analysis_page.dart';

mixin _QuizScreen on _ChessAnalysisPageStateBase {
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
  }

  /// Returns an approximate popularity score [0.0 – 1.0] for an opening by
  /// name, based on known over-the-board frequency (Lichess / Chess.com data).
  double _openingPopularityScore(String name) {
    final lower = name.toLowerCase();
    // Tier 1 – Top ~15%: universally played, household names
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
    // Tier 2 – ~15-35%: popular but not universal
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
    // Tier 3 – ~35-50%: moderate / club-level
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
    // Tier 4 – bottom ~50%: rare / exotic lines
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
        return score >= 0.65;
      case QuizDifficulty.hard:
        return score >= 0.45 && score < 0.86;
      case QuizDifficulty.veryHard:
        return score < 0.45;
    }
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

  @override
  void _precomputeQuizEligiblePools() {
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
    }

    _quizPoolsPrecomputed = true;
  }

  @override
  List<EcoLine> _quizEligiblePool({
    required GambitQuizMode mode,
    required QuizDifficulty difficulty,
  }) {
    if (!_quizPoolsPrecomputed) {
      _precomputeQuizEligiblePools();
    }
    return _quizEligiblePoolCache[_quizPoolKey(mode, difficulty)] ??
        const <EcoLine>[];
  }

  int _currentViewedEligibleCount() {
    if (!_quizPoolsPrecomputed) {
      _precomputeQuizEligiblePools();
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
      'streak': _quizStreak,
      'bestStreak': _quizBestStreak,
      'totalAnswered': _quizTotalAnswered,
      'correctAnswers': _quizCorrectAnswers,
      'score': _quizScore,
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
    };
    await prefs.setString(_quizStatsKey, jsonEncode(payload));
  }

  Future<void> _resetQuizStats() async {
    setState(() {
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

  String _quizDifficultyLabel(QuizDifficulty difficulty) {
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

  void _setQuizMode(GambitQuizMode mode) {
    if (_quizMode == mode) return;
    setState(() {
      _quizMode = mode;
      _quizEligibleCount = _quizEligiblePool(
        mode: _quizMode,
        difficulty: _quizDifficulty,
      ).length;
    });
  }

  void _setQuizQuestionTarget(int target) {
    if (_quizQuestionsTarget == target) return;
    setState(() {
      _quizQuestionsTarget = target;
    });
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
  void _openGambitQuizFromMenu() {
    setState(() {
      _playVsBot = false;
      _selectedBot = null;
      _botThinking = false;
      _resetQuizToSetupState();
      _activeSection = AppSection.gambitQuiz;
    });
  }

  void _startQuizSession() {
    setState(() {
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
    final total = max(1, _quizSessionAnswered);
    final accuracy = (_quizSessionCorrect / total) * 100.0;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Questions: $_quizSessionAnswered/$_quizQuestionsTarget'),
            Text('Correct: $_quizSessionCorrect'),
            Text('Accuracy: ${accuracy.toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );

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
    final panelSurface = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.14 : 0.05),
      scheme.surface,
    );
    final panelSurfaceAlt = Color.alphaBlend(
      scheme.secondary.withValues(alpha: isDark ? 0.10 : 0.04),
      scheme.surface,
    );
    final quizBackground = useMonochrome
        ? (isDark ? const Color(0xFF06080D) : Colors.white)
        : scheme.surface;
    final chipBorderColor = scheme.outline.withValues(alpha: 0.34);
    final lightHeaderColor = isDark ? scheme.onSurface : Colors.black;
    final chipUnselectedText = isDark
        ? scheme.onSurface.withValues(alpha: 0.82)
        : Colors.black;

    if (!_quizSessionStarted) {
      return Stack(
        children: [
          Container(color: quizBackground),
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
                  color: const ui.Color.fromARGB(
                    255,
                    46,
                    95,
                    232,
                  ).withValues(alpha: 0.92),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B78D8).withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: quizPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _goToMenu,
                      color: lightHeaderColor,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back to menu',
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Opening Puzzles',
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
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [panelSurface, panelSurfaceAlt, scheme.surface],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF5AAEE8).withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.66),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Identify Opening Name'),
                            selected: _quizMode == GambitQuizMode.guessName,
                            selectedColor: const Color(
                              0xFF5AAEE8,
                            ).withValues(alpha: isDark ? 0.20 : 0.28),
                            side: BorderSide(
                              color: _quizMode == GambitQuizMode.guessName
                                  ? const Color(0xFF5AAEE8)
                                  : chipBorderColor,
                            ),
                            labelStyle: TextStyle(
                              color: _quizMode == GambitQuizMode.guessName
                                  ? (isDark
                                        ? const Color(0xFF8FD0FF)
                                        : const Color(0xFF1040A0))
                                  : chipUnselectedText,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) =>
                                _setQuizMode(GambitQuizMode.guessName),
                          ),
                          ChoiceChip(
                            label: const Text('Complete Opening Line'),
                            selected: _quizMode == GambitQuizMode.guessLine,
                            selectedColor: const Color(
                              0xFF5AAEE8,
                            ).withValues(alpha: isDark ? 0.20 : 0.28),
                            side: BorderSide(
                              color: _quizMode == GambitQuizMode.guessLine
                                  ? const Color(0xFF5AAEE8)
                                  : chipBorderColor,
                            ),
                            labelStyle: TextStyle(
                              color: _quizMode == GambitQuizMode.guessLine
                                  ? (isDark
                                        ? const Color(0xFF8FD0FF)
                                        : const Color(0xFF1040A0))
                                  : chipUnselectedText,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) =>
                                _setQuizMode(GambitQuizMode.guessLine),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Difficulty',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.66),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...QuizDifficulty.values.map((difficulty) {
                            final selected = _quizDifficulty == difficulty;
                            final color = _quizDifficultyColor(difficulty);
                            return ChoiceChip(
                              label: Text(_quizDifficultyLabel(difficulty)),
                              selected: selected,
                              selectedColor: color.withValues(alpha: 0.2),
                              side: BorderSide(
                                color: selected
                                    ? color.withValues(alpha: 0.9)
                                    : chipBorderColor,
                              ),
                              labelStyle: TextStyle(
                                color: selected ? color : chipUnselectedText,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              onSelected: (_) => _setQuizDifficulty(difficulty),
                            );
                          }),
                          if (isLandscape) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 6,
                              ),
                              child: Text(
                                'Questions',
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.66,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...[10, 15, 20].map((target) {
                              final selected = _quizQuestionsTarget == target;
                              return ChoiceChip(
                                label: Text('$target'),
                                selected: selected,
                                selectedColor: const Color(
                                  0xFFD8B640,
                                ).withValues(alpha: 0.20),
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xFFD8B640)
                                      : chipBorderColor,
                                ),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? const Color(0xFFE4CA79)
                                      : chipUnselectedText,
                                  fontWeight: FontWeight.w700,
                                ),
                                onSelected: (_) =>
                                    _setQuizQuestionTarget(target),
                              );
                            }),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (!isLandscape) ...[
                        Text(
                          'Questions',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.66),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 8,
                          children: [10, 15, 20].map((target) {
                            final selected = _quizQuestionsTarget == target;
                            return ChoiceChip(
                              label: Text('$target'),
                              selected: selected,
                              selectedColor: const Color(
                                0xFFD8B640,
                              ).withValues(alpha: 0.20),
                              side: BorderSide(
                                color: selected
                                    ? const Color(0xFFD8B640)
                                    : chipBorderColor,
                              ),
                              labelStyle: TextStyle(
                                color: selected
                                    ? const Color(0xFFE4CA79)
                                    : chipUnselectedText,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (_) => _setQuizQuestionTarget(target),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openQuizStatsSheet,
                              icon: const Icon(Icons.insights_outlined),
                              label: const Text('View Stats'),
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
                              onPressed: _startQuizSession,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Start Quiz'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF5AAEE8),
                                foregroundColor: const Color(0xFF07131F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_currentViewedEligibleCount()}/${_quizEligibleCount > 0 ? _quizEligibleCount : _ecoOpenings.length} openings viewed',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.52),
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
          ),
        ],
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
                        color: scheme.onSurface.withValues(alpha: 0.90),
                        fontWeight: FontWeight.w600,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        displayedOptions[i],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            scheme.primary.withValues(alpha: isDark ? 0.10 : 0.04),
            scheme.surface,
          ).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayedPrompt,
              style: TextStyle(
                color: displayedQuizMode == GambitQuizMode.guessLine
                    ? scheme.onSurface.withValues(alpha: 0.92)
                    : scheme.onSurface.withValues(alpha: 0.74),
                fontSize: displayedQuizMode == GambitQuizMode.guessLine
                    ? 14
                    : 12,
                fontWeight: displayedQuizMode == GambitQuizMode.guessLine
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
            if (displayedPromptFocus.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                displayedPromptFocus,
                style: TextStyle(
                  color: displayedQuizMode == GambitQuizMode.guessLine
                      ? const Color(0xFFFFE09E)
                      : const Color(0xFFFFD88A),
                  fontSize: displayedQuizMode == GambitQuizMode.guessLine
                      ? 18
                      : 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: displayedQuizMode == GambitQuizMode.guessLine
                      ? 0.2
                      : 0.0,
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
                            : 'Next Puzzle'),
                ),
              ),
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
                        '${displayedQuizMode == GambitQuizMode.guessName ? 'Guess Name' : 'Guess Line'} · ${_quizDifficultyLabel(_quizDifficulty)} · $_quizQuestionsTarget Q',
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
                                      child: Text(
                                        displayedFeedback,
                                        style: TextStyle(
                                          color: isCorrectAnswer
                                              ? const Color(0xFF7EDC8A)
                                              : const Color(0xFFFFB26A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
                    child: Text(
                      displayedFeedback,
                      style: TextStyle(
                        color: isCorrectAnswer
                            ? const Color(0xFF7EDC8A)
                            : const Color(0xFFFFB26A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
