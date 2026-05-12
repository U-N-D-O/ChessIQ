part of '../screens/chess_analysis_page.dart';

class _GameResultReveal {
  const _GameResultReveal({
    required this.outcome,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.startedAt,
    this.toSquare,
  });

  final GameOutcome outcome;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final DateTime startedAt;
  final String? toSquare;
}

class _DetectedGameOutcome {
  const _DetectedGameOutcome(this.outcome, {this.drawReason});

  const _DetectedGameOutcome.draw(DrawReason? drawReason)
    : this(GameOutcome.draw, drawReason: drawReason);

  final GameOutcome outcome;
  final DrawReason? drawReason;
}

class _SquareToast {
  const _SquareToast({
    required this.square,
    required this.label,
    required this.accent,
    required this.startedAt,
    required this.duration,
  });

  final String square;
  final String label;
  final Color accent;
  final DateTime startedAt;
  final Duration duration;
}

class _CheckAlert {
  const _CheckAlert({
    required this.square,
    required this.againstViewer,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.startedAt,
  });

  final String square;
  final bool againstViewer;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final DateTime startedAt;
}

class _CheckedKingState {
  const _CheckedKingState({
    required this.square,
    required this.isWhite,
    required this.againstViewer,
  });

  final String square;
  final bool isWhite;
  final bool againstViewer;
}

class _MenuFloorMovePlan {
  _MenuFloorMovePlan({
    required this.startSceneTime,
    required this.endSceneTime,
    required this.fromRow,
    required this.fromColumn,
    required this.toRow,
    required this.toColumn,
    required this.knightMove,
    this.captureActorId,
  });

  final double startSceneTime;
  final double endSceneTime;
  final int fromRow;
  final int fromColumn;
  final int toRow;
  final int toColumn;
  final bool knightMove;
  final String? captureActorId;
  bool moveSoundPlayed = false;
  bool captureSoundPlayed = false;
}

class _MenuFloorActorState {
  _MenuFloorActorState({
    required this.id,
    required this.piece,
    required this.theme,
    required this.anchorRow,
    required this.anchorColumn,
    required this.spawnSceneTime,
    required this.activeMove,
  });

  final String id;
  final String piece;
  final PieceThemeMode theme;
  double anchorRow;
  double anchorColumn;
  final double spawnSceneTime;
  _MenuFloorMovePlan? activeMove;
  double? capturedSceneTime;
  bool blocksNewSpawnsUntilExit = false;
}

class _PendingMoveQualityGrading {
  static const Object _sentinel = Object();

  const _PendingMoveQualityGrading({
    required this.moveIndex,
    required this.uci,
    required this.moverIsWhite,
    required this.earliestPublishAt,
    required this.preMoveFen,
    required this.preMoveLines,
    required this.moverMaterialBefore,
    required this.moverMaterialAfter,
    required this.chargeBefore,
    required this.chargeEpoch,
    this.playedMoveRank,
    this.cpGapFromBest,
    this.cpGapFromNextBetter,
    this.totalLegalMoveCount,
    this.analyzedLegalMoveCount,
    this.preMoveMoverWinProbability,
    this.preMoveMoverEvalPawns,
    this.postMoveFen,
    this.postMoveWhiteToMove,
  });

  final int moveIndex;
  final String uci;
  final bool moverIsWhite;
  final DateTime earliestPublishAt;
  final String preMoveFen;
  final List<EngineLine> preMoveLines;
  final double moverMaterialBefore;
  final double moverMaterialAfter;
  final int chargeBefore;
  final int chargeEpoch;
  final int? playedMoveRank;
  final int? cpGapFromBest;
  final int? cpGapFromNextBetter;
  final int? totalLegalMoveCount;
  final int? analyzedLegalMoveCount;
  final double? preMoveMoverWinProbability;
  final double? preMoveMoverEvalPawns;
  final String? postMoveFen;
  final bool? postMoveWhiteToMove;

  _PendingMoveQualityGrading copyWith({
    Object? postMoveFen = _sentinel,
    Object? postMoveWhiteToMove = _sentinel,
  }) {
    return _PendingMoveQualityGrading(
      moveIndex: moveIndex,
      uci: uci,
      moverIsWhite: moverIsWhite,
      earliestPublishAt: earliestPublishAt,
      preMoveFen: preMoveFen,
      preMoveLines: preMoveLines,
      moverMaterialBefore: moverMaterialBefore,
      moverMaterialAfter: moverMaterialAfter,
      chargeBefore: chargeBefore,
      chargeEpoch: chargeEpoch,
      playedMoveRank: playedMoveRank,
      cpGapFromBest: cpGapFromBest,
      cpGapFromNextBetter: cpGapFromNextBetter,
      totalLegalMoveCount: totalLegalMoveCount,
      analyzedLegalMoveCount: analyzedLegalMoveCount,
      preMoveMoverWinProbability: preMoveMoverWinProbability,
      preMoveMoverEvalPawns: preMoveMoverEvalPawns,
      postMoveFen: identical(postMoveFen, _sentinel)
          ? this.postMoveFen
          : postMoveFen as String?,
      postMoveWhiteToMove: identical(postMoveWhiteToMove, _sentinel)
          ? this.postMoveWhiteToMove
          : postMoveWhiteToMove as bool?,
    );
  }

  bool get isSacrifice => moverMaterialAfter < moverMaterialBefore;
}

class _GradingSearchSnapshot {
  const _GradingSearchSnapshot({
    required this.lines,
    required this.whiteToMove,
  });

  final List<EngineLine> lines;
  final bool whiteToMove;
}

class _DeferredMoveQualityPublication {
  const _DeferredMoveQualityPublication({
    required this.pending,
    required this.assessment,
    required this.preMoveMoverWinProbability,
    required this.postMoveMoverWinProbability,
    required this.deltaWpLoss,
    required this.sourceRole,
  });

  final _PendingMoveQualityGrading pending;
  final MoveQualityAssessment assessment;
  final double preMoveMoverWinProbability;
  final double postMoveMoverWinProbability;
  final double deltaWpLoss;
  final EngineRequestRole? sourceRole;
}

class _SacrificePreviewCandidate {
  const _SacrificePreviewCandidate({
    required this.line,
    required this.materialLossCp,
    required this.positionalCompensationCp,
    required this.offeredExchangeCp,
    required this.hasImmediateRecapture,
  });

  final EngineLine line;
  final int materialLossCp;
  final int positionalCompensationCp;
  final int offeredExchangeCp;
  final bool hasImmediateRecapture;
}

class _SacrificeRecapturePreview {
  const _SacrificeRecapturePreview({
    required this.uciMove,
    required this.evalCp,
    required this.searchDepth,
  });

  final String uciMove;
  final int evalCp;
  final int searchDepth;
}

class _SacrificePreviewPosition {
  const _SacrificePreviewPosition({
    required this.boardState,
    required this.fen,
    required this.whiteToMove,
  });

  final Map<String, String> boardState;
  final String fen;
  final bool whiteToMove;
}

class _BoardDragPayload {
  const _BoardDragPayload._({required this.piece, this.fromSquare});

  const _BoardDragPayload.fromBoard({
    required String fromSquare,
    required String piece,
  }) : this._(piece: piece, fromSquare: fromSquare);

  const _BoardDragPayload.palette({required String piece})
    : this._(piece: piece);

  final String piece;
  final String? fromSquare;
}

class _EditToolboxPiece {
  const _EditToolboxPiece({required this.piece, required this.label});

  final String piece;
  final String label;
}

const List<_EditToolboxPiece> _editToolboxPieces = <_EditToolboxPiece>[
  _EditToolboxPiece(piece: 'q_w', label: 'White queen'),
  _EditToolboxPiece(piece: 't_w', label: 'White rook'),
  _EditToolboxPiece(piece: 'b_w', label: 'White bishop'),
  _EditToolboxPiece(piece: 'n_w', label: 'White knight'),
  _EditToolboxPiece(piece: 'p_w', label: 'White pawn'),
  _EditToolboxPiece(piece: 'q_b', label: 'Black queen'),
  _EditToolboxPiece(piece: 't_b', label: 'Black rook'),
  _EditToolboxPiece(piece: 'b_b', label: 'Black bishop'),
  _EditToolboxPiece(piece: 'n_b', label: 'Black knight'),
  _EditToolboxPiece(piece: 'p_b', label: 'Black pawn'),
];

abstract class _ChessAnalysisPageStateBase extends State<ChessAnalysisPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _lastBotIndexKey = 'last_bot_index_v1';
  static const String _vsBotCompletedTiersKey = 'vs_bot_completed_tiers_v1';
  static const BoardPerspective _defaultPerspective = BoardPerspective.white;
  static const BoardThemeMode _defaultBoardTheme = BoardThemeMode.dark;
  static const PieceThemeMode _defaultPieceTheme = PieceThemeMode.classic;
  static const int _defaultEngineDepth = 20;
  static const int _oracleInfiniteDepth = 30;
  static const int _defaultMultiPvCount = 1;
  static const String _savedDefaultSnapshotKey = 'saved_default_snapshot_v1';
  static const String _storeStateKey = 'store_state_v1';
  static const String _storeIntegrityScope = 'economy_store';
  static const String _storeVsBotMatchStartCountKey = 'vsBotMatchStartCount';
  static const String _cleanPlayPassTitle = 'Clean Play No-Ad Pass';
  static const String _cleanPlayPassBenefit =
      'analysis resets, bot rematches, and new bot matches stay ad-free';
  static const String _muteSoundsKey = 'mute_sounds_v1';
  static const String _hapticsEnabledKey = 'haptics_enabled_v1';
  static const String _cinematicThemeEnabledKey = 'cinematic_theme_enabled_v1';
  static const String _analysisEngineOwner = 'analysis.board';
  static const String _vsBotEngineOwner = 'analysis.vsbot';
  static const int _vsBotInterstitialMatchInterval = 3;
  static const int _bookOpeningPlyLimit = 6;
  static const int _sacrificeModePrice = 2850;
  static const int _pixelArrowThemePrice = 850;
  static const int _heavyArrowThemePrice = 1200;
  static const int _moveQualityGradingMultiPv = 4;
  static const int _moveQualityInitialPublishDepth = 2;
  static const int _moveQualityGradingDepth = 10;
  static const Duration _moveQualityPublishDelay = Duration(milliseconds: 500);
  static const int _positionAnalysisCacheLimit = 24;
  static const Duration _gameResultRevealDuration = Duration(
    milliseconds: 1150,
  );
  static const Duration _gameResultRevealSkipDelay = Duration(
    milliseconds: 250,
  );
  static const Duration _moveQualityOverlayDuration = Duration(
    milliseconds: 3400,
  );
  static const Duration _bookMoveQualityOverlayDuration = Duration(
    milliseconds: 4400,
  );
  static const Duration _checkAlertDuration = Duration(milliseconds: 1500);
  static const Duration _squareToastDuration = Duration(milliseconds: 1500);
  static const Duration _creditsModernDwell = Duration(seconds: 15);
  static const Duration _creditsGlitchWindow = Duration(milliseconds: 420);
  static const Duration _creditsRetroDwell = Duration(seconds: 15);
  static const bool _creditsDisableLoopForTests = bool.fromEnvironment(
    'FLUTTER_TEST',
  );

  late Map<String, String> boardState;
  CoordinatedEngineService? _engine;
  CoordinatedEngineService? _sacrificeScanEngine;
  String? _engineOwner;
  late AnimationController _pulseController;
  late AnimationController _introController;
  late AnimationController _menuRevealController;
  late AnimationController _launchController;
  late AnimationController _menuMusicFadeController;
  late AnimationController _sectionTransitionController;
  late AnimationController _menuExitAnimationController;
  late AnimationController _buttonRippleController;
  late AnimationController _openingButtonFlashController;
  late AnimationController _storeCoinGainController;
  final Stopwatch _spectralMotionClock = Stopwatch()..start();
  bool _openingButtonFlashRed = false;
  Timer? _openingModeFeedbackTimer;
  String? _openingModeFeedbackLabel;
  Color? _openingModeFeedbackColor;
  Offset? _buttonRippleCenter;
  Offset? _storeCoinGainCenter;
  int _storeCoinGainAmount = 10;
  bool _buttonUnlocked = false;
  final AudioPlayer _introAudioPlayer = AudioPlayer();
  final AudioPlayer _menuAudioPlayer = AudioPlayer();
  final AudioPlayer _sfxAudioPlayer = AudioPlayer();
  final List<_MenuSparkParticle> _menuSparkParticles = <_MenuSparkParticle>[];
  final List<_CreditsBackdropDot> _creditsBackdropDots =
      <_CreditsBackdropDot>[];
  final Random _creditsBackdropRandom = Random();
  bool _creditsDialogOpen = false;
  _CreditsVisualMode _creditsVisualMode = _CreditsVisualMode.modern;
  double _creditsVisualElapsed = 0.0;
  bool _menuDotsPreviouslyColliding = false;
  Offset _blueMenuDotPosition = Offset.zero;
  Offset _yellowMenuDotPosition = Offset.zero;
  Offset _blueMenuDotVelocity = Offset.zero;
  Offset _yellowMenuDotVelocity = Offset.zero;
  Size? _botSetupLastLayoutSize;
  double _botSetupLastScrollPosition = 0.0;
  double _botSetupScrollForce = 0.0;
  double _blueDotScrollVelocity = 0.0;
  double _blueDotScrollOffset = 0.0;
  Timer? _idleInterstitialTimer;
  DateTime? _menuSparkLastUpdate;
  DateTime? _creditsBackdropLastUpdate;
  late final Future<String> _creditsVersionFuture = _loadCreditsVersionLabel();
  double _menuDotTime = 0.0;
  double _mainMenuSceneTime = 0.0;
  double _blueYellowContactTime = 0.0;
  late final double _blueDotPhase;
  late final double _yellowDotPhase;
  late final String _menuFloorSequenceSeed;
  final List<_MenuFloorActorState> _menuFloorActors = <_MenuFloorActorState>[];
  int _menuFloorActionIndex = 0;
  int _menuFloorActorSerial = 0;
  bool _menuFloorReducedEffects = false;
  double _menuFloorNextActionSceneTime = 0.0;
  double _menuFloorExitRowThreshold = 8.9;
  late final double _blueDotSpeed;
  late final double _yellowDotSpeed;
  late final double _blueDotRadius;
  late final double _yellowDotRadius;
  late final double _blueDotTrajectoryNoise;
  late final double _yellowDotTrajectoryNoise;
  late final double _blueDotShapeSeed;
  late final double _yellowDotShapeSeed;
  static const double _menuCenterBaseSpinSpeed = 0.24;
  static const double _menuCenterMaxSpinSpeed = 6.0;
  static const double _menuCenterSpinDecayRate = 0.9;
  static const double _menuCenterCollisionStreakWindow = 1.2;
  static const List<_MenuBackdropSpritePlacement> _menuBackdropMotifs =
      <_MenuBackdropSpritePlacement>[];

  double _menuCenterRotationA = 0.0;
  double _menuCenterRotationB = 0.0;
  int _menuCenterShapeSidesA = 4;
  int _menuCenterShapeSidesB = 5;
  double _menuCenterShapeChangeTimerA = 1.6;
  double _menuCenterShapeChangeTimerB = 1.2;
  double _menuCenterSpinSpeed = _menuCenterBaseSpinSpeed;
  double _menuCenterImpact = 0.0;
  DateTime? _menuCenterLastUpdate;
  DateTime? _menuCenterLastCollision;
  int _menuCenterCollisionStreakCount = 0;
  static const int _boardSfxPlayerPoolSize = 4;
  final List<AudioPlayer> _boardSfxPlayers = List<AudioPlayer>.generate(
    _boardSfxPlayerPoolSize,
    (_) => AudioPlayer(),
  );
  int _nextBoardSfxPlayerIndex = 0;
  bool _menuMusicPlaying = false;
  bool _isHotkeyResetting = false;
  Future<void>? _engineStartFuture;
  Future<void>? _sacrificeScanEngineStartFuture;
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _suggestionButtonKey = GlobalKey();
  final GlobalKey _storeButtonKey = GlobalKey();
  final GlobalKey _evalBarHorizontalKey = GlobalKey();
  final GlobalKey _evalBarVerticalKey = GlobalKey();

  int _currentDepth = 0;
  double _currentEval = 0.0;
  bool _evalWhiteTurn =
      true; // whose turn it was when _currentEval was last set
  int _multiPvCount = _defaultMultiPvCount;
  int _engineDepth = _defaultEngineDepth;
  bool _isWhiteTurn = true;
  bool _whiteKingMoved = false;
  bool _blackKingMoved = false;
  bool _whiteKingsideRookMoved = false;
  bool _whiteQueensideRookMoved = false;
  bool _blackKingsideRookMoved = false;
  bool _blackQueensideRookMoved = false;
  String? _enPassantTarget;
  BoardPerspective _perspective = _defaultPerspective;
  BoardThemeMode _boardThemeMode = _defaultBoardTheme;
  PieceThemeMode _pieceThemeMode = _defaultPieceTheme;
  ArrowThemeMode _arrowThemeMode = ArrowThemeMode.classic;
  List<EngineLine> _topLines = [];
  List<EngineLine> _analysisLines = [];
  String? _analysisLinesFen;
  final List<MoveRecord> _moveHistory = [];
  int _historyIndex = -1;
  late ScrollController _historyScrollController;
  late ScrollController _quizStudyLibraryScrollController;
  late ScrollController _quizStudyLandscapeDetailScrollController;
  late ScrollController _quizQuestionOptionsScrollController;
  final Map<String, String> _ecoOpenings = {};
  final List<EcoLine> _ecoLines = [];
  int _quizEligibleCount = 0;
  final Map<String, List<EcoLine>> _quizEligiblePoolCache =
      <String, List<EcoLine>>{};
  final Map<String, Set<String>> _quizEligibleNameCache =
      <String, Set<String>>{};
  final Map<String, List<EcoLine>> _quizStudyPoolCache =
      <String, List<EcoLine>>{};
  bool _quizPoolsPrecomputed = false;
  Map<String, dynamic>? _precomputedQuizPoolData;
  bool _ecoOpeningsLoading = false;
  String _currentOpening = '';
  final List<String> _logs = [];
  OpeningMode _openingMode = OpeningMode.off;
  String? _gambitSelectedFrom;
  String? _holdSelectedFrom;
  final Set<String> _legalTargets = <String>{};
  final Set<String> _gambitAvailableTargets = <String>{};
  EcoLine? _selectedGambit;
  List<EngineLine> _gambitPreviewLines = [];
  final Random _rng = Random();
  bool _playVsBot = false;
  bool _humanPlaysWhite = true;
  bool _botThinking = false;
  final List<_GhostArrow> _botGhostArrows = <_GhostArrow>[];
  final Map<int, Timer> _botGhostArrowTimers = <int, Timer>{};
  int _ghostArrowIdSeed = 0;
  BotCharacter? _selectedBot;
  BotDifficulty _selectedBotDifficulty = BotDifficulty.easy;
  int _vsBotSessionWins = 0;
  int _vsBotSessionLosses = 0;
  int _vsBotSessionDraws = 0;
  EngineSearchHandle? _botSearchHandle;
  int _engineRequestSequence = 0;
  EvalSnapshot? _currentEvalSnapshot;
  final Map<String, PositionAnalysisCacheEntry> _positionAnalysisCacheByFen =
      <String, PositionAnalysisCacheEntry>{};
  final Map<String, EngineSearchUpdate> _primaryEngineUpdateByFen =
      <String, EngineSearchUpdate>{};
  final Map<String, EngineSearchHandle>
  _backgroundMoveQualityConfirmationsByFen = <String, EngineSearchHandle>{};
  Completer<List<EngineLine>>? _botSearchCompleter;
  final Map<int, EngineLine> _botSearchLines = <int, EngineLine>{};
  int _botSearchMultiPv = 1;
  Completer<_GradingSearchSnapshot?>? _gradingSearchCompleter;
  final Map<int, EngineLine> _gradingSearchLines = <int, EngineLine>{};
  int _gradingSearchMultiPv = 1;
  bool _gradingSearchWhiteToMove = true;
  Future<void> _moveQualityGradingOperation = Future<void>.value();
  int _moveQualityGradingGeneration = 0;
  bool _analysisRefreshQueuedWhileGrading = false;
  _PendingMoveQualityGrading? _pendingMoveQualityGrading;
  Timer? _moveQualityPublishTimer;
  _DeferredMoveQualityPublication? _deferredMoveQualityPublication;
  Future<void> _sacrificePreviewScanOperation = Future<void>.value();
  int _sacrificePreviewScanToken = 0;
  String? _lastSacrificeAnalysisSignature;
  bool _preferOpeningModeOnNextToggleAfterSacrifice = false;
  String? _sacrificePreviewFen;
  List<EngineLine> _sacrificePreviewLines = <EngineLine>[];
  DateTime? _sacrificeAvailabilityAlertUntil;
  String? _lastSacrificeAvailabilityAlertSignature;
  static const int _sacrificeRelativeEvalAllowanceCp = 100;
  static const int _sacrificeAcceptanceReplyAllowanceCp = 150;
  static const int _sacrificePreviewLineLimit = 3;
  static const int _sacrificeEligibleRootMoveLimit = 5;
  static const int _sacrificeFastConfirmationDepth = 15;
  static const Duration _sacrificeAvailabilityAlertDuration = Duration(
    seconds: 1,
  );
  static const Duration _sacrificeFastPathBudget = Duration(seconds: 5);
  static const Duration _sacrificeFastPathSearchTimeout = Duration(
    milliseconds: 900,
  );
  static const double _botSetupDefaultViewportFraction = 0.60;
  PageController _botSetupPageController = PageController(
    viewportFraction: _botSetupDefaultViewportFraction,
  );
  double _botSetupViewportFraction = _botSetupDefaultViewportFraction;
  int _botSetupSelectedIndex = 0;
  BotDifficulty _botSetupSelectedDifficulty = BotDifficulty.easy;
  final Set<String> _completedBotTierIds = <String>{};
  String? _vsBotProgressTitle;
  String? _vsBotProgressMessage;
  BotCharacter? _vsBotProgressNextBot;
  BotDifficulty? _vsBotProgressNextDifficulty;

  Future<void> _loadVsBotSetupPrefs();
  String? _selectedBotAvatarAsset(BotCharacter bot);

  BotSideChoice _botSideChoice = BotSideChoice.random;

  void _configureBotSetupPageController(double viewportFraction) {
    final normalizedViewport = viewportFraction.clamp(0.32, 0.86).toDouble();
    if ((_botSetupViewportFraction - normalizedViewport).abs() < 0.001) {
      return;
    }

    final previousController = _botSetupPageController;
    _botSetupViewportFraction = normalizedViewport;
    _botSetupPageController = PageController(
      initialPage: _botSetupSelectedIndex,
      viewportFraction: normalizedViewport,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousController.dispose();
      if (!mounted || !_botSetupPageController.hasClients) {
        return;
      }
      _botSetupPageController.jumpToPage(_botSetupSelectedIndex);
    });
  }

  int _depthTier = 1; // 1=pro,2=expert,3=grandmaster,4=oracle
  int _extraSuggestionPurchases = 0; // each +1 up to max 10 suggestions
  bool _themePackOwned = false;
  bool _sakuraBoardOwned = false;
  bool _tropicalBoardOwned = false;
  bool _tuttiFruttiOwned = false;
  bool _spectralOwned = false;
  bool _monochromePiecesOwned = false;
  bool _piecePackOwned = false;
  bool _pixelArrowThemeOwned = false;
  bool _heavyArrowThemeOwned = false;
  bool _sacrificeModeOwned = false;
  bool _adFreeOwned = false;
  bool _academyTuitionPassOwned = false;
  bool _introCompleted = true;
  bool _suggestionsEnabled = false;
  bool _vsBotEvalEnabled = false;
  bool _vsBotOptimalLineRevealActive = false;
  int _vsBotCharge = 0;
  int _vsBotMatchStartCount = 0;
  int _vsBotChargeEpoch = 0;
  bool _suggestionLaunchInProgress = false;
  bool _suggestionBurstActive = false;
  Offset? _launchStart;
  List<Offset> _launchTargets = <Offset>[];
  bool _launchTargetsEvalBar = false;
  GameOutcome? _gameOutcome;
  DrawReason? _gameDrawReason;
  bool _gameResultDialogVisible = false;
  _GameResultReveal? _gameResultReveal;
  int _gameResultRevealSequence = 0;
  Timer? _checkAlertTimer;
  _CheckAlert? _checkAlert;
  Timer? _squareToastTimer;
  _SquareToast? _squareToast;
  final List<String> _positionHistoryKeys = <String>[];
  final List<int> _halfmoveClockHistory = <int>[];
  bool _quizLaunchedFromAcademy = false;

  AppSection _activeSection = AppSection.menu;
  GambitQuizMode _quizMode = GambitQuizMode.guessName;
  bool _menuReady = false;
  bool _muteSounds = false;
  bool _hapticsEnabled = true;
  bool _isCinematicThemeEnabled = false;
  final ValueNotifier<bool> _cinematicThemeNotifier = ValueNotifier<bool>(
    false,
  );
  bool _analysisEditMode = false;
  String? _selectedEditToolboxPiece;
  bool _editToolboxEraserSelected = false;
  String? _lastEditDragEraseSquare;
  bool _pendingEditToolboxMetricsRefresh = false;
  Timer? _editModeHintTimer;
  String? _editModeHintText;
  Timer? _moveQualityOverlayTimer;
  MoveQuality? _moveQualityOverlayQuality;
  String? _moveQualityOverlayTitle;
  String? _moveQualityOverlayMessage;
  int? _moveQualityOverlayChargeDelta;
  MoveQualityScoringSuppressionReason?
  _moveQualityOverlayScoringSuppressedReason;
  MoveQuality? _lastMoveQualityBadgeQuality;
  String? _lastMoveQualityBadgeSquare;
  final Set<String> _viewedGambits = <String>{};
  String _quizPrompt = '';
  String _quizPromptFocus = '';
  List<String> _quizOptions = <String>[];
  int _quizCorrectIndex = 0;
  Timer? _quizFeedbackOverlayTimer;
  String? _quizFeedbackOverlayMessage;
  bool? _quizFeedbackOverlayCorrect;
  Map<String, String> _quizBoardState = <String, String>{};
  List<EngineLine> _quizContinuation = <EngineLine>[];
  bool _quizWhiteToMove = true;
  int _quizShownPly = 0;
  // Quiz piece-by-piece playback state
  Map<String, String> _quizPlayBoard = <String, String>{};
  int _quizPlayArrowCount = 0;
  bool _quizPlayActive = false;
  String? _quizFlyFrom;
  String? _quizFlyTo;
  String? _quizFlyPiece;
  double _quizFlyProgress = 0.0;
  bool _quizAnswered = false;
  int _quizSelectedIndex = -1;
  List<EngineLine> _quizPreviewContinuation = <EngineLine>[];
  final List<_QuizRoundReview> _quizReviewHistory = <_QuizRoundReview>[];
  int? _quizReviewIndex;
  QuizDifficulty _quizDifficulty = QuizDifficulty.easy;
  QuizAcademyProgress _quizAcademyProgress = QuizAcademyProgress.initial();
  bool _quizStudyMode = false;
  bool _quizOpeningsRoutePage = false;
  QuizStudyCategory _quizStudyCategory = QuizStudyCategory.basic;
  String _quizStudySearchQuery = '';
  bool _quizStudyDetailOpen = false;
  bool _quizStudyInfoExpanded = false;
  String? _quizStudySelectedOpeningName;
  String? _quizStudyExpandedFamily;
  Map<String, int> _quizStudyOpeningCounts = <String, int>{};
  int _quizStudyShownPly = 0;
  bool _quizStudyBoardFlipped = false;
  bool _quizStudyFollowUpMode = false;
  bool _quizStudyFollowUpSuggestionsVisible = true;
  bool _quizStudyFollowUpEvalVisible = true;
  bool _quizStudyFollowUpAutoReply = true;
  bool _quizStudyFollowUpBusy = false;
  String? _quizStudyFollowUpError;
  bool? _quizStudyFollowUpUserIsWhite;
  Map<String, String> _quizStudyFollowUpBoardState = <String, String>{};
  bool _quizStudyFollowUpWhiteToMove = true;
  String? _quizStudyFollowUpFen;
  String? _quizStudyFollowUpSelectedSquare;
  String? _quizStudyFollowUpLastAutoReplyMove;
  List<String> _quizStudyFollowUpBranchMoves = <String>[];
  List<EngineLine> _quizStudyFollowUpLines = <EngineLine>[];
  EvalSnapshot? _quizStudyFollowUpEvalSnapshot;
  EngineSearchHandle? _quizStudyFollowUpHandle;
  int _quizStudyFollowUpRequestToken = 0;
  int _quizStudyFollowUpStreak = 0;
  int _quizStudyFollowUpBestBranch = 0;
  int _quizStreak = 0;
  int _quizBestStreak = 0;
  int _quizTotalAnswered = 0;
  int _quizCorrectAnswers = 0;
  int _quizScore = 0;
  Map<String, int> _quizDailyScore = <String, int>{};
  Map<String, int> _quizDailyAttempts = <String, int>{};
  Map<String, int> _quizDailyCorrectByDay = <String, int>{};
  Map<String, int> _quizNameDailyAttempts = <String, int>{};
  Map<String, int> _quizNameDailyCorrect = <String, int>{};
  Map<String, int> _quizLineDailyAttempts = <String, int>{};
  Map<String, int> _quizLineDailyCorrect = <String, int>{};
  Map<String, int> _quizDailyQuestionsAsked = <String, int>{};
  // Per-difficulty daily stat maps
  Map<String, int> _quizEasyDailyAttempts = <String, int>{};
  Map<String, int> _quizEasyDailyCorrect = <String, int>{};
  Map<String, int> _quizMediumDailyAttempts = <String, int>{};
  Map<String, int> _quizMediumDailyCorrect = <String, int>{};
  Map<String, int> _quizHardDailyAttempts = <String, int>{};
  Map<String, int> _quizHardDailyCorrect = <String, int>{};
  Map<String, int> _quizVeryHardDailyAttempts = <String, int>{};
  Map<String, int> _quizVeryHardDailyCorrect = <String, int>{};
  int _quizQuestionsTarget = 10;
  int _quizSessionAnswered = 0;
  int _quizSessionCorrect = 0;
  bool _quizSessionStarted = false;

  Future<void> _showThemedErrorDialog({
    required String message,
    String title = 'Something went wrong',
    bool includeInternetHint = false,
  });

  void _loadQuizPrefs(SharedPreferences prefs);

  void _precomputeQuizEligiblePools();

  List<EcoLine> _quizEligiblePool({
    required GambitQuizMode mode,
    required QuizDifficulty difficulty,
  });

  void _markGambitViewed(String name);

  void _resetQuizToSetupState();

  void _openGambitQuizFromAcademy();

  Widget _buildMoveSequenceText(
    String notation, {
    double fontSize = 12,
    Color color = Colors.white70,
    FontWeight fontWeight = FontWeight.w600,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
  });

  Widget _buildGambitQuizScreen();

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()} - $message');
      if (_logs.length > 200) {
        _logs.removeAt(0);
      }
    });
  }

  bool get _shouldAnimateMainMenu =>
      _activeSection == AppSection.menu && !_creditsDialogOpen;

  @visibleForTesting
  bool get debugMainMenuAnimationsActive => _shouldAnimateMainMenu;

  void _scheduleEditModeHintHide() {
    _editModeHintTimer?.cancel();
    _editModeHintTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _editModeHintText = null;
      });
    });
  }

  void _setAnalysisEditMode(bool enabled) {
    setState(() {
      _analysisEditMode = enabled;
      _selectedEditToolboxPiece = null;
      _editToolboxEraserSelected = false;
      _holdSelectedFrom = null;
      _gambitSelectedFrom = null;
      _legalTargets.clear();
      _gambitAvailableTargets.clear();
      _editModeHintText = enabled ? 'Edit mode on' : 'Edit mode off';
    });
    _scheduleEditModeHintHide();
  }

  void _startIdleInterstitialTimer() {
    _cancelIdleInterstitialTimer();
  }

  void _cancelIdleInterstitialTimer() {
    _idleInterstitialTimer?.cancel();
    _idleInterstitialTimer = null;
  }

  void _resetIdleTimer() {
    _startIdleInterstitialTimer();
  }

  void _scheduleEditToolboxMetricsRefresh() {
    if (_pendingEditToolboxMetricsRefresh || !_analysisEditMode) {
      return;
    }
    _pendingEditToolboxMetricsRefresh = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingEditToolboxMetricsRefresh = false;
      if (!mounted || !_analysisEditMode) {
        return;
      }
      setState(() {});
    });
  }

  void _handleQuizStudyMetricsChange() {}

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _scheduleEditToolboxMetricsRefresh();
    _handleQuizStudyMetricsChange();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadVsBotSetupPrefs();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pulseController.addListener(_updateMenuSparks);
    _pulseController.addListener(_updateBotSetupBlueDotScrollOffset);
    _startIdleInterstitialTimer();
    _menuSparkLastUpdate = DateTime.now();
    _creditsBackdropLastUpdate = DateTime.now();
    final random = Random();
    _menuFloorSequenceSeed =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${random.nextInt(1 << 32).toRadixString(36)}';
    const menuDotRadiusScale = 1.15;
    _blueDotPhase = random.nextDouble() * 2 * pi;
    _yellowDotPhase = random.nextDouble() * 2 * pi;
    _blueDotSpeed = (0.28 + random.nextDouble() * 0.12) * 1.40;
    _yellowDotSpeed = (0.25 + random.nextDouble() * 0.12) * 1.40;
    _blueDotRadius = (0.58 + random.nextDouble() * 0.12) * menuDotRadiusScale;
    _yellowDotRadius = (0.52 + random.nextDouble() * 0.12) * menuDotRadiusScale;
    _blueDotTrajectoryNoise = random.nextDouble();
    _yellowDotTrajectoryNoise = random.nextDouble();
    _blueDotShapeSeed = random.nextDouble() * 3.2;
    _yellowDotShapeSeed = random.nextDouble() * 3.2;
    _menuCenterRotationA = 0.0;
    _menuCenterRotationB = 0.0;
    _menuCenterShapeSidesA = 4;
    _menuCenterShapeSidesB = 5;
    _menuCenterShapeChangeTimerA = 2.4 + random.nextDouble() * 2.0;
    _menuCenterShapeChangeTimerB = 2.8 + random.nextDouble() * 1.8;
    _menuCenterSpinSpeed = _menuCenterBaseSpinSpeed;
    _menuCenterLastUpdate = DateTime.now();
    _menuCenterLastCollision = null;
    _menuCenterCollisionStreakCount = 0;
    _menuDotTime = 0.0;
    _mainMenuSceneTime = 0.0;
    _menuFloorActors.clear();
    _menuFloorActionIndex = 0;
    _menuFloorActorSerial = 0;
    _menuFloorNextActionSceneTime = 0.0;
    _menuFloorExitRowThreshold = 8.9;
    _blueMenuDotPosition = Offset(
      cos(_blueDotPhase) * 0.58,
      sin(_blueDotPhase) * 0.56,
    );
    _yellowMenuDotPosition = Offset(
      cos(_yellowDotPhase) * 0.54,
      sin(_yellowDotPhase) * 0.52,
    );
    _blueMenuDotVelocity = Offset(
      0.18 - random.nextDouble() * 0.32,
      0.18 - random.nextDouble() * 0.32,
    );
    _yellowMenuDotVelocity = Offset(
      0.18 - random.nextDouble() * 0.32,
      0.18 - random.nextDouble() * 0.32,
    );
    _introController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3315),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() {
              _introCompleted = true;
            });
            if (_playVsBot &&
                !_isHumanTurnInBotGame &&
                !_botThinking &&
                _gameOutcome == null) {
              unawaited(_maybeTriggerBotMove());
            }
          }
        });
    _menuRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _launchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _buttonRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _storeCoinGainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _menuMusicFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sectionTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _menuExitAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _openingButtonFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _historyScrollController = ScrollController();
    _quizStudyLibraryScrollController = ScrollController();
    _quizStudyLandscapeDetailScrollController = ScrollController();
    _quizQuestionOptionsScrollController = ScrollController();
    _resetBoard(withIntro: false);
    _loadEcoOpenings();
    _restoreSnapshotAndStart();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _menuReady = true);
      _menuRevealController.forward(from: 0);
      _sectionTransitionController.forward(from: 0);
    });
  }

  void _updateMenuSparks() {
    final now = DateTime.now();
    final last = _menuSparkLastUpdate ?? now;
    final dt = now.difference(last).inMilliseconds / 1000.0;
    _menuSparkLastUpdate = now;

    _menuDotTime += dt;
    if (_menuDotTime > 1e6) {
      _menuDotTime %= 2 * pi;
    }

    if (_shouldAnimateMainMenu) {
      _mainMenuSceneTime += dt;
      if (_mainMenuSceneTime > 1e6) {
        _mainMenuSceneTime %= 2 * pi;
      }
      _updateMenuFloorPieces();

      final centerTime = _menuCenterLastUpdate == null
          ? 0.0
          : now.difference(_menuCenterLastUpdate!).inMilliseconds / 1000.0;
      _menuCenterLastUpdate = now;
      _menuCenterImpact = max(0.0, _menuCenterImpact - centerTime * 1.5);
      _menuCenterSpinSpeed = max(
        _menuCenterBaseSpinSpeed,
        _menuCenterSpinSpeed - _menuCenterSpinDecayRate * centerTime,
      );
      _menuCenterRotationA += centerTime * _menuCenterSpinSpeed;
      _menuCenterRotationB += centerTime * _menuCenterSpinSpeed;

      _menuCenterShapeChangeTimerA -= centerTime;
      _menuCenterShapeChangeTimerB -= centerTime;

      if (_menuCenterShapeChangeTimerA <= 0.0) {
        final rollA = _creditsBackdropRandom.nextDouble();
        _menuCenterShapeSidesA = rollA < (1.0 / 31.0)
            ? 5
            : rollA < (16.0 / 31.0)
            ? 0
            : 4;
        _menuCenterShapeChangeTimerA =
            2.4 + _creditsBackdropRandom.nextDouble() * 2.0;
      }
      if (_menuCenterShapeChangeTimerB <= 0.0) {
        final rollB = _creditsBackdropRandom.nextDouble();
        _menuCenterShapeSidesB = rollB < (1.0 / 31.0)
            ? 5
            : rollB < (16.0 / 31.0)
            ? 0
            : 4;
        _menuCenterShapeChangeTimerB =
            2.8 + _creditsBackdropRandom.nextDouble() * 1.8;
      }

      final pulse = _mainMenuSceneTime;
      final blueTargetAlignment = _menuDotAlignment(
        _blueDotPhase,
        _blueDotSpeed,
        _blueDotRadius,
        pulse,
        _blueDotTrajectoryNoise,
        _blueDotShapeSeed,
        false,
      );
      final yellowTargetAlignment = _menuDotAlignment(
        _yellowDotPhase,
        _yellowDotSpeed,
        _yellowDotRadius,
        pulse,
        _yellowDotTrajectoryNoise,
        _yellowDotShapeSeed,
        true,
      );
      final blueTarget = Offset(blueTargetAlignment.x, blueTargetAlignment.y);
      final yellowTarget = Offset(
        yellowTargetAlignment.x * -1.0,
        yellowTargetAlignment.y,
      );

      final separation = _blueMenuDotPosition - _yellowMenuDotPosition;
      final collisionDistance = separation.distance;
      final currentlyColliding = collisionDistance < 0.045;
      final reducedEffects =
          WidgetsBinding
              .instance
              .platformDispatcher
              .accessibilityFeatures
              .disableAnimations ||
          _useReducedMenuWindowsVisualEffects;

      if (currentlyColliding && !_menuDotsPreviouslyColliding) {
        final collisionAge = _menuCenterLastCollision == null
            ? double.infinity
            : now.difference(_menuCenterLastCollision!).inMilliseconds / 1000.0;
        if (collisionAge <= _menuCenterCollisionStreakWindow) {
          _menuCenterCollisionStreakCount += 1;
        } else {
          _menuCenterCollisionStreakCount = 1;
        }
        _menuCenterLastCollision = now;

        final collisionBonus = 1.4 + _menuCenterCollisionStreakCount * 0.55;
        _menuCenterSpinSpeed = min(
          _menuCenterSpinSpeed + collisionBonus,
          _menuCenterMaxSpinSpeed,
        );
        _menuCenterImpact = min(
          1.0,
          _menuCenterImpact + 0.42 + _menuCenterCollisionStreakCount * 0.10,
        );

        final origin = Offset(
          (_blueMenuDotPosition.dx + _yellowMenuDotPosition.dx) / 2,
          (_blueMenuDotPosition.dy + _yellowMenuDotPosition.dy) / 2,
        );
        _spawnMenuCollisionParticles(origin, reducedEffects: reducedEffects);

        unawaited(_lightHaptic());

        final safeDistance = max(collisionDistance, 0.0001);
        final direction = separation / safeDistance;
        const repulsionStrength = 14.7;
        final impulse =
            direction * repulsionStrength +
            Offset(-direction.dy, direction.dx) * 2.7;
        _blueMenuDotVelocity += impulse;
        _yellowMenuDotVelocity -= impulse;
      }

      _menuDotsPreviouslyColliding = currentlyColliding;

      final blueCenter = _blueMenuDotPosition;
      final yellowCenter = _yellowMenuDotPosition;
      final blueSpring = (blueTarget - blueCenter) * 4.4;
      final yellowSpring = (yellowTarget - yellowCenter) * 4.2;
      final blueOrbit = Offset(-blueCenter.dy, blueCenter.dx) * 3.8;
      final yellowOrbit = Offset(yellowCenter.dy, -yellowCenter.dx) * 3.7;
      final blueTwist =
          Offset(-_blueMenuDotVelocity.dy, _blueMenuDotVelocity.dx) * 2.4;
      final yellowTwist =
          Offset(_yellowMenuDotVelocity.dy, -_yellowMenuDotVelocity.dx) * 2.3;
      final blueNoise = Offset(
        sin(pulse * 3.1 + 1.7) * 0.28,
        cos(pulse * 3.5 - 0.5) * 0.28,
      );
      final yellowNoise = Offset(
        cos(pulse * 2.9 + 1.1) * 0.27,
        sin(pulse * 3.2 - 1.0) * 0.27,
      );
      final blueChaos = Offset(
        sin(pulse * 5.0 + _blueDotShapeSeed) * 0.14,
        cos(pulse * 4.2 - _blueDotShapeSeed) * 0.13,
      );
      final yellowChaos = Offset(
        cos(pulse * 4.7 + _yellowDotShapeSeed) * 0.15,
        sin(pulse * 4.4 - _yellowDotShapeSeed) * 0.14,
      );
      final blueRadial = blueCenter * -0.18;
      final yellowRadial = yellowCenter * -0.16;

      final blueAcceleration =
          blueSpring +
          blueOrbit +
          blueTwist +
          blueNoise +
          blueChaos +
          blueRadial;
      final yellowAcceleration =
          yellowSpring +
          yellowOrbit +
          yellowTwist +
          yellowNoise +
          yellowChaos +
          yellowRadial;

      _blueMenuDotVelocity =
          (_blueMenuDotVelocity + blueAcceleration * dt * 4.4) * 0.78;
      _yellowMenuDotVelocity =
          (_yellowMenuDotVelocity + yellowAcceleration * dt * 4.4) * 0.78;

      _blueMenuDotPosition += _blueMenuDotVelocity * dt;
      _yellowMenuDotPosition += _yellowMenuDotVelocity * dt;

      if (_blueMenuDotPosition.distance > 0.96) {
        _blueMenuDotPosition =
            _blueMenuDotPosition / _blueMenuDotPosition.distance * 0.92;
        _blueMenuDotVelocity *= 0.72;
      }
      if (_yellowMenuDotPosition.distance > 0.96) {
        _yellowMenuDotPosition =
            _yellowMenuDotPosition / _yellowMenuDotPosition.distance * 0.92;
        _yellowMenuDotVelocity *= 0.72;
      }

      _menuSparkParticles.removeWhere((particle) {
        particle.position += particle.velocity * dt;
        particle.velocity *= max(0.78, 1.0 - dt * 2.2);
        particle.rotation += particle.angularVelocity * dt;
        particle.age += dt;
        final travelDistance = (particle.position - particle.origin).distance;
        return particle.age >= particle.life ||
            travelDistance >= particle.maxTravelDistance ||
            particle.position.dx.abs() > 4.0 ||
            particle.position.dy.abs() > 4.0;
      });
    } else {
      _menuCenterLastUpdate = now;
    }

    if (_creditsDialogOpen) {
      final creditsLast = _creditsBackdropLastUpdate ?? now;
      final creditsDt = now.difference(creditsLast).inMilliseconds / 1000.0;
      _creditsBackdropLastUpdate = now;
      _advanceCreditsVisualLoop(creditsDt);
      if (_creditsBackdropDots.isNotEmpty) {
        const gravityStrength = 0.019;
        const centralStiffness = 0.20;
        const damping = 0.995;
        const repulsionThreshold = 0.10;
        const blueYellowContactThreshold = 0.13;
        const blueYellowRestDuration = 3.0;
        const greenPushStrength = 0.28 * 1.3;
        const blueYellowPushStrength = 0.64 * 1.2 * 1.3;

        var blueYellowTouching = false;
        Offset blueYellowMidpoint = Offset.zero;

        _blueYellowContactTime = _blueYellowContactTime.clamp(
          0.0,
          blueYellowRestDuration,
        );

        for (final dot in _creditsBackdropDots) {
          var acceleration = Offset.zero;
          for (final other in _creditsBackdropDots) {
            if (identical(dot, other)) continue;
            final separation = other.position - dot.position;
            final distance = separation.distance.clamp(0.06, 1.2);
            acceleration +=
                separation /
                (distance * distance) *
                (gravityStrength * (other.radius * 0.18));

            if (dot.role == _CreditsBackdropDotRole.green &&
                other.role == _CreditsBackdropDotRole.green &&
                distance < repulsionThreshold) {
              final push = separation / distance * greenPushStrength;
              dot.velocity -=
                  push * (1.0 + _creditsBackdropRandom.nextDouble() * 0.7);
            }

            final isBlueYellowPair =
                (dot.role == _CreditsBackdropDotRole.blue &&
                    other.role == _CreditsBackdropDotRole.yellow) ||
                (dot.role == _CreditsBackdropDotRole.yellow &&
                    other.role == _CreditsBackdropDotRole.blue);
            if (isBlueYellowPair && distance < blueYellowContactThreshold) {
              blueYellowTouching = true;
              blueYellowMidpoint = (dot.position + other.position) / 2;
            }
          }
          acceleration -= dot.position * centralStiffness;
          dot.velocity = (dot.velocity + acceleration * creditsDt) * damping;
        }

        var spawnGreenBall = false;
        if (blueYellowTouching) {
          _blueYellowContactTime += creditsDt;
          if (_blueYellowContactTime >= blueYellowRestDuration) {
            for (final dot in _creditsBackdropDots) {
              if (dot.role == _CreditsBackdropDotRole.blue ||
                  dot.role == _CreditsBackdropDotRole.yellow) {
                final other = _creditsBackdropDots.firstWhere(
                  (candidate) =>
                      candidate.role != dot.role &&
                      (candidate.role == _CreditsBackdropDotRole.blue ||
                          candidate.role == _CreditsBackdropDotRole.yellow),
                );
                final separation = dot.position - other.position;
                final distance = separation.distance.clamp(0.06, 1.2);
                final push = separation / distance * blueYellowPushStrength;
                dot.velocity +=
                    push * (1.0 + _creditsBackdropRandom.nextDouble() * 0.4);
              }
            }
            spawnGreenBall = _creditsBackdropDots.length < 10;
            _blueYellowContactTime = 0.0;
          }
        } else {
          _blueYellowContactTime = 0.0;
        }

        if (spawnGreenBall) {
          final angle = _creditsBackdropRandom.nextDouble() * 2 * pi;
          final direction = Offset(cos(angle), sin(angle));
          _creditsBackdropDots.add(
            _CreditsBackdropDot(
              position: blueYellowMidpoint,
              velocity:
                  direction *
                  (0.02 + _creditsBackdropRandom.nextDouble() * 0.03),
              color: const Color(0xFF7EDC8A).withValues(alpha: 0.84),
              radius: 4.0 + _creditsBackdropRandom.nextDouble() * 1.0,
              role: _CreditsBackdropDotRole.green,
            ),
          );
          _menuCenterSpinSpeed = min(_menuCenterSpinSpeed + 0.24, 4.2);
        }

        for (final dot in _creditsBackdropDots) {
          dot.position += dot.velocity * creditsDt;
          final distance = dot.position.distance;
          if (distance > 0.95) {
            dot.position = dot.position / distance * 0.92;
            dot.velocity *= 0.62;
          }
        }
      }
    } else {
      _creditsBackdropLastUpdate = now;
    }
  }

  bool get _useReducedMenuWindowsVisualEffects =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  double _menuUnit(double value) {
    if (value <= 0.0) return 0.0;
    if (value >= 1.0) return 1.0;
    return value;
  }

  void _spawnMenuCollisionParticles(
    Offset origin, {
    required bool reducedEffects,
  }) {
    final random = _creditsBackdropRandom;
    final pieceThemes = PieceThemeMode.values;
    const greenBallDistanceMultiplier = 3.0;
    const pieceDistanceMultiplier = 2.5;
    const baseTravelDistance = 1.24;

    void addCollisionParticle({
      required _MenuSparkVisual visual,
      required double distanceMultiplier,
    }) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = reducedEffects
          ? 0.52 + random.nextDouble() * 0.42
          : 0.72 + random.nextDouble() * 0.86;
      final tangent = Offset(-sin(angle), cos(angle));
      final spriteRole = visual == _MenuSparkVisual.sprite
          ? _MenuBackdropSpriteRole.values[random.nextInt(
              _MenuBackdropSpriteRole.values.length,
            )]
          : null;
      final spriteTheme = visual == _MenuSparkVisual.sprite
          ? pieceThemes[random.nextInt(pieceThemes.length)]
          : null;
      final baseLife = reducedEffects
          ? 0.48 + random.nextDouble() * 0.28
          : 0.74 + random.nextDouble() * 0.42;
      final size = switch (visual) {
        _MenuSparkVisual.pixel =>
          (reducedEffects ? 4.5 : 5.4) + random.nextDouble() * 1.8,
        _MenuSparkVisual.shard =>
          (reducedEffects ? 4.5 : 5.4) + random.nextDouble() * 1.8,
        _MenuSparkVisual.sprite =>
          (reducedEffects ? 8.5 : 10.8) + random.nextDouble() * 3.4,
      };

      _menuSparkParticles.add(
        _MenuSparkParticle(
          origin: origin,
          position: origin,
          velocity:
              Offset(cos(angle), sin(angle)) * speed +
              tangent * ((random.nextDouble() - 0.5) * 0.18),
          life: baseLife * distanceMultiplier,
          maxTravelDistance: baseTravelDistance * distanceMultiplier,
          size: size,
          visual: visual,
          accent: _MenuAccentSlot.emerald,
          rotation: random.nextDouble() * 2 * pi,
          angularVelocity:
              (random.nextDouble() - 0.5) *
              (visual == _MenuSparkVisual.sprite ? 2.2 : 6.0),
          spriteRole: spriteRole,
          spriteTheme: spriteTheme,
          useDarkSprite: random.nextBool(),
          mirrorX: random.nextBool(),
        ),
      );
    }

    final greenBallCount = 1 + random.nextInt(6);
    for (var index = 0; index < greenBallCount; index++) {
      addCollisionParticle(
        visual: _MenuSparkVisual.pixel,
        distanceMultiplier: greenBallDistanceMultiplier,
      );
    }

    if (random.nextBool()) {
      addCollisionParticle(
        visual: _MenuSparkVisual.sprite,
        distanceMultiplier: pieceDistanceMultiplier,
      );
    }

    final particleLimit = reducedEffects ? 24 : 48;
    if (_menuSparkParticles.length > particleLimit) {
      _menuSparkParticles.removeRange(
        0,
        _menuSparkParticles.length - particleLimit,
      );
    }
  }

  Widget _buildMenuCenterShape({
    required double size,
    required Color strokeColor,
    required double strokeWidth,
    required double rotation,
    required int sides,
    required double impact,
    required Color accentColor,
  }) {
    final pulse = _menuUnit(impact);
    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            if (pulse > 0.0)
              Transform.scale(
                scale: 1.0 + pulse * 0.08,
                child: CustomPaint(
                  painter: _RegularPolygonPainter(
                    sides: sides,
                    strokeColor: accentColor.withValues(
                      alpha: _menuUnit(0.12 + pulse * 0.12),
                    ),
                    strokeWidth: strokeWidth + 1.2 + pulse * 1.1,
                  ),
                ),
              ),
            if (pulse > 0.0)
              Center(
                child: Container(
                  width: size * (1.0 + pulse * 0.14),
                  height: size * (1.0 + pulse * 0.14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(
                        alpha: _menuUnit(0.08 + pulse * 0.10),
                      ),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            CustomPaint(
              painter: _RegularPolygonPainter(
                sides: sides,
                strokeColor: strokeColor,
                strokeWidth: strokeWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _menuAccentColor(
    _MenuAccentSlot slot, {
    required _VsBotArcadePalette arcade,
  }) {
    return switch (slot) {
      _MenuAccentSlot.cyan => arcade.cyan,
      _MenuAccentSlot.amber => arcade.amber,
      _MenuAccentSlot.pink => arcade.pink,
      _MenuAccentSlot.emerald => arcade.victory,
    };
  }

  String _menuBackdropSpriteAsset(
    _MenuBackdropSpriteRole role, {
    bool useDarkSprite = false,
  }) {
    final tone = useDarkSprite ? 'b' : 'w';
    return switch (role) {
      _MenuBackdropSpriteRole.king => 'assets/pieces/k_$tone.png',
      _MenuBackdropSpriteRole.queen => 'assets/pieces/q_$tone.png',
      _MenuBackdropSpriteRole.rook => 'assets/pieces/r_$tone.png',
      _MenuBackdropSpriteRole.bishop => 'assets/pieces/b_$tone.png',
      _MenuBackdropSpriteRole.knight => 'assets/pieces/n_$tone.png',
      _MenuBackdropSpriteRole.pawn => 'assets/pieces/p_$tone.png',
    };
  }

  String _menuBackdropRolePieceCode(
    _MenuBackdropSpriteRole role, {
    bool useDarkSprite = false,
  }) {
    final tone = useDarkSprite ? 'b' : 'w';
    final piece = switch (role) {
      _MenuBackdropSpriteRole.king => 'k',
      _MenuBackdropSpriteRole.queen => 'q',
      _MenuBackdropSpriteRole.rook => 't',
      _MenuBackdropSpriteRole.bishop => 'b',
      _MenuBackdropSpriteRole.knight => 'n',
      _MenuBackdropSpriteRole.pawn => 'p',
    };
    return '${piece}_$tone';
  }

  Widget _buildMenuBackdropSprite({
    required _MenuBackdropSpriteRole role,
    required Color tint,
    required double size,
    required bool reducedEffects,
    bool useDarkSprite = false,
    bool mirrorX = false,
    double rotation = 0.0,
    double glow = 0.0,
  }) {
    final asset = _menuBackdropSpriteAsset(role, useDarkSprite: useDarkSprite);
    Widget sprite = Stack(
      alignment: Alignment.center,
      children: [
        if (!reducedEffects && glow > 0.0)
          Image.asset(
            asset,
            width: size * 1.08,
            height: size * 1.08,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            color: tint.withValues(alpha: _menuUnit(glow)),
            colorBlendMode: BlendMode.srcIn,
          ),
        Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          color: tint,
          colorBlendMode: BlendMode.srcIn,
        ),
      ],
    );

    if (mirrorX) {
      sprite = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: sprite,
      );
    }
    if (rotation != 0.0) {
      sprite = Transform.rotate(angle: rotation, child: sprite);
    }
    return sprite;
  }

  double _menuHash01(String seed) {
    final hash = seed.codeUnits.fold<int>(
      2166136261,
      (value, code) => (value ^ code) * 16777619,
    );
    return ((hash & 0x7fffffff) % 1000000) / 1000000.0;
  }

  int _menuHashIndex(String seed, int length) {
    if (length <= 1) {
      return 0;
    }
    return (_menuHash01(seed) * length).floor().clamp(0, length - 1);
  }

  String _menuFloorSeed(String seed) {
    return '$_menuFloorSequenceSeed:$seed';
  }

  double get _menuFloorHoldDuration => _menuFloorReducedEffects ? 3.1 : 2.7;

  double get _menuFloorMoveDuration => _menuFloorReducedEffects ? 1.10 : 0.95;

  double get _menuFloorDriftSpeed => _menuFloorReducedEffects ? 0.16 : 0.24;

  static const double _menuFloorMoveSoundDelay = 0.5;
  static const double _menuFloorSettleDuration = 0.35;
  static const double _menuFloorCaptureFadeDuration = 0.22;
  static const int _menuFloorColumnCount = 7;
  static const int _menuFloorLogicalRowCount = 5;

  double _menuFloorYForProgress(
    Size size,
    double horizonY,
    double progress, {
    required bool reducedEffects,
  }) {
    final eased = pow(progress.clamp(0.0, 1.0), 2.16).toDouble();
    return ui.lerpDouble(
      horizonY + (reducedEffects ? 16.0 : 12.0),
      size.height * 1.02,
      eased,
    )!;
  }

  double _menuFloorHalfWidthForProgress(
    Size size,
    double outerRadius,
    double progress,
  ) {
    final eased = pow(progress.clamp(0.0, 1.0), 0.92).toDouble();
    return ui.lerpDouble(outerRadius * 0.16, size.width * 0.58, eased)!;
  }

  List<Point<int>> _menuFloorLegalTargets({
    required String piece,
    required int startRow,
    required int startColumn,
    required int rowCount,
    required int columnCount,
  }) {
    bool inBounds(int row, int column) {
      return row >= 0 && row < rowCount && column >= 0 && column < columnCount;
    }

    final targets = <Point<int>>[];
    void addTarget(int row, int column) {
      if (inBounds(row, column)) {
        targets.add(Point<int>(column, row));
      }
    }

    switch (piece[0]) {
      case 'p':
        addTarget(startRow - 1, startColumn);
        addTarget(startRow + 1, startColumn);
      case 'n':
        for (final offset in const <Point<int>>[
          Point<int>(1, 2),
          Point<int>(2, 1),
          Point<int>(2, -1),
          Point<int>(1, -2),
          Point<int>(-1, -2),
          Point<int>(-2, -1),
          Point<int>(-2, 1),
          Point<int>(-1, 2),
        ]) {
          addTarget(startRow + offset.y, startColumn + offset.x);
        }
      case 'b':
        for (var step = 1; step <= 4; step++) {
          addTarget(startRow + step, startColumn + step);
          addTarget(startRow + step, startColumn - step);
          addTarget(startRow - step, startColumn + step);
          addTarget(startRow - step, startColumn - step);
        }
      case 'r':
        for (var step = 1; step <= 4; step++) {
          addTarget(startRow + step, startColumn);
          addTarget(startRow - step, startColumn);
          addTarget(startRow, startColumn + step);
          addTarget(startRow, startColumn - step);
        }
      case 'q':
        for (var step = 1; step <= 4; step++) {
          addTarget(startRow + step, startColumn);
          addTarget(startRow - step, startColumn);
          addTarget(startRow, startColumn + step);
          addTarget(startRow, startColumn - step);
          addTarget(startRow + step, startColumn + step);
          addTarget(startRow + step, startColumn - step);
          addTarget(startRow - step, startColumn + step);
          addTarget(startRow - step, startColumn - step);
        }
      case 'k':
        for (var rowOffset = -1; rowOffset <= 1; rowOffset++) {
          for (var columnOffset = -1; columnOffset <= 1; columnOffset++) {
            if (rowOffset == 0 && columnOffset == 0) {
              continue;
            }
            addTarget(startRow + rowOffset, startColumn + columnOffset);
          }
        }
    }

    return targets;
  }

  List<int> _menuFloorStartRows({
    required String piece,
    required int rowCount,
  }) {
    if (rowCount <= 0) {
      return const <int>[];
    }
    final visibleTopRows = switch (piece[0]) {
      'b' || 'q' => min(rowCount, 2),
      _ => min(rowCount, 3),
    };
    return List<int>.generate(
      visibleTopRows,
      (index) => index,
      growable: false,
    );
  }

  List<int> _menuFloorActiveColumns(int columnCount) {
    return List<int>.generate(
      min(5, max(0, columnCount - 2)),
      (index) => index + 1,
      growable: false,
    );
  }

  String _menuFloorSquareKey(int row, int column) => '$row:$column';

  Set<String> _menuFloorReservedSquares({String? ignoringActorId}) {
    final reserved = <String>{};
    for (final actor in _menuFloorActors) {
      if (actor.id == ignoringActorId) {
        continue;
      }
      if (actor.capturedSceneTime != null) {
        reserved.add(
          _menuFloorSquareKey(
            actor.anchorRow.round(),
            actor.anchorColumn.round(),
          ),
        );
        continue;
      }
      reserved.add(
        _menuFloorSquareKey(
          actor.anchorRow.round(),
          actor.anchorColumn.round(),
        ),
      );
      final move = actor.activeMove;
      if (move != null) {
        reserved.add(_menuFloorSquareKey(move.toRow, move.toColumn));
      }
    }
    return reserved;
  }

  Point<int>? _menuFloorSelectTarget({
    required String piece,
    required int startRow,
    required int startColumn,
    required int rowCount,
    required String seedBase,
    required Set<String> reservedSquares,
    String? captureSquareKey,
    bool forwardOnly = false,
  }) {
    final activeColumns = _menuFloorActiveColumns(_menuFloorColumnCount);
    final targets =
        _menuFloorLegalTargets(
              piece: piece,
              startRow: startRow,
              startColumn: startColumn,
              rowCount: rowCount,
              columnCount: _menuFloorColumnCount,
            )
            .where((target) => activeColumns.contains(target.x))
            .where((target) {
              final key = _menuFloorSquareKey(target.y, target.x);
              return key == captureSquareKey || !reservedSquares.contains(key);
            })
            .toList(growable: false);
    if (targets.isEmpty) {
      return null;
    }
    if (captureSquareKey != null) {
      for (final target in targets) {
        if (_menuFloorSquareKey(target.y, target.x) == captureSquareKey) {
          return target;
        }
      }
      return null;
    }
    final forwardTargets = targets
        .where((target) => target.y > startRow)
        .toList(growable: false);
    if (forwardOnly) {
      if (forwardTargets.isEmpty) {
        return null;
      }
      return forwardTargets[_menuHashIndex(
        '$seedBase:target',
        forwardTargets.length,
      )];
    }
    final targetPool = switch (piece[0]) {
      'b' || 'q' => targets,
      _ => forwardTargets.isNotEmpty ? forwardTargets : targets,
    };
    return targetPool[_menuHashIndex('$seedBase:target', targetPool.length)];
  }

  _MenuFloorMovePlan _menuFloorCreateMovePlan({
    required int fromRow,
    required int fromColumn,
    required int toRow,
    required int toColumn,
    required bool knightMove,
    String? captureActorId,
  }) {
    final startSceneTime = _mainMenuSceneTime + _menuFloorHoldDuration;
    return _MenuFloorMovePlan(
      startSceneTime: startSceneTime,
      endSceneTime: startSceneTime + _menuFloorMoveDuration,
      fromRow: fromRow,
      fromColumn: fromColumn,
      toRow: toRow,
      toColumn: toColumn,
      knightMove: knightMove,
      captureActorId: captureActorId,
    );
  }

  _MenuFloorActorState? _menuFloorSpawnSoloActor(
    String seedBase, {
    String? requiredColor,
  }) {
    const pieceIds = <String>[
      'p_w',
      'p_b',
      'n_w',
      'n_b',
      'b_w',
      'b_b',
      'q_w',
      'q_b',
      'k_w',
      'k_b',
    ];
    const pieceThemes = <PieceThemeMode>[
      PieceThemeMode.ember,
      PieceThemeMode.frost,
      PieceThemeMode.tuttiFrutti,
      PieceThemeMode.monochrome,
    ];
    final piecePool = requiredColor == null
        ? pieceIds
        : pieceIds
              .where((piece) => piece.endsWith('_$requiredColor'))
              .toList(growable: false);
    if (piecePool.isEmpty) {
      return null;
    }
    final activeColumns = _menuFloorActiveColumns(_menuFloorColumnCount);
    final reservedSquares = _menuFloorReservedSquares();
    for (var attempt = 0; attempt < 24; attempt++) {
      final attemptSeed = '$seedBase:solo:$attempt';
      final piece =
          piecePool[_menuHashIndex('$attemptSeed:piece', piecePool.length)];
      final theme =
          pieceThemes[_menuHashIndex('$attemptSeed:theme', pieceThemes.length)];
      final startRows = _menuFloorStartRows(
        piece: piece,
        rowCount: _menuFloorLogicalRowCount,
      );
      final candidateStarts = <Point<int>>[];
      for (final startRow in startRows) {
        for (final column in activeColumns) {
          final key = _menuFloorSquareKey(startRow, column);
          if (!reservedSquares.contains(key)) {
            candidateStarts.add(Point<int>(column, startRow));
          }
        }
      }
      if (candidateStarts.isEmpty) {
        return null;
      }
      final start =
          candidateStarts[_menuHashIndex(
            '$attemptSeed:start',
            candidateStarts.length,
          )];
      final target = _menuFloorSelectTarget(
        piece: piece,
        startRow: start.y,
        startColumn: start.x,
        rowCount: _menuFloorLogicalRowCount,
        seedBase: attemptSeed,
        reservedSquares: reservedSquares,
      );
      if (target == null) {
        continue;
      }
      final actor = _MenuFloorActorState(
        id: 'menu-floor-${_menuFloorActorSerial++}',
        piece: piece,
        theme: theme,
        anchorRow: start.y.toDouble(),
        anchorColumn: start.x.toDouble(),
        spawnSceneTime: _mainMenuSceneTime,
        activeMove: _menuFloorCreateMovePlan(
          fromRow: start.y,
          fromColumn: start.x,
          toRow: target.y,
          toColumn: target.x,
          knightMove: piece.startsWith('n_'),
        ),
      );
      _menuFloorActors.add(actor);
      return actor;
    }
    return null;
  }

  _MenuFloorActorState? _menuFloorSpawnCaptureActor({
    required _MenuFloorActorState targetActor,
    required String seedBase,
  }) {
    if (targetActor.capturedSceneTime != null) {
      return null;
    }
    final targetRow = targetActor.anchorRow.round();
    final targetColumn = targetActor.anchorColumn.round();
    final attackerColor = targetActor.piece.endsWith('_w') ? 'b' : 'w';
    final attackerPieces = <String>[
      'n_$attackerColor',
      'b_$attackerColor',
      'q_$attackerColor',
      'k_$attackerColor',
    ];
    const pieceThemes = <PieceThemeMode>[
      PieceThemeMode.ember,
      PieceThemeMode.frost,
      PieceThemeMode.tuttiFrutti,
      PieceThemeMode.monochrome,
    ];
    final activeColumns = _menuFloorActiveColumns(_menuFloorColumnCount);
    final reservedSquares = _menuFloorReservedSquares();
    final captureSquareKey = _menuFloorSquareKey(targetRow, targetColumn);
    for (var attempt = 0; attempt < 24; attempt++) {
      final attemptSeed = '$seedBase:capture:$attempt';
      final piece =
          attackerPieces[_menuHashIndex(
            '$attemptSeed:piece',
            attackerPieces.length,
          )];
      final theme =
          pieceThemes[_menuHashIndex('$attemptSeed:theme', pieceThemes.length)];
      final startRows = _menuFloorStartRows(
        piece: piece,
        rowCount: _menuFloorLogicalRowCount,
      );
      final candidateStarts = <Point<int>>[];
      for (final startRow in startRows) {
        for (final column in activeColumns) {
          final key = _menuFloorSquareKey(startRow, column);
          if (!reservedSquares.contains(key)) {
            candidateStarts.add(Point<int>(column, startRow));
          }
        }
      }
      if (candidateStarts.isEmpty) {
        return null;
      }
      final start =
          candidateStarts[_menuHashIndex(
            '$attemptSeed:start',
            candidateStarts.length,
          )];
      final target = _menuFloorSelectTarget(
        piece: piece,
        startRow: start.y,
        startColumn: start.x,
        rowCount: _menuFloorLogicalRowCount,
        seedBase: attemptSeed,
        reservedSquares: reservedSquares,
        captureSquareKey: captureSquareKey,
      );
      if (target == null) {
        continue;
      }
      final actor = _MenuFloorActorState(
        id: 'menu-floor-${_menuFloorActorSerial++}',
        piece: piece,
        theme: theme,
        anchorRow: start.y.toDouble(),
        anchorColumn: start.x.toDouble(),
        spawnSceneTime: _mainMenuSceneTime,
        activeMove: _menuFloorCreateMovePlan(
          fromRow: start.y,
          fromColumn: start.x,
          toRow: target.y,
          toColumn: target.x,
          knightMove: piece.startsWith('n_'),
          captureActorId: targetActor.id,
        ),
      );
      _menuFloorActors.add(actor);
      return actor;
    }
    return null;
  }

  bool _menuFloorScheduleMoveForActor(
    _MenuFloorActorState actor, {
    required String seedBase,
    String? captureActorId,
  }) {
    if (actor.capturedSceneTime != null || actor.activeMove != null) {
      return false;
    }
    String? captureSquareKey;
    if (captureActorId != null) {
      final targetActor = _menuFloorActors
          .where((entry) => entry.id == captureActorId)
          .firstOrNull;
      if (targetActor == null || targetActor.capturedSceneTime != null) {
        return false;
      }
      final sameColor =
          targetActor.piece.endsWith('_w') == actor.piece.endsWith('_w');
      if (sameColor) {
        return false;
      }
      captureSquareKey = _menuFloorSquareKey(
        targetActor.anchorRow.round(),
        targetActor.anchorColumn.round(),
      );
    }
    final reservedSquares = _menuFloorReservedSquares(
      ignoringActorId: actor.id,
    );
    final startRow = actor.anchorRow.round();
    final startColumn = actor.anchorColumn.round();
    final exitRowCount = max(
      _menuFloorLogicalRowCount + 4,
      _menuFloorExitRowThreshold.ceil() + 2,
    );
    final target = _menuFloorSelectTarget(
      piece: actor.piece,
      startRow: startRow,
      startColumn: startColumn,
      rowCount: actor.blocksNewSpawnsUntilExit
          ? exitRowCount
          : _menuFloorLogicalRowCount,
      seedBase: seedBase,
      reservedSquares: reservedSquares,
      captureSquareKey: captureSquareKey,
      forwardOnly: actor.blocksNewSpawnsUntilExit,
    );
    if (target == null) {
      return false;
    }
    actor.activeMove = _menuFloorCreateMovePlan(
      fromRow: startRow,
      fromColumn: startColumn,
      toRow: target.y,
      toColumn: target.x,
      knightMove: actor.piece.startsWith('n_'),
      captureActorId: captureActorId,
    );
    return true;
  }

  ({double rowOffset, double columnOffset, double moveProgress})
  _menuFloorResolvedMoveOffsets(_MenuFloorMovePlan move) {
    final moveProgress =
        ((_mainMenuSceneTime - move.startSceneTime) /
                max(0.001, move.endSceneTime - move.startSceneTime))
            .clamp(0.0, 1.0);
    final easedMoveProgress = Curves.easeInOutCubic.transform(moveProgress);
    if (move.knightMove) {
      final rowDelta = move.toRow - move.fromRow;
      final columnDelta = move.toColumn - move.fromColumn;
      final rowIsLongAxis = rowDelta.abs() > columnDelta.abs();
      final midRowOffset = rowIsLongAxis ? rowDelta.toDouble() : 0.0;
      final midColumnOffset = rowIsLongAxis ? 0.0 : columnDelta.toDouble();
      const split = 0.68;
      if (easedMoveProgress < split) {
        final localT = Curves.easeInOut.transform(easedMoveProgress / split);
        return (
          rowOffset: ui.lerpDouble(0.0, midRowOffset, localT)!,
          columnOffset: ui.lerpDouble(0.0, midColumnOffset, localT)!,
          moveProgress: moveProgress,
        );
      }
      final localT = Curves.easeInOut.transform(
        (easedMoveProgress - split) / (1.0 - split),
      );
      return (
        rowOffset: ui.lerpDouble(midRowOffset, rowDelta.toDouble(), localT)!,
        columnOffset: ui.lerpDouble(
          midColumnOffset,
          columnDelta.toDouble(),
          localT,
        )!,
        moveProgress: moveProgress,
      );
    }
    return (
      rowOffset: ui.lerpDouble(
        0.0,
        (move.toRow - move.fromRow).toDouble(),
        easedMoveProgress,
      )!,
      columnOffset: ui.lerpDouble(
        0.0,
        (move.toColumn - move.fromColumn).toDouble(),
        easedMoveProgress,
      )!,
      moveProgress: moveProgress,
    );
  }

  double _currentMenuFloorActorRow(_MenuFloorActorState actor) {
    final age = max(0.0, _mainMenuSceneTime - actor.spawnSceneTime);
    var row = actor.anchorRow + age * _menuFloorDriftSpeed;
    final move = actor.activeMove;
    if (move != null) {
      row += _menuFloorResolvedMoveOffsets(move).rowOffset;
    }
    return row;
  }

  double _currentMenuFloorActorColumn(_MenuFloorActorState actor) {
    final move = actor.activeMove;
    if (move == null) {
      return actor.anchorColumn;
    }
    return actor.anchorColumn +
        _menuFloorResolvedMoveOffsets(move).columnOffset;
  }

  double _currentMenuFloorActorOpacity(_MenuFloorActorState actor) {
    if (actor.capturedSceneTime == null) {
      return 1.0;
    }
    final fadeT =
        ((_mainMenuSceneTime - actor.capturedSceneTime!) /
                _menuFloorCaptureFadeDuration)
            .clamp(0.0, 1.0);
    return 1.0 - Curves.easeIn.transform(fadeT);
  }

  void _playPendingMenuFloorMoveSounds() {
    for (final actor in _menuFloorActors) {
      final move = actor.activeMove;
      if (move == null) {
        continue;
      }
      if (move.captureActorId == null) {
        if (!move.moveSoundPlayed &&
            _mainMenuSceneTime >=
                move.startSceneTime + _menuFloorMoveSoundDelay) {
          move.moveSoundPlayed = true;
          unawaited(_playBoardMoveSound(isCapture: false));
        }
        continue;
      }
      if (!move.captureSoundPlayed && _mainMenuSceneTime >= move.endSceneTime) {
        move.captureSoundPlayed = true;
        unawaited(_playBoardMoveSound(isCapture: true));
      }
    }
  }

  void _finalizeMenuFloorMoves() {
    for (final actor in _menuFloorActors) {
      final move = actor.activeMove;
      if (move == null || _mainMenuSceneTime < move.endSceneTime) {
        continue;
      }
      actor.anchorRow = move.toRow.toDouble();
      actor.anchorColumn = move.toColumn.toDouble();
      actor.activeMove = null;
      if (move.captureActorId != null) {
        actor.blocksNewSpawnsUntilExit = true;
        for (final victim in _menuFloorActors) {
          if (victim.id == move.captureActorId &&
              victim.capturedSceneTime == null) {
            victim.capturedSceneTime = move.endSceneTime;
            break;
          }
        }
      }
    }
  }

  void _pruneMenuFloorActors() {
    _menuFloorActors.removeWhere((actor) {
      if (_currentMenuFloorActorOpacity(actor) <= 0.0) {
        return true;
      }
      return _currentMenuFloorActorRow(actor) > _menuFloorExitRowThreshold;
    });
  }

  void _updateMenuFloorPieces() {
    _playPendingMenuFloorMoveSounds();
    _finalizeMenuFloorMoves();
    _pruneMenuFloorActors();

    if (_menuFloorActors.any((actor) => actor.activeMove != null) ||
        _mainMenuSceneTime < _menuFloorNextActionSceneTime) {
      return;
    }

    final visibleActors = _menuFloorActors.toList(growable: false);
    final liveActors = visibleActors
        .where((actor) => actor.capturedSceneTime == null)
        .toList(growable: false);
    final actionSeed = _menuFloorSeed(
      'menu-floor-action:$_menuFloorActionIndex',
    );
    var scheduled = false;

    if (visibleActors.isEmpty) {
      scheduled = _menuFloorSpawnSoloActor(actionSeed) != null;
    } else if (visibleActors.length == 1 && liveActors.length == 1) {
      final survivor = liveActors.single;
      if (survivor.blocksNewSpawnsUntilExit) {
        scheduled = _menuFloorScheduleMoveForActor(
          survivor,
          seedBase: '$actionSeed:survivor-exit',
        );
      } else {
        scheduled =
            _menuFloorSpawnCaptureActor(
              targetActor: survivor,
              seedBase: actionSeed,
            ) !=
            null;
        if (!scheduled) {
          final survivorColor = survivor.piece.endsWith('_w') ? 'w' : 'b';
          scheduled =
              _menuFloorSpawnSoloActor(
                actionSeed,
                requiredColor: survivorColor,
              ) !=
              null;
        }
        if (!scheduled) {
          scheduled = _menuFloorScheduleMoveForActor(
            survivor,
            seedBase: '$actionSeed:survivor',
          );
        }
      }
    } else if (liveActors.length == 2) {
      final moverIndex = _menuHashIndex('$actionSeed:mover', liveActors.length);
      final mover = liveActors[moverIndex];
      final target = liveActors[1 - moverIndex];
      scheduled = _menuFloorScheduleMoveForActor(
        mover,
        seedBase: '$actionSeed:capture-primary',
        captureActorId: target.id,
      );
      if (!scheduled) {
        scheduled = _menuFloorScheduleMoveForActor(
          target,
          seedBase: '$actionSeed:capture-secondary',
          captureActorId: mover.id,
        );
      }
      if (!scheduled) {
        scheduled = _menuFloorScheduleMoveForActor(
          mover,
          seedBase: '$actionSeed:move-primary',
        );
      }
      if (!scheduled) {
        scheduled = _menuFloorScheduleMoveForActor(
          target,
          seedBase: '$actionSeed:move-secondary',
        );
      }
    }

    _menuFloorNextActionSceneTime =
        _mainMenuSceneTime +
        (scheduled
            ? _menuFloorHoldDuration +
                  _menuFloorMoveDuration +
                  _menuFloorSettleDuration
            : 0.6);
    if (scheduled) {
      _menuFloorActionIndex++;
    }
  }

  Widget _buildMenuFloorPieceLayer({required bool reducedEffects}) {
    _menuFloorReducedEffects = reducedEffects;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.width <= 0 || size.height <= 0) {
            return const SizedBox.shrink();
          }

          final center = Offset(size.width / 2, size.height / 2);
          final shortest = size.shortestSide;
          final outerRadius = shortest * 0.58;
          final horizonY = ui.lerpDouble(
            size.height * 0.30,
            center.dy * 0.88,
            0.62,
          )!;
          final tileCapProgress = reducedEffects ? 0.20 : 0.16;
          final visibleRowCount = reducedEffects ? 9 : 12;
          const columnCount = _menuFloorColumnCount;

          final tileCapY = _menuFloorYForProgress(
            size,
            horizonY,
            tileCapProgress,
            reducedEffects: reducedEffects,
          );
          final tileCapHalfWidth = _menuFloorHalfWidthForProgress(
            size,
            outerRadius,
            tileCapProgress,
          );
          final tileBoundaryYs = <double>[tileCapY];
          final tileBoundaryHalfWidths = <double>[tileCapHalfWidth];

          for (var row = 1; row <= visibleRowCount; row++) {
            final progress = ui.lerpDouble(
              tileCapProgress,
              1.0,
              (row / (visibleRowCount + 1)).clamp(0.0, 1.0),
            )!;
            if (progress >= 1.0) {
              continue;
            }
            tileBoundaryYs.add(
              _menuFloorYForProgress(
                size,
                horizonY,
                progress,
                reducedEffects: reducedEffects,
              ),
            );
            tileBoundaryHalfWidths.add(
              _menuFloorHalfWidthForProgress(size, outerRadius, progress),
            );
          }

          tileBoundaryYs.add(size.height * 1.02);
          tileBoundaryHalfWidths.add(size.width * 0.60);
          final pieceBoundaryYs = <double>[...tileBoundaryYs];
          final pieceBoundaryHalfWidths = <double>[...tileBoundaryHalfWidths];
          if (pieceBoundaryYs.length >= 2) {
            final lastRowDelta =
                pieceBoundaryYs.last -
                pieceBoundaryYs[pieceBoundaryYs.length - 2];
            final lastHalfWidthDelta =
                pieceBoundaryHalfWidths.last -
                pieceBoundaryHalfWidths[pieceBoundaryHalfWidths.length - 2];
            pieceBoundaryYs.add(pieceBoundaryYs.last + lastRowDelta);
            pieceBoundaryHalfWidths.add(
              pieceBoundaryHalfWidths.last + lastHalfWidthDelta,
            );
          }

          final tileRowCount = tileBoundaryYs.length - 1;
          if (tileRowCount < 3) {
            return const SizedBox.shrink();
          }

          final maxRenderableRow = pieceBoundaryYs.length - 1.001;
          _menuFloorExitRowThreshold = max(0.0, maxRenderableRow);

          ({Offset position, double rowHeight, double tileWidth, double depth})?
          projectPoint({required double row, required double column}) {
            if (row < 0 ||
                row > maxRenderableRow ||
                column < 0 ||
                column >= columnCount) {
              return null;
            }
            final clampedRow = row.clamp(0.0, maxRenderableRow);
            final projectedRow = (clampedRow + 0.5).clamp(
              0.0,
              pieceBoundaryYs.length - 1.001,
            );
            final rowIndex = projectedRow.floor();
            final rowT = projectedRow - rowIndex;
            final topY = pieceBoundaryYs[rowIndex];
            final bottomY = pieceBoundaryYs[rowIndex + 1];
            final halfWidth = ui.lerpDouble(
              pieceBoundaryHalfWidths[rowIndex],
              pieceBoundaryHalfWidths[rowIndex + 1],
              rowT,
            )!;
            final y = ui.lerpDouble(topY, bottomY, rowT)!;
            final x =
                center.dx +
                ((((column + 0.5) / columnCount) * 2) - 1) * halfWidth;
            return (
              position: Offset(x, y),
              rowHeight: bottomY - topY,
              tileWidth: (halfWidth * 2) / columnCount,
              depth: clampedRow / max(1.0, maxRenderableRow),
            );
          }

          final renderables = <({double depthY, Widget widget})>[];

          void addProjectedPiece({
            required String piece,
            required PieceThemeMode theme,
            required ({
              Offset position,
              double rowHeight,
              double tileWidth,
              double depth,
            })
            projection,
            required ({
              Offset position,
              double rowHeight,
              double tileWidth,
              double depth,
            })
            scaleProjection,
            required double lift,
            required double opacity,
          }) {
            if (opacity <= 0.0) {
              return;
            }

            final pieceHeightFactor = switch (piece[0]) {
              'p' => 0.86,
              'n' => 0.96,
              'b' => 1.00,
              'r' => 0.94,
              'q' => 1.04,
              'k' => 1.08,
              _ => 1.0,
            };
            final tileUnit = min(
              scaleProjection.tileWidth * 1.52,
              scaleProjection.rowHeight * 2.25,
            );
            final pieceHeight = max(
              14.0,
              tileUnit * pieceHeightFactor,
            ).toDouble();
            final pieceWidth = min(
              scaleProjection.tileWidth * 0.96,
              pieceHeight * 0.92,
            );
            final groundY =
                projection.position.dy + projection.rowHeight * 0.10 - lift;
            final pieceTop = groundY - pieceHeight;
            final shadowWidth = pieceWidth * 0.42;
            final shadowHeight = max(2.5, pieceHeight * 0.09);
            final shadowTop = groundY - shadowHeight * 0.08;
            final resolvedOpacity = (0.48 + projection.depth * 0.14) * opacity;
            final pieceWidget = _pieceImage(
              piece,
              width: pieceWidth,
              height: pieceHeight,
              theme: theme,
              blackOutlineOverflowPx: pieceWidth * 0.04,
            );

            renderables.add((
              depthY: groundY - 0.01,
              widget: Positioned(
                left: projection.position.dx - shadowWidth / 2,
                top: shadowTop - shadowHeight / 2,
                child: IgnorePointer(
                  child: Container(
                    width: shadowWidth,
                    height: shadowHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(shadowHeight),
                      color: Colors.black.withValues(
                        alpha: 0.12 * resolvedOpacity,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.09 * resolvedOpacity,
                          ),
                          blurRadius: shadowHeight * 1.6,
                          spreadRadius: shadowHeight * 0.18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ));
            renderables.add((
              depthY: groundY,
              widget: Positioned(
                left: projection.position.dx - pieceWidth / 2,
                top: pieceTop,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: resolvedOpacity,
                    child: SizedBox(
                      width: pieceWidth,
                      height: pieceHeight,
                      child: pieceWidget,
                    ),
                  ),
                ),
              ),
            ));
          }

          final scaleLockRow = max(0.0, pieceBoundaryYs.length - 2.35);
          for (final actor in _menuFloorActors) {
            final opacity = _currentMenuFloorActorOpacity(actor);
            if (opacity <= 0.0) {
              continue;
            }
            final rowPos = _currentMenuFloorActorRow(actor);
            final columnPos = _currentMenuFloorActorColumn(actor);
            final projection = projectPoint(row: rowPos, column: columnPos);
            if (projection == null) {
              continue;
            }
            final scaleProjection =
                projectPoint(
                  row: min(rowPos, scaleLockRow),
                  column: columnPos,
                ) ??
                projection;
            addProjectedPiece(
              piece: actor.piece,
              theme: actor.theme,
              projection: projection,
              scaleProjection: scaleProjection,
              lift: 0.0,
              opacity: opacity,
            );
          }

          if (renderables.isEmpty) {
            return const SizedBox.shrink();
          }

          renderables.sort((a, b) => a.depthY.compareTo(b.depthY));
          return Stack(
            children: renderables
                .map((entry) => entry.widget)
                .toList(growable: false),
          );
        },
      ),
    );
  }

  Widget _buildMenuBackgroundLayer({
    required Alignment blueDotAlignment,
    required Alignment yellowDotAlignment,
    required Color blueDotColor,
    required Color yellowDotColor,
    required _VsBotArcadePalette arcade,
    required bool reducedEffects,
    required bool isMono,
    required double shortestSide,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MenuBlastBackdropPainter(
                time: _mainMenuSceneTime,
                impact: _menuCenterImpact,
                blueAlignment: Offset(blueDotAlignment.x, blueDotAlignment.y),
                yellowAlignment: Offset(
                  yellowDotAlignment.x,
                  yellowDotAlignment.y,
                ),
                cyan: blueDotColor,
                amber: yellowDotColor,
                pink: arcade.pink,
                crimson: arcade.crimson,
                lineColor: arcade.line,
                reducedEffects: reducedEffects,
                monochrome: isMono,
              ),
            ),
            ..._menuBackdropMotifs.map((motif) {
              final driftAngle =
                  _mainMenuSceneTime * motif.driftSpeed + motif.driftPhase;
              final drift =
                  Offset(cos(driftAngle), sin(driftAngle * 1.18)) *
                  (motif.driftRadius * (reducedEffects ? 0.55 : 1.0));
              final tint = _menuAccentColor(
                motif.accent,
                arcade: arcade,
              ).withValues(alpha: motif.opacity * (isMono ? 0.60 : 0.82));
              return Align(
                alignment: motif.alignment,
                child: Transform.translate(
                  offset: drift,
                  child: _buildMenuBackdropSprite(
                    role: motif.role,
                    tint: tint,
                    size: max(48.0, shortestSide * motif.sizeFactor),
                    reducedEffects: reducedEffects,
                    useDarkSprite: motif.useDarkSprite,
                    mirrorX: motif.mirrorX,
                    rotation: motif.rotation + sin(driftAngle) * 0.05,
                    glow: reducedEffects ? 0.0 : 0.10,
                  ),
                ),
              );
            }),
            _buildMenuFloorPieceLayer(reducedEffects: reducedEffects),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCollisionLayer({
    required _VsBotArcadePalette arcade,
    required bool reducedEffects,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            ..._menuSparkParticles.map((particle) {
              return Align(
                alignment: Alignment(
                  particle.position.dx,
                  particle.position.dy,
                ),
                child: _buildMenuSparkWidget(
                  particle: particle,
                  arcade: arcade,
                  reducedEffects: reducedEffects,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuAccentLayer({
    required Alignment blueDotAlignment,
    required Alignment yellowDotAlignment,
    required Color blueDotColor,
    required Color yellowDotColor,
    required bool reducedEffects,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            _buildMenuDot(
              alignment: blueDotAlignment,
              color: blueDotColor,
              reducedEffects: reducedEffects,
            ),
            _buildMenuDot(
              alignment: yellowDotAlignment,
              color: yellowDotColor,
              reducedEffects: reducedEffects,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDot({
    required Alignment alignment,
    required Color color,
    required bool reducedEffects,
  }) {
    final size = 10.0 + _menuCenterImpact * 1.4;
    final blurRadius = reducedEffects ? 10.0 : 18.0 + _menuCenterImpact * 8.0;
    final spreadRadius = reducedEffects ? 1.0 : 3.0 + _menuCenterImpact * 1.6;

    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: reducedEffects ? 0.32 : 0.48),
              blurRadius: blurRadius,
              spreadRadius: spreadRadius,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSparkWidget({
    required _MenuSparkParticle particle,
    required _VsBotArcadePalette arcade,
    required bool reducedEffects,
  }) {
    final opacity = _menuUnit((1.0 - particle.progress) * 0.96);
    final orbColor = const Color(0xFF7EDC8A).withValues(alpha: opacity * 0.92);

    Widget buildThemedSparkPiece() {
      Widget piece = _pieceImage(
        _menuBackdropRolePieceCode(
          particle.spriteRole!,
          useDarkSprite: particle.useDarkSprite,
        ),
        width: particle.size * (reducedEffects ? 1.72 : 1.96),
        height: particle.size * (reducedEffects ? 1.72 : 1.96),
        theme: particle.spriteTheme ?? _defaultPieceTheme,
        blackOutlineOverflowPx: particle.size * 0.08,
      );

      if (particle.mirrorX) {
        piece = Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
          child: piece,
        );
      }
      if (particle.rotation != 0.0) {
        piece = Transform.rotate(angle: particle.rotation, child: piece);
      }
      return Opacity(opacity: opacity, child: piece);
    }

    return switch (particle.visual) {
      _MenuSparkVisual.pixel => Transform.rotate(
        angle: particle.rotation,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: orbColor,
            boxShadow: reducedEffects
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: orbColor.withValues(alpha: 0.34),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
          ),
        ),
      ),
      _MenuSparkVisual.shard => Transform.rotate(
        angle: particle.rotation,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: orbColor,
            boxShadow: reducedEffects
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: orbColor.withValues(alpha: 0.34),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
          ),
        ),
      ),
      _MenuSparkVisual.sprite => buildThemedSparkPiece(),
    };
  }

  void _initializeCreditsBackdrop() {
    _creditsBackdropDots.clear();

    final specs = <Map<String, Object>>[
      {
        'role': _CreditsBackdropDotRole.green,
        'color': const Color(0xFF7EDC8A),
        'radius': 4.5,
      },
      {
        'role': _CreditsBackdropDotRole.blue,
        'color': const Color(0xFF2A6CF0),
        'radius': 10.0,
      },
      {
        'role': _CreditsBackdropDotRole.yellow,
        'color': const Color(0xFFD8B640),
        'radius': 11.0,
      },
      {
        'role': _CreditsBackdropDotRole.green,
        'color': const Color(0xFF4ADE80),
        'radius': 4.25,
      },
      {
        'role': _CreditsBackdropDotRole.green,
        'color': const Color(0xFF7EDC8A),
        'radius': 5.25,
      },
    ];

    for (final spec in specs) {
      final angle = _creditsBackdropRandom.nextDouble() * 2 * pi;
      final distance = 0.18 + _creditsBackdropRandom.nextDouble() * 0.26;
      final position = Offset(cos(angle) * distance, sin(angle) * distance);
      final speed = 0.025 + _creditsBackdropRandom.nextDouble() * 0.05;
      final velocity = Offset.fromDirection(
        angle + pi / 2 + (_creditsBackdropRandom.nextDouble() - 0.5) * 0.8,
        speed,
      );

      _creditsBackdropDots.add(
        _CreditsBackdropDot(
          position: position,
          velocity: velocity,
          color: (spec['color'] as Color).withValues(alpha: 0.84),
          radius: spec['radius'] as double,
          role: spec['role'] as _CreditsBackdropDotRole,
        ),
      );
    }

    _creditsBackdropLastUpdate = DateTime.now();
  }

  void _resetCreditsVisualLoop() {
    _creditsVisualMode = _CreditsVisualMode.modern;
    _creditsVisualElapsed = 0.0;
  }

  double _creditsModeWindow(_CreditsVisualMode mode) {
    switch (mode) {
      case _CreditsVisualMode.modern:
        return _creditsModernDwell.inMilliseconds / 1000.0;
      case _CreditsVisualMode.glitchToRetro:
      case _CreditsVisualMode.glitchToModern:
        return _creditsGlitchWindow.inMilliseconds / 1000.0;
      case _CreditsVisualMode.retro:
        return _creditsRetroDwell.inMilliseconds / 1000.0;
    }
  }

  _CreditsVisualMode _nextCreditsVisualMode(_CreditsVisualMode mode) {
    switch (mode) {
      case _CreditsVisualMode.modern:
        return _CreditsVisualMode.glitchToRetro;
      case _CreditsVisualMode.glitchToRetro:
        return _CreditsVisualMode.retro;
      case _CreditsVisualMode.retro:
        return _CreditsVisualMode.glitchToModern;
      case _CreditsVisualMode.glitchToModern:
        return _CreditsVisualMode.modern;
    }
  }

  void _advanceCreditsVisualLoop(double dt) {
    if (_creditsDisableLoopForTests || dt <= 0) {
      return;
    }

    _creditsVisualElapsed += dt;
    var currentWindow = _creditsModeWindow(_creditsVisualMode);
    while (currentWindow > 0 && _creditsVisualElapsed >= currentWindow) {
      _creditsVisualElapsed -= currentWindow;
      _creditsVisualMode = _nextCreditsVisualMode(_creditsVisualMode);
      currentWindow = _creditsModeWindow(_creditsVisualMode);
    }
  }

  double? _captureScrollAnchor(ScrollController controller) {
    if (!controller.hasClients) {
      return null;
    }

    final position = controller.position;
    final totalExtent = position.maxScrollExtent + position.viewportDimension;
    if (totalExtent <= 0) {
      return 0.0;
    }

    return ((position.pixels + position.viewportDimension * 0.5) / totalExtent)
        .clamp(0.0, 1.0);
  }

  void _restoreScrollAnchor(ScrollController controller, double? anchor) {
    if (anchor == null || !controller.hasClients) {
      return;
    }

    final position = controller.position;
    final totalExtent = position.maxScrollExtent + position.viewportDimension;
    if (totalExtent <= 0) {
      return;
    }

    final target = (anchor * totalExtent - position.viewportDimension * 0.5)
        .clamp(0.0, position.maxScrollExtent);

    if ((position.pixels - target).abs() > 0.5) {
      controller.jumpTo(target);
    }
  }

  _CreditsDialogVisuals _buildCreditsDialogVisuals(BuildContext context) {
    final appTheme = context.watch<AppThemeProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome = appTheme.isMonochrome || _isCinematicThemeEnabled;
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: useMonochrome,
    );
    final reducedEffects =
        puzzleAcademyShouldReduceEffects(context) ||
        _useReducedMenuWindowsVisualEffects;
    final window = _creditsModeWindow(_creditsVisualMode);
    final progress = window <= 0
        ? 1.0
        : (_creditsVisualElapsed / window).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(progress);

    double themeBlend;
    switch (_creditsVisualMode) {
      case _CreditsVisualMode.modern:
        themeBlend = 0.0;
      case _CreditsVisualMode.glitchToRetro:
        themeBlend = eased;
      case _CreditsVisualMode.retro:
        themeBlend = 1.0;
      case _CreditsVisualMode.glitchToModern:
        themeBlend = 1.0 - eased;
    }

    var rawGlitch = 0.0;
    if (_creditsVisualMode == _CreditsVisualMode.glitchToRetro ||
        _creditsVisualMode == _CreditsVisualMode.glitchToModern) {
      rawGlitch = 1.0 - ((progress * 2.0) - 1.0).abs();
    }
    final glitchStrength = reducedEffects ? rawGlitch * 0.32 : rawGlitch;

    final modernPrimary = useMonochrome
        ? scheme.onSurface.withValues(alpha: 0.88)
        : scheme.secondary;
    final modernSecondary = useMonochrome
        ? scheme.onSurface.withValues(alpha: 0.76)
        : scheme.primary;
    final modernTertiary = useMonochrome
        ? scheme.onSurface.withValues(alpha: 0.64)
        : scheme.tertiary;

    final primaryAccent =
        Color.lerp(modernPrimary, palette.cyan, themeBlend) ?? modernPrimary;
    final secondaryAccent =
        Color.lerp(modernSecondary, palette.amber, themeBlend) ??
        modernSecondary;
    final tertiaryAccent =
        Color.lerp(modernTertiary, palette.emerald, themeBlend) ??
        modernTertiary;

    final shellStart =
        Color.lerp(
          Color.alphaBlend(
            scheme.surface.withValues(alpha: isDark ? 0.98 : 0.99),
            palette.shell,
          ),
          Color.alphaBlend(
            palette.boardDark.withValues(alpha: isDark ? 0.58 : 0.22),
            palette.backdrop,
          ),
          themeBlend,
        ) ??
        palette.shell;
    final shellEnd =
        Color.lerp(
          Color.alphaBlend(
            modernPrimary.withValues(alpha: isDark ? 0.10 : 0.05),
            palette.panelAlt,
          ),
          Color.alphaBlend(
            primaryAccent.withValues(alpha: palette.isDark ? 0.18 : 0.10),
            palette.boardLight.withValues(alpha: palette.isDark ? 0.22 : 0.36),
          ),
          themeBlend,
        ) ??
        palette.panelAlt;
    final panel =
        Color.lerp(
          palette.panel,
          Color.alphaBlend(
            palette.boardDark.withValues(alpha: palette.isDark ? 0.42 : 0.24),
            palette.panel,
          ),
          themeBlend,
        ) ??
        palette.panel;
    final panelAlt =
        Color.lerp(
          palette.panelAlt,
          Color.alphaBlend(
            palette.boardLight.withValues(alpha: palette.isDark ? 0.18 : 0.28),
            palette.boardDark.withValues(alpha: palette.isDark ? 0.24 : 0.10),
          ),
          themeBlend,
        ) ??
        palette.panelAlt;
    final frame =
        Color.lerp(
          scheme.outline.withValues(alpha: 0.30),
          primaryAccent.withValues(alpha: palette.monochrome ? 0.54 : 0.68),
          themeBlend,
        ) ??
        scheme.outline.withValues(alpha: 0.30);
    final edgeGlow =
        Color.lerp(primaryAccent, secondaryAccent, 0.42) ?? primaryAccent;
    final titleColor =
        Color.lerp(
          palette.text,
          Color.lerp(primaryAccent, palette.text, 0.22) ?? palette.text,
          themeBlend,
        ) ??
        palette.text;

    return _CreditsDialogVisuals(
      palette: palette,
      mode: _creditsVisualMode,
      themeBlend: themeBlend,
      glitchStrength: glitchStrength,
      reducedEffects: reducedEffects,
      shellStart: shellStart,
      shellEnd: shellEnd,
      panel: panel,
      panelAlt: panelAlt,
      frame: frame,
      edgeGlow: edgeGlow,
      primaryAccent: primaryAccent,
      secondaryAccent: secondaryAccent,
      tertiaryAccent: tertiaryAccent,
      titleColor: titleColor,
    );
  }

  TextStyle _creditsTitleStyle(
    _CreditsDialogVisuals visuals, {
    double size = 28,
    Color? color,
  }) {
    final resolvedColor = color ?? visuals.titleColor;
    if (visuals.isRetro) {
      return puzzleAcademyDisplayStyle(
        palette: visuals.palette,
        size: size,
        letterSpacing: 0.82,
        color: resolvedColor,
        withGlow: !visuals.reducedEffects,
      );
    }

    return TextStyle(
      color: resolvedColor,
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.18,
      height: 1.0,
      shadows: puzzleAcademyTextGlow(
        resolvedColor,
        monochrome: visuals.palette.monochrome,
        strength: 0.58,
      ),
    );
  }

  TextStyle _creditsLabelStyle(
    _CreditsDialogVisuals visuals, {
    double size = 11.5,
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) {
    final resolvedColor = color ?? visuals.palette.textMuted;
    if (visuals.isRetro) {
      return puzzleAcademyHudStyle(
        palette: visuals.palette,
        size: size,
        weight: weight,
        letterSpacing: 0.72,
        color: resolvedColor,
        withGlow: !visuals.reducedEffects,
      );
    }

    return TextStyle(
      color: resolvedColor,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: 0.26,
      height: 1.22,
    );
  }

  TextStyle _creditsBodyStyle(
    _CreditsDialogVisuals visuals, {
    double size = 12.6,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextStyle(
      color: color ?? visuals.palette.text,
      fontSize: size,
      fontWeight: weight,
      height: 1.45,
    );
  }

  TextStyle _creditsActionStyle(_CreditsDialogVisuals visuals, {Color? color}) {
    final resolvedColor = color ?? visuals.palette.text;
    if (visuals.isRetro) {
      return puzzleAcademyHudStyle(
        palette: visuals.palette,
        size: 11.0,
        weight: FontWeight.w700,
        letterSpacing: 0.78,
        color: resolvedColor,
        withGlow: !visuals.reducedEffects,
      );
    }

    return TextStyle(
      color: resolvedColor,
      fontSize: 12.0,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.24,
    );
  }

  Widget _buildCreditsGlitchShell({
    required _CreditsDialogVisuals visuals,
    required Widget child,
  }) {
    final strength = visuals.glitchStrength;
    final effectEnabled = strength > 0.01 && !visuals.reducedEffects;

    final phase = _pulseController.value * 2 * pi;
    final baseJitter = Offset(
      sin(phase * 9.5) * strength * 1.15,
      cos(phase * 6.8) * strength * 0.36,
    );
    final shellSkew = sin(phase * 1.9) * strength * 0.0036;
    final fragmentSpecs =
        <
          ({
            double top,
            double height,
            double inset,
            double offset,
            double opacity,
            Color tint,
          })
        >[
          (
            top: 0.08 + (sin(phase * 0.8) + 1.0) * 0.015,
            height: 0.07,
            inset: 0.02,
            offset: -26 * strength,
            opacity: 0.16 + strength * 0.14,
            tint: visuals.primaryAccent,
          ),
          (
            top: 0.23 + (cos(phase * 1.1) + 1.0) * 0.018,
            height: 0.05,
            inset: 0.10,
            offset: 30 * strength,
            opacity: 0.14 + strength * 0.12,
            tint: visuals.secondaryAccent,
          ),
          (
            top: 0.36 + (sin(phase * 1.6) + 1.0) * 0.012,
            height: 0.09,
            inset: 0.04,
            offset: -16 * strength,
            opacity: 0.18 + strength * 0.12,
            tint: Colors.white,
          ),
          (
            top: 0.55 + (cos(phase * 1.9) + 1.0) * 0.02,
            height: 0.06,
            inset: 0.14,
            offset: 22 * strength,
            opacity: 0.12 + strength * 0.11,
            tint: visuals.primaryAccent,
          ),
          (
            top: 0.72 + (sin(phase * 1.3) + 1.0) * 0.018,
            height: 0.07,
            inset: 0.03,
            offset: -24 * strength,
            opacity: 0.16 + strength * 0.13,
            tint: visuals.secondaryAccent,
          ),
        ];

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(
            effectEnabled ? baseJitter.dx : 0,
            effectEnabled ? baseJitter.dy : 0,
            0,
          )..setEntry(0, 1, effectEnabled ? shellSkew : 0),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: effectEnabled ? 0.12 + strength * 0.34 : 0.0,
              sigmaY: effectEnabled ? 0.04 + strength * 0.10 : 0.0,
            ),
            child: child,
          ),
        ),
        if (effectEnabled)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    visuals.primaryAccent.withValues(alpha: 0.012),
                    Colors.transparent,
                    visuals.secondaryAccent.withValues(alpha: 0.018),
                    Colors.transparent,
                    visuals.primaryAccent.withValues(alpha: 0.014),
                  ],
                  stops: const <double>[0.0, 0.16, 0.52, 0.82, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        if (effectEnabled)
          for (final fragment in fragmentSpecs)
            IgnorePointer(
              child: ClipRect(
                clipper: _CreditsGlitchBandClipper(
                  topFraction: fragment.top,
                  heightFraction: fragment.height,
                  horizontalInsetFraction: fragment.inset,
                ),
                child: Transform.translate(
                  offset: Offset(
                    fragment.offset,
                    sin(phase * 4.0 + fragment.top * 10) * strength * 0.85,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: <Color>[
                          fragment.tint.withValues(alpha: 0.0),
                          fragment.tint.withValues(
                            alpha: fragment.opacity * 0.54,
                          ),
                          Colors.white.withValues(
                            alpha: fragment.opacity * 0.32,
                          ),
                          fragment.tint.withValues(
                            alpha: fragment.opacity * 0.18,
                          ),
                          fragment.tint.withValues(alpha: 0.0),
                        ],
                        stops: const <double>[0.0, 0.18, 0.5, 0.82, 1.0],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: fragment.tint.withValues(alpha: 0.24),
                        ),
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildCreditsGlitchTitle({
    required String text,
    required TextStyle style,
    required _CreditsDialogVisuals visuals,
    Key? key,
  }) {
    final strength = visuals.glitchStrength;
    if (strength <= 0.01 || visuals.reducedEffects) {
      return Text(text, key: key, style: style);
    }

    final phase = _pulseController.value * 2 * pi;
    final primaryOffset = Offset(
      sin(phase * 1.7) * strength * 3.0,
      cos(phase * 2.1) * strength * 0.5,
    );
    final secondaryOffset = Offset(-cos(phase * 1.3) * strength * 2.6, 0);

    return Stack(
      children: <Widget>[
        Transform.translate(
          offset: primaryOffset,
          child: Opacity(
            opacity: 0.24 + strength * 0.12,
            child: Text(
              text,
              style: style.copyWith(color: visuals.primaryAccent),
            ),
          ),
        ),
        Transform.translate(
          offset: secondaryOffset,
          child: Opacity(
            opacity: 0.18 + strength * 0.10,
            child: Text(
              text,
              style: style.copyWith(color: visuals.secondaryAccent),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(
            sin(phase * 8.0) * strength * 0.6,
            cos(phase * 6.0) * strength * 0.2,
          ),
          child: Text(text, key: key, style: style),
        ),
      ],
    );
  }

  Widget _buildCreditsLogoMark(
    _CreditsDialogVisuals visuals, {
    required double width,
  }) {
    final baseLogo = Image.asset(
      'assets/QILAmodus.png',
      width: width,
      fit: BoxFit.contain,
    );
    final strength = visuals.glitchStrength;

    if (strength <= 0.01 || visuals.reducedEffects) {
      return baseLogo;
    }

    final phase = _pulseController.value * 2 * pi;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Transform.translate(
          offset: Offset(-2.6 * strength + sin(phase * 1.8), 0),
          child: Opacity(
            opacity: 0.22 + strength * 0.10,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                visuals.primaryAccent.withValues(alpha: 0.85),
                BlendMode.srcATop,
              ),
              child: baseLogo,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(2.2 * strength - cos(phase * 1.4), 0),
          child: Opacity(
            opacity: 0.18 + strength * 0.08,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                visuals.secondaryAccent.withValues(alpha: 0.85),
                BlendMode.srcATop,
              ),
              child: baseLogo,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(sin(phase * 5.0) * strength * 0.4, 0),
          child: baseLogo,
        ),
      ],
    );
  }

  Widget _buildCreditsHero({
    required _CreditsDialogVisuals visuals,
    required Duration duration,
    required Curve curve,
    required bool condensed,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      padding: EdgeInsets.fromLTRB(
        condensed ? 12 : 14,
        condensed ? 12 : 14,
        condensed ? 12 : 14,
        condensed ? 12 : 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(visuals.isRetro ? 12 : 18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            visuals.panel.withValues(alpha: 0.96),
            visuals.panelAlt.withValues(alpha: 0.84),
          ],
        ),
        border: Border.all(
          color: visuals.frame.withValues(alpha: visuals.isRetro ? 0.72 : 0.30),
          width: visuals.isRetro ? 1.8 : 1.0,
        ),
        boxShadow: puzzleAcademySurfaceGlow(
          visuals.edgeGlow,
          monochrome: visuals.palette.monochrome,
          strength: visuals.isRetro ? 0.18 : 0.10,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420 || condensed;
          final titleStyle = _creditsTitleStyle(
            visuals,
            size: compact ? (condensed ? 21 : 24) : 27,
          );
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildCreditsGlitchTitle(
                text: 'Credits, Data & Legal',
                key: const ValueKey<String>('credits_dialog_title'),
                style: titleStyle,
                visuals: visuals,
              ),
              SizedBox(height: condensed ? 8 : 10),
              Text(
                'Product lineage, community feedback, data sources, and legal access points for the ChessIQ shell.',
                style: _creditsBodyStyle(
                  visuals,
                  size: condensed ? 11.8 : 12.5,
                  color: visuals.palette.text.withValues(alpha: 0.88),
                ),
              ),
              SizedBox(height: condensed ? 8 : 10),
              _buildCreditsVersionLabel(visuals, condensed: condensed),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: _buildCreditsLogoMark(
                    visuals,
                    width: condensed ? 180 : 220,
                  ),
                ),
                SizedBox(height: condensed ? 10 : 14),
                titleBlock,
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Center(
                  child: _buildCreditsLogoMark(
                    visuals,
                    width: condensed ? 186 : 230,
                  ),
                ),
              ),
              SizedBox(width: condensed ? 12 : 18),
              Expanded(flex: 6, child: titleBlock),
            ],
          );
        },
      ),
    );
  }

  Future<String> _loadCreditsVersionLabel() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      final buildNumber = packageInfo.buildNumber.trim();
      if (version.isEmpty) {
        return 'Version unavailable';
      }
      return buildNumber.isEmpty
          ? 'Version $version'
          : 'Version $version (Build $buildNumber)';
    } catch (_) {
      return 'Version unavailable';
    }
  }

  Widget _buildCreditsVersionLabel(
    _CreditsDialogVisuals visuals, {
    required bool condensed,
  }) {
    return FutureBuilder<String>(
      future: _creditsVersionFuture,
      initialData: 'Version...',
      builder: (context, snapshot) {
        final versionLabel = snapshot.data ?? 'Version...';
        return Text(
          versionLabel,
          key: const ValueKey<String>('credits_version_label'),
          style: _creditsBodyStyle(
            visuals,
            size: condensed ? 11.0 : 11.6,
            color: visuals.secondaryAccent.withValues(alpha: 0.90),
            weight: FontWeight.w700,
          ),
        );
      },
    );
  }

  Widget _buildCreditsOwnershipPanel({required _CreditsDialogVisuals visuals}) {
    Future<void> openFeedbackPage() async {
      const feedbackUrl = 'https://modus.qila.gl/ChessIQ/feedback';
      final feedbackUri = Uri.parse(feedbackUrl);

      final launched = await launchUrl(feedbackUri);
      if (launched || !mounted) return;
      await Clipboard.setData(const ClipboardData(text: feedbackUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the feedback page. The URL has been copied instead.',
          ),
        ),
      );
    }

    Future<void> openPrivacyNotice() async {
      final launched = await launchUrl(chessIqPrivacyNoticeUri);
      if (launched || !mounted) return;
      await Clipboard.setData(
        const ClipboardData(text: chessIqPrivacyNoticeUrl),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the privacy notice. The URL has been copied instead.',
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey<String>('credits_ownership_copy'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            visuals.panel.withValues(alpha: 0.96),
            visuals.panelAlt.withValues(alpha: visuals.isRetro ? 0.84 : 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(visuals.isRetro ? 10 : 16),
        border: Border.all(
          color: visuals.frame.withValues(alpha: visuals.isRetro ? 0.72 : 0.28),
          width: visuals.isRetro ? 1.8 : 1.0,
        ),
        boxShadow: puzzleAcademySurfaceGlow(
          visuals.edgeGlow,
          monochrome: visuals.palette.monochrome,
          strength: visuals.isRetro ? 0.16 : 0.10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.forum_outlined,
                size: 16,
                color: visuals.primaryAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'COMMUNITY / LEGAL',
                style: _creditsLabelStyle(
                  visuals,
                  color: visuals.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'ChessIQ is an open-source project that is actively developed in public. The current release is designed to be dependable and polished, while the broader product continues to evolve through new ideas, feature additions, refinements, and quality improvements from the community that uses it.',
            style: _creditsBodyStyle(
              visuals,
              size: 12.4,
              color: visuals.palette.text.withValues(alpha: 0.90),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _buildLegalNoticeLink(
                key: const ValueKey<String>('credits_legal_link_copyright'),
                label: 'Project Record',
                icon: Icons.copyright_rounded,
                accent: visuals.primaryAccent,
                visuals: visuals,
                onTap: () => _showLegalNoticeDialog(
                  title: 'COPYRIGHT.md',
                  assetPath: 'COPYRIGHT.md',
                  accent: visuals.primaryAccent,
                ),
              ),
              _buildLegalNoticeLink(
                key: const ValueKey<String>('credits_legal_link_third_party'),
                label: 'Third-Party Notices',
                icon: Icons.policy_outlined,
                accent: visuals.tertiaryAccent,
                visuals: visuals,
                onTap: () => _showLegalNoticeDialog(
                  title: 'THIRD_PARTY_NOTICES.md',
                  assetPath: 'THIRD_PARTY_NOTICES.md',
                  accent: visuals.tertiaryAccent,
                ),
              ),
              _buildLegalNoticeLink(
                key: const ValueKey<String>('credits_legal_link_license'),
                label: 'License',
                icon: Icons.gavel_rounded,
                accent: visuals.secondaryAccent,
                visuals: visuals,
                onTap: () => _showLegalNoticeDialog(
                  title: 'LICENSE',
                  assetPath: 'LICENSE',
                  accent: visuals.secondaryAccent,
                ),
              ),
              _buildLegalNoticeLink(
                key: const ValueKey<String>('credits_legal_link_privacy'),
                label: 'Privacy Notice',
                icon: Icons.open_in_new_rounded,
                accent: visuals.primaryAccent,
                visuals: visuals,
                onTap: () {
                  unawaited(openPrivacyNotice());
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Leaderboard privacy: the nickname and country or region you choose may be displayed publicly with your score and title. ChessIQ also sends an anonymous Firebase ID and update metadata to the backend to manage the entry. Email, real name, and precise location are not requested, and network metadata such as IP addresses is not shown on the public leaderboard.',
            style: _creditsBodyStyle(
              visuals,
              size: 11.6,
              color: visuals.palette.text.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ideas for improvement, bug reports, and community contributions are welcome. Thoughtful feedback helps guide future updates, prioritize fixes, and refine the project over time.',
            style: _creditsBodyStyle(
              visuals,
              size: 12.0,
              color: visuals.palette.text.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 10),
          _buildLegalNoticeLink(
            label: 'Suggestions & Bug Reports',
            icon: Icons.open_in_new_rounded,
            accent: visuals.primaryAccent,
            visuals: visuals,
            onTap: () {
              unawaited(openFeedbackPage());
            },
          ),
          const SizedBox(height: 10),
          Text(
            'The feedback button opens the hosted ChessIQ feedback page. The hosted privacy notice opens in your browser, while the other buttons open the bundled legal records.',
            style: _creditsLabelStyle(
              visuals,
              size: 10.9,
              color: visuals.palette.textMuted,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsFooterActions({
    required BuildContext context,
    required bool openedFromAnalysis,
    required _CreditsDialogVisuals visuals,
  }) {
    final primaryColor = visuals.isRetro
        ? visuals.secondaryAccent
        : visuals.primaryAccent;
    final foregroundColor =
        ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.light
        ? const Color(0xFF10151A)
        : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        final logsButton = OutlinedButton.icon(
          onPressed: _showLogsDialog,
          icon: Icon(
            Icons.bug_report_outlined,
            size: visuals.isRetro ? 16 : 18,
          ),
          label: Text(
            'View Logs',
            style: _creditsActionStyle(visuals, color: visuals.primaryAccent),
          ),
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll<Color>(
              visuals.primaryAccent,
            ),
            backgroundColor: WidgetStatePropertyAll<Color>(
              visuals.primaryAccent.withValues(
                alpha: visuals.isRetro ? 0.14 : 0.08,
              ),
            ),
            side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(
                color: visuals.frame.withValues(
                  alpha: visuals.isRetro ? 0.82 : 0.40,
                ),
                width: visuals.isRetro ? 1.6 : 1.0,
              ),
            ),
            padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(visuals.isRetro ? 8 : 14),
              ),
            ),
          ),
        );
        final closeButton = FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            if (!openedFromAnalysis) {
              Future.microtask(() {
                if (mounted) {
                  _goToMenu();
                }
              });
            }
          },
          icon: Icon(
            openedFromAnalysis ? Icons.close_rounded : Icons.home_rounded,
            size: visuals.isRetro ? 16 : 18,
          ),
          label: Text(
            openedFromAnalysis ? 'Close Credits' : 'Back to Main Menu',
            style: _creditsActionStyle(visuals, color: foregroundColor),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(visuals.isRetro ? 8 : 14),
            ),
            side: BorderSide(
              color: visuals.frame.withValues(
                alpha: visuals.isRetro ? 0.84 : 0.36,
              ),
              width: visuals.isRetro ? 1.5 : 0.8,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              logsButton,
              const SizedBox(height: 10),
              closeButton,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: logsButton),
            const SizedBox(width: 10),
            Expanded(child: closeButton),
          ],
        );
      },
    );
  }

  Alignment _menuDotAlignment(
    double phase,
    double speed,
    double radius,
    double pulse,
    double trajectoryNoise,
    double shapeSeed,
    bool inverted,
  ) {
    final time =
        pulse * 2.6 * speed + phase + shapeSeed * (inverted ? 1.22 : 1.0);
    final x = inverted
        ? cos(time * (1.45 + shapeSeed * 0.16) + 0.7) * radius * 0.82 +
              cos(time * (2.9 + shapeSeed * 0.20) - 1.1) * 0.10 +
              sin(time * (4.6 + shapeSeed * 0.27) + 0.9) * 0.05
        : sin(time * (1.25 + shapeSeed * 0.14)) * radius +
              sin(time * (2.7 + shapeSeed * 0.22) + 1.3 + shapeSeed * 0.9) *
                  0.12 +
              sin(time * (4.1 + shapeSeed * 0.35) + 2.1) * 0.06;
    final y = inverted
        ? sin(time * (1.65 + shapeSeed * 0.19) - 0.5) * radius * 0.90 +
              sin(time * (2.55 + shapeSeed * 0.13) + 0.2) * 0.12 +
              cos(time * (3.9 + shapeSeed * 0.33) - 0.4) * 0.06
        : cos(time * (1.77 + shapeSeed * 0.18) + 0.4) * radius * 0.88 +
              cos(time * (2.35 + shapeSeed * 0.15) - 0.8) * 0.11 +
              sin(time * (3.9 + shapeSeed * 0.28) + 0.6) * 0.05;
    final driftX = inverted
        ? cos(time * (0.70 + shapeSeed * 0.05) - 0.4) * 0.05
        : sin(time * (0.64 + shapeSeed * 0.04) + 1.2) * 0.04;
    final driftY = inverted
        ? sin(time * (0.88 + shapeSeed * 0.06) + 0.1) * 0.05
        : cos(time * (0.71 + shapeSeed * 0.03) - 0.7) * 0.04;
    final jitterX =
        sin(
          time * (0.92 + trajectoryNoise * 0.18 + shapeSeed * 0.06) +
              trajectoryNoise * 3.7 +
              (inverted ? 1.4 : 0.0),
        ) *
        (trajectoryNoise * 0.08 + shapeSeed * 0.04);
    final jitterY =
        cos(
          time * (1.08 + trajectoryNoise * 0.22 - shapeSeed * 0.07) -
              trajectoryNoise * 2.9 +
              (inverted ? 1.7 : 0.0),
        ) *
        (trajectoryNoise * 0.08 + shapeSeed * 0.04);
    final raw = Offset(x + driftX + jitterX, y + driftY + jitterY);
    final distance = raw.distance;
    const limit = 1.20;
    final returnFactor = distance > limit ? limit / distance : 1.0;
    return Alignment(raw.dx * returnFactor, raw.dy * returnFactor);
  }

  void _updateBotSetupBlueDotScrollOffset();

  Future<void> _playIntroSound() async {
    if (_muteSounds) return;
    try {
      await _introAudioPlayer.stop();
      await _introAudioPlayer.setReleaseMode(ReleaseMode.stop);
      await _introAudioPlayer.play(
        AssetSource(_introSoundAssetPath),
        mode: PlayerMode.mediaPlayer,
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('Intro sound failed: $e');
      _addLog('Intro sound failed: $e');
    }
  }

  Future<void> _playMenuMusic() async {
    if (_muteSounds || _menuMusicPlaying) return;
    try {
      await _menuAudioPlayer.setReleaseMode(ReleaseMode.stop);
      await _menuAudioPlayer.play(
        AssetSource('sounds/main.mp3'),
        mode: PlayerMode.mediaPlayer,
        volume: 0.0,
      );
      _menuMusicPlaying = true;
      _menuMusicFadeController.reset();
      _menuMusicFadeController.forward().then((_) async {
        if (_menuMusicPlaying) {
          await _menuAudioPlayer.setVo