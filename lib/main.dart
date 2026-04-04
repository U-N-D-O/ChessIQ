import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'dart:convert';

// ─── Engine Service Abstraction ──────────────────────────────────────────────

abstract class _EngineService {
  Future<void> start(void Function(String line) onOutput);
  void send(String cmd);
  Future<void> stop();
}

/// No-op — used on web where no engine is available.
class _NullEngineService extends _EngineService {
  @override
  Future<void> start(void Function(String line) onOutput) async {}
  @override
  void send(String cmd) {}
  @override
  Future<void> stop() async {}
}

/// Desktop — launches stockfish.exe as a subprocess via dart:io Process.
class _DesktopEngineService extends _EngineService {
  Process? _process;
  StreamSubscription<String>? _sub;

  @override
  Future<void> start(void Function(String line) onOutput) async {
    _process = await Process.start('./engine/stockfish.exe', []);
    _sub = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(onOutput);
  }

  @override
  void send(String cmd) => _process?.stdin.writeln(cmd);

  @override
  Future<void> stop() async {
    send('quit');
    await _sub?.cancel();
    _process?.kill();
    _process = null;
    _sub = null;
  }
}

/// iOS — communicates with the native Swift bridge via platform channels.
class _IosEngineService extends _EngineService {
  static const _method = MethodChannel('com.chessiq/stockfish');
  static const _event  = EventChannel('com.chessiq/stockfish_output');
  StreamSubscription? _sub;

  @override
  Future<void> start(void Function(String line) onOutput) async {
    await _method.invokeMethod<void>('start');
    _sub = _event.receiveBroadcastStream().cast<String>().listen(onOutput);
  }

  @override
  void send(String cmd) => _method.invokeMethod<void>('send', cmd);

  @override
  Future<void> stop() async {
    await _method.invokeMethod<void>('stop');
    await _sub?.cancel();
    _sub = null;
  }
}

_EngineService _createEngineService() {
  if (kIsWeb) return _NullEngineService();
  if (Platform.isIOS) return _IosEngineService();
  return _DesktopEngineService();
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChessIQApp());
}

enum BoardPerspective { white, black, auto }

enum BoardThemeMode { dark, light, monochrome, ember, aurora }

enum PieceThemeMode { classic, ember, frost }

enum StoreSection { general, themes }

enum AppSection { menu, analysis, gambitQuiz }

enum GambitQuizMode { guessName, guessLine }

enum QuizDifficulty { easy, medium, hard }

enum QuizTrendFilter { both, guessName, guessLine }

class QuizAccuracyPoint {
  final String dayLabel;
  final double value;

  const QuizAccuracyPoint({required this.dayLabel, required this.value});
}

class ChessIQApp extends StatelessWidget {
  const ChessIQApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
          headlineSmall: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          titleLarge: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.w700,
          ),
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFF090B12),
        textTheme: textTheme,
        colorScheme: base.colorScheme.copyWith(
          primary: const Color(0xFFB9A46A),
          secondary: const Color(0xFF3F6ED8),
          surface: const Color(0xFF10131D),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFC7CBD6)),
      ),
      home: const ChessAnalysisPage(),
    );
  }
}

// --- Enhanced Data Models ---
class MoveRecord {
  final String notation;
  final String pieceMoved;
  final String? pieceCaptured;
  final Map<String, String> state;
  final bool isWhite;
  MoveRecord({
    required this.notation,
    required this.pieceMoved,
    this.pieceCaptured,
    required this.state,
    required this.isWhite,
  });
}

class EngineLine {
  final String move;
  final int eval;
  final int depth;
  final int multiPv;
  EngineLine(this.move, this.eval, this.depth, this.multiPv);
}

class EcoLine {
  final String name;
  final String normalizedMoves;
  final List<String> moveTokens;
  final bool isGambit;

  EcoLine({
    required this.name,
    required this.normalizedMoves,
    required this.moveTokens,
    required this.isGambit,
  });
}

class QuizBoardSnapshot {
  final Map<String, String> boardState;
  final bool whiteToMove;
  final int shownPly;
  final List<EngineLine> continuation;

  QuizBoardSnapshot({
    required this.boardState,
    required this.whiteToMove,
    required this.shownPly,
    required this.continuation,
  });
}

class _RenderedMoveToken {
  final String notation;
  final String movingPiece;
  final String? capturedPiece;

  const _RenderedMoveToken({
    required this.notation,
    required this.movingPiece,
    this.capturedPiece,
  });
}

class ChessAnalysisPage extends StatefulWidget {
  const ChessAnalysisPage({super.key});
  @override
  State<ChessAnalysisPage> createState() => _ChessAnalysisPageState();
}

class _ChessAnalysisPageState extends State<ChessAnalysisPage>
    with TickerProviderStateMixin {
  static const BoardPerspective _defaultPerspective = BoardPerspective.white;
  static const BoardThemeMode _defaultBoardTheme = BoardThemeMode.dark;
  static const PieceThemeMode _defaultPieceTheme = PieceThemeMode.classic;
  static const int _defaultEngineDepth = 20;
  static const int _defaultMultiPvCount = 1;
  static const String _savedDefaultSnapshotKey = 'saved_default_snapshot_v1';
  static const String _storeStateKey = 'store_state_v1';
  static const String _viewedGambitsKey = 'viewed_gambits_v1';
  static const String _muteSoundsKey = 'mute_sounds_v1';
  static const String _quizStatsKey = 'quiz_stats_v1';

  late Map<String, String> boardState;
  _EngineService? _engine;
  late AnimationController _pulseController;
  late AnimationController _introController;
  late AnimationController _menuRevealController;
  late AnimationController _launchController;
  late AnimationController _menuMusicFadeController;
  late AnimationController _sectionTransitionController;
  late AnimationController _menuExitAnimationController;
  late AnimationController _buttonRippleController;
  Offset? _buttonRippleCenter;
  bool _buttonUnlocked = false;
  final AudioPlayer _introAudioPlayer = AudioPlayer();
  final AudioPlayer _menuAudioPlayer = AudioPlayer();
  bool _menuMusicPlaying = false;
  bool _isHotkeyResetting = false;
  Future<void>? _engineStartFuture;
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _suggestionButtonKey = GlobalKey();

  int _currentDepth = 0;
  double _currentEval = 0.0;
  int _multiPvCount = _defaultMultiPvCount;
  int _engineDepth = _defaultEngineDepth;
  bool _isWhiteTurn = true;
  BoardPerspective _perspective = _defaultPerspective;
  BoardThemeMode _boardThemeMode = _defaultBoardTheme;
  PieceThemeMode _pieceThemeMode = _defaultPieceTheme;

  List<EngineLine> _topLines = [];
  final List<MoveRecord> _moveHistory = [];
  int _historyIndex = -1;
  late ScrollController _historyScrollController;
  final Map<String, String> _ecoOpenings = {};
  final List<EcoLine> _ecoLines = [];
  String _currentOpening = '';
  final List<String> _logs = [];
  bool _isChoosingGambit = false;
  String? _gambitSelectedFrom;
  String? _holdSelectedFrom;
  final Set<String> _legalTargets = <String>{};
  final Set<String> _gambitAvailableTargets = <String>{};
  EcoLine? _selectedGambit;
  List<EngineLine> _gambitPreviewLines = [];

  int _storeCoins = 0;
  int _depthTier = 0; // 0=base,1=pro,2=expert,3=grandmaster
  int _extraSuggestionPurchases = 0; // each +1 up to max 10 suggestions
  bool _themePackOwned = false;
  bool _piecePackOwned = false;
  bool _adFreeOwned = false;
  bool _introCompleted = true;
  bool _suggestionsEnabled = false;
  bool _suggestionLaunchInProgress = false;
  Offset? _launchStart;
  List<Offset> _launchTargets = <Offset>[];

  AppSection _activeSection = AppSection.menu;
  GambitQuizMode _quizMode = GambitQuizMode.guessName;
  bool _menuReady = false;
  bool _muteSounds = false;
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
  int _quizQuestionsTarget = 10;
  int _quizSessionAnswered = 0;
  int _quizSessionCorrect = 0;
  bool _quizSessionStarted = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()} - $message');
      if (_logs.length > 200) {
        _logs.removeAt(0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
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
      await _menuAudioPlayer.setReleaseMode(ReleaseMode.loop);
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
      final viewed = prefs.getStringList(_viewedGambitsKey) ?? const <String>[];
      _viewedGambits
        ..clear()
        ..addAll(viewed);

      final rawQuizStats = prefs.getString(_quizStatsKey);
      if (rawQuizStats != null && rawQuizStats.isNotEmpty) {
        final decoded = jsonDecode(rawQuizStats);
        if (decoded is Map<String, dynamic>) {
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
        }
      }
    } catch (e) {
      debugPrint('Failed to load UI prefs: $e');
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
    };
    await prefs.setString(_quizStatsKey, jsonEncode(payload));
  }

  Future<void> _saveViewedGambits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _viewedGambitsKey,
      _viewedGambits.toList()..sort(),
    );
  }

  Future<void> _setMute(bool value) async {
    setState(() => _muteSounds = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_muteSoundsKey, value);
    if (value) {
      await _introAudioPlayer.stop();
      await _stopMenuMusic(fadeOut: false);
    } else if (_activeSection != AppSection.analysis) {
      await _playMenuMusic();
    }
  }

  int get _maxDepthAllowed {
    switch (_depthTier) {
      case 1:
        return 27;
      case 2:
        return 29;
      case 3:
        return 32;
      default:
        return 24;
    }
  }

  int get _maxSuggestionsAllowed =>
      (2 + _extraSuggestionPurchases).clamp(2, 10);

  bool _isBoardThemeUnlocked(BoardThemeMode mode) {
    switch (mode) {
      case BoardThemeMode.dark:
      case BoardThemeMode.light:
      case BoardThemeMode.monochrome:
        return true;
      case BoardThemeMode.ember:
      case BoardThemeMode.aurora:
        return _themePackOwned;
    }
  }

  bool _isPieceThemeUnlocked(PieceThemeMode mode) {
    switch (mode) {
      case PieceThemeMode.classic:
        return true;
      case PieceThemeMode.ember:
      case PieceThemeMode.frost:
        return _piecePackOwned;
    }
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
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storeStateKey);
      if (raw == null || raw.isEmpty) {
        _engineDepth = _engineDepth.clamp(10, _maxDepthAllowed);
        _multiPvCount = _multiPvCount.clamp(1, _maxSuggestionsAllowed);
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final coins = decoded['coins'];
      final tier = decoded['depthTier'];
      final extraSuggestions = decoded['extraSuggestions'];
      final themePack = decoded['themePackOwned'];
      final piecePack = decoded['piecePackOwned'];
      final adFree = decoded['adFreeOwned'];

      if (coins is int) _storeCoins = max(0, coins);
      if (tier is int) _depthTier = tier.clamp(0, 3);
      if (extraSuggestions is int) {
        _extraSuggestionPurchases = extraSuggestions.clamp(0, 8);
      }
      if (themePack is bool) _themePackOwned = themePack;
      if (piecePack is bool) _piecePackOwned = piecePack;
      if (adFree is bool) _adFreeOwned = adFree;

      _engineDepth = _engineDepth.clamp(10, _maxDepthAllowed);
      _multiPvCount = _multiPvCount.clamp(1, _maxSuggestionsAllowed);
      _normalizeUnlockedThemes();
    } catch (e) {
      debugPrint('Failed to load store state: $e');
    }
  }

  Future<void> _saveStoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'coins': _storeCoins,
      'depthTier': _depthTier,
      'extraSuggestions': _extraSuggestionPurchases,
      'themePackOwned': _themePackOwned,
      'piecePackOwned': _piecePackOwned,
      'adFreeOwned': _adFreeOwned,
    };
    await prefs.setString(_storeStateKey, jsonEncode(payload));
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
      if (savedDepth is int) {
        _engineDepth = savedDepth.clamp(10, _maxDepthAllowed);
      }
      if (savedMultiPv is int) {
        _multiPvCount = savedMultiPv.clamp(1, _maxSuggestionsAllowed);
      }
      if (savedWhiteTurn is bool) {
        _isWhiteTurn = savedWhiteTurn;
      }
      if (savedSuggestionsEnabled is bool) {
        _suggestionsEnabled = savedSuggestionsEnabled;
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

      _currentOpening = '';
      _gambitSelectedFrom = null;
      _holdSelectedFrom = null;
      _legalTargets.clear();
      _gambitAvailableTargets.clear();
      _selectedGambit = null;
      _gambitPreviewLines = [];
      _normalizeUnlockedThemes();
    } catch (e) {
      debugPrint('Failed to load saved default snapshot: $e');
    }
  }

  void _persistCurrentSettings() {
    unawaited(_saveCurrentAsDefaultSnapshot(logChange: false));
  }

  Map<String, dynamic> _moveRecordToMap(MoveRecord move) {
    return {
      'notation': move.notation,
      'pieceMoved': move.pieceMoved,
      'pieceCaptured': move.pieceCaptured,
      'state': move.state,
      'isWhite': move.isWhite,
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
      );
    } catch (_) {
      return null;
    }
  }

  void _resetBoard({bool initialLaunch = false, bool withIntro = true}) {
    boardState = {
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
    _isWhiteTurn = true;
    _moveHistory.clear();
    _historyIndex = -1;
    _currentOpening = '';
    _gambitSelectedFrom = null;
    _holdSelectedFrom = null;
    _legalTargets.clear();
    _gambitAvailableTargets.clear();
    _selectedGambit = null;
    _gambitPreviewLines = [];
    _suggestionsEnabled = false;
    _suggestionLaunchInProgress = false;
    _launchStart = null;
    _launchTargets = <Offset>[];
    _topLines = [];
    _currentDepth = 0;
    _currentEval = 0.0;
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
    if (_engine != null) return;
    if (kIsWeb) {
      _addLog('Engine unavailable on web; running without Stockfish process.');
      return;
    }
    try {
      _engine = _createEngineService();
      await _engine!.start(_parseOutput);
      _engine!.send('uci');
      _engine!.send('setoption name MultiPV value $_multiPvCount');
      if (_suggestionsEnabled) {
        _analyze();
      }
    } catch (e) {
      _engine = null;
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

  void _analyze() {
    if (!_suggestionsEnabled) {
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
    _send('position fen ${_genFen()}');
    _send('go depth $_engineDepth');
  }

  void _parseOutput(String line) {
    if (!line.startsWith('info depth')) return;
    final d = RegExp(r'depth (\d+)').firstMatch(line);
    final pv = RegExp(r'multipv (\d+)').firstMatch(line);
    final m = RegExp(r'pv ([a-h][1-8][a-h][1-8])').firstMatch(line);
    final s = RegExp(r'score cp (-?\d+)').firstMatch(line);

    if (d != null && pv != null && m != null) {
      int depth = int.parse(d.group(1)!);
      int multiPv = int.parse(pv.group(1)!);
      int cp = s != null ? int.parse(s.group(1)!) : 0;
      setState(() {
        _currentDepth = depth;
        if (multiPv == 1) _currentEval = cp / 100.0;
        _topLines.removeWhere(
          (e) => e.multiPv == multiPv || e.multiPv > _multiPvCount,
        );
        _topLines.add(EngineLine(m.group(1)!, cp, depth, multiPv));
        _topLines.sort((a, b) => a.multiPv.compareTo(b.multiPv));
      });
    }
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

  String _pieceCodeForSanToken(String san, bool isWhiteMove) {
    final cleaned = _sanitizeSanToken(san);
    String pieceCode;

    if (cleaned.startsWith('O-O')) {
      pieceCode = 'k';
    } else {
      final designator = RegExp(r'^[KQRBN]').stringMatch(cleaned);
      switch (designator) {
        case 'K':
          pieceCode = 'k';
          break;
        case 'Q':
          pieceCode = 'q';
          break;
        case 'R':
          pieceCode = 't';
          break;
        case 'B':
          pieceCode = 'b';
          break;
        case 'N':
          pieceCode = 'n';
          break;
        default:
          pieceCode = 'p';
          break;
      }
    }

    return '${pieceCode}_${isWhiteMove ? 'w' : 'b'}';
  }

  List<_RenderedMoveToken> _renderedMoveTokens(String notation) {
    final tokens = _moveSequenceTokens(notation);
    if (tokens.isEmpty) return const <_RenderedMoveToken>[];

    final rendered = <_RenderedMoveToken>[];
    var state = _initialBoardState();
    var whiteToMove = true;

    for (int index = 0; index < tokens.length; index++) {
      final token = tokens[index];
      final fallbackPiece = _pieceCodeForSanToken(token, whiteToMove);
      final uciMove = _resolveSanToUci(state, token, whiteToMove);

      if (uciMove == null) {
        rendered.add(
          _RenderedMoveToken(notation: token, movingPiece: fallbackPiece),
        );
        whiteToMove = !whiteToMove;
        continue;
      }

      final from = uciMove.substring(0, 2);
      final to = uciMove.substring(2, 4);
      final movingPiece = state[from] ?? fallbackPiece;
      String? capturedPiece = state[to];

      if (capturedPiece == null &&
          movingPiece.startsWith('p') &&
          from[0] != to[0]) {
        final targetRank = int.parse(to[1]);
        final capturedRank = whiteToMove ? targetRank - 1 : targetRank + 1;
        final capturedSquare = '${to[0]}$capturedRank';
        capturedPiece = state[capturedSquare];
      }

      rendered.add(
        _RenderedMoveToken(
          notation: token,
          movingPiece: movingPiece,
          capturedPiece: capturedPiece,
        ),
      );

      state = _applyUciMove(state, uciMove);
      whiteToMove = !whiteToMove;
    }

    return rendered;
  }

  Widget _buildMoveSequenceText(
    String notation, {
    double fontSize = 12,
    Color color = Colors.white70,
    FontWeight fontWeight = FontWeight.w600,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
  }) {
    final renderedTokens = _renderedMoveTokens(notation);
    if (renderedTokens.isEmpty) {
      return Text(
        notation,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
      );
    }

    final iconSize = fontSize + 4;
    final spans = <InlineSpan>[];
    for (int index = 0; index < renderedTokens.length; index++) {
      final token = renderedTokens[index];
      if (index > 0) {
        spans.add(const TextSpan(text: '  '));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(right: token.capturedPiece == null ? 4 : 0),
            child: _pieceImage(
              token.movingPiece,
              width: iconSize,
              height: iconSize,
            ),
          ),
        ),
      );
      if (token.capturedPiece != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              Icons.arrow_right_alt_rounded,
              size: fontSize + 2,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        );
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 3),
              child: _pieceImage(
                token.capturedPiece!,
                width: iconSize,
                height: iconSize,
              ),
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: token.notation,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  bool _isCurrentTurnPiece(String? piece) {
    if (piece == null) return false;
    return _isWhiteTurn ? piece.endsWith('_w') : piece.endsWith('_b');
  }

  bool get _isBlackPovActive {
    return _perspective == BoardPerspective.black ||
        (_perspective == BoardPerspective.auto && !_isWhiteTurn);
  }

  double _displayEvalForPov() {
    // Engine cp is from side-to-move perspective. Convert to white eval first.
    final whiteEval = _isWhiteTurn ? _currentEval : -_currentEval;
    return _isBlackPovActive ? -whiteEval : whiteEval;
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

  void _toggleGambitMode() {
    // If a gambit is already selected, show possible continuations instead of exiting
    if (_selectedGambit != null) {
      _showContinuingGambits();
      return;
    }

    setState(() {
      _isChoosingGambit = !_isChoosingGambit;
      if (_isChoosingGambit) {
        final selected = _holdSelectedFrom;
        if (selected != null && _isCurrentTurnPiece(boardState[selected])) {
          _selectGambitSource(selected);
          _addLog('Gambit source selected from held piece: $selected');
        } else {
          _gambitSelectedFrom = null;
          _legalTargets.clear();
          _gambitAvailableTargets.clear();
        }
      } else {
        _gambitSelectedFrom = null;
        _legalTargets.clear();
        _gambitAvailableTargets.clear();
        _selectedGambit = null;
        _gambitPreviewLines = [];
      }
    });
    _addLog(_isChoosingGambit ? 'Gambit mode enabled' : 'Gambit mode disabled');
  }

  List<EcoLine> _findContinuingGambits() {
    final currentMoves = _currentMoveSequence();
    final prefix = currentMoves.isEmpty ? '' : '$currentMoves ';

    // Find all gambits that start with current move sequence followed by more moves
    final results = _ecoLines
        .where(
          (line) =>
              line.isGambit &&
              line.normalizedMoves.startsWith(prefix.trim()) &&
              line.normalizedMoves.length > prefix.trim().length,
        )
        .toList();

    results.sort((a, b) => a.moveTokens.length.compareTo(b.moveTokens.length));

    // Deduplicate by name and keep the shortest (most direct) path to each unique name
    final unique = <String, EcoLine>{};
    for (final line in results) {
      unique.putIfAbsent(line.name, () => line);
    }
    return unique.values.toList();
  }

  void _showContinuingGambits() {
    final continuingGambits = _findContinuingGambits();

    if (continuingGambits.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                'No further gambits here',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1A1B22),
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
            ),
          );
      }
      return;
    }

    _addLog('Found ${continuingGambits.length} continuing gambits');

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
                      Icons.fork_right,
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
                          'Continuing Gambits',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${continuingGambits.length} line${continuingGambits.length == 1 ? '' : 's'} from current position',
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
                  itemCount: continuingGambits.length,
                  itemBuilder: (context, index) {
                    final gambit = continuingGambits[index];
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
                                    color: Colors.white.withValues(
                                      alpha: 0.72,
                                    ),
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
    if (!_isChoosingGambit) return;

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
      );
      if (_findGambitsForCandidateMove(notation).isNotEmpty) {
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

    final notation = _buildMoveNotation(from, to, sourcePiece, boardState[to]);
    final gambits = _findGambitsForCandidateMove(notation);
    _addLog('Gambit lookup for move "$notation": ${gambits.length} matches');

    if (gambits.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                'No gambits for this move',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1A1B22),
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
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

    _showGambitChooser(gambits, notation);
  }

  void _handleGambitDragDrop(String from, String to) {
    if (!_isChoosingGambit || from == to) return;

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
  ) {
    if (piece.startsWith('p')) {
      return captured != null ? '${from[0]}x$to' : to;
    }
    final pieceLetter = _pieceNotationLetter(piece);
    return '$pieceLetter${captured != null ? 'x' : ''}$to';
  }

  List<EcoLine> _findGambitsForCandidateMove(String notation) {
    final currentMoves = _currentMoveSequence();
    final prefix = currentMoves.isEmpty
        ? notation.toLowerCase()
        : '$currentMoves ${notation.toLowerCase()}';
    final results = _ecoLines
        .where(
          (line) =>
              line.isGambit &&
              (line.normalizedMoves == prefix ||
                  line.normalizedMoves.startsWith('$prefix ')),
        )
        .toList();
    results.sort((a, b) => a.moveTokens.length.compareTo(b.moveTokens.length));

    final unique = <String, EcoLine>{};
    for (final line in results) {
      unique.putIfAbsent(line.name, () => line);
    }
    return unique.values.toList();
  }

  void _showGambitChooser(List<EcoLine> gambits, String notation) {
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
                      color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.30),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFFD700),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Gambit',
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
                              color: const Color(
                                0xFFFFD700,
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
                                    color: Colors.white.withValues(
                                      alpha: 0.72,
                                    ),
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
                                  0xFFFFD700,
                                ).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                '$moveCount ply',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFFFD700),
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
      _isChoosingGambit = false;
    });
    _addLog(
      'Selected gambit: ${gambit.name} (${preview.length} preview arrows)',
    );
  }

  List<EcoLine> _uniqueGambits() {
    final map = <String, EcoLine>{};
    for (final line in _ecoLines.where((line) => line.isGambit)) {
      map.putIfAbsent(line.name, () => line);
    }
    final values = map.values.toList();
    values.sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  void _markGambitViewed(String name) {
    if (name.isEmpty) return;
    if (_viewedGambits.add(name)) {
      unawaited(_saveViewedGambits());
    }
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

  int _quizOptionCount() {
    switch (_quizDifficulty) {
      case QuizDifficulty.easy:
        return 3;
      case QuizDifficulty.medium:
        return 4;
      case QuizDifficulty.hard:
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

  void _trimDailyMap(Map<String, int> values, {int keepDays = 21}) {
    final keys = values.keys.toList()..sort();
    if (keys.length <= keepDays) return;
    for (final key in keys.take(keys.length - keepDays)) {
      values.remove(key);
    }
  }

  List<QuizAccuracyPoint> _buildQuizAccuracySeries(
    QuizTrendFilter filter, {
    int days = 10,
  }) {
    late final Map<String, int> attempts;
    late final Map<String, int> correct;
    switch (filter) {
      case QuizTrendFilter.both:
        attempts = _quizDailyAttempts;
        correct = _quizDailyCorrectByDay;
        break;
      case QuizTrendFilter.guessName:
        attempts = _quizNameDailyAttempts;
        correct = _quizNameDailyCorrect;
        break;
      case QuizTrendFilter.guessLine:
        attempts = _quizLineDailyAttempts;
        correct = _quizLineDailyCorrect;
        break;
    }

    final keys = attempts.keys.toSet().union(correct.keys.toSet()).toList()
      ..sort();
    if (keys.isEmpty) return const <QuizAccuracyPoint>[];
    final recentKeys = keys.length <= days
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

  int _baseQuizPoints() {
    switch (_quizDifficulty) {
      case QuizDifficulty.easy:
        return 60;
      case QuizDifficulty.medium:
        return 95;
      case QuizDifficulty.hard:
        return 130;
    }
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

    unawaited(_saveQuizStats());
  }

  void _setQuizDifficulty(QuizDifficulty difficulty) {
    if (_quizDifficulty == difficulty) return;
    setState(() {
      _quizDifficulty = difficulty;
    });
    unawaited(_saveQuizStats());
  }

  void _setQuizQuestionTarget(int target) {
    if (_quizQuestionsTarget == target) return;
    setState(() {
      _quizQuestionsTarget = target;
    });
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
    _quizPlayActive = false;
    _quizPlayArrowCount = 0;
    _quizPlayBoard = <String, String>{};
    _quizFlyFrom = null;
    _quizFlyTo = null;
    _quizFlyPiece = null;
    _quizFlyProgress = 0.0;
  }

  void _resetQuizToSetupState() {
    _quizSessionStarted = false;
    _quizSessionAnswered = 0;
    _quizSessionCorrect = 0;
    _clearQuizRoundState();
  }

  void _returnToQuizSetup() {
    setState(_resetQuizToSetupState);
  }

  void _openGambitQuizFromMenu() {
    setState(() {
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
    if (!_quizSessionStarted) {
      _startQuizSession();
      return;
    }
    if (_quizAnswered && _quizSessionAnswered >= _quizQuestionsTarget) {
      await _finishQuizSession();
      return;
    }
    _startQuizRound();
  }

  void _openQuizStatsSheet() {
    var filter = QuizTrendFilter.both;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10131B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            child: _buildQuizStatsCard(
              filter: filter,
              onFilterChanged: (next) {
                setSheetState(() => filter = next);
              },
            ),
          ),
        ),
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

    final maxPrefix = tokens.length - 1;
    final int prefix;
    if (mode == GambitQuizMode.guessLine) {
      // Guess Line always starts from exactly 2 ply (two moved pieces).
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

    return QuizBoardSnapshot(
      boardState: state,
      whiteToMove: whiteToMove,
      shownPly: prefix,
      continuation: continuation,
    );
  }

  void _startQuizRound({GambitQuizMode? mode}) {
    final gambits = _uniqueGambits();
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
        if (mode != null) _quizMode = mode;
      });
      return;
    }

    final activeMode = mode ?? _quizMode;
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
          // Skip weak line quizzes with fewer than 3 total answer choices.
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
      final linePool = gambits
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
      while (options.length < targetOptions) {
        final candidate = gambits[random.nextInt(gambits.length)];
        if (!options.any((entry) => entry.name == candidate.name)) {
          options.add(candidate);
        }
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
      _quizPlayActive = false;
      _quizPlayArrowCount = 0;
      _quizPlayBoard = <String, String>{};
      _quizFlyFrom = null;
      _quizFlyTo = null;
      _quizFlyPiece = null;
      _quizFlyProgress = 0.0;
      if (activeMode == GambitQuizMode.guessName) {
        _quizPrompt = 'Name this gambit from the position and continuation.';
        _quizPromptFocus = '';
        _quizOptions = options.map((entry) => entry.name).toList();
      } else {
        _quizPrompt = 'Pick the correct continuation for';
        _quizPromptFocus = resolvedCorrect.name;
        _quizOptions = options.map((entry) => entry.normalizedMoves).toList();
      }
    });
  }

  /// Returns the center point of a square in the quiz board widget.
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
    if (!mounted || _quizContinuation.isEmpty || _quizBoardState.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 420));
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

      final boardDuringFlight = Map<String, String>.from(board)
        ..remove(from);
      setState(() {
        _quizPlayBoard = boardDuringFlight;
        _quizFlyFrom = from;
        _quizFlyTo = to;
        _quizFlyPiece = piece;
        _quizFlyProgress = 0.0;
      });

      for (final step in const <double>[
        0.125,
        0.25,
        0.375,
        0.5,
        0.625,
        0.75,
        0.875,
        1.0,
      ]) {
        if (!mounted || !_quizPlayActive) return;
        setState(() {
          _quizFlyProgress = step;
        });
        await Future.delayed(const Duration(milliseconds: 60));
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

      if (i < _quizContinuation.length - 1) {
        await Future.delayed(const Duration(milliseconds: 340));
        if (!mounted || !_quizPlayActive) return;
      }
    }

    if (mounted) setState(() => _quizPlayActive = false);
  }

  void _submitQuizAnswer(int index) {
    if (_quizAnswered) return;
    final isCorrect = index == _quizCorrectIndex;
    setState(() {
      _quizSelectedIndex = index;
      _quizAnswered = true;
      _quizSessionAnswered += 1;
      if (isCorrect) {
        _quizSessionCorrect += 1;
      }
        _quizFeedback = isCorrect
          ? 'Correct. Great pattern recognition.'
          : (_quizMode == GambitQuizMode.guessLine
            ? 'Not quite. The correct continuation is highlighted.'
            : 'Not quite. Correct answer: ${_quizOptions[_quizCorrectIndex]}');
      _recordQuizResult(isCorrect: isCorrect);
    });
    if (_quizBoardState.isNotEmpty && _quizContinuation.isNotEmpty) {
      unawaited(_startQuizPlayback());
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
      });
      unawaited(_ensureEngineStarted());
      _resetBoard(initialLaunch: true, withIntro: true);
      _analyze();
    } catch (e) {
      _addLog('Enter analysis failed: $e');
      debugPrint('Enter analysis failed: $e');
    }
  }

  void _goToMenu() {
    if (_activeSection == AppSection.gambitQuiz) {
      setState(() {
        _resetQuizToSetupState();
        _activeSection = AppSection.menu;
      });
      unawaited(_playMenuMusic());
      return;
    }

    _menuExitAnimationController.reset();
    _sectionTransitionController.reset();
    _sectionTransitionController.forward().then((_) {
      setState(() {
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

      if (!mounted) return;
      setState(() {
        _activeSection = AppSection.menu;
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
                    : _buildGambitQuizScreen(),
              ),
            ),
          ),
        );
      },
    );
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
    return moves;
  }

  void _handleHoldTap(String square) {
    if (_isChoosingGambit) return;

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
      _onMove(from, square);
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

  Map<String, String> _applyUciMove(Map<String, String> state, String uciMove) {
    final updated = Map<String, String>.from(state);
    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final piece = updated[from];
    if (piece == null) return updated;

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
  void _onMove(String from, String to) {
    if (from == to) return;
    String piece = boardState[from]!;
    String? captured = boardState[to];

    // Opening matching needs SAN-like notation such as e4, exd5, Nf3, Rxe5.
    final notation = _buildMoveNotation(from, to, piece, captured);

    _addLog('Recorded move notation: $notation');

    setState(() {
      // If we're not at the end of history, discard outdated future moves.
      if (_historyIndex < _moveHistory.length - 1) {
        _moveHistory.removeRange(_historyIndex + 1, _moveHistory.length);
      }
      boardState[to] = piece;
      boardState.remove(from);
      _moveHistory.add(
        MoveRecord(
          notation: notation,
          pieceMoved: piece,
          pieceCaptured: captured,
          state: Map.from(boardState),
          isWhite: _isWhiteTurn,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_historyScrollController.hasClients) {
        _historyScrollController.animateTo(
          _historyScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });

    _analyze();
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
      _currentOpening = _findOpeningFromHistory();
      _holdSelectedFrom = null;
      _gambitSelectedFrom = null;
      _legalTargets.clear();
      _gambitAvailableTargets.clear();
      _selectedGambit = null;
      _gambitPreviewLines = [];
    });
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
    return "$fen ${_isWhiteTurn ? 'w' : 'b'} - - 0 1";
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

  Offset _introButtonCenter(Size scene) =>
      Offset(scene.width / 2, scene.height - 52);

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
      final start = yellow
          ? Offset(scene.width * 0.22, 46 - topInsetCompensation)
          : Offset(scene.width * 0.76, 96 - topInsetCompensation);
      final settle =
          boardCenter +
          (yellow ? const Offset(-42, -58) : const Offset(48, -18));
      return Offset.lerp(start, settle, p)!;
    }

    if (t < 0.56) {
      final q = (t - 0.22) / 0.34;
      final centerDrift = Offset(
        sin(q * pi * 1.3) * 14,
        cos(q * pi * 1.15) * 6,
      );
      final pairCenter = boardCenter + centerDrift;
      final inspectAngle = (q * pi * 2 * 1.15) + (yellow ? 0.7 : 3.4);
      final inspectRadius = 34 - (6 * sin(q * pi * 2));
      final flirt = Offset(
        sin(q * pi * 4 + (yellow ? 0.0 : pi / 2)) * 7,
        cos(q * pi * 3 + (yellow ? pi / 3 : pi)) * 5,
      );
      return pairCenter +
          flirt +
          Offset(
            cos(inspectAngle) * inspectRadius,
            sin(inspectAngle) * inspectRadius * 0.88,
          );
    }

    if (t < 0.68) {
      final q = (t - 0.56) / 0.12;
      final eased = Curves.easeInOutCubic.transform(q);
      final radius = 46 - (18 * eased);
      final angle = (q * pi * 2 * 2.8) + (yellow ? 0 : pi);
      return boardCenter +
          Offset(cos(angle) * radius, sin(angle) * radius * 0.68);
    }

    if (t < 0.86) {
      final q = (t - 0.68) / 0.18;
      final travelCenter = Offset.lerp(
        boardCenter,
        buttonCenter,
        Curves.easeInOutCubic.transform(q),
      )!;
      final radius = 26 - (14 * q);
      final angle = (q * pi * 2 * 3.0) + (yellow ? 0 : pi);
      return travelCenter +
          Offset(cos(angle) * radius, sin(angle) * radius * 0.72);
    }

    final q = (t - 0.86) / 0.14;
    final radius = 12 - (8 * Curves.easeIn.transform(q));
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

    final boardBox = boardContext.findRenderObject() as RenderBox?;
    final sceneBox = sceneContext.findRenderObject() as RenderBox?;
    if (boardBox == null || sceneBox == null) return null;

    final boardTopLeft = sceneBox.globalToLocal(
      boardBox.localToGlobal(Offset.zero),
    );
    final size = boardBox.size;
    const inset = 2.0;
    final sq = (size.width - inset * 2) / 8;

    var col = square.codeUnitAt(0) - 97;
    var row = int.parse(square[1]) - 1;
    final reverse =
        (_perspective == BoardPerspective.black) ||
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

      final buttonBox = buttonContext.findRenderObject() as RenderBox?;
      final sceneBox = sceneContext.findRenderObject() as RenderBox?;
      if (buttonBox == null || sceneBox == null) {
        if (!completer.isCompleted) completer.complete();
        return;
      }

      final buttonCenter = sceneBox.globalToLocal(
        buttonBox.localToGlobal(buttonBox.size.center(Offset.zero)),
      );
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

  // --- UI Sections ---
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.f5) {
          unawaited(_resetFromHotkey());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: _activeSection == AppSection.analysis
          ? _buildAnalysisBoardScaffold(context)
          : Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B0F19),
                      Color(0xFF080A12),
                      Color(0xFF101624),
                    ],
                    stops: [0.0, 0.55, 1.0],
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
                                    'assets/logo.png',
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
                                  'assets/logo.png',
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
        final t = _pulseController.value;
        final blueOrb = Alignment(
          -0.66 + 0.05 * sin(t * pi * 2),
          -0.24 + 0.03 * cos(t * pi * 2),
        );
        final goldOrb = Alignment(
          0.66 + 0.05 * cos(t * pi * 2),
          -0.24 + 0.03 * sin(t * pi * 2),
        );
        final fusionPulse = 0.22 + 0.13 * (0.5 + 0.5 * sin(t * pi * 2));

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF060912),
                      Color(0xFF0B1022),
                      Color(0xFF12102A),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: coreBlue.withValues(alpha: 0.2),
                      blurRadius: 120,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    Align(
                      alignment: blueOrb,
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: coreBlue.withValues(alpha: 0.16),
                          boxShadow: [
                            BoxShadow(
                              color: coreBlue.withValues(alpha: 0.55),
                              blurRadius: 60,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: goldOrb,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: coreGold.withValues(alpha: 0.15),
                          boxShadow: [
                            BoxShadow(
                              color: coreGold.withValues(alpha: 0.5),
                              blurRadius: 56,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, -0.22),
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fusionGreen.withValues(alpha: fusionPulse),
                          boxShadow: [
                            BoxShadow(
                              color: fusionGreen.withValues(alpha: 0.7),
                              blurRadius: 70,
                            ),
                          ],
                        ),
                      ),
                    ),
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
                      child: Image.asset(
                        'assets/logo.png',
                        width: 220,
                        fit: BoxFit.contain,
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
                            Container(
                              width: 360,
                              height: 360,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 2,
                                ),
                              ),
                            ),
                            Container(
                              width: 285,
                              height: 285,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            Container(
                              width: 220,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0D1020,
                                ).withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0x66D8B640),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _menuGlyphButton(
                                    label: 'ANALYSIS',
                                    icon: Icons.analytics_outlined,
                                    accent: coreGold,
                                    onTap: () =>
                                        unawaited(_enterAnalysisBoard()),
                                  ),
                                  _menuGlyphButton(
                                    label: 'GAMBIT QUIZ',
                                    icon: Icons.extension_outlined,
                                    accent: coreBlue,
                                    onTap: _openGambitQuizFromMenu,
                                  ),
                                  _menuGlyphButton(
                                    label: 'STORE',
                                    icon: Icons.storefront_outlined,
                                    accent: fusionGreen,
                                    onTap: _openStore,
                                  ),
                                  _menuGlyphButton(
                                    label: 'CREDITS',
                                    icon: Icons.info_outline,
                                    accent: Colors.white70,
                                    onTap: _showCreditsDialog,
                                  ),
                                ],
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
                          backgroundColor: const Color(0xFF10172A),
                          foregroundColor: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Settings'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10172A),
                          foregroundColor: Colors.white70,
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
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                accent.withValues(alpha: 0.14),
                const Color(0x14000000),
                accent.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: accent,
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

  Widget _buildGambitQuizScreen() {
    final gambits = _uniqueGambits();
    final hasQuizBoard =
        _quizBoardState.isNotEmpty && _quizContinuation.isNotEmpty;
    final revealContinuation =
      hasQuizBoard &&
      (_quizMode == GambitQuizMode.guessName || _quizAnswered);
    final isCorrectAnswer =
        _quizAnswered && _quizSelectedIndex == _quizCorrectIndex;

    if (!_quizSessionStarted) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _goToMenu,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to menu',
                ),
                const SizedBox(width: 6),
                const Text(
                  'Gambit Puzzles',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _openAppearanceSettings,
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: 'Board & Pieces',
                ),
                IconButton(
                  onPressed: _openQuizStatsSheet,
                  icon: const Icon(Icons.insights_outlined),
                  tooltip: 'Performance Stats',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF121B2E),
                    Color(0xFF0F1626),
                    Color(0xFF0B111E),
                  ],
                  stops: [0.0, 0.55, 1.0],
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
                  const Text(
                    'Mode',
                    style: TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Guess Gambit Name'),
                        selected: _quizMode == GambitQuizMode.guessName,
                        selectedColor: const Color(
                          0xFF5AAEE8,
                        ).withValues(alpha: 0.20),
                        side: BorderSide(
                          color: _quizMode == GambitQuizMode.guessName
                              ? const Color(0xFF5AAEE8)
                              : Colors.white24,
                        ),
                        labelStyle: TextStyle(
                          color: _quizMode == GambitQuizMode.guessName
                              ? const Color(0xFF8FD0FF)
                              : Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => setState(
                          () => _quizMode = GambitQuizMode.guessName,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Guess Gambit Line'),
                        selected: _quizMode == GambitQuizMode.guessLine,
                        selectedColor: const Color(
                          0xFF5AAEE8,
                        ).withValues(alpha: 0.20),
                        side: BorderSide(
                          color: _quizMode == GambitQuizMode.guessLine
                              ? const Color(0xFF5AAEE8)
                              : Colors.white24,
                        ),
                        labelStyle: TextStyle(
                          color: _quizMode == GambitQuizMode.guessLine
                              ? const Color(0xFF8FD0FF)
                              : Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => setState(
                          () => _quizMode = GambitQuizMode.guessLine,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Difficulty',
                    style: TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: QuizDifficulty.values.map((difficulty) {
                      final selected = _quizDifficulty == difficulty;
                      final color = _quizDifficultyColor(difficulty);
                      return ChoiceChip(
                        label: Text(_quizDifficultyLabel(difficulty)),
                        selected: selected,
                        selectedColor: color.withValues(alpha: 0.2),
                        side: BorderSide(
                          color: selected
                              ? color.withValues(alpha: 0.9)
                              : Colors.white24,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? color : Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        onSelected: (_) => _setQuizDifficulty(difficulty),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Questions',
                    style: TextStyle(
                      color: Colors.white60,
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
                              : Colors.white24,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? const Color(0xFFE4CA79)
                              : Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => _setQuizQuestionTarget(target),
                      );
                    }).toList(),
                  ),
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
            Text(
              '${_viewedGambits.length}/${gambits.length} gambits viewed',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget buildQuizBoardCard() {
      final reverse =
          _perspective == BoardPerspective.black ||
          (_perspective == BoardPerspective.auto && !_quizWhiteToMove);
      final visibleArrows = !_quizAnswered
        ? _quizContinuation
        : _quizContinuation.take(
          _quizPlayArrowCount == 0
            ? _quizContinuation.length
            : _quizPlayArrowCount,
        ).toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1420).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFB9A46A).withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Position after $_quizShownPly ply',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                Text(
                  _quizWhiteToMove ? 'White to move' : 'Black to move',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10, width: 1.2),
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
                        _buildQuizBoard(),
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
                        if (flyFromPx != null &&
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
          ],
        ),
      );
    }

    List<Widget> buildQuizOptionButtons() {
      return [
        for (int i = 0; i < _quizOptions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _quizAnswered ? null : () => _submitQuizAnswer(i),
                icon: _quizAnswered
                    ? Icon(
                        i == _quizCorrectIndex
                            ? Icons.check_circle
                            : (i == _quizSelectedIndex
                                  ? Icons.cancel
                                  : Icons.radio_button_unchecked),
                        size: 18,
                        color: i == _quizCorrectIndex
                            ? const Color(0xFF7EDC8A)
                            : (i == _quizSelectedIndex
                                  ? const Color(0xFFFF8A80)
                                  : Colors.white30),
                      )
                    : const Icon(
                        Icons.help_outline,
                        size: 17,
                        color: Colors.white38,
                      ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  side: BorderSide(
                    color: _quizAnswered && i == _quizCorrectIndex
                        ? const Color(0xFF7EDC8A).withValues(alpha: 0.7)
                        : Colors.white24,
                  ),
                  backgroundColor: _quizAnswered && i == _quizCorrectIndex
                      ? const Color(0xFF7EDC8A).withValues(alpha: 0.12)
                      : (_quizAnswered && i == _quizSelectedIndex
                            ? const Color(0xFFFF8A80).withValues(alpha: 0.08)
                            : null),
                ),
                label: _quizMode == GambitQuizMode.guessLine
                    ? _buildMoveSequenceText(
                        _quizOptions[i],
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        _quizOptions[i],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
          ),
      ];
    }

    Widget buildQuizPromptBlock() {
      if (_quizPrompt.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1627).withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _quizPrompt,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_quizPromptFocus.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _quizPromptFocus,
                style: const TextStyle(
                  color: Color(0xFFFFD88A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _returnToQuizSetup,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Setup',
              ),
              Expanded(
                child: Text(
                  '${_quizMode == GambitQuizMode.guessName ? 'Guess Name' : 'Guess Line'} · ${_quizDifficultyLabel(_quizDifficulty)} · $_quizQuestionsTarget Q',
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
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Board & Pieces',
              ),
              IconButton(
                onPressed: _openQuizStatsSheet,
                icon: const Icon(Icons.insights_outlined),
                tooltip: 'Performance Stats',
              ),
              Text(
                'Q ${min(_quizSessionAnswered + (_quizAnswered ? 0 : 1), _quizQuestionsTarget)}/$_quizQuestionsTarget',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide =
                    isLandscape && hasQuizBoard && constraints.maxWidth >= 700;

                if (sideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          child: buildQuizBoardCard(),
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
          if (_quizFeedback.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                _quizFeedback,
                style: TextStyle(
                  color: isCorrectAnswer
                      ? const Color(0xFF7EDC8A)
                      : const Color(0xFFFFB26A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _handleQuizPrimaryAction,
              icon: Icon(
                _quizAnswered && _quizSessionAnswered >= _quizQuestionsTarget
                    ? Icons.flag_rounded
                    : Icons.navigate_next_rounded,
              ),
              label: Text(
                _quizAnswered
                    ? (_quizSessionAnswered >= _quizQuestionsTarget
                          ? 'Finish Session'
                          : 'Next Puzzle')
                    : 'Skip Puzzle',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStatsCard({
    required QuizTrendFilter filter,
    required ValueChanged<QuizTrendFilter> onFilterChanged,
  }) {
    final accuracy = _quizAccuracy();
    final series = _buildQuizAccuracySeries(filter, days: 10);
    final latest = series.isEmpty ? null : series.last.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF131D31), Color(0xFF0F1728), Color(0xFF0A1220)],
          stops: [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5AAEE8).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quiz Performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (latest != null)
                Text(
                  'Latest ${latest.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF8FD0FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quizMetricChip(
                'Score',
                _quizScore.toString(),
                const Color(0xFFD8B640),
              ),
              _quizMetricChip(
                'Streak',
                _quizStreak.toString(),
                const Color(0xFF7EDC8A),
              ),
              _quizMetricChip(
                'Best',
                _quizBestStreak.toString(),
                const Color(0xFF5AAEE8),
              ),
              _quizMetricChip(
                'Accuracy',
                '${accuracy.toStringAsFixed(1)}%',
                const Color(0xFFFFB26A),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QuizTrendFilter.values.map((entry) {
              final selected = entry == filter;
              return ChoiceChip(
                label: Text(_quizTrendFilterLabel(entry)),
                selected: selected,
                selectedColor: const Color(0xFF5AAEE8).withValues(alpha: 0.22),
                side: BorderSide(
                  color: selected ? const Color(0xFF5AAEE8) : Colors.white24,
                ),
                labelStyle: TextStyle(
                  color: selected ? const Color(0xFF8FD0FF) : Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
                onSelected: (_) => onFilterChanged(entry),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          if (series.isEmpty)
            const Text(
              'Play puzzles in this mode to build your accuracy trend.',
              style: TextStyle(color: Colors.white54, fontSize: 11.5),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1220).withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 112,
                    child: CustomPaint(
                      painter: QuizAccuracyTrendPainter(series: series),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final point in series)
                        Expanded(
                          child: Text(
                            point.dayLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _quizMetricChip(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildQuizBoard() {
    final darkSquareColor = _darkSquareColorForTheme();
    final lightSquareColor = _lightSquareColorForTheme();
    final boardState = _quizPlayBoard.isNotEmpty
      ? _quizPlayBoard
      : _quizBoardState;
    final reverse =
        _perspective == BoardPerspective.black ||
        (_perspective == BoardPerspective.auto && !_quizWhiteToMove);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemCount: 64,
      itemBuilder: (context, i) {
        int row, col;
        if (reverse) {
          row = i ~/ 8;
          col = 7 - i % 8;
        } else {
          row = 7 - i ~/ 8;
          col = i % 8;
        }
        final sq = '${String.fromCharCode(97 + col)}${row + 1}';
        final isDark = (row + col) % 2 == 0;
        final piece = boardState[sq];

        return Container(
          decoration: BoxDecoration(
            color: isDark ? darkSquareColor : lightSquareColor,
          ),
          child: piece == null
              ? null
              : Center(child: _pieceImage(piece)),
        );
      },
    );
  }

  Widget _buildAnalysisBoardScaffold(BuildContext context) {
    bool reverse =
        (_perspective == BoardPerspective.black) ||
        (_perspective == BoardPerspective.auto && !_isWhiteTurn);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F19), Color(0xFF080A12), Color(0xFF101624)],
            stops: [0.0, 0.55, 1.0],
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
                  color: const Color(0xFF3F6ED8).withValues(alpha: 0.16),
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
                  color: const Color(0xFFB9A46A).withValues(alpha: 0.12),
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
                                    _buildEvalBarHorizontal(scale),
                                    SizedBox(
                                      height: 0,
                                      child: OverflowBox(
                                        maxHeight: 28 * scale,
                                        alignment: Alignment.topCenter,
                                        child: _buildOpeningLabel(scale),
                                      ),
                                    ),
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
                                                    builder: (
                                                      context,
                                                      boardBox,
                                                    ) {
                                                      final boardSize = max(
                                                        0.0,
                                                        min(
                                                          boardBox.maxWidth,
                                                          boardBox.maxHeight,
                                                        ),
                                                      );
                                                      return Center(
                                                        child: SizedBox(
                                                          key: _boardKey,
                                                          width: boardSize,
                                                          height: boardSize,
                                                          child: Stack(
                                                            children: [
                                                              Opacity(
                                                                opacity:
                                                                    _boardIntroOpacity(),
                                                                child:
                                                                    _buildBoard(
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
                                                const SizedBox(width: 12),
                                                SizedBox(
                                                  width: sideWidth,
                                                  child: LayoutBuilder(
                                                    builder: (
                                                      context,
                                                      sideConstraints,
                                                    ) {
                                                      final suggestionsHeight =
                                                          (sideConstraints
                                                                  .maxHeight *
                                                              0.46)
                                                              .clamp(96.0, 220.0);
                                                      final historyHeight =
                                                          (sideConstraints
                                                                  .maxHeight *
                                                              0.16)
                                                              .clamp(46.0, 72.0);
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          if (_selectedGambit != null)
                                                            Padding(
                                                              padding: const EdgeInsets.only(
                                                                bottom: 6,
                                                              ),
                                                              child: Text(
                                                                _selectedGambit!.name,
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: Color(0xFFD8B640),
                                                                ),
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          _buildSuggestedMovesList(
                                                            height:
                                                                suggestionsHeight,
                                                          ),
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
                                    SizedBox(
                                      height: 0,
                                      child: OverflowBox(
                                        maxHeight: 32 * scale,
                                        alignment: Alignment.topCenter,
                                        child: _buildOpeningLabel(scale),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: LayoutBuilder(
                                          builder: (context, inner) {
                                            final boardSize = min(
                                              inner.maxWidth,
                                              inner.maxHeight,
                                            );
                                            return Center(
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
                                    _buildSuggestedMovesList(),
                                    _buildHistoryBar(),
                                    _buildActionArea(),
                                  ],
                                ),
                        ),
                        if (!_introCompleted)
                          _buildPremiumIntroOverlay(Size(width, height)),
                        _buildSuggestionLaunchOverlay(),
                        _buildButtonRippleOverlay(),
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
    final displayedEval = _displayEvalForPov();
    final displayedEvalColor = _displayEvalColor(displayedEval);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 8 * scale,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  "Engine: Stockfish 18",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10 * scale,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14 * scale,
                  vertical: 6 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111723).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFB9A46A).withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "${displayedEval > 0 ? '+' : ''}${displayedEval.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: displayedEvalColor,
                    fontSize: 14 * scale,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Depth $_currentDepth",
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 11 * scale,
                    ),
                  ),
                  SizedBox(width: 4 * scale),
                  IconButton(
                    onPressed: _showLogsDialog,
                    icon: Icon(
                      Icons.bug_report_outlined,
                      color: Colors.white38,
                      size: 16 * scale,
                    ),
                    splashRadius: 14 * scale,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: 20 * scale,
                      height: 20 * scale,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvalBarHorizontal(double scale) {
    final displayedEval = _displayEvalForPov();
    final displayedEvalColor = _displayEvalColor(displayedEval);
    final showWinningAura = displayedEval > 5.0;
    double fill = (0.5 + displayedEval / 8).clamp(0.0, 1.0);
    return Container(
      height: 6 * scale,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: Colors.white10,
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
    );
  }

  Widget _buildOpeningLabel(double scale) {
    if (_currentOpening.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 4 * scale,
      ),
      child: Text(
        _currentOpening,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12 * scale,
          fontWeight: FontWeight.w600,
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
          int row = reverse ? (i ~/ 8) : (7 - i ~/ 8);
          int col = reverse ? (7 - i % 8) : (i % 8);
          String sq = String.fromCharCode(97 + col) + (row + 1).toString();
          bool isDark = (row + col) % 2 == 0;
          String? p = boardState[sq];
          final isGambitSelected = _gambitSelectedFrom == sq;
          final isHoldSelected = _holdSelectedFrom == sq;
          final isLegalTarget = _legalTargets.contains(sq);
          final isGambitAvailableTarget = _gambitAvailableTargets.contains(sq);
          final isCaptureTarget = isLegalTarget && p != null;

          return DragTarget<String>(
            onAcceptWithDetails: (d) {
              if (_isChoosingGambit) {
                _handleGambitDragDrop(d.data, sq);
                return;
              }
              _onMove(d.data, sq);
            },
            builder: (context, candidateData, rejectedData) => Container(
              decoration: BoxDecoration(
                color: isDark ? darkSquareColor : lightSquareColor,
                border: (isGambitSelected || isHoldSelected)
                    ? Border.all(color: const Color(0xFFFFD166), width: 2)
                    : null,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _isChoosingGambit
                    ? _handleBoardTap(sq)
                    : _handleHoldTap(sq),
                onLongPress: () {
                  if (_isChoosingGambit) return;
                  if (!_isCurrentTurnPiece(p)) return;
                  setState(() {
                    _holdSelectedFrom = sq;
                    _gambitSelectedFrom = null;
                    _legalTargets
                      ..clear()
                      ..addAll(_legalMovesFrom(sq));
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isLegalTarget)
                      Center(
                        child: Container(
                          width: isCaptureTarget ? 26 : 12,
                          height: isCaptureTarget ? 26 : 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCaptureTarget
                                ? Colors.transparent
                                : (_isChoosingGambit
                                      ? (isGambitAvailableTarget
                                            ? const Color(
                                                0xFFFFD166,
                                              ).withValues(alpha: 0.55)
                                            : Colors.white.withValues(
                                                alpha: 0.45,
                                              ))
                                      : Colors.white.withValues(alpha: 0.45)),
                            border: isCaptureTarget
                                ? Border.all(
                                    color:
                                        (_isChoosingGambit &&
                                            isGambitAvailableTarget)
                                        ? const Color(
                                            0xFFFFD166,
                                          ).withValues(alpha: 0.75)
                                        : Colors.white.withValues(alpha: 0.65),
                                    width: 2,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    if (p != null)
                      Center(
                        child: Draggable<String>(
                          data: sq,
                          feedback: _buildPieceGlow(p),
                          onDragStarted: () {
                            if (!_isCurrentTurnPiece(p)) return;
                            setState(() {
                              if (_isChoosingGambit) {
                                _selectGambitSource(sq);
                              } else {
                                _holdSelectedFrom = sq;
                                _gambitSelectedFrom = null;
                                _legalTargets
                                  ..clear()
                                  ..addAll(_legalMovesFrom(sq));
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
                          child: _pieceImage(p),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF335AAE).withValues(alpha: 0.45)
            : const Color(0xFF121724).withValues(alpha: 0.72),
        border: Border.all(
          color: active
              ? const Color(0xFFB9A46A).withValues(alpha: 0.35)
              : Colors.white12,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _pieceImage(move.pieceMoved, width: 18, height: 18),
          const SizedBox(width: 4),
          Text(
            move.notation,
            style: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontSize: 13,
            ),
          ),
          if (move.pieceCaptured != null) ...[
            const SizedBox(width: 4),
            _pieceImage(move.pieceCaptured!, width: 16, height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildPieceGlow(String p) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.6),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: _pieceImage(p),
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
        child: CustomPaint(
          size: Size.infinite,
          painter: EnergyArrowPainter(
            lines: lines,
            bestEval: (_currentEval * 100).toInt(),
            progress: _pulseController.value,
            reverse: reverse,
            showSequenceNumbers: showSequenceNumbers,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedMovesList({double height = 130}) {
    return SizedBox(
      height: height,
      child: _topLines.isEmpty
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
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

  Widget _buildActionArea({
    double compactBottom = 20,
    double horizontal = 20,
  }) {
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
          _iconBtn(
            _isChoosingGambit
                ? Icons.auto_awesome
                : Icons.auto_awesome_outlined,
            _toggleGambitMode,
          ),
          _iconBtn(Icons.settings_outlined, _openSettings),
        ],
      ),
    );
  }

  Widget _buildSuggestionTriggerButton() {
    if (_suggestionsEnabled) {
      return GestureDetector(
        key: _suggestionButtonKey,
        onTap: () => setState(() {
          _isWhiteTurn = !_isWhiteTurn;
          _analyze();
        }),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isWhiteTurn
                ? const Color(0xFFEDEFF4)
                : const Color(0xFF111319),
            border: Border.all(
              color: const Color(0xFFB9A46A).withValues(alpha: 0.42),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _pieceImage(
            _isWhiteTurn ? 'p_w' : 'p_b',
            width: 28,
            height: 28,
          ),
        ),
      );
    }

    return GestureDetector(
      key: _suggestionButtonKey,
      onTap: (!_buttonUnlocked || _suggestionLaunchInProgress)
          ? null
          : () async {
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
                await _fireSuggestionLaunch();
              } else {
                // Pulse a green ripple from the button position
                final buttonContext = _suggestionButtonKey.currentContext;
                final sceneContext = _sceneKey.currentContext;
                if (buttonContext != null && sceneContext != null) {
                  final buttonBox =
                      buttonContext.findRenderObject() as RenderBox?;
                  final sceneBox =
                      sceneContext.findRenderObject() as RenderBox?;
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
              _addLog('Suggestions started');
            },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _introController]),
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

          Offset yellow;
          Offset blue;
          double coreIntensity;

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
            final angle = pulseT * pi * 2;
            const orbit = 11.0;
            yellow = Offset(cos(angle) * orbit, sin(angle) * orbit);
            blue = Offset(cos(angle + pi) * orbit, sin(angle + pi) * orbit);
            coreIntensity = 0.9;
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
                Transform.translate(
                  offset: yellow,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8B640),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD8B640).withValues(alpha: 0.7),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: blue,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F6ED8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3F6ED8).withValues(alpha: 0.7),
                          blurRadius: 10,
                        ),
                      ],
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
    return IconButton(
      onPressed: _openStore,
      icon: const Icon(Icons.storefront_outlined, color: Color(0xFFC7CBD6)),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF121724).withValues(alpha: 0.78),
        side: const BorderSide(color: Colors.white12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _iconBtn(IconData i, VoidCallback fn) => IconButton(
    onPressed: fn,
    icon: Icon(i, color: const Color(0xFFC7CBD6)),
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xFF121724).withValues(alpha: 0.78),
      side: const BorderSide(color: Colors.white12),
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

  void _showCreditsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final dialogHeight = min(
          MediaQuery.of(context).size.height * 0.82,
          700.0,
        );
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: BoxConstraints(maxWidth: 560, maxHeight: dialogHeight),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF04122A), Color(0xFF030C1C)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
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
                          icon: const Icon(Icons.close, color: Colors.white70),
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
                          color: const Color(0xFF9ED8FF).withValues(alpha: 0.2),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2A6CF0).withValues(alpha: 0.08),
                            const Color(0xFF16D3E7).withValues(alpha: 0.06),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6FCBFF,
                            ).withValues(alpha: 0.18),
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
                      'Credits & Attribution',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildCreditRow('Creative Direction', 'QILA modus'),
                            _buildCreditRow('App Engineering', 'QILA modus'),
                            _buildCreditRow(
                              'Chess Engine',
                              'Stockfish (GPL-3.0)',
                            ),
                            _buildCreditRow(
                              'Opening Database',
                              'ECO data (MIT)',
                            ),
                            _buildCreditRow('Platform', 'Flutter / Dart'),
                            _buildCreditRow('Music', 'Created with Suno'),
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
                                    const Color(
                                      0xFF0E1B34,
                                    ).withValues(alpha: 0.92),
                                    const Color(
                                      0xFF091527,
                                    ).withValues(alpha: 0.9),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF16D3E7,
                                  ).withValues(alpha: 0.24),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.28),
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
                                        color: const Color(
                                          0xFF16D3E7,
                                        ).withValues(alpha: 0.95),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Ownership & Legal',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                          color: Color(0xFF16D3E7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ChessIQ original code, design, and project-specific assets are owned by QILA modus.',
                                    style: TextStyle(
                                      fontSize: 12.2,
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Full legal notices are available in COPYRIGHT.md and THIRD_PARTY_NOTICES.md.',
                                    style: TextStyle(
                                      fontSize: 11.6,
                                      color: Colors.white.withValues(
                                        alpha: 0.68,
                                      ),
                                      height: 1.32,
                                    ),
                                  ),
                                ],
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
                          _goToMenu();
                        },
                        child: const Text('Back to Main Menu'),
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

  Widget _buildCreditsDynamicBackdrop() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value;
        final yellow = Offset(
          0.33 + 0.19 * sin(t * pi * 2),
          0.26 + 0.10 * cos(t * pi * 2),
        );
        final blue = Offset(
          0.67 + 0.19 * cos(t * pi * 2),
          0.26 + 0.10 * sin(t * pi * 2),
        );
        final dx = yellow.dx - blue.dx;
        final dy = yellow.dy - blue.dy;
        final dist = sqrt(dx * dx + dy * dy);
        final collision = (1.0 - (dist / 0.20)).clamp(0.0, 1.0);
        final fusion = Offset(
          (yellow.dx + blue.dx) / 2,
          (yellow.dy + blue.dy) / 2,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x220C1732),
                        Color(0x140A1124),
                        Color(0x220E1A34),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment(yellow.dx * 2 - 1, yellow.dy * 2 - 1),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD8B640).withValues(alpha: 0.22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD8B640,
                          ).withValues(alpha: 0.55),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment(blue.dx * 2 - 1, blue.dy * 2 - 1),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3F6ED8).withValues(alpha: 0.22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF3F6ED8,
                          ).withValues(alpha: 0.55),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (collision > 0)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(fusion.dx * 2 - 1, fusion.dy * 2 - 1),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(
                          0xFF7EDC8A,
                        ).withValues(alpha: 0.14 + 0.24 * collision),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF7EDC8A,
                            ).withValues(alpha: 0.40 * collision),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              for (int i = 0; i < 7; i++)
                if (collision > 0.05)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(
                        (fusion.dx + 0.08 * cos(t * pi * 2 * (i + 1))) * 2 - 1,
                        (fusion.dy + 0.08 * sin(t * pi * 2 * (i + 1))) * 2 - 1,
                      ),
                      child: Container(
                        width: 3 + (i % 2),
                        height: 3 + (i % 2),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF7EDC8A,
                          ).withValues(alpha: 0.45 * collision),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7EDC8A,
                              ).withValues(alpha: 0.65 * collision),
                              blurRadius: 6,
                            ),
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
              style: const TextStyle(
                color: Color(0xFF16D3E7),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog<String?>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF151722),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 18),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop('menu'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3F6ED8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: const Icon(Icons.menu_rounded, size: 18),
                      label: const Text('Main Menu'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop('reset'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6CF0),
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
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
            ],
          ),
        ),
      ),
    ).then((result) async {
      if (result == 'reset') {
        await _playResetRewardAdIfNeeded();
        setState(() {
          _resetBoard();
          _analyze();
        });
      } else if (result == 'menu') {
        _goToMenu();
      }
    });
  }

  void _openAppearanceSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10131B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setL) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12 + MediaQuery.of(ctx).padding.top,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Board & Pieces',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'BOARD PERSPECTIVE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _perspectiveOption('White', BoardPerspective.white, setL),
                        _perspectiveOption('Black', BoardPerspective.black, setL),
                        _perspectiveOption('Auto', BoardPerspective.auto, setL),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'THEMES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Board Themes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _availableBoardThemes
                          .map((mode) => _boardThemeOption(_boardThemeLabel(mode), mode, setL))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Piece Themes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _availablePieceThemes
                          .map((mode) => _pieceThemeOption(_pieceThemeLabel(mode), mode, setL))
                          .toList(),
                    ),
                    if (_availableBoardThemes.length < BoardThemeMode.values.length ||
                        _availablePieceThemes.length < PieceThemeMode.values.length) ...
                      [
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Future.microtask(
                              () => _openStore(initialSection: StoreSection.themes),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D6EF2), Color(0xFF1F56C8)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF89AEFF).withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2A6CF0).withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Get More Themes',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        'Open Theme Store',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10131B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setL) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12 + MediaQuery.of(ctx).padding.top,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Settings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      "BOARD PERSPECTIVE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _perspectiveOption(
                          "White",
                          BoardPerspective.white,
                          setL,
                        ),
                        _perspectiveOption(
                          "Black",
                          BoardPerspective.black,
                          setL,
                        ),
                        _perspectiveOption("Auto", BoardPerspective.auto, setL),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'THEMES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Board Themes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _availableBoardThemes
                          .map(
                            (mode) => _boardThemeOption(
                              _boardThemeLabel(mode),
                              mode,
                              setL,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Piece Themes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _availablePieceThemes
                          .map(
                            (mode) => _pieceThemeOption(
                              _pieceThemeLabel(mode),
                              mode,
                              setL,
                            ),
                          )
                          .toList(),
                    ),
                    if (_availableBoardThemes.length <
                            BoardThemeMode.values.length ||
                        _availablePieceThemes.length <
                            PieceThemeMode.values.length) ...[
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Future.microtask(
                            () =>
                                _openStore(initialSection: StoreSection.themes),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D6EF2), Color(0xFF1F56C8)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(
                                0xFF89AEFF,
                              ).withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2A6CF0,
                                ).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Get More Themes',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      'Open Theme Store',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "SEARCH DEPTH",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_engineDepth',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00FF88),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _engineDepth.toDouble(),
                      min: 10,
                      max: _maxDepthAllowed.toDouble(),
                      divisions: _maxDepthAllowed - 10,
                      onChanged: (v) {
                        setState(() => _engineDepth = v.toInt());
                        setL(() {});
                        _analyze();
                      },
                      onChangeEnd: (_) => _persistCurrentSettings(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "SUGGESTED MOVES",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_multiPvCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00FF88),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _multiPvCount.toDouble(),
                      min: 1,
                      max: _maxSuggestionsAllowed.toDouble(),
                      divisions: _maxSuggestionsAllowed - 1,
                      onChanged: (v) {
                        setState(() => _multiPvCount = v.toInt());
                        setL(() {});
                        _send('setoption name MultiPV value ${v.toInt()}');
                        _analyze();
                      },
                      onChangeEnd: (_) => _persistCurrentSettings(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
      'suggestionsEnabled': _suggestionsEnabled,
      'boardState': boardState,
      'historyIndex': _historyIndex,
      'moveHistory': _moveHistory.map(_moveRecordToMap).toList(),
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
      default:
        return 'Standard';
    }
  }

  Future<void> _purchaseDepthTier(int targetTier) async {
    final price = switch (targetTier) {
      1 => 1800,
      2 => 2600,
      3 => 4200,
      _ => 0,
    };
    if (targetTier <= _depthTier || targetTier < 1 || targetTier > 3) return;
    if (targetTier != _depthTier + 1) {
      _addLog('Unlock tiers in order: Pro -> Expert -> Grandmaster');
      return;
    }
    if (_storeCoins < price) {
      _addLog('Not enough coins for ${_depthTierLabel()} upgrade');
      return;
    }

    setState(() {
      _storeCoins -= price;
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
    if (_storeCoins < price) {
      _addLog('Not enough coins for +1 suggestion');
      return;
    }

    setState(() {
      _storeCoins -= price;
      _extraSuggestionPurchases += 1;
    });
    await _saveStoreState();
    _addLog('Suggestions increased to $_maxSuggestionsAllowed');
  }

  Future<void> _purchaseThemePack() async {
    const price = 900;
    if (_themePackOwned) return;
    if (_storeCoins < price) {
      _addLog('Not enough coins for Theme Pack');
      return;
    }
    setState(() {
      _storeCoins -= price;
      _themePackOwned = true;
    });
    await _saveStoreState();
    _addLog('Theme Pack unlocked');
  }

  Future<void> _purchasePiecePack() async {
    const price = 1400;
    if (_piecePackOwned) return;
    if (_storeCoins < price) {
      _addLog('Not enough coins for Piece Set Pack');
      return;
    }
    setState(() {
      _storeCoins -= price;
      _piecePackOwned = true;
    });
    await _saveStoreState();
    _addLog('Piece Set Pack unlocked (Ember and Frost styles available)');
  }

  Future<void> _playResetRewardAdIfNeeded() async {
    if (_adFreeOwned) {
      return;
    }
    const reward = 180;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF151722),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.ondemand_video,
                color: Color(0xFFFFD166),
                size: 30,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sponsored Break',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ad played. You earned +180 coins.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() {
      _storeCoins += reward;
    });
    await _saveStoreState();
    _addLog('Reset ad reward claimed (+$reward coins)');
  }

  Future<void> _watchRewardAdFromStore() async {
    const reward = 220;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF151722),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: Color(0xFFFFD166),
                size: 30,
              ),
              const SizedBox(height: 8),
              const Text(
                'Reward Ad',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Watched! +220 coins added.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Claim'),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() {
      _storeCoins += reward;
    });
    await _saveStoreState();
    _addLog('Reward ad claimed (+$reward coins)');
  }

  Future<void> _buyCoinPack(int amount, String label) async {
    setState(() {
      _storeCoins += amount;
    });
    await _saveStoreState();
    _addLog('Purchased $label (+$amount coins)');
  }

  Future<void> _buyAdFree() async {
    if (_adFreeOwned) return;
    _adFreeOwned = true;
    await _saveStoreState();
    _addLog('Ad-Free activated');
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Ad-Free activated')));
  }

  Future<void> _resetPurchases() async {
    setState(() {
      _storeCoins = 0;
      _depthTier = 0;
      _extraSuggestionPurchases = 0;
      _themePackOwned = false;
      _piecePackOwned = false;
      _adFreeOwned = false;
      _perspective = _defaultPerspective;
      _boardThemeMode = _defaultBoardTheme;
      _pieceThemeMode = _defaultPieceTheme;
      _engineDepth = _engineDepth.clamp(10, _maxDepthAllowed);
      _multiPvCount = _multiPvCount.clamp(1, _maxSuggestionsAllowed);
      if (_multiPvCount >
          _defaultMultiPvCount.clamp(1, _maxSuggestionsAllowed)) {
        _multiPvCount = _defaultMultiPvCount.clamp(1, _maxSuggestionsAllowed);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storeStateKey);
    await prefs.remove(_savedDefaultSnapshotKey);
    await _saveStoreState();
    _send('setoption name MultiPV value $_multiPvCount');
    _analyze();
    _addLog('Store purchases and saved settings reset');
  }

  void _openStore({StoreSection initialSection = StoreSection.general}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10131B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setL) => SingleChildScrollView(
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      initialSection == StoreSection.themes
                          ? 'Store · Themes'
                          : 'Store',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2330),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      'Coins: $_storeCoins',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFD166),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).maybePop(),
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
                subtitle: 'Watch and earn +220 coins',
                priceLabel: 'Free',
                enabled: true,
                actionLabel: 'Watch',
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
                onTap: () async {
                  await _buyCoinPack(5000, 'Coin Pack L');
                  setL(() {});
                },
              ),
              _storeItemCard(
                icon: Icons.block_outlined,
                title: 'Ad-Free Pass',
                subtitle: _adFreeOwned
                    ? 'Owned (skips reset ads)'
                    : 'Skips ads when pressing reset',
                priceLabel: '\$6.99',
                enabled: !_adFreeOwned,
                actionLabel: _adFreeOwned ? 'Owned' : 'Buy',
                onTap: () async {
                  await _buyAdFree();
                  setL(() {});
                },
              ),
              const SizedBox(height: 10),
              _storeSectionHeader(
                'Themes',
                'Owned themes live here, and new ones unlock below',
              ),
              _buildThemeVaultCard(setL),
              _storeItemCard(
                icon: Icons.palette_outlined,
                title: 'Board Theme Pack',
                subtitle: _themePackOwned
                    ? 'Owned · unlocks Ember and Aurora boards'
                    : 'Unlock Ember and Aurora board palettes',
                priceLabel: '900 c',
                enabled: !_themePackOwned,
                actionLabel: _themePackOwned ? 'Owned' : 'Buy',
                preview: _themePackPreview(),
                onTap: () async {
                  await _purchaseThemePack();
                  setL(() {});
                },
              ),
              _storeItemCard(
                icon: Icons.extension_outlined,
                title: 'Piece Set Pack',
                subtitle: _piecePackOwned
                    ? 'Owned · unlocks Ember and Frost pieces'
                    : 'Unlock Ember and Frost piece styles',
                priceLabel: '1400 c',
                enabled: !_piecePackOwned,
                actionLabel: _piecePackOwned ? 'Owned' : 'Buy',
                preview: _piecePackPreview(),
                onTap: () async {
                  await _purchasePiecePack();
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
                subtitle: _depthTier >= 1
                    ? 'Unlocked (max ply depth 27)'
                    : 'Unlock ply depth 25-27',
                priceLabel: '1800 c',
                enabled: _depthTier == 0,
                actionLabel: _depthTier >= 1 ? 'Owned' : 'Unlock',
                onTap: () async {
                  await _purchaseDepthTier(1);
                  setL(() {});
                },
              ),
              _storeItemCard(
                icon: Icons.psychology_alt_outlined,
                title: 'Expert Mode',
                subtitle: _depthTier >= 2
                    ? 'Unlocked (max ply depth 29)'
                    : 'Unlock ply depth 28-29',
                priceLabel: '2600 c',
                enabled: _depthTier == 1,
                actionLabel: _depthTier >= 2
                    ? 'Owned'
                    : (_depthTier == 1 ? 'Unlock' : 'Locked'),
                onTap: () async {
                  await _purchaseDepthTier(2);
                  setL(() {});
                },
              ),
              _storeItemCard(
                icon: Icons.workspace_premium_outlined,
                title: 'Grandmaster Mode',
                subtitle: _depthTier >= 3
                    ? 'Unlocked (max ply depth 32)'
                    : 'Unlock ply depth 30-32',
                priceLabel: '4200 c',
                enabled: _depthTier == 2,
                actionLabel: _depthTier >= 3
                    ? 'Owned'
                    : (_depthTier == 2 ? 'Unlock' : 'Locked'),
                onTap: () async {
                  await _purchaseDepthTier(3);
                  setL(() {});
                },
              ),
              _storeItemCard(
                icon: Icons.add_circle_outline,
                title: '+1 Suggested Move',
                subtitle:
                    'Current max suggestions: $_maxSuggestionsAllowed / 10',
                priceLabel: '${500 + (_extraSuggestionPurchases * 120)} c',
                enabled: _maxSuggestionsAllowed < 10,
                actionLabel: _maxSuggestionsAllowed < 10 ? 'Buy +1' : 'Maxed',
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
                  style: TextButton.styleFrom(foregroundColor: Colors.white60),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Depth tier: ${_depthTierLabel()}  |  Max depth: $_maxDepthAllowed',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storeSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeVaultCard(Function setL) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theme Vault',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Board: ${_boardThemeLabel(_boardThemeMode)} · Pieces: ${_pieceThemeLabel(_pieceThemeMode)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text(
            'Board Themes',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableBoardThemes
                .map(
                  (mode) => _themeVaultChip(
                    label: _boardThemeLabel(mode),
                    selected: _boardThemeMode == mode,
                    leading: _boardThemeSwatch(mode),
                    onTap: () {
                      setState(() => _boardThemeMode = mode);
                      setL(() {});
                      _persistCurrentSettings();
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Piece Themes',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availablePieceThemes
                .map(
                  (mode) => _themeVaultChip(
                    label: _pieceThemeLabel(mode),
                    selected: _pieceThemeMode == mode,
                    leading: _pieceThemePreview(mode),
                    onTap: () {
                      setState(() => _pieceThemeMode = mode);
                      setL(() {});
                      _persistCurrentSettings();
                    },
                  ),
                )
                .toList(),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2A6CF0).withValues(alpha: 0.22)
              : Colors.white10,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF2A6CF0) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [leading, const SizedBox(width: 7), Text(label)],
        ),
      ),
    );
  }

  Widget _storeItemCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String priceLabel,
    required bool enabled,
    required String actionLabel,
    Widget? preview,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white70),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                style: const TextStyle(
                  color: Color(0xFFFFD166),
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
                        ? const Color(0xFF2A6CF0)
                        : Colors.white24,
                    disabledBackgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontSize: 12),
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
    bool sel = _perspective == p;
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
          const Icon(Icons.sync, size: 11, color: Colors.white70),
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
          color: sel ? Colors.blue : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [kingWidget, const SizedBox(width: 5), Text(label)],
        ),
      ),
    );
  }

  Widget _boardThemeOption(String label, BoardThemeMode mode, Function setL) {
    final selected = _boardThemeMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _boardThemeMode = mode);
        setL(() {});
        _persistCurrentSettings();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _boardThemeSwatch(mode),
            const SizedBox(width: 7),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _pieceThemeOption(String label, PieceThemeMode mode, Function setL) {
    final selected = _pieceThemeMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _pieceThemeMode = mode);
        setL(() {});
        _persistCurrentSettings();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pieceThemePreview(mode),
            const SizedBox(width: 7),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _boardThemeSwatch(BoardThemeMode mode) {
    final Color dark, light;
    switch (mode) {
      case BoardThemeMode.dark:
        dark = const Color(0xFF2C3E50);
        light = const Color(0xFF95A5A6);
      case BoardThemeMode.light:
        dark = const Color(0xFFB58863);
        light = const Color(0xFFF0D9B5);
      case BoardThemeMode.monochrome:
        dark = const Color(0xFF1A1A1A);
        light = const Color(0xFFF0F0F0);
      case BoardThemeMode.ember:
        dark = const Color(0xFF6B2D1A);
        light = const Color(0xFFF2C08D);
      case BoardThemeMode.aurora:
        dark = const Color(0xFF1E5F74);
        light = const Color(0xFFBFE6D8);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 18,
        height: 18,
        child: Column(
          children: [
            Row(
              children: [
                Container(width: 9, height: 9, color: dark),
                Container(width: 9, height: 9, color: light),
              ],
            ),
            Row(
              children: [
                Container(width: 9, height: 9, color: light),
                Container(width: 9, height: 9, color: dark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pieceThemePreview(PieceThemeMode mode) {
    return SizedBox(
      width: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _pieceImage('k_w', width: 12, height: 12, theme: mode),
          const SizedBox(width: 2),
          _pieceImage('k_b', width: 12, height: 12, theme: mode),
        ],
      ),
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
          label: 'Aurora',
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
  }) {
    final activeTheme = theme ?? _pieceThemeMode;
    final baseImage = Image.asset(
      'pieces/$piece.png',
      width: width,
      height: height,
    );
    if (activeTheme == PieceThemeMode.classic) {
      return baseImage;
    }

    final tinted = ColorFiltered(
      colorFilter: ColorFilter.mode(
        _pieceTintColor(piece, activeTheme),
        BlendMode.modulate,
      ),
      child: baseImage,
    );

    final isBlackPiece = piece.endsWith('_b');
    if (!isBlackPiece) {
      return tinted;
    }

    return Stack(
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
                'pieces/$piece.png',
                width: width,
                height: height,
                color: const Color(0xFFF7FBFF),
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
        tinted,
      ],
    );
  }

  Color _pieceTintColor(String piece, PieceThemeMode theme) {
    final isWhitePiece = piece.endsWith('_w');
    switch (theme) {
      case PieceThemeMode.classic:
        return Colors.white;
      case PieceThemeMode.ember:
        return isWhitePiece ? const Color(0xFFFFD38A) : const Color(0xFF8B3A1B);
      case PieceThemeMode.frost:
        return isWhitePiece ? const Color(0xFFDDF7FF) : const Color(0xFF4D6F94);
    }
  }

  String _boardThemeLabel(BoardThemeMode mode) {
    switch (mode) {
      case BoardThemeMode.dark:
        return 'Dark';
      case BoardThemeMode.light:
        return 'Light';
      case BoardThemeMode.monochrome:
        return 'B&W';
      case BoardThemeMode.ember:
        return 'Ember';
      case BoardThemeMode.aurora:
        return 'Aurora';
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
    }
  }

  Color _darkSquareColorForTheme() {
    switch (_boardThemeMode) {
      case BoardThemeMode.light:
        return const Color(0xFFB58863);
      case BoardThemeMode.monochrome:
        // High-contrast black square, roughly +80% contrast feel.
        return Colors.black.withValues(alpha: 0.9);
      case BoardThemeMode.dark:
        return const Color(0xFF2C3E50);
      case BoardThemeMode.ember:
        return const Color(0xFF6B2D1A);
      case BoardThemeMode.aurora:
        return const Color(0xFF1E5F74);
    }
  }

  Color _lightSquareColorForTheme() {
    switch (_boardThemeMode) {
      case BoardThemeMode.light:
        return const Color(0xFFF0D9B5);
      case BoardThemeMode.monochrome:
        return Colors.white.withValues(alpha: 0.9);
      case BoardThemeMode.dark:
        return const Color(0xFF95A5A6).withValues(alpha: 0.2);
      case BoardThemeMode.ember:
        return const Color(0xFFF2C08D);
      case BoardThemeMode.aurora:
        return const Color(0xFFBFE6D8);
    }
  }

  @override
  void dispose() {
    _engine?.stop();
    _pulseController.dispose();
    _introController.dispose();
    _menuRevealController.dispose();
    _launchController.dispose();
    _buttonRippleController.dispose();
    _menuMusicFadeController.dispose();
    _sectionTransitionController.dispose();
    _menuExitAnimationController.dispose();
    _introAudioPlayer.dispose();
    _menuAudioPlayer.dispose();
    super.dispose();
  }
}

// --- Custom Energy Painter ---
class EnergyArrowPainter extends CustomPainter {
  final List<EngineLine> lines;
  final int bestEval;
  final double progress;
  final bool reverse;
  final bool showSequenceNumbers;
  final Color? overrideColor;
  final bool staticArrowStyle;
  EnergyArrowPainter({
    required this.lines,
    required this.bestEval,
    required this.progress,
    required this.reverse,
    this.showSequenceNumbers = false,
    this.overrideColor,
    this.staticArrowStyle = false,
  });

  // Engine mode: color based on eval quality
  Color _getRelativeColor(int currentEval, int multiPv) {
    if (multiPv == 1) return const Color(0xFF00FF88);
    int loss = (bestEval - currentEval).abs();
    if (loss < 30) return const Color(0xFF00FF88).withValues(alpha: 0.7);
    if (loss < 100) return Colors.yellowAccent;
    if (loss < 250) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double boardInset = 2.0;
    double sq = (size.width - (boardInset * 2)) / 8;
    for (var l in lines.reversed) {
      final start = _getOffset(l.move.substring(0, 2), sq, size, boardInset);
      final end = _getOffset(l.move.substring(2, 4), sq, size, boardInset);

      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < 0.001) continue;
      final unitX = dx / distance;
      final unitY = dy / distance;
      final lineEnd = Offset(end.dx - unitX * 8, end.dy - unitY * 8);

        final bool isGambitMode = showSequenceNumbers;
        final bool isFirstArrow = l.multiPv == 1;
        final bool useStaticStyle = staticArrowStyle && isGambitMode;
        final Color baseColor =
          overrideColor ?? _getRelativeColor(l.eval, l.multiPv);

      // Opacity fades with sequence depth in gambit mode
        final double alphaScale = useStaticStyle
          ? 0.92
          : (isGambitMode
            ? (isFirstArrow
                ? 1.0
                : max(0.45, 1.0 - (l.multiPv - 1) * 0.10))
            : 1.0);

        final double strokeWidth = useStaticStyle
          ? 4.8
          : (isGambitMode
            ? (isFirstArrow ? 9.0 : (l.multiPv == 2 ? 5.5 : 4.5))
            : (l.multiPv == 1 ? 6.0 : 4.0));

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(lineEnd.dx, lineEnd.dy);

      // Base line (solid-ish, always readable)
      final basePaint = Paint()
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..color = baseColor.withValues(
          alpha: useStaticStyle ? 0.58 : 0.30 * alphaScale,
        );
      canvas.drawPath(path, basePaint);

      if (!useStaticStyle) {
        final pulseHalfLen = max(18.0, distance * 0.14);
        final travel = distance + (pulseHalfLen * 2);
        final pulseCenter = (-pulseHalfLen) + (travel * (progress % 1.0));
        final pulseStart = Offset(
          start.dx + unitX * (pulseCenter - pulseHalfLen),
          start.dy + unitY * (pulseCenter - pulseHalfLen),
        );
        final pulseEnd = Offset(
          start.dx + unitX * (pulseCenter + pulseHalfLen),
          start.dy + unitY * (pulseCenter + pulseHalfLen),
        );

        final pulsePaint = Paint()
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..shader = ui.Gradient.linear(
            pulseStart,
            pulseEnd,
            [
              baseColor.withValues(alpha: 0.0),
              baseColor.withValues(alpha: alphaScale),
              baseColor.withValues(alpha: 0.0),
            ],
            const [0.0, 0.5, 1.0],
            TileMode.clamp,
          );
        canvas.drawPath(path, pulsePaint);
      }

      // Arrowhead
      final angle = atan2(end.dy - start.dy, end.dx - start.dx);
        final double headLen = useStaticStyle
          ? 18.0
          : (isGambitMode && isFirstArrow ? 22.0 : 18.0);
      final double headWaist = headLen * (2.0 / 3.0);
      final headPath = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - headLen * cos(angle - 0.40),
          end.dy - headLen * sin(angle - 0.40),
        )
        ..lineTo(
          end.dx - headWaist * cos(angle),
          end.dy - headWaist * sin(angle),
        )
        ..lineTo(
          end.dx - headLen * cos(angle + 0.40),
          end.dy - headLen * sin(angle + 0.40),
        )
        ..close();

      final solidHeadColor = baseColor.withValues(alpha: alphaScale);
      canvas.drawPath(
        headPath,
        Paint()
          ..color = solidHeadColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        headPath,
        Paint()
          ..color = solidHeadColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round,
      );

      // Sequence number badge
      if (isGambitMode) {
        final double badgeRadius = isFirstArrow ? 14.0 : 10.5;
        final markerCenter = Offset(
          start.dx + (end.dx - start.dx) * 0.68,
          start.dy + (end.dy - start.dy) * 0.68,
        );

        if (useStaticStyle) {
          canvas.drawCircle(
            markerCenter,
            badgeRadius,
            Paint()..color = const Color(0xFF1D222A).withValues(alpha: 0.96),
          );
        } else if (isFirstArrow) {
          // Glowing halo behind badge 1
          canvas.drawCircle(
            markerCenter,
            badgeRadius + 5,
            Paint()
              ..color = const Color(0xFFFFD700).withValues(alpha: 0.28)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
          // Dark badge background with yellow glow outline only for #1.
          canvas.drawCircle(
            markerCenter,
            badgeRadius,
            Paint()
              ..shader = ui.Gradient.radial(
                markerCenter,
                badgeRadius,
                [const Color(0xFF1D222A), const Color(0xFF0C1016)],
                [0.0, 1.0],
              ),
          );
        } else {
          canvas.drawCircle(
            markerCenter,
            badgeRadius,
            Paint()..color = baseColor.withValues(alpha: 0.92 * alphaScale),
          );
        }

        // Badge border
        canvas.drawCircle(
          markerCenter,
          badgeRadius,
          Paint()
          ..color = useStaticStyle
            ? baseColor
            : (isFirstArrow
                ? const Color(0xFFFFD700)
                : baseColor.withValues(alpha: alphaScale))
            ..style = PaintingStyle.stroke
          ..strokeWidth = useStaticStyle ? 1.8 : (isFirstArrow ? 2.5 : 1.5),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: l.multiPv.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isFirstArrow ? 13.5 : 11.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            markerCenter.dx - textPainter.width / 2,
            markerCenter.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }

  Offset _getOffset(String s, double sq, Size size, double inset) {
    int col = s.codeUnitAt(0) - 97;
    int row = int.parse(s[1]) - 1;
    if (reverse) {
      col = 7 - col;
    } else {
      row = 7 - row;
    }
    return Offset(inset + col * sq + sq / 2, inset + row * sq + sq / 2);
  }

  @override
  bool shouldRepaint(EnergyArrowPainter old) => true;
}

class QuizAccuracyTrendPainter extends CustomPainter {
  final List<QuizAccuracyPoint> series;

  QuizAccuracyTrendPainter({required this.series});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    for (final y in [0.25, 0.5, 0.75]) {
      final dy = size.height * y;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    if (series.isEmpty) return;

    final points = <Offset>[];
    for (int i = 0; i < series.length; i++) {
      final x = series.length == 1
          ? size.width / 2
          : (size.width * i) / (series.length - 1);
      final y = size.height * (1 - (series[i].value / 100.0));
      points.add(Offset(x, y.clamp(0, size.height)));
    }

    if (points.length >= 2) {
      final fillPath = Path()
        ..moveTo(points.first.dx, size.height)
        ..lineTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath
        ..lineTo(points.last.dx, size.height)
        ..close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [
            const Color(0xFF5AAEE8).withValues(alpha: 0.32),
            const Color(0xFF2A6CF0).withValues(alpha: 0.06),
          ])
          ..style = PaintingStyle.fill,
      );
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, 0), Offset(size.width, 0), [
          const Color(0xFF5AAEE8),
          const Color(0xFF7EDC8A),
        ])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final point in points) {
      canvas.drawCircle(point, 3.3, Paint()..color = const Color(0xFF8FD0FF));
      canvas.drawCircle(
        point,
        6.5,
        Paint()
          ..color = const Color(0xFF5AAEE8).withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant QuizAccuracyTrendPainter oldDelegate) {
    if (oldDelegate.series.length != series.length) return true;
    for (int i = 0; i < series.length; i++) {
      if (oldDelegate.series[i].value != series[i].value ||
          oldDelegate.series[i].dayLabel != series[i].dayLabel) {
        return true;
      }
    }
    return false;
  }
}
