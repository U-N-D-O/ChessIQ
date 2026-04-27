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

class _PuzzleNodeLayoutSpec {
  const _PuzzleNodeLayoutSpec._({
    required this.isLandscape,
    required this.compactLandscape,
    required this.compactPortrait,
    required this.compactPhoneLayout,
  });

  factory _PuzzleNodeLayoutSpec.fromMediaQuery(MediaQueryData media) {
    final safeHeight = media.size.height - media.padding.vertical;
    final isLandscape = media.size.width > safeHeight;
    final compactLandscape = isLandscape && safeHeight <= 500;
    final compactPortrait =
        !isLandscape && (safeHeight <= 780 || media.size.width <= 430);
    final compactPhoneLayout =
        compactLandscape || compactPortrait || media.size.width <= 430;

    return _PuzzleNodeLayoutSpec._(
      isLandscape: isLandscape,
      compactLandscape: compactLandscape,
      compactPortrait: compactPortrait,
      compactPhoneLayout: compactPhoneLayout,
    );
  }

  final bool isLandscape;
  final bool compactLandscape;
  final bool compactPortrait;
  final bool compactPhoneLayout;

  bool get showGlobalTopBar => !compactLandscape;
  bool get showCompactRailHeader => compactLandscape;
  bool get useHorizontalEvalStrip => compactPortrait;
  bool get useCompactButtons => compactPhoneLayout;

  EdgeInsets get landscapeCanvasPadding => compactLandscape
      ? const EdgeInsets.fromLTRB(6, 0, 6, 6)
      : const EdgeInsets.fromLTRB(6, 0, 8, 8);

  EdgeInsets get boardOuterPadding => compactLandscape
      ? const EdgeInsets.fromLTRB(6, 0, 6, 6)
      : compactPortrait
      ? const EdgeInsets.fromLTRB(10, 6, 10, 6)
      : const EdgeInsets.fromLTRB(12, 8, 12, 8);

  EdgeInsets get boardInnerPadding =>
      compactPhoneLayout ? const EdgeInsets.all(8) : const EdgeInsets.all(10);

  EdgeInsets get topBarOuterPadding => compactPortrait
      ? const EdgeInsets.fromLTRB(10, 6, 10, 4)
      : const EdgeInsets.fromLTRB(12, 10, 12, 6);

  EdgeInsets get topBarInnerPadding => compactPortrait
      ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
      : const EdgeInsets.fromLTRB(8, 10, 8, 10);

  double get topBarGap => compactPortrait ? 8 : 10;
  double get topBarCloseButtonSize => compactPortrait ? 34 : 38;
  double get topBarActionButtonSize => compactPortrait ? 30 : 34;
  double get topBarIconSize => compactPortrait ? 16 : 18;
  double get topBarTileSize => compactPortrait ? 42 : 50;
  double get topBarTileTextSize => compactPortrait ? 10.4 : 11.6;
  double get topBarTitleSize => compactPortrait ? 15.6 : 18;
  double get topBarSubtitleSize => compactPortrait ? 10.6 : 11.7;
  double get topBarTitleGap => compactPortrait ? 4 : 6;

  EdgeInsets get railOuterPadding => compactLandscape
      ? const EdgeInsets.fromLTRB(0, 0, 8, 4)
      : const EdgeInsets.fromLTRB(0, 8, 8, 8);

  double get railGap => compactLandscape ? 6 : 10;
  double get compactRailHeaderActionSize => 30;
  double get compactRailHeaderTileSize => 36;
  double get compactRailHeaderTileTextSize => 10.2;
  double get compactRailTitleSize => 14.8;
  double get compactRailSubtitleSize => 10.2;

  EdgeInsets get intelOuterPadding => compactLandscape
      ? EdgeInsets.zero
      : const EdgeInsets.fromLTRB(8, 8, 12, 8);

  EdgeInsets get intelInnerPadding =>
      compactLandscape ? const EdgeInsets.all(10) : const EdgeInsets.all(14);

  double get intelTitleSize => compactLandscape ? 13.6 : 15;
  double get intelStatusSize => compactLandscape ? 11.1 : 12.1;
  double get intelSectionGap => compactLandscape ? 6 : 12;
  double get intelDetailGap => compactLandscape ? 4 : 8;

  double get actionButtonHeight => compactLandscape
      ? 36
      : compactPortrait
      ? 40
      : 44;
  double get actionGap => compactPhoneLayout ? 8 : 10;
  EdgeInsets get actionPadding => compactLandscape
      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 7)
      : compactPortrait
      ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
      : const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  double get actionTextSize => compactLandscape
      ? 10.1
      : compactPortrait
      ? 10.6
      : 11.8;
  double get actionLetterSpacing => compactLandscape
      ? 0.55
      : compactPortrait
      ? 0.7
      : 0.9;
  double get actionIconSize => compactPhoneLayout ? 16 : 18;
  double get actionRadius => compactPhoneLayout ? 7 : 8;

  EdgeInsets bottomActionsOuterPadding(bool vertical) {
    if (vertical) {
      return compactLandscape
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(8, 4, 12, 8);
    }
    return compactPortrait
        ? const EdgeInsets.fromLTRB(10, 4, 10, 10)
        : const EdgeInsets.fromLTRB(12, 6, 12, 12);
  }
}

class _PuzzleNodeHeaderCopy {
  const _PuzzleNodeHeaderCopy({
    required this.title,
    required this.subtitle,
    required this.modeInfoTitle,
    required this.displayedStartElo,
    required this.showRatingTile,
  });

  final String title;
  final String subtitle;
  final String modeInfoTitle;
  final int displayedStartElo;
  final bool showRatingTile;
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

  bool get _isWidgetTestBinding {
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return bindingType.contains('TestWidgetsFlutterBinding');
  }

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

    if (!_isWidgetTestBinding) {
      await _analyzePosition();
    }
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
          subtitle:
              'Bracket ${widget.node.title} archived to the academy board.',
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
    final layout = _PuzzleNodeLayoutSpec.fromMediaQuery(MediaQuery.of(context));

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
                  if (layout.showGlobalTopBar)
                    _nonBoardChromeFilter(
                      useMonochrome,
                      AnimatedOpacity(
                        opacity: _focusModeActive ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        child: _buildTopBar(provider, themeProvider, layout),
                      ),
                    ),
                  Expanded(
                    child: layout.isLandscape
                        ? Padding(
                            padding: layout.landscapeCanvasPadding,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 8,
                                  child: _buildBoardCard(
                                    themeProvider,
                                    monochrome: useMonochrome,
                                    layout: layout,
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: AnimatedOpacity(
                                    opacity: _focusModeActive ? 0.5 : 1.0,
                                    duration: const Duration(milliseconds: 220),
                                    child: _buildLandscapeControlRail(
                                      provider,
                                      themeProvider,
                                      useMonochrome,
                                      layout,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final hideLowPriorityIntelMetrics =
                                  _shouldHidePortraitLowPriorityIntelMetrics(
                                    layout: layout,
                                    constraints: constraints,
                                    monochrome: useMonochrome,
                                  );

                              return SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildBoardCard(
                                            themeProvider,
                                            monochrome: useMonochrome,
                                            layout: layout,
                                          ),
                                          _nonBoardChromeFilter(
                                            useMonochrome,
                                            AnimatedOpacity(
                                              opacity: _focusModeActive
                                                  ? 0.5
                                                  : 1.0,
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              child: _buildIntelPanel(
                                                provider,
                                                layout: layout,
                                                hideLowPriorityMetrics:
                                                    hideLowPriorityIntelMetrics,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      _buildBottomActions(
                                        provider,
                                        layout: layout,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  PuzzleAcademyPalette _academyPalette(bool monochrome) {
    return puzzleAcademyPalette(context, monochromeOverride: monochrome);
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

  bool _shouldHidePortraitLowPriorityIntelMetrics({
    required _PuzzleNodeLayoutSpec layout,
    required BoxConstraints constraints,
    required bool monochrome,
  }) {
    const portraitActionSafetyMargin = 24.0;

    if (layout.isLandscape || _isExamMode) {
      return false;
    }
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return false;
    }

    final requiredHeight = _estimatePortraitContentHeight(
      layout: layout,
      viewportWidth: constraints.maxWidth,
      monochrome: monochrome,
      includeLowPriorityMetrics: true,
    );
    return requiredHeight >
        (constraints.maxHeight - portraitActionSafetyMargin);
  }

  double _estimatePortraitContentHeight({
    required _PuzzleNodeLayoutSpec layout,
    required double viewportWidth,
    required bool monochrome,
    required bool includeLowPriorityMetrics,
  }) {
    return _estimatePortraitBoardCardHeight(
          layout: layout,
          viewportWidth: viewportWidth,
          monochrome: monochrome,
        ) +
        _estimatePortraitIntelPanelHeight(
          layout: layout,
          viewportWidth: viewportWidth,
          monochrome: monochrome,
          includeLowPriorityMetrics: includeLowPriorityMetrics,
        ) +
        _estimatePortraitBottomActionsHeight(layout: layout);
  }

  double _estimatePortraitBoardCardHeight({
    required _PuzzleNodeLayoutSpec layout,
    required double viewportWidth,
    required bool monochrome,
  }) {
    final palette = _academyPalette(monochrome);
    final effectiveWidth = max(
      0.0,
      viewportWidth - layout.boardOuterPadding.horizontal,
    );
    final contentWidth = max(
      0.0,
      effectiveWidth - layout.boardInnerPadding.horizontal - 6,
    );
    final boardHeight = layout.useHorizontalEvalStrip
        ? contentWidth
        : max(0.0, contentWidth - 48);

    if (!layout.useHorizontalEvalStrip) {
      return layout.boardOuterPadding.vertical +
          layout.boardInnerPadding.vertical +
          boardHeight;
    }

    final evalStripTextStyle = puzzleAcademyHudStyle(
      palette: palette,
      size: 10.4,
      weight: FontWeight.w800,
      letterSpacing: 0.8,
      height: 1.0,
      color: palette.text,
    );
    final evalStripHeight =
        max(
          _measureTextHeight(
            _formatEval(
              _evalBarPlayerIsBlack ? -_evalWhitePawns : _evalWhitePawns,
            ),
            evalStripTextStyle,
          ),
          14.0,
        ) +
        14;

    return layout.boardOuterPadding.vertical +
        layout.boardInnerPadding.vertical +
        evalStripHeight +
        8 +
        boardHeight;
  }

  double _estimatePortraitIntelPanelHeight({
    required _PuzzleNodeLayoutSpec layout,
    required double viewportWidth,
    required bool monochrome,
    required bool includeLowPriorityMetrics,
  }) {
    final palette = _academyPalette(monochrome);
    final accent = _modeAccent(palette);
    final total = _usesCustomSequence
        ? _activeSequence.length
        : context.read<PuzzleAcademyProvider>().gridPuzzleCountForNode(
            widget.node,
          );
    final modeLabel = _isExamMode
        ? 'Exam'
        : _isDailySequence
        ? 'Daily'
        : widget.initialReviewMode
        ? 'Review'
        : 'Training';
    final effectiveWidth = max(
      0.0,
      viewportWidth - layout.intelOuterPadding.horizontal,
    );
    final contentWidth = max(
      0.0,
      effectiveWidth - layout.intelInnerPadding.horizontal - 6,
    );
    final valueWidth = max(0.0, contentWidth - 96);

    final titleStyle = puzzleAcademyDisplayStyle(
      palette: palette,
      size: layout.intelTitleSize,
      color: accent,
    );
    final labelStyle = puzzleAcademyHudStyle(
      palette: palette,
      size: 10.6,
      weight: FontWeight.w700,
      letterSpacing: 0.85,
      height: 1.0,
      color: palette.textMuted,
    );
    final valueStyle = puzzleAcademyHudStyle(
      palette: palette,
      size: 11.2,
      weight: FontWeight.w700,
      color: palette.text,
    );
    final statusStyle = puzzleAcademyHudStyle(
      palette: palette,
      size: layout.intelStatusSize,
      weight: FontWeight.w600,
      height: 1.45,
    );

    double infoLineHeight(String label, String value) {
      return max(
            _measureTextHeight(label, labelStyle),
            _measureTextHeight(value, valueStyle, maxWidth: valueWidth),
          ) +
          8;
    }

    var totalHeight =
        layout.intelOuterPadding.vertical +
        layout.intelInnerPadding.vertical +
        _measureTextHeight('Puzzle Intel', titleStyle) +
        layout.intelSectionGap +
        infoLineHeight('Mode', modeLabel) +
        infoLineHeight(
          'State',
          _solved
              ? 'Solved'
              : (_busy
                    ? 'Engine Response'
                    : (_coachingOffScript ? 'Coach Review' : 'Solving')),
        );

    if (includeLowPriorityMetrics) {
      totalHeight += infoLineHeight('Progress', '${_puzzleIndex + 1}/$total');
      totalHeight += infoLineHeight(
        'Eval',
        _formatEval(_evalBarPlayerIsBlack ? -_evalWhitePawns : _evalWhitePawns),
      );
    }

    if (_lastMistakeFromEval != null && _lastMistakeToEval != null) {
      totalHeight += infoLineHeight(
        'Swing',
        '${_formatEval(_evalBarPlayerIsBlack ? -_lastMistakeFromEval! : _lastMistakeFromEval!)} -> ${_formatEval(_evalBarPlayerIsBlack ? -_lastMistakeToEval! : _lastMistakeToEval!)}',
      );
    }

    totalHeight +=
        layout.intelDetailGap +
        _measureTextHeight(_status, statusStyle, maxWidth: contentWidth);
    return totalHeight;
  }

  double _estimatePortraitBottomActionsHeight({
    required _PuzzleNodeLayoutSpec layout,
  }) {
    final padding = layout.bottomActionsOuterPadding(false);
    return padding.vertical +
        layout.actionButtonHeight +
        layout.actionGap +
        layout.actionButtonHeight;
  }

  double _measureTextHeight(String text, TextStyle style, {double? maxWidth}) {
    final painter =
        TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(
          maxWidth: maxWidth == null ? double.infinity : max(0.0, maxWidth),
        );
    return painter.height;
  }

  _PuzzleNodeHeaderCopy _headerCopy(
    PuzzleAcademyProvider provider, {
    required bool compactLandscape,
  }) {
    final currentRating = _puzzle?.rating ?? widget.node.startElo;
    final displayedStartElo = (currentRating ~/ 50) * 50;
    final total = _usesCustomSequence
        ? _activeSequence.length
        : provider.gridPuzzleCountForNode(widget.node);
    final index = _puzzleIndex + 1;
    final title = _isExamMode
        ? (compactLandscape ? 'Exam' : 'Bracket ${widget.node.title} Exam')
        : _isDailySequence
        ? (compactLandscape
              ? _compactDailyTitle()
              : '${widget.sequenceTitle ?? 'Daily Challenge'} • ${widget.node.title}')
        : compactLandscape
        ? widget.node.title
        : 'Elo Bracket ${widget.node.title}';
    final subtitle = _isExamMode
        ? (compactLandscape
              ? _formatDuration(_examRemaining)
              : 'Puzzle #$index of $total • ${_formatDuration(_examRemaining)} left')
        : compactLandscape
        ? '#$index/$total'
        : 'Puzzle #$index of $total';
    final modeInfoTitle = _isExamMode
        ? 'Exam Mode'
        : _isDailySequence
        ? 'Daily Sequence'
        : widget.initialReviewMode
        ? 'Review Mode'
        : 'Training Mode';

    return _PuzzleNodeHeaderCopy(
      title: title,
      subtitle: subtitle,
      modeInfoTitle: modeInfoTitle,
      displayedStartElo: displayedStartElo,
      showRatingTile: !compactLandscape || _isExamMode,
    );
  }

  String _compactDailyTitle() {
    final sequenceTitle = widget.sequenceTitle?.trim();
    if (sequenceTitle == null || sequenceTitle.isEmpty) {
      return 'Daily';
    }
    return sequenceTitle.replaceAll('Daily Challenge', 'Daily');
  }

  Widget _buildHeaderRatingTile({
    required PuzzleAcademyPalette palette,
    required Color accent,
    required int displayedStartElo,
    required double size,
    required double textSize,
    required bool animateHero,
  }) {
    final tile = Container(
      key: const ValueKey<String>('puzzle_node_rating_tile'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.68), width: 2),
      ),
      child: Center(
        child: Text(
          '$displayedStartElo',
          style: puzzleAcademyHudStyle(
            palette: palette,
            size: textSize,
            weight: FontWeight.w800,
            letterSpacing: 0.9,
            height: 1.0,
            color: palette.text,
          ),
        ),
      ),
    );

    if (!animateHero) {
      return tile;
    }

    return Hero(
      tag: widget.heroTag,
      child: Material(color: Colors.transparent, child: tile),
    );
  }

  Widget _buildHeaderActionButton({
    required Key key,
    required double size,
    required double iconSize,
    required Color accent,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.46), width: 2),
      ),
      child: IconButton(
        key: key,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: size, height: size),
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, color: accent, size: iconSize),
      ),
    );
  }

  Widget _buildModeInfoButton({
    required String title,
    required String message,
    required Color accent,
    required bool monochrome,
    required double size,
  }) {
    final infoButton = PuzzleAcademyInfoButton(
      title: title,
      message: message,
      accent: accent,
      monochromeOverride: monochrome,
    );
    if ((size - 34).abs() < 0.1) {
      return infoButton;
    }
    return SizedBox.square(
      dimension: size,
      child: FittedBox(fit: BoxFit.contain, child: infoButton),
    );
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
      leadGlow.withValues(alpha: palette.isDark ? 0.14 : 0.06),
      palette.backdrop,
    );
    final bottomColor = Color.alphaBlend(
      altGlow.withValues(alpha: palette.isDark ? 0.10 : 0.05),
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
    _PuzzleNodeLayoutSpec layout,
  ) {
    final monochrome =
        themeProvider.isMonochrome || widget.cinematicThemeEnabled;
    final palette = _academyPalette(monochrome);
    final accent = _modeAccent(palette);
    final header = _headerCopy(provider, compactLandscape: false);

    return Padding(
      padding: layout.topBarOuterPadding,
      child: Container(
        key: const ValueKey<String>('puzzle_node_top_bar'),
        decoration: puzzleAcademyPanelDecoration(
          palette: palette,
          accent: accent,
          radius: 10,
          elevated: false,
        ),
        child: Padding(
          padding: layout.topBarInnerPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderActionButton(
                key: const ValueKey<String>('puzzle_node_close_button'),
                size: layout.topBarCloseButtonSize,
                iconSize: layout.topBarIconSize,
                accent: accent,
                icon: Icons.close_rounded,
                tooltip: 'Exit to Map',
                onPressed: _exitToMap,
              ),
              SizedBox(width: layout.topBarGap),
              _buildHeaderRatingTile(
                palette: palette,
                accent: accent,
                displayedStartElo: header.displayedStartElo,
                size: layout.topBarTileSize,
                textSize: layout.topBarTileTextSize,
                animateHero: true,
              ),
              SizedBox(width: layout.topBarGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      header.title,
                      key: const ValueKey<String>('puzzle_node_header_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: puzzleAcademyDisplayStyle(
                        palette: palette,
                        size: layout.topBarTitleSize,
                        color: accent,
                      ),
                    ),
                    SizedBox(height: layout.topBarTitleGap),
                    Text(
                      header.subtitle,
                      key: const ValueKey<String>(
                        'puzzle_node_header_subtitle',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: puzzleAcademyHudStyle(
                        palette: palette,
                        size: layout.topBarSubtitleSize,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: layout.topBarGap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isExamMode)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: layout.compactPortrait ? 6 : 8,
                      ),
                      child: KeyedSubtree(
                        key: const ValueKey<String>(
                          'puzzle_node_exam_progress_tag',
                        ),
                        child: PuzzleAcademyTag(
                          label: '$_examCorrectCount/${_activeSequence.length}',
                          accent: palette.amber,
                          icon: Icons.verified_outlined,
                          monochromeOverride: monochrome,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeInfoButton(
                        title: header.modeInfoTitle,
                        message: _modeIntelMessage(),
                        accent: accent,
                        monochrome: monochrome,
                        size: layout.topBarActionButtonSize,
                      ),
                      SizedBox(width: layout.compactPortrait ? 6 : 8),
                      _buildHeaderActionButton(
                        key: const ValueKey<String>(
                          'puzzle_node_settings_button',
                        ),
                        size: layout.topBarActionButtonSize,
                        iconSize: layout.topBarIconSize,
                        accent: accent,
                        icon: Icons.settings_outlined,
                        tooltip: 'Settings',
                        onPressed: () =>
                            _openBoardAndPieceThemeSettings(themeProvider),
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

  Widget _buildCompactLandscapeHeader(
    PuzzleAcademyProvider provider,
    AppThemeProvider themeProvider,
    bool monochrome,
    _PuzzleNodeLayoutSpec layout,
  ) {
    final palette = _academyPalette(monochrome);
    final accent = _modeAccent(palette);
    final header = _headerCopy(provider, compactLandscape: true);

    return Container(
      key: const ValueKey<String>('puzzle_node_compact_landscape_header'),
      decoration: puzzleAcademyPanelDecoration(
        palette: palette,
        accent: accent,
        radius: 10,
        elevated: false,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        header.title,
                        key: const ValueKey<String>('puzzle_node_header_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: puzzleAcademyDisplayStyle(
                          palette: palette,
                          size: layout.compactRailTitleSize,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        header.subtitle,
                        key: const ValueKey<String>(
                          'puzzle_node_header_subtitle',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: puzzleAcademyHudStyle(
                          palette: palette,
                          size: layout.compactRailSubtitleSize,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (header.showRatingTile) ...[
                  _buildHeaderRatingTile(
                    palette: palette,
                    accent: accent,
                    displayedStartElo: header.displayedStartElo,
                    size: layout.compactRailHeaderTileSize,
                    textSize: layout.compactRailHeaderTileTextSize,
                    animateHero: false,
                  ),
                  const SizedBox(width: 6),
                ],
                _buildHeaderActionButton(
                  key: const ValueKey<String>('puzzle_node_close_button'),
                  size: layout.compactRailHeaderActionSize,
                  iconSize: layout.topBarIconSize,
                  accent: accent,
                  icon: Icons.close_rounded,
                  tooltip: 'Exit to Map',
                  onPressed: _exitToMap,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (_isExamMode)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: KeyedSubtree(
                        key: const ValueKey<String>(
                          'puzzle_node_exam_progress_tag',
                        ),
                        child: PuzzleAcademyTag(
                          label: '$_examCorrectCount/${_activeSequence.length}',
                          accent: palette.amber,
                          icon: Icons.verified_outlined,
                          monochromeOverride: monochrome,
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                _buildModeInfoButton(
                  title: header.modeInfoTitle,
                  message: _modeIntelMessage(),
                  accent: accent,
                  monochrome: monochrome,
                  size: layout.compactRailHeaderActionSize,
                ),
                const SizedBox(width: 6),
                _buildHeaderActionButton(
                  key: const ValueKey<String>('puzzle_node_settings_button'),
                  size: layout.compactRailHeaderActionSize,
                  iconSize: layout.topBarIconSize,
                  accent: accent,
                  icon: Icons.settings_outlined,
                  tooltip: 'Settings',
                  onPressed: () =>
                      _openBoardAndPieceThemeSettings(themeProvider),
                ),
              ],
            ),
          ],
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

  Widget _buildBoardCard(
    AppThemeProvider theme, {
    required bool monochrome,
    required _PuzzleNodeLayoutSpec layout,
  }) {
    final palette = _academyPalette(monochrome);
    final accent = _modeAccent(palette);
    final evalFromPlayerPerspective = _evalBarPlayerIsBlack
        ? -_evalWhitePawns
        : _evalWhitePawns;
    final board = Center(
      child: AspectRatio(
        key: const ValueKey<String>('puzzle_node_board_square'),
        aspectRatio: 1,
        child: Stack(
          children: [
            Positioned.fill(child: _buildBoard(theme)),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _arrowFadeController,
                  builder: (context, _) {
                    final opacity = (1.0 - (_arrowFadeController.value * 0.75))
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
    );

    final boardContent = layout.useHorizontalEvalStrip
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: const ValueKey<String>('puzzle_node_compact_eval_strip'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: monochrome ? 0.10 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: monochrome ? 0.24 : 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _formatEval(evalFromPlayerPerspective),
                      style: puzzleAcademyHudStyle(
                        palette: palette,
                        size: 10.4,
                        weight: FontWeight.w800,
                        letterSpacing: 0.8,
                        height: 1.0,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PerspectiveEvalBar(
                        evalFromPlayerPerspective: evalFromPlayerPerspective,
                        playerIsBlack: _evalBarPlayerIsBlack,
                        monochrome: monochrome,
                        axis: Axis.horizontal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              board,
            ],
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final evalColumnWidth = layout.compactLandscape ? 36.0 : 40.0;
              final evalGap = layout.compactLandscape ? 6.0 : 8.0;
              final boardSize = max(
                0.0,
                constraints.maxWidth - evalColumnWidth - evalGap,
              );

              return SizedBox(
                height: boardSize,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: evalColumnWidth,
                      child: Column(
                        children: [
                          Text(
                            _formatEval(evalFromPlayerPerspective),
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
                                evalFromPlayerPerspective:
                                    evalFromPlayerPerspective,
                                playerIsBlack: _evalBarPlayerIsBlack,
                                monochrome: monochrome,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: evalGap),
                    Expanded(child: board),
                  ],
                ),
              );
            },
          );

    return Padding(
      padding: layout.boardOuterPadding,
      child: Container(
        key: const ValueKey<String>('puzzle_node_board_card'),
        decoration: puzzleAcademyPanelDecoration(
          palette: palette,
          accent: accent,
          fillColor: palette.panel,
          radius: 10,
        ),
        padding: layout.boardInnerPadding,
        child: boardContent,
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

  Widget _buildIntelPanel(
    PuzzleAcademyProvider provider, {
    required _PuzzleNodeLayoutSpec layout,
    bool hideLowPriorityMetrics = false,
  }) {
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
      padding: layout.intelOuterPadding,
      child: Container(
        key: const ValueKey<String>('puzzle_node_intel_panel'),
        padding: layout.intelInnerPadding,
        decoration: puzzleAcademyPanelDecoration(
          palette: palette,
          accent: accent,
          fillColor: palette.panelAlt,
          radius: 10,
        ),
        child: Column(
          mainAxisSize: layout.isLandscape
              ? MainAxisSize.max
              : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puzzle Intel',
              style: puzzleAcademyDisplayStyle(
                palette: palette,
                size: layout.intelTitleSize,
                color: accent,
              ),
            ),
            SizedBox(height: layout.intelSectionGap),
            _InfoLine(
              label: 'Mode',
              value: modeLabel,
              monochrome: monochrome,
              compact: layout.compactLandscape,
            ),
            _InfoLine(
              label: 'State',
              value: _solved
                  ? 'Solved'
                  : (_busy
                        ? 'Engine Response'
                        : (_coachingOffScript ? 'Coach Review' : 'Solving')),
              monochrome: monochrome,
              compact: layout.compactLandscape,
            ),
            if (!hideLowPriorityMetrics)
              _InfoLine(
                label: 'Progress',
                value: '${_puzzleIndex + 1}/$total',
                monochrome: monochrome,
                compact: layout.compactLandscape,
              ),
            if (!hideLowPriorityMetrics)
              _InfoLine(
                label: 'Eval',
                value: _formatEval(
                  _evalBarPlayerIsBlack ? -_evalWhitePawns : _evalWhitePawns,
                ),
                monochrome: monochrome,
                compact: layout.compactLandscape,
              ),
            if (_lastMistakeFromEval != null && _lastMistakeToEval != null)
              _InfoLine(
                label: 'Swing',
                value:
                    '${_formatEval(_evalBarPlayerIsBlack ? -_lastMistakeFromEval! : _lastMistakeFromEval!)} -> ${_formatEval(_evalBarPlayerIsBlack ? -_lastMistakeToEval! : _lastMistakeToEval!)}',
                monochrome: monochrome,
                compact: layout.compactLandscape,
              ),
            SizedBox(height: layout.intelDetailGap),
            if (layout.isLandscape)
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    _status,
                    key: const ValueKey<String>('puzzle_node_intel_status'),
                    maxLines: layout.compactLandscape ? 4 : null,
                    overflow: layout.compactLandscape
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
                    style: puzzleAcademyHudStyle(
                      palette: palette,
                      size: layout.intelStatusSize,
                      weight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
              )
            else
              Text(
                _status,
                key: const ValueKey<String>('puzzle_node_intel_status'),
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: layout.intelStatusSize,
                  weight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeControlRail(
    PuzzleAcademyProvider provider,
    AppThemeProvider themeProvider,
    bool monochrome,
    _PuzzleNodeLayoutSpec layout,
  ) {
    return Padding(
      key: const ValueKey<String>('puzzle_node_landscape_control_rail'),
      padding: layout.railOuterPadding,
      child: Column(
        children: [
          if (layout.showCompactRailHeader) ...[
            _nonBoardChromeFilter(
              monochrome,
              _buildCompactLandscapeHeader(
                provider,
                themeProvider,
                monochrome,
                layout,
              ),
            ),
            SizedBox(height: layout.railGap),
          ],
          Expanded(
            child: _nonBoardChromeFilter(
              monochrome,
              _buildIntelPanel(
                provider,
                layout: layout,
                hideLowPriorityMetrics: false,
              ),
            ),
          ),
          SizedBox(height: layout.railGap),
          _buildBottomActions(provider, layout: layout, vertical: true),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    PuzzleAcademyProvider provider, {
    required _PuzzleNodeLayoutSpec layout,
    bool vertical = false,
  }) {
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;
    final palette = _academyPalette(monochrome);
    final compactButtons = layout.useCompactButtons;
    final actionTextStyle = puzzleAcademyHudStyle(
      palette: palette,
      size: layout.actionTextSize,
      weight: FontWeight.w800,
      letterSpacing: layout.actionLetterSpacing,
      height: 1.0,
      color: palette.text,
    );

    Widget buttonLabel(String text, {Key? key}) {
      final label = Text(
        text,
        key: key,
        maxLines: compactButtons ? 1 : null,
        softWrap: !compactButtons,
      );
      if (!compactButtons) {
        return label;
      }
      return FittedBox(fit: BoxFit.scaleDown, child: label);
    }

    if (_isExamMode) {
      final accuracy = _examCompletedCount <= 0
          ? 0
          : ((_examCorrectCount / _examCompletedCount) * 100).round();
      final compactLandscapeExam = layout.compactLandscape;
      final statusCard = Container(
        padding: compactLandscapeExam
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    compactLandscapeExam
                        ? 'Accuracy $accuracy%'
                        : 'Correct $_examCorrectCount/${_activeSequence.length}',
                    style: puzzleAcademyHudStyle(
                      palette: palette,
                      size: compactLandscapeExam ? 10.8 : 11.3,
                      weight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    compactLandscapeExam
                        ? 'Score locks when the bracket ends.'
                        : 'Accuracy $accuracy% • ${_formatDuration(_examRemaining)} left',
                    style: puzzleAcademyHudStyle(
                      palette: palette,
                      size: compactLandscapeExam ? 10.2 : 11.0,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _buildModeInfoButton(
              title: 'Exam Scoring',
              message:
                  'Exam score blends 80% accuracy and 20% speed. Your leaderboard score then scales that result by node difficulty so stronger brackets are worth more.',
              accent: palette.amber,
              monochrome: monochrome,
              size: compactButtons ? 30 : 34,
            ),
          ],
        ),
      );

      return Padding(
        padding: layout.bottomActionsOuterPadding(vertical),
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
      final resolvedForeground =
          foregroundColor ??
          (color.computeLuminance() > 0.55
              ? const Color(0xFF08131F)
              : Colors.white);
      return puzzleAcademyFilledButtonStyle(
        palette: palette,
        backgroundColor: color,
        foregroundColor: resolvedForeground,
        disabledBackgroundColor: disabledBackgroundColor,
        disabledForegroundColor: disabledForegroundColor,
        padding: layout.actionPadding,
        radius: layout.actionRadius,
      ).copyWith(
        minimumSize: WidgetStatePropertyAll<Size>(
          Size.fromHeight(layout.actionButtonHeight),
        ),
        iconSize: WidgetStatePropertyAll<double>(layout.actionIconSize),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          actionTextStyle.copyWith(color: resolvedForeground),
        ),
      );
    }

    ButtonStyle outlinedAccentStyle(Color color) {
      return puzzleAcademyOutlinedButtonStyle(
        palette: palette,
        accent: color,
        padding: layout.actionPadding,
        radius: layout.actionRadius,
      ).copyWith(
        minimumSize: WidgetStatePropertyAll<Size>(
          Size.fromHeight(layout.actionButtonHeight),
        ),
        iconSize: WidgetStatePropertyAll<double>(layout.actionIconSize),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          actionTextStyle.copyWith(color: color),
        ),
      );
    }

    final previousButton = OutlinedButton.icon(
      key: const ValueKey<String>('puzzle_node_previous_button'),
      onPressed: hasPrevious ? _openPreviousPuzzle : null,
      style: outlinedAccentStyle(palette.cyan),
      icon: const Icon(Icons.skip_previous_rounded),
      label: buttonLabel('Previous Puzzle'),
    );

    final regretButton = FilledButton.icon(
      onPressed: canRegret ? _regretLastMistake : null,
      style: filledAccentStyle(regretColor),
      icon: const Icon(Icons.undo_rounded),
      label: buttonLabel(
        'Regret',
        key: const ValueKey<String>('puzzle_node_regret_button_label'),
      ),
    );

    final hintButton = OutlinedButton.icon(
      onPressed: canHint ? () => _useHint(provider) : null,
      style: outlinedAccentStyle(hintColor),
      icon: const Icon(Icons.lightbulb_outline_rounded),
      label: buttonLabel('Hint (${provider.progress.freeHints})'),
    );

    final skipButton = OutlinedButton.icon(
      onPressed: canSkip ? () => _skipCurrentPuzzle(provider) : null,
      style: outlinedAccentStyle(skipColor),
      icon: const Icon(Icons.fast_forward_rounded),
      label: buttonLabel('Skip (${provider.progress.freeSkips})'),
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
            child: buttonLabel('Back to Academy'),
          )
        : FilledButton.icon(
            key: const ValueKey<String>('puzzle_node_next_button'),
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
            label: buttonLabel('Next Puzzle'),
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
      label: buttonLabel('Get Reward'),
    );

    Widget withDisabledOpacity(Widget child, bool enabled) {
      return Opacity(opacity: enabled ? 1.0 : 0.3, child: child);
    }

    Widget actionSlot(Widget child, bool enabled) {
      return SizedBox(
        width: double.infinity,
        height: layout.actionButtonHeight,
        child: withDisabledOpacity(child, enabled),
      );
    }

    if (vertical && layout.compactLandscape) {
      return Padding(
        padding: layout.bottomActionsOuterPadding(true),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: actionSlot(previousButton, hasPrevious)),
                SizedBox(width: layout.actionGap),
                Expanded(child: actionSlot(regretButton, canRegret)),
              ],
            ),
            SizedBox(height: layout.actionGap),
            if (!isReviewMistakeSequence)
              Row(
                children: [
                  Expanded(child: actionSlot(hintButton, canHint)),
                  SizedBox(width: layout.actionGap),
                  Expanded(child: actionSlot(skipButton, canSkip)),
                ],
              )
            else
              actionSlot(hintButton, canHint),
            SizedBox(height: layout.actionGap),
            actionSlot(
              showDailyRewardButton ? dailyRewardButton : nextButton,
              showDailyRewardButton ? canClaimDailyReward : nextButtonEnabled,
            ),
          ],
        ),
      );
    }

    if (vertical) {
      return Padding(
        padding: layout.bottomActionsOuterPadding(true),
        child: Column(
          children: [
            actionSlot(previousButton, hasPrevious),
            SizedBox(height: layout.actionGap),
            actionSlot(regretButton, canRegret),
            SizedBox(height: layout.actionGap),
            actionSlot(hintButton, canHint),
            if (!isReviewMistakeSequence) ...[
              SizedBox(height: layout.actionGap),
              actionSlot(skipButton, canSkip),
            ],
            SizedBox(height: layout.actionGap),
            actionSlot(
              showDailyRewardButton ? dailyRewardButton : nextButton,
              showDailyRewardButton ? canClaimDailyReward : nextButtonEnabled,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: layout.bottomActionsOuterPadding(false),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: withDisabledOpacity(regretButton, canRegret)),
              SizedBox(width: layout.actionGap),
              Expanded(child: withDisabledOpacity(hintButton, canHint)),
              if (!isReviewMistakeSequence) ...[
                SizedBox(width: layout.actionGap),
                Expanded(child: withDisabledOpacity(skipButton, canSkip)),
              ],
            ],
          ),
          SizedBox(height: layout.actionGap),
          Row(
            children: [
              Expanded(child: withDisabledOpacity(previousButton, hasPrevious)),
              SizedBox(width: layout.actionGap),
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
