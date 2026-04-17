// ignore_for_file: override_on_non_overriding_member

part of '../../analysis/screens/chess_analysis_page.dart';

mixin _VsBotCore on _ChessAnalysisPageStateBase {
  @override
  Future<void> _loadVsBotSetupPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final completedTierIds =
        prefs.getStringList(
          _ChessAnalysisPageStateBase._vsBotCompletedTiersKey,
        ) ??
        const <String>[];
    final storedIndex =
        prefs.getInt(_ChessAnalysisPageStateBase._lastBotIndexKey) ?? 0;
    final nextIndex = completedTierIds.isEmpty
        ? 0
        : storedIndex.clamp(0, _botCharacters.length - 1);

    if (!mounted) {
      _completedBotTierIds
        ..clear()
        ..addAll(completedTierIds);
      _setBotSetupSelectionFields(nextIndex);
      return;
    }

    setState(() {
      _completedBotTierIds
        ..clear()
        ..addAll(completedTierIds);
      _setBotSetupSelectionFields(nextIndex);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_botSetupPageController.hasClients) {
        _botSetupPageController.jumpToPage(_botSetupSelectedIndex);
      }
    });
  }

  @override
  Future<void> _saveLastBotIndex(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ChessAnalysisPageStateBase._lastBotIndexKey, idx);
  }

  @override
  Future<void> _saveVsBotProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completedTierIds = _completedBotTierIds.toList()..sort();
    await prefs.setStringList(
      _ChessAnalysisPageStateBase._vsBotCompletedTiersKey,
      completedTierIds,
    );
  }

  @override
  void _setBotSetupSelectionFields(int index, {BotDifficulty? difficulty}) {
    final clamped = max(0, min(index, _botCharacters.length - 1));
    final bot = _botCharacters[clamped];
    _botSetupSelectedIndex = clamped;
    _botSetupSelectedDifficulty =
        difficulty != null && _isBotTierUnlocked(bot, difficulty)
        ? difficulty
        : _defaultBotSetupDifficulty(bot);
  }

  @override
  int _botIndexFor(BotCharacter bot) {
    return _botCharacters.indexWhere((candidate) => candidate.id == bot.id);
  }

  @override
  String _botTierProgressId(BotCharacter bot, BotDifficulty difficulty) {
    return '${bot.id}:${difficulty.storageKey}';
  }

  @override
  bool _hasClearedBotTier(BotCharacter bot, BotDifficulty difficulty) {
    return _completedBotTierIds.contains(_botTierProgressId(bot, difficulty));
  }

  @override
  bool _isBotUnlocked(BotCharacter bot) {
    final botIndex = _botIndexFor(bot);
    if (botIndex <= 0) {
      return true;
    }
    return _hasClearedBotTier(_botCharacters[botIndex - 1], BotDifficulty.hard);
  }

  @override
  bool _isBotTierUnlocked(BotCharacter bot, BotDifficulty difficulty) {
    if (!_isBotUnlocked(bot)) {
      return false;
    }

    switch (difficulty) {
      case BotDifficulty.easy:
        return true;
      case BotDifficulty.medium:
        return _hasClearedBotTier(bot, BotDifficulty.easy);
      case BotDifficulty.hard:
        return _hasClearedBotTier(bot, BotDifficulty.medium);
    }
  }

  @override
  bool _isBotFullyCleared(BotCharacter bot) {
    return _hasClearedBotTier(bot, BotDifficulty.hard);
  }

  @override
  int _clearedTierCountForBot(BotCharacter bot) {
    return BotDifficulty.values
        .where((difficulty) => _hasClearedBotTier(bot, difficulty))
        .length;
  }

  @override
  int get _totalBotTierCount {
    return _botCharacters.length * BotDifficulty.values.length;
  }

  @override
  BotDifficulty _defaultBotSetupDifficulty(BotCharacter bot) {
    if (!_isBotUnlocked(bot)) {
      return BotDifficulty.easy;
    }

    for (final difficulty in BotDifficulty.values) {
      if (_isBotTierUnlocked(bot, difficulty) &&
          !_hasClearedBotTier(bot, difficulty)) {
        return difficulty;
      }
    }

    if (_isBotTierUnlocked(bot, BotDifficulty.hard)) {
      return BotDifficulty.hard;
    }
    if (_isBotTierUnlocked(bot, BotDifficulty.medium)) {
      return BotDifficulty.medium;
    }
    return BotDifficulty.easy;
  }

  @override
  void _selectNextRecommendedBotChallenge() {
    for (var index = 0; index < _botCharacters.length; index += 1) {
      final bot = _botCharacters[index];
      if (!_isBotUnlocked(bot)) {
        break;
      }

      for (final difficulty in BotDifficulty.values) {
        if (_isBotTierUnlocked(bot, difficulty) &&
            !_hasClearedBotTier(bot, difficulty)) {
          _setBotSetupSelectionFields(index, difficulty: difficulty);
          unawaited(_saveLastBotIndex(index));
          return;
        }
      }
    }

    for (var index = _botCharacters.length - 1; index >= 0; index -= 1) {
      final bot = _botCharacters[index];
      if (_isBotUnlocked(bot)) {
        _setBotSetupSelectionFields(index);
        unawaited(_saveLastBotIndex(index));
        return;
      }
    }
  }

  @override
  String? _botTierLockReason(BotCharacter bot, BotDifficulty difficulty) {
    if (!_isBotUnlocked(bot)) {
      final botIndex = _botIndexFor(bot);
      if (botIndex <= 0) {
        return null;
      }
      final previousBot = _botCharacters[botIndex - 1];
      return 'Clear all ${previousBot.name} tiers to unlock ${bot.name}.';
    }

    switch (difficulty) {
      case BotDifficulty.easy:
        return null;
      case BotDifficulty.medium:
        return _hasClearedBotTier(bot, BotDifficulty.easy)
            ? null
            : 'Beat ${bot.name} on Easy to unlock Medium.';
      case BotDifficulty.hard:
        return _hasClearedBotTier(bot, BotDifficulty.medium)
            ? null
            : 'Beat ${bot.name} on Medium to unlock Hard.';
    }
  }

  @override
  Color _botDifficultyColor(BotDifficulty difficulty) {
    switch (difficulty) {
      case BotDifficulty.easy:
        return const Color(0xFF59C98A);
      case BotDifficulty.medium:
        return const Color(0xFFD8B640);
      case BotDifficulty.hard:
        return const Color(0xFFE56A6A);
    }
  }

  @override
  String? _botSetupAvatarAsset(BotCharacter bot, int index) {
    final previewDifficulty = index == _botSetupSelectedIndex
        ? _botSetupSelectedDifficulty
        : BotDifficulty.easy;
    return bot.avatarAssetFor(previewDifficulty);
  }

  @override
  String? _selectedBotAvatarAsset(BotCharacter bot) {
    return bot.avatarAssetFor(_selectedBotDifficulty);
  }

  @override
  void _clearVsBotProgressState() {
    _vsBotProgressTitle = null;
    _vsBotProgressMessage = null;
    _vsBotProgressNextBot = null;
    _vsBotProgressNextDifficulty = null;
  }

  @override
  String? _vsBotProgressActionLabel({
    BotCharacter? currentBot,
    BotCharacter? targetBot,
    BotDifficulty? targetDifficulty,
  }) {
    if (targetBot == null || targetDifficulty == null) {
      return null;
    }

    if (currentBot != null && currentBot.id == targetBot.id) {
      return 'Play ${targetDifficulty.label}';
    }

    if (targetDifficulty == BotDifficulty.easy) {
      return 'Play ${targetBot.name}';
    }

    return 'Play ${targetBot.name} ${targetDifficulty.label}';
  }

  @override
  Alignment _botSelectorBlueDotAlignment(
    double phase,
    double speed,
    double radius,
    double pulse,
    double trajectoryNoise,
    double shapeSeed,
    double scrollOffset,
  ) {
    final time = pulse * 1.26 * speed + phase + shapeSeed;
    final x =
        sin(time * (1.25 + shapeSeed * 0.14)) * radius +
        sin(time * (2.6 + shapeSeed * 0.22) + 1.3 + shapeSeed * 0.9) * 0.09 +
        sin(time * (3.5 + shapeSeed * 0.35) + 2.1) * 0.035;
    final y =
        cos(time * (1.77 + shapeSeed * 0.18) + 0.4) * radius * 0.88 +
        cos(time * (2.35 + shapeSeed * 0.15) - 0.8) * 0.09 +
        sin(time * (3.5 + shapeSeed * 0.28) + 0.6) * 0.035;
    final driftX = sin(time * (0.64 + shapeSeed * 0.04) + 1.2) * 0.015;
    final driftY = cos(time * (0.71 + shapeSeed * 0.03) - 0.7) * 0.015;
    final jitterX =
        sin(
          time * (0.92 + trajectoryNoise * 0.18 + shapeSeed * 0.06) +
              trajectoryNoise * 3.7,
        ) *
        (trajectoryNoise * 0.025 + shapeSeed * 0.015);
    final jitterY =
        cos(
          time * (1.08 + trajectoryNoise * 0.22 - shapeSeed * 0.07) -
              trajectoryNoise * 2.9,
        ) *
        (trajectoryNoise * 0.025 + shapeSeed * 0.015);
    final raw = Offset(
      x + driftX + jitterX + (scrollOffset * 0.03),
      y + driftY + jitterY + (scrollOffset * 0.90),
    );
    final distance = raw.distance;
    const limit = 1.35;
    final returnFactor = distance > limit ? limit / distance : 1.0;
    return Alignment(raw.dx * returnFactor, raw.dy * returnFactor);
  }

  @override
  void _updateBotSetupBlueDotScrollOffset() {
    _blueDotScrollVelocity *= 0.93;
    _blueDotScrollOffset += _blueDotScrollVelocity * 0.016;
    _blueDotScrollOffset = _blueDotScrollOffset.clamp(-1.15, 1.15);
  }

  @override
  List<EngineLine> _sortedBotSearchLines() {
    final lines = _botSearchLines.values.toList();
    lines.sort((a, b) => a.multiPv.compareTo(b.multiPv));
    return lines;
  }

  @override
  int _botSearchDepth(BotDifficultySettings settings) {
    return settings.searchDepth ?? 8;
  }

  @override
  int _botRequestTimeoutMs(BotDifficultySettings settings) {
    if (settings.moveTimeMs != null) {
      return settings.moveTimeMs! + 450;
    }
    return 2200;
  }

  @override
  Future<List<EngineLine>> _requestBotCandidates(
    BotCharacter bot,
    BotDifficulty difficulty,
  ) async {
    await _ensureEngineStarted();
    if (_engine == null) {
      return const <EngineLine>[];
    }

    final settings = bot.settingsFor(difficulty);

    _botSearchLines.clear();
    _botSearchMultiPv = settings.multiPv;

    final completer = Completer<List<EngineLine>>();
    _botSearchCompleter = completer;

    _send('stop');
    _send('setoption name UCI_LimitStrength value ${settings.limitStrength}');
    if (settings.limitStrength) {
      _send('setoption name UCI_Elo value ${settings.elo}');
    }
    if (settings.skillLevel != null) {
      _send('setoption name Skill Level value ${settings.skillLevel}');
    }
    _send('setoption name Threads value ${settings.threads}');
    _send('setoption name Contempt value ${settings.contempt ?? 0}');
    _send('setoption name MultiPV value ${settings.multiPv}');
    _send('position fen ${_genFen()}');
    if (settings.moveTimeMs != null) {
      _send('go movetime ${settings.moveTimeMs}');
    } else {
      _send('go depth ${_botSearchDepth(settings)}');
    }

    late final List<EngineLine> lines;
    try {
      lines = await completer.future.timeout(
        Duration(milliseconds: _botRequestTimeoutMs(settings)),
        onTimeout: _sortedBotSearchLines,
      );
    } finally {
      _botSearchCompleter = null;
      _send('setoption name MultiPV value $_effectiveMultiPvCount');
    }

    final legal = <EngineLine>[];
    for (final line in lines) {
      if (_isLegalUciMove(line.move)) {
        legal.add(line);
      }
    }
    legal.sort((a, b) => a.multiPv.compareTo(b.multiPv));
    return legal;
  }

  @override
  bool _isLegalUciMove(String move) {
    if (move.length < 4) return false;
    final from = move.substring(0, 2);
    final to = move.substring(2, 4);
    final piece = boardState[from];
    if (piece == null) return false;
    final isTurnPiece = _isWhiteTurn
        ? piece.endsWith('_w')
        : piece.endsWith('_b');
    if (!isTurnPiece) return false;
    if (!_legalMovesFrom(from).contains(to)) return false;

    final nextState = _applyUciMove(boardState, move);
    final movingWhite = piece.endsWith('_w');
    return !_isKingAttacked(nextState, movingWhite);
  }

  @override
  String? _fallbackBotMove() {
    final legalMoves = <String>[];
    for (final entry in boardState.entries) {
      final from = entry.key;
      final piece = entry.value;
      final isTurnPiece = _isWhiteTurn
          ? piece.endsWith('_w')
          : piece.endsWith('_b');
      if (!isTurnPiece) continue;
      final targets = _legalMovesFrom(from);
      for (final to in targets) {
        final move = _uciMoveForCandidate(from, to, piece);
        if (_isLegalUciMove(move)) {
          legalMoves.add(move);
        }
      }
    }
    if (legalMoves.isEmpty) return null;
    return legalMoves[_rng.nextInt(legalMoves.length)];
  }

  @override
  String? _fallbackCaptureMove() {
    final captureMoves = <String>[];
    for (final entry in boardState.entries) {
      final from = entry.key;
      final piece = entry.value;
      final isTurnPiece = _isWhiteTurn
          ? piece.endsWith('_w')
          : piece.endsWith('_b');
      if (!isTurnPiece) continue;
      final targets = _legalMovesFrom(from);
      for (final to in targets) {
        final move = _uciMoveForCandidate(from, to, piece);
        if (_isCaptureMove(move) && _isLegalUciMove(move)) {
          captureMoves.add(move);
        }
      }
    }
    if (captureMoves.isEmpty) return null;
    return captureMoves[_rng.nextInt(captureMoves.length)];
  }

  @override
  EngineLine? _rankedCandidate(List<EngineLine> lines, int rank) {
    if (lines.isEmpty) return null;
    final idx = (rank - 1).clamp(0, lines.length - 1);
    return lines[idx];
  }

  @override
  bool _isCaptureMove(String uciMove) {
    if (uciMove.length < 4) return false;
    final to = uciMove.substring(2, 4);
    return boardState[to] != null;
  }

  @override
  String? _findKingSquare(Map<String, String> state, bool whiteKing) {
    final king = whiteKing ? 'k_w' : 'k_b';
    for (final entry in state.entries) {
      if (entry.value == king) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  bool _isKingAttacked(Map<String, String> state, bool whiteKing) {
    final kingSquare = _findKingSquare(state, whiteKing);
    if (kingSquare == null) return false;
    return _isSquareAttacked(state, kingSquare, !whiteKing);
  }

  @override
  bool _isCheckingMove(String uciMove) {
    if (uciMove.length < 4) return false;
    final from = uciMove.substring(0, 2);
    final movingPiece = boardState[from];
    if (movingPiece == null) return false;
    final movingWhite = movingPiece.endsWith('_w');
    final nextState = _applyUciMove(boardState, uciMove);
    return _isKingAttacked(nextState, !movingWhite);
  }

  @override
  int _uncleComplexityScore(EngineLine line, int bestEval) {
    final evalGap = (bestEval - line.eval).abs();
    var score = 0;
    if (evalGap <= 40) score += 3;
    if (!_isCaptureMove(line.move)) score += 2;
    if (!_isCheckingMove(line.move)) score += 1;
    return score;
  }

  @override
  String? _chooseBotMove(BotCharacter bot, List<EngineLine> lines) {
    if (lines.isEmpty) return null;

    switch (bot.profile) {
      case BotSkillProfile.baby:
        final chaoticPool = lines.where((line) => line.multiPv >= 15).toList();
        final pool = chaoticPool.isNotEmpty
            ? chaoticPool
            : lines.skip(max(0, lines.length - 6)).toList(growable: false);
        if (pool.isNotEmpty) {
          return pool[_rng.nextInt(pool.length)].move;
        }
        return _fallbackBotMove();
      case BotSkillProfile.nephew:
        for (final line in lines) {
          if (_isCaptureMove(line.move)) {
            return line.move;
          }
        }
        return _fallbackCaptureMove() ?? _rankedCandidate(lines, 1)?.move;
      case BotSkillProfile.bestFriend:
        final rank = _rng.nextBool() ? 2 : 3;
        return _rankedCandidate(lines, rank)?.move ??
            _rankedCandidate(lines, 1)?.move;
      case BotSkillProfile.nerdyGirl:
        if (_moveHistory.length < 20) {
          return _rankedCandidate(lines, 1)?.move;
        }
        return _rankedCandidate(lines, 3)?.move ??
            _rankedCandidate(lines, 1)?.move;
      case BotSkillProfile.teenBoy:
        return _rankedCandidate(lines, 1)?.move;
      case BotSkillProfile.uncle:
        final bestEval = lines.first.eval;
        var bestLine = lines.first;
        var bestScore = _uncleComplexityScore(bestLine, bestEval);
        for (final line in lines.skip(1)) {
          final score = _uncleComplexityScore(line, bestEval);
          if (score > bestScore) {
            bestLine = line;
            bestScore = score;
          }
        }
        return bestLine.move;
      case BotSkillProfile.grandpa:
        return _rankedCandidate(lines, 1)?.move;
      case BotSkillProfile.interGm:
        return _rankedCandidate(lines, 1)?.move;
    }
  }

  @override
  Duration _botPersonaMoveDelay(BotCharacter bot) {
    switch (bot.profile) {
      case BotSkillProfile.grandpa:
        return Duration(milliseconds: 450 + _rng.nextInt(451));
      case BotSkillProfile.interGm:
        return Duration(milliseconds: 500 + _rng.nextInt(501));
      default:
        return Duration(milliseconds: 100 + _rng.nextInt(101));
    }
  }

  @override
  Future<void> _maybeTriggerBotMove() async {
    if (!_playVsBot || _selectedBot == null) return;
    if (_activeSection != AppSection.analysis) return;
    if (_isHumanTurnInBotGame || _botThinking) return;
    if (_gameOutcome != null) return;
    if (kIsWeb) return;

    final introDelay = _remainingBotAvatarIntroDelay();
    if (introDelay > Duration.zero) {
      unawaited(
        Future<void>.delayed(introDelay, () async {
          if (!mounted ||
              !_playVsBot ||
              _selectedBot == null ||
              _activeSection != AppSection.analysis ||
              _isHumanTurnInBotGame ||
              _botThinking ||
              _gameOutcome != null ||
              !_hasBotAvatarIntroArrived) {
            return;
          }
          await _maybeTriggerBotMove();
        }),
      );
      return;
    }

    setState(() {
      _botThinking = true;
    });

    try {
      final bot = _selectedBot!;
      final candidates = await _requestBotCandidates(
        bot,
        _selectedBotDifficulty,
      );
      final chosen = _chooseBotMove(bot, candidates) ?? _fallbackBotMove();
      if (!mounted || chosen == null) return;
      if (!_isLegalUciMove(chosen)) {
        _addLog('Rejected illegal bot move: $chosen');
        _send('stop');
        _analyze();
        return;
      }

      final from = chosen.substring(0, 2);
      final to = chosen.substring(2, 4);
      await Future<void>.delayed(_botPersonaMoveDelay(bot));
      if (!mounted ||
          !_playVsBot ||
          _selectedBot == null ||
          _isHumanTurnInBotGame) {
        return;
      }
      _onMove(from, to, promotion: chosen.length == 5 ? chosen[4] : null);
      _showLastBotMoveArrow(chosen);
    } finally {
      if (mounted) {
        setState(() {
          _botThinking = false;
        });
      }
    }
  }

  @override
  void _showLastBotMoveArrow(String uciMove) {
    final id = _ghostArrowIdSeed++;
    final ghost = _GhostArrow(id: id, line: EngineLine(uciMove, 0, 0, 1));

    setState(() {
      _botGhostArrows.add(ghost);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final idx = _botGhostArrows.indexWhere((a) => a.id == id);
      if (idx == -1) return;
      setState(() {
        _botGhostArrows[idx].opacity = 0.0;
      });
    });

    _botGhostArrowTimers[id] = Timer(const Duration(milliseconds: 3100), () {
      if (!mounted) return;
      _botGhostArrowTimers.remove(id);
      setState(() {
        _botGhostArrows.removeWhere((a) => a.id == id);
      });
    });
  }

  @override
  void _clearBotGhostArrows() {
    for (final timer in _botGhostArrowTimers.values) {
      timer.cancel();
    }
    _botGhostArrowTimers.clear();
    _botGhostArrows.clear();
  }

  @override
  Future<void> _showGameResultDialog(GameOutcome outcome) async {
    if (!mounted || _gameResultDialogVisible) return;

    _gameResultDialogVisible = true;
    if (!_playVsBot) {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final isDraw = outcome == GameOutcome.draw;
          final accent = isDraw
              ? const Color(0xFFD8B640)
              : const Color(0xFFE45C5C);
          final title = isDraw ? 'Draw' : 'Checkmate';
          final message = isDraw
              ? 'No legal moves remain. Continue to explore or reset the board.'
              : 'Checkmate has been reached. Continue to inspect, or reset to start over.';
          final icon = isDraw
              ? Icons.balance_rounded
              : Icons.crisis_alert_rounded;

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 430),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF141B2A), Color(0xFF0C121D)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 34,
                    spreadRadius: 1.5,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.35),
                          accent.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(color: accent.withValues(alpha: 0.45)),
                    ),
                    child: Icon(icon, color: accent, size: 33),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop('continue'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6CF0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('Continue'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(dialogContext).pop('reset'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      _gameResultDialogVisible = false;
      if (!mounted) return;

      if (result == 'reset') {
        setState(() {
          _resetBoard(initialLaunch: false, withIntro: false);
        });
        _analyze();
      }
      return;
    }

    final progressNextBot = _vsBotProgressNextBot;
    final progressNextDifficulty = _vsBotProgressNextDifficulty;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final media = MediaQuery.of(dialogContext);
        final isLandscape = media.orientation == Orientation.landscape;
        final progressActionLabel = _vsBotProgressActionLabel(
          currentBot: _selectedBot,
          targetBot: progressNextBot,
          targetDifficulty: progressNextDifficulty,
        );
        final isWin = _isWinningOutcomeForPov;
        final isDraw = outcome == GameOutcome.draw;
        final accent = isDraw
            ? const Color(0xFFD8B640)
            : isWin
            ? const Color(0xFF2ECC71)
            : const Color(0xFFE45C5C);
        final title = isDraw
            ? 'Draw'
            : isWin
            ? 'Victory'
            : 'Defeat';
        final icon = isDraw
            ? Icons.balance_rounded
            : isWin
            ? Icons.check_circle_rounded
            : Icons.flag_rounded;
        final selectedBot = _selectedBot;
        final selectedDifficulty = _selectedBotDifficulty;
        final progressTitle = _vsBotProgressTitle;
        final progressMessage = _vsBotProgressMessage;
        final challengeAccent = _botDifficultyColor(selectedDifficulty);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 18 : 24,
            vertical: isLandscape ? 12 : 24,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isLandscape ? 520 : 460,
              maxHeight: media.size.height - (isLandscape ? 24 : 48),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF141B2A), Color(0xFF0C121D)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 34,
                  spreadRadius: 1.5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                26,
                isLandscape ? 18 : 24,
                26,
                isLandscape ? 16 : 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildVsBotResultAnimation(
                    outcome: outcome,
                    isWin: isWin,
                    accent: accent,
                    icon: icon,
                  ),
                  SizedBox(height: isLandscape ? 12 : 18),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLandscape ? 28 : 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isDraw
                        ? 'Evenly matched. This one stays on the board.'
                        : isWin
                        ? 'Excellent conversion. You closed it with style.'
                        : 'Tough one. Reset and strike back.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12.5,
                      letterSpacing: 0.24,
                    ),
                  ),
                  if (selectedBot != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: challengeAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: challengeAccent.withValues(alpha: 0.34),
                        ),
                      ),
                      child: Text(
                        '${selectedBot.name} - ${selectedDifficulty.label}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: challengeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildVsBotSessionScoreboard(accent),
                  if (progressTitle != null && progressMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: challengeAccent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: challengeAccent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            progressTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: challengeAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            progressMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.76),
                              fontSize: 11.8,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: isLandscape ? 12 : 18),
                  if (progressActionLabel != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: isLandscape ? 44 : 48,
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop('next'),
                        style: FilledButton.styleFrom(
                          backgroundColor: challengeAccent,
                          foregroundColor: const Color(0xFF0A0E14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.skip_next_rounded, size: 18),
                        label: Text(
                          progressActionLabel,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: isLandscape ? 8 : 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: isLandscape ? 44 : 48,
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop('restart'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: const Color(0xFF0A0E14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Play Again'),
                    ),
                  ),
                  SizedBox(height: isLandscape ? 8 : 10),
                  SizedBox(
                    width: double.infinity,
                    height: isLandscape ? 42 : 44,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop('opponent'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.groups_rounded, size: 18),
                      label: const Text('Choose Opponent'),
                    ),
                  ),
                  SizedBox(height: isLandscape ? 8 : 10),
                  SizedBox(
                    width: double.infinity,
                    height: isLandscape ? 42 : 44,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(dialogContext).pop('menu'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: const Text('Main Menu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    _gameResultDialogVisible = false;
    if (!mounted) return;

    if (result == 'next' &&
        progressNextBot != null &&
        progressNextDifficulty != null) {
      await _startBotMatch(
        bot: progressNextBot,
        difficulty: progressNextDifficulty,
        sideChoice: _botSideChoice,
      );
      return;
    }

    if (result == 'restart') {
      await _performResetWithSponsoredBreak();
      return;
    }

    if (result == 'opponent') {
      _openBotSetupFromMenu();
      return;
    }

    _goToMenu();
  }

  @override
  Widget _buildVsBotResultAnimation({
    required GameOutcome outcome,
    required bool isWin,
    required Color accent,
    required IconData icon,
  }) {
    return SizedBox(
      width: 96,
      height: 96,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1150),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          final isDraw = outcome == GameOutcome.draw;
          final glowAlpha = 0.12 + ((1 - progress) * 0.34);
          final ringOpacity = ((1 - progress) * 0.55).clamp(0.0, 1.0);
          final ringScale = 0.78 + (progress * 0.62);
          final winIconScale =
              0.70 + (0.30 * Curves.easeOutBack.transform(progress));
          final drawIconScale = 0.88 + (0.12 * progress);

          double lossShake = 0;
          if (!isWin && !isDraw) {
            if (progress < 0.20) {
              lossShake = -12 * (progress / 0.20);
            } else if (progress < 0.40) {
              lossShake = 12 * ((progress - 0.20) / 0.20);
            } else if (progress < 0.60) {
              lossShake = -8 * ((progress - 0.40) / 0.20);
            } else if (progress < 0.80) {
              lossShake = 8 * ((progress - 0.60) / 0.20);
            }
          }

          final iconScale = isDraw
              ? drawIconScale
              : isWin
              ? winIconScale
              : 1.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: glowAlpha),
                      accent.withValues(alpha: 0.03),
                    ],
                  ),
                ),
              ),
              if (isDraw)
                Transform.scale(
                  scale: ringScale,
                  child: Opacity(
                    opacity: ringOpacity,
                    child: Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.40),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isWin)
                Opacity(
                  opacity: (1 - progress).clamp(0.0, 1.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      Positioned(
                        top: 6,
                        child: Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFF0AA),
                          size: 14,
                        ),
                      ),
                      Positioned(
                        left: 7,
                        child: Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFF0AA),
                          size: 11,
                        ),
                      ),
                      Positioned(
                        right: 7,
                        child: Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFF0AA),
                          size: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              Transform.translate(
                offset: Offset(lossShake, 0),
                child: Transform.scale(
                  scale: iconScale,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.38),
                          accent.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(color: accent.withValues(alpha: 0.48)),
                    ),
                    child: Icon(icon, color: accent, size: 34),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget _buildVsBotSessionScoreboard(Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Score',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildVsBotScoreTile(
                  label: 'Wins',
                  value: _vsBotSessionWins,
                  valueColor: const Color(0xFF4BE38F),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVsBotScoreTile(
                  label: 'Losses',
                  value: _vsBotSessionLosses,
                  valueColor: const Color(0xFFFF7E7E),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVsBotScoreTile(
                  label: 'Draws',
                  value: _vsBotSessionDraws,
                  valueColor: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildVsBotScoreTile({
    required String label,
    required int value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void _openBotSetupFromMenu() {
    setState(() {
      _playVsBot = false;
      _selectedBot = null;
      _botThinking = false;
      _vsBotSessionWins = 0;
      _vsBotSessionLosses = 0;
      _vsBotSessionDraws = 0;
      _gameOutcome = null;
      _botSideChoice = BotSideChoice.random;
      _activeSection = AppSection.botSetup;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_botSetupPageController.hasClients) {
        _botSetupPageController.jumpToPage(_botSetupSelectedIndex);
      }
      _botSetupLastScrollPosition = 0.0;
      _botSetupScrollForce = 0.0;
    });
  }

  @override
  void _animateBotSetupTo(int index) {
    final clamped = max(0, min(index, _botCharacters.length - 1));
    if (_botSetupSelectedIndex != clamped) {
      setState(() => _setBotSetupSelectionFields(clamped));
    }
    if (_botSetupPageController.hasClients) {
      _botSetupPageController.animateToPage(
        clamped,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  BotDifficulty _botSetupLaunchDifficultyFor(BotCharacter bot, int index) {
    if (index == _botSetupSelectedIndex &&
        _isBotTierUnlocked(bot, _botSetupSelectedDifficulty)) {
      return _botSetupSelectedDifficulty;
    }
    return _defaultBotSetupDifficulty(bot);
  }

  @override
  Future<void> _launchBotFromSelector(BotCharacter bot, int index) async {
    final difficulty = _botSetupLaunchDifficultyFor(bot, index);

    if (_botSetupSelectedIndex != index ||
        _botSetupSelectedDifficulty != difficulty) {
      setState(() {
        _setBotSetupSelectionFields(index, difficulty: difficulty);
      });
      unawaited(_saveLastBotIndex(index));
    }

    if (!_isBotTierUnlocked(bot, difficulty)) {
      return;
    }

    await _startBotMatch(
      bot: bot,
      difficulty: difficulty,
      sideChoice: _botSideChoice,
    );
  }

  @override
  Widget _buildBotSetupCard(
    BotCharacter bot,
    int index, {
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final previewDifficulty = index == _botSetupSelectedIndex
        ? _botSetupSelectedDifficulty
        : BotDifficulty.easy;
    final previewSettings = bot.settingsFor(previewDifficulty);
    final avatarAsset = _botSetupAvatarAsset(bot, index);
    final locked = !_isBotUnlocked(bot);
    final clearedTierCount = _clearedTierCountForBot(bot);
    final difficultyAccent = locked
        ? scheme.outline
        : _botDifficultyColor(previewDifficulty);
    final statusText = locked
        ? 'Clear all ${_botCharacters[max(0, index - 1)].name} tiers first.'
        : 'Approx. ${previewSettings.elo} Elo | $clearedTierCount/3 tiers cleared';

    return AnimatedBuilder(
      animation: _botSetupPageController,
      child: GestureDetector(
        onTap: () {
          if (_botSetupSelectedIndex != index) {
            _animateBotSetupTo(index);
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 6 : 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  unawaited(_launchBotFromSelector(bot, index));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Container(
                        width: compact ? 96 : 144,
                        height: compact ? 96 : 144,
                        color: Color.alphaBlend(
                          scheme.primary.withValues(
                            alpha: isDark ? 0.16 : 0.05,
                          ),
                          scheme.surface,
                        ),
                        child: avatarAsset != null
                            ? Image.asset(avatarAsset, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  '#${bot.rank}',
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 30,
                                  ),
                                ),
                              ),
                      ),
                      if (locked)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.44),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  size: compact ? 24 : 28,
                                ),
                                SizedBox(height: compact ? 4 : 6),
                                Text(
                                  'Locked',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 11 : 13,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: compact ? 8 : 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: useMonochrome
                          ? scheme.outline.withValues(alpha: 0.24)
                          : const Color(0xFFD8B640).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: useMonochrome
                            ? scheme.outline.withValues(alpha: 0.42)
                            : const Color(0xFFD8B640).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '#${bot.rank}',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: difficultyAccent.withValues(alpha: 0.44),
                      ),
                    ),
                    child: Text(
                      locked ? 'Locked' : previewDifficulty.label,
                      style: TextStyle(
                        color: locked ? scheme.onSurface : difficultyAccent,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 8 : 12),
              Text(
                bot.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 15 : 18,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: compact ? 6 : 10),
              Text(
                statusText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.74),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                bot.description,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.66),
                  fontSize: compact ? 10.5 : 11.6,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
      builder: (context, child) {
        final page =
            _botSetupPageController.hasClients &&
                _botSetupPageController.positions.length == 1 &&
                _botSetupPageController.position.hasContentDimensions
            ? (_botSetupPageController.page ??
                  _botSetupSelectedIndex.toDouble())
            : _botSetupSelectedIndex.toDouble();
        final delta = index - page;
        final distance = delta.abs().clamp(0.0, 1.8);
        final focus = (1.0 - (distance / 1.8)).clamp(0.0, 1.0);
        final scale = ui.lerpDouble(
          0.72,
          1.0,
          Curves.easeOut.transform(focus),
        )!;
        final opacity = ui.lerpDouble(0.28, 1.0, focus)!;
        final lift = ui.lerpDouble(26, 0, Curves.easeOut.transform(focus))!;
        final rotation = delta * -0.24;
        final horizontal = delta * 18;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(horizontal, lift),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(rotation)
                ..scaleByDouble(scale, scale, 1.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        Color.alphaBlend(
                          scheme.primary.withValues(alpha: 0.10),
                          scheme.surface,
                        ),
                        Color.alphaBlend(
                          scheme.secondary.withValues(alpha: 0.22),
                          scheme.surface,
                        ),
                        focus,
                      )!,
                      Color.lerp(
                        Color.alphaBlend(
                          scheme.primary.withValues(alpha: 0.06),
                          scheme.surface,
                        ),
                        Color.alphaBlend(
                          scheme.secondary.withValues(alpha: 0.14),
                          scheme.surface,
                        ),
                        focus,
                      )!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color.lerp(
                      scheme.outline.withValues(alpha: 0.28),
                      const Color(0xFF7FC4FF),
                      focus,
                    )!,
                    width: focus > 0.75 ? 1.6 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF5AAEE8,
                      ).withValues(alpha: 0.10 + (0.20 * focus)),
                      blurRadius: 14 + (24 * focus),
                      spreadRadius: focus > 0.8 ? 1.0 : 0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Future<void> _startBotMatch({
    required BotCharacter bot,
    required BotDifficulty difficulty,
    required BotSideChoice sideChoice,
  }) async {
    if (kIsWeb) {
      _addLog('Play vs Bot is unavailable on web (no Stockfish process).');
      return;
    }

    try {
      unawaited(_stopMenuMusic(fadeOut: true));
      if (!mounted) return;

      if (_activeSection == AppSection.analysis && !_playVsBot) {
        _persistAnalysisSnapshotIfNeeded();
      }

      final humanPlaysWhite = switch (sideChoice) {
        BotSideChoice.white => true,
        BotSideChoice.black => false,
        BotSideChoice.random => _rng.nextBool(),
      };
      final switchedChallenge =
          _selectedBot?.id != bot.id || _selectedBotDifficulty != difficulty;

      setState(() {
        _activeSection = AppSection.analysis;
        _playVsBot = true;
        _selectedBot = bot;
        _selectedBotDifficulty = difficulty;
        _vsBotEvalBarOnly = false;
        if (switchedChallenge) {
          _vsBotSessionWins = 0;
          _vsBotSessionLosses = 0;
          _vsBotSessionDraws = 0;
        }
        _clearVsBotProgressState();
        _humanPlaysWhite = humanPlaysWhite;
        _botThinking = false;
        _analysisEditMode = false;
      });

      _resetBoard(initialLaunch: false, withIntro: true);
      await _ensureEngineStarted();

      if (!mounted) return;
      setState(() {
        _suggestionsEnabled = false;
      });

      _analyze();
      unawaited(_maybeTriggerBotMove());
    } catch (e) {
      _addLog('Start bot match failed: $e');
      debugPrint('Start bot match failed: $e');
    }
  }

  @override
  Widget _buildBotSetupScreen() {
    final selectedBot = _botCharacters[_botSetupSelectedIndex];
    final selectedBotSettings = selectedBot.settingsFor(
      _botSetupSelectedDifficulty,
    );
    final selectedTierLockReason = _botTierLockReason(
      selectedBot,
      _botSetupSelectedDifficulty,
    );
    final selectedTierUnlocked = selectedTierLockReason == null;
    final selectedTierCleared = _hasClearedBotTier(
      selectedBot,
      _botSetupSelectedDifficulty,
    );
    final selectedBotClearedCount = _clearedTierCountForBot(selectedBot);
    final selectedDifficultyColor = _botDifficultyColor(
      _botSetupSelectedDifficulty,
    );
    final ladderStatusText =
        selectedTierLockReason ??
        (selectedTierCleared
            ? '${selectedBot.name} ${_botSetupSelectedDifficulty.label} is already cleared. Replay it or push to the next tier.'
            : 'Win this tier to unlock the next step in the ladder.');
    final pulse = _pulseController.value;
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final isLandscape = media.orientation == Orientation.landscape;
    final pageBackground = useMonochrome
        ? (isDark ? const Color(0xFF050505) : Colors.white)
        : scheme.surface;
    final lightHeaderColor = isDark ? scheme.onSurface : Colors.black;
    final compactLandscape = isLandscape && media.size.height <= 460;
    final cardViewportHeight = compactLandscape
        ? 248.0
        : (isLandscape ? 292.0 : 372.0);

    return Container(
      color: pageBackground,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final currentLayoutSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              if (_botSetupLastLayoutSize != currentLayoutSize) {
                _botSetupLastLayoutSize = currentLayoutSize;
                _botSetupLastScrollPosition = _botSetupLastScrollPosition.clamp(
                  0.0,
                  double.infinity,
                );
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    final position = notification.metrics.pixels;
                    final delta = position - _botSetupLastScrollPosition;
                    if (delta.abs() <= 200) {
                      final rawImpulse = (-delta / 20).clamp(-1.2, 1.2);
                      final nextForce =
                          (_botSetupScrollForce * 0.2) + (rawImpulse * 0.8);
                      _botSetupScrollForce = nextForce.abs() < 0.001
                          ? 0.0
                          : nextForce;
                      _blueDotScrollVelocity += _botSetupScrollForce * 0.7;
                    }
                    _botSetupLastScrollPosition = position;
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Play Chess',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: lightHeaderColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _openSettings(),
                                color: lightHeaderColor,
                                icon: const Icon(Icons.settings_outlined),
                                tooltip: 'Settings',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.alphaBlend(
                                    scheme.primary.withValues(
                                      alpha: isDark ? 0.16 : 0.06,
                                    ),
                                    scheme.surface,
                                  ),
                                  Color.alphaBlend(
                                    scheme.secondary.withValues(
                                      alpha: isDark ? 0.10 : 0.04,
                                    ),
                                    scheme.surface,
                                  ),
                                  scheme.surface,
                                ],
                                stops: const [0.0, 0.55, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(
                                  0xFF5AAEE8,
                                ).withValues(alpha: 0.25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5AAEE8).withValues(
                                    alpha:
                                        0.10 +
                                        (0.08 *
                                            (0.5 + 0.5 * sin(pulse * pi * 2))),
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: cardViewportHeight,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned(
                                        left: 18 + (sin(pulse * pi * 2) * 8),
                                        top: 18 + (cos(pulse * pi * 2) * 6),
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                (useMonochrome
                                                        ? scheme.outline
                                                        : const Color(
                                                            0xFF8FD0FF,
                                                          ))
                                                    .withValues(
                                                      alpha: useMonochrome
                                                          ? 0.12
                                                          : 0.16,
                                                    ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (useMonochrome
                                                            ? scheme.outline
                                                            : const Color(
                                                                0xFF8FD0FF,
                                                              ))
                                                        .withValues(
                                                          alpha: useMonochrome
                                                              ? 0.18
                                                              : 0.28,
                                                        ),
                                                blurRadius: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 20 + (cos(pulse * pi * 2) * 9),
                                        bottom: 20 + (sin(pulse * pi * 2) * 7),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                (useMonochrome
                                                        ? scheme.outline
                                                        : const Color(
                                                            0xFFD8B640,
                                                          ))
                                                    .withValues(
                                                      alpha: useMonochrome
                                                          ? 0.10
                                                          : 0.15,
                                                    ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (useMonochrome
                                                            ? scheme.outline
                                                            : const Color(
                                                                0xFFD8B640,
                                                              ))
                                                        .withValues(
                                                          alpha: useMonochrome
                                                              ? 0.16
                                                              : 0.25,
                                                        ),
                                                blurRadius: 12,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            gradient: RadialGradient(
                                              center: Alignment(
                                                sin(pulse * pi * 2) * 0.08,
                                                -0.12 +
                                                    cos(pulse * pi * 2) * 0.05,
                                              ),
                                              radius: 0.95,
                                              colors: [
                                                (useMonochrome
                                                        ? scheme.outline
                                                        : const Color(
                                                            0xFF5AAEE8,
                                                          ))
                                                    .withValues(
                                                      alpha: useMonochrome
                                                          ? 0.10
                                                          : 0.18,
                                                    ),
                                                (useMonochrome
                                                        ? scheme.outline
                                                        : const Color(
                                                            0xFF5AAEE8,
                                                          ))
                                                    .withValues(alpha: 0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      PageView.builder(
                                        controller: _botSetupPageController,
                                        itemCount: _botCharacters.length,
                                        physics: const BouncingScrollPhysics(),
                                        allowImplicitScrolling: true,
                                        onPageChanged: (index) {
                                          setState(
                                            () => _setBotSetupSelectionFields(
                                              index,
                                            ),
                                          );
                                          _saveLastBotIndex(index);
                                        },
                                        itemBuilder: (context, index) =>
                                            _buildBotSetupCard(
                                              _botCharacters[index],
                                              index,
                                              compact: compactLandscape,
                                            ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: IgnorePointer(
                                          child: Container(
                                            width: 52,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  scheme.surface.withValues(
                                                    alpha: isDark ? 0.95 : 0.82,
                                                  ),
                                                  scheme.surface.withValues(
                                                    alpha: 0.0,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: IgnorePointer(
                                          child: Container(
                                            width: 52,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              gradient: LinearGradient(
                                                begin: Alignment.centerRight,
                                                end: Alignment.centerLeft,
                                                colors: [
                                                  scheme.surface.withValues(
                                                    alpha: isDark ? 0.95 : 0.82,
                                                  ),
                                                  scheme.surface.withValues(
                                                    alpha: 0.0,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _botSetupSelectedIndex == 0
                                          ? null
                                          : () => _animateBotSetupTo(
                                              _botSetupSelectedIndex - 1,
                                            ),
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Color.alphaBlend(
                                          scheme.primary.withValues(
                                            alpha: isDark ? 0.12 : 0.05,
                                          ),
                                          scheme.surface,
                                        ),
                                        side: BorderSide(
                                          color: scheme.outline.withValues(
                                            alpha: 0.32,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          _botCharacters.length,
                                          (index) {
                                            final bot = _botCharacters[index];
                                            final active =
                                                index == _botSetupSelectedIndex;
                                            final unlocked = _isBotUnlocked(
                                              bot,
                                            );
                                            final cleared = _isBotFullyCleared(
                                              bot,
                                            );
                                            final dotColor = active
                                                ? const Color(0xFF7FC4FF)
                                                : cleared
                                                ? const Color(0xFF59C98A)
                                                : unlocked
                                                ? Colors.white54
                                                : Colors.white24;
                                            return AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              width: active ? 22 : 8,
                                              height: 8,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                color: dotColor,
                                                boxShadow: active
                                                    ? [
                                                        BoxShadow(
                                                          color:
                                                              const Color(
                                                                0xFF5AAEE8,
                                                              ).withValues(
                                                                alpha: 0.32,
                                                              ),
                                                          blurRadius: 10,
                                                          spreadRadius: 1,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          _botSetupSelectedIndex ==
                                              _botCharacters.length - 1
                                          ? null
                                          : () => _animateBotSetupTo(
                                              _botSetupSelectedIndex + 1,
                                            ),
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Color.alphaBlend(
                                          scheme.primary.withValues(
                                            alpha: isDark ? 0.12 : 0.05,
                                          ),
                                          scheme.surface,
                                        ),
                                        side: BorderSide(
                                          color: scheme.outline.withValues(
                                            alpha: 0.32,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(
                                scheme.primary.withValues(
                                  alpha: isDark ? 0.12 : 0.05,
                                ),
                                scheme.surface,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.32),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.videogame_asset_rounded,
                                      size: 16,
                                      color: selectedDifficultyColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Arcade Ladder',
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_completedBotTierIds.length}/$_totalBotTierCount cleared',
                                      style: TextStyle(
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.70,
                                        ),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${selectedBot.name} - ${_botSetupSelectedDifficulty.label}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Approx. ${selectedBotSettings.elo} Elo | $selectedBotClearedCount/3 tiers cleared',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.66,
                                    ),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: BotDifficulty.values
                                      .map((difficulty) {
                                        final tierUnlocked = _isBotTierUnlocked(
                                          selectedBot,
                                          difficulty,
                                        );
                                        final tierCleared = _hasClearedBotTier(
                                          selectedBot,
                                          difficulty,
                                        );
                                        final tierSelected =
                                            _botSetupSelectedDifficulty ==
                                            difficulty;
                                        final accent = tierUnlocked
                                            ? _botDifficultyColor(difficulty)
                                            : scheme.outline;

                                        return ChoiceChip(
                                          selected: tierSelected,
                                          showCheckmark: false,
                                          selectedColor: accent.withValues(
                                            alpha: 0.20,
                                          ),
                                          side: BorderSide(
                                            color: tierSelected
                                                ? accent
                                                : accent.withValues(
                                                    alpha: tierUnlocked
                                                        ? 0.40
                                                        : 0.28,
                                                  ),
                                          ),
                                          avatar: Icon(
                                            tierCleared
                                                ? Icons.check_circle_rounded
                                                : tierUnlocked
                                                ? Icons.bolt_rounded
                                                : Icons.lock_outline_rounded,
                                            size: 16,
                                            color: tierUnlocked
                                                ? accent
                                                : scheme.onSurface.withValues(
                                                    alpha: 0.46,
                                                  ),
                                          ),
                                          label: Text(
                                            difficulty.label,
                                            style: TextStyle(
                                              color: tierUnlocked
                                                  ? accent
                                                  : scheme.onSurface.withValues(
                                                      alpha: 0.54,
                                                    ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          onSelected: tierUnlocked
                                              ? (_) {
                                                  setState(
                                                    () =>
                                                        _botSetupSelectedDifficulty =
                                                            difficulty,
                                                  );
                                                }
                                              : null,
                                        );
                                      })
                                      .toList(growable: false),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  ladderStatusText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.70,
                                    ),
                                    fontSize: 11.8,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(
                                scheme.primary.withValues(
                                  alpha: isDark ? 0.12 : 0.05,
                                ),
                                scheme.surface,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.32),
                              ),
                            ),
                            child: Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ChoiceChip(
                                    selected:
                                        _botSideChoice == BotSideChoice.white,
                                    checkmarkColor: const Color(0xFF1A2232),
                                    selectedColor: const Color(0xFFDEE4EF),
                                    side: BorderSide(
                                      color:
                                          _botSideChoice == BotSideChoice.white
                                          ? const Color(0xFFEDEFF4)
                                          : scheme.outline.withValues(
                                              alpha: 0.34,
                                            ),
                                    ),
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _pieceImage(
                                          'p_w',
                                          width: 16,
                                          height: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'White',
                                          style: TextStyle(
                                            color:
                                                _botSideChoice ==
                                                    BotSideChoice.white
                                                ? const Color(0xFF1A2232)
                                                : scheme.onSurface.withValues(
                                                    alpha: 0.82,
                                                  ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onSelected: (_) {
                                      setState(
                                        () => _botSideChoice =
                                            BotSideChoice.white,
                                      );
                                    },
                                  ),
                                  ChoiceChip(
                                    selected:
                                        _botSideChoice == BotSideChoice.random,
                                    checkmarkColor: const Color(0xFF8FD0FF),
                                    selectedColor: const Color(
                                      0xFF5AAEE8,
                                    ).withValues(alpha: 0.22),
                                    side: BorderSide(
                                      color:
                                          _botSideChoice == BotSideChoice.random
                                          ? const Color(0xFF5AAEE8)
                                          : scheme.outline.withValues(
                                              alpha: 0.34,
                                            ),
                                    ),
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.shuffle_rounded,
                                          size: 16,
                                          color:
                                              _botSideChoice ==
                                                  BotSideChoice.random
                                              ? const Color(0xFF8FD0FF)
                                              : scheme.onSurface.withValues(
                                                  alpha: 0.82,
                                                ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Random',
                                          style: TextStyle(
                                            color:
                                                _botSideChoice ==
                                                    BotSideChoice.random
                                                ? const Color(0xFF8FD0FF)
                                                : scheme.onSurface.withValues(
                                                    alpha: 0.82,
                                                  ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onSelected: (_) {
                                      setState(
                                        () => _botSideChoice =
                                            BotSideChoice.random,
                                      );
                                    },
                                  ),
                                  ChoiceChip(
                                    selected:
                                        _botSideChoice == BotSideChoice.black,
                                    checkmarkColor: Colors.white,
                                    selectedColor: const Color(0xFF222933),
                                    side: BorderSide(
                                      color:
                                          _botSideChoice == BotSideChoice.black
                                          ? const Color(0xFF49576B)
                                          : scheme.outline.withValues(
                                              alpha: 0.34,
                                            ),
                                    ),
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _pieceImage(
                                          'p_b',
                                          width: 16,
                                          height: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Black',
                                          style: TextStyle(
                                            color:
                                                _botSideChoice ==
                                                    BotSideChoice.black
                                                ? Colors.white
                                                : scheme.onSurface.withValues(
                                                    alpha: 0.82,
                                                  ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onSelected: (_) {
                                      setState(
                                        () => _botSideChoice =
                                            BotSideChoice.black,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: FilledButton(
                                onPressed: selectedTierUnlocked
                                    ? () {
                                        unawaited(
                                          _launchBotFromSelector(
                                            selectedBot,
                                            _botSetupSelectedIndex,
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text(
                                  selectedTierUnlocked
                                      ? 'Start ${_botSetupSelectedDifficulty.label}'
                                      : 'Locked',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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
                  _blueDotScrollOffset,
                );
                return Align(alignment: alignment, child: child);
              },
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5AAEE8).withValues(alpha: 0.92),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5AAEE8).withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void _recordVsBotSessionResult(GameOutcome outcome) {
    if (!_playVsBot || _selectedBot == null) {
      return;
    }
    _clearVsBotProgressState();
    if (outcome == GameOutcome.draw) {
      _vsBotSessionDraws += 1;
      return;
    }
    final humanWon =
        outcome == GameOutcome.whiteWin && _humanPlaysWhite ||
        outcome == GameOutcome.blackWin && !_humanPlaysWhite;
    if (humanWon) {
      _vsBotSessionWins += 1;
      final bot = _selectedBot!;
      final newlyCleared = _completedBotTierIds.add(
        _botTierProgressId(bot, _selectedBotDifficulty),
      );
      if (newlyCleared) {
        final nextDifficulty = _selectedBotDifficulty.next;
        if (nextDifficulty != null) {
          _vsBotProgressTitle = '${nextDifficulty.label} unlocked';
          _vsBotProgressMessage =
              'You cleared ${bot.name} on ${_selectedBotDifficulty.label}. ${nextDifficulty.label} is now open.';
          _vsBotProgressNextBot = bot;
          _vsBotProgressNextDifficulty = nextDifficulty;
        } else {
          final botIndex = _botIndexFor(bot);
          if (botIndex >= 0 && botIndex < _botCharacters.length - 1) {
            final nextBot = _botCharacters[botIndex + 1];
            _vsBotProgressTitle = '${nextBot.name} unlocked';
            _vsBotProgressMessage =
                'You cleared every ${bot.name} tier. ${nextBot.name} is now open on Easy.';
            _vsBotProgressNextBot = nextBot;
            _vsBotProgressNextDifficulty = BotDifficulty.easy;
          } else {
            _vsBotProgressTitle = 'Arcade cleared';
            _vsBotProgressMessage = 'You beat every bot on every tier.';
          }
        }
        _selectNextRecommendedBotChallenge();
        unawaited(_saveVsBotProgress());
      }
    } else {
      _vsBotSessionLosses += 1;
    }
  }

  @override
  Future<void> _onBotAvatarTapped() async {
    final bot = _selectedBot;
    if (bot == null || !_playVsBot || !mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    if (!mounted) return;
    final messages = <String>[
      '${bot.name} says: "I saw that move coming."',
      '${bot.name} says: "Press me again for extra luck."',
      '${bot.name} says: "Play bold. I dare you."',
      '${bot.name} says: "I am calculating... dramatically."',
    ];
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(messages[_rng.nextInt(messages.length)]),
          duration: const Duration(milliseconds: 1700),
        ),
      );
  }
}
