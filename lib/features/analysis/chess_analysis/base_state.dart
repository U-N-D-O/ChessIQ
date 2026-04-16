part of '../screens/chess_analysis_page.dart';

abstract class _ChessAnalysisPageStateBase extends State<ChessAnalysisPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _lastBotIndexKey = 'last_bot_index_v1';
  static const BoardPerspective _defaultPerspective = BoardPerspective.white;
  static const BoardThemeMode _defaultBoardTheme = BoardThemeMode.dark;
  static const PieceThemeMode _defaultPieceTheme = PieceThemeMode.classic;
  static const int _defaultEngineDepth = 20;
  static const int _defaultMultiPvCount = 1;
  static const String _savedDefaultSnapshotKey = 'saved_default_snapshot_v1';
  static const String _storeStateKey = 'store_state_v1';
  static const String _muteSoundsKey = 'mute_sounds_v1';
  static const String _hapticsEnabledKey = 'haptics_enabled_v1';
  static const String _cinematicThemeEnabledKey = 'cinematic_theme_enabled_v1';
  static const String _analysisEngineOwner = 'analysis.board';
  static const String _vsBotEngineOwner = 'analysis.vsbot';

  late Map<String, String> boardState;
  EngineService? _engine;
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
  bool _openingButtonFlashRed = false;
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
  bool _screenActive = true;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  DateTime? _menuSparkLastUpdate;
  DateTime? _creditsBackdropLastUpdate;
  double _menuDotTime = 0.0;
  double _blueYellowContactTime = 0.0;
  late final double _blueDotPhase;
  late final double _yellowDotPhase;
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

  double _menuCenterRotationA = 0.0;
  double _menuCenterRotationB = 0.0;
  int _menuCenterShapeSidesA = 4;
  int _menuCenterShapeSidesB = 5;
  double _menuCenterShapeChangeTimerA = 1.6;
  double _menuCenterShapeChangeTimerB = 1.2;
  double _menuCenterSpinSpeed = _menuCenterBaseSpinSpeed;
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
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _suggestionButtonKey = GlobalKey();
  final GlobalKey _storeButtonKey = GlobalKey();

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

  List<EngineLine> _topLines = [];
  final List<MoveRecord> _moveHistory = [];
  int _historyIndex = -1;
  late ScrollController _historyScrollController;
  final Map<String, String> _ecoOpenings = {};
  final List<EcoLine> _ecoLines = [];
  int _quizEligibleCount = 0;
  final Map<String, List<EcoLine>> _quizEligiblePoolCache =
      <String, List<EcoLine>>{};
  final Map<String, Set<String>> _quizEligibleNameCache =
      <String, Set<String>>{};
  bool _quizPoolsPrecomputed = false;
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
  int _vsBotSessionWins = 0;
  int _vsBotSessionLosses = 0;
  int _vsBotSessionDraws = 0;
  Completer<List<EngineLine>>? _botSearchCompleter;
  final Map<int, EngineLine> _botSearchLines = <int, EngineLine>{};
  int _botSearchMultiPv = 1;
  final PageController _botSetupPageController = PageController(
    viewportFraction: 0.60,
  );
  int _botSetupSelectedIndex = 0;
  Future<void> _loadLastBotIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_lastBotIndexKey);
    if (idx != null && idx >= 0 && idx < _botCharacters.length) {
      setState(() {
        _botSetupSelectedIndex = idx;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_botSetupPageController.hasClients) {
          _botSetupPageController.jumpToPage(idx);
        }
      });
    }
  }

  Future<void> _saveLastBotIndex(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBotIndexKey, idx);
  }

  BotSideChoice _botSideChoice = BotSideChoice.random;

  int _depthTier = 1; // 1=pro,2=expert,3=grandmaster,4=oracle
  int _extraSuggestionPurchases = 0; // each +1 up to max 10 suggestions
  bool _themePackOwned = false;
  bool _sakuraBoardOwned = false;
  bool _tropicalBoardOwned = false;
  bool _tuttiFruttiOwned = false;
  bool _spectralOwned = false;
  bool _piecePackOwned = false;
  bool _adFreeOwned = false;
  bool _academyTuitionPassOwned = false;
  bool _introCompleted = true;
  bool _suggestionsEnabled = false;
  bool _suggestionLaunchInProgress = false;
  bool _suggestionBurstActive = false;
  Offset? _launchStart;
  List<Offset> _launchTargets = <Offset>[];
  GameOutcome? _gameOutcome;
  bool _gameResultDialogVisible = false;

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
  Timer? _editModeHintTimer;
  String? _editModeHintText;
  final Set<String> _viewedGambits = <String>{};
  String _quizPrompt = '';
  String _quizPromptFocus = '';
  List<String> _quizOptions = <String>[];
  int _quizCorrectIndex = 0;
  String _quizFeedback = '';
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
  QuizDifficulty _quizDifficulty = QuizDifficulty.medium;
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

  void _openGambitQuizFromMenu();

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

  void _scheduleEditModeHintHide() {
    _editModeHintTimer?.cancel();
    _editModeHintTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _editModeHintText = null;
      });
    });
  }

  void _startIdleInterstitialTimer() {
    _cancelIdleInterstitialTimer();
    if (!_screenActive || _lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _idleInterstitialTimer = Timer(const Duration(minutes: 3), () async {
      if (!mounted ||
          !_screenActive ||
          _lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      final shown = await AdService.instance.showInterstitialAd();
      if (shown && mounted) {
        await _handleAnalysisInterstitialShown();
        _resetIdleTimer();
      }
    });
  }

  void _cancelIdleInterstitialTimer() {
    _idleInterstitialTimer?.cancel();
    _idleInterstitialTimer = null;
  }

  void _resetIdleTimer() {
    _startIdleInterstitialTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      _screenActive = true;
      _resetIdleTimer();
    } else {
      _screenActive = false;
      _cancelIdleInterstitialTimer();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastBotIndex();
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
    _blueDotPhase = random.nextDouble() * 2 * pi;
    _yellowDotPhase = random.nextDouble() * 2 * pi;
    _blueDotSpeed = (0.28 + random.nextDouble() * 0.12) * 1.40;
    _yellowDotSpeed = (0.25 + random.nextDouble() * 0.12) * 1.40;
    _blueDotRadius = 0.58 + random.nextDouble() * 0.12;
    _yellowDotRadius = 0.52 + random.nextDouble() * 0.12;
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

    final centerTime = _menuCenterLastUpdate == null
        ? 0.0
        : now.difference(_menuCenterLastUpdate!).inMilliseconds / 1000.0;
    _menuCenterLastUpdate = now;
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

    final pulse = _menuDotTime;
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

      final origin = Offset(
        (_blueMenuDotPosition.dx + _yellowMenuDotPosition.dx) / 2,
        (_blueMenuDotPosition.dy + _yellowMenuDotPosition.dy) / 2,
      );
      final particleCount = Random().nextInt(2) + 1;
      for (var i = 0; i < particleCount; i++) {
        final angle = Random().nextDouble() * 2 * pi;
        final velocity = Offset(
          cos(angle) * (0.8 + Random().nextDouble() * 0.6),
          sin(angle) * (0.8 + Random().nextDouble() * 0.6),
        );
        _menuSparkParticles.add(
          _MenuSparkParticle(
            position: origin,
            velocity: velocity,
            color: Colors.green.withValues(alpha: 0.90),
          ),
        );
      }

      unawaited(_lightHaptic());

      final direction = separation / collisionDistance;
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
        blueSpring + blueOrbit + blueTwist + blueNoise + blueChaos + blueRadial;
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
      return particle.position.dx.abs() > 1.2 ||
          particle.position.dy.abs() > 1.2;
    });

    if (_creditsDialogOpen) {
      final creditsLast = _creditsBackdropLastUpdate ?? now;
      final creditsDt = now.difference(creditsLast).inMilliseconds / 1000.0;
      _creditsBackdropLastUpdate = now;
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

  Widget _buildMenuCenterShape({
    required double size,
    required Color strokeColor,
    required double strokeWidth,
    required double rotation,
    required int sides,
  }) {
    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RegularPolygonPainter(
            sides: sides,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
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

  void _updateBotSetupBlueDotScrollOffset() {
    _blueDotScrollVelocity *= 0.93;
    _blueDotScrollOffset += _blueDotScrollVelocity * 0.016;
    _blueDotScrollOffset = _blueDotScrollOffset.clamp(-1.15, 1.15);
  }

  Future<void> _playIntroSound() async {
    if (_muteSounds) return;
    try {
      await _introAudioPlayer.stop();
      await _introAudioPlayer.setReleaseMode(ReleaseMode.stop);
      await _introAudioPlayer.play(
        AssetSource('sounds/intro.mp3'),
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
          await _menuAudioPlayer.setVolume(0.45);
        }
      });
    } catch (e) {
      debugPrint('Menu music failed: $e');
      _addLog('Menu music failed: $e');
    }
  }

  Future<void> _stopMenuMusic({bool fadeOut = true}) async {
    if (!_menuMusicPlaying) return;
    try {
      if (fadeOut) {
        await _menuMusicFadeController.reverse();
      }
      await _menuAudioPlayer.stop();
    } catch (e) {
      debugPrint('Stopping menu music failed: $e');
      _addLog('Stopping menu music failed: $e');
    } finally {
      _menuMusicPlaying = false;
    }
  }

  Future<void> _playCoinRewardSound() async {
    if (_muteSounds) return;
    try {
      await _sfxAudioPlayer.stop();
      await _sfxAudioPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxAudioPlayer.setSource(AssetSource('sounds/coin.mp3'));
      await _sfxAudioPlayer.seek(const Duration(milliseconds: 300));
      await _sfxAudioPlayer.setVolume(1.0);
      await _sfxAudioPlayer.resume();
    } catch (e) {
      debugPrint('Coin reward sound failed: $e');
      _addLog('Coin reward sound failed: $e');
    }
  }

  Future<void> _playCoinBagSound() async {
    if (_muteSounds) return;
    try {
      await _sfxAudioPlayer.stop();
      await _sfxAudioPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxAudioPlayer.setSource(AssetSource('sounds/coinbag.mp3'));
      await _sfxAudioPlayer.setVolume(1.0);
      await _sfxAudioPlayer.resume();
    } catch (e) {
      debugPrint('Coin bag sound failed: $e');
      _addLog('Coin bag sound failed: $e');
    }
  }

  Future<void> _playCoinBagSoundL() async {
    if (_muteSounds) return;
    try {
      await _sfxAudioPlayer.stop();
      await _sfxAudioPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxAudioPlayer.setSource(AssetSource('sounds/coinbag2.mp3'));
      await _sfxAudioPlayer.setVolume(1.0);
      await _sfxAudioPlayer.resume();
    } catch (e) {
      debugPrint('Coin bag L sound failed: $e');
      _addLog('Coin bag L sound failed: $e');
    }
  }

  Future<void> _playBoardMoveSound({required bool isCapture}) async {
    if (_muteSounds) return;
    final assetPath = isCapture
        ? 'sounds/take1.wav'
        : 'sounds/move${_rng.nextInt(8) + 1}.wav';
    final player = _boardSfxPlayers[_nextBoardSfxPlayerIndex];
    _nextBoardSfxPlayerIndex =
        (_nextBoardSfxPlayerIndex + 1) % _boardSfxPlayers.length;
    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(
        AssetSource(assetPath),
        mode: PlayerMode.lowLatency,
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('Board move sound failed: $e');
      _addLog('Board move sound failed: $e');
    }
  }

  Future<void> _restoreSnapshotAndStart() async {
    await _loadUiPrefs();
    await _loadStoreState();
    await _loadSavedDefaultSnapshot();
    if (_activeSection == AppSection.menu ||
        _activeSection == AppSection.gambitQuiz) {
      unawaited(_playMenuMusic());
    }
  }

  Future<void> _loadUiPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _muteSounds = prefs.getBool(_muteSoundsKey) ?? false;
      _hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;
      _isCinematicThemeEnabled =
          prefs.getBool(_cinematicThemeEnabledKey) ?? false;
      _cinematicThemeNotifier.value = _isCinematicThemeEnabled;
      if (mounted) {
        unawaited(
          context.read<AppThemeProvider>().syncLegacySettings(
            cinematicEnabled: _isCinematicThemeEnabled,
            boardThemeIndex: _boardThemeMode.index,
            pieceThemeIndex: _pieceThemeMode.index,
            notify: false,
          ),
        );
      }
      _loadQuizPrefs(prefs);
    } catch (e) {
      debugPrint('Failed to load UI prefs: $e');
    }
  }

  Future<void> _setMute(bool value) async {
    setState(() => _muteSounds = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_muteSoundsKey, value);
    if (value) {
      await _introAudioPlayer.stop();
      await _stopMenuMusic(fadeOut: false);
      await _sfxAudioPlayer.stop();
      await Future.wait(_boardSfxPlayers.map((player) => player.stop()));
    } else if (_activeSection != AppSection.analysis) {
      await _playMenuMusic();
    }
  }

  Future<void> _setHapticsEnabled(bool value) async {
    setState(() => _hapticsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsEnabledKey, value);
  }

  Future<void> _setCinematicThemeEnabled(bool value) async {
    setState(() => _isCinematicThemeEnabled = value);
    _cinematicThemeNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cinematicThemeEnabledKey, value);
    if (mounted) {
      await context.read<AppThemeProvider>().setThemeStyle(
        value ? AppThemeStyle.monochrome : AppThemeStyle.standard,
      );
    }
  }

  Future<void> _lightHaptic() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> _checkHaptic() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.selectionClick();
  }

  int get _maxDepthAllowed {
    switch (_depthTier) {
      case 1:
        return 24;
      case 2:
        return 27;
      case 3:
        return 29;
      case 4:
        return 35;
      default:
        return 24;
    }
  }

  int get _maxSuggestionsAllowed =>
      (2 + _extraSuggestionPurchases).clamp(2, 10);

  int get _effectiveMultiPvCount => max(1, _multiPvCount);

  bool get _isEngineActive => _suggestionsEnabled;

  bool get _shouldShowVisualSuggestions => _isEngineActive && _multiPvCount > 0;

  bool get _shouldKeepEvalActive => _isEngineActive;

  bool _isBoardThemeUnlocked(BoardThemeMode mode) {
    return AppThemeProvider.isBoardThemeIndexUnlocked(
      mode.index,
      themePackOwned: _themePackOwned,
      sakuraBoardOwned: _sakuraBoardOwned,
      tropicalBoardOwned: _tropicalBoardOwned,
    );
  }

  bool _isPieceThemeUnlocked(PieceThemeMode mode) {
    return AppThemeProvider.isPieceThemeIndexUnlocked(
      mode.index,
      piecePackOwned: _piecePackOwned,
      tuttiFruttiOwned: _tuttiFruttiOwned,
      spectralOwned: _spectralOwned,
    );
  }

  List<BoardThemeMode> get _availableBoardThemes => BoardThemeMode.values
      .where(_isBoardThemeUnlocked)
      .toList(growable: false);

  List<PieceThemeMode> get _availablePieceThemes => PieceThemeMode.values
      .where(_isPieceThemeUnlocked)
      .toList(growable: false);

  void _normalizeUnlockedThemes() {
    if (!_isBoardThemeUnlocked(_boardThemeMode)) {
      _boardThemeMode = _defaultBoardTheme;
    }
    if (!_isPieceThemeUnlocked(_pieceThemeMode)) {
      _pieceThemeMode = _defaultPieceTheme;
    }
  }

  Future<void> _loadStoreState() async {
    try {
      await context.read<EconomyProvider>().refresh(notify: false);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storeStateKey);
      if (raw == null || raw.isEmpty) {
        _engineDepth = _engineDepth.clamp(10, _maxDepthAllowed);
        _multiPvCount = _multiPvCount.clamp(0, _maxSuggestionsAllowed);
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final tier = decoded['depthTier'];
      final extraSuggestions = decoded['extraSuggestions'];
      final themePack = decoded['themePackOwned'];
      final sakuraBoard = decoded['sakuraBoardOwned'];
      final tropicalBoard = decoded['tropicalBoardOwned'];
      final piecePack = decoded['piecePackOwned'];
      final tuttiFrutti = decoded['tuttiFruttiOwned'];
      final spectral = decoded['spectralOwned'];
      final adFree = decoded['adFreeOwned'];
      final academyTuitionPass = decoded['academyTuitionPassOwned'];

      if (tier is int) _depthTier = max(1, tier.clamp(1, 4));
      if (extraSuggestions is int) {
        _extraSuggestionPurchases = extraSuggestions.clamp(0, 8);
      }
      if (themePack is bool) _themePackOwned = themePack;
      if (sakuraBoard is bool) _sakuraBoardOwned = sakuraBoard;
      if (tropicalBoard is bool) _tropicalBoardOwned = tropicalBoard;
      if (piecePack is bool) _piecePackOwned = piecePack;
      if (tuttiFrutti is bool) _tuttiFruttiOwned = tuttiFrutti;
      if (spectral is bool) _spectralOwned = spectral;
      if (adFree is bool) _adFreeOwned = adFree;
      if (academyTuitionPass is bool) {
        _academyTuitionPassOwned = academyTuitionPass;
      }

      _engineDepth = _engineDepth.clamp(10, _maxDepthAllowed);
      _multiPvCount = _multiPvCount.clamp(0, _maxSuggestionsAllowed);
      _normalizeUnlockedThemes();

      // ── Restore IAP-delivered non-consumable flags ────────────────────────
      if (await PurchaseService.instance.isOwned(IapProducts.resetBoardPass)) {
        _adFreeOwned = true;
      }
      if (await PurchaseService.instance.isOwned(IapProducts.academyPass)) {
        _academyTuitionPassOwned = true;
      }
    } catch (e) {
      debugPrint('Failed to load store state: $e');
    }
  }

  Future<void> _saveStoreState() async {
    final economy = context.read<EconomyProvider>();
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'coins': economy.coins,
      'depthTier': _depthTier,
      'extraSuggestions': _extraSuggestionPurchases,
      'themePackOwned': _themePackOwned,
      'sakuraBoardOwned': _sakuraBoardOwned,
      'tropicalBoardOwned': _tropicalBoardOwned,
      'tuttiFruttiOwned': _tuttiFruttiOwned,
      'spectralOwned': _spectralOwned,
      'piecePackOwned': _piecePackOwned,
      'adFreeOwned': _adFreeOwned,
      'academyTuitionPassOwned': _academyTuitionPassOwned,
    };
    await prefs.setString(_storeStateKey, jsonEncode(payload));
  }

  String _storeRewardAdCountdownLabel(Duration remaining) {
    final economy = context.read<EconomyProvider>();
    if (economy.storeRewardLockedUntilTomorrow) {
      return 'tomorrow';
    }
    final totalMinutes = max(
      1,
      remaining.inMinutes + (remaining.inSeconds % 60 == 0 ? 0 : 1),
    );
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Future<void> _loadSavedDefaultSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedDefaultSnapshotKey);
      if (raw == null || raw.isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final savedPerspective = decoded['perspective'];
      final savedTheme = decoded['boardTheme'];
      final savedPieceTheme = decoded['pieceTheme'];
      final savedDepth = decoded['engineDepth'];
      final savedMultiPv = decoded['multiPvCount'];
      final savedWhiteTurn = decoded['isWhiteTurn'];
      final savedBoard = decoded['boardState'];
      final savedHistory = decoded['moveHistory'];
      final savedHistoryIndex = decoded['historyIndex'];
      final savedSuggestionsEnabled = decoded['suggestionsEnabled'];
      final savedTopLines = decoded['topLines'];
      final savedGambitPreviewLines = decoded['gambitPreviewLines'];
      final savedCurrentEval = decoded['currentEval'];
      final savedCurrentDepth = decoded['currentDepth'];
      final savedEvalWhiteTurn = decoded['evalWhiteTurn'];
      final savedCurrentOpening = decoded['currentOpening'];
      final savedWhiteKingMoved = decoded['whiteKingMoved'];
      final savedBlackKingMoved = decoded['blackKingMoved'];
      final savedWhiteKingsideRookMoved = decoded['whiteKingsideRookMoved'];
      final savedWhiteQueensideRookMoved = decoded['whiteQueensideRookMoved'];
      final savedBlackKingsideRookMoved = decoded['blackKingsideRookMoved'];
      final savedBlackQueensideRookMoved = decoded['blackQueensideRookMoved'];
      final savedEnPassantTarget = decoded['enPassantTarget'];

      if (savedPerspective is int &&
          savedPerspective >= 0 &&
          savedPerspective < BoardPerspective.values.length) {
        _perspective = BoardPerspective.values[savedPerspective];
      }
      if (savedTheme is int &&
          savedTheme >= 0 &&
          savedTheme < BoardThemeMode.values.length) {
        _boardThemeMode = BoardThemeMode.values[savedTheme];
      }
      if (savedPieceTheme is int &&
          savedPieceTheme >= 0 &&
          savedPieceTheme < PieceThemeMode.values.length) {
        _pieceThemeMode = PieceThemeMode.values[savedPieceTheme];
      }
      if (mounted) {
        unawaited(
          context.read<AppThemeProvider>().syncLegacySettings(
            boardThemeIndex: _boardThemeMode.index,
            pieceThemeIndex: _pieceThemeMode.index,
            notify: false,
          ),
        );
      }
      if (savedDepth is int) {
        _engineDepth = savedDepth.clamp(10, _maxDepthAllowed);
      }
      if (savedMultiPv is int) {
        _multiPvCount = savedMultiPv.clamp(0, _maxSuggestionsAllowed);
      }
      if (savedWhiteTurn is bool) {
        _isWhiteTurn = savedWhiteTurn;
      }
      if (savedSuggestionsEnabled is bool) {
        _suggestionsEnabled = savedSuggestionsEnabled;
      }
      if (savedCurrentEval is num) {
        _currentEval = savedCurrentEval.toDouble();
      }
      if (savedCurrentDepth is int) {
        _currentDepth = max(0, savedCurrentDepth);
      }
      if (savedEvalWhiteTurn is bool) {
        _evalWhiteTurn = savedEvalWhiteTurn;
      }
      if (savedWhiteKingMoved is bool) _whiteKingMoved = savedWhiteKingMoved;
      if (savedBlackKingMoved is bool) _blackKingMoved = savedBlackKingMoved;
      if (savedWhiteKingsideRookMoved is bool) {
        _whiteKingsideRookMoved = savedWhiteKingsideRookMoved;
      }
      if (savedWhiteQueensideRookMoved is bool) {
        _whiteQueensideRookMoved = savedWhiteQueensideRookMoved;
      }
      if (savedBlackKingsideRookMoved is bool) {
        _blackKingsideRookMoved = savedBlackKingsideRookMoved;
      }
      if (savedBlackQueensideRookMoved is bool) {
        _blackQueensideRookMoved = savedBlackQueensideRookMoved;
      }
      if (savedEnPassantTarget is String && savedEnPassantTarget.isNotEmpty) {
        _enPassantTarget = savedEnPassantTarget;
      }

      if (savedBoard is Map) {
        boardState = savedBoard.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }

      _moveHistory.clear();
      if (savedHistory is List) {
        for (final item in savedHistory) {
          if (item is Map) {
            final restored = _moveRecordFromMap(item);
            if (restored != null) {
              _moveHistory.add(restored);
            }
          }
        }
      }

      if (savedHistoryIndex is int &&
          savedHistoryIndex >= -1 &&
          savedHistoryIndex < _moveHistory.length) {
        _historyIndex = savedHistoryIndex;
      } else {
        _historyIndex = _moveHistory.isEmpty ? -1 : _moveHistory.length - 1;
      }

      _topLines = <EngineLine>[];
      if (savedTopLines is List) {
        for (final item in savedTopLines) {
          if (item is! Map) continue;
          final restored = EngineLine.fromMap(item);
          if (restored == null || restored.multiPv > _multiPvCount) continue;
          _topLines.add(restored);
        }
        _topLines.sort((a, b) => a.multiPv.compareTo(b.multiPv));
      }

      _gambitPreviewLines = <EngineLine>[];
      if (savedGambitPreviewLines is List) {
        for (final item in savedGambitPreviewLines) {
          if (item is! Map) continue;
          final restored = EngineLine.fromMap(item);
          if (restored == null) continue;
          _gambitPreviewLines.add(restored);
        }
      }

      _currentOpening = savedCurrentOpening is String
          ? savedCurrentOpening
          : '';
      _gambitSelectedFrom = null;
      _holdSelectedFrom = null;
      _legalTargets.clear();
      _gambitAvailableTargets.clear();
      _selectedGambit = null;
      _normalizeUnlockedThemes();
    } catch (e) {
      debugPrint('Failed to load saved default snapshot: $e');
    }
  }

  void _persistCurrentSettings() {
    unawaited(_saveCurrentAsDefaultSnapshot(logChange: false));
  }

  void _persistAnalysisSnapshotIfNeeded() {
    if (_playVsBot || _activeSection != AppSection.analysis) return;
    _persistCurrentSettings();
  }

  Future<void> _restoreAnalysisWorkspace() async {
    _resetBoard(withIntro: false);
    await _loadSavedDefaultSnapshot();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _releaseEngineSession() async {
    _engineStartFuture = null;
    final engine = _engine;
    _engine = null;
    _engineOwner = null;
    if (engine == null) return;
    try {
      await engine.stop();
    } catch (e) {
      _addLog('Engine release failed: $e');
      debugPrint('Engine release failed: $e');
    }
  }

  Map<String, dynamic> _moveRecordToMap(MoveRecord move) {
    return {
      'notation': move.notation,
      'pieceMoved': move.pieceMoved,
      'pieceCaptured': move.pieceCaptured,
      'state': move.state,
      'isWhite': move.isWhite,
      'whiteKingMoved': move.whiteKingMoved,
      'blackKingMoved': move.blackKingMoved,
      'whiteKingsideRookMoved': move.whiteKingsideRookMoved,
      'whiteQueensideRookMoved': move.whiteQueensideRookMoved,
      'blackKingsideRookMoved': move.blackKingsideRookMoved,
      'blackQueensideRookMoved': move.blackQueensideRookMoved,
      'enPassantTarget': move.enPassantTarget,
    };
  }

  MoveRecord? _moveRecordFromMap(Map<dynamic, dynamic> data) {
    try {
      final stateRaw = data['state'];
      if (stateRaw is! Map) {
        return null;
      }
      final mappedState = stateRaw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      return MoveRecord(
        notation: (data['notation'] ?? '').toString(),
        pieceMoved: (data['pieceMoved'] ?? '').toString(),
        pieceCaptured: data['pieceCaptured']?.toString(),
        state: mappedState,
        isWhite: data['isWhite'] == true,
        whiteKingMoved: data['whiteKingMoved'] == true,
        blackKingMoved: data['blackKingMoved'] == true,
        whiteKingsideRookMoved: data['whiteKingsideRookMoved'] == true,
        whiteQueensideRookMoved: data['whiteQueensideRookMoved'] == true,
        blackKingsideRookMoved: data['blackKingsideRookMoved'] == true,
        blackQueensideRookMoved: data['blackQueensideRookMoved'] == true,
        enPassantTarget: data['enPassantTarget']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  void _resetBoard({bool initialLaunch = false, bool withIntro = true}) {
    _send('stop');
    _send('ucinewgame');
    _clearBotGhostArrows();
    boardState = _initialBoardState();
    _isWhiteTurn = true;
    _resetSpecialMoveState();
    _moveHistory.clear();
    _historyIndex = -1;
    _currentOpening = '';
    _openingMode = OpeningMode.off;
    _gambitSelectedFrom = null;
    _holdSelectedFrom = null;
    _legalTargets.clear();
    _gambitAvailableTargets.clear();
    _selectedGambit = null;
    _gambitPreviewLines = [];
    _suggestionsEnabled = false;
    _suggestionLaunchInProgress = false;
    _suggestionBurstActive = false;
    _botThinking = false;
    _gameOutcome = null;
    _gameResultDialogVisible = false;
    _launchStart = null;
    _launchTargets = <Offset>[];
    _topLines = [];
    _currentDepth = 0;
    _currentEval = 0.0;
    _evalWhiteTurn = true;
    if (withIntro) {
      _introCompleted = false;
      _buttonUnlocked = false;
      _introController.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final delay = initialLaunch
            ? const Duration(milliseconds: 800)
            : Duration.zero;
        Future.delayed(delay, () {
          if (!mounted) return;
          unawaited(_playIntroSound());
        });
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (mounted) setState(() => _buttonUnlocked = true);
        });
      });
    } else {
      _introCompleted = true;
      _buttonUnlocked = true;
      _introController.value = 1.0;
    }
  }

  // --- Engine Logic ---
  Future<void> _startEngine() async {
    if (kIsWeb) {
      _addLog('Engine unavailable on web; running without Stockfish process.');
      return;
    }
    final desiredOwner = _playVsBot ? _vsBotEngineOwner : _analysisEngineOwner;
    if (_engine != null && _engineOwner == desiredOwner) return;

    if (_engine != null && _engineOwner != desiredOwner) {
      await _releaseEngineSession();
    }

    final nextEngine = createEngineService(owner: desiredOwner);
    _engine = nextEngine;
    _engineOwner = desiredOwner;

    try {
      await nextEngine.start(_parseOutput);
      nextEngine.send('uci');
      nextEngine.send('setoption name MultiPV value $_effectiveMultiPvCount');
      if (_shouldKeepEvalActive || _shouldShowVisualSuggestions) {
        _analyze();
      }
    } catch (e) {
      if (identical(_engine, nextEngine)) {
        _engine = null;
        _engineOwner = null;
      }
      _addLog('Engine start failed: $e');
      debugPrint('Engine start failed: $e');
    }
  }

  Future<void> _ensureEngineStarted() async {
    if (kIsWeb || _engine != null) return;
    _engineStartFuture ??= _startEngine();
    try {
      await _engineStartFuture;
    } finally {
      _engineStartFuture = null;
    }
  }

  void _send(String cmd) => _engine?.send(cmd);

  bool get _isHumanTurnInBotGame {
    if (!_playVsBot || _selectedBot == null) return true;
    return _isWhiteTurn == _humanPlaysWhite;
  }

  void _analyze() {
    final shouldShowVisualSuggestions = _shouldShowVisualSuggestions;
    if ((_playVsBot && !_isHumanTurnInBotGame) ||
        (!_shouldKeepEvalActive && !shouldShowVisualSuggestions)) {
      _send('stop');
      setState(() {
        _topLines = [];
        _currentDepth = 0;
      });
      return;
    }
    _send('stop');
    setState(() {
      _topLines = [];
      _currentDepth = 0;
    });
    _send(
      'setoption name MultiPV value ${shouldShowVisualSuggestions ? _effectiveMultiPvCount : 1}',
    );
    _send('position fen ${_genFen()}');
    _send('go depth $_engineDepth');
  }

  void _applySuggestionCount(int count, {bool persist = false}) {
    final nextCount = count.clamp(0, _maxSuggestionsAllowed);
    final changed = nextCount != _multiPvCount;

    setState(() {
      _multiPvCount = nextCount;
      if (nextCount <= 0) {
        _topLines = [];
        _currentDepth = 0;
      } else {
        _topLines =
            _topLines.where((line) => line.multiPv <= nextCount).toList()
              ..sort((a, b) => a.multiPv.compareTo(b.multiPv));
      }
    });

    if (changed) {
      _send('stop');
      _send('setoption name MultiPV value ${max(1, nextCount)}');
      if (_shouldKeepEvalActive || (_suggestionsEnabled && nextCount > 0)) {
        _analyze();
      }
    }

    if (persist) {
      _persistCurrentSettings();
    }
  }

  void _parseOutput(String line) {
    if (line.startsWith('bestmove')) {
      final activeSearch = _botSearchCompleter;
      if (activeSearch != null && !activeSearch.isCompleted) {
        final sorted = _sortedBotSearchLines();
        if (sorted.isEmpty) {
          final fallback = RegExp(
            r'^bestmove\s+([a-h][1-8][a-h][1-8][nbrq]?)',
          ).firstMatch(line);
          if (fallback != null) {
            activeSearch.complete([
              EngineLine(fallback.group(1)!, 0, _currentDepth, 1),
            ]);
          } else {
            activeSearch.complete(const <EngineLine>[]);
          }
        } else {
          activeSearch.complete(sorted);
        }
      }
      return;
    }

    if (!line.startsWith('info depth')) return;
    final activeSearch = _botSearchCompleter;
    final botSearchActive = activeSearch != null && !activeSearch.isCompleted;
    final shouldShowVisualSuggestions =
        _shouldShowVisualSuggestions && (!_playVsBot || _isHumanTurnInBotGame);
    if (!botSearchActive &&
        !shouldShowVisualSuggestions &&
        !_shouldKeepEvalActive) {
      return;
    }
    if (_gameOutcome != null && !botSearchActive) {
      return;
    }
    final d = RegExp(r'depth (\d+)').firstMatch(line);
    final pv = RegExp(r'multipv (\d+)').firstMatch(line);
    final m = RegExp(r'pv ([a-h][1-8][a-h][1-8][nbrq]?)').firstMatch(line);
    final sCp = RegExp(r'score cp (-?\d+)').firstMatch(line);
    final sMate = RegExp(r'score mate (-?\d+)').firstMatch(line);

    if (d != null && pv != null && m != null) {
      int depth = int.parse(d.group(1)!);
      int multiPv = int.parse(pv.group(1)!);
      final maxMultiPvAllowed = botSearchActive
          ? _botSearchMultiPv
          : (shouldShowVisualSuggestions ? _multiPvCount : 1);
      if (multiPv > maxMultiPvAllowed) {
        return;
      }
      final move = m.group(1)!;
      if (!_isLegalUciMove(move)) {
        return;
      }
      int cp;
      double normalizedEval;
      if (sCp != null) {
        cp = int.parse(sCp.group(1)!);
        normalizedEval = cp / 100.0;
      } else if (sMate != null) {
        final mateScore = int.parse(sMate.group(1)!);
        if (mateScore > 0) {
          cp = 10000;
          normalizedEval = 100.0;
        } else if (mateScore < 0) {
          cp = -10000;
          normalizedEval = -100.0;
        } else {
          cp = 0;
          normalizedEval = 0.0;
        }
      } else {
        cp = 0;
        normalizedEval = 0.0;
      }

      if (botSearchActive) {
        // Recovery guard: if bot search state leaked, unblock normal analysis.
        if (!_playVsBot || !_botThinking) {
          _botSearchCompleter = null;
        }
        if (multiPv <= _botSearchMultiPv) {
          _botSearchLines[multiPv] = EngineLine(move, cp, depth, multiPv);
        }
        if (_botSearchCompleter != null) {
          return;
        }
      }

      setState(() {
        if (_shouldKeepEvalActive) {
          _currentDepth = depth;
          if (multiPv == 1) {
            _currentEval = normalizedEval;
            _evalWhiteTurn = _isWhiteTurn;
          }
        }
        if (shouldShowVisualSuggestions) {
          _topLines.removeWhere(
            (e) => e.multiPv == multiPv || e.multiPv > _multiPvCount,
          );
          _topLines.add(EngineLine(move, cp, depth, multiPv));
          _topLines.sort((a, b) => a.multiPv.compareTo(b.multiPv));
        } else if (_topLines.isNotEmpty && multiPv == 1) {
          _topLines = [];
        }
      });
    }
  }

  List<EngineLine> _sortedBotSearchLines() {
    final lines = _botSearchLines.values.toList();
    lines.sort((a, b) => a.multiPv.compareTo(b.multiPv));
    return lines;
  }

  int _botSearchDepth(BotCharacter bot) {
    return bot.searchDepth ?? 8;
  }

  int _botRequestTimeoutMs(BotCharacter bot) {
    if (bot.moveTimeMs != null) {
      return bot.moveTimeMs! + 450;
    }
    return 2200;
  }

  Future<List<EngineLine>> _requestBotCandidates(BotCharacter bot) async {
    await _ensureEngineStarted();
    if (_engine == null) {
      return const <EngineLine>[];
    }

    _botSearchLines.clear();
    _botSearchMultiPv = bot.multiPv;

    final completer = Completer<List<EngineLine>>();
    _botSearchCompleter = completer;

    _send('stop');
    _send('setoption name UCI_LimitStrength value ${bot.limitStrength}');
    if (bot.limitStrength) {
      _send('setoption name UCI_Elo value ${bot.elo}');
    }
    if (bot.skillLevel != null) {
      _send('setoption name Skill Level value ${bot.skillLevel}');
    }
    _send('setoption name Threads value ${bot.threads}');
    _send('setoption name Contempt value ${bot.contempt ?? 0}');
    _send('setoption name MultiPV value ${bot.multiPv}');
    _send('position fen ${_genFen()}');
    if (bot.moveTimeMs != null) {
      _send('go movetime ${bot.moveTimeMs}');
    } else {
      _send('go depth ${_botSearchDepth(bot)}');
    }

    late final List<EngineLine> lines;
    try {
      lines = await completer.future.timeout(
        Duration(milliseconds: _botRequestTimeoutMs(bot)),
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

  EngineLine? _rankedCandidate(List<EngineLine> lines, int rank) {
    if (lines.isEmpty) return null;
    final idx = (rank - 1).clamp(0, lines.length - 1);
    return lines[idx];
  }

  bool _isCaptureMove(String uciMove) {
    if (uciMove.length < 4) return false;
    final to = uciMove.substring(2, 4);
    return boardState[to] != null;
  }

  String? _findKingSquare(Map<String, String> state, bool whiteKing) {
    final king = whiteKing ? 'k_w' : 'k_b';
    for (final entry in state.entries) {
      if (entry.value == king) {
        return entry.key;
      }
    }
    return null;
  }

  bool _isKingAttacked(Map<String, String> state, bool whiteKing) {
    final kingSquare = _findKingSquare(state, whiteKing);
    if (kingSquare == null) return false;
    return _isSquareAttacked(state, kingSquare, !whiteKing);
  }

  bool _isCheckingMove(String uciMove) {
    if (uciMove.length < 4) return false;
    final from = uciMove.substring(0, 2);
    final movingPiece = boardState[from];
    if (movingPiece == null) return false;
    final movingWhite = movingPiece.endsWith('_w');
    final nextState = _applyUciMove(boardState, uciMove);
    return _isKingAttacked(nextState, !movingWhite);
  }

  int _uncleComplexityScore(EngineLine line, int bestEval) {
    final evalGap = (bestEval - line.eval).abs();
    var score = 0;
    if (evalGap <= 40) score += 3;
    if (!_isCaptureMove(line.move)) score += 2;
    if (!_isCheckingMove(line.move)) score += 1;
    return score;
  }

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

  Future<void> _maybeTriggerBotMove() async {
    if (!_playVsBot || _selectedBot == null) return;
    if (_activeSection != AppSection.analysis) return;
    if (_isHumanTurnInBotGame || _botThinking) return;
    if (_gameOutcome != null) return;
    if (kIsWeb) return;

    setState(() {
      _botThinking = true;
    });

    try {
      final bot = _selectedBot!;
      final candidates = await _requestBotCandidates(bot);
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

  void _clearBotGhostArrows() {
    for (final timer in _botGhostArrowTimers.values) {
      timer.cancel();
    }
    _botGhostArrowTimers.clear();
    _botGhostArrows.clear();
  }

  void _loadEcoOpenings() async {
    final fileNames = [
      'openings/ecoA.json',
      'openings/ecoB.json',
      'openings/ecoC.json',
      'openings/ecoD.json',
      'openings/ecoE.json',
    ];

    _ecoLines.clear();
    _ecoOpenings.clear();
    _quizEligiblePoolCache.clear();
    _quizEligibleNameCache.clear();
    _quizPoolsPrecomputed = false;

    for (final path in fileNames) {
      try {
        final content = await rootBundle.loadString(path);
        final data = jsonDecode(content);
        if (data is Map<String, dynamic>) {
          data.forEach((_, entry) {
            if (entry is Map<String, dynamic>) {
              final movesRaw = entry['moves']?.toString() ?? '';
              final baseName = entry['name']?.toString() ?? '';
              final aliases = entry['aliases'];
              String aliasCt = '';
              String aliasScid = '';
              if (aliases is Map<String, dynamic>) {
                aliasCt = aliases['ct']?.toString() ?? '';
                aliasScid = aliases['scid']?.toString() ?? '';
              }

              final searchText = '$baseName $aliasCt $aliasScid'.toLowerCase();
              final displayName = aliasCt.isNotEmpty ? aliasCt : baseName;
              if (movesRaw.isEmpty || displayName.isEmpty) return;

              final normalizedMoves = _normalizeSan(movesRaw);
              if (normalizedMoves.isEmpty) return;

              final moveTokens = normalizedMoves
                  .split(' ')
                  .where((part) => part.isNotEmpty)
                  .toList();
              if (moveTokens.isEmpty) return;

              if (!_ecoOpenings.containsKey(normalizedMoves)) {
                _ecoOpenings[normalizedMoves] = displayName;
              }

              _ecoLines.add(
                EcoLine(
                  name: displayName,
                  normalizedMoves: normalizedMoves,
                  moveTokens: moveTokens,
                  isGambit: searchText.contains('gambit'),
                ),
              );
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading ECO file $path: $e');
      }
    }
    _addLog('Loaded ECO openings: ${_ecoOpenings.length} entries');

    _precomputeQuizEligiblePools();

    final eligible = _quizEligiblePool(
      mode: _quizMode,
      difficulty: _quizDifficulty,
    );
    if (mounted) {
      setState(() => _quizEligibleCount = eligible.length);
    }
    _addLog('Quiz-eligible openings: ${eligible.length}');
  }

  String _normalizeSan(String raw) {
    var cleaned = raw.toLowerCase().replaceAll('*', '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\d+\.'), '');
    cleaned = cleaned.replaceAll('...', '');
    cleaned = cleaned.replaceAll(RegExp(r'[^a-z0-9 x#+\-\/=]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  String _findOpeningFromHistory() {
    if (_moveHistory.isEmpty) return '';
    final moves = _moveHistory
        .map((m) => m.notation.toLowerCase())
        .join(' ')
        .trim();

    if (moves.isEmpty) return '';

    _addLog('Opening check: moves="$moves"');

    final parts = moves.split(' ').where((part) => part.isNotEmpty).toList();
    for (int len = parts.length; len >= 1; len--) {
      final candidate = parts.sublist(0, len).join(' ');
      final opening = _ecoOpenings[candidate];
      if (opening != null && opening.isNotEmpty) {
        _addLog('Found opening: "$opening" (len=$len)');
        return opening;
      }
    }

    _addLog('Found opening: "" (len=0)');
    return '';
  }

  void _updateCurrentOpening() {
    _currentOpening = _findOpeningFromHistory();
  }

  String _pieceNotationLetter(String piece) {
    switch (piece[0]) {
      case 't':
        return 'R';
      case 'n':
        return 'N';
      case 'b':
        return 'B';
      case 'q':
        return 'Q';
      case 'k':
        return 'K';
      default:
        return piece[0].toUpperCase();
    }
  }

  List<String> _moveSequenceTokens(String notation) {
    return notation
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  bool _isCurrentTurnPiece(String? piece) {
    if (piece == null) return false;
    return _isWhiteTurn ? piece.endsWith('_w') : piece.endsWith('_b');
  }

  bool get _isBlackPovActive {
    if (_playVsBot && _selectedBot != null) {
      return !_humanPlaysWhite;
    }
    return _perspective == BoardPerspective.black ||
        (_perspective == BoardPerspective.auto && !_isWhiteTurn);
  }

  double _displayEvalForPov() {
    if (_gameOutcome == GameOutcome.draw) {
      return 0.0;
    }
    if (_gameOutcome == GameOutcome.whiteWin) {
      return _isBlackPovActive ? -99.0 : 99.0;
    }
    if (_gameOutcome == GameOutcome.blackWin) {
      return _isBlackPovActive ? 99.0 : -99.0;
    }

    // In bot games the gauge stays anchored to the human player's side.
    // In analysis it follows the active viewing perspective.
    final whiteEval = _evalWhiteTurn ? _currentEval : -_currentEval;
    return _isBlackPovActive ? -whiteEval : whiteEval;
  }

  bool get _isWinningOutcomeForPov {
    return _gameOutcome == GameOutcome.whiteWin && !_isBlackPovActive ||
        _gameOutcome == GameOutcome.blackWin && _isBlackPovActive;
  }

  bool get _isLosingOutcomeForPov {
    return _gameOutcome == GameOutcome.whiteWin && _isBlackPovActive ||
        _gameOutcome == GameOutcome.blackWin && !_isBlackPovActive;
  }

  String _evalTextForUi(double displayedEval) {
    if (_gameOutcome == GameOutcome.draw) {
      return '=';
    }
    if (_isWinningOutcomeForPov) {
      return '+∞';
    }
    if (_isLosingOutcomeForPov) {
      return '-∞';
    }
    return '${displayedEval > 0 ? '+' : ''}${displayedEval.toStringAsFixed(2)}';
  }

  Color _evalColorForUi(double displayedEval) {
    if (_isWinningOutcomeForPov) {
      return const Color(0xFF2ECC71);
    }
    if (_isLosingOutcomeForPov) {
      return const Color(0xFFE45C5C);
    }
    if (_gameOutcome == GameOutcome.draw) {
      return const Color(0xFFD8B640);
    }
    return _displayEvalColor(displayedEval);
  }

  double _evalFillForUi(double displayedEval) {
    if (_isWinningOutcomeForPov) return 1.0;
    if (_isLosingOutcomeForPov) return 0.0;
    if (_gameOutcome == GameOutcome.draw) return 0.5;
    return (0.5 + displayedEval / 8).clamp(0.0, 1.0);
  }

  bool _sideToMoveHasLegalMoves() {
    for (final entry in boardState.entries) {
      final piece = entry.value;
      final isTurnPiece = _isWhiteTurn
          ? piece.endsWith('_w')
          : piece.endsWith('_b');
      if (!isTurnPiece) continue;
      if (_legalMovesFrom(entry.key).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  GameOutcome? _detectCurrentGameOutcome() {
    final whiteKingPresent = boardState.values.contains('k_w');
    final blackKingPresent = boardState.values.contains('k_b');
    if (!whiteKingPresent && !blackKingPresent) {
      return GameOutcome.draw;
    }
    if (!whiteKingPresent) {
      return GameOutcome.blackWin;
    }
    if (!blackKingPresent) {
      return GameOutcome.whiteWin;
    }

    if (_sideToMoveHasLegalMoves()) {
      return null;
    }
    if (_isKingAttacked(boardState, _isWhiteTurn)) {
      return _isWhiteTurn ? GameOutcome.blackWin : GameOutcome.whiteWin;
    }
    return GameOutcome.draw;
  }

  Color _displayEvalColor(double eval) {
    final clamped = eval.clamp(-2.0, 2.0);
    const deepYellow = Color(0xFFD8B640);
    const deepLime = Color(0xFF8CBF3F);
    const deepGreen = Color(0xFF33A85C);
    const deepEmerald = Color(0xFF13935A);
    const deepOrange = Color(0xFFC96F3D);
    const deepRed = Color(0xFFB44747);

    // Keep true yellow in the neutral window, then transition smoothly outward.
    if (clamped >= -0.20 && clamped <= 0.20) {
      return deepYellow;
    }

    if (clamped > 0.20 && clamped <= 0.35) {
      final t = ((clamped - 0.20) / 0.15).clamp(0.0, 1.0);
      return Color.lerp(deepYellow, deepLime, t) ?? deepLime;
    }

    if (clamped > 0.35 && clamped <= 1.0) {
      final t = ((clamped - 0.35) / 0.65).clamp(0.0, 1.0);
      return Color.lerp(deepLime, deepGreen, t) ?? deepGreen;
    }

    if (clamped > 1.0) {
      final t = ((clamped - 1.0) / 1.0).clamp(0.0, 1.0);
      return Color.lerp(deepGreen, deepEmerald, t) ?? deepEmerald;
    }

    if (clamped < -0.20 && clamped >= -0.80) {
      final t = ((clamped + 0.80) / 0.60).clamp(0.0, 1.0);
      return Color.lerp(deepOrange, deepYellow, t) ?? deepYellow;
    }

    final t = ((clamped + 2.0) / 1.20).clamp(0.0, 1.0);
    return Color.lerp(deepRed, deepOrange, t) ?? deepRed;
  }

  String _currentMoveSequence() =>
      _moveHistory.map((move) => move.notation.toLowerCase()).join(' ').trim();

  bool get _isOpeningSelectionMode =>
      _openingMode == OpeningMode.yellowGlow ||
      _openingMode == OpeningMode.violetGlow;

  bool get _isGambitsOnlyOpeningMode => _openingMode == OpeningMode.violetGlow;

  Color get _openingSelectionAccent => _isGambitsOnlyOpeningMode
      ? const Color(0xFFB16CFF)
      : const Color(0xFFFFD166);

  void _toggleGambitMode() {
    setState(() {
      // Cycle: off -> yellow -> blue -> violet -> yellow
      if (_openingMode == OpeningMode.off) {
        // First press: enter yellow selection mode.
        _openingMode = OpeningMode.yellowGlow;
        _selectedGambit = null;
        _gambitPreviewLines = [];
        _gambitSelectedFrom = null;
        _legalTargets.clear();
        _gambitAvailableTargets.clear();
        final selected = _holdSelectedFrom;
        if (selected != null && _isCurrentTurnPiece(boardState[selected])) {
          _selectGambitSource(selected);
        }
        _addLog('Opening mode enabled - yellow glow');
      } else if (_openingMode == OpeningMode.yellowGlow) {
        // Second press: show all available openings list.
        _openingMode = OpeningMode.blueGlow;
        _addLog('Opening mode - blue glow - showing all possible openings');
        _showAllPossibleOpenings();
      } else if (_openingMode == OpeningMode.blueGlow) {
        // Third press: switch to gambits-only selection mode.
        _openingMode = OpeningMode.violetGlow;
        _selectedGambit = null;
        _gambitPreviewLines = [];
        _gambitSelectedFrom = null;
        _legalTargets.clear();
        _gambitAvailableTargets.clear();
        final selected = _holdSelectedFrom;
        if (selected != null && _isCurrentTurnPiece(boardState[selected])) {
          _selectGambitSource(selected);
        }
        _addLog('Opening mode enabled - violet gambits only');
      } else {
        // Fourth press: back to yellow selection mode.
        _openingMode = OpeningMode.yellowGlow;
        _gambitSelectedFrom = null;
        _legalTargets.clear();
        _gambitAvailableTargets.clear();
        _selectedGambit = null;
        _gambitPreviewLines = [];
        _addLog('Opening mode back to yellow');
      }
    });
  }

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

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
            ? Icons.emoji_events_rounded
            : Icons.flag_rounded;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
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
                  child: Icon(icon, color: accent, size: 34),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Session',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        'W $_vsBotSessionWins · L $_vsBotSessionLosses · D $_vsBotSessionDraws',
                        style: TextStyle(
                          color: accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop('restart'),
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
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
        );
      },
    );

    _gameResultDialogVisible = false;
    if (!mounted) return;

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

  void _showAllPossibleOpenings() {
    // Find all openings that could be played from the current position
    final currentMoves = _currentMoveSequence();
    final allOpenings = <String, EcoLine>{};

    // Find all openings that start with the current move sequence
    for (final line in _ecoLines) {
      final normalizedMoves = line.normalizedMoves.trim().toLowerCase();
      final currentMovesLower = currentMoves.isEmpty ? '' : '$currentMoves ';

      // Check if this line starts with current moves followed by more
      if (currentMoves.isEmpty) {
        // At starting position - show all openings
        allOpenings.putIfAbsent(line.name, () => line);
      } else if (normalizedMoves.startsWith(currentMovesLower.trim()) &&
          normalizedMoves.length > currentMovesLower.trim().length) {
        // Opening that continues from current position
        allOpenings.putIfAbsent(line.name, () => line);
      }
    }

    // Sort by name and move length
    final openingsList = allOpenings.values.toList();
    openingsList.sort((a, b) {
      final cmp = a.name.compareTo(b.name);
      if (cmp != 0) return cmp;
      return a.moveTokens.length.compareTo(b.moveTokens.length);
    });

    if (openingsList.isEmpty) {
      // Flash the button red then reset to off
      setState(() {
        _openingButtonFlashRed = true;
      });
      _openingButtonFlashController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _openingButtonFlashRed = false;
            _openingMode = OpeningMode.off;
          });
        }
      });
      return;
    }

    _addLog('Found ${openingsList.length} possible openings');

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E0F17),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5AAEE8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF5AAEE8).withValues(alpha: 0.30),
                      ),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: Color(0xFF5AAEE8),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Possible Openings',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${openingsList.length} lines available',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: openingsList.length,
                  itemBuilder: (context, index) {
                    final opening = openingsList[index];
                    final moveCount = opening.moveTokens.length;
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        _activateGambit(opening);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141622),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(
                              color: const Color(
                                0xFF5AAEE8,
                              ).withValues(alpha: 0.55),
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opening.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  _buildMoveSequenceText(
                                    opening.normalizedMoves,
                                    fontSize: 11.5,
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontWeight: FontWeight.w500,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF5AAEE8,
                                ).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(
                                    0xFF5AAEE8,
                                  ).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                '$moveCount ply',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF5AAEE8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
        ),
      ),
    );
  }

  void _handleBoardTap(String square) {
    if (_playVsBot && !_isHumanTurnInBotGame) return;
    if (!_isOpeningSelectionMode) return;

    final piece = boardState[square];
    if (_gambitSelectedFrom == null) {
      if (_isCurrentTurnPiece(piece)) {
        setState(() {
          _selectGambitSource(square);
        });
        _addLog('Gambit source selected: $square');
      }
      return;
    }

    if (_gambitSelectedFrom == square) {
      setState(() {
        _gambitSelectedFrom = null;
        _legalTargets.clear();
        _gambitAvailableTargets.clear();
      });
      _addLog('Gambit source cleared');
      return;
    }

    if (_isCurrentTurnPiece(piece)) {
      setState(() {
        _selectGambitSource(square);
      });
      _addLog('Gambit source changed: $square');
      return;
    }

    if (!_legalTargets.contains(square)) {
      return;
    }

    final from = _gambitSelectedFrom!;
    _showGambitsForMove(from, square);
  }

  void _selectGambitSource(String square) {
    _gambitSelectedFrom = square;
    _holdSelectedFrom = null;
    _legalTargets
      ..clear()
      ..addAll(_legalMovesFrom(square));
    _gambitAvailableTargets
      ..clear()
      ..addAll(_targetsWithRegisteredGambits(square, _legalTargets));
  }

  Set<String> _targetsWithRegisteredGambits(String from, Set<String> targets) {
    final sourcePiece = boardState[from];
    if (sourcePiece == null) {
      return <String>{};
    }

    final available = <String>{};
    for (final to in targets) {
      final notation = _buildMoveNotation(
        from,
        to,
        sourcePiece,
        boardState[to],
        null,
      );
      if (_findGambitsForCandidateMove(
        notation,
        gambitsOnly: _isGambitsOnlyOpeningMode,
      ).isNotEmpty) {
        available.add(to);
      }
    }
    return available;
  }

  void _showGambitsForMove(String from, String to) {
    final sourcePiece = boardState[from];
    if (sourcePiece == null) {
      setState(() {
        _gambitSelectedFrom = null;
        _legalTargets.clear();
        _gambitAvailableTargets.clear();
      });
      return;
    }

    final notation = _buildMoveNotation(
      from,
      to,
      sourcePiece,
      boardState[to],
      null,
    );
    final gambits = _findGambitsForCandidateMove(
      notation,
      gambitsOnly: _isGambitsOnlyOpeningMode,
    );
    _addLog('Gambit lookup for move "$notation": ${gambits.length} matches');

    if (gambits.isEmpty) {
      if (mounted) {
        unawaited(
          _showThemedErrorDialog(
            title: _isGambitsOnlyOpeningMode
                ? 'No Gambits Found'
                : 'No Openings Found',
            message: _isGambitsOnlyOpeningMode
                ? 'No gambits are available for this move.'
                : 'No openings are available for this move.',
          ),
        );
      }
      setState(() {
        _gambitSelectedFrom = null;
        _legalTargets.clear();
        _gambitAvailableTargets.clear();
      });
      return;
    }

    _showGambitChooser(
      gambits,
      notation,
      gambitsOnly: _isGambitsOnlyOpeningMode,
    );
  }

  void _handleGambitDragDrop(String from, String to) {
    if (_playVsBot && !_isHumanTurnInBotGame) return;
    if (!_isOpeningSelectionMode || from == to) return;

    final sourcePiece = boardState[from];
    if (!_isCurrentTurnPiece(sourcePiece)) return;

    final legalTargets = _legalMovesFrom(from);
    if (!legalTargets.contains(to)) return;

    _showGambitsForMove(from, to);
  }

  String _buildMoveNotation(
    String from,
    String to,
    String piece,
    String? captured,
    String? promotion,
  ) {
    if (piece[0] == 'k' && from == 'e1' && to == 'g1' ||
        piece[0] == 'k' && from == 'e8' && to == 'g8') {
      return 'O-O';
    }
    if (piece[0] == 'k' && from == 'e1' && to == 'c1' ||
        piece[0] == 'k' && from == 'e8' && to == 'c8') {
      return 'O-O-O';
    }

    if (piece.startsWith('p')) {
      final base = captured != null ? '${from[0]}x$to' : to;
      if (promotion != null) {
        return '$base=${promotion.toUpperCase()}';
      }
      return base;
    }
    final pieceLetter = _pieceNotationLetter(piece);
    final base = '$pieceLetter${captured != null ? 'x' : ''}$to';
    if (promotion != null) {
      return '$base=${promotion.toUpperCase()}';
    }
    return base;
  }

  Future<String?> _showPromotionPicker(bool whitePiece) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0E0F17),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final options = <String>['q', 't', 'b', 'n'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Promotion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final option in options)
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(option),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFF161A24),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Center(
                            child: _pieceImage(
                              '${option}_${whitePiece ? 'w' : 'b'}',
                              width: 34,
                              height: 34,
                            ),
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

  Future<void> _attemptMove(
    String from,
    String to, {
    String? forcedPromotion,
  }) async {
    if (_gameOutcome != null) return;
    final piece = boardState[from];
    if (piece == null) return;
    if (!_analysisEditMode && !_legalMovesFrom(from).contains(to)) return;

    var promotion = forcedPromotion;
    if (_isPromotionTarget(from, to, piece)) {
      promotion ??= await _showPromotionPicker(piece.endsWith('_w'));
      if (promotion == null) return;
      if (promotion == 'r') {
        promotion = 't';
      }
    }

    if (_analysisEditMode) {
      final uciPromotion = promotion == null
          ? null
          : (promotion == 't' ? 'r' : promotion.toLowerCase());
      final uciMove = uciPromotion == null
          ? '$from$to'
          : '$from$to$uciPromotion';
      final nextState = _applyUciMove(
        boardState,
        uciMove,
        enPassantTarget: _enPassantTarget,
      );
      final movingSideIsWhite = _isWhiteTurn;
      if (_isKingAttacked(nextState, movingSideIsWhite)) {
        _addLog(
          'Illegal move blocked: ${movingSideIsWhite ? 'White' : 'Black'} king would remain in check.',
        );
        return;
      }
    }

    _onMove(from, to, promotion: promotion);
  }

  List<EcoLine> _findGambitsForCandidateMove(
    String notation, {
    bool gambitsOnly = false,
  }) {
    final currentMoves = _currentMoveSequence();
    final prefix = currentMoves.isEmpty
        ? notation.toLowerCase()
        : '$currentMoves ${notation.toLowerCase()}';
    final results = _ecoLines.where((line) {
      if (gambitsOnly && !line.isGambit) {
        return false;
      }
      return line.normalizedMoves == prefix ||
          line.normalizedMoves.startsWith('$prefix ');
    }).toList();
    results.sort((a, b) => a.moveTokens.length.compareTo(b.moveTokens.length));

    final unique = <String, EcoLine>{};
    for (final line in results) {
      unique.putIfAbsent(line.name, () => line);
    }
    return unique.values.toList();
  }

  void _showGambitChooser(
    List<EcoLine> gambits,
    String notation, {
    required bool gambitsOnly,
  }) {
    final accentColor = gambitsOnly
        ? const Color(0xFFB16CFF)
        : const Color(0xFFFFD700);
    final title = gambitsOnly ? 'Select Gambit' : 'Select Opening';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E0F17),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: accentColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$notation  ·  ${gambits.length} line${gambits.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: gambits.length,
                  itemBuilder: (context, index) {
                    final gambit = gambits[index];
                    final moveCount = gambit.moveTokens.length;
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        _activateGambit(gambit);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141622),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(
                              color: accentColor.withValues(alpha: 0.55),
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gambit.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  _buildMoveSequenceText(
                                    gambit.normalizedMoves,
                                    fontSize: 11.5,
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontWeight: FontWeight.w500,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                '$moveCount ply',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
        ),
      ),
    );
  }

  void _activateGambit(EcoLine gambit) {
    final preview = _buildGambitPreviewLines(gambit);
    _markGambitViewed(gambit.name);
    setState(() {
      _selectedGambit = gambit;
      _gambitPreviewLines = preview;
      _gambitSelectedFrom = null;
      _holdSelectedFrom = null;
      _legalTargets.clear();
      _gambitAvailableTargets.clear();
    });
    _addLog(
      'Selected opening: ${gambit.name} (${preview.length} preview arrows)',
    );
  }

  Map<String, String> _initialBoardState() {
    return {
      'a8': 't_b',
      'b8': 'n_b',
      'c8': 'b_b',
      'd8': 'q_b',
      'e8': 'k_b',
      'f8': 'b_b',
      'g8': 'n_b',
      'h8': 't_b',
      'a7': 'p_b',
      'b7': 'p_b',
      'c7': 'p_b',
      'd7': 'p_b',
      'e7': 'p_b',
      'f7': 'p_b',
      'g7': 'p_b',
      'h7': 'p_b',
      'a2': 'p_w',
      'b2': 'p_w',
      'c2': 'p_w',
      'd2': 'p_w',
      'e2': 'p_w',
      'f2': 'p_w',
      'g2': 'p_w',
      'h2': 'p_w',
      'a1': 't_w',
      'b1': 'n_w',
      'c1': 'b_w',
      'd1': 'q_w',
      'e1': 'k_w',
      'f1': 'b_w',
      'g1': 'n_w',
      'h1': 't_w',
    };
  }

  void _resetSpecialMoveState() {
    _whiteKingMoved = false;
    _blackKingMoved = false;
    _whiteKingsideRookMoved = false;
    _whiteQueensideRookMoved = false;
    _blackKingsideRookMoved = false;
    _blackQueensideRookMoved = false;
    _enPassantTarget = null;
  }

  void _restoreSpecialMoveStateFromRecord(MoveRecord? move) {
    if (move == null) {
      _resetSpecialMoveState();
      return;
    }
    _whiteKingMoved = move.whiteKingMoved;
    _blackKingMoved = move.blackKingMoved;
    _whiteKingsideRookMoved = move.whiteKingsideRookMoved;
    _whiteQueensideRookMoved = move.whiteQueensideRookMoved;
    _blackKingsideRookMoved = move.blackKingsideRookMoved;
    _blackQueensideRookMoved = move.blackQueensideRookMoved;
    _enPassantTarget = move.enPassantTarget;
  }

  void _openPuzzleAcademyFromMenu() {
    setState(() {
      _playVsBot = false;
      _selectedBot = null;
      _botThinking = false;
      _vsBotSessionWins = 0;
      _vsBotSessionLosses = 0;
      _vsBotSessionDraws = 0;
      _gameOutcome = null;
      _activeSection = AppSection.puzzleAcademy;
    });
  }

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

  void _animateBotSetupTo(int index) {
    final clamped = max(0, min(index, _botCharacters.length - 1));
    if (_botSetupSelectedIndex != clamped) {
      setState(() => _botSetupSelectedIndex = clamped);
    }
    if (_botSetupPageController.hasClients) {
      _botSetupPageController.animateToPage(
        clamped,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

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

    return AnimatedBuilder(
      animation: _botSetupPageController,
      child: GestureDetector(
        onTap: () {
          setState(() => _botSetupSelectedIndex = index);
          unawaited(_startBotMatch(bot: bot, sideChoice: _botSideChoice));
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 6 : 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: compact ? 96 : 144,
                  height: compact ? 96 : 144,
                  color: Color.alphaBlend(
                    scheme.primary.withValues(alpha: isDark ? 0.16 : 0.05),
                    scheme.surface,
                  ),
                  child: bot.avatarAsset != null
                      ? Image.asset(bot.avatarAsset!, fit: BoxFit.cover)
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
              ),
              SizedBox(height: compact ? 8 : 12),
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

  Future<void> _startBotMatch({
    required BotCharacter bot,
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
      final switchedOpponent = _selectedBot?.name != bot.name;

      setState(() {
        _activeSection = AppSection.analysis;
        _playVsBot = true;
        _selectedBot = bot;
        if (switchedOpponent) {
          _vsBotSessionWins = 0;
          _vsBotSessionLosses = 0;
          _vsBotSessionDraws = 0;
        }
        _humanPlaysWhite = humanPlaysWhite;
        _botThinking = false;
        _analysisEditMode = false;
      });

      await _ensureEngineStarted();
      _resetBoard(initialLaunch: false, withIntro: false);

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

  Future<void> _enterAnalysisBoard() async {
    if (_activeSection == AppSection.analysis) return;
    try {
      // Coordinate menu exit animation with music fade.
      _menuExitAnimationController.reset();

      // Run menu exit animation and stop music in parallel.
      final transition = _menuExitAnimationController.forward();
      unawaited(_stopMenuMusic(fadeOut: true));

      // After menu exits, switch to analysis.
      await transition;
      if (!mounted) return;
      setState(() {
        _activeSection = AppSection.analysis;
        _playVsBot = false;
        _selectedBot = null;
        _botThinking = false;
        _vsBotSessionWins = 0;
        _vsBotSessionLosses = 0;
        _vsBotSessionDraws = 0;
      });
      await _restoreAnalysisWorkspace();
      unawaited(_ensureEngineStarted());
      _analyze();
    } catch (e) {
      _addLog('Enter analysis failed: $e');
      debugPrint('Enter analysis failed: $e');
    }
  }

  void _goToMenu() {
    if (_activeSection == AppSection.gambitQuiz) {
      setState(() {
        _playVsBot = false;
        _selectedBot = null;
        _botThinking = false;
        _vsBotSessionWins = 0;
        _vsBotSessionLosses = 0;
        _vsBotSessionDraws = 0;
        _gameOutcome = null;
        _resetQuizToSetupState();
        _activeSection = AppSection.menu;
      });
      unawaited(_playMenuMusic());
      return;
    }

    if (_activeSection == AppSection.botSetup) {
      setState(() {
        _playVsBot = false;
        _selectedBot = null;
        _botThinking = false;
        _vsBotSessionWins = 0;
        _vsBotSessionLosses = 0;
        _vsBotSessionDraws = 0;
        _gameOutcome = null;
        _clearBotGhostArrows();
        _activeSection = AppSection.menu;
      });
      return;
    }

    if (_activeSection == AppSection.puzzleAcademy) {
      setState(() {
        _playVsBot = false;
        _selectedBot = null;
        _botThinking = false;
        _vsBotSessionWins = 0;
        _vsBotSessionLosses = 0;
        _vsBotSessionDraws = 0;
        _gameOutcome = null;
        _activeSection = AppSection.menu;
      });
      return;
    }

    final wasBotGame = _playVsBot;
    if (wasBotGame) {
      _send('stop');
    } else {
      _persistAnalysisSnapshotIfNeeded();
    }
    unawaited(_releaseEngineSession());

    _menuExitAnimationController.reset();
    _sectionTransitionController.reset();
    _sectionTransitionController.forward().then((_) {
      setState(() {
        if (wasBotGame) {
          _suggestionsEnabled = false;
          _topLines = [];
          _currentDepth = 0;
          _botSearchCompleter = null;
          _botSearchLines.clear();
          _clearBotGhostArrows();
        }
        _playVsBot = false;
        _selectedBot = null;
        _botThinking = false;
        _vsBotSessionWins = 0;
        _vsBotSessionLosses = 0;
        _vsBotSessionDraws = 0;
        _gameOutcome = null;
        _activeSection = AppSection.menu;
      });
      unawaited(_playMenuMusic());
    });
  }

  Future<void> _resetFromHotkey() async {
    if (_isHotkeyResetting) return;
    _isHotkeyResetting = true;
    try {
      await _stopMenuMusic(fadeOut: false);
      await _introAudioPlayer.stop();
      _send('stop');
      await _releaseEngineSession();

      if (!mounted) return;
      setState(() {
        _activeSection = AppSection.menu;
        _playVsBot = false;
        _selectedBot = null;
        _botThinking = false;
        _vsBotSessionWins = 0;
        _vsBotSessionLosses = 0;
        _vsBotSessionDraws = 0;
        _menuReady = true;
        _introCompleted = true;
        _buttonUnlocked = true;
        _menuMusicPlaying = false;
      });

      _menuExitAnimationController.reset();
      _sectionTransitionController.value = 1.0;
      _menuRevealController.value = 1.0;
      _introController.value = 1.0;

      _resetBoard(withIntro: false);
      unawaited(_restoreSnapshotAndStart());
    } catch (e) {
      _addLog('F5 reset failed: $e');
      debugPrint('F5 reset failed: $e');
    } finally {
      _isHotkeyResetting = false;
    }
  }

  Widget _buildMenuExitTransition() {
    return AnimatedBuilder(
      animation: _menuExitAnimationController,
      builder: (context, child) {
        // Use easeOutCubic for smooth, elegant deceleration
        final exitProgress = Curves.easeOutCubic.transform(
          _menuExitAnimationController.value,
        );
        final scale = 1.0 - (exitProgress * 0.25);
        final offsetY = exitProgress * 120;
        final opacity = 1.0 - exitProgress;
        final blur = exitProgress * 8.0; // Add blur for elegance

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.scale(
            scale: scale,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Opacity(
                opacity: opacity,
                child: _activeSection == AppSection.menu
                    ? _buildStartMenu()
                    : _activeSection == AppSection.botSetup
                    ? _buildBotSetupScreen()
                    : _activeSection == AppSection.puzzleAcademy
                    ? PuzzleMapScreen(
                        onBack: _goToMenu,
                        cinematicThemeEnabled: _isCinematicThemeEnabled,
                        onShowCredits: _showCreditsDialog,
                        onOpenMainStore: () =>
                            _openStore(initialSection: StoreSection.general),
                      )
                    : _buildGambitQuizScreen(),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isPromotionTarget(String from, String to, String piece) {
    if (piece[0] != 'p') return false;
    final toRank = int.parse(to[1]);
    return (piece.endsWith('_w') && toRank == 8) ||
        (piece.endsWith('_b') && toRank == 1);
  }

  String _uciMoveForCandidate(String from, String to, String piece) {
    if (_isPromotionTarget(from, to, piece)) {
      return '$from${to}q';
    }
    return '$from$to';
  }

  String? _enPassantCaptureSquare(
    Map<String, String> state,
    String from,
    String to,
    String piece, {
    String? enPassantTarget,
  }) {
    if (piece[0] != 'p' || enPassantTarget != to || state[to] != null) {
      return null;
    }
    final fromFile = from.codeUnitAt(0) - 97;
    final toFile = to.codeUnitAt(0) - 97;
    final fromRank = int.parse(from[1]);
    final toRank = int.parse(to[1]);
    final forward = piece.endsWith('_w') ? 1 : -1;
    if ((toFile - fromFile).abs() != 1 || toRank - fromRank != forward) {
      return null;
    }
    final captureSquare = '${to[0]}${from[1]}';
    final captured = state[captureSquare];
    if (captured == null ||
        captured[0] != 'p' ||
        captured.endsWith(piece.endsWith('_w') ? '_w' : '_b')) {
      return null;
    }
    return captureSquare;
  }

  bool _pieceAttacksSquare(
    Map<String, String> state,
    String from,
    String to,
    String piece,
  ) {
    final fromFile = from.codeUnitAt(0) - 97;
    final fromRank = int.parse(from[1]);
    final toFile = to.codeUnitAt(0) - 97;
    final toRank = int.parse(to[1]);
    final deltaFile = toFile - fromFile;
    final deltaRank = toRank - fromRank;
    final absFile = deltaFile.abs();
    final absRank = deltaRank.abs();
    final whitePiece = piece.endsWith('_w');

    switch (piece[0]) {
      case 'p':
        final forward = whitePiece ? 1 : -1;
        return absFile == 1 && deltaRank == forward;
      case 'n':
        return absFile == 1 && absRank == 2 || absFile == 2 && absRank == 1;
      case 'b':
        return absFile == absRank && _isPathClear(state, from, to);
      case 't':
        return (deltaFile == 0 || deltaRank == 0) &&
            _isPathClear(state, from, to);
      case 'q':
        return ((absFile == absRank) || deltaFile == 0 || deltaRank == 0) &&
            _isPathClear(state, from, to);
      case 'k':
        return absFile <= 1 && absRank <= 1;
      default:
        return false;
    }
  }

  bool _isSquareAttacked(
    Map<String, String> state,
    String square,
    bool byWhite,
  ) {
    for (final entry in state.entries) {
      final piece = entry.value;
      if (piece.endsWith('_w') != byWhite) continue;
      if (_pieceAttacksSquare(state, entry.key, square, piece)) {
        return true;
      }
    }
    return false;
  }

  bool _canCastleKingside(bool whiteKing) {
    final kingSquare = whiteKing ? 'e1' : 'e8';
    final rookSquare = whiteKing ? 'h1' : 'h8';
    final throughSquare = whiteKing ? 'f1' : 'f8';
    final targetSquare = whiteKing ? 'g1' : 'g8';
    final kingPiece = whiteKing ? 'k_w' : 'k_b';
    final rookPiece = whiteKing ? 't_w' : 't_b';
    final rookMoved = whiteKing
        ? _whiteKingsideRookMoved
        : _blackKingsideRookMoved;
    final kingMoved = whiteKing ? _whiteKingMoved : _blackKingMoved;

    if (kingMoved || rookMoved) return false;
    if (boardState[kingSquare] != kingPiece ||
        boardState[rookSquare] != rookPiece) {
      return false;
    }
    if (boardState[throughSquare] != null || boardState[targetSquare] != null) {
      return false;
    }
    if (_isSquareAttacked(boardState, kingSquare, !whiteKing) ||
        _isSquareAttacked(boardState, throughSquare, !whiteKing) ||
        _isSquareAttacked(boardState, targetSquare, !whiteKing)) {
      return false;
    }
    return true;
  }

  bool _canCastleQueenside(bool whiteKing) {
    final kingSquare = whiteKing ? 'e1' : 'e8';
    final rookSquare = whiteKing ? 'a1' : 'a8';
    final throughSquare = whiteKing ? 'd1' : 'd8';
    final targetSquare = whiteKing ? 'c1' : 'c8';
    final betweenSquare = whiteKing ? 'b1' : 'b8';
    final kingPiece = whiteKing ? 'k_w' : 'k_b';
    final rookPiece = whiteKing ? 't_w' : 't_b';
    final rookMoved = whiteKing
        ? _whiteQueensideRookMoved
        : _blackQueensideRookMoved;
    final kingMoved = whiteKing ? _whiteKingMoved : _blackKingMoved;

    if (kingMoved || rookMoved) return false;
    if (boardState[kingSquare] != kingPiece ||
        boardState[rookSquare] != rookPiece) {
      return false;
    }
    if (boardState[throughSquare] != null ||
        boardState[targetSquare] != null ||
        boardState[betweenSquare] != null) {
      return false;
    }
    if (_isSquareAttacked(boardState, kingSquare, !whiteKing) ||
        _isSquareAttacked(boardState, throughSquare, !whiteKing) ||
        _isSquareAttacked(boardState, targetSquare, !whiteKing)) {
      return false;
    }
    return true;
  }

  Set<String> _legalMovesFrom(String from) {
    final piece = boardState[from];
    if (piece == null || !_isCurrentTurnPiece(piece)) {
      return <String>{};
    }

    final moves = <String>{};
    for (int file = 0; file < 8; file++) {
      for (int rank = 1; rank <= 8; rank++) {
        final to = '${String.fromCharCode(97 + file)}$rank';
        if (to == from) continue;
        final isCapture = boardState[to] != null;
        if (_canReachSquare(boardState, from, to, piece, isCapture)) {
          moves.add(to);
        }
      }
    }

    if (piece[0] == 'k') {
      if (piece.endsWith('_w')) {
        if (_canCastleKingside(true)) moves.add('g1');
        if (_canCastleQueenside(true)) moves.add('c1');
      } else {
        if (_canCastleKingside(false)) moves.add('g8');
        if (_canCastleQueenside(false)) moves.add('c8');
      }
    }

    final enPassantTarget = _enPassantTarget;
    if (piece[0] == 'p' && enPassantTarget != null) {
      if (_enPassantCaptureSquare(
            boardState,
            from,
            enPassantTarget,
            piece,
            enPassantTarget: enPassantTarget,
          ) !=
          null) {
        moves.add(enPassantTarget);
      }
    }

    final legalMoves = <String>{};
    final movingWhite = piece.endsWith('_w');
    for (final to in moves) {
      final uciMove = _uciMoveForCandidate(from, to, piece);
      final nextState = _applyUciMove(
        boardState,
        uciMove,
        enPassantTarget: _enPassantTarget,
      );
      if (!_isKingAttacked(nextState, movingWhite)) {
        legalMoves.add(to);
      }
    }
    return legalMoves;
  }

  void _handleHoldTap(String square) {
    if (_playVsBot && !_isHumanTurnInBotGame) return;
    if (_analysisEditMode && !_isOpeningSelectionMode) {
      final tappedPiece = boardState[square];
      if (_holdSelectedFrom == null) {
        if (tappedPiece != null) {
          setState(() {
            _holdSelectedFrom = square;
            _gambitSelectedFrom = null;
            _legalTargets.clear();
            _gambitAvailableTargets.clear();
          });
        }
        return;
      }

      if (_holdSelectedFrom == square) {
        setState(() {
          _holdSelectedFrom = null;
          _legalTargets.clear();
          _gambitAvailableTargets.clear();
        });
        return;
      }

      if (tappedPiece != null) {
        setState(() {
          _holdSelectedFrom = square;
          _legalTargets.clear();
        });
        return;
      }

      if (boardState[square] == null) {
        final from = _holdSelectedFrom!;
        unawaited(_attemptMove(from, square));
      }
      return;
    }
    if (_openingMode != OpeningMode.off &&
        !(_isOpeningSelectionMode && _selectedGambit != null)) {
      return;
    }

    final tappedPiece = boardState[square];
    if (_holdSelectedFrom == null) {
      if (_isCurrentTurnPiece(tappedPiece)) {
        setState(() {
          _holdSelectedFrom = square;
          _gambitSelectedFrom = null;
          _legalTargets
            ..clear()
            ..addAll(_legalMovesFrom(square));
        });
      }
      return;
    }

    if (_holdSelectedFrom == square) {
      setState(() {
        _holdSelectedFrom = null;
        _legalTargets.clear();
        _gambitAvailableTargets.clear();
      });
      return;
    }

    if (_isCurrentTurnPiece(tappedPiece)) {
      setState(() {
        _holdSelectedFrom = square;
        _legalTargets
          ..clear()
          ..addAll(_legalMovesFrom(square));
      });
      return;
    }

    if (_legalTargets.contains(square)) {
      final from = _holdSelectedFrom!;
      unawaited(_attemptMove(from, square));
      return;
    }

    setState(() {
      _holdSelectedFrom = null;
      _legalTargets.clear();
      _gambitAvailableTargets.clear();
    });
  }

  void _refreshGambitPreview() {
    if (_selectedGambit == null) return;
    final preview = _buildGambitPreviewLines(_selectedGambit!);
    _gambitPreviewLines = preview;
    if (preview.isEmpty && _selectedGambit != null) {
      _addLog(
        'Clearing gambit preview: no remaining moves from current position',
      );
      _selectedGambit = null;
    }
  }

  List<EngineLine> _buildGambitPreviewLines(EcoLine gambit) {
    final currentMoves = _currentMoveSequence();
    final currentTokens = currentMoves.isEmpty
        ? <String>[]
        : currentMoves.split(' ');
    if (currentTokens.length > gambit.moveTokens.length) return [];

    for (int index = 0; index < currentTokens.length; index++) {
      if (gambit.moveTokens[index] != currentTokens[index]) {
        return [];
      }
    }

    var simulatedState = Map<String, String>.from(boardState);
    var sideToMove = _isWhiteTurn;
    final preview = <EngineLine>[];
    final remainingTokens = gambit.moveTokens.sublist(currentTokens.length);
    for (int index = 0; index < remainingTokens.length && index < 6; index++) {
      final uciMove = _resolveSanToUci(
        simulatedState,
        remainingTokens[index],
        sideToMove,
      );
      if (uciMove == null) {
        _addLog('Could not resolve gambit SAN: ${remainingTokens[index]}');
        break;
      }
      preview.add(EngineLine(uciMove, 0, max(1, 6 - index), index + 1));
      simulatedState = _applyUciMove(simulatedState, uciMove);
      sideToMove = !sideToMove;
    }
    return preview;
  }

  String _sanitizeSanToken(String san) {
    var cleaned = san.replaceAll(RegExp(r'[+#?!]+$'), '');
    // ECO data is lowercased during normalization, so castling tokens arrive as
    // 'o-o' / 'o-o-o' (letter o) rather than 'O-O'. Handle both digit-zero and
    // letter-o variants. Order: longer match first to avoid partial replacement.
    cleaned = cleaned.replaceAll('o-o-o', 'O-O-O');
    cleaned = cleaned.replaceAll('o-o', 'O-O');
    cleaned = cleaned.replaceAll('0-0-0', 'O-O-O');
    cleaned = cleaned.replaceAll('0-0', 'O-O');
    return cleaned;
  }

  String? _resolveSanToUci(
    Map<String, String> state,
    String san,
    bool whiteToMove,
  ) {
    final cleanedSan = _sanitizeSanToken(san);
    if (cleanedSan == 'O-O' || cleanedSan == 'O-O-O') {
      if (whiteToMove) {
        return cleanedSan == 'O-O' ? 'e1g1' : 'e1c1';
      }
      return cleanedSan == 'O-O' ? 'e8g8' : 'e8c8';
    }

    final targetMatch = RegExp(
      r'([a-h][1-8])(?:=[nbrq])?$',
    ).firstMatch(cleanedSan);
    if (targetMatch == null) return null;
    final target = targetMatch.group(1)!;
    final targetIndex = cleanedSan.indexOf(target);
    final prefix = cleanedSan.substring(0, targetIndex);
    final isCapture = prefix.contains('x');
    final promotionMatch = RegExp(
      r'=([nbrq])$',
    ).firstMatch(cleanedSan.toLowerCase());
    final promotion = promotionMatch?.group(1);

    String pieceLetter = 'P';
    String disambiguation = prefix;
    if (prefix.isNotEmpty &&
        RegExp(r'^[nbrqk]').hasMatch(prefix[0].toLowerCase())) {
      pieceLetter = prefix[0].toUpperCase();
      disambiguation = prefix.substring(1);
    }
    disambiguation = disambiguation.replaceAll('x', '');

    final candidates = <String>[];
    state.forEach((square, piece) {
      if (!_pieceMatchesSan(piece, pieceLetter, whiteToMove)) return;
      if (!_matchesDisambiguation(square, disambiguation)) return;
      if (_canReachSquare(state, square, target, piece, isCapture)) {
        candidates.add(square);
      }
    });

    if (candidates.isEmpty) return null;
    final from = candidates.first;
    return promotion == null ? '$from$target' : '$from$target$promotion';
  }

  bool _pieceMatchesSan(String piece, String pieceLetter, bool whiteToMove) {
    if (whiteToMove != piece.endsWith('_w')) return false;
    final type = piece[0];
    switch (pieceLetter) {
      case 'P':
        return type == 'p';
      case 'N':
        return type == 'n';
      case 'B':
        return type == 'b';
      case 'R':
        return type == 't';
      case 'Q':
        return type == 'q';
      case 'K':
        return type == 'k';
      default:
        return false;
    }
  }

  bool _matchesDisambiguation(String square, String disambiguation) {
    if (disambiguation.isEmpty) return true;
    if (disambiguation.length == 1) {
      return square.contains(disambiguation);
    }
    return square.startsWith(disambiguation[0]) &&
        square.endsWith(disambiguation[1]);
  }

  bool _canReachSquare(
    Map<String, String> state,
    String from,
    String to,
    String piece,
    bool isCapture,
  ) {
    if (from == to) return false;
    final targetPiece = state[to];
    if (targetPiece != null &&
        targetPiece.endsWith(piece.endsWith('_w') ? '_w' : '_b')) {
      return false;
    }

    final fromFile = from.codeUnitAt(0) - 97;
    final fromRank = int.parse(from[1]);
    final toFile = to.codeUnitAt(0) - 97;
    final toRank = int.parse(to[1]);
    final deltaFile = toFile - fromFile;
    final deltaRank = toRank - fromRank;
    final absFile = deltaFile.abs();
    final absRank = deltaRank.abs();
    final whitePiece = piece.endsWith('_w');

    switch (piece[0]) {
      case 'p':
        final forward = whitePiece ? 1 : -1;
        final startRank = whitePiece ? 2 : 7;
        if (isCapture) {
          return absFile == 1 && deltaRank == forward && targetPiece != null;
        }
        if (deltaFile != 0 || targetPiece != null) return false;
        if (deltaRank == forward) return true;
        if (fromRank == startRank && deltaRank == 2 * forward) {
          final middleSquare = '${from[0]}${fromRank + forward}';
          return state[middleSquare] == null;
        }
        return false;
      case 'n':
        return absFile == 1 && absRank == 2 || absFile == 2 && absRank == 1;
      case 'b':
        return absFile == absRank && _isPathClear(state, from, to);
      case 't':
        return (deltaFile == 0 || deltaRank == 0) &&
            _isPathClear(state, from, to);
      case 'q':
        return ((absFile == absRank) || deltaFile == 0 || deltaRank == 0) &&
            _isPathClear(state, from, to);
      case 'k':
        return absFile <= 1 && absRank <= 1;
      default:
        return false;
    }
  }

  bool _isPathClear(Map<String, String> state, String from, String to) {
    final fromFile = from.codeUnitAt(0) - 97;
    final fromRank = int.parse(from[1]);
    final toFile = to.codeUnitAt(0) - 97;
    final toRank = int.parse(to[1]);
    final stepFile = (toFile - fromFile).sign;
    final stepRank = (toRank - fromRank).sign;

    var file = fromFile + stepFile;
    var rank = fromRank + stepRank;
    while (file != toFile || rank != toRank) {
      final square = '${String.fromCharCode(97 + file)}$rank';
      if (state[square] != null) return false;
      file += stepFile;
      rank += stepRank;
    }
    return true;
  }

  Map<String, String> _applyUciMove(
    Map<String, String> state,
    String uciMove, {
    String? enPassantTarget,
  }) {
    final updated = Map<String, String>.from(state);
    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final piece = updated[from];
    if (piece == null) return updated;

    final enPassantCaptureSquare = _enPassantCaptureSquare(
      state,
      from,
      to,
      piece,
      enPassantTarget: enPassantTarget,
    );
    if (enPassantCaptureSquare != null) {
      updated.remove(enPassantCaptureSquare);
    }

    updated.remove(from);
    updated[to] = piece;

    if (piece[0] == 'k' &&
        from == 'e1' &&
        to == 'g1' &&
        updated['h1'] != null) {
      updated['f1'] = updated['h1']!;
      updated.remove('h1');
    } else if (piece[0] == 'k' &&
        from == 'e1' &&
        to == 'c1' &&
        updated['a1'] != null) {
      updated['d1'] = updated['a1']!;
      updated.remove('a1');
    } else if (piece[0] == 'k' &&
        from == 'e8' &&
        to == 'g8' &&
        updated['h8'] != null) {
      updated['f8'] = updated['h8']!;
      updated.remove('h8');
    } else if (piece[0] == 'k' &&
        from == 'e8' &&
        to == 'c8' &&
        updated['a8'] != null) {
      updated['d8'] = updated['a8']!;
      updated.remove('a8');
    }

    if (uciMove.length == 5) {
      final promotion = uciMove[4];
      final colorSuffix = piece.endsWith('_w') ? '_w' : '_b';
      final promotedPiece = switch (promotion) {
        'n' => 'n',
        'b' => 'b',
        'r' => 't',
        'q' => 'q',
        _ => 'q',
      };
      updated[to] = '$promotedPiece$colorSuffix';
    }

    return updated;
  }

  // --- Move Handling ---
  void _onMove(String from, String to, {String? promotion}) {
    if (_gameOutcome != null) return;
    if (_playVsBot && !_isHumanTurnInBotGame && !_botThinking) {
      return;
    }
    if (from == to) return;
    String piece = boardState[from]!;
    final normalizedPromotion = promotion == 'r' ? 't' : promotion;
    final uciPromotion = normalizedPromotion == null
        ? null
        : (normalizedPromotion == 't'
              ? 'r'
              : normalizedPromotion.toLowerCase());
    final captureSquare = _enPassantCaptureSquare(
      boardState,
      from,
      to,
      piece,
      enPassantTarget: _enPassantTarget,
    );
    final captured = captureSquare == null
        ? boardState[to]
        : boardState[captureSquare];
    final uciMove = uciPromotion == null ? '$from$to' : '$from$to$uciPromotion';
    final nextBoardState = _applyUciMove(
      boardState,
      uciMove,
      enPassantTarget: _enPassantTarget,
    );

    // Opening matching needs SAN-like notation such as e4, exd5, Nf3, Rxe5.
    final notation = _buildMoveNotation(
      from,
      to,
      piece,
      captured,
      normalizedPromotion == 't' ? 'R' : normalizedPromotion,
    );

    _addLog('Recorded move notation: $notation');

    setState(() {
      // If we're not at the end of history, discard outdated future moves.
      if (_historyIndex < _moveHistory.length - 1) {
        _moveHistory.removeRange(_historyIndex + 1, _moveHistory.length);
      }
      boardState = nextBoardState;

      if (piece[0] == 'k') {
        if (piece.endsWith('_w')) {
          _whiteKingMoved = true;
        } else {
          _blackKingMoved = true;
        }
      }
      if (piece[0] == 't') {
        if (from == 'a1') _whiteQueensideRookMoved = true;
        if (from == 'h1') _whiteKingsideRookMoved = true;
        if (from == 'a8') _blackQueensideRookMoved = true;
        if (from == 'h8') _blackKingsideRookMoved = true;
      }
      final rookCaptureSquare = captureSquare ?? to;
      if (rookCaptureSquare == 'a1') _whiteQueensideRookMoved = true;
      if (rookCaptureSquare == 'h1') _whiteKingsideRookMoved = true;
      if (rookCaptureSquare == 'a8') _blackQueensideRookMoved = true;
      if (rookCaptureSquare == 'h8') _blackKingsideRookMoved = true;

      final fromRank = int.parse(from[1]);
      final toRank = int.parse(to[1]);
      if (piece[0] == 'p' && (toRank - fromRank).abs() == 2) {
        _enPassantTarget = '${from[0]}${(fromRank + toRank) ~/ 2}';
      } else {
        _enPassantTarget = null;
      }

      _moveHistory.add(
        MoveRecord(
          notation: notation,
          pieceMoved: piece,
          pieceCaptured: captured,
          state: Map.from(boardState),
          isWhite: _isWhiteTurn,
          whiteKingMoved: _whiteKingMoved,
          blackKingMoved: _blackKingMoved,
          whiteKingsideRookMoved: _whiteKingsideRookMoved,
          whiteQueensideRookMoved: _whiteQueensideRookMoved,
          blackKingsideRookMoved: _blackKingsideRookMoved,
          blackQueensideRookMoved: _blackQueensideRookMoved,
          enPassantTarget: _enPassantTarget,
        ),
      );
      _historyIndex = _moveHistory.length - 1;
      _holdSelectedFrom = null;
      _gambitSelectedFrom = null;
      _legalTargets.clear();
      _gambitAvailableTargets.clear();
      _isWhiteTurn = !_isWhiteTurn;
      _updateCurrentOpening();
      _refreshGambitPreview();
    });

    unawaited(_playBoardMoveSound(isCapture: captured != null));

    if (_playVsBot && _isKingAttacked(boardState, _isWhiteTurn)) {
      unawaited(_checkHaptic());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_historyScrollController.hasClients) {
        _historyScrollController.animateTo(
          _historyScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });

    final gameOutcome = _detectCurrentGameOutcome();
    if (gameOutcome != null) {
      _send('stop');
      setState(() {
        _recordVsBotSessionResult(gameOutcome);
        _gameOutcome = gameOutcome;
        _botThinking = false;
      });
      _persistAnalysisSnapshotIfNeeded();
      unawaited(_showGameResultDialog(gameOutcome));
      return;
    }

    _persistAnalysisSnapshotIfNeeded();
    _analyze();
    if (_playVsBot) {
      unawaited(_maybeTriggerBotMove());
    }
  }

  void _jumpToMove(int index) {
    setState(() {
      _historyIndex = index;
      // Truncate any future moves so they don't interfere with opening/gambit lookups
      if (index < _moveHistory.length - 1) {
        _moveHistory.removeRange(index + 1, _moveHistory.length);
      }
      boardState = Map.from(_moveHistory[index].state);
      _isWhiteTurn = !_moveHistory[index].isWhite;
      _restoreSpecialMoveStateFromRecord(_moveHistory[index]);
      _gameOutcome = null;
      _currentOpening = _findOpeningFromHistory();
      _holdSelectedFrom = null;
      _gambitSelectedFrom = null;
      _legalTargets.clear();
      _gambitAvailableTargets.clear();
      _selectedGambit = null;
      _gambitPreviewLines = [];
      _topLines = [];
      _currentDepth = 0;
      _currentEval = 0.0;
    });
    _persistAnalysisSnapshotIfNeeded();
    _analyze();
  }

  String _genFen() {
    String fen = "";
    for (int r = 8; r >= 1; r--) {
      int e = 0;
      for (int c = 0; c < 8; c++) {
        String s = String.fromCharCode(97 + c) + r.toString();
        if (boardState[s] == null) {
          e++;
        } else {
          if (e > 0) {
            fen += e.toString();
            e = 0;
          }
          String p = boardState[s]![0];
          if (boardState[s]!.endsWith('_w')) {
            p = p.toUpperCase();
          }
          if (p.toLowerCase() == 't') {
            p = boardState[s]!.endsWith('_w') ? 'R' : 'r';
          }
          fen += p;
        }
      }
      if (e > 0) fen += e.toString();
      if (r > 1) fen += "/";
    }

    final castling = StringBuffer();
    if (!_whiteKingMoved &&
        !_whiteKingsideRookMoved &&
        boardState['e1'] == 'k_w' &&
        boardState['h1'] == 't_w') {
      castling.write('K');
    }
    if (!_whiteKingMoved &&
        !_whiteQueensideRookMoved &&
        boardState['e1'] == 'k_w' &&
        boardState['a1'] == 't_w') {
      castling.write('Q');
    }
    if (!_blackKingMoved &&
        !_blackKingsideRookMoved &&
        boardState['e8'] == 'k_b' &&
        boardState['h8'] == 't_b') {
      castling.write('k');
    }
    if (!_blackKingMoved &&
        !_blackQueensideRookMoved &&
        boardState['e8'] == 'k_b' &&
        boardState['a8'] == 't_b') {
      castling.write('q');
    }

    final castlingFen = castling.isEmpty ? '-' : castling.toString();
    final enPassantFen = _enPassantTarget ?? '-';
    final fullmove = (_moveHistory.length ~/ 2) + 1;
    return "$fen ${_isWhiteTurn ? 'w' : 'b'} $castlingFen $enPassantFen 0 $fullmove";
  }

  double _boardIntroOpacity() {
    if (_introCompleted) return 1.0;
    final t = _introController.value;
    return ((t - 0.24) / 0.42).clamp(0.0, 1.0);
  }

  double _buttonIntroOpacity() {
    if (_introCompleted) return 1.0;
    final t = _introController.value;
    return (0.18 + ((t - 0.62) / 0.28).clamp(0.0, 1.0) * 0.82).clamp(0.0, 1.0);
  }

  double _buttonIntroScale() {
    if (_introCompleted) return 1.0;
    final t = _introController.value;
    return 0.86 + (((t - 0.62) / 0.28).clamp(0.0, 1.0) * 0.14);
  }

  Offset _introBoardCenter(Size scene, {double topInsetCompensation = 0.0}) =>
      Offset(scene.width / 2, (scene.height * 0.40) - topInsetCompensation);

  Offset? _suggestionButtonCenterInScene() {
    final buttonContext = _suggestionButtonKey.currentContext;
    final sceneContext = _sceneKey.currentContext;
    if (buttonContext == null || sceneContext == null) return null;

    final buttonBox = _renderBoxFromContext(buttonContext);
    final sceneBox = _renderBoxFromContext(sceneContext);
    if (buttonBox == null || sceneBox == null) return null;

    return sceneBox.globalToLocal(
      buttonBox.localToGlobal(buttonBox.size.center(Offset.zero)),
    );
  }

  Offset? _storeButtonCenterInScene() {
    final buttonContext = _storeButtonKey.currentContext;
    final sceneContext = _sceneKey.currentContext;
    if (buttonContext == null || sceneContext == null) return null;

    final buttonBox = _renderBoxFromContext(buttonContext);
    final sceneBox = _renderBoxFromContext(sceneContext);
    if (buttonBox == null || sceneBox == null) return null;

    return sceneBox.globalToLocal(
      buttonBox.localToGlobal(buttonBox.size.center(Offset.zero)),
    );
  }

  Future<void> _handleAnalysisInterstitialShown() async {
    if (!mounted || _activeSection != AppSection.analysis) return;
    final economy = context.read<EconomyProvider>();
    await economy.addCoins(10);
    await _saveStoreState();
    if (!mounted) return;

    final center = _storeButtonCenterInScene();
    if (center == null) return;
    setState(() {
      _storeCoinGainCenter = center;
      _storeCoinGainAmount = 10;
    });
    await _storeCoinGainController.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _storeCoinGainCenter = null;
    });
  }

  Widget _buildStoreCoinGainOverlay() {
    if (_storeCoinGainCenter == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _storeCoinGainController,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_storeCoinGainController.value);
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        final yOffset = -42 * t;
        final xOffset = sin(t * pi * 2.2) * 2.4;
        final scale = 0.92 + (0.12 * (1.0 - (t - 0.35).abs()));

        return IgnorePointer(
          child: Positioned(
            left: _storeCoinGainCenter!.dx - 26 + xOffset,
            top: _storeCoinGainCenter!.dy - 14 + yOffset,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10261B).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF7EDC8A).withValues(alpha: 0.72),
                    ),
                  ),
                  child: Text(
                    '+$_storeCoinGainAmount',
                    style: const TextStyle(
                      color: Color(0xFF7EDC8A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _introButtonCenter(Size scene) =>
      _suggestionButtonCenterInScene() ??
      Offset(scene.width / 2, scene.height - 52);

  Offset _introMenuDotStart(Size scene, bool yellow) {
    final menuCenter = Offset(scene.width / 2, scene.height / 2);
    final menuDotPosition = yellow
        ? _yellowMenuDotPosition
        : _blueMenuDotPosition;
    final alignedMenuDot = Offset(
      menuDotPosition.dx.clamp(-1.0, 1.0),
      menuDotPosition.dy.clamp(-1.0, 1.0),
    );
    return menuCenter +
        Offset(
          alignedMenuDot.dx * scene.width * 0.42,
          alignedMenuDot.dy * scene.height * 0.40,
        );
  }

  RenderBox? _renderBoxFromContext(BuildContext? context) {
    final obj = context?.findRenderObject();
    if (obj is! RenderBox) return null;
    if (!obj.attached || !obj.hasSize) return null;
    return obj;
  }

  Offset _sceneDotOffset({
    required bool yellow,
    required double t,
    required Size scene,
    required double topInsetCompensation,
  }) {
    final boardCenter = _introBoardCenter(
      scene,
      topInsetCompensation: topInsetCompensation,
    );
    final buttonCenter = _introButtonCenter(scene);

    if (t < 0.22) {
      final p = Curves.easeOutCubic.transform(t / 0.22);
      final start = _introMenuDotStart(scene, yellow);
      final settle =
          boardCenter +
          (yellow ? const Offset(-38, -50) : const Offset(38, -22));
      return Offset.lerp(start, settle, p)!;
    }

    if (t < 0.56) {
      final q = (t - 0.22) / 0.34;
      final centerDrift = Offset(sin(q * pi * 0.9) * 10, cos(q * pi * 0.8) * 8);
      final pairCenter = boardCenter + centerDrift;
      final swirlAngle = (q * pi * 2.0 * 3.6) + (yellow ? 0.0 : pi);
      final swirlRadius = 38 - (20 * q) + sin(q * pi * 3) * 4;
      final swirl = Offset(
        cos(swirlAngle) * swirlRadius,
        sin(swirlAngle) * swirlRadius * 0.92,
      );
      final polish = Offset(
        sin(q * pi * 2 + (yellow ? 0.5 : -0.5)) * 3.5,
        cos(q * pi * 2 + (yellow ? -0.4 : 0.4)) * 2.8,
      );
      return pairCenter + swirl + polish;
    }

    if (t < 0.68) {
      final q = (t - 0.56) / 0.12;
      final eased = Curves.easeInOutCubic.transform(q);
      final radius = 30 - (12 * eased);
      final angle = (q * pi * 2 * 4.0) + (yellow ? pi / 2 : 0);
      return boardCenter +
          Offset(cos(angle) * radius, sin(angle) * radius * 0.82);
    }

    if (t < 0.86) {
      final q = (t - 0.68) / 0.18;
      final travelCenter = Offset.lerp(
        boardCenter,
        buttonCenter,
        Curves.easeInOutCubic.transform(q),
      )!;
      final radius = 30 - (18 * q);
      final angle = (q * pi * 2 * 4.2) + (yellow ? 0.25 : -0.25);
      return travelCenter +
          Offset(cos(angle) * radius, sin(angle) * radius * 0.78);
    }

    final q = (t - 0.86) / 0.14;
    final radius = 18 - (10 * Curves.easeIn.transform(q));
    final angle = (q * pi * 2 * 6.6) + (yellow ? 0 : pi);
    return buttonCenter +
        Offset(cos(angle) * radius, sin(angle) * radius * 0.78);
  }

  Widget _buildPremiumIntroOverlay(Size scene) {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        final t = _introController.value.clamp(0.0, 1.0);
        final topInsetCompensation = MediaQuery.of(context).padding.top;
        final fade = (1.0 - ((t - 0.90) / 0.10).clamp(0.0, 1.0));
        final yellowOffset = _sceneDotOffset(
          yellow: true,
          t: t,
          scene: scene,
          topInsetCompensation: topInsetCompensation,
        );
        final blueOffset = _sceneDotOffset(
          yellow: false,
          t: t,
          scene: scene,
          topInsetCompensation: topInsetCompensation,
        );

        return IgnorePointer(
          child: Opacity(
            opacity: fade,
            child: SizedBox(
              width: scene.width,
              height: scene.height,
              child: Stack(
                children: [
                  Positioned(
                    left: yellowOffset.dx - 10,
                    top: yellowOffset.dy - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD8B640),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD8B640,
                            ).withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: blueOffset.dx - 10,
                    top: blueOffset.dy - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3F6ED8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3F6ED8,
                            ).withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Offset? _squareCenterInScene(String square) {
    final boardContext = _boardKey.currentContext;
    final sceneContext = _sceneKey.currentContext;
    if (boardContext == null || sceneContext == null) return null;

    final boardBox = _renderBoxFromContext(boardContext);
    final sceneBox = _renderBoxFromContext(sceneContext);
    if (boardBox == null || sceneBox == null) return null;

    final boardTopLeft = sceneBox.globalToLocal(
      boardBox.localToGlobal(Offset.zero),
    );
    final size = boardBox.size;
    const inset = 2.0;
    final sq = (size.width - inset * 2) / 8;

    var col = square.codeUnitAt(0) - 97;
    var row = int.parse(square[1]) - 1;
    final reverse = _playVsBot
        ? !_humanPlaysWhite
        : (_perspective == BoardPerspective.black) ||
              (_perspective == BoardPerspective.auto && !_isWhiteTurn);
    if (reverse) {
      col = 7 - col;
    } else {
      row = 7 - row;
    }

    return boardTopLeft +
        Offset(inset + col * sq + sq / 2, inset + row * sq + sq / 2);
  }

  List<String> _launchSquaresForSuggestionCount(int count) {
    const preferred = <String>['e2', 'c2', 'd2', 'f2', 'b2', 'g2', 'a2', 'h2'];
    final safeCount = count.clamp(1, preferred.length);
    return preferred.take(safeCount).toList();
  }

  Future<void> _fireSuggestionLaunch() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final buttonContext = _suggestionButtonKey.currentContext;
      final sceneContext = _sceneKey.currentContext;
      if (buttonContext == null || sceneContext == null) {
        if (!completer.isCompleted) completer.complete();
        return;
      }

      final buttonBox = _renderBoxFromContext(buttonContext);
      final sceneBox = _renderBoxFromContext(sceneContext);
      if (buttonBox == null || sceneBox == null) {
        if (!completer.isCompleted) completer.complete();
        return;
      }

      final buttonCenter = _suggestionButtonCenterInScene();
      if (buttonCenter == null) {
        if (!completer.isCompleted) completer.complete();
        return;
      }
      final squares = _launchSquaresForSuggestionCount(_multiPvCount);
      final targets = squares
          .map(_squareCenterInScene)
          .whereType<Offset>()
          .toList();
      if (targets.isEmpty) {
        if (!completer.isCompleted) completer.complete();
        return;
      }

      setState(() {
        _launchStart = buttonCenter;
        _launchTargets = targets;
      });

      _launchController.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _launchStart = null;
          _launchTargets = <Offset>[];
        });
        if (!completer.isCompleted) completer.complete();
      });
    });
    await completer.future;
  }

  Widget _buildSuggestionLaunchOverlay() {
    if (_launchStart == null || _launchTargets.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _launchController,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_launchController.value);
        final start = _launchStart!;
        final rippleT = ((t - 0.82) / 0.18).clamp(0.0, 1.0);
        final rippleRadius = 8 + (24 * rippleT);
        final rippleAlpha = (1.0 - rippleT) * 0.75;

        return IgnorePointer(
          child: Stack(
            children: [
              for (int index = 0; index < _launchTargets.length; index++) ...[
                if (rippleT > 0)
                  Positioned(
                    left: _launchTargets[index].dx - rippleRadius,
                    top: _launchTargets[index].dy - rippleRadius,
                    child: Container(
                      width: rippleRadius * 2,
                      height: rippleRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(
                            0xFF7EDC8A,
                          ).withValues(alpha: rippleAlpha),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                Builder(
                  builder: (context) {
                    final end = _launchTargets[index];
                    final x = ui.lerpDouble(start.dx, end.dx, t)!;
                    final arcHeight = 26 + (8 * (index % 3));
                    final sideBias =
                        (index - ((_launchTargets.length - 1) / 2)) * 6.0;
                    final y =
                        ui.lerpDouble(start.dy, end.dy, t)! -
                        sin(t * pi) * arcHeight;
                    final glow =
                        4 + (5 * (1 - (t - 0.7).abs().clamp(0.0, 0.7)));
                    return Positioned(
                      left: x - 4 + sideBias * (1 - t),
                      top: y - 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF7EDC8A),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7EDC8A,
                              ).withValues(alpha: 0.85),
                              blurRadius: glow,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildButtonRippleOverlay() {
    if (_buttonRippleCenter == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _buttonRippleController,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_buttonRippleController.value);
        return IgnorePointer(
          child: Stack(
            children: [
              for (int i = 0; i < 3; i++)
                Builder(
                  builder: (context) {
                    final delay = i * 0.22;
                    final rt = ((t - delay) / (1.0 - delay)).clamp(0.0, 1.0);
                    final radius = 16 + (54 * rt);
                    final alpha = (1.0 - rt) * 0.28;
                    return Positioned(
                      left: _buttonRippleCenter!.dx - radius,
                      top: _buttonRippleCenter!.dy - radius,
                      child: Container(
                        width: radius * 2,
                        height: radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF7EDC8A,
                            ).withValues(alpha: alpha),
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _menuLogoAsset(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? 'assets/logo2.png'
        : 'assets/logo.png';
  }

  // --- UI Sections ---
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final menuTopColor = Color.alphaBlend(
      Color.lerp(
        scheme.primary,
        scheme.secondary,
        0.32,
      )!.withValues(alpha: isDark ? 0.12 : 0.05),
      scheme.surface,
    );
    final menuBottomColor = Color.alphaBlend(
      scheme.tertiary.withValues(alpha: isDark ? 0.08 : 0.04),
      scheme.surface,
    );
    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      onPointerMove: (_) => _resetIdleTimer(),
      onPointerSignal: (_) => _resetIdleTimer(),
      child: Focus(
        canRequestFocus: _activeSection == AppSection.analysis,
        autofocus: _activeSection == AppSection.analysis,
        onKeyEvent: (node, event) {
          if (_activeSection != AppSection.analysis) {
            return KeyEventResult.ignored;
          }
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.f5) {
            unawaited(_resetFromHotkey());
            _resetIdleTimer();
            return KeyEventResult.handled;
          }
          if (event is KeyDownEvent || event is KeyUpEvent) {
            _resetIdleTimer();
          }
          return KeyEventResult.ignored;
        },
        child: _activeSection == AppSection.analysis
            ? _buildAnalysisBoardScaffold(context)
            : Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [menuTopColor, scheme.surface, menuBottomColor],
                      stops: [0.0, 0.72, 1.0],
                    ),
                  ),
                  child: (!isLandscape)
                      ? SafeArea(
                          child: !_menuReady
                              ? Center(
                                  child: FadeTransition(
                                    opacity: CurvedAnimation(
                                      parent: _menuRevealController,
                                      curve: Curves.easeOutCubic,
                                    ),
                                    child: Image.asset(
                                      _menuLogoAsset(context),
                                      width: 220,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                              : FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: _sectionTransitionController,
                                    curve: Curves.easeInOutCubic,
                                  ),
                                  child: _buildMenuExitTransition(),
                                ),
                        )
                      : (!_menuReady
                            ? Center(
                                child: FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: _menuRevealController,
                                    curve: Curves.easeOutCubic,
                                  ),
                                  child: Image.asset(
                                    _menuLogoAsset(context),
                                    width: 220,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            : FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: _sectionTransitionController,
                                  curve: Curves.easeInOutCubic,
                                ),
                                child: _buildMenuExitTransition(),
                              )),
                ),
              ),
      ),
    );
  }

  Widget _buildStartMenu() {
    const coreBlue = Color(0xFF2A6CF0);
    const coreGold = Color(0xFFD8B640);
    const fusionGreen = Color(0xFF7EDC8A);
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final isTablet = media.size.shortestSide >= 700;
    final showMenuLogo = !isLandscape || isTablet;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final appTheme = context.watch<AppThemeProvider>();
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final isMono = appTheme.isMonochrome || _isCinematicThemeEnabled;
        final controlSurface = scheme.surfaceContainerHighest;
        final menuBackground = scheme.surface;
        final menuWindowSurface = scheme.surfaceContainerHighest;
        final blueDotColor = isMono
            ? scheme.onSurface.withValues(alpha: 0.52)
            : const Color(0xFF5AAEE8);
        final yellowDotColor = isMono
            ? scheme.onSurface.withValues(alpha: 0.50)
            : const Color(0xFFD8B640);

        final blueDotAlignment = Alignment(
          _blueMenuDotPosition.dx.clamp(-1.0, 1.0),
          _blueMenuDotPosition.dy.clamp(-1.0, 1.0),
        );
        final yellowDotAlignment = Alignment(
          _yellowMenuDotPosition.dx.clamp(-1.0, 1.0),
          _yellowMenuDotPosition.dy.clamp(-1.0, 1.0),
        );

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: menuBackground),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    Align(
                      alignment: blueDotAlignment,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: blueDotColor,
                          boxShadow: [
                            BoxShadow(
                              color: blueDotColor.withValues(alpha: 0.48),
                              blurRadius: 18,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: yellowDotAlignment,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: yellowDotColor,
                          boxShadow: [
                            BoxShadow(
                              color: yellowDotColor.withValues(alpha: 0.48),
                              blurRadius: 18,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ..._menuSparkParticles.map((particle) {
                      return Align(
                        alignment: Alignment(
                          particle.position.dx,
                          particle.position.dy,
                        ),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: particle.color,
                            boxShadow: [
                              BoxShadow(
                                color: particle.color.withValues(alpha: 0.85),
                                blurRadius: 8,
                                spreadRadius: 1.5,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  if (showMenuLogo)
                    Center(
                      child: GestureDetector(
                        onTap: _showCreditsDialog,
                        child: Image.asset(
                          _menuLogoAsset(context),
                          width: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  SizedBox(height: showMenuLogo ? 10 : 2),
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 430,
                          maxHeight: 560,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildMenuCenterShape(
                              size: 360,
                              strokeColor: scheme.outline.withValues(
                                alpha: 0.38,
                              ),
                              strokeWidth: 2,
                              rotation: _menuCenterRotationA,
                              sides: _menuCenterShapeSidesA,
                            ),
                            _buildMenuCenterShape(
                              size: 285,
                              strokeColor: scheme.outline.withValues(
                                alpha: 0.30,
                              ),
                              strokeWidth: 1.5,
                              rotation: _menuCenterRotationB,
                              sides: _menuCenterShapeSidesB,
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 3,
                                  sigmaY: 3,
                                ),
                                child: Container(
                                  width: 220,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: menuWindowSurface.withValues(
                                      alpha: isMono ? 0.10 : 0.14,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(
                                          alpha: isMono ? 0.38 : 0.44,
                                        ),
                                        menuWindowSurface.withValues(
                                          alpha: isMono ? 0.14 : 0.10,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: isMono ? 0.50 : 0.60,
                                      ),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withValues(
                                          alpha: isMono ? 0.08 : 0.12,
                                        ),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 12),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 26,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _menuGlyphButton(
                                        label: 'PLAY CHESS',
                                        icon: Icons.smart_toy_outlined,
                                        accent: isMono
                                            ? scheme.onSurface.withValues(
                                                alpha: 0.88,
                                              )
                                            : const Color(0xFF5AAEE8),
                                        onTap: _openBotSetupFromMenu,
                                      ),
                                      _menuGlyphButton(
                                        label: 'ANALYSIS',
                                        icon: Icons.analytics_outlined,
                                        accent: isMono
                                            ? scheme.onSurface.withValues(
                                                alpha: 0.82,
                                              )
                                            : coreGold,
                                        onTap: () =>
                                            unawaited(_enterAnalysisBoard()),
                                      ),
                                      _menuGlyphButton(
                                        label: 'OPENING LAB',
                                        icon: Icons.extension_outlined,
                                        accent: isMono
                                            ? scheme.onSurface.withValues(
                                                alpha: 0.78,
                                              )
                                            : coreBlue,
                                        onTap: _openGambitQuizFromMenu,
                                      ),
                                      _menuGlyphButton(
                                        label: 'PUZZLE ACADEMY',
                                        icon: Icons.auto_stories_outlined,
                                        accent: isMono
                                            ? scheme.onSurface.withValues(
                                                alpha: 0.76,
                                              )
                                            : const Color(0xFF6FE7FF),
                                        onTap: _openPuzzleAcademyFromMenu,
                                      ),
                                      _menuGlyphButton(
                                        label: 'STORE',
                                        icon: Icons.storefront_outlined,
                                        accent: isMono
                                            ? scheme.onSurface.withValues(
                                                alpha: 0.74,
                                              )
                                            : fusionGreen,
                                        onTap: _openStore,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _setMute(!_muteSounds),
                        icon: Icon(
                          _muteSounds
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                        ),
                        label: Text(_muteSounds ? 'Muted' : 'Sound On'),
                        style: FilledButton.styleFrom(
                          backgroundColor: controlSurface,
                          foregroundColor: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () => _openSettings(),
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Settings'),
                        style: FilledButton.styleFrom(
                          backgroundColor: controlSurface,
                          foregroundColor: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _menuGlyphButton({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final labelColor = isLight ? scheme.onSurface : accent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLight
                  ? scheme.outline.withValues(alpha: 0.45)
                  : accent.withValues(alpha: 0.45),
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                accent.withValues(alpha: isLight ? 0.08 : 0.14),
                scheme.surface.withValues(alpha: isLight ? 0.56 : 0.08),
                accent.withValues(alpha: isLight ? 0.05 : 0.08),
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isLight ? accent.withValues(alpha: 0.78) : accent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accent.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotSetupScreen() {
    final selectedBot = _botCharacters[_botSetupSelectedIndex];
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
                                            () =>
                                                _botSetupSelectedIndex = index,
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
                                            final active =
                                                index == _botSetupSelectedIndex;
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
                                                color: active
                                                    ? const Color(0xFF7FC4FF)
                                                    : Colors.white24,
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
                                onPressed: () {
                                  unawaited(
                                    _startBotMatch(
                                      bot: selectedBot,
                                      sideChoice: _botSideChoice,
                                    ),
                                  );
                                },
                                child: const Text('Start'),
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

  Widget _buildAnalysisBoardScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    bool reverse = _playVsBot
        ? !_humanPlaysWhite
        : (_perspective == BoardPerspective.black) ||
              (_perspective == BoardPerspective.auto && !_isWhiteTurn);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final pageBackground = scheme.surface;
    final bgTop = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.16 : 0.05),
      scheme.surface,
    );
    final bgBottom = Color.alphaBlend(
      scheme.secondary.withValues(alpha: isDark ? 0.10 : 0.04),
      scheme.surface,
    );
    final leftBlob = useMonochrome
        ? (isDark ? const Color(0xFF334B80) : const Color(0xFFDEE8FB))
        : const Color(0xFF3F6ED8);
    final rightBlob = useMonochrome
        ? (isDark ? const Color(0xFF6E6540) : const Color(0xFFF3EBCF))
        : const Color(0xFFB9A46A);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, pageBackground, bgBottom],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: leftBlob.withValues(alpha: isDark ? 0.16 : 0.09),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rightBlob.withValues(alpha: isDark ? 0.12 : 0.08),
                ),
              ),
            ),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double modelRatio = 393.0 / 852.0;
                  double maxWidth = constraints.maxWidth;
                  double maxHeight = constraints.maxHeight;
                  double width;
                  double height;

                  if (isLandscape) {
                    width = maxWidth;
                    height = maxHeight;
                  } else {
                    width = maxWidth <= 430 ? maxWidth : 430;
                    height = width / modelRatio;
                    if (height > maxHeight) {
                      height = maxHeight;
                      width = height * modelRatio;
                    }
                  }

                  final double scale = (width / 430.0).clamp(0.8, 1.4);

                  return SizedBox(
                    key: _sceneKey,
                    width: width,
                    height: height,
                    child: Stack(
                      children: [
                        SafeArea(
                          child: isLandscape
                              ? Column(
                                  children: [
                                    _buildHeader(scale),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          10,
                                          8,
                                          10,
                                          8,
                                        ),
                                        child: LayoutBuilder(
                                          builder: (context, inner) {
                                            final sideWidth =
                                                (inner.maxWidth * 0.34).clamp(
                                                  220.0,
                                                  360.0,
                                                );
                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Expanded(
                                                  flex: 7,
                                                  child: LayoutBuilder(
                                                    builder: (context, boardBox) {
                                                      const double evalBarW =
                                                          22.0;
                                                      final boardSize = max(
                                                        0.0,
                                                        min(
                                                          boardBox.maxWidth -
                                                              evalBarW,
                                                          boardBox.maxHeight,
                                                        ),
                                                      );
                                                      return Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                            width: evalBarW,
                                                            height: boardSize,
                                                            child: Center(
                                                              child:
                                                                  _buildEvalBarVertical(
                                                                    scale,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Center(
                                                              child: SizedBox(
                                                                key: _boardKey,
                                                                width:
                                                                    boardSize,
                                                                height:
                                                                    boardSize,
                                                                child: Stack(
                                                                  children: [
                                                                    Opacity(
                                                                      opacity:
                                                                          _boardIntroOpacity(),
                                                                      child: _buildBoard(
                                                                        reverse,
                                                                      ),
                                                                    ),
                                                                    Opacity(
                                                                      opacity:
                                                                          _boardIntroOpacity(),
                                                                      child: _buildAnimatedArrows(
                                                                        reverse,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                SizedBox(
                                                  width: sideWidth,
                                                  child: LayoutBuilder(
                                                    builder: (context, sideConstraints) {
                                                      final suggestionsHeight =
                                                          (sideConstraints
                                                                      .maxHeight *
                                                                  0.46)
                                                              .clamp(
                                                                96.0,
                                                                250.0,
                                                              );
                                                      final historyHeight =
                                                          (sideConstraints
                                                                      .maxHeight *
                                                                  0.16)
                                                              .clamp(
                                                                46.0,
                                                                72.0,
                                                              );
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 10,
                                                                ),
                                                            child: Align(
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              child: SizedBox(
                                                                height:
                                                                    20 * scale,
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    if (!_playVsBot)
                                                                      SizedBox(
                                                                        width:
                                                                            20 *
                                                                            scale,
                                                                        height:
                                                                            20 *
                                                                            scale,
                                                                        child: IconButton(
                                                                          onPressed: () {
                                                                            setState(() {
                                                                              _analysisEditMode = !_analysisEditMode;
                                                                              _holdSelectedFrom = null;
                                                                              _gambitSelectedFrom = null;
                                                                              _legalTargets.clear();
                                                                              _gambitAvailableTargets.clear();
                                                                              _editModeHintText = _analysisEditMode
                                                                                  ? 'Edit mode on'
                                                                                  : 'Edit mode off';
                                                                            });
                                                                            _scheduleEditModeHintHide();
                                                                          },
                                                                          icon: Text(
                                                                            _analysisEditMode
                                                                                ? '🛠️'
                                                                                : '🔒',
                                                                            style: TextStyle(
                                                                              fontSize:
                                                                                  14 *
                                                                                  scale,
                                                                            ),
                                                                          ),
                                                                          tooltip:
                                                                              _analysisEditMode
                                                                              ? 'Edit mode on (any move allowed)'
                                                                              : 'Edit mode off (legal moves only)',
                                                                          splashRadius:
                                                                              14 *
                                                                              scale,
                                                                          visualDensity:
                                                                              VisualDensity.compact,
                                                                          padding:
                                                                              EdgeInsets.zero,
                                                                          constraints: BoxConstraints.tightFor(
                                                                            width:
                                                                                20 *
                                                                                scale,
                                                                            height:
                                                                                20 *
                                                                                scale,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Text(
                                                                      'Depth $_currentDepth',
                                                                      style: TextStyle(
                                                                        color: scheme
                                                                            .onSurface
                                                                            .withValues(
                                                                              alpha: 0.54,
                                                                            ),
                                                                        fontSize:
                                                                            11 *
                                                                            scale,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          if (!_playVsBot &&
                                                              _selectedGambit !=
                                                                  null)
                                                            Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      bottom: 6,
                                                                    ),
                                                                child: Text(
                                                                  _selectedGambit!
                                                                      .name,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        useMonochrome
                                                                        ? scheme.onSurface.withValues(
                                                                            alpha:
                                                                                0.86,
                                                                          )
                                                                        : const Color(
                                                                            0xFFD8B640,
                                                                          ),
                                                                  ),
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            )
                                                          else if (!_playVsBot &&
                                                              _currentOpening
                                                                  .isNotEmpty)
                                                            Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      bottom: 6,
                                                                    ),
                                                                child: Text(
                                                                  _currentOpening,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color: scheme
                                                                        .onSurface
                                                                        .withValues(
                                                                          alpha:
                                                                              0.72,
                                                                        ),
                                                                  ),
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                          _buildSuggestedMovesList(
                                                            height:
                                                                suggestionsHeight,
                                                            padding: _playVsBot
                                                                ? const EdgeInsets.fromLTRB(
                                                                    16,
                                                                    2,
                                                                    16,
                                                                    8,
                                                                  )
                                                                : const EdgeInsets.symmetric(
                                                                    vertical:
                                                                        10,
                                                                    horizontal:
                                                                        20,
                                                                  ),
                                                          ),
                                                          if (!_playVsBot)
                                                            _buildHistoryBar(
                                                              height:
                                                                  historyHeight,
                                                              margin:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 6,
                                                                  ),
                                                            ),
                                                          const Spacer(),
                                                          _buildActionArea(
                                                            compactBottom: 8,
                                                            horizontal: 0,
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildHeader(scale),
                                    _buildEvalBarHorizontal(scale),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          8,
                                          8,
                                          8,
                                          _playVsBot ? 2 : 8,
                                        ),
                                        child: LayoutBuilder(
                                          builder: (context, inner) {
                                            final boardSize = min(
                                              inner.maxWidth,
                                              inner.maxHeight,
                                            );
                                            return Align(
                                              alignment: Alignment.topCenter,
                                              child: SizedBox(
                                                key: _boardKey,
                                                width: boardSize,
                                                height: boardSize,
                                                child: Stack(
                                                  children: [
                                                    Opacity(
                                                      opacity:
                                                          _boardIntroOpacity(),
                                                      child: _buildBoard(
                                                        reverse,
                                                      ),
                                                    ),
                                                    Opacity(
                                                      opacity:
                                                          _boardIntroOpacity(),
                                                      child:
                                                          _buildAnimatedArrows(
                                                            reverse,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    if (!_playVsBot) _buildOpeningLabel(scale),
                                    _buildSuggestedMovesList(
                                      height: _playVsBot ? 168 : 130,
                                      padding: _playVsBot
                                          ? const EdgeInsets.fromLTRB(
                                              20,
                                              2,
                                              20,
                                              8,
                                            )
                                          : const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 20,
                                            ),
                                    ),
                                    if (!_playVsBot) _buildHistoryBar(),
                                    _buildActionArea(),
                                  ],
                                ),
                        ),
                        if (!_introCompleted)
                          _buildPremiumIntroOverlay(Size(width, height)),
                        if (_editModeHintText != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0C1018,
                                    ).withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _analysisEditMode
                                          ? const Color(
                                              0xFFFFD166,
                                            ).withValues(alpha: 0.42)
                                          : Colors.white24,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _editModeHintText!,
                                    style: TextStyle(
                                      color: _analysisEditMode
                                          ? const Color(0xFFFFD166)
                                          : Colors.white70,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        _buildSuggestionLaunchOverlay(),
                        _buildButtonRippleOverlay(),
                        _buildStoreCoinGainOverlay(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double scale) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final isLightMono = useMonochrome && !isDark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final displayedEval = _displayEvalForPov();
    final displayedEvalColor = isLightMono
        ? Colors.black
        : useMonochrome
        ? const Color(0xFFEEEEEE)
        : _evalColorForUi(displayedEval);
    final selectedBot = _selectedBot;
    if (isLandscape) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 8 * scale,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isLandscape)
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right: (_playVsBot && selectedBot != null)
                          ? (46 * scale)
                          : 0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _showCreditsDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 2 * scale,
                                horizontal: 2 * scale,
                              ),
                              child: Image.asset(
                                'assets/ChessIQ.png',
                                width: 120 * scale,
                                height: 34 * scale,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 120 * scale,
                            child: Text(
                              'Engine: Stockfish 18',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.54),
                                fontSize: 10 * scale,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_playVsBot && selectedBot != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: _onBotAvatarTapped,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 34 * scale,
                          height: 34 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF9ED8FF,
                              ).withValues(alpha: 0.38),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.24 : 0.10,
                                ),
                                blurRadius: 10 * scale,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: selectedBot.avatarAsset != null
                                ? Image.asset(
                                    selectedBot.avatarAsset!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Color.alphaBlend(
                                      scheme.primary.withValues(alpha: 0.08),
                                      scheme.surface,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.smart_toy_outlined,
                                      color: const Color(0xFF9ED8FF),
                                      size: 18 * scale,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (!isLandscape)
            Expanded(
              child: Center(
                child: Visibility(
                  visible: _shouldKeepEvalActive,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14 * scale,
                      vertical: 6 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: isLightMono
                          ? Colors.white
                          : Color.alphaBlend(
                              scheme.primary.withValues(
                                alpha: isDark ? 0.14 : 0.05,
                              ),
                              scheme.surface,
                            ).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLightMono
                            ? Colors.black
                            : scheme.outline.withValues(alpha: 0.34),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.30 : 0.10,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _evalTextForUi(displayedEval),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: displayedEvalColor,
                        fontSize: 14 * scale,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 120 * scale,
                height: 20 * scale,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerRight,
                  children: [
                    Positioned(
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Depth $_currentDepth',
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.54),
                              fontSize: 11 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_playVsBot)
                      Positioned(
                        right: 84 * scale,
                        child: SizedBox(
                          width: 20 * scale,
                          height: 20 * scale,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _analysisEditMode = !_analysisEditMode;
                                _holdSelectedFrom = null;
                                _gambitSelectedFrom = null;
                                _legalTargets.clear();
                                _gambitAvailableTargets.clear();
                                _editModeHintText = _analysisEditMode
                                    ? 'Edit mode on'
                                    : 'Edit mode off';
                              });
                              _scheduleEditModeHintHide();
                            },
                            icon: Text(
                              _analysisEditMode ? '🛠️' : '🔒',
                              style: TextStyle(fontSize: 14 * scale),
                            ),
                            tooltip: _analysisEditMode
                                ? 'Edit mode on (any move allowed)'
                                : 'Edit mode off (legal moves only)',
                            splashRadius: 14 * scale,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints.tightFor(
                              width: 20 * scale,
                              height: 20 * scale,
                            ),
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
    );
  }

  Widget _buildEvalBarHorizontal(double scale) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final isLightMono = useMonochrome && !isDark;
    final showEvalBar = _shouldKeepEvalActive;
    final displayedEval = _displayEvalForPov();

    if (!useMonochrome) {
      final displayedEvalColor = _evalColorForUi(displayedEval);
      final showWinningAura = _isWinningOutcomeForPov || displayedEval > 5.0;
      final fill = _evalFillForUi(displayedEval);
      return Visibility(
        visible: showEvalBar,
        maintainAnimation: true,
        maintainSize: true,
        maintainState: true,
        child: Container(
          height: 6 * scale,
          width: double.infinity,
          margin: EdgeInsets.symmetric(
            horizontal: 18 * scale,
            vertical: 4 * scale,
          ),
          decoration: BoxDecoration(
            color: scheme.outline.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(2 * scale),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fill,
            child: Container(
              decoration: BoxDecoration(
                color: displayedEvalColor,
                borderRadius: BorderRadius.circular(2 * scale),
                boxShadow: [
                  BoxShadow(
                    color:
                        (showWinningAura
                                ? const Color(0xFFD8B640)
                                : displayedEvalColor)
                            .withValues(alpha: 0.65),
                    blurRadius: showWinningAura ? 10 * scale : 4 * scale,
                    spreadRadius: showWinningAura ? 1.2 : 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final Color whiteSegmentColor = isLightMono
        ? Colors.white
        : const Color(0xFFF7F7F7);
    final Color blackSegmentColor = isLightMono
        ? Colors.black
        : const Color(0xFF13161C);
    final Color trackBorderColor = Colors.black;
    final bool leftSideIsWhite = !_isBlackPovActive;
    final Color leftColor = leftSideIsWhite
        ? whiteSegmentColor
        : blackSegmentColor;
    final Color rightColor = leftSideIsWhite
        ? blackSegmentColor
        : whiteSegmentColor;
    final double leftShare = _evalFillForUi(displayedEval);
    final bool turnMatchesLeft = _isWhiteTurn == leftSideIsWhite;
    final Alignment overlayAlignment = turnMatchesLeft
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final double overlayWidthFactor = turnMatchesLeft
        ? leftShare
        : (1.0 - leftShare);
    final Color baseColor = turnMatchesLeft ? rightColor : leftColor;
    final Color overlayColor = turnMatchesLeft ? leftColor : rightColor;

    return Visibility(
      visible: showEvalBar,
      maintainAnimation: true,
      maintainSize: true,
      maintainState: true,
      child: Container(
        height: 6 * scale,
        width: double.infinity,
        margin: EdgeInsets.symmetric(
          horizontal: 18 * scale,
          vertical: 4 * scale,
        ),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(2 * scale),
          border: isLightMono ? Border.all(color: trackBorderColor) : null,
        ),
        child: FractionallySizedBox(
          alignment: overlayAlignment,
          widthFactor: overlayWidthFactor,
          child: Container(
            decoration: BoxDecoration(
              color: overlayColor,
              borderRadius: BorderRadius.circular(2 * scale),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvalBarVertical(double scale) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final isLightMono = useMonochrome && !isDark;
    final showEvalBar = _shouldKeepEvalActive;
    final displayedEval = _displayEvalForPov();
    final fill = _evalFillForUi(displayedEval);
    final showWinningAura = _isWinningOutcomeForPov || displayedEval > 5.0;

    final int topFlex = max(1, ((1.0 - fill) * 100).round());
    final int bottomFlex = max(1, (fill * 100).round());

    if (!useMonochrome) {
      // Themed color mode: bottom = player's eval color, top = opponent track
      final displayedEvalColor = _evalColorForUi(displayedEval);
      final auraColor = showWinningAura
          ? const Color(0xFFD8B640)
          : displayedEvalColor;
      return Visibility(
        visible: showEvalBar,
        maintainAnimation: true,
        maintainSize: true,
        maintainState: true,
        child: Container(
          width: 10 * scale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5 * scale),
            color: scheme.outline.withValues(alpha: 0.24),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.32)),
            boxShadow: [
              BoxShadow(
                color: auraColor.withValues(
                  alpha: showWinningAura ? 0.55 : 0.40,
                ),
                blurRadius: showWinningAura ? 10 * scale : 4 * scale,
                spreadRadius: showWinningAura ? 1.2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5 * scale),
            child: Column(
              children: [
                Expanded(
                  flex: topFlex,
                  child: Container(
                    color: scheme.outline.withValues(alpha: 0.18),
                  ),
                ),
                Expanded(
                  flex: bottomFlex,
                  child: Container(color: displayedEvalColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Monochrome mode: classic black/white segments
    final Color lightSeg = isLightMono ? Colors.white : const Color(0xFFF7F7F7);
    final Color darkSeg = isLightMono ? Colors.black : const Color(0xFF13161C);
    final bool bottomIsWhite = !_isBlackPovActive;
    final Color bottomColor = bottomIsWhite ? lightSeg : darkSeg;
    final Color topColor = bottomIsWhite ? darkSeg : lightSeg;

    return Visibility(
      visible: showEvalBar,
      maintainAnimation: true,
      maintainSize: true,
      maintainState: true,
      child: Container(
        width: 10 * scale,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5 * scale),
          border: Border.all(
            color: isLightMono
                ? Colors.black
                : scheme.outline.withValues(alpha: 0.48),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5 * scale),
          child: Column(
            children: [
              Expanded(
                flex: topFlex,
                child: Container(color: topColor),
              ),
              Expanded(
                flex: bottomFlex,
                child: Container(color: bottomColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningLabel(double scale) {
    final scheme = Theme.of(context).colorScheme;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final label = _selectedGambit?.name ?? _currentOpening;
    return SizedBox(
      height: 24 * scale,
      child: Visibility(
        visible: label.isNotEmpty,
        maintainAnimation: true,
        maintainSize: true,
        maintainState: true,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scale,
            vertical: 4 * scale,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: useMonochrome
                  ? scheme.onSurface.withValues(alpha: 0.86)
                  : (_selectedGambit != null
                        ? const Color(0xFFD8B640)
                        : scheme.onSurface.withValues(alpha: 0.72)),
              fontSize: _selectedGambit != null ? (13 * scale) : (12 * scale),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(bool reverse) {
    final darkSquareColor = _darkSquareColorForTheme();
    final lightSquareColor = _lightSquareColorForTheme();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: 64,
        itemBuilder: (context, i) {
          final visualFile = i % 8;
          final visualRankFromTop = i ~/ 8;
          int row = reverse ? (i ~/ 8) : (7 - i ~/ 8);
          int col = reverse ? (7 - i % 8) : (i % 8);
          String sq = String.fromCharCode(97 + col) + (row + 1).toString();
          bool isDark = (row + col) % 2 == 0;
          String? p = boardState[sq];
          final showFileLabel = visualRankFromTop == 7;
          final showRankLabel = visualFile == 0;
          final labelColor = isDark ? lightSquareColor : darkSquareColor;
          final isGambitSelected = _gambitSelectedFrom == sq;
          final isHoldSelected = _holdSelectedFrom == sq;
          final isLegalTarget = _legalTargets.contains(sq);
          final isGambitAvailableTarget = _gambitAvailableTargets.contains(sq);
          final showOpeningSelectionDots =
              _isOpeningSelectionMode && isGambitAvailableTarget;
          final showLockedLegalDots =
              !_analysisEditMode && !_isOpeningSelectionMode;
          final showTargetDot =
              isLegalTarget &&
              (showOpeningSelectionDots || showLockedLegalDots);
          final isCaptureTarget = isLegalTarget && p != null;
          const legalDotBase = Color(0xFF9EA8BA);

          return DragTarget<String>(
            onAcceptWithDetails: (d) {
              if (_isOpeningSelectionMode && _selectedGambit == null) {
                _handleGambitDragDrop(d.data, sq);
                return;
              }
              unawaited(_attemptMove(d.data, sq));
            },
            builder: (context, candidateData, rejectedData) => Container(
              decoration: BoxDecoration(
                color: isDark ? darkSquareColor : lightSquareColor,
                border: (isGambitSelected || isHoldSelected)
                    ? Border.all(color: _openingSelectionAccent, width: 2)
                    : null,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    (_isOpeningSelectionMode && _selectedGambit == null)
                    ? _handleBoardTap(sq)
                    : _handleHoldTap(sq),
                onLongPress: () {
                  if (_openingMode != OpeningMode.off) return;
                  if (!_analysisEditMode && !_isCurrentTurnPiece(p)) return;
                  setState(() {
                    _holdSelectedFrom = sq;
                    _gambitSelectedFrom = null;
                    _legalTargets
                      ..clear()
                      ..addAll(
                        _analysisEditMode ? <String>{} : _legalMovesFrom(sq),
                      );
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (showTargetDot)
                      Center(
                        child: Container(
                          width: isCaptureTarget ? 26 : 12,
                          height: isCaptureTarget ? 26 : 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCaptureTarget
                                ? Colors.transparent
                                : (showOpeningSelectionDots
                                      ? _openingSelectionAccent.withValues(
                                          alpha: 0.55,
                                        )
                                      : legalDotBase.withValues(alpha: 0.6)),
                            border: isCaptureTarget
                                ? Border.all(
                                    color: showOpeningSelectionDots
                                        ? _openingSelectionAccent.withValues(
                                            alpha: 0.75,
                                          )
                                        : legalDotBase.withValues(alpha: 0.8),
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
                                (row + 1).toString(),
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
                                String.fromCharCode(97 + col),
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
                    if (p != null)
                      Center(
                        child: Draggable<String>(
                          data: sq,
                          feedback: _buildPieceGlow(p),
                          onDragStarted: () {
                            if (_isOpeningSelectionMode &&
                                !_isCurrentTurnPiece(p)) {
                              return;
                            }
                            if (!_isOpeningSelectionMode &&
                                !_analysisEditMode &&
                                !_isCurrentTurnPiece(p)) {
                              return;
                            }
                            setState(() {
                              if (_isOpeningSelectionMode) {
                                _selectGambitSource(sq);
                              } else {
                                _holdSelectedFrom = sq;
                                _gambitSelectedFrom = null;
                                _legalTargets
                                  ..clear()
                                  ..addAll(
                                    _analysisEditMode
                                        ? <String>{}
                                        : _legalMovesFrom(sq),
                                  );
                                _gambitAvailableTargets.clear();
                              }
                            });
                          },
                          onDragEnd: (details) {
                            if (!details.wasAccepted) {
                              setState(() {
                                _holdSelectedFrom = null;
                                _gambitSelectedFrom = null;
                                _legalTargets.clear();
                                _gambitAvailableTargets.clear();
                              });
                            }
                          },
                          childWhenDragging: Opacity(
                            opacity: 0.2,
                            child: _pieceImage(p),
                          ),
                          child: () {
                            String? glowColor;
                            if (_isOpeningSelectionMode &&
                                _gambitSelectedFrom == sq) {
                              glowColor = _isGambitsOnlyOpeningMode
                                  ? 'violet'
                                  : 'yellow';
                            } else if (_gambitPreviewLines.isNotEmpty &&
                                _getPreviewMoveSqares().contains(sq)) {
                              glowColor = _isGambitsOnlyOpeningMode
                                  ? 'violet'
                                  : 'blue';
                            }
                            return _buildPieceWithGlow(p, glowColor);
                          }(),
                        ),
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

  Widget _buildHistoryMoveChip(MoveRecord move, bool active) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = active
        ? (useMonochrome
              ? scheme.onSurface.withValues(alpha: isDark ? 0.14 : 0.12)
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: isDark ? 0.24 : 0.18),
                  scheme.surface,
                ))
        : (useMonochrome
              ? scheme.surface.withValues(alpha: isDark ? 0.24 : 0.92)
              : scheme.surface.withValues(alpha: isDark ? 0.72 : 0.72));

    final borderColor = active
        ? (useMonochrome
              ? scheme.onSurface.withValues(alpha: 0.18)
              : scheme.primary.withValues(alpha: 0.35))
        : scheme.outline.withValues(alpha: 0.12);

    final textColor = active
        ? scheme.onSurface
        : useMonochrome
        ? scheme.onSurface.withValues(alpha: 0.70)
        : scheme.onSurface.withValues(alpha: 0.68);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _pieceImage(move.pieceMoved, width: 18, height: 18),
          const SizedBox(width: 4),
          Text(move.notation, style: TextStyle(color: textColor, fontSize: 13)),
          if (move.pieceCaptured != null) ...[
            const SizedBox(width: 4),
            _pieceImage(move.pieceCaptured!, width: 16, height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildPieceGlow(String p) {
    final glowColor = _isGambitsOnlyOpeningMode
        ? const Color(0xFFB16CFF)
        : _openingMode == OpeningMode.yellowGlow
        ? const Color(0xFFFFD166)
        : const Color(0xFF5AAEE8);

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.6),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: _pieceImage(p),
    );
  }

  Set<String> _getPreviewMoveSqares() {
    final squares = <String>{};
    for (final line in _gambitPreviewLines) {
      if (line.move.length >= 4) {
        final from = line.move.substring(0, 2);
        final to = line.move.substring(2, 4);
        squares.add(from);
        squares.add(to);
      }
    }
    return squares;
  }

  Widget _buildPieceWithGlow(String piece, String? selectedGlowColor) {
    if (selectedGlowColor == null) {
      return _pieceImage(piece);
    }

    final glowColor = selectedGlowColor == 'yellow'
        ? const Color(0xFFFFD166)
        : selectedGlowColor == 'violet'
        ? const Color(0xFFB16CFF)
        : const Color(0xFF5AAEE8);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.7),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: _pieceImage(piece),
    );
  }

  Widget _buildAnimatedArrows(bool reverse) {
    final lines = _gambitPreviewLines.isNotEmpty
        ? _gambitPreviewLines
        : _topLines;
    final showSequenceNumbers = _gambitPreviewLines.isNotEmpty;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: EnergyArrowPainter(
                lines: lines,
                bestEval: (_currentEval * 100).toInt(),
                progress: _pulseController.value,
                reverse: reverse,
                showSequenceNumbers: showSequenceNumbers,
              ),
            ),
            ..._botGhostArrows.map(
              (ghost) => AnimatedOpacity(
                opacity: ghost.opacity,
                duration: const Duration(milliseconds: 3000),
                curve: Curves.easeOut,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: EnergyArrowPainter(
                    lines: [ghost.line],
                    bestEval: 0,
                    progress: 0,
                    reverse: reverse,
                    overrideColor: const Color(0xFF6D7482),
                    staticArrowStyle: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedMovesList({
    double height = 130,
    EdgeInsets padding = const EdgeInsets.symmetric(
      vertical: 10,
      horizontal: 20,
    ),
  }) {
    final showSuggestions =
        _shouldShowVisualSuggestions && _topLines.isNotEmpty;

    return SizedBox(
      height: height,
      child: showSuggestions
          ? SingleChildScrollView(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _topLines.map((l) {
                  String from = l.move.substring(0, 2);
                  String to = l.move.substring(2, 4);
                  String? movingPiece = boardState[from];
                  if (movingPiece == null) return const SizedBox.shrink();
                  String? capturedPiece = boardState[to];
                  bool isCapture = capturedPiece != null;
                  String pieceLetter = movingPiece.startsWith('p')
                      ? ''
                      : movingPiece[0].toUpperCase();
                  String notation = pieceLetter + (isCapture ? 'x' : '') + to;
                  Color color = _getRelativeColorForWidget(l.eval, l.multiPv);
                  double eval = l.eval / 100.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _pieceImage(movingPiece, width: 24, height: 24),
                        const SizedBox(width: 8),
                        Text(
                          notation,
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: l.multiPv == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            shadows: const [
                              Shadow(
                                color: Color(0xFF757575),
                                offset: Offset(0.5, 0.5),
                                blurRadius: 0.8,
                              ),
                              Shadow(
                                color: Color(0xFF757575),
                                offset: Offset(-0.5, 0.5),
                                blurRadius: 0.8,
                              ),
                              Shadow(
                                color: Color(0xFF757575),
                                offset: Offset(0.5, -0.5),
                                blurRadius: 0.8,
                              ),
                              Shadow(
                                color: Color(0xFF757575),
                                offset: Offset(-0.5, -0.5),
                                blurRadius: 0.8,
                              ),
                            ],
                          ),
                        ),
                        if (isCapture) ...[
                          const SizedBox(width: 8),
                          _pieceImage(capturedPiece, width: 20, height: 20),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          eval >= 0
                              ? '+${eval.toStringAsFixed(2)}'
                              : eval.toStringAsFixed(2),
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                color: Color(0xFF757575),
                                offset: Offset(0.5, 0.5),
                                blurRadius: 0.8,
                              ),
                              Shadow(
                                color: Color(0xFF757575),
                                offset: Offset(-0.5, 0.5),
                                blurRadius: 0.8,
                              ),
                              Shadow(
                                color: Color(0xFF757575),
                                offset: Offset(0.5, -0.5),
                                blurRadius: 0.8,
                              ),
                              Shadow(
                                color: Color(0xFF757575),
                                offset: Offset(-0.5, -0.5),
                                blurRadius: 0.8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Color _getRelativeColorForWidget(int currentEval, int multiPv) {
    if (multiPv == 1) return const Color(0xFF00FF88);
    int loss = ((_currentEval * 100).toInt() - currentEval).abs();
    if (loss < 30) return const Color(0xFF00FF88).withValues(alpha: 0.7);
    if (loss < 100) return Colors.yellowAccent;
    if (loss < 250) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildHistoryBar({
    double height = 60,
    EdgeInsets margin = const EdgeInsets.symmetric(vertical: 10),
  }) {
    return Container(
      height: height,
      margin: margin,
      child: ListView.builder(
        controller: _historyScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _moveHistory.length,
        itemBuilder: (context, i) {
          final m = _moveHistory[i];
          bool active = i == _historyIndex;
          return GestureDetector(
            onTap: () => _jumpToMove(i),
            child: _buildHistoryMoveChip(m, active),
          );
        },
      ),
    );
  }

  void _undoBotTurn() {
    if (!_playVsBot || _moveHistory.isEmpty) return;

    _send('stop');
    setState(() {
      _botThinking = false;
      _botSearchCompleter = null;

      int safety = 4;
      do {
        _moveHistory.removeLast();
        _historyIndex = _moveHistory.length - 1;

        if (_moveHistory.isEmpty) {
          boardState = _initialBoardState();
          _isWhiteTurn = true;
          _resetSpecialMoveState();
        } else {
          boardState = Map.from(_moveHistory.last.state);
          _isWhiteTurn = !_moveHistory.last.isWhite;
          _restoreSpecialMoveStateFromRecord(_moveHistory.last);
        }
        safety -= 1;
      } while (_moveHistory.isNotEmpty && !_isHumanTurnInBotGame && safety > 0);

      _currentOpening = _findOpeningFromHistory();
      _holdSelectedFrom = null;
      _gambitSelectedFrom = null;
      _legalTargets.clear();
      _gambitAvailableTargets.clear();
      _selectedGambit = null;
      _gambitPreviewLines = [];
      _openingMode = OpeningMode.off;
      _topLines = [];
      _currentDepth = 0;
      _currentEval = 0.0;
    });

    _analyze();
  }

  Widget _buildBotUndoButton() {
    final enabled = _moveHistory.isNotEmpty;
    return GestureDetector(
      onTap: enabled ? _undoBotTurn : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF173048), Color(0xFF245782)],
            ),
            border: Border.all(
              color: const Color(0xFF7FC4FF).withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5AAEE8).withValues(alpha: 0.28),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.undo_rounded, color: Color(0xFF9ED8FF)),
        ),
      ),
    );
  }

  Widget _buildActionArea({double compactBottom = 20, double horizontal = 20}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: EdgeInsets.only(
        bottom: compactBottom,
        left: horizontal,
        right: horizontal,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconBtn(Icons.refresh, _confirmReset),
          _marketplaceBtn(),
          _buildSuggestionTriggerButton(),
          if (!_playVsBot)
            GestureDetector(
              onTap: _toggleGambitMode,
              child: AnimatedBuilder(
                animation: _openingButtonFlashController,
                builder: (context, child) {
                  final flashProgress = _openingButtonFlashController.value;
                  // Blink: visible for first half, invisible for second half
                  final blink = (flashProgress * 4).floor().isEven;
                  final Color activeColor = _openingButtonFlashRed
                      ? Colors.redAccent
                      : _openingMode == OpeningMode.violetGlow
                      ? const Color(0xFFB16CFF)
                      : _openingMode == OpeningMode.yellowGlow
                      ? const Color(0xFFFFD166)
                      : const Color(0xFF5AAEE8);
                  final bool isOn =
                      _openingButtonFlashRed || _openingMode != OpeningMode.off;
                  final idleBackground = Color.alphaBlend(
                    scheme.primary.withValues(alpha: isLight ? 0.10 : 0.05),
                    scheme.surface,
                  );
                  final idleIconColor = scheme.onSurface.withValues(
                    alpha: isLight ? 0.78 : 0.54,
                  );
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOn
                          ? Color.alphaBlend(
                              activeColor.withValues(
                                alpha: isLight ? 0.18 : 0.10,
                              ),
                              scheme.surface,
                            )
                          : idleBackground,
                      border: Border.all(
                        color: isOn
                            ? activeColor.withValues(
                                alpha: isLight ? 0.56 : 0.36,
                              )
                            : scheme.outline.withValues(
                                alpha: isLight ? 0.38 : 0.24,
                              ),
                      ),
                      boxShadow: isOn
                          ? [
                              BoxShadow(
                                color: activeColor.withValues(
                                  alpha: _openingButtonFlashRed
                                      ? (blink ? 0.7 : 0.0)
                                      : 0.5,
                                ),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: _openingButtonFlashRed
                          ? (blink ? Colors.redAccent : idleIconColor)
                          : _openingMode == OpeningMode.violetGlow
                          ? const Color(0xFFB16CFF)
                          : _openingMode == OpeningMode.yellowGlow
                          ? const Color(0xFFFFD166)
                          : _openingMode == OpeningMode.blueGlow
                          ? const Color(0xFF5AAEE8)
                          : idleIconColor,
                    ),
                  );
                },
              ),
            )
          else
            _buildBotUndoButton(),
          _iconBtn(
            Icons.settings_outlined,
            () => _openSettings(fromAnalysisMode: !_playVsBot),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTriggerButton() {
    if (_isEngineActive) {
      return GestureDetector(
        key: _suggestionButtonKey,
        onTap: () {
          setState(() {
            _suggestionsEnabled = false;
            _topLines = [];
            _currentDepth = 0;
          });
          _send('stop');
        },
        onLongPress: _playVsBot
            ? null
            : () {
                setState(() {
                  _isWhiteTurn = !_isWhiteTurn;
                });
                _analyze();
              },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2A0F13),
            border: Border.all(
              color: const Color(0xFFE06A79).withValues(alpha: 0.75),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE06A79).withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.power_settings_new_rounded,
            color: Color(0xFFFFA3AF),
            size: 22,
          ),
        ),
      );
    }

    return GestureDetector(
      key: _suggestionButtonKey,
      onTap: (!_buttonUnlocked || _suggestionLaunchInProgress)
          ? null
          : () async {
              if (_playVsBot) {
                setState(() {
                  _suggestionsEnabled = true;
                });
                _analyze();
                _addLog(
                  _multiPvCount > 0
                      ? 'Stockfish suggestions activated'
                      : 'Stockfish evaluation activated',
                );
                return;
              }
              if (kIsWeb) {
                _addLog(
                  'Suggestions unavailable on web (engine process not supported).',
                );
                return;
              }
              setState(() {
                _suggestionLaunchInProgress = true;
              });
              // Only show launch animation on first activation (no moves made yet)
              if (_moveHistory.isEmpty) {
                setState(() => _suggestionBurstActive = true);
                await Future<void>.delayed(const Duration(milliseconds: 140));
                if (mounted) setState(() => _suggestionBurstActive = false);
                await _fireSuggestionLaunch();
              } else {
                // Pulse a green ripple from the button position
                final buttonContext = _suggestionButtonKey.currentContext;
                final sceneContext = _sceneKey.currentContext;
                if (buttonContext != null && sceneContext != null) {
                  final buttonBox = _renderBoxFromContext(buttonContext);
                  final sceneBox = _renderBoxFromContext(sceneContext);
                  if (buttonBox != null && sceneBox != null) {
                    final center = sceneBox.globalToLocal(
                      buttonBox.localToGlobal(
                        buttonBox.size.center(Offset.zero),
                      ),
                    );
                    setState(() => _buttonRippleCenter = center);
                    await _buttonRippleController.forward(from: 0);
                    if (mounted) setState(() => _buttonRippleCenter = null);
                  }
                }
              }
              if (!mounted) return;
              setState(() {
                _suggestionLaunchInProgress = false;
                _suggestionsEnabled = true;
              });
              _analyze();
              _addLog(
                _multiPvCount > 0
                    ? 'Stockfish suggestions activated'
                    : 'Stockfish evaluation activated',
              );
            },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _introController,
          _launchController,
        ]),
        builder: (context, child) {
          final buttonOpacity = _buttonIntroOpacity();
          final buttonScale = _buttonIntroScale();

          if (!_introCompleted) {
            final ignition = Curves.easeOut.transform(
              ((_introController.value - 0.78) / 0.22).clamp(0.0, 1.0),
            );
            return Opacity(
              opacity: buttonOpacity,
              child: Transform.scale(
                scale: buttonScale,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.lerp(
                          const Color(0xFF141A25),
                          const Color(0xFF2A6CF0),
                          ignition,
                        )!.withValues(alpha: 0.28 + (0.22 * ignition)),
                        const Color(0xFF0E131D),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(
                        0xFFB9A46A,
                      ).withValues(alpha: 0.28 + 0.18 * ignition),
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF3F6ED8,
                        ).withValues(alpha: 0.12 + (0.22 * ignition)),
                        blurRadius: 14 + (10 * ignition),
                      ),
                      BoxShadow(
                        color: const Color(
                          0xFFD8B640,
                        ).withValues(alpha: 0.08 + (0.18 * ignition)),
                        blurRadius: 18 + (10 * ignition),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 22,
                    color: Colors.white.withValues(
                      alpha: 0.4 + (0.35 * ignition),
                    ),
                  ),
                ),
              ),
            );
          }

          final introT = _introController.value.clamp(0.0, 1.0);
          final pulseT = _pulseController.value;
          final launchT = _suggestionLaunchInProgress
              ? _launchController.value.clamp(0.0, 1.0)
              : 0.0;

          Offset yellow;
          Offset blue;
          double coreIntensity;
          double orbOpacity = 1.0;

          if (introT < 0.32) {
            final p = Curves.easeOutCubic.transform(introT / 0.32);
            yellow = Offset(-6 + (6 * p), -82 + (82 * p));
            blue = Offset(6 - (6 * p), -62 + (62 * p));
            coreIntensity = 0.25 + (0.35 * p);
          } else if (introT < 0.74) {
            final q = (introT - 0.32) / 0.42;
            final radius = (14 - (11 * Curves.easeIn.transform(q))).clamp(
              3.0,
              14.0,
            );
            final fastAngle = q * pi * 2 * 5.5;
            yellow = Offset(cos(fastAngle) * radius, sin(fastAngle) * radius);
            blue = Offset(
              cos(fastAngle + pi) * radius,
              sin(fastAngle + pi) * radius,
            );
            coreIntensity = 0.55 + (0.35 * q);
          } else {
            final launchBurstWindow = Curves.easeOut.transform(
              (launchT / 0.16).clamp(0.0, 1.0),
            );
            final collapseT = Curves.easeIn.transform(
              ((launchT - 0.08) / 0.20).clamp(0.0, 1.0),
            );
            final speedMultiplier = _suggestionBurstActive
                ? 8.0
                : (1.0 + (5.0 * launchBurstWindow));
            final orbit = ui.lerpDouble(11.0, 0.0, collapseT)!;
            final angle = pulseT * pi * 2 * speedMultiplier;
            yellow = Offset(cos(angle) * orbit, sin(angle) * orbit);
            blue = Offset(cos(angle + pi) * orbit, sin(angle + pi) * orbit);
            coreIntensity = 0.9 + (0.2 * launchBurstWindow);
            orbOpacity =
                1.0 -
                Curves.easeIn.transform(
                  ((launchT - 0.06) / 0.18).clamp(0.0, 1.0),
                );
          }

          final ignition = Curves.easeOut.transform(
            ((introT - 0.58) / 0.42).clamp(0.0, 1.0),
          );

          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFF1A2131),
                    const Color(0xFF2A6CF0),
                    ignition,
                  )!.withValues(alpha: 0.6 * coreIntensity),
                  const Color(0xFF101621),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFB9A46A).withValues(alpha: 0.45),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF3F6ED8,
                  ).withValues(alpha: 0.25 + 0.25 * coreIntensity),
                  blurRadius: 14 + (8 * coreIntensity),
                ),
                BoxShadow(
                  color: const Color(
                    0xFFD8B640,
                  ).withValues(alpha: 0.18 + 0.22 * coreIntensity),
                  blurRadius: 18 + (10 * coreIntensity),
                ),
                if (_suggestionLaunchInProgress)
                  BoxShadow(
                    color: const Color(0xFF7EDC8A).withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: orbOpacity,
                  child: Transform.translate(
                    offset: yellow,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8B640),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD8B640,
                            ).withValues(alpha: 0.7 * orbOpacity),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: orbOpacity,
                  child: Transform.translate(
                    offset: blue,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F6ED8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3F6ED8,
                            ).withValues(alpha: 0.7 * orbOpacity),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.bolt_rounded,
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.55 + 0.35 * ignition),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _marketplaceBtn() {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      key: _storeButtonKey,
      child: IconButton(
        onPressed: _openStore,
        icon: Icon(Icons.storefront_outlined, color: scheme.onSurface),
        style: IconButton.styleFrom(
          backgroundColor: Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.07),
            scheme.surface,
          ),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.36)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData i, VoidCallback fn) => IconButton(
    onPressed: fn,
    icon: Icon(i, color: Theme.of(context).colorScheme.onSurface),
    style: IconButton.styleFrom(
      backgroundColor: Color.alphaBlend(
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
        Theme.of(context).colorScheme.surface,
      ),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.36),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  void _showLogsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Internal Logs'),
        content: SizedBox(
          width: double.maxFinite,
          child: _logs.isEmpty
              ? const Text('No logs yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) =>
                      Text(_logs[index], style: const TextStyle(fontSize: 12)),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              final text = _logs.join('\n');
              Clipboard.setData(ClipboardData(text: text));
              Navigator.of(context).pop();
              _addLog('Logs copied to clipboard (count=${_logs.length})');
            },
            child: const Text('Copy all'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreditsDialog() async {
    setState(() {
      _creditsDialogOpen = true;
      _initializeCreditsBackdrop();
    });

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          final openedFromAnalysis = _activeSection == AppSection.analysis;
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;
          final useMonochrome =
              context.watch<AppThemeProvider>().isMonochrome ||
              _isCinematicThemeEnabled;
          final dialogSurface = useMonochrome
              ? scheme.surface
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: isDark ? 0.10 : 0.04),
                  scheme.surface,
                );
          final dialogAccent = useMonochrome
              ? Color.alphaBlend(
                  scheme.onSurface.withValues(alpha: 0.12),
                  scheme.surface,
                )
              : Color.alphaBlend(
                  scheme.secondary.withValues(alpha: isDark ? 0.10 : 0.05),
                  scheme.surface,
                );
          final dialogHeadingAccent = useMonochrome
              ? scheme.onSurface.withValues(alpha: 0.92)
              : scheme.secondary;
          final legalAccent = useMonochrome
              ? scheme.onSurface.withValues(alpha: 0.92)
              : scheme.secondary;
          final thirdPartyAccent = useMonochrome
              ? scheme.onSurface.withValues(alpha: 0.92)
              : scheme.primary;
          final licenseAccent = useMonochrome
              ? scheme.onSurface.withValues(alpha: 0.92)
              : const Color(0xFFD8B640);
          final dialogHeight = min(
            MediaQuery.of(context).size.height * 0.82,
            700.0,
          );
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: dialogHeight,
              ),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [dialogSurface, dialogAccent],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: _buildCreditsDynamicBackdrop()),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: scheme.onSurface.withValues(alpha: 0.72),
                            ),
                            tooltip: 'Close credits',
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.22),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: useMonochrome
                                ? [
                                    scheme.surface.withAlpha(0xEE),
                                    Color.alphaBlend(
                                      scheme.onSurface.withValues(alpha: 0.06),
                                      scheme.surface,
                                    ),
                                  ]
                                : [
                                    scheme.primary.withValues(alpha: 0.10),
                                    scheme.secondary.withValues(alpha: 0.05),
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: useMonochrome
                                  ? scheme.onSurface.withValues(alpha: 0.08)
                                  : scheme.primary.withValues(alpha: 0.12),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/QILAmodus.png',
                          width: 260,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Credits, Data & Legal',
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withValues(alpha: 0.74),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildCreditRow(
                                'Product & Direction',
                                'QILA modus',
                              ),
                              _buildCreditRow(
                                'Engineering & Design',
                                'QILA modus',
                              ),
                              _buildCreditRow(
                                'Chess Engine',
                                'Stockfish (GPL-3.0)',
                              ),
                              _buildCreditRow(
                                'Puzzle Data',
                                'Lichess puzzle database (CC0)',
                              ),
                              _buildCreditRow('Opening Data', 'ECO data (MIT)'),
                              _buildCreditRow(
                                'Audio',
                                'Freesound and Floraphonic effects',
                              ),
                              _buildCreditRow('Platform', 'Flutter / Dart'),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.alphaBlend(
                                        scheme.primary.withValues(alpha: 0.10),
                                        scheme.surface,
                                      ),
                                      Color.alphaBlend(
                                        scheme.secondary.withValues(
                                          alpha: 0.06,
                                        ),
                                        scheme.surface,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scheme.outline.withValues(
                                      alpha: 0.26,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.18 : 0.06,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified_outlined,
                                          size: 16,
                                          color: dialogHeadingAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Ownership & Legal',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                            color: dialogHeadingAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ChessIQ is developed by QILA modus (a division of Qila). Original code, design, and project-specific assets are owned by Qila (CVR no. 42666297).',
                                      style: TextStyle(
                                        fontSize: 12.2,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.86,
                                        ),
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildLegalNoticeLink(
                                          label: 'Copyright Notice',
                                          icon: Icons.copyright_rounded,
                                          accent: legalAccent,
                                          onTap: () => _showLegalNoticeDialog(
                                            title: 'COPYRIGHT.md',
                                            assetPath: 'COPYRIGHT.md',
                                            accent: legalAccent,
                                          ),
                                        ),
                                        _buildLegalNoticeLink(
                                          label: 'Third-Party Notices',
                                          icon: Icons.policy_outlined,
                                          accent: thirdPartyAccent,
                                          onTap: () => _showLegalNoticeDialog(
                                            title: 'THIRD_PARTY_NOTICES.md',
                                            assetPath: 'THIRD_PARTY_NOTICES.md',
                                            accent: thirdPartyAccent,
                                          ),
                                        ),
                                        _buildLegalNoticeLink(
                                          label: 'License',
                                          icon: Icons.gavel_rounded,
                                          accent: licenseAccent,
                                          onTap: () => _showLegalNoticeDialog(
                                            title: 'LICENSE',
                                            assetPath: 'LICENSE',
                                            accent: licenseAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _showLogsDialog,
                                  icon: const Icon(Icons.bug_report_outlined),
                                  label: const Text('View Logs'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: dialogHeadingAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (!openedFromAnalysis) {
                              _goToMenu();
                            }
                          },
                          child: Text(
                            openedFromAnalysis ? 'Close' : 'Back to Main Menu',
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
    } finally {
      if (mounted) {
        setState(() {
          _creditsDialogOpen = false;
          _creditsBackdropDots.clear();
          _blueYellowContactTime = 0.0;
          _creditsBackdropLastUpdate = null;
        });
      } else {
        _creditsDialogOpen = false;
        _creditsBackdropDots.clear();
        _blueYellowContactTime = 0.0;
        _creditsBackdropLastUpdate = null;
      }
    }
  }

  Widget _buildLegalNoticeLink({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent.withValues(alpha: 0.38)),
        backgroundColor: accent.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 11.7, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _showLegalNoticeDialog({
    required String title,
    required String assetPath,
    required Color accent,
  }) async {
    final scrollController = ScrollController();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final appTheme = context.watch<AppThemeProvider>();
          final useMonochrome =
              appTheme.isMonochrome || _isCinematicThemeEnabled;
          final theme = Theme.of(dialogContext);
          final scheme = theme.colorScheme;
          final isLightTheme = theme.brightness == Brightness.light;
          final noticeHasLightSurface = useMonochrome || isLightTheme;
          final dialogHeight = min(
            MediaQuery.of(dialogContext).size.height * 0.86,
            760.0,
          );
          final dialogAccentColor = useMonochrome
              ? scheme.onSurface.withValues(alpha: 0.92)
              : accent;
          final dialogBackgroundStart = noticeHasLightSurface
              ? scheme.surface
              : const Color(0xFF071429);
          final dialogBackgroundEnd = noticeHasLightSurface
              ? Color.alphaBlend(
                  scheme.onSurface.withValues(alpha: 0.06),
                  scheme.surface,
                )
              : const Color(0xFF040D1D);
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 700,
                maxHeight: dialogHeight,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [dialogBackgroundStart, dialogBackgroundEnd],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dialogAccentColor.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.42),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: accent.withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: dialogAccentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: dialogAccentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.2,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: Icon(
                            Icons.close,
                            color: scheme.onSurface.withValues(alpha: 0.72),
                          ),
                          tooltip: 'Close legal notice',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: _loadLegalNoticeText(assetPath),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              'Unable to load this notice from app assets.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12.2,
                              ),
                            ),
                          );
                        }

                        final lines = const LineSplitter().convert(
                          snapshot.data!.replaceAll('\r\n', '\n'),
                        );
                        return Scrollbar(
                          controller: scrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            itemCount: lines.length,
                            itemBuilder: (context, index) {
                              final line = lines[index];
                              final trimmed = line.trim();

                              if (trimmed.isEmpty) {
                                return const SizedBox(height: 10);
                              }
                              if (trimmed.startsWith('### ')) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    trimmed.substring(4),
                                    style: TextStyle(
                                      color: dialogAccentColor.withValues(
                                        alpha: 0.95,
                                      ),
                                      fontSize: 13.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }
                              if (trimmed.startsWith('## ')) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Text(
                                    trimmed.substring(3),
                                    style: TextStyle(
                                      color: dialogAccentColor.withValues(
                                        alpha: 0.97,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );
                              }
                              if (trimmed.startsWith('# ')) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    trimmed.substring(2),
                                    style: TextStyle(
                                      color: dialogAccentColor,
                                      fontSize: 15.2,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                );
                              }

                              if (trimmed.startsWith('- ') ||
                                  trimmed.startsWith('* ')) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 6,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          color: dialogAccentColor.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 12.6,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Expanded(
                                        child: SelectableText(
                                          trimmed.substring(2),
                                          style: TextStyle(
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.88,
                                            ),
                                            fontSize: 12.35,
                                            height: 1.42,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: SelectableText(
                                  line,
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.86,
                                    ),
                                    fontSize: 12.3,
                                    height: 1.42,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: dialogAccentColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Done'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      scrollController.dispose();
    }
  }

  Future<String> _loadLegalNoticeText(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (_) {
      if (!kIsWeb) {
        final candidates = <String>{
          assetPath,
          '${Directory.current.path}${Platform.pathSeparator}$assetPath',
        };
        for (final path in candidates) {
          final file = File(path);
          if (await file.exists()) {
            return file.readAsString();
          }
        }
      }
      throw Exception('Unable to load legal notice: $assetPath');
    }
  }

  Widget _buildCreditsDynamicBackdrop() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value;
        final coreNodes = <({double x, double y, Color color})>[
          (x: 0.16 + 0.02 * sin(t * pi * 2), y: 0.22, color: scheme.primary),
          (x: 0.34, y: 0.35 + 0.02 * cos(t * pi * 2), color: scheme.secondary),
          (x: 0.58 + 0.015 * cos(t * pi * 2), y: 0.24, color: scheme.primary),
          (x: 0.78, y: 0.38 + 0.02 * sin(t * pi * 2), color: scheme.tertiary),
          (x: 0.28, y: 0.68, color: scheme.secondary),
          (x: 0.56 + 0.02 * sin(t * pi * 2), y: 0.58, color: scheme.primary),
          (x: 0.82, y: 0.70, color: scheme.tertiary),
        ];

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                        scheme.surface.withValues(alpha: 0.94),
                        scheme.secondary.withValues(
                          alpha: isDark ? 0.08 : 0.04,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              for (final line
                  in <
                    ({
                      Alignment alignment,
                      double width,
                      double rotation,
                      Color color,
                    })
                  >[
                    (
                      alignment: const Alignment(-0.18, -0.26),
                      width: 150,
                      rotation: -0.18,
                      color: scheme.primary,
                    ),
                    (
                      alignment: const Alignment(0.22, -0.06),
                      width: 170,
                      rotation: 0.12,
                      color: scheme.secondary,
                    ),
                    (
                      alignment: const Alignment(-0.04, 0.28),
                      width: 140,
                      rotation: -0.42,
                      color: scheme.tertiary,
                    ),
                    (
                      alignment: const Alignment(0.38, 0.34),
                      width: 128,
                      rotation: 0.36,
                      color: scheme.primary,
                    ),
                  ])
                Positioned.fill(
                  child: Align(
                    alignment: line.alignment,
                    child: Transform.rotate(
                      angle: line.rotation,
                      child: Container(
                        width: line.width,
                        height: 1.2,
                        decoration: BoxDecoration(
                          color: line.color.withValues(
                            alpha: isDark ? 0.18 : 0.10,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: line.color.withValues(
                                alpha: isDark ? 0.12 : 0.06,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              for (final node in coreNodes)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(node.x * 2 - 1, node.y * 2 - 1),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: node.color.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: node.color.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              for (final dot in _creditsBackdropDots)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(dot.position.dx, dot.position.dy),
                    child: Container(
                      width: dot.radius * 2,
                      height: dot.radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dot.color.withValues(alpha: 0.16),
                        boxShadow: [
                          BoxShadow(
                            color: dot.color.withValues(alpha: 0.28),
                            blurRadius: dot.radius * 3,
                            spreadRadius: dot.radius * 0.8,
                          ),
                        ],
                      ),
                      child: dot.role == _CreditsBackdropDotRole.green
                          ? Center(
                              child: Container(
                                width: dot.radius,
                                height: dot.radius,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dot.color,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surface.withValues(alpha: 0.02),
                        scheme.surface.withValues(alpha: isDark ? 0.14 : 0.08),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreditRow(String role, String name) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              role,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: scheme.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final useMonochrome =
            context.watch<AppThemeProvider>().isMonochrome ||
            _isCinematicThemeEnabled;
        final isVsBot = _playVsBot;
        final dialogSurface = useMonochrome
            ? scheme.surface
            : Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.10),
                scheme.surface,
              );
        final dialogAccent = useMonochrome
            ? Color.alphaBlend(
                scheme.onSurface.withValues(alpha: 0.08),
                scheme.surface,
              )
            : Color.alphaBlend(
                scheme.secondary.withValues(alpha: 0.10),
                scheme.surface,
              );
        final buttonPrimarySurface = useMonochrome
            ? scheme.onSurface.withValues(alpha: 0.12)
            : scheme.primary;
        final buttonSecondary = useMonochrome
            ? scheme.onSurface.withValues(alpha: 0.92)
            : scheme.secondary;
        final buttonBackground = useMonochrome
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.85)
            : scheme.surfaceContainerHighest;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [dialogSurface, dialogAccent],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.52),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: scheme.onSurface.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Return Menu',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop('reset'),
                      style: FilledButton.styleFrom(
                        backgroundColor: buttonPrimarySurface,
                        foregroundColor: scheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            padding: const EdgeInsets.all(1),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: _boardThemeSwatch(_boardThemeMode),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('Reset Board'),
                        ],
                      ),
                    ),
                  ),
                  if (isVsBot) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop('opponent'),
                        style: FilledButton.styleFrom(
                          backgroundColor: buttonSecondary.withValues(
                            alpha: 0.18,
                          ),
                          foregroundColor: buttonSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: Icon(
                          Icons.smart_toy_outlined,
                          size: 18,
                          color: buttonSecondary,
                        ),
                        label: Text('New Opponent'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop('menu'),
                      style: FilledButton.styleFrom(
                        backgroundColor: buttonBackground,
                        foregroundColor: scheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: Icon(
                        Icons.menu_rounded,
                        size: 18,
                        color: scheme.onSurface,
                      ),
                      label: Text('Main Menu'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                        side: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.38),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (result == 'reset') {
      // Let the return menu fully dismiss before presenting the sponsored break.
      await Future<void>.delayed(Duration.zero);
      await _performResetWithSponsoredBreak();
    } else if (result == 'opponent') {
      _openBotSetupFromMenu();
    } else if (result == 'menu') {
      _goToMenu();
    }
  }

  void _openAppearanceSettings() {
    _openSettings(
      fromAnalysisMode: _activeSection == AppSection.analysis && !_playVsBot,
    );
  }

  Future<void> _openSettings({
    bool isAcademyMode = false,
    bool fromAnalysisMode = false,
  }) async {
    final themeProvider = context.read<AppThemeProvider>();
    final isBoardAnalysisPage =
        _activeSection == AppSection.analysis && !_playVsBot;
    final isVsBotPage = _playVsBot;
    final showBoardPerspectiveSection =
        !isAcademyMode && fromAnalysisMode && isBoardAnalysisPage;
    final showEngineControlsSection =
        !isAcademyMode && (isBoardAnalysisPage || isVsBotPage);

    await showUniversalSettingsSheet(
      context: context,
      title: 'Settings',
      isAcademyMode: isAcademyMode,
      themeMode: themeProvider.themeMode,
      themeStyle: themeProvider.themeStyle,
      onThemeModeChanged: (mode) async {
        await themeProvider.setThemeMode(mode);
      },
      onThemeStyleChanged: (style) async {
        await _setCinematicThemeEnabled(style == AppThemeStyle.monochrome);
      },
      soundEnabled: !_muteSounds,
      hapticsEnabled: _hapticsEnabled,
      onSoundEnabledChanged: (enabled) async {
        await _setMute(!enabled);
      },
      onHapticsEnabledChanged: (enabled) async {
        await _setHapticsEnabled(enabled);
      },
      boardThemeSelectorBuilder: (setSheetState) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _availableBoardThemes
              .map((mode) => _boardThemeOption(mode, setSheetState))
              .toList(),
        );
      },
      pieceThemeSelectorBuilder: (setSheetState) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _availablePieceThemes
              .map((mode) => _pieceThemeOption(mode, setSheetState))
              .toList(),
        );
      },
      showBoardPerspectiveSection: showBoardPerspectiveSection,
      boardPerspectiveSectionBuilder: showBoardPerspectiveSection
          ? (setSheetState) {
              final theme = Theme.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Board Perspective',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _perspectiveOption(
                        'White',
                        BoardPerspective.white,
                        setSheetState,
                      ),
                      _perspectiveOption(
                        'Black',
                        BoardPerspective.black,
                        setSheetState,
                      ),
                      _perspectiveOption(
                        'Auto',
                        BoardPerspective.auto,
                        setSheetState,
                      ),
                    ],
                  ),
                ],
              );
            }
          : null,
      showEngineControlsSection: showEngineControlsSection,
      engineDepth: _engineDepth,
      maxEngineDepth: _maxDepthAllowed,
      suggestedMoves: _multiPvCount,
      maxSuggestedMoves: _maxSuggestionsAllowed,
      onEngineDepthChanged: (value) {
        setState(() => _engineDepth = value);
        _analyze();
      },
      onEngineDepthChangeEnd: (value) {
        setState(() => _engineDepth = value);
        _persistCurrentSettings();
      },
      onSuggestedMovesChanged: (value) {
        _applySuggestionCount(value);
      },
      onSuggestedMovesChangeEnd: (value) {
        _applySuggestionCount(value, persist: true);
      },
      extraSectionsBuilder: (sheetContext, setSheetState) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;
        final sectionColor = Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.06),
          scheme.surface,
        );
        final borderColor = scheme.outline.withValues(alpha: 0.24);

        final hasAllThemes =
            _availableBoardThemes.length >= BoardThemeMode.values.length &&
            _availablePieceThemes.length >= PieceThemeMode.values.length;
        final hasAllStockfishUpgrades =
            _depthTier >= 3 && _maxSuggestionsAllowed >= 10;

        if (hasAllThemes && hasAllStockfishUpgrades) {
          return const <Widget>[];
        }

        final storeButtonLabel = hasAllThemes
            ? 'Open Stockfish Upgrades'
            : 'Open Theme Store';
        final storeButtonIcon = hasAllThemes
            ? Icons.upgrade_rounded
            : Icons.auto_awesome_rounded;
        final initialStoreSection = hasAllThemes
            ? StoreSection.general
            : StoreSection.themes;

        return <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sectionColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Future.microtask(
                  () => _openStore(initialSection: initialStoreSection),
                );
              },
              icon: Icon(storeButtonIcon, size: 18),
              label: Text(storeButtonLabel),
            ),
          ),
        ];
      },
    );
  }

  Future<void> _saveCurrentAsDefaultSnapshot({bool logChange = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'perspective': _perspective.index,
      'boardTheme': _boardThemeMode.index,
      'pieceTheme': _pieceThemeMode.index,
      'engineDepth': _engineDepth,
      'multiPvCount': _multiPvCount,
      'isWhiteTurn': _isWhiteTurn,
      'whiteKingMoved': _whiteKingMoved,
      'blackKingMoved': _blackKingMoved,
      'whiteKingsideRookMoved': _whiteKingsideRookMoved,
      'whiteQueensideRookMoved': _whiteQueensideRookMoved,
      'blackKingsideRookMoved': _blackKingsideRookMoved,
      'blackQueensideRookMoved': _blackQueensideRookMoved,
      'enPassantTarget': _enPassantTarget,
      'suggestionsEnabled': _suggestionsEnabled,
      'currentEval': _currentEval,
      'currentDepth': _currentDepth,
      'evalWhiteTurn': _evalWhiteTurn,
      'currentOpening': _selectedGambit?.name ?? _currentOpening,
      'boardState': boardState,
      'historyIndex': _historyIndex,
      'moveHistory': _moveHistory.map(_moveRecordToMap).toList(),
      'topLines': _topLines.map((line) => line.toMap()).toList(),
      'gambitPreviewLines': _gambitPreviewLines
          .map((line) => line.toMap())
          .toList(),
    };
    await prefs.setString(_savedDefaultSnapshotKey, jsonEncode(payload));
    if (logChange) {
      _addLog('Current position and settings saved as default');
    }
  }

  String _depthTierLabel() {
    switch (_depthTier) {
      case 1:
        return 'Pro';
      case 2:
        return 'Expert';
      case 3:
        return 'Grandmaster';
      case 4:
        return 'Oracle';
      default:
        return 'Pro';
    }
  }

  Future<void> _purchaseDepthTier(int targetTier) async {
    final price = switch (targetTier) {
      2 => 2600,
      3 => 4200,
      4 => 6200,
      _ => 0,
    };
    if (targetTier <= _depthTier || targetTier < 2 || targetTier > 4) return;
    if (targetTier != _depthTier + 1) {
      _addLog('Unlock tiers in order: Pro -> Expert -> Grandmaster -> Oracle');
      return;
    }
    final economy = context.read<EconomyProvider>();
    if (!await economy.spendCoins(price)) {
      _addLog('Not enough coins for ${_depthTierLabel()} upgrade');
      return;
    }

    setState(() {
      _depthTier = targetTier;
      _engineDepth = _engineDepth.clamp(10, _maxDepthAllowed);
    });
    await _saveStoreState();
    _analyze();
    _addLog(
      'Depth tier unlocked: ${_depthTierLabel()} (max depth $_maxDepthAllowed)',
    );
  }

  Future<void> _purchaseExtraSuggestion() async {
    if (_maxSuggestionsAllowed >= 10) {
      _addLog('Extra suggestions already maxed');
      return;
    }
    final price = 500 + (_extraSuggestionPurchases * 120);
    final economy = context.read<EconomyProvider>();
    if (!await economy.spendCoins(price)) {
      _addLog('Not enough coins for +1 suggestion');
      return;
    }

    setState(() {
      _extraSuggestionPurchases += 1;
    });
    await _saveStoreState();
    _addLog('Suggestions increased to $_maxSuggestionsAllowed');
  }

  Future<void> _purchaseThemePack() async {
    const price = 900;
    if (_themePackOwned) return;
    final economy = context.read<EconomyProvider>();
    if (!await economy.spendCoins(price)) {
      _addLog('Not enough coins for Theme Pack');
      return;
    }
    setState(() {
      _themePackOwned = true;
    });
    await _saveStoreState();
    _addLog('Theme Pack unlocked');
  }

  Future<void> _purchasePiecePack() async {
    const price = 1400;
    if (_piecePackOwned) return;
    final economy = context.read<EconomyProvider>();
    if (!await economy.spendCoins(price)) {
      _addLog('Not enough coins for Piece Set Pack');
      return;
    }
    setState(() {
      _piecePackOwned = true;
    });
    await _saveStoreState();
    _addLog('Piece Set Pack unlocked (Ember and Frost styles available)');
  }

  Future<void> _purchaseSpectral() async {
    const price = 2900;
    if (_spectralOwned) return;
    final economy = context.read<EconomyProvider>();
    if (!await economy.spendCoins(price)) {
      _addLog('Not enough coins for Spectral pieces');
      return;
    }
    setState(() {
      _spectralOwned = true;
    });
    await _saveStoreState();
    _addLog('Spectral pieces unlocked');
  }

  Future<void> _purchaseTuttiFrutti() async {
    const price = 1000;
    if (_tuttiFruttiOwned) return;
    final economy = context.read<EconomyProvider>();
    if (!await economy.spendCoins(price)) {
      _addLog('Not enough coins for Tutti Frutti pieces');
      return;
    }
    setState(() {
      _tuttiFruttiOwned = true;
    });
    await _saveStoreState();
    _addLog('Tutti Frutti pieces unlocked');
  }

  Future<void> _purchaseSakuraBoard() async {
    const price = 700;
    if (_sakuraBoardOwned) return;
    final economy = context.read<EconomyProvider>();
    if (!await economy.spendCoins(price)) {
      _addLog('Not enough coins for Sakura board');
      return;
    }
    setState(() {
      _sakuraBoardOwned = true;
    });
    await _saveStoreState();
    _addLog('Sakura board unlocked');
  }

  Future<void> _purchaseTropicalBoard() async {
    const price = 700;
    if (_tropicalBoardOwned) return;
    final economy = context.read<EconomyProvider>();
    if (!await economy.spendCoins(price)) {
      _addLog('Not enough coins for Tropical board');
      return;
    }
    setState(() {
      _tropicalBoardOwned = true;
    });
    await _saveStoreState();
    _addLog('Tropical board unlocked');
  }

  Future<void> _performResetWithSponsoredBreak() async {
    final adService = AdService.instance;
    final shouldAttemptAd =
        !_adFreeOwned && adService.boardResetCooldownRemaining == Duration.zero;
    if (shouldAttemptAd) {
      final shown = await adService.maybeShowBoardResetInterstitial();
      if (!shown) {
        _addLog('Reset interstitial unavailable; continuing without ad');
      } else {
        await _handleAnalysisInterstitialShown();
      }
    }
    if (!mounted) return;
    setState(() {
      _resetBoard();
      _analyze();
    });
    _persistAnalysisSnapshotIfNeeded();
    unawaited(_maybeTriggerBotMove());
  }

  Future<void> _watchRewardAdFromStore() async {
    if (!mounted) return;
    final economy = context.read<EconomyProvider>();
    if (!economy.canClaimStoreReward) {
      return;
    }

    final rewardEarned = await AdService.instance.showRewardedAd();
    if (!mounted) return;
    if (!rewardEarned) {
      await _showThemedErrorDialog(
        title: 'Ad Unavailable',
        message: 'Rewarded ad is unavailable or was not completed.',
        includeInternetHint: true,
      );
      _addLog('Rewarded store ad unavailable or not completed');
      return;
    }

    final claimed = await economy.claimStoreRewardAd();
    if (!claimed) {
      return;
    }

    setState(() {});
    unawaited(_playCoinRewardSound());
    await _saveStoreState();
    _addLog('Reward ad claimed (+120 coins)');
  }

  Future<void> _buyCoinPack(int amount, String label) async {
    final productId = amount == IapProducts.coinPackSAmount
        ? IapProducts.coinPackS
        : IapProducts.coinPackL;

    final success = await PurchaseService.instance.buy(productId);
    if (!success || !mounted) return;

    // EconomyProvider was already credited by PurchaseService._deliver().
    if (label == 'Coin Pack L') {
      unawaited(_playCoinBagSoundL());
    } else {
      unawaited(_playCoinBagSound());
    }
    await _saveStoreState();
    _addLog('Purchased $label (+$amount coins)');
  }

  Future<void> _buyAdFree() async {
    if (_adFreeOwned) return;

    final success = await PurchaseService.instance.buy(
      IapProducts.resetBoardPass,
    );
    if (!success || !mounted) return;

    _adFreeOwned = true;
    await _saveStoreState();
    _addLog('Reset Board No-Ad Pass activated');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Purchase Complete'),
        content: const Text('Reset Board No-Ad Pass activated.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _buyAcademyTuitionPass() async {
    if (_academyTuitionPassOwned) return;

    final success = await PurchaseService.instance.buy(IapProducts.academyPass);
    if (!success || !mounted) return;

    _academyTuitionPassOwned = true;
    await _saveStoreState();
    _addLog('Academy Tuition Pass activated');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Purchase Complete'),
        content: const Text('Academy Tuition Pass activated.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPurchases() async {
    final economy = context.read<EconomyProvider>();
    setState(() {
      _depthTier = 1;
      _extraSuggestionPurchases = 0;
      _themePackOwned = false;
      _sakuraBoardOwned = false;
      _tropicalBoardOwned = false;
      _tuttiFruttiOwned = false;
      _spectralOwned = false;
      _piecePackOwned = false;
      _adFreeOwned = false;
      _academyTuitionPassOwned = false;
      _perspective = _defaultPerspective;
      _boardThemeMode = _defaultBoardTheme;
      _pieceThemeMode = _defaultPieceTheme;
      _engineDepth = _engineDepth.clamp(10, _maxDepthAllowed);
      _multiPvCount = _multiPvCount.clamp(0, _maxSuggestionsAllowed);
      if (_multiPvCount >
          _defaultMultiPvCount.clamp(0, _maxSuggestionsAllowed)) {
        _multiPvCount = _defaultMultiPvCount.clamp(0, _maxSuggestionsAllowed);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedDefaultSnapshotKey);
    await economy.reset(clearStoreRewardCooldown: true, notify: false);
    await _saveStoreState();
    _send('setoption name MultiPV value $_effectiveMultiPvCount');
    _analyze();
    _addLog('Store purchases and saved settings reset');
  }

  Future<void> _openStore({
    StoreSection initialSection = StoreSection.general,
  }) async {
    await _loadStoreState();
    if (!mounted) return;

    Timer? rewardCooldownTicker;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setL) {
          rewardCooldownTicker ??= Timer.periodic(const Duration(seconds: 1), (
            _,
          ) {
            if (!ctx.mounted) {
              rewardCooldownTicker?.cancel();
              return;
            }
            setL(() {});
          });
          final themePackCardKey = GlobalKey();
          final piecePackCardKey = GlobalKey();
          Future<void> scrollToPack(GlobalKey key) async {
            final targetContext = key.currentContext;
            if (targetContext != null) {
              await Scrollable.ensureVisible(
                targetContext,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }

          final theme = Theme.of(ctx);
          final scheme = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;
          final economy = ctx.watch<EconomyProvider>();
          final useMonochrome =
              ctx.watch<AppThemeProvider>().isMonochrome ||
              _isCinematicThemeEnabled;
          final rewardAdRemaining = economy.remainingStoreRewardCooldown;
          final canWatchRewardAd = economy.canClaimStoreReward;
          final lockedUntilTomorrow = economy.storeRewardLockedUntilTomorrow;
          final storeCoins = economy.coins;
          final sheetSurface = useMonochrome
              ? (isDark ? const Color(0xFF050505) : Colors.white)
              : scheme.surface;
          final pillSurface = Color.alphaBlend(
            scheme.primary.withValues(alpha: isDark ? 0.10 : 0.04),
            sheetSurface,
          );

          return ColoredBox(
            color: sheetSurface,
            child: SafeArea(
              top: false,
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.outline.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Store',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                              if (initialSection == StoreSection.themes)
                                Text(
                                  'Themes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.62,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: pillSurface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: scheme.outline.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Text(
                            'Coins: $storeCoins',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFFFD166)
                                  : const Color(0xFF8A6700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            await _openSettings();
                            if (!ctx.mounted) return;
                            setL(() {});
                          },
                          color: scheme.onSurface,
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: 'Settings',
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).maybePop(),
                          color: scheme.onSurface,
                          icon: const Icon(Icons.close),
                          tooltip: 'Close store',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _storeSectionHeader(
                      'Essentials',
                      'Coins, unlocks, and analysis upgrades',
                    ),
                    _storeItemCard(
                      icon: Icons.ondemand_video_outlined,
                      title: 'Watch Ad For Coins',
                      subtitle: canWatchRewardAd
                          ? 'Watch and earn +120 coins'
                          : lockedUntilTomorrow
                          ? 'Come back tomorrow for +120 coins'
                          : 'Earn +120 coins (cooldown active)',
                      priceLabel: 'Free',
                      enabled: canWatchRewardAd,
                      preview: canWatchRewardAd
                          ? null
                          : _buildStoreRewardCooldownPreview(
                              rewardAdRemaining,
                              lockedUntilTomorrow: lockedUntilTomorrow,
                              useMonochrome: useMonochrome,
                            ),
                      actionLabel: canWatchRewardAd ? 'Watch' : 'Cooldown',
                      actionColor: canWatchRewardAd
                          ? const Color(0xFF5AAEE8)
                          : const Color(0xFF6B7280),
                      onTap: () async {
                        await _watchRewardAdFromStore();
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.monetization_on_outlined,
                      title: 'Coin Pack S',
                      subtitle: '+1,500 coins',
                      priceLabel: '\$4.99',
                      enabled: true,
                      actionLabel: 'Buy',
                      actionColor: const Color(0xFF7EDC8A),
                      onTap: () async {
                        await _buyCoinPack(1500, 'Coin Pack S');
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Coin Pack L',
                      subtitle: '+5,000 coins',
                      priceLabel: '\$9.99',
                      enabled: true,
                      actionLabel: 'Buy',
                      actionColor: const Color(0xFF7EDC8A),
                      onTap: () async {
                        await _buyCoinPack(5000, 'Coin Pack L');
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.block_outlined,
                      title: 'Reset Board No-Ad Pass',
                      subtitle: _adFreeOwned
                          ? 'Owned (skips ad after tapping board resets)'
                          : 'Skips the ad that plays after board resets',
                      priceLabel: '\$6.99',
                      enabled: !_adFreeOwned,
                      actionLabel: _adFreeOwned ? 'Owned' : 'Buy',
                      actionColor: const Color(0xFF7EDC8A),
                      onTap: () async {
                        await _buyAdFree();
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.school_outlined,
                      title: 'Academy Tuition Pass',
                      subtitle: _academyTuitionPassOwned
                          ? 'Owned (academy progression without ads)'
                          : 'Skips academy brain-break and daily reward ads',
                      priceLabel: '\$6.99',
                      enabled: !_academyTuitionPassOwned,
                      actionLabel: _academyTuitionPassOwned ? 'Owned' : 'Buy',
                      actionColor: const Color(0xFF7EDC8A),
                      onTap: () async {
                        await _buyAcademyTuitionPass();
                        setL(() {});
                      },
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.restore),
                        label: const Text('Restore Purchases'),
                        onPressed: () async {
                          await PurchaseService.instance.restorePurchases();
                          await _loadStoreState();
                          setL(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    _storeSectionHeader(
                      'Themes',
                      'Owned themes live here, and new ones unlock below',
                    ),
                    _buildThemeVaultCard(
                      setL,
                      onBoardThemeUnlockTap: () =>
                          scrollToPack(themePackCardKey),
                      onPieceThemeUnlockTap: () =>
                          scrollToPack(piecePackCardKey),
                    ),
                    _storeItemCard(
                      itemKey: themePackCardKey,
                      icon: Icons.palette_outlined,
                      title: 'Board Theme Pack',
                      subtitle: _themePackOwned
                          ? 'Owned · unlocks Ember and Sea boards'
                          : 'Unlock Ember and Sea board palettes',
                      priceLabel: '900 c',
                      enabled: !_themePackOwned,
                      actionLabel: _themePackOwned ? 'Owned' : 'Buy',
                      actionColor: const Color(0xFFD8B640),
                      preview: _themePackPreview(),
                      onTap: () async {
                        await _purchaseThemePack();
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.local_florist_outlined,
                      title: 'Sakura Board',
                      subtitle: _sakuraBoardOwned
                          ? 'Owned'
                          : 'Unlock Sakura board palette',
                      priceLabel: '700 c',
                      enabled: !_sakuraBoardOwned,
                      actionLabel: _sakuraBoardOwned ? 'Owned' : 'Buy',
                      actionColor: const Color(0xFFD8B640),
                      preview: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: _boardThemeSwatch(BoardThemeMode.sakura),
                      ),
                      onTap: () async {
                        await _purchaseSakuraBoard();
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.beach_access_outlined,
                      title: 'Tropical Board',
                      subtitle: _tropicalBoardOwned
                          ? 'Owned'
                          : 'Unlock Tropical board palette',
                      priceLabel: '700 c',
                      enabled: !_tropicalBoardOwned,
                      actionLabel: _tropicalBoardOwned ? 'Owned' : 'Buy',
                      actionColor: const Color(0xFFD8B640),
                      preview: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: _boardThemeSwatch(BoardThemeMode.tropical),
                      ),
                      onTap: () async {
                        await _purchaseTropicalBoard();
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      itemKey: piecePackCardKey,
                      icon: Icons.extension_outlined,
                      title: 'Piece Set Pack',
                      subtitle: _piecePackOwned
                          ? 'Owned · unlocks Ember and Frost pieces'
                          : 'Unlock Ember and Frost piece styles',
                      priceLabel: '1400 c',
                      enabled: !_piecePackOwned,
                      actionLabel: _piecePackOwned ? 'Owned' : 'Buy',
                      actionColor: const Color(0xFFD8B640),
                      preview: _piecePackPreview(),
                      onTap: () async {
                        await _purchasePiecePack();
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.auto_awesome,
                      title: 'Spectral Pieces',
                      subtitle: _spectralOwned
                          ? 'Owned'
                          : 'Unlock the Spectral piece theme',
                      priceLabel: '2900 c',
                      enabled: !_spectralOwned,
                      actionLabel: _spectralOwned ? 'Owned' : 'Buy',
                      actionColor: const Color(0xFFD8B640),
                      preview: _pieceThemePreview(
                        PieceThemeMode.spectral,
                        pieceSize: 24.0,
                      ),
                      onTap: () async {
                        await _purchaseSpectral();
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.icecream,
                      title: 'Tutti Frutti Pieces',
                      subtitle: _tuttiFruttiOwned
                          ? 'Owned'
                          : 'Unlock Tutti Frutti piece styles',
                      priceLabel: '1000 c',
                      enabled: !_tuttiFruttiOwned,
                      actionLabel: _tuttiFruttiOwned ? 'Owned' : 'Buy',
                      actionColor: const Color(0xFFD8B640),
                      preview: _pieceThemePreview(
                        PieceThemeMode.tuttiFrutti,
                        pieceSize: 24.0,
                      ),
                      onTap: () async {
                        await _purchaseTuttiFrutti();
                        setL(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    _storeSectionHeader(
                      'Analysis Upgrades',
                      'Depth, suggestions, and long-run unlocks',
                    ),
                    _storeItemCard(
                      icon: Icons.auto_graph,
                      title: 'Pro Mode',
                      subtitle: 'Default mode (max ply depth 24)',
                      priceLabel: 'Included',
                      enabled: false,
                      actionLabel: 'Owned',
                      actionColor: const Color(0xFF5AAEE8),
                      onTap: null,
                    ),
                    _storeItemCard(
                      icon: Icons.psychology_alt_outlined,
                      title: 'Expert Mode',
                      subtitle: _depthTier >= 2
                          ? 'Unlocked (max ply depth 27)'
                          : 'Unlock ply depth 25-27',
                      priceLabel: '2600 c',
                      enabled: _depthTier == 1,
                      actionLabel: _depthTier >= 2
                          ? 'Owned'
                          : (_depthTier == 1 ? 'Unlock' : 'Locked'),
                      actionColor: const Color(0xFF5AAEE8),
                      onTap: () async {
                        await _purchaseDepthTier(2);
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Grandmaster Mode',
                      subtitle: _depthTier >= 3
                          ? 'Unlocked (max ply depth 29)'
                          : 'Unlock ply depth 28-29',
                      priceLabel: '4200 c',
                      enabled: _depthTier == 2,
                      actionLabel: _depthTier >= 3
                          ? 'Owned'
                          : (_depthTier == 2 ? 'Unlock' : 'Locked'),
                      actionColor: const Color(0xFF5AAEE8),
                      onTap: () async {
                        await _purchaseDepthTier(3);
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.whatshot_outlined,
                      title: 'Oracle Mode',
                      subtitle: _depthTier >= 4
                          ? 'Unlocked (max ply depth 35)'
                          : 'Unlock ply depth 33-35',
                      priceLabel: '6200 c',
                      enabled: _depthTier == 3,
                      actionLabel: _depthTier >= 4
                          ? 'Owned'
                          : (_depthTier == 3 ? 'Unlock' : 'Locked'),
                      actionColor: const Color(0xFF5AAEE8),
                      onTap: () async {
                        await _purchaseDepthTier(4);
                        setL(() {});
                      },
                    ),
                    _storeItemCard(
                      icon: Icons.add_circle_outline,
                      title: '+1 Suggested Move',
                      subtitle:
                          'Current max suggestions: $_maxSuggestionsAllowed / 10',
                      priceLabel:
                          '${500 + (_extraSuggestionPurchases * 120)} c',
                      enabled: _maxSuggestionsAllowed < 10,
                      actionLabel: _maxSuggestionsAllowed < 10
                          ? 'Buy +1'
                          : 'Maxed',
                      actionColor: const Color(0xFF8FD0FF),
                      onTap: () async {
                        await _purchaseExtraSuggestion();
                        setL(() {});
                      },
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          await _resetPurchases();
                          if (!ctx.mounted) return;
                          setL(() {});
                        },
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('Reset Purchases'),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurface.withValues(
                            alpha: 0.64,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Depth tier: ${_depthTierLabel()}  |  Max depth: $_maxDepthAllowed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.64),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    rewardCooldownTicker?.cancel();
  }

  Widget _storeSectionHeader(String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.64),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreRewardCooldownPreview(
    Duration remaining, {
    required bool lockedUntilTomorrow,
    required bool useMonochrome,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currentCooldown = context.read<EconomyProvider>().watchCountToday >= 3
        ? remaining
        : const [
            Duration(minutes: 5),
            Duration(minutes: 15),
            Duration(minutes: 30),
          ][context.read<EconomyProvider>().watchCountToday.clamp(0, 2)];
    final totalSeconds = currentCooldown.inSeconds;
    final clampedRemainingSeconds = remaining.inSeconds.clamp(0, totalSeconds);
    final progress =
        1 - (clampedRemainingSeconds / totalSeconds.clamp(1, totalSeconds));
    final accent = useMonochrome
        ? scheme.onSurface.withValues(alpha: 0.78)
        : const Color(0xFF5AAEE8);
    final track = Color.alphaBlend(
      accent.withValues(alpha: 0.18),
      scheme.surface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.timer_outlined, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              lockedUntilTomorrow
                  ? 'Come back tomorrow'
                  : 'Available in ${_storeRewardAdCountdownLabel(remaining)}',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: track,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }

  void _recordVsBotSessionResult(GameOutcome outcome) {
    if (!_playVsBot || _selectedBot == null) {
      return;
    }
    if (outcome == GameOutcome.draw) {
      _vsBotSessionDraws += 1;
      return;
    }
    final humanWon =
        outcome == GameOutcome.whiteWin && _humanPlaysWhite ||
        outcome == GameOutcome.blackWin && !_humanPlaysWhite;
    if (humanWon) {
      _vsBotSessionWins += 1;
    } else {
      _vsBotSessionLosses += 1;
    }
  }

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

  Widget _buildThemeVaultCard(
    Function setL, {
    Future<void> Function()? onBoardThemeUnlockTap,
    Future<void> Function()? onPieceThemeUnlockTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: isDark ? 0.10 : 0.04),
          scheme.surface,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Vault',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Board: ${_boardThemeLabel(_boardThemeMode)} · Pieces: ${_pieceThemeLabel(_pieceThemeMode)} · UI: ${_isCinematicThemeEnabled ? 'Mono' : 'Neon'}',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.64),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _storeThemeCategoryHeader('Board Themes'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: BoardThemeMode.values
                .map(
                  (mode) => _buildStoreBoardThemeCard(
                    mode,
                    setL,
                    onLockedTap: onBoardThemeUnlockTap,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _storeThemeCategoryHeader('Piece Themes'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: PieceThemeMode.values
                .map(
                  (mode) => _buildStorePieceThemeCard(
                    mode,
                    setL,
                    onLockedTap: onPieceThemeUnlockTap,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _storeThemeCategoryHeader('UI Themes'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStoreUiThemeCard(AppThemeStyle.standard, setL),
              _buildStoreUiThemeCard(AppThemeStyle.monochrome, setL),
            ],
          ),
        ],
      ),
    );
  }

  Widget _storeThemeCategoryHeader(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        color: scheme.onSurface.withValues(alpha: 0.72),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildStoreBoardThemeCard(
    BoardThemeMode mode,
    Function setL, {
    Future<void> Function()? onLockedTap,
  }) {
    final unlocked = _isBoardThemeUnlocked(mode);
    final selected = _boardThemeMode == mode;
    return _storeThemeChoiceCard(
      label: _boardThemeLabel(mode),
      preview: _boardThemeSwatch(mode),
      selected: selected,
      locked: !unlocked,
      actionLabel: selected
          ? 'Selected'
          : unlocked
          ? 'Select'
          : 'Unlock',
      onTap: selected
          ? null
          : () async {
              if (!unlocked) {
                if (onLockedTap != null) {
                  await onLockedTap();
                }
              } else {
                setState(() => _boardThemeMode = mode);
                _persistCurrentSettings();
                unawaited(
                  context.read<AppThemeProvider>().setBoardThemeIndex(
                    mode.index,
                  ),
                );
              }
              setL(() {});
            },
    );
  }

  Widget _buildStorePieceThemeCard(
    PieceThemeMode mode,
    Function setL, {
    Future<void> Function()? onLockedTap,
  }) {
    final unlocked = _isPieceThemeUnlocked(mode);
    final selected = _pieceThemeMode == mode;
    return _storeThemeChoiceCard(
      label: _pieceThemeLabel(mode),
      preview: _pieceThemePreview(mode),
      selected: selected,
      locked: !unlocked,
      actionLabel: selected
          ? 'Selected'
          : unlocked
          ? 'Select'
          : 'Unlock',
      onTap: selected
          ? null
          : () async {
              if (!unlocked) {
                if (onLockedTap != null) {
                  await onLockedTap();
                }
              } else {
                setState(() => _pieceThemeMode = mode);
                _persistCurrentSettings();
                unawaited(
                  context.read<AppThemeProvider>().setPieceThemeIndex(
                    mode.index,
                  ),
                );
              }
              setL(() {});
            },
    );
  }

  Widget _buildStoreUiThemeCard(AppThemeStyle style, Function setL) {
    final selected =
        (_isCinematicThemeEnabled
            ? AppThemeStyle.monochrome
            : AppThemeStyle.standard) ==
        style;
    final preview = style == AppThemeStyle.monochrome
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 16, height: 16, color: Colors.black),
              const SizedBox(width: 4),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.white24),
                ),
              ),
              const SizedBox(width: 4),
              Container(width: 16, height: 16, color: const Color(0xFF808080)),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 16, height: 16, color: const Color(0xFFD8B640)),
              const SizedBox(width: 4),
              Container(width: 16, height: 16, color: const Color(0xFF3F6ED8)),
              const SizedBox(width: 4),
              Container(width: 16, height: 16, color: const Color(0xFF5CCB8A)),
            ],
          );
    return _storeThemeChoiceCard(
      label: style == AppThemeStyle.monochrome ? 'Mono' : 'Neon',
      preview: preview,
      selected: selected,
      locked: false,
      actionLabel: selected ? 'Selected' : 'Select',
      onTap: selected
          ? null
          : () async {
              await _setCinematicThemeEnabled(
                style == AppThemeStyle.monochrome,
              );
              setL(() {});
            },
    );
  }

  Widget _storeThemeChoiceCard({
    required String label,
    required Widget preview,
    required bool selected,
    required bool locked,
    required String actionLabel,
    required Future<void> Function()? onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final idleSurface = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.08 : 0.03),
      scheme.surface,
    );
    final selectedSurface = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.18 : 0.10),
      scheme.surface,
    );
    final lockedAccent = const Color(0xFFD8B640);
    final readyAccent = const Color(0xFF5AAEE8);
    final selectedAccent = const Color(0xFF7EDC8A);
    final actionAccent = selected
        ? selectedAccent
        : locked
        ? lockedAccent
        : readyAccent;
    final actionForeground = actionAccent.computeLuminance() > 0.45
        ? const Color(0xFF07131F)
        : Colors.white;

    return Container(
      width: 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? selectedSurface : idleSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? scheme.primary.withValues(alpha: 0.72)
              : scheme.outline.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 46, child: Center(child: preview)),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selected
                ? 'Active now'
                : locked
                ? 'Locked in store'
                : 'Ready to equip',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.64),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap == null ? null : () => onTap(),
              style: FilledButton.styleFrom(
                backgroundColor: actionAccent,
                foregroundColor: actionForeground,
                disabledBackgroundColor: scheme.outline.withValues(alpha: 0.18),
                disabledForegroundColor: scheme.onSurface.withValues(
                  alpha: 0.38,
                ),
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeVaultChip({
    required String label,
    required bool selected,
    required Widget leading,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.20)
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.05),
                  scheme.surface,
                ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.72)
                : scheme.outline.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 7),
            Text(label, style: TextStyle(color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _storeItemCard({
    Key? itemKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required String priceLabel,
    required bool enabled,
    required String actionLabel,
    Color? actionColor,
    Widget? preview,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardSurface = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.08 : 0.03),
      scheme.surface,
    );
    final resolvedActionColor = actionColor ?? scheme.primary;
    final actionForeground = resolvedActionColor.computeLuminance() > 0.45
        ? const Color(0xFF07131F)
        : Colors.white;

    return Container(
      key: itemKey,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                scheme.primary.withValues(alpha: isDark ? 0.10 : 0.05),
                scheme.surface,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.64),
                    fontSize: 12,
                  ),
                ),
                if (preview != null) ...[const SizedBox(height: 8), preview],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceLabel,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFFFD166)
                      : const Color(0xFF8A6700),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 30,
                child: FilledButton(
                  onPressed: enabled ? onTap : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: enabled
                        ? resolvedActionColor
                        : scheme.outline.withValues(alpha: 0.18),
                    foregroundColor: enabled
                        ? actionForeground
                        : scheme.onSurface.withValues(alpha: 0.38),
                    disabledBackgroundColor: scheme.outline.withValues(
                      alpha: 0.18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _perspectiveOption(String label, BoardPerspective p, Function setL) {
    final sel = _perspective == p;
    final scheme = Theme.of(context).colorScheme;
    Widget kingWidget;
    if (p == BoardPerspective.white) {
      kingWidget = _pieceImage('k_w', width: 20, height: 20);
    } else if (p == BoardPerspective.black) {
      kingWidget = _pieceImage('k_b', width: 20, height: 20);
    } else {
      kingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pieceImage('k_w', width: 15, height: 15),
          Icon(
            Icons.sync,
            size: 11,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
          _pieceImage('k_b', width: 15, height: 15),
        ],
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() => _perspective = p);
        setL(() {});
        _persistCurrentSettings();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? scheme.primary.withValues(alpha: 0.20)
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.05),
                  scheme.surface,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel
                ? scheme.primary.withValues(alpha: 0.62)
                : scheme.outline.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            kingWidget,
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _boardThemeOption(BoardThemeMode mode, Function setL) {
    final selected = _boardThemeMode == mode;
    return ThemeSelectorTile(
      selected: selected,
      onTap: () {
        setState(() => _boardThemeMode = mode);
        setL(() {});
        _persistCurrentSettings();
        unawaited(
          context.read<AppThemeProvider>().setBoardThemeIndex(mode.index),
        );
      },
      child: _boardThemeSwatch(mode),
    );
  }

  Widget _pieceThemeOption(PieceThemeMode mode, Function setL) {
    final selected = _pieceThemeMode == mode;
    return ThemeSelectorTile(
      selected: selected,
      onTap: () {
        setState(() => _pieceThemeMode = mode);
        setL(() {});
        _persistCurrentSettings();
        unawaited(
          context.read<AppThemeProvider>().setPieceThemeIndex(mode.index),
        );
      },
      child: _pieceThemePreview(mode),
    );
  }

  Widget _boardThemeSwatch(BoardThemeMode mode) {
    return BoardThemeSwatchPreview(
      palette: AppThemeProvider.boardPaletteForIndex(mode.index),
    );
  }

  Widget _pieceThemePreview(PieceThemeMode mode, {double pieceSize = 18}) {
    return PieceThemePreviewTile(
      pieceThemeIndex: mode.index,
      pieceSize: pieceSize,
    );
  }

  Widget _themePackPreview() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _themeVaultChip(
          label: 'Ember',
          selected: false,
          leading: _boardThemeSwatch(BoardThemeMode.ember),
        ),
        _themeVaultChip(
          label: 'Sea',
          selected: false,
          leading: _boardThemeSwatch(BoardThemeMode.aurora),
        ),
      ],
    );
  }

  Widget _piecePackPreview() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _themeVaultChip(
          label: 'Ember',
          selected: false,
          leading: _pieceThemePreview(PieceThemeMode.ember),
        ),
        _themeVaultChip(
          label: 'Frost',
          selected: false,
          leading: _pieceThemePreview(PieceThemeMode.frost),
        ),
      ],
    );
  }

  Widget _pieceImage(
    String piece, {
    double? width,
    double? height,
    PieceThemeMode? theme,
    bool applyBlackOutline = true,
    double blackOutlineOverflowPx = 0,
  }) {
    final activeTheme = theme ?? _pieceThemeMode;
    final baseImage = Image.asset(
      'assets/pieces/$piece.png',
      width: width,
      height: height,
    );
    final tinted = activeTheme == PieceThemeMode.classic
        ? baseImage
        : ColorFiltered(
            colorFilter: ColorFilter.mode(
              _pieceTintColor(piece, activeTheme),
              BlendMode.modulate,
            ),
            child: baseImage,
          );

    final isBlackPiece = piece.endsWith('_b');
    final isSpectral = activeTheme == PieceThemeMode.spectral;
    Widget result;

    if (!isBlackPiece || !applyBlackOutline) {
      if (!isSpectral) {
        result = tinted;
      } else {
        result = Stack(
          clipBehavior: Clip.none,
          children: [
            for (final offset in const [
              Offset(-0.8, -0.8),
              Offset(0.8, -0.5),
              Offset(-0.5, 0.8),
              Offset(0.8, 0.8),
            ])
              Transform.translate(
                offset: offset,
                child: Opacity(
                  opacity: 0.18,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _pieceTintColor(
                        piece,
                        activeTheme,
                      ).withValues(alpha: 0.4),
                      BlendMode.srcIn,
                    ),
                    child: baseImage,
                  ),
                ),
              ),
            tinted,
          ],
        );
      }
    } else {
      final outlineWidth = width == null
          ? null
          : width + blackOutlineOverflowPx;
      final outlineHeight = height == null
          ? null
          : height + blackOutlineOverflowPx;
      final outlineCenterShift = Offset(
        -blackOutlineOverflowPx / 2,
        -blackOutlineOverflowPx / 2,
      );

      result = Stack(
        clipBehavior: Clip.none,
        children: [
          if (isSpectral)
            for (final offset in const [
              Offset(-0.8, -0.8),
              Offset(0.8, -0.5),
              Offset(-0.5, 0.8),
              Offset(0.8, 0.8),
            ])
              Transform.translate(
                offset: offset,
                child: Opacity(
                  opacity: 0.18,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _pieceTintColor(
                        piece,
                        activeTheme,
                      ).withValues(alpha: 0.4),
                      BlendMode.srcIn,
                    ),
                    child: baseImage,
                  ),
                ),
              ),
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
              offset: offset + outlineCenterShift,
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  'assets/pieces/$piece.png',
                  width: outlineWidth,
                  height: outlineHeight,
                  color: const Color(0xFFF7FBFF),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          tinted,
        ],
      );
    }

    if (!isSpectral) {
      return result;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final phase = _pieceThemePhase(piece);
        final phase2 = _pieceThemePhase2(piece);
        final phase3 = _pieceThemePhase3(piece);
        final frequency =
            1.55 +
            (piece.codeUnits.fold<int>(0, (sum, v) => sum + v) % 8) * 0.055;
        final t = _pulseController.value * 2 * pi * frequency + phase;
        final pulse =
            ((sin(t) * 0.8) +
                    (sin(t * 1.73 + phase2) * 0.45) +
                    (sin(t * 2.27 + phase3) * 0.35)) *
                0.18 +
            0.53;
        final flutterOffset = Offset(
          cos(t * 1.95 + phase2) * (0.28 + pulse * 0.43),
          sin(t * 2.23 + phase3) * (0.22 + pulse * 0.48),
        );
        final glowColor = _pieceTintColor(
          piece,
          activeTheme,
        ).withValues(alpha: (0.26 + pulse * 0.34).clamp(0.2, 0.78));
        final trailOffsets =
            <Offset>[
                  const Offset(-1.1, -0.9),
                  const Offset(1.0, -0.2),
                  const Offset(-0.6, 1.2),
                ]
                .map(
                  (offset) =>
                      offset * (0.70 + pulse * 0.92) +
                      flutterOffset * (0.6 + pulse * 0.35),
                )
                .toList(growable: false);

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 18 + pulse * 12,
                spreadRadius: 2.8 + pulse * 4.5,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final offset in trailOffsets)
                Transform.translate(
                  offset: offset,
                  child: Opacity(
                    opacity: (0.16 - pulse * 0.06).clamp(0.06, 0.18),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        glowColor.withValues(alpha: 0.26),
                        BlendMode.srcIn,
                      ),
                      child: baseImage,
                    ),
                  ),
                ),
              Transform.translate(offset: flutterOffset * 0.38, child: result),
            ],
          ),
        );
      },
    );
  }

  double _pieceThemePhase(String piece) {
    return (piece.codeUnits.fold<int>(0, (sum, v) => sum + v) % 100) * 0.0628;
  }

  double _pieceThemePhase2(String piece) {
    return (piece.codeUnits.fold<int>(0, (sum, v) => sum + v * 3) % 100) *
        0.0628;
  }

  double _pieceThemePhase3(String piece) {
    return (piece.codeUnits.fold<int>(0, (sum, v) => sum + v * 5) % 100) *
        0.0628;
  }

  Color _pieceTintColor(String piece, PieceThemeMode theme) {
    return AppThemeProvider.pieceTintColorForIndex(theme.index, piece);
  }

  String _boardThemeLabel(BoardThemeMode mode) {
    switch (mode) {
      case BoardThemeMode.dark:
        return 'Neon';
      case BoardThemeMode.light:
        return 'Classic';
      case BoardThemeMode.monochrome:
        return 'Mono';
      case BoardThemeMode.ember:
        return 'Ember';
      case BoardThemeMode.aurora:
        return 'Sea';
      case BoardThemeMode.sakura:
        return 'Sakura';
      case BoardThemeMode.tropical:
        return 'Tropical';
    }
  }

  String _pieceThemeLabel(PieceThemeMode mode) {
    switch (mode) {
      case PieceThemeMode.classic:
        return 'Classic';
      case PieceThemeMode.ember:
        return 'Ember';
      case PieceThemeMode.frost:
        return 'Frost';
      case PieceThemeMode.tuttiFrutti:
        return 'Tutti Frutti';
      case PieceThemeMode.spectral:
        return 'Spectral';
    }
  }

  Color _darkSquareColorForTheme() {
    return AppThemeProvider.boardPaletteForIndex(
      _boardThemeMode.index,
    ).darkSquare;
  }

  Color _lightSquareColorForTheme() {
    return AppThemeProvider.boardPaletteForIndex(
      _boardThemeMode.index,
    ).lightSquare;
  }

  @override
  void dispose() {
    _cancelIdleInterstitialTimer();
    WidgetsBinding.instance.removeObserver(this);
    _editModeHintTimer?.cancel();
    _clearBotGhostArrows();
    unawaited(_engine?.stop());
    _cancelIdleInterstitialTimer();
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.removeListener(_updateBotSetupBlueDotScrollOffset);
    _pulseController.dispose();
    _introController.dispose();
    _menuRevealController.dispose();
    _launchController.dispose();
    _buttonRippleController.dispose();
    _menuMusicFadeController.dispose();
    _sectionTransitionController.dispose();
    _menuExitAnimationController.dispose();
    _openingButtonFlashController.dispose();
    _storeCoinGainController.dispose();
    _botSetupPageController.dispose();
    _introAudioPlayer.dispose();
    _menuAudioPlayer.dispose();
    _sfxAudioPlayer.dispose();
    _cinematicThemeNotifier.dispose();
    for (final player in _boardSfxPlayers) {
      player.dispose();
    }
    super.dispose();
  }
}
