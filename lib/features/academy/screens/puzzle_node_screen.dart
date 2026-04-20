import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:chess/chess.dart' as chess;
import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/services/ad_service.dart';
import 'package:chessiq/core/services/purchase_service.dart';
import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/academy/services/puzzle_engine_service.dart';
import 'package:chessiq/features/academy/widgets/academy_theme_settings_sheet.dart';
import 'package:chessiq/features/academy/widgets/puzzle_academy_surface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'package:chessiq/features/academy/widgets/puzzle_node_components.dart';

class PuzzleNodeScreen extends StatefulWidget {
  const PuzzleNodeScreen({
    super.key,
    required this.node,
    required this.heroTag,
    this.initialPuzzle,
    this.initialPuzzleIndex,
    this.puzzleSequence,
    this.sequenceTitle,
    this.examMode = false,
    this.examDuration = const Duration(hours: 1),
    this.initialReviewMode = false,
    this.cinematicThemeEnabled = false,
    this.onExitToMap,
  });

  final EloNodeProgress node;
  final String heroTag;
  final PuzzleItem? initialPuzzle;
  final int? initialPuzzleIndex;
  final List<PuzzleItem>? puzzleSequence;
  final String? sequenceTitle;
  final bool examMode;
  final Duration examDuration;
  final bool initialReviewMode;
  final bool cinematicThemeEnabled;
  final VoidCallback? onExitToMap;

  @override
  State<PuzzleNodeScreen> createState() => _PuzzleNodeScreenState();
}

class _PuzzleNodeScreenState extends State<PuzzleNodeScreen>
    with SingleTickerProviderStateMixin {
  static const String _muteSoundsKey = 'mute_sounds_v1';
  static const String _hapticsEnabledKey = 'haptics_enabled_v1';
  static const String _storeStateKey = 'store_state_v1';
  static const String _academyTuitionPassKey = 'academyTuitionPassOwned';
  static const int _boardSfxPlayerPoolSize = 4;

  final PuzzleEngineService _engine = PuzzleEngineService();
  final Stopwatch _stopwatch = Stopwatch();
  final Random _rng = Random();
  final List<AudioPlayer?> _boardSfxPlayers = List<AudioPlayer?>.filled(
    _boardSfxPlayerPoolSize,
    null,
  );
  AudioPlayer? _rewardAdAudioPlayer;
  int _nextBoardSfxPlayerIndex = 0;

  late final AnimationController _arrowFadeController;
  Timer? _examTicker;

  PuzzleItem? _puzzle;
  int _puzzleIndex = 0;
  int _lineIndex = 0;
  bool _busy = false;
  bool _solved = false;
  bool _focusModeActive = false;
  bool _playerIsBlack = false;
  bool _evalBarPlayerIsBlack = false;
  bool _userMovesOnOddPly = true;
  bool _coachingOffScript = false;
  bool _muteSounds = false;
  bool _hapticsEnabled = true;
  int _pendingRegretHalfMoves = 0;
  final List<PuzzleItem> _examMistakePuzzles = <PuzzleItem>[];
  final Set<String> _examMistakePuzzleIds = <String>{};

  double _evalWhitePawns = 0.0;
  double? _lastMistakeFromEval;
  double? _lastMistakeToEval;
  String _status = 'Find the best move.';
  String? _dragFromSquare;
  String? _greyArrowFrom;
  String? _greyArrowTo;
  Duration _examRemaining = Duration.zero;
  DateTime? _examStartedAt;
  int _examCorrectCount = 0;
  int _examCompletedCount = 0;
  bool _examFinished = false;

  late chess.Chess _game;

  bool get _usesCustomSequence => (widget.puzzleSequence?.isNotEmpty ?? false);
  List<PuzzleItem> get _activeSequence => widget.puzzleSequence ?? const [];
  bool get _isExamMode => widget.examMode;
  bool get _isDailySequence => _usesCustomSequence && !_isExamMode;

  bool get _canMove =>
      !_busy &&
      !_solved &&
      !_coachingOffScript &&
      (_lineIndex.isOdd == _userMovesOnOddPly);

  bool get _isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  PlayerMode get _boardSfxPlayerMode =>
      _isWindowsDesktop ? PlayerMode.mediaPlayer : PlayerMode.lowLatency;

  AudioPlayer _takeBoardSfxPlayer() {
    final index = _isWindowsDesktop ? 0 : _nextBoardSfxPlayerIndex;
    if (!_isWindowsDesktop) {
      _nextBoardSfxPlayerIndex =
          (_nextBoardSfxPlayerIndex + 1) % _boardSfxPlayers.length;
    }
    return _boardSfxPlayers[index] ??= AudioPlayer();
  }

  AudioPlayer _ensureRewardAdAudioPlayer() {
    return _rewardAdAudioPlayer ??= AudioPlayer();
  }

  @override
  void initState() {
    super.initState();
    _game = chess.Chess();
    _arrowFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 1.0,
    );
    _examRemaining = widget.examDuration;
    unawaited(_loadAudioPrefs());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_puzzle != null) return;
    final provider = context.read<PuzzleAcademyProvider>();

    final puzzle =
        widget.initialPuzzle ??
        (_usesCustomSequence
            ? (_activeSequence.isEmpty ? null : _activeSequence.first)
            : provider.nextAvailablePuzzleForNode(widget.node));
    if (puzzle == null) {
      _status = 'No puzzle found for this level yet.';
      return;
    }

    final fallbackIndex = _usesCustomSequence
        ? _activeSequence.indexWhere(
            (candidate) => candidate.puzzleId == puzzle.puzzleId,
          )
        : provider.indexOfPuzzleInNode(widget.node, puzzle.puzzleId);
    final requestedIndex = widget.initialPuzzleIndex ?? fallbackIndex;
    final safeIndex = _usesCustomSequence
        ? (_activeSequence.isEmpty
              ? 0
              : requestedIndex.clamp(0, _activeSequence.length - 1).toInt())
        : max(0, requestedIndex);
    _loadPuzzle(puzzle, safeIndex, historicalView: widget.initialReviewMode);
    _startExamClockIfNeeded();
  }

  @override
  void dispose() {
    _examTicker?.cancel();
    _stopwatch.stop();
    _arrowFadeController.dispose();
    for (final player in _boardSfxPlayers) {
      player?.dispose();
    }
    _rewardAdAudioPlayer?.dispose();
    _engine.dispose();
    super.dispose();
  }

  Future<void> _loadAudioPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _muteSounds = prefs.getBool(_muteSoundsKey) ?? false;
      _hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;
    });
  }

  Future<void> _loadPuzzle(
    PuzzleItem puzzle,
    int index, {
    bool historicalView = false,
  }) async {
    final game = chess.Chess.fromFEN(puzzle.fen);
    String? setupMoveUci;
    var setupMoveApplied = false;
    var nextLineIndex = 0;

    if (puzzle.moves.isNotEmpty) {
      setupMoveUci = puzzle.moves.first;
      setupMoveApplied = _applyUciMoveOnGame(game, setupMoveUci);
      if (setupMoveApplied) {
        nextLineIndex = 1;
      }
    }

    final playerIsBlack = game.turn == chess.Color.BLACK;
    final solvedOnLoad = nextLineIndex >= puzzle.moves.length;

    final normalizedIndex = _usesCustomSequence
        ? (_activeSequence.isEmpty
              ? 0
              : index.clamp(0, _activeSequence.length - 1).toInt())
        : max(0, index);

    setState(() {
      _puzzle = puzzle;
      _puzzleIndex = normalizedIndex;
      _lineIndex = nextLineIndex;
      _busy = false;
      _solved = solvedOnLoad;
      _focusModeActive = false;
      _status = solvedOnLoad ? 'Puzzle line complete.' : 'Find the best move.';
      _dragFromSquare = null;
      _evalWhitePawns = 0.0;
      _game = game;
      _playerIsBlack = playerIsBlack;
      _evalBarPlayerIsBlack = playerIsBlack;
      _userMovesOnOddPly = setupMoveApplied;
      _coachingOffScript = false;
      _pendingRegretHalfMoves = 0;
      _lastMistakeFromEval = null;
      _lastMistakeToEval = null;
      _greyArrowFrom = null;
      _greyArrowTo = null;
    });

    _stopwatch
      ..reset()
      ..start();

    if (setupMoveApplied && setupMoveUci != null) {
      _setGreyArrowFromUci(setupMoveUci, animate: true);
    }

    await _analyzePosition();
  }

  void _startExamClockIfNeeded() {
    if (!_isExamMode || _examStartedAt != null || _examFinished) {
      return;
    }

    _examStartedAt = DateTime.now();
    _examRemaining = widget.examDuration;
    _examTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final startedAt = _examStartedAt;
      if (!mounted || startedAt == null || _examFinished) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(startedAt);
      final remaining = widget.examDuration - elapsed;
      if (remaining <= Duration.zero) {
        timer.cancel();
        setState(() => _examRemaining = Duration.zero);
        unawaited(_finishExam(timedOut: true));
        return;
      }

      setState(() => _examRemaining = remaining);
    });
  }

  Future<void> _completeExamPuzzle({required bool correct}) async {
    if (_examFinished) return;

    if (!correct && _puzzle != null) {
      final id = _puzzle!.puzzleId;
      if (!_examMistakePuzzleIds.contains(id)) {
        _examMistakePuzzleIds.add(id);
        _examMistakePuzzles.add(_puzzle!);
      }
    }

    setState(() {
      if (correct) {
        _solved = true;
      }
      _busy = true;
      _focusModeActive = false;
      _coachingOffScript = false;
      _pendingRegretHalfMoves = 0;
      _examCompletedCount += 1;
      if (correct) {
        _examCorrectCount += 1;
      }
    });

    final nextIndex = _puzzleIndex + 1;
    final isLastPuzzle = nextIndex >= _activeSequence.length;
    if (isLastPuzzle) {
      await _finishExam(timedOut: false);
      return;
    }

    await Future<void>.delayed(Duration(milliseconds: correct ? 360 : 480));
    if (!mounted) return;

    await _loadPuzzle(
      _activeSequence[nextIndex],
      nextIndex,
      historicalView: false,
    );
  }

  Future<void> _finishExam({required bool timedOut}) async {
    if (_examFinished) return;
    _examFinished = true;
    _examTicker?.cancel();

    final provider = context.read<PuzzleAcademyProvider>();
    final totalCount = _activeSequence.length;
    final remaining = timedOut ? Duration.zero : _examRemaining;
    final elapsedMs = max(
      0,
      widget.examDuration.inMilliseconds - remaining.inMilliseconds,
    );
    final examScore = provider.calculateExamScore(
      correctCount: _examCorrectCount,
      totalCount: totalCount,
      remaining: remaining,
      nodeElo: widget.node.startElo,
      timeLimit: widget.examDuration,
    );
    final result = AcademyExamResult(
      nodeKey: widget.node.key,
      score: examScore,
      leaderboardScore: provider.calculateLeaderboardScore(
        examScore: examScore,
        nodeElo: widget.node.startElo,
      ),
      correctCount: _examCorrectCount,
      totalCount: totalCount,
      elapsedMs: elapsedMs,
      timeLimitMs: widget.examDuration.inMilliseconds,
      completedAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    await provider.recordExamResult(result);
    if (!mounted) return;

    final grade = result.grade;
    final accuracy = totalCount <= 0
        ? 0
        : ((result.correctCount / totalCount) * 100).round();
    final heading = timedOut ? 'Exam Time Expired' : 'Exam Complete';
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;

    final reviewMistakes = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final palette = puzzleAcademyPalette(
          dialogContext,
          monochromeOverride: monochrome,
        );
        return PuzzleAcademyDialogShell(
          title: heading,
          subtitle: 'Bracket ${widget.node.title} archived to the academy board.',
          accent: palette.amber,
          icon: Icons.workspace_premium_outlined,
          monochromeOverride: monochrome,
          actions: [
            if (_examMistakePuzzles.isNotEmpty)
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: puzzleAcademyOutlinedButtonStyle(
                  palette: palette,
                  accent: palette.cyan,
                ),
                child: const Text('REVIEW MISTAKES'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: puzzleAcademyFilledButtonStyle(
                palette: palette,
                backgroundColor: palette.amber,
                foregroundColor: const Color(0xFF191204),
              ),
              child: const Text('BACK TO ACADEMY'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PuzzleAcademyTag(
                    label: 'SCORE ${result.score}',
                    accent: palette.cyan,
                    monochromeOverride: monochrome,
                  ),
                  PuzzleAcademyTag(
                    label: 'BOARD ${result.leaderboardScore}',
                    accent: palette.amber,
                    monochromeOverride: monochrome,
                  ),
                  PuzzleAcademyTag(
                    label: 'GRADE $grade',
                    accent: palette.emerald,
                    monochromeOverride: monochrome,
                  ),
                  PuzzleAcademyTag(
                    label: 'ACCURACY $accuracy%',
                    accent: palette.signal,
                    monochromeOverride: monochrome,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Solved ${result.correctCount}/$totalCount in ${_formatDuration(Duration(milliseconds: elapsedMs))}. Score blends 80% accuracy and 20% speed, so faster clean runs rank higher.',
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: 12.2,
                  weight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (reviewMistakes == true) {
      await _openReviewMistakes();
      return;
    }

    await _maybeShowExamReturnAd(Duration(milliseconds: elapsedMs));
    _exitToMap();
  }

  Future<void> _maybeShowExamReturnAd(Duration elapsed) async {
    if (elapsed < const Duration(minutes: 3)) return;

    final economy = context.read<EconomyProvider>();
    if (elapsed >= const Duration(minutes: 20)) {
      final rewarded = await AdService.instance.showRewardedAd();
      if (rewarded && mounted) {
        await economy.addCoins(50);
        await _showStatusDialog(title: 'Reward Earned', message: '+50 coins.');
      }
      return;
    }

    await AdService.instance.showInterstitialAd();
  }

  Future<void> _showRewardAdUnavailableDialog() async {
    if (!mounted) return;

    final useMonochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final palette = puzzleAcademyPalette(
          dialogContext,
          monochromeOverride: useMonochrome,
        );
        return PuzzleAcademyDialogShell(
          title: 'Ad Unavailable',
          accent: palette.signal,
          icon: Icons.error_outline_rounded,
          monochromeOverride: useMonochrome,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: puzzleAcademyFilledButtonStyle(
                palette: palette,
                backgroundColor: palette.signal,
                foregroundColor: const Color(0xFF171107),
              ),
              child: const Text('OK'),
            ),
          ],
          child: Text(
            'Rewarded ad is unavailable or was not completed. Try again when you have a stable internet connection.',
            style: puzzleAcademyHudStyle(
              palette: palette,
              size: 12.1,
              weight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showStatusDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final palette = puzzleAcademyPalette(
          dialogContext,
          monochromeOverride: monochrome,
        );
        return PuzzleAcademyDialogShell(
          title: title,
          accent: palette.cyan,
          icon: Icons.info_outline_rounded,
          monochromeOverride: monochrome,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: puzzleAcademyFilledButtonStyle(
                palette: palette,
                backgroundColor: palette.cyan,
                foregroundColor: const Color(0xFF07131F),
              ),
              child: const Text('OK'),
            ),
          ],
          child: Text(
            message,
            style: puzzleAcademyHudStyle(
              palette: palette,
              size: 12.2,
              weight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openReviewMistakes() async {
    if (_examMistakePuzzles.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleNodeScreen(
          node: widget.node,
          heroTag: widget.heroTag,
          puzzleSequence: List<PuzzleItem>.from(_examMistakePuzzles),
          sequenceTitle: 'Review Mistakes',
          initialReviewMode: true,
          cinematicThemeEnabled: widget.cinematicThemeEnabled,
          onExitToMap: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = max(0, duration.inSeconds);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  bool _applyUciMoveOnGame(chess.Chess game, String uci) {
    if (uci.length < 4) return false;
    final payload = <String, String>{
      'from': uci.substring(0, 2),
      'to': uci.substring(2, 4),
    };
    if (uci.length == 5) {
      payload['promotion'] = uci[4];
    }
    final result = game.move(payload);
    return result == true;
  }

  Future<void> _analyzePosition({int depth = 20}) async {
    try {
      final analysis = await _engine.analyzePosition(
        _game.fen,
        whiteToMove: _game.turn == chess.Color.WHITE,
        depth: depth,
        onEval: (value) {
          if (!mounted) return;
          setState(() => _evalWhitePawns = value);
        },
      );
      if (!mounted) return;
      if (analysis.evalWhitePawns != null) {
        setState(() => _evalWhitePawns = analysis.evalWhitePawns!);
      }
    } catch (_) {
      // Keep puzzle flow live even if engine output is unavailable.
    }
  }

  String? _resolveLegalUci(
    String from,
    String to, {
    String? preferredPromotion,
  }) {
    final requestedPromotion = preferredPromotion?.toLowerCase();
    final verbose = _game.moves(<String, dynamic>{'verbose': true});
    var hasNonPromotionCandidate = false;
    String? fallbackPromotion;
    for (final move in verbose) {
      if (move is! Map) continue;
      final candidate = move.cast<String, dynamic>();
      if (candidate['from']?.toString() != from ||
          candidate['to']?.toString() != to) {
        continue;
      }

      final promotion = candidate['promotion']?.toString().toLowerCase();
      if (promotion == null || promotion.isEmpty) {
        hasNonPromotionCandidate = true;
        continue;
      }

      final candidateUci = '$from$to$promotion';
      if (requestedPromotion != null && promotion == requestedPromotion) {
        return candidateUci;
      }
      fallbackPromotion ??= candidateUci;
    }

    if (requestedPromotion != null) {
      return fallbackPromotion ?? '$from$to$requestedPromotion';
    }

    if (hasNonPromotionCandidate) {
      return '$from$to';
    }

    return fallbackPromotion;
  }

  bool _isPromotionTarget(String from, String to) {
    final piece = _game.get(from);
    if (piece == null || piece.type != chess.Chess.PAWN) {
      return false;
    }

    final targetRank = int.tryParse(to[1]);
    if (targetRank == null) return false;

    return (piece.color == chess.Color.WHITE && targetRank == 8) ||
        (piece.color == chess.Color.BLACK && targetRank == 1);
  }

  Future<String?> _showPromotionPicker(chess.Color color) async {
    final themeProvider = context.read<AppThemeProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isWhite = color == chess.Color.WHITE;
    final options = <({String value, String label, String assetId})>[
      (value: 'q', label: 'Queen', assetId: 'q_${isWhite ? 'w' : 'b'}'),
      (value: 'r', label: 'Rook', assetId: 't_${isWhite ? 'w' : 'b'}'),
      (value: 'b', label: 'Bishop', assetId: 'b_${isWhite ? 'w' : 'b'}'),
      (value: 'n', label: 'Knight', assetId: 'n_${isWhite ? 'w' : 'b'}'),
    ];

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        final sheetScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetScheme.outline.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Promotion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: sheetScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final option in options)
                      InkWell(
                        onTap: () =>
                            Navigator.of(sheetContext).pop(option.value),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 132,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                              sheetScheme.primary.withValues(alpha: 0.06),
                              sheetScheme.surface,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: sheetScheme.outline.withValues(
                                alpha: 0.28,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPieceImage(themeProvider, option.assetId),
                              const SizedBox(height: 10),
                              Text(
                                option.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: sheetScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatEval(double value) {
    final fixed = value.toStringAsFixed(1);
    return value >= 0 ? '+$fixed' : fixed;
  }

  String _formatUciMove(String uci) {
    if (uci.length < 4) return uci;
    final promotion = uci.length == 5 ? '=${uci[4].toUpperCase()}' : '';
    return '${uci.substring(0, 2)}-${uci.substring(2, 4)}$promotion';
  }

  Future<void> _onUserDrop(String from, String to) async {
    if (!_canMove || _puzzle == null) return;

    final expected = _puzzle!.moves[_lineIndex];
    String? chosenPromotion;
    if (_isPromotionTarget(from, to)) {
      final movingPiece = _game.get(from);
      if (movingPiece == null) return;
      chosenPromotion = await _showPromotionPicker(movingPiece.color);
      if (chosenPromotion == null) return;
    }

    final attemptedUci = _resolveLegalUci(
      from,
      to,
      preferredPromotion:
          chosenPromotion ?? (expected.length == 5 ? expected[4] : null),
    );
    if (attemptedUci == null) {
      return;
    }

    if (attemptedUci != expected) {
      if (_isExamMode) {
        await _handleExamWrongMove(attemptedUci);
        return;
      }
      await _handleWrongMove(attemptedUci);
      return;
    }

    final wasCapture = _isCaptureUci(attemptedUci);
    if (!_applyUciMove(attemptedUci)) {
      return;
    }

    unawaited(_playBoardMoveSound(isCapture: wasCapture));

    if (_hapticsEnabled) await HapticFeedback.lightImpact();
    if (!_focusModeActive) {
      setState(() => _focusModeActive = true);
    }

    setState(() {
      _coachingOffScript = false;
      _pendingRegretHalfMoves = 0;
      _lastMistakeFromEval = null;
      _lastMistakeToEval = null;
      _lineIndex += 1;
      _status = 'Engine response...';
      _busy = true;
      _dragFromSquare = null;
    });

    if (_lineIndex >= _puzzle!.moves.length) {
      await _handlePuzzleSolved();
      return;
    }

    await _playOpponentCounterMove();
  }

  Future<void> _handleWrongMove(String attemptedUci) async {
    final provider = context.read<PuzzleAcademyProvider>();
    final puzzle = _puzzle;
    final evalBefore = _evalWhitePawns;

    final attemptedWasCapture = _isCaptureUci(attemptedUci);
    if (!_applyUciMove(attemptedUci)) {
      if (_hapticsEnabled) await HapticFeedback.heavyImpact();
      if (!mounted) return;
      setState(() {
        _focusModeActive = false;
        _busy = false;
        _dragFromSquare = null;
        _status = 'Find the best move.';
      });
      return;
    }

    unawaited(_playBoardMoveSound(isCapture: attemptedWasCapture));

    if (puzzle != null) {
      await provider.recordPuzzleMiss(rating: puzzle.rating);
    }

    if (_hapticsEnabled) await HapticFeedback.heavyImpact();
    if (!mounted) return;

    _setGreyArrowFromUci(attemptedUci, animate: true);

    setState(() {
      _focusModeActive = true;
      _busy = true;
      _dragFromSquare = null;
      _coachingOffScript = true;
      _pendingRegretHalfMoves = 1;
      _lastMistakeFromEval = evalBefore;
      _lastMistakeToEval = null;
      _status = 'Find the best move.';
    });

    PuzzleEngineAnalysis? analysis;
    try {
      analysis = await _engine.analyzePosition(
        _game.fen,
        whiteToMove: _game.turn == chess.Color.WHITE,
        depth: 18,
        onEval: (value) {
          if (!mounted) return;
          setState(() => _evalWhitePawns = value);
        },
      );
    } catch (_) {
      // Leave the position playable even if the engine can't answer.
    }

    if (!mounted) return;

    if (analysis?.evalWhitePawns != null) {
      setState(() => _evalWhitePawns = analysis!.evalWhitePawns!);
    }

    var counterMove = analysis?.bestMove;
    var counterWasCapture = false;
    if (counterMove != null) {
      counterWasCapture = _isCaptureUci(counterMove);
      if (!_applyUciMove(counterMove)) {
        counterMove = null;
      }
    }

    if (counterMove != null) {
      unawaited(_playBoardMoveSound(isCapture: counterWasCapture));
      _setGreyArrowFromUci(counterMove, animate: true);
      setState(() {
        _pendingRegretHalfMoves = 2;
      });
      await _analyzePosition(depth: 18);
    }

    if (!mounted) return;

    final swingTo = _evalWhitePawns;
    setState(() {
      _busy = false;
      _focusModeActive = false;
      _lastMistakeToEval = swingTo;
      _status = 'Find the best move.';
    });
  }

  Future<void> _handleExamWrongMove(String attemptedUci) async {
    if (_hapticsEnabled) await HapticFeedback.heavyImpact();
    if (!mounted) return;

    _setGreyArrowFromUci(attemptedUci, animate: true);
    unawaited(_playWrongMoveSound());
    setState(() {
      _busy = true;
      _focusModeActive = false;
      _dragFromSquare = null;
      _status = 'Incorrect. Loading the next exam puzzle...';
    });

    await _completeExamPuzzle(correct: false);
  }

  Future<void> _playOpponentCounterMove() async {
    final puzzle = _puzzle;
    if (puzzle == null || _lineIndex >= puzzle.moves.length) {
      await _handlePuzzleSolved();
      return;
    }

    final expectedCounter = puzzle.moves[_lineIndex];
    final expectedCounterWasCapture = _isCaptureUci(expectedCounter);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final applied = _applyUciMove(expectedCounter);
    if (!applied) {
      setState(() {
        _busy = false;
        _status = 'Coach could not continue this line. Try the next puzzle.';
      });
      return;
    }

    unawaited(_playBoardMoveSound(isCapture: expectedCounterWasCapture));

    _setGreyArrowFromUci(expectedCounter, animate: true);

    if (!mounted) return;
    setState(() {
      _lineIndex += 1;
      _busy = false;
      _focusModeActive = false;
      _status = _lineIndex >= puzzle.moves.length
          ? 'Solved. Continue to next puzzle.'
          : 'Continue';
    });

    if (_lineIndex >= puzzle.moves.length) {
      await _handlePuzzleSolved();
      return;
    }

    unawaited(_analyzePosition());
  }

  bool _applyUciMove(String uci) {
    if (uci.length < 4) return false;
    final payload = <String, String>{
      'from': uci.substring(0, 2),
      'to': uci.substring(2, 4),
    };
    if (uci.length == 5) {
      payload['promotion'] = uci[4];
    }
    final result = _game.move(payload);
    return result == true;
  }

  bool _isCaptureUci(String uci) {
    if (uci.length < 4) {
      return false;
    }
    final targetSquare = uci.substring(2, 4);
    return _game.get(targetSquare) != null;
  }

  Future<void> _playBoardMoveSound({required bool isCapture}) async {
    if (_muteSounds) {
      return;
    }

    final assetPath = isCapture
        ? 'sounds/take1.wav'
        : 'sounds/move${_rng.nextInt(8) + 1}.wav';
    final player = _takeBoardSfxPlayer();

    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(
        AssetSource(assetPath),
        mode: _boardSfxPlayerMode,
        volume: 1.0,
      );
    } catch (_) {
      // Keep puzzle flow responsive if audio playback fails.
    }
  }

  Future<void> _playWrongMoveSound() async {
    if (_muteSounds) {
      return;
    }

    final player = _takeBoardSfxPlayer();

    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(
        AssetSource('sounds/wrongmove.wav'),
        mode: _boardSfxPlayerMode,
        volume: 1.0,
      );
    } catch (_) {
      // Keep the exam flow responsive if audio playback fails.
    }
  }

  void _setGreyArrowFromUci(String? uci, {required bool animate}) {
    if (uci == null || uci.length < 4) return;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    setState(() {
      _greyArrowFrom = from;
      _greyArrowTo = to;
    });
    if (animate) {
      _arrowFadeController
        ..stop()
        ..value = 0.0
        ..forward();
    } else {
      _arrowFadeController.value = 1.0;
    }
  }

  Future<void> _handlePuzzleSolved() async {
    final puzzle = _puzzle;
    if (puzzle == null) return;

    if (mounted) {
      setState(() {
        _solved = true;
        _busy = false;
        _focusModeActive = false;
        _coachingOffScript = false;
        _pendingRegretHalfMoves = 0;
        _status = 'Solved. Continue to next puzzle.';
      });
    }

    if (_isExamMode) {
      if (_hapticsEnabled) await HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() {
        _status = 'Correct. Loading the next exam puzzle...';
      });
      await _completeExamPuzzle(correct: true);
      return;
    }

    final provider = context.read<PuzzleAcademyProvider>();

    final isDaily =
        _isDailySequence ||
        provider.todayDailyPuzzle?.puzzleId == puzzle.puzzleId;
    await provider.recordPuzzleSolve(
      puzzle: puzzle,
      solveTime: _stopwatch.elapsed,
      daily: isDaily,
      brilliant: puzzle.moves.length >= 5 || puzzle.rating >= 2200,
    );

    await _maybeShowAcademyInterstitialReward(provider);

    if (!mounted) return;

    setState(() {});

    if (_hapticsEnabled) await HapticFeedback.mediumImpact();
  }

  Future<void> _maybeShowAcademyInterstitialReward(
    PuzzleAcademyProvider provider,
  ) async {
    if (!provider.shouldShowBrainBreak) {
      return;
    }

    final academyAdFree = await _isAcademyTuitionPassOwned();
    if (academyAdFree) {
      if (!mounted) return;
      final economy = context.read<EconomyProvider>();
      await economy.awardAcademyInterstitialCoins();
      await provider.syncCoinsFromStoreState(notify: true);
      if (!mounted) return;
      await _showStatusDialog(
        title: 'Academy Break Complete',
        message: '+10 coins.',
      );
      provider.consumeBrainBreakTrigger();
      return;
    }

    final shown = await AdService.instance.showInterstitialAd();
    if (shown && mounted) {
      final economy = context.read<EconomyProvider>();
      await economy.awardAcademyInterstitialCoins();
      await provider.syncCoinsFromStoreState(notify: true);
      if (!mounted) return;
      await _showStatusDialog(
        title: 'Academy Break Complete',
        message: '+10 coins.',
      );
    }

    provider.consumeBrainBreakTrigger();
  }

  Future<void> _regretLastMistake() async {
    if (_pendingRegretHalfMoves <= 0 || _busy) return;

    var remaining = _pendingRegretHalfMoves;
    while (remaining > 0) {
      final undone = _game.undo_move();
      if (undone == null) break;
      remaining -= 1;
    }

    if (_hapticsEnabled) await HapticFeedback.selectionClick();
    if (!mounted) return;

    setState(() {
      _busy = false;
      _focusModeActive = false;
      _coachingOffScript = false;
      _pendingRegretHalfMoves = 0;
      _dragFromSquare = null;
      _greyArrowFrom = null;
      _greyArrowTo = null;
      _lastMistakeFromEval = null;
      _lastMistakeToEval = null;
      _status = 'Back on puzzle line. Find the best move.';
    });

    await _analyzePosition();
  }

  Future<void> _useHint(PuzzleAcademyProvider provider) async {
    if (_isExamMode) return;
    final puzzle = _puzzle;
    if (puzzle == null || _busy || _solved) return;

    if (_coachingOffScript && _pendingRegretHalfMoves > 0) {
      await _regretLastMistake();
      if (!mounted) return;
    }

    final consumed = await provider.consumeHint();
    if (!mounted) return;
    if (!consumed) {
      await _showStatusDialog(
        title: 'Hints Unavailable',
        message: 'No hints available.',
      );
      return;
    }

    final hintedMove = puzzle.moves[_lineIndex];
    _setGreyArrowFromUci(hintedMove, animate: true);
    setState(() {
      _status =
          'Hint: play ${_formatUciMove(hintedMove)}. Hints left: ${provider.progress.freeHints}.';
    });
  }

  Future<void> _skipCurrentPuzzle(PuzzleAcademyProvider provider) async {
    if (_isExamMode) return;
    final puzzle = _puzzle;
    if (puzzle == null || _busy || _solved) return;

    final skipped = await provider.skipPuzzle(puzzle);
    if (!mounted) return;
    if (!skipped) {
      await _showStatusDialog(
        title: 'Skips Unavailable',
        message: 'No skips available.',
      );
      return;
    }

    await _showStatusDialog(
      title: 'Puzzle Skipped',
      message: 'Puzzle skipped.',
    );
    await _openNextPuzzle(allowUncleared: true);
  }

  MapEntry<int, PuzzleItem>? _adjacentNavigablePuzzle(
    PuzzleAcademyProvider provider, {
    required bool forward,
  }) {
    if (_usesCustomSequence) {
      final index = _puzzleIndex + (forward ? 1 : -1);
      if (index < 0 || index >= _activeSequence.length) {
        return null;
      }
      return MapEntry<int, PuzzleItem>(index, _activeSequence[index]);
    }

    final startIndex = _puzzleIndex + (forward ? 1 : -1);
    final endIndex = provider.gridPuzzleCountForNode(widget.node);

    for (
      var index = startIndex;
      forward ? index < endIndex : index >= 0;
      index += forward ? 1 : -1
    ) {
      final candidate = provider.puzzleForNodeIndex(widget.node, index);
      if (candidate == null || !provider.canOpenGridIndex(widget.node, index)) {
        continue;
      }
      return MapEntry<int, PuzzleItem>(index, candidate);
    }

    return null;
  }

  Future<void> _openNextPuzzle({bool allowUncleared = false}) async {
    final provider = context.read<PuzzleAcademyProvider>();
    final currentPuzzle = _puzzle;
    final currentSolvedHistorically =
        currentPuzzle != null &&
        provider.isPuzzleSolved(currentPuzzle.puzzleId);
    final currentSkippedHistorically =
        currentPuzzle != null &&
        provider.isPuzzleSkipped(currentPuzzle.puzzleId);
    final nextEntry = _adjacentNavigablePuzzle(provider, forward: true);
    final isReviewMistakeSequence =
        widget.initialReviewMode && widget.sequenceTitle == 'Review Mistakes';
    if (nextEntry == null ||
        (!allowUncleared &&
            !isReviewMistakeSequence &&
            !_solved &&
            !currentSolvedHistorically &&
            !currentSkippedHistorically)) {
      return;
    }

    if (_usesCustomSequence) {
      await _loadPuzzle(nextEntry.value, nextEntry.key, historicalView: false);
      return;
    }

    final nextState = provider.tileStateForNodeIndex(
      widget.node,
      nextEntry.key,
    );
    await _loadPuzzle(
      nextEntry.value,
      nextEntry.key,
      historicalView: nextState != PuzzleGridTileState.nextAvailable,
    );
  }

  Future<void> _openPreviousPuzzle() async {
    if (_isExamMode) return;
    final provider = context.read<PuzzleAcademyProvider>();
    final previousEntry = _adjacentNavigablePuzzle(provider, forward: false);
    if (previousEntry == null) return;

    if (_usesCustomSequence) {
      await _loadPuzzle(
        previousEntry.value,
        previousEntry.key,
        historicalView: true,
      );
      return;
    }

    await _loadPuzzle(
      previousEntry.value,
      previousEntry.key,
      historicalView: true,
    );
  }

  Future<void> _claimDailySequenceReward(PuzzleAcademyProvider provider) async {
    if (provider.todayDailyChallengeRewardClaimed) {
      if (!mounted) return;
      await _showStatusDialog(
        title: 'Already Claimed',
        message: 'Today\'s daily reward is already claimed.',
      );
      return;
    }

    final economy = context.read<EconomyProvider>();
    final academyAdFree = await _isAcademyTuitionPassOwned();
    final rewardEarned = academyAdFree
        ? true
        : await AdService.instance.showRewardedAd();
    if (!mounted) {
      return;
    }
    if (!rewardEarned) {
      await _showRewardAdUnavailableDialog();
      return;
    }

    const rewardAmount = 200;
    await economy.addCoins(rewardAmount);
    await provider.markTodayDailyChallengeRewardClaimed();
    await provider.syncCoinsFromStoreState(notify: true);

    if (!mounted) return;
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final palette = puzzleAcademyPalette(
          dialogContext,
          monochromeOverride: monochrome,
        );
        final navigator = Navigator.of(dialogContext);
        return PuzzleAcademyDialogShell(
          title: 'Daily Challenge Complete!',
          subtitle: 'Reward confirmed for today\'s academy run.',
          accent: palette.emerald,
          icon: Icons.emoji_events_rounded,
          monochromeOverride: monochrome,
          actions: [
            FilledButton(
              onPressed: () async {
                final rewardPlayer = _ensureRewardAdAudioPlayer();
                try {
                  await rewardPlayer.stop();
                  await rewardPlayer.setReleaseMode(ReleaseMode.stop);
                  await rewardPlayer.setSource(
                    AssetSource('sounds/coinbag.mp3'),
                  );
                  await rewardPlayer.setVolume(1.0);
                  await rewardPlayer.resume();
                } catch (_) {
                  // Ignore sound playback failures.
                }
                navigator.pop();
              },
              style: puzzleAcademyFilledButtonStyle(
                palette: palette,
                backgroundColor: palette.emerald,
                foregroundColor: const Color(0xFF07131F),
              ),
              child: const Text('CONFIRM'),
            ),
          ],
          child: Text(
            '+$rewardAmount coins awarded. Great work completing today\'s daily challenge!',
            style: puzzleAcademyHudStyle(
              palette: palette,
              size: 12.2,
              weight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    await _exitToMap();
  }

  Future<bool> _isAcademyTuitionPassOwned() async {
    // Check IAP delivery flag first (survives reinstall / restore).
    if (await PurchaseService.instance.isOwned(IapProducts.academyPass)) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeStateKey);
    if (raw == null || raw.isEmpty) {
      return false;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return false;
    }
    final owned = decoded[_academyTuitionPassKey];
    return owned == true;
  }

  Future<void> _handleSquareTap(String square) async {
    if (!_canMove) return;

    final tappedPiece = _game.get(square);
    final selectedFrom = _dragFromSquare;
    if (selectedFrom == null) {
      if (tappedPiece != null && _isPieceTurnColor(tappedPiece)) {
        setState(() => _dragFromSquare = square);
      }
      return;
    }

    if (selectedFrom == square) {
      setState(() => _dragFromSquare = null);
      return;
    }

    if (tappedPiece != null && _isPieceTurnColor(tappedPiece)) {
      setState(() => _dragFromSquare = square);
      return;
    }

    if (!_legalTargetsForSquare(selectedFrom).contains(square)) {
      return;
    }

    await _onUserDrop(selectedFrom, square);
  }

  Future<void> _exitToMap() async {
    if (_isExamMode && !_examFinished) {
      final monochrome =
          context.read<AppThemeProvider>().isMonochrome ||
          widget.cinematicThemeEnabled;
      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final palette = puzzleAcademyPalette(
            dialogContext,
            monochromeOverride: monochrome,
          );
          return PuzzleAcademyDialogShell(
            title: 'End Exam Early?',
            accent: palette.signal,
            icon: Icons.warning_amber_rounded,
            monochromeOverride: monochrome,
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: puzzleAcademyOutlinedButtonStyle(
                  palette: palette,
                  accent: palette.cyan,
                ),
                child: const Text('CONTINUE EXAM'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: puzzleAcademyFilledButtonStyle(
                  palette: palette,
                  backgroundColor: palette.signal,
                  foregroundColor: const Color(0xFF171107),
                ),
                child: const Text('SUBMIT EXAM'),
              ),
            ],
            child: Text(
              'Leaving now submits your current score and returns to the Academy map.',
              style: puzzleAcademyHudStyle(
                palette: palette,
                size: 12.1,
                weight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          );
        },
      );

      if (shouldSubmit != true) {
        return;
      }

      await _finishExam(timedOut: false);
      return;
    }

    final navigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final callback = widget.onExitToMap;
    final isReviewMistakeExit =
        widget.initialReviewMode && widget.sequenceTitle == 'Review Mistakes';
    if (callback != null) {
      if (isReviewMistakeExit) {
        await AdService.instance.showInterstitialAd();
      }
      if (!mounted) return;
      try {
        callback();
      } catch (_) {
        if (await navigator.maybePop()) {
          return;
        }
        await rootNavigator.maybePop();
      }
      return;
    }
    if (isReviewMistakeExit) {
      await AdService.instance.showInterstitialAd();
    }
    if (!mounted) return;
    if (!await navigator.maybePop()) {
      await rootNavigator.maybePop();
    }
  }

  List<String> _legalTargetsForSquare(String from) {
    final verbose = _game.moves(<String, dynamic>{'verbose': true});
    final targets = <String>[];
    for (final move in verbose) {
      if (move is! Map) continue;
      final m = move.cast<String, dynamic>();
      if (m['from']?.toString() == from) {
        targets.add(m['to']?.toString() ?? '');
      }
    }
    return targets.where((e) => e.length == 2).toSet().toList(growable: false);
  }

  bool _isPieceTurnColor(chess.Piece piece) {
    final isWhiteTurn = _game.turn == chess.Color.WHITE;
    return (piece.color == chess.Color.WHITE) == isWhiteTurn;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PuzzleAcademyProvider>();
    final themeProvider = context.watch<AppThemeProvider>();
    final puzzle = _puzzle;
    final useMonochrome =
        themeProvider.isMonochrome || widget.cinematicThemeEnabled;
    final palette = _academyPalette(useMonochrome);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: palette.backdrop,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBackdrop(context, useMonochrome)),
            if (puzzle == null)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  _nonBoardChromeFilter(
                    useMonochrome,
                    AnimatedOpacity(
                      opacity: _focusModeActive ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      child: _buildTopBar(provider, themeProvider),
                    ),
                  ),
                  Expanded(
                    child: isLandscape
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 8, 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 8,
                                  child: _buildBoardCard(
                                    themeProvider,
                                    monochrome: useMonochrome,
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: AnimatedOpacity(
                                    opacity: _focusModeActive ? 0.5 : 1.0,
                                    duration: const Duration(milliseconds: 220),
                                    child: _buildLandscapeControlRail(
                                      provider,
                                      useMonochrome,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildBoardCard(
                                  themeProvider,
                                  monochrome: useMonochrome,
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: _nonBoardChromeFilter(
                                  useMonochrome,
                                  AnimatedOpacity(
                                    opacity: _focusModeActive ? 0.5 : 1.0,
                                    duration: const Duration(milliseconds: 220),
                                    child: _buildIntelPanel(provider),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (!isLandscape) _buildBottomActions(provider),
                ],
              ),
          ],
        ),
      ),
    );
  }

  PuzzleAcademyPalette _academyPalette(bool monochrome) {
    return puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
  }

  Color _modeAccent(PuzzleAcademyPalette palette) {
    if (_isExamMode) return palette.amber;
    if (_isDailySequence) return palette.emerald;
    if (widget.initialReviewMode) return palette.signal;
    return palette.cyan;
  }

  String _modeIntelMessage() {
    if (_isExamMode) {
      return 'Exam mode runs a fixed 50-puzzle bracket. Score weights 80% accuracy and 20% speed, and leaving early submits the current run.';
    }
    if (_isDailySequence) {
      return 'Daily mode runs today\'s sequence in order. Keep live status minimal here and use reward/status popups for secondary rules and reward handling.';
    }
    if (widget.initialReviewMode) {
      return 'Review mode replays archived mistakes without changing progression. Use it to clean up weak spots and move back to the academy when the sequence is done.';
    }
    return 'Training mode tracks the current puzzle, eval swing, and action economy. Hints, skips, and regret remain available without changing the puzzle progression rules.';
  }

  Widget _nonBoardChromeFilter(bool monochrome, Widget child) {
    if (!monochrome) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: child,
    );
  }

  Widget _buildBackdrop(BuildContext context, bool monochrome) {
    final palette = _academyPalette(monochrome);
    final leadGlow = _modeAccent(palette);
    final altGlow = _isExamMode ? palette.signal : palette.amber;
    final topColor = Color.alphaBlend(
      leadGlow.withValues(
        alpha: palette.isDark ? 0.14 : 0.06,
      ),
      palette.backdrop,
    );
    final bottomColor = Color.alphaBlend(
      altGlow.withValues(
        alpha: palette.isDark ? 0.10 : 0.05,
      ),
      palette.backdrop,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, palette.backdrop, bottomColor],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-0.8, -0.7),
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: leadGlow.withValues(alpha: monochrome ? 0.08 : 0.12),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.9, -0.85),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: altGlow.withValues(alpha: monochrome ? 0.07 : 0.10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    PuzzleAcademyProvider provider,
    AppThemeProvider themeProvider,
  ) {
    final monochrome = themeProvider.isMonochrome || widget.cinematicThemeEnabled;
    final palette = _academyPalette(monochrome);
    final accent = _modeAccent(palette);
    final currentRating = _puzzle?.rating ?? widget.node.startElo;
    final displayedStartElo = (currentRating ~/ 50) * 50;
    final total = _usesCustomSequence
        ? _activeSequence.length
        : provider.gridPuzzleCountForNode(widget.node);
    final index = _puzzleIndex + 1;
    final title = _isExamMode
        ? 'Bracket ${widget.node.title} Exam'
        : (_isDailySequence
              ? '${widget.sequenceTitle ?? 'Daily Challenge'} • ${widget.node.title}'
              : 'Elo Bracket ${widget.node.title}');
    final subtitle = _isExamMode
        ? 'Puzzle #$index of $total • ${_formatDuration(_examRemaining)} left'
        : 'Puzzle #$index of $total';
    final modeInfoTitle = _isExamMode
        ? 'Exam Mode'
        : _isDailySequence
        ? 'Daily Sequence'
        : widget.initialReviewMode
        ? 'Review Mode'
        : 'Training Mode';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Container(
        decoration: puzzleAcademyPanelDecoration(
          palette: palette,
          accent: accent,
          radius: 10,
          elevated: false,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accent.withValues(alpha: 0.50), width: 2),
                ),
                child: IconButton(
                  tooltip: 'Exit to Map',
                  padding: EdgeInsets.zero,
                  onPressed: _exitToMap,
                  icon: Icon(Icons.close_rounded, color: accent, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Hero(
                tag: widget.heroTag,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.68),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$displayedStartElo',
                        style: puzzleAcademyHudStyle(
                          palette: palette,
                          size: 11.6,
                          weight: FontWeight.w800,
                          letterSpacing: 0.9,
                          height: 1.0,
                          color: palette.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: puzzleAcademyDisplayStyle(
                        palette: palette,
                        size: 18,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: puzzleAcademyHudStyle(
                        palette: palette,
                        size: 11.7,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isExamMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PuzzleAcademyTag(
                        label: '$_examCorrectCount/${_activeSequence.length}',
                        accent: palette.amber,
                        icon: Icons.verified_outlined,
                        monochromeOverride: monochrome,
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PuzzleAcademyInfoButton(
                        title: modeInfoTitle,
                        message: _modeIntelMessage(),
                        accent: accent,
                        monochromeOverride: monochrome,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.46),
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          tooltip: 'Settings',
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              _openBoardAndPieceThemeSettings(themeProvider),
                          icon: Icon(
                            Icons.settings_outlined,
                            color: accent,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBoardAndPieceThemeSettings(
    AppThemeProvider themeProvider,
  ) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = !(prefs.getBool(_muteSoundsKey) ?? false);
    final hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;

    if (!mounted) return;
    try {
      await showAcademyThemeSettingsSheet(
        context: context,
        themeProvider: themeProvider,
        soundEnabled: soundEnabled,
        hapticsEnabled: hapticsEnabled,
        onSoundEnabledChanged: (enabled) async {
          await prefs.setBool(_muteSoundsKey, !enabled);
          if (mounted) {
            setState(() {
              _muteSounds = !enabled;
            });
          }
        },
        onHapticsEnabledChanged: (enabled) async {
          await prefs.setBool(_hapticsEnabledKey, enabled);
          if (mounted) setState(() => _hapticsEnabled = enabled);
        },
      );
    } catch (_) {
      if (!mounted) return;
      await _showStatusDialog(
        title: 'Settings Unavailable',
        message: 'Academy settings could not be opened right now.',
      );
    }
  }

  Widget _buildBoardCard(AppThemeProvider theme, {required bool monochrome}) {
    final palette = _academyPalette(monochrome);
    final accent = _modeAccent(palette);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Container(
        decoration: puzzleAcademyPanelDecoration(
          palette: palette,
          accent: accent,
          fillColor: palette.panel,
          radius: 10,
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    _formatEval(
                      _evalBarPlayerIsBlack
                          ? -_evalWhitePawns
                          : _evalWhitePawns,
                    ),
                    style: puzzleAcademyHudStyle(
                      palette: palette,
                      size: 10.8,
                      weight: FontWeight.w800,
                      letterSpacing: 0.8,
                      height: 1.0,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: _PerspectiveEvalBar(
                        evalFromPlayerPerspective: _evalBarPlayerIsBlack
                            ? -_evalWhitePawns
                            : _evalWhitePawns,
                        playerIsBlack: _evalBarPlayerIsBlack,
                        monochrome: monochrome,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildBoard(theme)),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _arrowFadeController,
                            builder: (context, _) {
                              final opacity =
                                  (1.0 - (_arrowFadeController.value * 0.75))
                                      .clamp(0.25, 1.0);
                              return CustomPaint(
                                painter: _GreyArrowPainter(
                                  fromSquare: _greyArrowFrom,
                                  toSquare: _greyArrowTo,
                                  flipped: _playerIsBlack,
                                  opacity: opacity,
                                ),
                              );
                            },
                          ),
                        ),
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

  Widget _buildBoard(AppThemeProvider theme) {
    final palette = theme.boardPalette();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 64,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemBuilder: (context, visualIndex) {
        final visualFile = visualIndex % 8;
        final visualRankFromTop = visualIndex ~/ 8;

        final boardFile = _playerIsBlack ? 7 - visualFile : visualFile;
        final boardRank = _playerIsBlack
            ? visualRankFromTop + 1
            : 8 - visualRankFromTop;

        final square = '${String.fromCharCode(97 + boardFile)}$boardRank';
        final piece = _game.get(square);
        final dark = (boardFile + boardRank).isEven;
        final showFileLabel = visualRankFromTop == 7;
        final showRankLabel = visualFile == 0;
        final labelColor = dark ? palette.lightSquare : palette.darkSquare;

        final isTarget =
            _dragFromSquare != null &&
            _legalTargetsForSquare(_dragFromSquare!).contains(square);
        final isCaptureTarget = isTarget && piece != null;
        const targetDotColor = Color(0xFF9EA8BA);

        return DragTarget<_DragPieceData>(
          onWillAcceptWithDetails: (details) {
            final targets = _legalTargetsForSquare(details.data.from);
            return _canMove && targets.contains(square);
          },
          onAcceptWithDetails: (details) {
            _onUserDrop(details.data.from, square);
            setState(() => _dragFromSquare = null);
          },
          builder: (context, candidateData, rejectedData) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: dark ? palette.darkSquare : palette.lightSquare,
              ),
              child: InkWell(
                onTap: () => unawaited(_handleSquareTap(square)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isTarget)
                      Center(
                        child: Container(
                          width: isCaptureTarget ? 26 : 12,
                          height: isCaptureTarget ? 26 : 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCaptureTarget
                                ? Colors.transparent
                                : targetDotColor.withValues(alpha: 0.60),
                            border: isCaptureTarget
                                ? Border.all(
                                    color: targetDotColor.withValues(
                                      alpha: 0.82,
                                    ),
                                    width: 2,
                                  )
                                : null,
                          ),
                        ),
                      ),
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
                                '$boardRank',
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
                                String.fromCharCode(97 + boardFile),
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
                    if (piece != null) _buildPiece(square, piece, theme),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPiece(String square, chess.Piece piece, AppThemeProvider theme) {
    final canDrag = _canMove && _isPieceTurnColor(piece);
    final assetId = _pieceAssetId(piece);
    final pieceWidget = _buildPieceImage(theme, assetId);

    if (!canDrag) return pieceWidget;

    return Draggable<_DragPieceData>(
      data: _DragPieceData(from: square),
      feedback: SizedBox(width: 54, height: 54, child: pieceWidget),
      childWhenDragging: Opacity(opacity: 0.25, child: pieceWidget),
      onDragStarted: () => setState(() => _dragFromSquare = square),
      onDragEnd: (_) => setState(() => _dragFromSquare = null),
      child: pieceWidget,
    );
  }

  Widget _buildPieceImage(AppThemeProvider theme, String assetId) {
    final baseImage = Image.asset(
      'assets/pieces/$assetId.png',
      fit: BoxFit.contain,
    );
    final tinted = theme.useClassicPieces
        ? baseImage
        : ColorFiltered(
            colorFilter: ColorFilter.mode(
              theme.pieceTintColor(assetId),
              BlendMode.modulate,
            ),
            child: baseImage,
          );

    final isBlackPiece = assetId.endsWith('_b');
    if (!isBlackPiece) {
      return Padding(padding: const EdgeInsets.all(2), child: tinted);
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final offset in const [
            Offset(-0.65, 0),
            Offset(0.65, 0),
            Offset(0, -0.65),
            Offset(0, 0.65),
            Offset(-0.5, -0.5),
            Offset(0.5, -0.5),
            Offset(-0.5, 0.5),
            Offset(0.5, 0.5),
          ])
            Transform.translate(
              offset: offset,
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  'assets/pieces/$assetId.png',
                  fit: BoxFit.contain,
                  color: const Color(0xFFF7FBFF),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          tinted,
        ],
      ),
    );
  }

  String _pieceAssetId(chess.Piece piece) {
    final fenType = _pieceTypeFenChar(piece.type);
    final assetType = switch (fenType) {
      'p' => 'p',
      'r' => 't',
      'n' => 'n',
      'b' => 'b',
      'q' => 'q',
      'k' => 'k',
      _ => 'p',
    };
    final colorSuffix = piece.color == chess.Color.WHITE ? 'w' : 'b';
    return '${assetType}_$colorSuffix';
  }

  String _pieceTypeFenChar(chess.PieceType type) {
    if (identical(type, chess.Chess.PAWN) || type == chess.Chess.PAWN) {
      return 'p';
    }
    if (identical(type, chess.Chess.ROOK) || type == chess.Chess.ROOK) {
      return 'r';
    }
    if (identical(type, chess.Chess.KNIGHT) || type == chess.Chess.KNIGHT) {
      return 'n';
    }
    if (identical(type, chess.Chess.BISHOP) || type == chess.Chess.BISHOP) {
      return 'b';
    }
    if (identical(type, chess.Chess.QUEEN) || type == chess.Chess.QUEEN) {
      return 'q';
    }
    if (identical(type, chess.Chess.KING) || type == chess.Chess.KING) {
      return 'k';
    }

    final normalized = type.toString().toLowerCase();
    return switch (normalized) {
      'p' || 'pawn' => 'p',
      'r' || 'rook' => 'r',
      'n' || 'knight' => 'n',
      'b' || 'bishop' => 'b',
      'q' || 'queen' => 'q',
      'k' || 'king' => 'k',
      _ => 'p',
    };
  }

  Widget _buildIntelPanel(PuzzleAcademyProvider provider) {
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;
    final palette = _academyPalette(monochrome);
    final accent = _modeAccent(palette);
    final total = _usesCustomSequence
        ? _activeSequence.length
        : provider.gridPuzzleCountForNode(widget.node);
    final modeLabel = _isExamMode
        ? 'Exam'
        : _isDailySequence
        ? 'Daily'
        : widget.initialReviewMode
        ? 'Review'
        : 'Training';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: puzzleAcademyPanelDecoration(
          palette: palette,
          accent: accent,
          fillColor: palette.panelAlt,
          radius: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Puzzle Intel',
                    style: puzzleAcademyDisplayStyle(
                      palette: palette,
                      size: 15,
                      color: accent,
                    ),
                  ),
                ),
                PuzzleAcademyInfoButton(
                  title: 'Puzzle Intel',
                  message: _modeIntelMessage(),
                  accent: accent,
                  monochromeOverride: monochrome,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(
              label: 'Mode',
              value: modeLabel,
              monochrome: monochrome,
            ),
            _InfoLine(
              label: 'State',
              value: _solved
                  ? 'Solved'
                  : (_busy
                        ? 'Engine Response'
                        : (_coachingOffScript
                              ? 'Coach Review'
                              : 'Solving')),
              monochrome: monochrome,
            ),
            _InfoLine(
              label: 'Progress',
              value: '${_puzzleIndex + 1}/$total',
              monochrome: monochrome,
            ),
            _InfoLine(
              label: 'Eval',
              value: _formatEval(
                _evalBarPlayerIsBlack ? -_evalWhitePawns : _evalWhitePawns,
              ),
              monochrome: monochrome,
            ),
            if (_lastMistakeFromEval != null && _lastMistakeToEval != null)
              _InfoLine(
                label: 'Swing',
                value:
                    '${_formatEval(_evalBarPlayerIsBlack ? -_lastMistakeFromEval! : _lastMistakeFromEval!)} -> ${_formatEval(_evalBarPlayerIsBlack ? -_lastMistakeToEval! : _lastMistakeToEval!)}',
                monochrome: monochrome,
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                _status,
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: 12.1,
                  weight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeControlRail(
    PuzzleAcademyProvider provider,
    bool monochrome,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
      child: Column(
        children: [
          Expanded(
            child: _nonBoardChromeFilter(
              monochrome,
              _buildIntelPanel(provider),
            ),
          ),
          _buildBottomActions(provider, vertical: true),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    PuzzleAcademyProvider provider, {
    bool vertical = false,
  }) {
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;
    final palette = _academyPalette(monochrome);
    if (_isExamMode) {
      final accuracy = _examCompletedCount <= 0
          ? 0
          : ((_examCorrectCount / _examCompletedCount) * 100).round();
      final statusCard = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: puzzleAcademyPanelDecoration(
          palette: palette,
          accent: palette.amber,
          fillColor: palette.panelAlt,
          radius: 10,
          elevated: false,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Correct $_examCorrectCount/${_activeSequence.length}',
                    style: puzzleAcademyHudStyle(
                      palette: palette,
                      size: 11.3,
                      weight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accuracy $accuracy% • ${_formatDuration(_examRemaining)} left',
                    style: puzzleAcademyHudStyle(
                      palette: palette,
                      size: 11.0,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            PuzzleAcademyInfoButton(
              title: 'Exam Scoring',
              message:
                  'Exam score blends 80% accuracy and 20% speed. Your leaderboard score then scales that result by node difficulty so stronger brackets are worth more.',
              accent: palette.amber,
              monochromeOverride: monochrome,
            ),
          ],
        ),
      );

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: vertical ? statusCard : Column(children: [statusCard]),
      );
    }

    final hasPrevious = _puzzleIndex > 0;
    final canRegret = _pendingRegretHalfMoves > 0 && !_busy;
    final canHint = !_busy && !_solved && provider.progress.freeHints > 0;
    final isReviewMistakeSequence =
        widget.initialReviewMode && widget.sequenceTitle == 'Review Mistakes';
    final canSkip =
        !_busy &&
        !_solved &&
        provider.progress.freeSkips > 0 &&
        !isReviewMistakeSequence;
    final nextPuzzle = _adjacentNavigablePuzzle(provider, forward: true);
    final currentPuzzle = _puzzle;
    final currentSolvedHistorically =
        currentPuzzle != null &&
        provider.isPuzzleSolved(currentPuzzle.puzzleId);
    final currentSkippedHistorically =
        currentPuzzle != null &&
        provider.isPuzzleSkipped(currentPuzzle.puzzleId);
    final isLastReviewMistake =
        isReviewMistakeSequence && _puzzleIndex == _activeSequence.length - 1;
    final reviewModeCanAdvanceToNext =
        !_busy && nextPuzzle != null && !isLastReviewMistake;
    final normalModeCanAdvanceToNext =
        !_busy &&
        nextPuzzle != null &&
        nextPuzzle.value.puzzleId != _puzzle?.puzzleId &&
        (_solved || currentSolvedHistorically || currentSkippedHistorically);
    final canAdvanceToNext = isReviewMistakeSequence
        ? reviewModeCanAdvanceToNext
        : normalModeCanAdvanceToNext;
    final isDailyEndSequence =
        _isDailySequence && _puzzleIndex == _activeSequence.length - 1;
    final canReturnToAcademy = isLastReviewMistake;
    final nextButtonEnabled = isLastReviewMistake
        ? canReturnToAcademy
        : canAdvanceToNext;
    final canClaimDailyReward =
        isDailyEndSequence &&
        !provider.todayDailyChallengeRewardClaimed &&
        (_solved || currentSolvedHistorically || currentSkippedHistorically) &&
        !isReviewMistakeSequence;
    final showDailyRewardButton =
        isDailyEndSequence && !isReviewMistakeSequence;
    const regretColor = Color(0xFF6FE7FF);
    const hintColor = Color(0xFF71B7FF);
    const skipColor = Color(0xFFE0A6FF);
    const nextEnabledColor = Color(0xFF7EDC8A);
    const nextDisabledColor = Color(0xFF6B7280);

    ButtonStyle filledAccentStyle(
      Color color, {
      Color? foregroundColor,
      Color? disabledBackgroundColor,
      Color? disabledForegroundColor,
    }) {
      return puzzleAcademyFilledButtonStyle(
        palette: palette,
        backgroundColor: color,
        foregroundColor: foregroundColor ??
            (color.computeLuminance() > 0.55
                ? const Color(0xFF08131F)
                : Colors.white),
        disabledBackgroundColor: disabledBackgroundColor,
        disabledForegroundColor: disabledForegroundColor,
      );
    }

    ButtonStyle outlinedAccentStyle(Color color) {
      return puzzleAcademyOutlinedButtonStyle(
        palette: palette,
        accent: color,
      );
    }

    final previousButton = OutlinedButton.icon(
      onPressed: hasPrevious ? _openPreviousPuzzle : null,
      style: outlinedAccentStyle(palette.cyan),
      icon: const Icon(Icons.skip_previous_rounded),
      label: const Text('Previous Puzzle'),
    );

    final regretButton = FilledButton.icon(
      onPressed: canRegret ? _regretLastMistake : null,
      style: filledAccentStyle(regretColor),
      icon: const Icon(Icons.undo_rounded),
      label: const Text('Regret'),
    );

    final hintButton = OutlinedButton.icon(
      onPressed: canHint ? () => _useHint(provider) : null,
      style: outlinedAccentStyle(hintColor),
      icon: const Icon(Icons.lightbulb_outline_rounded),
      label: Text('Hint (${provider.progress.freeHints})'),
    );

    final skipButton = OutlinedButton.icon(
      onPressed: canSkip ? () => _skipCurrentPuzzle(provider) : null,
      style: outlinedAccentStyle(skipColor),
      icon: const Icon(Icons.fast_forward_rounded),
      label: Text('Skip (${provider.progress.freeSkips})'),
    );

    final nextButton = isLastReviewMistake
        ? FilledButton(
            onPressed: canReturnToAcademy ? _exitToMap : null,
            style: filledAccentStyle(
              canReturnToAcademy ? nextEnabledColor : nextDisabledColor,
              foregroundColor: canReturnToAcademy
                  ? const Color(0xFF07131F)
                  : Colors.white.withValues(alpha: 0.88),
              disabledBackgroundColor: nextDisabledColor,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.88),
            ),
            child: const Text('Back to Academy'),
          )
        : FilledButton.icon(
            onPressed: canAdvanceToNext ? _openNextPuzzle : null,
            style: filledAccentStyle(
              canAdvanceToNext ? nextEnabledColor : nextDisabledColor,
              foregroundColor: canAdvanceToNext
                  ? const Color(0xFF07131F)
                  : Colors.white.withValues(alpha: 0.88),
              disabledBackgroundColor: nextDisabledColor,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.88),
            ),
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Next Puzzle'),
          );

    final dailyRewardButton = FilledButton.icon(
      onPressed: canClaimDailyReward
          ? () => _claimDailySequenceReward(provider)
          : null,
      style: filledAccentStyle(
        canClaimDailyReward ? nextEnabledColor : nextDisabledColor,
        foregroundColor: canClaimDailyReward
            ? const Color(0xFF07131F)
            : Colors.white.withValues(alpha: 0.88),
        disabledBackgroundColor: nextDisabledColor,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.88),
      ),
      icon: const Icon(Icons.emoji_events_rounded),
      label: const Text('Get Reward'),
    );

    Widget withDisabledOpacity(Widget child, bool enabled) {
      return Opacity(opacity: enabled ? 1.0 : 0.3, child: child);
    }

    if (vertical) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: withDisabledOpacity(previousButton, hasPrevious),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: withDisabledOpacity(regretButton, canRegret),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: withDisabledOpacity(hintButton, canHint),
            ),
            if (!isReviewMistakeSequence) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: withDisabledOpacity(skipButton, canSkip),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: withDisabledOpacity(
                showDailyRewardButton ? dailyRewardButton : nextButton,
                showDailyRewardButton ? canClaimDailyReward : nextButtonEnabled,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: withDisabledOpacity(regretButton, canRegret)),
              const SizedBox(width: 10),
              Expanded(child: withDisabledOpacity(hintButton, canHint)),
              if (!isReviewMistakeSequence) ...[
                const SizedBox(width: 10),
                Expanded(child: withDisabledOpacity(skipButton, canSkip)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: withDisabledOpacity(previousButton, hasPrevious)),
              const SizedBox(width: 10),
              Expanded(
                child: withDisabledOpacity(
                  showDailyRewardButton ? dailyRewardButton : nextButton,
                  showDailyRewardButton
                      ? canClaimDailyReward
                      : nextButtonEnabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
