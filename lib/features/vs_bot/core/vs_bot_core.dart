// ignore_for_file: override_on_non_overriding_member

part of '../../analysis/screens/chess_analysis_page.dart';

class _VsBotArcadePalette {
  const _VsBotArcadePalette({
    required this.base,
    required this.reducedEffects,
    required this.backdrop,
    required this.shell,
    required this.panel,
    required this.panelAlt,
    required this.marquee,
    required this.line,
    required this.text,
    required this.textMuted,
    required this.cyan,
    required this.amber,
    required this.pink,
    required this.crimson,
    required this.victory,
    required this.shadow,
  });

  final PuzzleAcademyPalette base;
  final bool reducedEffects;
  final Color backdrop;
  final Color shell;
  final Color panel;
  final Color panelAlt;
  final Color marquee;
  final Color line;
  final Color text;
  final Color textMuted;
  final Color cyan;
  final Color amber;
  final Color pink;
  final Color crimson;
  final Color victory;
  final Color shadow;

  bool get monochrome => base.monochrome;

  bool get isDark => base.isDark;
}

_VsBotArcadePalette _vsBotArcadePaletteFor(
  BuildContext context, {
  required bool monochrome,
}) {
  final base = puzzleAcademyPalette(context, monochromeOverride: monochrome);
  final reducedEffects = puzzleAcademyShouldReduceEffects(context);
  final cyan = monochrome
      ? base.text.withValues(alpha: base.isDark ? 0.86 : 0.76)
      : const Color(0xFF87E8FF);
  final amber = monochrome
      ? base.text.withValues(alpha: base.isDark ? 0.72 : 0.60)
      : const Color(0xFFFFC857);
  final pink = monochrome
      ? base.text.withValues(alpha: base.isDark ? 0.80 : 0.68)
      : const Color(0xFFFF8AB6);
  final crimson = monochrome
      ? base.text.withValues(alpha: base.isDark ? 0.76 : 0.64)
      : const Color(0xFFFF6464);
  final victory = monochrome
      ? base.text.withValues(alpha: base.isDark ? 0.74 : 0.62)
      : const Color(0xFF58E09A);
  final backdrop = Color.alphaBlend(
    crimson.withValues(alpha: monochrome ? 0.02 : 0.08),
    base.backdrop,
  );
  final shell = Color.alphaBlend(
    cyan.withValues(alpha: monochrome ? 0.03 : 0.07),
    base.shell,
  );
  final panel = Color.alphaBlend(
    pink.withValues(alpha: monochrome ? 0.03 : 0.06),
    base.panel,
  );
  final panelAlt = Color.alphaBlend(
    amber.withValues(alpha: monochrome ? 0.03 : 0.08),
    base.panelAlt,
  );
  final marquee = Color.alphaBlend(
    crimson.withValues(alpha: monochrome ? 0.04 : 0.12),
    shell,
  );
  final line = Color.alphaBlend(
    cyan.withValues(alpha: monochrome ? 0.14 : 0.28),
    base.line,
  );

  return _VsBotArcadePalette(
    base: base,
    reducedEffects: reducedEffects,
    backdrop: backdrop,
    shell: shell,
    panel: panel,
    panelAlt: panelAlt,
    marquee: marquee,
    line: line,
    text: base.text,
    textMuted: base.textMuted,
    cyan: cyan,
    amber: amber,
    pink: pink,
    crimson: crimson,
    victory: victory,
    shadow: Colors.black.withValues(alpha: base.isDark ? 0.54 : 0.24),
  );
}

BoxDecoration _vsBotArcadePanelDecoration({
  required _VsBotArcadePalette palette,
  required Color accent,
  Color? fillColor,
  double radius = 18,
  double borderWidth = 2.6,
  bool inset = false,
  bool elevated = true,
}) {
  final background = fillColor ?? (inset ? palette.panelAlt : palette.panel);
  final useSoftInsetShadow = inset && elevated;
  final highlight = Color.alphaBlend(
    accent.withValues(alpha: palette.monochrome ? 0.06 : (inset ? 0.10 : 0.16)),
    background,
  );
  final lowlight = Color.alphaBlend(
    palette.backdrop.withValues(alpha: palette.monochrome ? 0.10 : 0.24),
    background,
  );

  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[highlight, background, lowlight],
      stops: const <double>[0.0, 0.50, 1.0],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: accent.withValues(alpha: inset ? 0.58 : 0.82),
      width: borderWidth,
    ),
    boxShadow: <BoxShadow>[
      if (elevated)
        BoxShadow(
          color: useSoftInsetShadow
              ? accent.withValues(alpha: palette.monochrome ? 0.08 : 0.16)
              : palette.shadow,
          blurRadius: useSoftInsetShadow ? 18 : 0,
          offset: useSoftInsetShadow ? const Offset(0, 5) : const Offset(7, 7),
        ),
      ...puzzleAcademySurfaceGlow(
        accent,
        monochrome: palette.monochrome,
        strength: palette.reducedEffects
            ? 0.14
            : (inset
                  ? (useSoftInsetShadow ? 0.20 : 0.30)
                  : (elevated ? 0.88 : 0.54)),
      ),
    ],
  );
}

Color _vsBotReadableAccentColor(Color accent, _VsBotArcadePalette palette) {
  if (palette.monochrome) {
    return palette.text;
  }

  final luminance = accent.computeLuminance();
  if (luminance >= 0.78) {
    return const Color(0xFF18202A);
  }
  if (luminance >= 0.50) {
    return HSLColor.fromColor(accent).withLightness(0.24).toColor();
  }
  return accent;
}

ButtonStyle _vsBotArcadeFilledButtonStyle({
  required _VsBotArcadePalette palette,
  required Color backgroundColor,
  Color foregroundColor = const Color(0xFF0B0F16),
  BorderSide? side,
  EdgeInsetsGeometry? padding,
  double radius = 14,
}) {
  return puzzleAcademyFilledButtonStyle(
    palette: palette.base,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    side:
        side ??
        BorderSide(
          color: Colors.white.withValues(
            alpha: palette.monochrome ? 0.16 : 0.22,
          ),
          width: 2,
        ),
    padding: padding,
    radius: radius,
  );
}

ButtonStyle _vsBotArcadeOutlinedButtonStyle({
  required _VsBotArcadePalette palette,
  required Color accent,
  EdgeInsetsGeometry? padding,
  double radius = 14,
}) {
  return puzzleAcademyOutlinedButtonStyle(
    palette: palette.base,
    accent: accent,
    padding: padding,
    radius: radius,
  );
}

Color _vsBotProfileAccent(
  BotSkillProfile profile,
  _VsBotArcadePalette palette,
) {
  switch (profile) {
    case BotSkillProfile.baby:
      return palette.pink;
    case BotSkillProfile.nephew:
      return palette.amber;
    case BotSkillProfile.bestFriend:
      return palette.cyan;
    case BotSkillProfile.nerdyGirl:
      return Color.lerp(palette.cyan, palette.pink, 0.55)!;
    case BotSkillProfile.teenBoy:
      return palette.crimson;
    case BotSkillProfile.uncle:
      return Color.lerp(palette.amber, palette.crimson, 0.45)!;
    case BotSkillProfile.grandpa:
      return Color.lerp(palette.cyan, palette.amber, 0.28)!;
    case BotSkillProfile.interGm:
      return Color.lerp(palette.crimson, palette.pink, 0.40)!;
  }
}

String _vsBotProfileLabel(BotSkillProfile profile) {
  switch (profile) {
    case BotSkillProfile.baby:
      return 'Chaos Rookie';
    case BotSkillProfile.nephew:
      return 'Mate Hunter';
    case BotSkillProfile.bestFriend:
      return 'Sparring Pal';
    case BotSkillProfile.nerdyGirl:
      return 'Theory Driver';
    case BotSkillProfile.teenBoy:
      return 'Center Crusher';
    case BotSkillProfile.uncle:
      return 'Trap Dealer';
    case BotSkillProfile.grandpa:
      return 'Board Sage';
    case BotSkillProfile.interGm:
      return 'Prime Engine';
  }
}

String _vsBotTierTitle(BotDifficulty difficulty) {
  switch (difficulty) {
    case BotDifficulty.easy:
      return 'ENTRY';
    case BotDifficulty.medium:
      return 'ADVANCE';
    case BotDifficulty.hard:
      return 'EXPERT';
  }
}

abstract class _VsBotCore extends _ChessAnalysisPageStateCore {
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
        final useMonochrome =
            dialogContext.watch<AppThemeProvider>().isMonochrome ||
            _isCinematicThemeEnabled;
        final arcade = _vsBotArcadePaletteFor(
          dialogContext,
          monochrome: useMonochrome,
        );
        final progressActionLabel = _vsBotProgressActionLabel(
          currentBot: _selectedBot,
          targetBot: progressNextBot,
          targetDifficulty: progressNextDifficulty,
        );
        final isWin = _isWinningOutcomeForPov;
        final isDraw = outcome == GameOutcome.draw;
        final accent = isDraw
            ? arcade.amber
            : isWin
            ? arcade.victory
            : arcade.crimson;
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
        final summaryText = isDraw
            ? 'Evenly matched. This one stays on the board.'
            : isWin
            ? 'Excellent conversion. You closed it with style.'
            : 'Tough one. Reset and strike back.';
        final dialogMaxWidth = isLandscape
            ? min(880.0, media.size.width - 28)
            : 460.0;

        Widget? challengeChip;
        if (selectedBot != null) {
          challengeChip = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: _vsBotArcadePanelDecoration(
              palette: arcade,
              accent: challengeAccent,
              radius: 999,
              borderWidth: 2.0,
              inset: true,
              elevated: false,
              fillColor: Color.alphaBlend(
                challengeAccent.withValues(
                  alpha: arcade.monochrome ? 0.08 : 0.14,
                ),
                arcade.panelAlt,
              ),
            ),
            child: Text(
              '${selectedBot.name.toUpperCase()} // ${selectedDifficulty.label.toUpperCase()}',
              textAlign: TextAlign.center,
              style: puzzleAcademyIdentityStyle(
                palette: arcade.base,
                size: 8.0,
                color: challengeAccent,
                withGlow: true,
              ),
            ),
          );
        }

        Widget? progressCard;
        if (progressTitle != null && progressMessage != null) {
          progressCard = Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: _vsBotArcadePanelDecoration(
              palette: arcade,
              accent: challengeAccent,
              radius: 16,
              borderWidth: 2.2,
              inset: true,
              elevated: false,
              fillColor: Color.alphaBlend(
                challengeAccent.withValues(
                  alpha: arcade.monochrome ? 0.06 : 0.12,
                ),
                arcade.panelAlt,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  progressTitle.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: puzzleAcademyIdentityStyle(
                    palette: arcade.base,
                    size: 8.0,
                    color: challengeAccent,
                    withGlow: true,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progressMessage,
                  textAlign: TextAlign.center,
                  style: puzzleAcademyHudStyle(
                    palette: arcade.base,
                    size: 11.2,
                    color: arcade.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildActionButton({
          required String resultValue,
          required String label,
          required IconData icon,
          Color? backgroundColor,
          Color foregroundColor = Colors.white,
          BorderSide? side,
          bool textButton = false,
        }) {
          final height = isLandscape ? 42.0 : 46.0;
          final shape = RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          );

          if (textButton) {
            return SizedBox(
              width: double.infinity,
              height: height,
              child: TextButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(resultValue),
                style: TextButton.styleFrom(
                  foregroundColor: foregroundColor,
                  shape: shape,
                  textStyle: puzzleAcademyHudStyle(
                    palette: arcade.base,
                    size: 11.8,
                    weight: FontWeight.w800,
                    color: foregroundColor,
                  ),
                ),
                icon: Icon(icon, size: 18),
                label: Text(label),
              ),
            );
          }

          if (backgroundColor != null) {
            return SizedBox(
              width: double.infinity,
              height: height,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(resultValue),
                style: _vsBotArcadeFilledButtonStyle(
                  palette: arcade,
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                  side: BorderSide(
                    color: foregroundColor.withValues(alpha: 0.18),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  radius: 14,
                ),
                icon: Icon(icon, size: 18),
                label: Text(label, textAlign: TextAlign.center),
              ),
            );
          }

          return SizedBox(
            width: double.infinity,
            height: height,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(resultValue),
              style: _vsBotArcadeOutlinedButtonStyle(
                palette: arcade,
                accent: side?.color ?? foregroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                radius: 14,
              ),
              icon: Icon(icon, size: 18),
              label: Text(label),
            ),
          );
        }

        Widget buildActionColumn() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (progressActionLabel != null) ...[
                buildActionButton(
                  resultValue: 'next',
                  label: progressActionLabel,
                  icon: Icons.skip_next_rounded,
                  backgroundColor: challengeAccent,
                  foregroundColor: const Color(0xFF0A0E14),
                ),
                SizedBox(height: isLandscape ? 8 : 10),
              ],
              buildActionButton(
                resultValue: 'restart',
                label: 'Play Again',
                icon: Icons.replay_rounded,
                backgroundColor: accent,
                foregroundColor: const Color(0xFF0A0E14),
              ),
              SizedBox(height: isLandscape ? 8 : 10),
              buildActionButton(
                resultValue: 'opponent',
                label: 'Choose Opponent',
                icon: Icons.groups_rounded,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
              ),
              SizedBox(height: isLandscape ? 8 : 10),
              buildActionButton(
                resultValue: 'menu',
                label: 'Main Menu',
                icon: Icons.home_rounded,
                foregroundColor: Colors.white70,
                textButton: true,
              ),
            ],
          );
        }

        Widget buildHeroColumn() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildVsBotResultAnimation(
                outcome: outcome,
                isWin: isWin,
                accent: accent,
                icon: icon,
              ),
              SizedBox(height: isLandscape ? 10 : 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: puzzleAcademyDisplayStyle(
                  palette: arcade.base,
                  size: isLandscape ? 28 : 32,
                  color: accent,
                  withGlow: true,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                summaryText,
                textAlign: TextAlign.center,
                style: puzzleAcademyHudStyle(
                  palette: arcade.base,
                  size: 12.2,
                  color: arcade.textMuted,
                ),
              ),
              if (challengeChip != null) ...[
                const SizedBox(height: 12),
                challengeChip,
              ],
            ],
          );
        }

        Widget buildPortraitBody() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildHeroColumn(),
              const SizedBox(height: 16),
              _buildVsBotSessionScoreboard(accent),
              if (progressCard != null) ...[
                const SizedBox(height: 16),
                progressCard,
              ],
              SizedBox(height: isLandscape ? 12 : 18),
              buildActionColumn(),
            ],
          );
        }

        Widget buildLandscapeBody() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: buildHeroColumn(),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 11,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildVsBotSessionScoreboard(accent),
                    if (progressCard != null) ...[
                      const SizedBox(height: 12),
                      progressCard,
                    ],
                    const SizedBox(height: 14),
                    buildActionColumn(),
                  ],
                ),
              ),
            ],
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 18 : 24,
            vertical: isLandscape ? 12 : 24,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: dialogMaxWidth,
              maxHeight: media.size.height - (isLandscape ? 24 : 48),
            ),
            decoration: _vsBotArcadePanelDecoration(
              palette: arcade,
              accent: accent,
              radius: 28,
              borderWidth: 3.2,
              fillColor: arcade.marquee,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isLandscape ? 18 : 26,
                isLandscape ? 18 : 24,
                isLandscape ? 18 : 26,
                isLandscape ? 14 : 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PuzzleAcademyTag(
                        label: title.toUpperCase(),
                        accent: accent,
                        compact: true,
                        filled: true,
                        foregroundColor: arcade.monochrome
                            ? arcade.text
                            : const Color(0xFF0B0F16),
                      ),
                      if (selectedBot != null)
                        PuzzleAcademyTag(
                          label:
                              '${selectedBot.name.toUpperCase()} // ${selectedDifficulty.label.toUpperCase()}',
                          accent: challengeAccent,
                          compact: true,
                        ),
                      if (progressActionLabel != null)
                        PuzzleAcademyTag(
                          label: 'NEXT CHALLENGE READY',
                          accent: arcade.cyan,
                          compact: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  isLandscape ? buildLandscapeBody() : buildPortraitBody(),
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
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final arcade = _vsBotArcadePaletteFor(context, monochrome: useMonochrome);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: _vsBotArcadePanelDecoration(
        palette: arcade,
        accent: accent,
        radius: 20,
        borderWidth: 2.4,
        inset: true,
        elevated: false,
        fillColor: arcade.panelAlt,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESSION SCORE',
            style: puzzleAcademyIdentityStyle(
              palette: arcade.base,
              size: 8.0,
              color: accent,
              withGlow: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildVsBotScoreTile(
                  label: 'Wins',
                  value: _vsBotSessionWins,
                  valueColor: arcade.victory,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVsBotScoreTile(
                  label: 'Losses',
                  value: _vsBotSessionLosses,
                  valueColor: arcade.crimson,
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
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final arcade = _vsBotArcadePaletteFor(context, monochrome: useMonochrome);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: _vsBotArcadePanelDecoration(
        palette: arcade,
        accent: valueColor,
        radius: 14,
        borderWidth: 2.0,
        inset: true,
        elevated: false,
        fillColor: arcade.panel,
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: puzzleAcademyDisplayStyle(
              palette: arcade.base,
              size: 20,
              color: valueColor,
              withGlow: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: puzzleAcademyIdentityStyle(
              palette: arcade.base,
              size: 7.4,
              color: arcade.textMuted,
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
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final arcade = _vsBotArcadePaletteFor(context, monochrome: useMonochrome);
    final previewDifficulty = index == _botSetupSelectedIndex
        ? _botSetupSelectedDifficulty
        : BotDifficulty.easy;
    final previewSettings = bot.settingsFor(previewDifficulty);
    final avatarAsset = _botSetupAvatarAsset(bot, index);
    final locked = !_isBotUnlocked(bot);
    final clearedTierCount = _clearedTierCountForBot(bot);
    final difficultyAccent = locked
        ? arcade.line
        : _botDifficultyColor(previewDifficulty);
    final profileAccent = _vsBotProfileAccent(bot.profile, arcade);
    final shellAccent = locked
        ? arcade.line
        : Color.lerp(profileAccent, difficultyAccent, 0.55)!;
    final statusText = locked
        ? 'Clear all ${_botCharacters[max(0, index - 1)].name} tiers first.'
        : clearedTierCount == 3
        ? 'Cabinet cleared. Replay any tier or jump back in for a rematch.'
        : 'Approx. ${previewSettings.elo} Elo | $clearedTierCount/3 tiers cleared';
    final posterHeight = compact ? 156.0 : 214.0;
    final filledTagForeground = arcade.monochrome
        ? arcade.text
        : const Color(0xFF0B0F16);

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
            horizontal: compact ? 8 : 10,
            vertical: compact ? 10 : 12,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 190 : 236),
            child: Container(
              decoration: _vsBotArcadePanelDecoration(
                palette: arcade,
                accent: shellAccent,
                radius: compact ? 26 : 30,
                borderWidth: 2.8,
                fillColor: arcade.marquee,
              ),
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 12,
                compact ? 10 : 12,
                compact ? 10 : 12,
                compact ? 12 : 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: PuzzleAcademyTag(
                          label: 'RANK ${bot.rank}',
                          accent: arcade.amber,
                          compact: true,
                          filled: true,
                          foregroundColor: filledTagForeground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PuzzleAcademyTag(
                          label: _vsBotProfileLabel(bot.profile).toUpperCase(),
                          accent: profileAccent,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  GestureDetector(
                    onTap: () => unawaited(_launchBotFromSelector(bot, index)),
                    child: Container(
                      decoration: _vsBotArcadePanelDecoration(
                        palette: arcade,
                        accent: shellAccent,
                        radius: 22,
                        borderWidth: 2.2,
                        inset: true,
                        elevated: !locked,
                        fillColor: arcade.panelAlt,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: posterHeight,
                              child: avatarAsset != null
                                  ? Image.asset(avatarAsset, fit: BoxFit.cover)
                                  : Container(
                                      color: arcade.shell,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '#${bot.rank}',
                                        style: puzzleAcademyDisplayStyle(
                                          palette: arcade.base,
                                          size: compact ? 32 : 38,
                                          color: arcade.text,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.52),
                                      Colors.black.withValues(alpha: 0.82),
                                    ],
                                    stops: const <double>[0.0, 0.44, 0.78, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: PuzzleAcademyTag(
                                label: locked
                                    ? 'LOCKED'
                                    : '${previewSettings.elo} ELO',
                                accent: locked ? arcade.line : profileAccent,
                                compact: true,
                                filled: locked,
                                foregroundColor: locked
                                    ? arcade.text
                                    : filledTagForeground,
                              ),
                            ),
                            if (locked)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.58),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                        size: compact ? 26 : 30,
                                      ),
                                      SizedBox(height: compact ? 6 : 8),
                                      Text(
                                        'LOCKED',
                                        style: puzzleAcademyDisplayStyle(
                                          palette: arcade.base,
                                          size: compact ? 14 : 16,
                                          color: Colors.white,
                                          withGlow: true,
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
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  Text(
                    bot.name,
                    textAlign: TextAlign.center,
                    style: puzzleAcademyDisplayStyle(
                      palette: arcade.base,
                      size: compact ? 18 : 20,
                      color: arcade.text,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  Text(
                    _vsBotProfileLabel(bot.profile).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: puzzleAcademyIdentityStyle(
                      palette: arcade.base,
                      size: compact ? 8.4 : 9.0,
                      color: profileAccent,
                      withGlow: true,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      PuzzleAcademyTag(
                        label: locked
                            ? 'LADDER LOCK'
                            : previewDifficulty.label.toUpperCase(),
                        accent: difficultyAccent,
                        compact: true,
                        filled: !locked,
                        foregroundColor: !locked ? filledTagForeground : null,
                      ),
                      PuzzleAcademyTag(
                        label: '$clearedTierCount/3 CLEARED',
                        accent: clearedTierCount == 3
                            ? arcade.victory
                            : arcade.cyan,
                        compact: true,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Text(
                    statusText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: puzzleAcademyHudStyle(
                      palette: arcade.base,
                      size: compact ? 10.0 : 10.8,
                      color: arcade.text.withValues(alpha: 0.86),
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    bot.description,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: puzzleAcademyCompactStyle(
                      palette: arcade.base,
                      size: compact ? 10.2 : 10.8,
                      color: arcade.textMuted,
                    ),
                  ),
                ],
              ),
            ),
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
        final opacity = ui.lerpDouble(0.26, 1.0, focus)!;
        final lift = ui.lerpDouble(28, 0, Curves.easeOut.transform(focus))!;
        final rotation = delta * -0.24;
        final horizontal = delta * 16;

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
                  borderRadius: BorderRadius.circular(compact ? 30 : 34),
                  border: Border.all(
                    color: Color.lerp(
                      arcade.line.withValues(alpha: 0.26),
                      shellAccent.withValues(alpha: 0.82),
                      focus,
                    )!,
                    width: focus > 0.74 ? 2.4 : 1.2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color.alphaBlend(
                        shellAccent.withValues(alpha: 0.10 + (0.14 * focus)),
                        arcade.marquee,
                      ),
                      arcade.marquee,
                      Color.alphaBlend(
                        arcade.backdrop.withValues(alpha: 0.26),
                        arcade.panelAlt,
                      ),
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: arcade.shadow.withValues(
                        alpha: 0.20 + (0.18 * focus),
                      ),
                      blurRadius: 0,
                      offset: const Offset(8, 10),
                    ),
                    ...puzzleAcademySurfaceGlow(
                      shellAccent,
                      monochrome: arcade.monochrome,
                      strength: arcade.reducedEffects
                          ? 0.18
                          : (0.36 + (0.44 * focus)),
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

  Widget _buildVsBotSelectorChoiceTile({
    required _VsBotArcadePalette arcade,
    required String caption,
    required String label,
    required Widget leading,
    required Color accent,
    required bool selected,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final fillColor = selected
        ? Color.alphaBlend(
            accent.withValues(alpha: arcade.monochrome ? 0.08 : 0.14),
            arcade.panelAlt,
          )
        : arcade.panel;
    final readableAccent = _vsBotReadableAccentColor(accent, arcade);

    return Opacity(
      opacity: enabled ? 1.0 : 0.46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          overlayColor: puzzleAcademyInteractiveOverlay(
            palette: arcade.base,
            accent: accent,
          ),
          child: Ink(
            decoration: _vsBotArcadePanelDecoration(
              palette: arcade,
              accent: selected ? accent : arcade.line,
              fillColor: fillColor,
              radius: 16,
              borderWidth: selected ? 2.8 : 2.0,
              inset: true,
              elevated: selected,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      leading,
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          caption.toUpperCase(),
                          style: puzzleAcademyIdentityStyle(
                            palette: arcade.base,
                            size: 7.8,
                            color: selected ? readableAccent : arcade.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: puzzleAcademyDisplayStyle(
                      palette: arcade.base,
                      size: 15.5,
                      color: enabled ? arcade.text : arcade.textMuted,
                      withGlow: selected,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget _buildBotSetupScreen() {
    final selectedBot = _botCharacters[_botSetupSelectedIndex];
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
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final arcade = _vsBotArcadePaletteFor(context, monochrome: useMonochrome);
    final isLandscape = media.orientation == Orientation.landscape;
    final compactLandscape = isLandscape && media.size.height <= 460;
    final compactPortrait = !isLandscape && media.size.height <= 760;
    final tightPortrait = !isLandscape && media.size.width <= 375;
    final compactPhoneLayout = compactLandscape || compactPortrait;
    final cardViewportHeight = compactLandscape
        ? 300.0
        : isLandscape
        ? 346.0
        : tightPortrait
        ? 356.0
        : compactPortrait
        ? 384.0
        : 426.0;
    final sectionGap = compactPhoneLayout ? 12.0 : 14.0;
    final profileAccent = _vsBotProfileAccent(selectedBot.profile, arcade);
    final marqueeAccent = Color.lerp(
      profileAccent,
      selectedDifficultyColor,
      0.45,
    )!;
    final filledTagForeground = arcade.monochrome
        ? arcade.text
        : const Color(0xFF0B0F16);

    return Container(
      color: arcade.backdrop,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color.alphaBlend(
                        marqueeAccent.withValues(alpha: 0.08),
                        arcade.backdrop,
                      ),
                      arcade.backdrop,
                      Color.alphaBlend(
                        arcade.crimson.withValues(alpha: 0.06),
                        arcade.backdrop,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!arcade.reducedEffects)
            Positioned(
              left: -80,
              top: -120,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        profileAccent.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!arcade.reducedEffects)
            Positioned(
              right: -60,
              bottom: -80,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        selectedDifficultyColor.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
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

              final contentMaxWidth = isLandscape ? 1180.0 : 760.0;

              IconButton buildChromeButton({
                required VoidCallback onPressed,
                required IconData icon,
                required String tooltip,
                required Color accent,
              }) {
                return IconButton(
                  onPressed: onPressed,
                  tooltip: tooltip,
                  icon: Icon(icon),
                  color: arcade.text,
                  style: IconButton.styleFrom(
                    backgroundColor: Color.alphaBlend(
                      accent.withValues(alpha: arcade.monochrome ? 0.08 : 0.14),
                      arcade.panel,
                    ),
                    side: BorderSide(
                      color: accent.withValues(alpha: 0.62),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              }

              Widget buildNavButton({
                required IconData icon,
                required VoidCallback? onPressed,
              }) {
                return AnimatedOpacity(
                  opacity: onPressed == null ? 0.34 : 1.0,
                  duration: puzzleAcademyMotionDuration(
                    reducedEffects: arcade.reducedEffects,
                    milliseconds: 160,
                  ),
                  child: IconButton(
                    onPressed: onPressed,
                    icon: Icon(icon, size: compactPhoneLayout ? 22 : 26),
                    color: arcade.text,
                    style: IconButton.styleFrom(
                      backgroundColor: Color.alphaBlend(
                        marqueeAccent.withValues(
                          alpha: arcade.monochrome ? 0.08 : 0.14,
                        ),
                        arcade.panelAlt,
                      ),
                      side: BorderSide(
                        color: marqueeAccent.withValues(alpha: 0.70),
                        width: 2,
                      ),
                      shadowColor: marqueeAccent.withValues(alpha: 0.22),
                      elevation: arcade.monochrome ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
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
                      padding: EdgeInsets.fromLTRB(
                        tightPortrait ? 12 : 16,
                        compactPhoneLayout ? 12 : 14,
                        tightPortrait ? 12 : 16,
                        compactPhoneLayout ? 14 : 18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentMaxWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  buildChromeButton(
                                    onPressed: _goToMenu,
                                    icon: Icons.arrow_back_rounded,
                                    tooltip: 'Back to menu',
                                    accent: arcade.cyan,
                                  ),
                                  const Spacer(),
                                  buildChromeButton(
                                    onPressed: () => _openSettings(),
                                    icon: Icons.settings_outlined,
                                    tooltip: 'Settings',
                                    accent: arcade.amber,
                                  ),
                                ],
                              ),
                              SizedBox(height: sectionGap),
                              Container(
                                decoration: _vsBotArcadePanelDecoration(
                                  palette: arcade,
                                  accent: marqueeAccent,
                                  radius: 32,
                                  borderWidth: 3.4,
                                  fillColor: arcade.shell,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  14,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            selectedBot.name,
                                            style: puzzleAcademyDisplayStyle(
                                              palette: arcade.base,
                                              size: compactLandscape ? 18 : 22,
                                              color: arcade.text,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        PuzzleAcademyTag(
                                          label: selectedTierUnlocked
                                              ? 'READY'
                                              : 'LOCKED',
                                          accent: selectedTierUnlocked
                                              ? selectedDifficultyColor
                                              : arcade.crimson,
                                          compact: true,
                                          filled: selectedTierUnlocked,
                                          foregroundColor: selectedTierUnlocked
                                              ? filledTagForeground
                                              : null,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: cardViewportHeight,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Positioned.fill(
                                            child: Container(
                                              decoration:
                                                  _vsBotArcadePanelDecoration(
                                                    palette: arcade,
                                                    accent: profileAccent,
                                                    radius: 26,
                                                    borderWidth: 2.2,
                                                    inset: true,
                                                    elevated: false,
                                                    fillColor: arcade.panelAlt,
                                                  ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 8,
                                            top: 18,
                                            bottom: 18,
                                            child: IgnorePointer(
                                              child: Container(
                                                width: 14,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: <Color>[
                                                      marqueeAccent.withValues(
                                                        alpha: 0.92,
                                                      ),
                                                      arcade.crimson.withValues(
                                                        alpha: 0.30,
                                                      ),
                                                      Colors.black.withValues(
                                                        alpha: 0.12,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 8,
                                            top: 18,
                                            bottom: 18,
                                            child: IgnorePointer(
                                              child: Container(
                                                width: 14,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: <Color>[
                                                      profileAccent.withValues(
                                                        alpha: 0.92,
                                                      ),
                                                      arcade.cyan.withValues(
                                                        alpha: 0.28,
                                                      ),
                                                      Colors.black.withValues(
                                                        alpha: 0.12,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(26),
                                                gradient: RadialGradient(
                                                  center: Alignment(
                                                    sin(pulse * pi * 2) * 0.08,
                                                    -0.18 +
                                                        cos(pulse * pi * 2) *
                                                            0.05,
                                                  ),
                                                  radius: 1.02,
                                                  colors: <Color>[
                                                    marqueeAccent.withValues(
                                                      alpha:
                                                          arcade.reducedEffects
                                                          ? 0.08
                                                          : 0.18,
                                                    ),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          PageView.builder(
                                            controller: _botSetupPageController,
                                            itemCount: _botCharacters.length,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            allowImplicitScrolling: true,
                                            onPageChanged: (index) {
                                              setState(
                                                () =>
                                                    _setBotSetupSelectionFields(
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
                                            left: tightPortrait ? 8 : 12,
                                            child: buildNavButton(
                                              icon: Icons.chevron_left_rounded,
                                              onPressed:
                                                  _botSetupSelectedIndex == 0
                                                  ? null
                                                  : () => _animateBotSetupTo(
                                                      _botSetupSelectedIndex -
                                                          1,
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            right: tightPortrait ? 8 : 12,
                                            child: buildNavButton(
                                              icon: Icons.chevron_right_rounded,
                                              onPressed:
                                                  _botSetupSelectedIndex ==
                                                      _botCharacters.length - 1
                                                  ? null
                                                  : () => _animateBotSetupTo(
                                                      _botSetupSelectedIndex +
                                                          1,
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 0,
                                            top: 0,
                                            bottom: 0,
                                            child: IgnorePointer(
                                              child: Container(
                                                width: compactPhoneLayout
                                                    ? 44
                                                    : 52,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: <Color>[
                                                      arcade.shell.withValues(
                                                        alpha: 0.94,
                                                      ),
                                                      arcade.shell.withValues(
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
                                                width: compactPhoneLayout
                                                    ? 44
                                                    : 52,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  gradient: LinearGradient(
                                                    begin:
                                                        Alignment.centerRight,
                                                    end: Alignment.centerLeft,
                                                    colors: <Color>[
                                                      arcade.shell.withValues(
                                                        alpha: 0.94,
                                                      ),
                                                      arcade.shell.withValues(
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
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
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
                                                ? marqueeAccent
                                                : cleared
                                                ? arcade.victory
                                                : unlocked
                                                ? arcade.text.withValues(
                                                    alpha: 0.44,
                                                  )
                                                : arcade.text.withValues(
                                                    alpha: 0.18,
                                                  );
                                            return AnimatedContainer(
                                              duration:
                                                  puzzleAcademyMotionDuration(
                                                    reducedEffects:
                                                        arcade.reducedEffects,
                                                    milliseconds: 220,
                                                  ),
                                              curve: puzzleAcademyMotionCurve(
                                                reducedEffects:
                                                    arcade.reducedEffects,
                                              ),
                                              width: active ? 22 : 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                color: dotColor,
                                                boxShadow: active
                                                    ? puzzleAcademySurfaceGlow(
                                                        dotColor,
                                                        monochrome:
                                                            arcade.monochrome,
                                                        strength: 0.26,
                                                      )
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: sectionGap),
                              Container(
                                decoration: _vsBotArcadePanelDecoration(
                                  palette: arcade,
                                  accent: selectedDifficultyColor,
                                  radius: 24,
                                  borderWidth: 2.8,
                                  fillColor: arcade.panel,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        const Spacer(),
                                        PuzzleAcademyTag(
                                          label:
                                              '$selectedBotClearedCount/3 TIERS',
                                          accent: selectedBotClearedCount == 3
                                              ? arcade.victory
                                              : arcade.amber,
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${selectedBot.name.toUpperCase()} // ${_vsBotProfileLabel(selectedBot.profile).toUpperCase()}',
                                      textAlign: TextAlign.center,
                                      style: puzzleAcademyIdentityStyle(
                                        palette: arcade.base,
                                        size: 8.4,
                                        color: profileAccent,
                                        withGlow: true,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ladderStatusText,
                                      textAlign: TextAlign.center,
                                      style: puzzleAcademyHudStyle(
                                        palette: arcade.base,
                                        size: 11.8,
                                        color: arcade.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    LayoutBuilder(
                                      builder: (context, inner) {
                                        final spacing = inner.maxWidth < 460
                                            ? 8.0
                                            : 12.0;
                                        final tileWidth =
                                            ((inner.maxWidth - (spacing * 2)) /
                                                    3)
                                                .toDouble();
                                        return Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: spacing,
                                          runSpacing: spacing,
                                          children: BotDifficulty.values
                                              .map((difficulty) {
                                                final tierUnlocked =
                                                    _isBotTierUnlocked(
                                                      selectedBot,
                                                      difficulty,
                                                    );
                                                final tierCleared =
                                                    _hasClearedBotTier(
                                                      selectedBot,
                                                      difficulty,
                                                    );
                                                final tierSelected =
                                                    _botSetupSelectedDifficulty ==
                                                    difficulty;
                                                final accent = tierUnlocked
                                                    ? _botDifficultyColor(
                                                        difficulty,
                                                      )
                                                    : arcade.line;
                                                final caption = tierUnlocked
                                                    ? tierCleared
                                                          ? 'Clear // ${selectedBot.settingsFor(difficulty).elo} Elo'
                                                          : '${_vsBotTierTitle(difficulty)} // ${selectedBot.settingsFor(difficulty).elo} Elo'
                                                    : (_botTierLockReason(
                                                            selectedBot,
                                                            difficulty,
                                                          ) ??
                                                          'Locked');

                                                return SizedBox(
                                                  width: tileWidth,
                                                  child: _buildVsBotSelectorChoiceTile(
                                                    arcade: arcade,
                                                    caption: caption,
                                                    label: difficulty.label,
                                                    leading: Icon(
                                                      tierCleared
                                                          ? Icons
                                                                .check_circle_rounded
                                                          : tierUnlocked
                                                          ? Icons.bolt_rounded
                                                          : Icons
                                                                .lock_outline_rounded,
                                                      size: 18,
                                                      color: tierUnlocked
                                                          ? accent
                                                          : arcade.textMuted,
                                                    ),
                                                    accent: accent,
                                                    selected: tierSelected,
                                                    enabled: tierUnlocked,
                                                    onTap: () {
                                                      setState(
                                                        () =>
                                                            _botSetupSelectedDifficulty =
                                                                difficulty,
                                                      );
                                                    },
                                                  ),
                                                );
                                              })
                                              .toList(growable: false),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: sectionGap),
                              Container(
                                decoration: _vsBotArcadePanelDecoration(
                                  palette: arcade,
                                  accent: arcade.cyan,
                                  radius: 24,
                                  borderWidth: 2.8,
                                  fillColor: arcade.panel,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    LayoutBuilder(
                                      builder: (context, inner) {
                                        final spacing = inner.maxWidth < 460
                                            ? 8.0
                                            : 12.0;
                                        final tileWidth =
                                            ((inner.maxWidth - (spacing * 2)) /
                                                    3)
                                                .toDouble();
                                        return Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: spacing,
                                          runSpacing: spacing,
                                          children: [
                                            SizedBox(
                                              width: tileWidth,
                                              child:
                                                  _buildVsBotSelectorChoiceTile(
                                                    arcade: arcade,
                                                    caption: 'You move first',
                                                    label: 'White',
                                                    leading: _pieceImage(
                                                      'p_w',
                                                      width: 18,
                                                      height: 18,
                                                    ),
                                                    accent: const Color(
                                                      0xFFEDEFF4,
                                                    ),
                                                    selected:
                                                        _botSideChoice ==
                                                        BotSideChoice.white,
                                                    enabled: true,
                                                    onTap: () {
                                                      setState(
                                                        () => _botSideChoice =
                                                            BotSideChoice.white,
                                                      );
                                                    },
                                                  ),
                                            ),
                                            SizedBox(
                                              width: tileWidth,
                                              child:
                                                  _buildVsBotSelectorChoiceTile(
                                                    arcade: arcade,
                                                    caption:
                                                        'Randomized launch',
                                                    label: 'Random',
                                                    leading: Icon(
                                                      Icons.shuffle_rounded,
                                                      size: 18,
                                                      color: arcade.cyan,
                                                    ),
                                                    accent: arcade.cyan,
                                                    selected:
                                                        _botSideChoice ==
                                                        BotSideChoice.random,
                                                    enabled: true,
                                                    onTap: () {
                                                      setState(
                                                        () => _botSideChoice =
                                                            BotSideChoice
                                                                .random,
                                                      );
                                                    },
                                                  ),
                                            ),
                                            SizedBox(
                                              width: tileWidth,
                                              child:
                                                  _buildVsBotSelectorChoiceTile(
                                                    arcade: arcade,
                                                    caption:
                                                        'Bot opens the round',
                                                    label: 'Black',
                                                    leading: _pieceImage(
                                                      'p_b',
                                                      width: 18,
                                                      height: 18,
                                                    ),
                                                    accent: const Color(
                                                      0xFF46566C,
                                                    ),
                                                    selected:
                                                        _botSideChoice ==
                                                        BotSideChoice.black,
                                                    enabled: true,
                                                    onTap: () {
                                                      setState(
                                                        () => _botSideChoice =
                                                            BotSideChoice.black,
                                                      );
                                                    },
                                                  ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: sectionGap),
                              Container(
                                decoration: _vsBotArcadePanelDecoration(
                                  palette: arcade,
                                  accent: selectedTierUnlocked
                                      ? selectedDifficultyColor
                                      : arcade.crimson,
                                  radius: 26,
                                  borderWidth: 3.0,
                                  fillColor: arcade.marquee,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  18,
                                ),
                                child: SizedBox(
                                  height: compactPhoneLayout ? 52 : 56,
                                  child: FilledButton.icon(
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
                                    style: _vsBotArcadeFilledButtonStyle(
                                      palette: arcade,
                                      backgroundColor: selectedTierUnlocked
                                          ? selectedDifficultyColor
                                          : arcade.line,
                                      foregroundColor: selectedTierUnlocked
                                          ? filledTagForeground
                                          : arcade.textMuted,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      radius: 16,
                                    ),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 22,
                                    ),
                                    label: Text(
                                      selectedTierUnlocked
                                          ? 'START ${_botSetupSelectedDifficulty.label.toUpperCase()}'
                                          : 'LOCKED',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                  color: arcade.cyan.withValues(alpha: 0.92),
                  boxShadow: puzzleAcademySurfaceGlow(
                    arcade.cyan,
                    monochrome: arcade.monochrome,
                    strength: 0.36,
                  ),
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
