import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/services/firebase_auth_service.dart';
import 'package:chessiq/core/services/local_integrity_service.dart';
import 'package:chessiq/core/services/scoreboard_service.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _basePuzzleAssetPath = 'assets/puzzles/base_puzzles.json';
final RegExp _ratingPattern = RegExp(r'"Rating"\s*:\s*(\d+)');

String _nodeKeyForRating(int rating) {
  final start = (rating ~/ 50) * 50;
  final end = start + 50;
  return '${start}_$end';
}

Iterable<String> _iterateJsonObjects(String rawJson) sync* {
  var depth = 0;
  var inString = false;
  var escaped = false;
  int? objectStart;

  for (var index = 0; index < rawJson.length; index++) {
    final char = rawJson[index];

    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (char == '\\') {
        escaped = true;
      } else if (char == '"') {
        inString = false;
      }
      continue;
    }

    if (char == '"') {
      inString = true;
      continue;
    }

    if (char == '{') {
      if (depth == 0) {
        objectStart = index;
      }
      depth += 1;
      continue;
    }

    if (char == '}') {
      if (depth == 0) {
        continue;
      }
      depth -= 1;
      if (depth == 0 && objectStart != null) {
        yield rawJson.substring(objectStart, index + 1);
        objectStart = null;
      }
    }
  }
}

List<Map<String, dynamic>> _decodePuzzleMaps(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! List) return const <Map<String, dynamic>>[];

  final items = <Map<String, dynamic>>[];
  for (final raw in decoded) {
    if (raw is! Map) continue;
    final map = raw.cast<String, dynamic>();
    final item = PuzzleItem.fromMap(map);
    if (_validatePuzzle(item)) {
      items.add(map);
    }
  }
  return items;
}

bool _validatePuzzle(PuzzleItem item) {
  if (item.puzzleId.isEmpty || item.fen.isEmpty || item.moves.isEmpty) {
    return false;
  }

  if (!chess.Chess.validate_fen(item.fen)['valid']) {
    return false;
  }

  final game = chess.Chess.fromFEN(item.fen);
  for (final move in item.moves) {
    if (move.length < 4) return false;
    final from = move.substring(0, 2);
    final to = move.substring(2, 4);
    final payload = <String, String>{'from': from, 'to': to};
    if (move.length == 5) {
      payload['promotion'] = move[4];
    }
    final ok = game.move(payload);
    if (ok == false) return false;
  }

  return true;
}

enum PuzzleGridTileState { solved, skipped, nextAvailable, replayable, locked }

class PuzzleSolveResult {
  final bool countedAsNewSolve;
  final bool beatGhostTime;
  final bool earnedGoldCrown;
  final bool brilliant;
  final int? previousBestMs;

  const PuzzleSolveResult({
    required this.countedAsNewSolve,
    required this.beatGhostTime,
    required this.earnedGoldCrown,
    required this.brilliant,
    required this.previousBestMs,
  });
}

class PuzzleAcademyProvider extends ChangeNotifier {
  static const String _progressKey = 'puzzle_academy_progress_v2';
  static const String _sharedStoreStateKey = 'store_state_v1';
  static const String _progressIntegrityScope = 'academy_progress';
  static const String _storeIntegrityScope = 'economy_store';
  static const int _coinsPerAdWatch = 10;
  static const int _brainBreakSolveInterval = 15;
  static const int _dailyPuzzleReward = 40;
  static const int _gridPuzzleCount = 500;
  static const int _examUnlockSolveCount = 150;
  static const int _examPuzzleCount = 50;
  static const Duration _examDuration = Duration(hours: 1);
  static const Map<String, int> _examUnlockRequirementsByNodeKey =
      <String, int>{
        '1000_1050': 2,
        '1500_1550': 6,
        '2100_2150': 6,
        '2500_2550': 3,
        '3000_3050': 2,
      };

  final List<SemesterRange> semesters = const <SemesterRange>[
    SemesterRange(
      id: 'novice',
      title: 'Novice Semester',
      minElo: 450,
      maxElo: 950,
      intro:
          'Checks, captures, and forcing lines. Master the basics and find the best moves to build your chess foundation. You can take exams once you have solved 150 puzzles at your current level.',
    ),
    SemesterRange(
      id: 'tactician',
      title: 'Tactician Semester',
      minElo: 1000,
      maxElo: 1450,
      intro:
          'Now the combinations deepen. You are expected to calculate cleanly through distractions and tactical noise.',
    ),
    SemesterRange(
      id: 'strategist',
      title: 'Strategist Semester',
      minElo: 1500,
      maxElo: 2050,
      intro:
          'Winning ideas are quieter now. Improve your pattern memory, piece coordination, and patience under tension.',
    ),
    SemesterRange(
      id: 'master',
      title: 'Master Semester',
      minElo: 2100,
      maxElo: 2450,
      intro:
          'Elite tactical positions demand restraint. Precision matters more than speed, until speed matters more than everything.',
    ),
    SemesterRange(
      id: 'grandmaster',
      title: 'Grandmaster Semester',
      minElo: 2500,
      maxElo: 2950,
      intro:
          'This tier opens only after proven exam consistency. Calculate with control and finish with force.',
    ),
    SemesterRange(
      id: 'oracle',
      title: 'Oracle Semester',
      minElo: 3000,
      maxElo: 3999,
      intro:
          'The final ascent. Neural constraints begin to dissolve here. Complete this tier and Analysis Mode changes permanently.',
    ),
  ];

  final List<LeaderboardEntry> dailyLeaderboard = const <LeaderboardEntry>[
    LeaderboardEntry(rank: 1, handle: 'Qh8+', score: 14820, title: 'Oracle'),
    LeaderboardEntry(
      rank: 2,
      handle: 'FianchettoFox',
      score: 14110,
      title: 'Master',
    ),
    LeaderboardEntry(
      rank: 3,
      handle: 'KnightVision',
      score: 13870,
      title: 'Strategist',
    ),
    LeaderboardEntry(
      rank: 4,
      handle: 'TempoDrip',
      score: 13480,
      title: 'Master',
    ),
    LeaderboardEntry(
      rank: 5,
      handle: 'Zwischenzug',
      score: 13120,
      title: 'Oracle',
    ),
    LeaderboardEntry(
      rank: 6,
      handle: 'RookLift',
      score: 12730,
      title: 'Tactician',
    ),
    LeaderboardEntry(
      rank: 7,
      handle: 'IceVariation',
      score: 12560,
      title: 'Strategist',
    ),
    LeaderboardEntry(
      rank: 8,
      handle: 'BlueBishop',
      score: 12105,
      title: 'Tactician',
    ),
    LeaderboardEntry(
      rank: 9,
      handle: 'EndgameFiend',
      score: 11890,
      title: 'Master',
    ),
    LeaderboardEntry(
      rank: 10,
      handle: 'PawnScout',
      score: 11640,
      title: 'Novice',
    ),
  ];

  PuzzleProgressModel? _progress;
  String? _lastRegistrationError;
  Map<String, int> _basePuzzleCountsByNode = const <String, int>{};
  final Map<String, List<PuzzleItem>> _basePuzzleCacheByNode =
      <String, List<PuzzleItem>>{};
  final Map<String, Future<void>> _nodePuzzleLoadFutures =
      <String, Future<void>>{};
  List<PuzzleItem> _dailyPuzzles = const <PuzzleItem>[];
  List<String> _dailyPuzzleAssetPaths = const <String>[];
  PuzzleItem? _todayDailyPuzzle;
  String? _todayDailyPuzzleAssetPath;
  EconomyProvider? _economyProvider;

  bool _initialized = false;
  bool _isLoading = false;
  String? _serverDateStamp;
  DateTime? _serverDateFetchedAt;
  bool _shouldShowBrainBreak = false;
  bool _shouldShowGrandmasterOracle = false;
  String? _celebrationNodeKey;
  bool _remoteScoreboardLoaded = false;
  List<LeaderboardEntry> _remoteScoreboardEntries = const <LeaderboardEntry>[];
  bool _scoreboardSyncing = false;

  bool get initialized => _initialized;
  bool get isLoading => _isLoading;
  bool get scoreboardLoaded => _remoteScoreboardLoaded;
  bool get scoreboardSyncing => _scoreboardSyncing;
  bool get shouldShowBrainBreak => _shouldShowBrainBreak;
  bool get shouldShowGrandmasterOracle => _shouldShowGrandmasterOracle;
  String? get celebrationNodeKey => _celebrationNodeKey;
  String? get lastRegistrationError => _lastRegistrationError;
  List<PuzzleItem> get dailyPuzzles => _dailyPuzzles;
  Duration get examDuration => _examDuration;
  int get examPuzzleCount => _examPuzzleCount;
  List<PuzzleItem> get basePuzzles => _basePuzzleCacheByNode.values
      .expand((items) => items)
      .toList(growable: false);
  PuzzleItem? get todayDailyPuzzle {
    final snapshot = _progress;
    if (snapshot == null || _dailyPuzzles.isEmpty) {
      return _todayDailyPuzzle;
    }

    for (final puzzle in _dailyPuzzles) {
      if (!snapshot.completedDailyPuzzleIds.contains(puzzle.puzzleId)) {
        return puzzle;
      }
    }

    return _todayDailyPuzzle ?? _dailyPuzzles.first;
  }

  int get todayDailyPuzzleIndex {
    final activePuzzle = todayDailyPuzzle;
    if (activePuzzle == null) return -1;
    return _dailyPuzzles.indexWhere(
      (puzzle) => puzzle.puzzleId == activePuzzle.puzzleId,
    );
  }

  bool get hasTodayDailyPuzzle => todayDailyPuzzle != null;
  int get unresolvedSkippedPuzzleCount => progress.skippedPuzzleIds
      .where((puzzleId) => !progress.solvedPuzzleIds.contains(puzzleId))
      .length;
  int get completedTodayDailyCount => _dailyPuzzles
      .where(
        (puzzle) => progress.completedDailyPuzzleIds.contains(puzzle.puzzleId),
      )
      .length;
  List<AcademyExamResult> get academyExamResults {
    final results = List<AcademyExamResult>.from(progress.examResults);
    results.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.completedAtMs.compareTo(a.completedAtMs);
    });
    return results;
  }

  List<LeaderboardEntry> get academyScoreboardEntries {
    if (_remoteScoreboardLoaded) {
      return _remoteScoreboardEntries;
    }
    final results = List<AcademyExamResult>.from(progress.examResults);
    final bestResultsByNode = <String, AcademyExamResult>{};
    for (final result in results) {
      final existing = bestResultsByNode[result.nodeKey];
      if (existing == null ||
          _effectiveLeaderboardScore(result) >
              _effectiveLeaderboardScore(existing)) {
        bestResultsByNode[result.nodeKey] = result;
      }
    }

    if (bestResultsByNode.isEmpty) {
      return const <LeaderboardEntry>[];
    }

    final totalScore = bestResultsByNode.values.fold<int>(
      0,
      (sum, result) => sum + _effectiveLeaderboardScore(result),
    );
    final handle = progress.handle.trim().isEmpty
        ? 'Unknown Player'
        : progress.handle.trim();
    return <LeaderboardEntry>[
      LeaderboardEntry(
        rank: 1,
        handle: handle,
        score: totalScore,
        title: '${bestResultsByNode.length} exams counted',
      ),
    ];
  }

  PuzzleProgressModel get progress {
    final value = _progress;
    if (value == null) {
      throw StateError('PuzzleAcademyProvider used before initialization');
    }
    return value;
  }

  bool get todayDailyChallengeRewardClaimed {
    return progress.claimedDailyChallengeRewardDates.contains(_todayStamp());
  }

  Future<void> markTodayDailyChallengeRewardClaimed() async {
    final stamp = _todayStamp();
    if (progress.claimedDailyChallengeRewardDates.contains(stamp)) {
      return;
    }
    final updated = progress.copyWith(
      claimedDailyChallengeRewardDates: {
        ...progress.claimedDailyChallengeRewardDates,
        stamp,
      },
    );
    _progress = updated;
    notifyListeners();
    await _saveProgress(mirrorStoreCoins: false);
  }

  void attachEconomyProvider(EconomyProvider economyProvider) {
    _economyProvider = economyProvider;
    if (!_initialized || _progress == null || !economyProvider.loaded) {
      return;
    }
    if (progress.coins == economyProvider.coins) {
      return;
    }

    _progress = progress.copyWith(coins: economyProvider.coins);
    unawaited(_saveProgress(mirrorStoreCoins: false));
    notifyListeners();
  }

  List<EloNodeProgress> get orderedNodes {
    final value = progress.nodes.values.toList(growable: false)
      ..sort((a, b) => a.startElo.compareTo(b.startElo));
    return value;
  }

  int get highestUnlockedElo {
    var highest = 450;
    for (final node in orderedNodes.where((n) => n.unlocked)) {
      highest = max(highest, node.endElo);
    }
    return highest;
  }

  bool get shouldAskForProfile =>
      progress.handle.trim().isEmpty || progress.country.trim().isEmpty;

  Future<void> updateAcademyProfile({
    required String handle,
    required String country,
  }) async {
    _progress = progress.copyWith(
      handle: handle.trim(),
      country: country.trim(),
    );
    await _saveProgress();
    notifyListeners();
  }

  Future<HandleAvailabilityStatus> registerAcademyProfile({
    required String handle,
    required String country,
  }) async {
    _lastRegistrationError = null;
    final bestResultsByNode = <String, AcademyExamResult>{};
    for (final result in progress.examResults) {
      final existing = bestResultsByNode[result.nodeKey];
      if (existing == null ||
          _effectiveLeaderboardScore(result) >
              _effectiveLeaderboardScore(existing)) {
        bestResultsByNode[result.nodeKey] = result;
      }
    }

    final totalScore = bestResultsByNode.values.fold<int>(
      0,
      (sum, result) => sum + _effectiveLeaderboardScore(result),
    );

    final status = await ScoreboardService.instance.registerProfile(
      handle: handle,
      country: country,
      score: totalScore,
      title: '${bestResultsByNode.length} exams counted',
    );
    if (status == HandleAvailabilityStatus.verificationUnavailable) {
      _lastRegistrationError = ScoreboardService.instance.lastFunctionError;
    }
    return status;
  }

  Future<HandleAvailabilityStatus> checkHandleAvailability({
    required String handle,
    String? currentHandle,
  }) async {
    return ScoreboardService.instance.checkHandleAvailability(
      handle: handle,
      currentHandle: currentHandle,
    );
  }

  Future<void> resetAcademyScoreboard() async {
    _progress = progress.copyWith(examResults: const <AcademyExamResult>[]);
    await _saveProgress();
    notifyListeners();
  }

  Future<void> resetAcademyProfile() async {
    _progress = progress.copyWith(handle: '', country: '');
    await _saveProgress();
    notifyListeners();
  }

  String get currentTitle {
    final elo = highestUnlockedElo;
    if (elo >= 3000) return 'Grandmaster Oracle';
    if (elo >= 2500) return 'Grandmaster Candidate';
    if (elo >= 2200) return 'Master of Tactics';
    if (elo >= 1500) return 'Tactical Sergeant';
    if (elo >= 1000) return 'Knight Captain';
    if (elo >= 700) return 'Pawn Scout';
    return 'Board Initiate';
  }

  int get totalSolved => progress.solvedPuzzleIds.length;
  int get masteredNodeCount => orderedNodes.where((n) => n.goldCrown).length;

  double get overallMasteryProgress {
    final nodes = orderedNodes;
    if (nodes.isEmpty) return 0.0;
    final sum = nodes.fold<double>(
      0.0,
      (acc, node) => acc + node.masteryProgress,
    );
    return (sum / nodes.length).clamp(0.0, 1.0);
  }

  Future<void> initialize() async {
    if (_initialized || _isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      _basePuzzleCountsByNode = await _loadBasePuzzleCounts();
      _dailyPuzzleAssetPaths = await _loadDailyAssetPaths();
      await _initServerDate();
      await _refreshTodayDailyPuzzle(notify: false);

      final fallbackNodes = _buildInitialNodes(_basePuzzleCountsByNode);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey);

      if (raw == null || raw.trim().isEmpty) {
        _progress = PuzzleProgressModel.initial(nodes: fallbackNodes);
      } else {
        final signed = LocalIntegrityService.decodeJson(
          raw,
          scope: _progressIntegrityScope,
        );
        if (signed.data == null) {
          _progress = PuzzleProgressModel.initial(nodes: fallbackNodes);
        } else if (signed.isSigned && !signed.isValid) {
          _progress = PuzzleProgressModel.initial(nodes: fallbackNodes)
              .copyWith(
                handle: signed.data!['handle']?.toString().trim() ?? '',
                country: signed.data!['country']?.toString().trim() ?? '',
              );
        } else {
          _progress = PuzzleProgressModel.fromMap(
            signed.data!,
            fallbackNodes: fallbackNodes,
          );
        }
      }

      _normalizeUnlockState();
      await _ensureNodePuzzlesLoaded(
        orderedNodes
            .where((node) => node.unlocked)
            .map((node) => node.key)
            .toSet(),
      );
      if (_economyProvider?.loaded == true) {
        _progress = progress.copyWith(coins: _economyProvider!.coins);
      } else {
        await syncCoinsFromStoreState(notify: false);
      }
      await _saveProgress();
      _initialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDailyPuzzle() async {
    await _refreshTodayDailyPuzzle(notify: true);
  }

  Future<PuzzleSolveResult> recordPuzzleSolve({
    required PuzzleItem puzzle,
    required Duration solveTime,
    bool daily = false,
    bool brilliant = false,
  }) async {
    final previouslyUnlocked = progress.nodes.values
        .where((node) => node.unlocked)
        .map((node) => node.key)
        .toSet();
    final nodeKey = keyForRating(puzzle.rating);
    final node = progress.nodes[nodeKey];
    if (node == null) {
      return const PuzzleSolveResult(
        countedAsNewSolve: false,
        beatGhostTime: false,
        earnedGoldCrown: false,
        brilliant: false,
        previousBestMs: null,
      );
    }

    final wasSolved = isPuzzleSolved(puzzle.puzzleId);
    final previousBestMs = progress.bestSolveTimeMsByPuzzleId[puzzle.puzzleId];
    final solveMs = max(1, solveTime.inMilliseconds);
    final beatGhostTime = previousBestMs != null && solveMs < previousBestMs;

    final solvedPuzzleIds = Set<String>.from(progress.solvedPuzzleIds)
      ..add(puzzle.puzzleId);
    final skippedPuzzleIds = Set<String>.from(progress.skippedPuzzleIds)
      ..remove(puzzle.puzzleId);

    final bestTimes = Map<String, int>.from(progress.bestSolveTimeMsByPuzzleId)
      ..update(
        puzzle.puzzleId,
        (value) => min(value, solveMs),
        ifAbsent: () => solveMs,
      );

    final completedDaily = Set<String>.from(progress.completedDailyPuzzleIds);
    var coins = _economyProvider?.coins ?? progress.coins;
    if (daily && completedDaily.add(puzzle.puzzleId)) {
      coins += _dailyPuzzleReward;
    }

    var streak = progress.streak + 1;
    var freeHints = progress.freeHints;
    var freeSkips = progress.freeSkips;
    if (streak % 3 == 0) {
      freeHints += 1;
    }
    if (streak % 7 == 0) {
      freeSkips += 1;
    }

    var adCounter = progress.adCounter;
    if (!wasSolved) {
      adCounter += 1;
      if (adCounter >= _brainBreakSolveInterval) {
        _shouldShowBrainBreak = true;
        adCounter = 0;
      }
    }

    final solvedCount = wasSolved ? node.solvedCount : node.solvedCount + 1;
    final updatedNodes = Map<String, EloNodeProgress>.from(progress.nodes)
      ..[nodeKey] = node.copyWith(
        attempts: node.attempts + 1,
        solvedCount: solvedCount,
      );

    final earnedGoldCrown =
        !node.goldCrown && solvedCount >= updatedNodes[nodeKey]!.masteryTarget;

    var updated = progress.copyWith(
      coins: coins,
      nodes: updatedNodes,
      streak: streak,
      freeHints: freeHints,
      freeSkips: freeSkips,
      adCounter: adCounter,
      completedDailyPuzzleIds: completedDaily,
      solvedPuzzleIds: solvedPuzzleIds,
      skippedPuzzleIds: skippedPuzzleIds,
      bestSolveTimeMsByPuzzleId: bestTimes,
    );

    updated = _applyUnlockingAndRewards(updated);
    await _saveUpdatedProgress(updated, syncCoins: true);
    final unlockedNow = updated.nodes.values
        .where((candidate) => candidate.unlocked)
        .map((candidate) => candidate.key)
        .toSet();
    final newlyUnlocked = unlockedNow.difference(previouslyUnlocked);
    if (newlyUnlocked.isNotEmpty) {
      await _ensureNodePuzzlesLoaded(newlyUnlocked);
    }
    notifyListeners();

    return PuzzleSolveResult(
      countedAsNewSolve: !wasSolved,
      beatGhostTime: beatGhostTime,
      earnedGoldCrown: earnedGoldCrown,
      brilliant: brilliant,
      previousBestMs: previousBestMs,
    );
  }

  Future<void> recordPuzzleMiss({required int rating}) async {
    final nodeKey = keyForRating(rating);
    final node = progress.nodes[nodeKey];
    if (node == null) return;

    _progress = progress.copyWith(
      streak: 0,
      nodes: Map<String, EloNodeProgress>.from(progress.nodes)
        ..[nodeKey] = node.copyWith(attempts: node.attempts + 1),
    );

    await _saveProgress();
    notifyListeners();
  }

  Future<bool> skipPuzzle(PuzzleItem puzzle) async {
    if (isPuzzleSolved(puzzle.puzzleId) || isPuzzleSkipped(puzzle.puzzleId)) {
      return false;
    }
    if (progress.freeSkips <= 0) return false;

    final skipped = Set<String>.from(progress.skippedPuzzleIds)
      ..add(puzzle.puzzleId);
    _progress = progress.copyWith(
      freeSkips: progress.freeSkips - 1,
      skippedPuzzleIds: skipped,
      streak: 0,
    );
    await _saveProgress();
    notifyListeners();
    return true;
  }

  Future<void> completeDailyPuzzle(String puzzleId) async {
    if (progress.completedDailyPuzzleIds.contains(puzzleId)) return;

    final completed = Set<String>.from(progress.completedDailyPuzzleIds)
      ..add(puzzleId);

    final updated = progress.copyWith(
      completedDailyPuzzleIds: completed,
      coins: (_economyProvider?.coins ?? progress.coins) + _dailyPuzzleReward,
    );

    await _saveUpdatedProgress(updated, syncCoins: true);
    notifyListeners();
  }

  Future<void> watchRewardedAd() async {
    final updated = progress.copyWith(
      coins: (_economyProvider?.coins ?? progress.coins) + _coinsPerAdWatch,
    );
    await _saveUpdatedProgress(updated, syncCoins: true);
    notifyListeners();
  }

  Future<bool> buyHintPack({int amount = 3, int cost = 25}) async {
    final currentCoins = _economyProvider?.coins ?? progress.coins;
    if (currentCoins < cost) return false;
    final updated = progress.copyWith(
      coins: currentCoins - cost,
      freeHints: progress.freeHints + amount,
    );
    await _saveUpdatedProgress(updated, syncCoins: true);
    notifyListeners();
    return true;
  }

  Future<bool> buySkipPack({int amount = 2, int cost = 35}) async {
    final currentCoins = _economyProvider?.coins ?? progress.coins;
    if (currentCoins < cost) return false;
    final updated = progress.copyWith(
      coins: currentCoins - cost,
      freeSkips: progress.freeSkips + amount,
    );
    await _saveUpdatedProgress(updated, syncCoins: true);
    notifyListeners();
    return true;
  }

  Future<bool> buyProfileReset({int cost = 500}) async {
    final currentCoins = _economyProvider?.coins ?? progress.coins;
    if (currentCoins < cost) return false;
    final updated = progress.copyWith(coins: currentCoins - cost);
    await _saveUpdatedProgress(updated, syncCoins: true);
    notifyListeners();
    return true;
  }

  Future<bool> buyNicknameReset({int cost = 500}) async {
    final currentCoins = _economyProvider?.coins ?? progress.coins;
    if (currentCoins < cost) return false;
    final updated = progress.copyWith(coins: currentCoins - cost, handle: '');
    await _saveUpdatedProgress(updated, syncCoins: true);
    notifyListeners();
    return true;
  }

  Future<bool> buyCountryReset({int cost = 500}) async {
    final currentCoins = _economyProvider?.coins ?? progress.coins;
    if (currentCoins < cost) return false;
    final updated = progress.copyWith(coins: currentCoins - cost, country: '');
    await _saveUpdatedProgress(updated, syncCoins: true);
    notifyListeners();
    return true;
  }

  Future<bool> consumeHint() async {
    if (progress.freeHints <= 0) return false;
    _progress = progress.copyWith(freeHints: progress.freeHints - 1);
    await _saveProgress();
    notifyListeners();
    return true;
  }

  Future<bool> consumeSkip() async {
    if (progress.freeSkips <= 0) return false;
    _progress = progress.copyWith(freeSkips: progress.freeSkips - 1);
    await _saveProgress();
    notifyListeners();
    return true;
  }

  Future<void> markSemesterSeen(String semesterId) async {
    if (progress.seenSemesters.contains(semesterId)) return;
    final seen = Set<String>.from(progress.seenSemesters)..add(semesterId);
    _progress = progress.copyWith(seenSemesters: seen);
    await _saveProgress();
    notifyListeners();
  }

  bool isNodeUnlocked(String nodeKey) =>
      progress.nodes[nodeKey]?.unlocked == true;
  bool isPuzzleSolved(String puzzleId) =>
      progress.solvedPuzzleIds.contains(puzzleId);
  bool isPuzzleSkipped(String puzzleId) =>
      progress.skippedPuzzleIds.contains(puzzleId);
  int? bestSolveTimeFor(String puzzleId) =>
      progress.bestSolveTimeMsByPuzzleId[puzzleId];
  bool shouldShowSemesterIntro(String semesterId) =>
      !progress.seenSemesters.contains(semesterId);
  bool canTakeExam(EloNodeProgress node) =>
      node.unlocked && node.solvedCount >= _examUnlockSolveCount;
  int examUnlockSolveTarget(EloNodeProgress node) => _examUnlockSolveCount;

  SemesterRange semesterForNode(EloNodeProgress node) {
    return semesters.firstWhere(
      (semester) => semester.includes(node.startElo),
      orElse: () => semesters.last,
    );
  }

  double semesterProgress(SemesterRange semester) {
    final list = orderedNodes
        .where((node) => semester.includes(node.startElo))
        .toList(growable: false);
    if (list.isEmpty) return 0.0;
    final sum = list.fold<double>(
      0.0,
      (acc, node) => acc + node.masteryProgress,
    );
    return (sum / list.length).clamp(0.0, 1.0);
  }

  int _completedExamCountInSemester(
    PuzzleProgressModel snapshot,
    SemesterRange semester,
  ) {
    return snapshot.examResults.where((result) {
      final node = snapshot.nodes[result.nodeKey];
      return node != null && semester.includes(node.startElo);
    }).length;
  }

  int completedExamCountInSemester(SemesterRange semester) {
    return _completedExamCountInSemester(progress, semester);
  }

  int examUnlockRequirementForNode(EloNodeProgress node) {
    return _examUnlockRequirementsByNodeKey[node.key] ?? 0;
  }

  String? unlockRequirementText(EloNodeProgress node) {
    final required = examUnlockRequirementForNode(node);
    if (required <= 0) {
      return null;
    }

    final previousSemester = _previousSemesterFor(node);
    if (previousSemester == null) {
      return null;
    }

    final completed = completedExamCountInSemester(previousSemester);
    return '$completed/$required exams in ${previousSemester.title}';
  }

  String? previousNodeSolveRequirementText(EloNodeProgress node) {
    if (requiresPreviousSemesterExamGate(node)) {
      return null;
    }

    final previous = _previousNodeFor(node);
    if (previous == null) {
      return null;
    }

    return '${previous.solvedCount}/${previous.unlockTarget} puzzles in previous level';
  }

  SemesterRange? _previousSemesterFor(EloNodeProgress node) {
    SemesterRange? previous;
    for (final semester in semesters) {
      if (semester.maxElo < node.startElo) {
        previous = semester;
      }
    }
    return previous;
  }

  bool requiresPreviousSemesterExamGate(EloNodeProgress node) {
    return examUnlockRequirementForNode(node) > 0;
  }

  bool _hasRequiredPreviousSemesterExams(
    PuzzleProgressModel snapshot,
    EloNodeProgress node,
  ) {
    final required = examUnlockRequirementForNode(node);
    if (required <= 0) {
      return true;
    }

    final previousSemester = _previousSemesterFor(node);
    if (previousSemester == null) {
      return false;
    }

    return _completedExamCountInSemester(snapshot, previousSemester) >=
        required;
  }

  bool requiresPreviousNodeSolveTarget(EloNodeProgress node) {
    return node.startElo > 450 && node.startElo <= 800;
  }

  EloNodeProgress? _previousNodeFor(EloNodeProgress node) {
    final ordered = orderedNodes;
    for (var i = 1; i < ordered.length; i++) {
      if (ordered[i].key == node.key) {
        return ordered[i - 1];
      }
    }
    return null;
  }

  Map<String, EloNodeProgress> _normalizedNodesFor(
    PuzzleProgressModel snapshot,
  ) {
    final nodes = snapshot.nodes.values.toList(growable: false)
      ..sort((a, b) => a.startElo.compareTo(b.startElo));

    final updated = <String, EloNodeProgress>{};
    for (var index = 0; index < nodes.length; index++) {
      final node = snapshot.nodes[nodes[index].key] ?? nodes[index];
      final previouslyUnlocked = node.unlocked;
      late final bool unlocked;

      if (index == 0) {
        unlocked = true;
      } else if (requiresPreviousSemesterExamGate(node)) {
        unlocked = _hasRequiredPreviousSemesterExams(snapshot, node);
      } else {
        final previous = updated[nodes[index - 1].key] ?? nodes[index - 1];
        if (requiresPreviousNodeSolveTarget(node)) {
          unlocked = previouslyUnlocked || previous.unlocked;
        } else {
          unlocked =
              previouslyUnlocked ||
              (previous.unlocked &&
                  previous.solvedCount >= previous.unlockTarget);
        }
      }

      updated[node.key] = node.copyWith(unlocked: unlocked);
    }

    return updated;
  }

  String heroTagForNode(EloNodeProgress node) =>
      'puzzle-node-badge-${node.key}';

  String keyForRating(int rating) {
    return _nodeKeyForRating(rating);
  }

  PuzzleItem? featuredPuzzleForNode(EloNodeProgress node) {
    final next = nextAvailablePuzzleForNode(node);
    if (next != null) return next;
    final nodePuzzles = puzzlesForNode(node);
    if (nodePuzzles.isEmpty) return null;
    return nodePuzzles.first;
  }

  List<PuzzleItem> puzzlesForNode(EloNodeProgress node) {
    return _basePuzzleCacheByNode[node.key] ?? const <PuzzleItem>[];
  }

  int gridPuzzleCountForNode(EloNodeProgress node) {
    return min(_gridPuzzleCount, max(node.masteryTarget, node.totalPuzzles));
  }

  PuzzleItem? puzzleForNodeIndex(EloNodeProgress node, int index) {
    final nodePuzzles = puzzlesForNode(node);
    final maxReachableIndex = min(_gridPuzzleCount, node.totalPuzzles);
    if (index < 0 ||
        index >= maxReachableIndex ||
        index >= nodePuzzles.length) {
      return null;
    }
    return nodePuzzles[index];
  }

  int indexOfPuzzleInNode(EloNodeProgress node, String puzzleId) {
    final nodePuzzles = puzzlesForNode(node);
    return nodePuzzles.indexWhere((puzzle) => puzzle.puzzleId == puzzleId);
  }

  int completedPuzzleCountForNode(
    EloNodeProgress node,
    PuzzleProgressModel snapshot,
  ) {
    final nodePuzzles = puzzlesForNode(node);
    if (nodePuzzles.isEmpty) return node.solvedCount;

    final skipped = snapshot.skippedPuzzleIds;
    final skippedCount = nodePuzzles
        .where((puzzle) => skipped.contains(puzzle.puzzleId))
        .length;
    return node.solvedCount + skippedCount;
  }

  double completedProgressForNode(
    EloNodeProgress node,
    PuzzleProgressModel snapshot,
  ) {
    final target = node.masteryTarget <= 0 ? 1 : node.masteryTarget;
    final completedCount = completedPuzzleCountForNode(node, snapshot);
    return (completedCount.clamp(0, target) / target).clamp(0.0, 1.0);
  }

  int frontierPuzzleIndexForNode(EloNodeProgress node) {
    final nodePuzzles = puzzlesForNode(node);
    if (nodePuzzles.isEmpty) return 0;
    for (
      var index = 0;
      index < min(nodePuzzles.length, _gridPuzzleCount);
      index++
    ) {
      final puzzle = nodePuzzles[index];
      if (isPuzzleSolved(puzzle.puzzleId) || isPuzzleSkipped(puzzle.puzzleId)) {
        continue;
      }
      return index;
    }
    return min(nodePuzzles.length, _gridPuzzleCount) - 1;
  }

  PuzzleItem? nextAvailablePuzzleForNode(EloNodeProgress node) {
    final index = frontierPuzzleIndexForNode(node);
    return puzzleForNodeIndex(node, index);
  }

  Future<List<PuzzleItem>> buildExamPuzzleSequence(EloNodeProgress node) async {
    await ensureNodePuzzlesLoadedForNode(node);
    final source = List<PuzzleItem>.from(puzzlesForNode(node));
    if (source.isEmpty) return const <PuzzleItem>[];
    final random = Random(
      DateTime.now().millisecondsSinceEpoch ^ node.startElo ^ node.solvedCount,
    );
    source.shuffle(random);
    return source
        .take(min(_examPuzzleCount, source.length))
        .toList(growable: false);
  }

  List<AcademyExamResult> examResultsForNode(String nodeKey) {
    final results = progress.examResults
        .where((result) => result.nodeKey == nodeKey)
        .toList(growable: false);
    results.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.completedAtMs.compareTo(a.completedAtMs);
    });
    return results;
  }

  AcademyExamResult? bestExamResultForNode(String nodeKey) {
    final results = examResultsForNode(nodeKey);
    return results.isEmpty ? null : results.first;
  }

  int _effectiveLeaderboardScore(AcademyExamResult result) {
    final node = progress.nodes[result.nodeKey];
    if (node == null) {
      return result.leaderboardScore;
    }
    return calculateLeaderboardScore(
      examScore: result.score,
      nodeElo: node.startElo,
    );
  }

  int calculateExamScore({
    required int correctCount,
    required int totalCount,
    required Duration remaining,
    required int nodeElo,
    Duration timeLimit = _examDuration,
  }) {
    if (totalCount <= 0) return 0;
    final boundedRemainingMs = remaining.inMilliseconds.clamp(
      0,
      timeLimit.inMilliseconds,
    );
    final accuracyRatio = (correctCount / totalCount).clamp(0.0, 1.0);
    final speedRatio = timeLimit.inMilliseconds <= 0
        ? 0.0
        : boundedRemainingMs / timeLimit.inMilliseconds;
    final rawScore = (accuracyRatio * 8000) + (speedRatio * 2000);
    return rawScore.round();
  }

  int calculateLeaderboardScore({
    required int examScore,
    required int nodeElo,
  }) {
    final normalizedElo = nodeElo.clamp(450, 3999);
    final weight =
        0.5 + ((normalizedElo - 450) / (3999 - 450)) * 1.0; // range 0.5..1.5
    return (examScore * weight).round();
  }

  Future<void> recordExamResult(AcademyExamResult result) async {
    final updatedResults = List<AcademyExamResult>.from(progress.examResults)
      ..add(result)
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return b.completedAtMs.compareTo(a.completedAtMs);
      });

    _progress = progress.copyWith(
      examResults: updatedResults.take(40).toList(growable: false),
    );
    await _saveProgress();
    notifyListeners();
    unawaited(_submitScoreboardScore());
  }

  Future<void> _submitScoreboardScore() async {
    if (progress.handle.trim().isEmpty || progress.country.trim().isEmpty) {
      return;
    }
    final bestResultsByNode = <String, AcademyExamResult>{};
    for (final result in progress.examResults) {
      final existing = bestResultsByNode[result.nodeKey];
      if (existing == null ||
          _effectiveLeaderboardScore(result) >
              _effectiveLeaderboardScore(existing)) {
        bestResultsByNode[result.nodeKey] = result;
      }
    }
    final totalScore = bestResultsByNode.values.fold<int>(
      0,
      (sum, result) => sum + _effectiveLeaderboardScore(result),
    );
    if (totalScore <= 0) return;

    await ScoreboardService.instance.submitScore(
      handle: progress.handle.trim().isEmpty
          ? 'Unknown Player'
          : progress.handle.trim(),
      country: progress.country.trim(),
      score: totalScore,
      title: '${bestResultsByNode.length} exams counted',
    );
  }

  Future<void> refreshRemoteScoreboard({required bool national}) async {
    if (_scoreboardSyncing) return;
    _scoreboardSyncing = true;
    notifyListeners();

    final country = national ? progress.country.trim() : null;
    final entries = await ScoreboardService.instance.fetchTopScores(
      country: country,
      limit: 10,
    );
    _remoteScoreboardEntries = entries;
    _remoteScoreboardLoaded = true;
    _scoreboardSyncing = false;
    notifyListeners();
  }

  Future<void> ensureNodePuzzlesLoadedForNode(EloNodeProgress node) async {
    await _ensureNodePuzzlesLoaded(<String>{node.key});
  }

  PuzzleGridTileState tileStateForNodeIndex(EloNodeProgress node, int index) {
    final puzzle = puzzleForNodeIndex(node, index);
    if (puzzle == null) return PuzzleGridTileState.locked;
    if (isPuzzleSolved(puzzle.puzzleId)) return PuzzleGridTileState.solved;
    if (isPuzzleSkipped(puzzle.puzzleId)) return PuzzleGridTileState.skipped;
    final frontier = frontierPuzzleIndexForNode(node);
    if (index == frontier) return PuzzleGridTileState.nextAvailable;
    if (index < frontier) return PuzzleGridTileState.replayable;
    return PuzzleGridTileState.locked;
  }

  bool canOpenGridIndex(EloNodeProgress node, int index) {
    final state = tileStateForNodeIndex(node, index);
    return state != PuzzleGridTileState.locked;
  }

  void consumeBrainBreakTrigger() {
    if (!_shouldShowBrainBreak) return;
    _shouldShowBrainBreak = false;
    notifyListeners();
  }

  void consumeGrandmasterOracleTrigger() {
    if (!_shouldShowGrandmasterOracle) return;
    _shouldShowGrandmasterOracle = false;
    notifyListeners();
  }

  void consumeCelebrationNode() {
    if (_celebrationNodeKey == null) return;
    _celebrationNodeKey = null;
    notifyListeners();
  }

  Future<void> syncCoinsFromStoreState({bool notify = true}) async {
    if (_progress == null) return;

    final prefs = await SharedPreferences.getInstance();
    final signed = LocalIntegrityService.decodeJson(
      prefs.getString(_sharedStoreStateKey),
      scope: _storeIntegrityScope,
    );
    if (signed.data == null || (signed.isSigned && !signed.isValid)) {
      await _mirrorCoinsToStoreState(progress.coins, prefs: prefs);
      return;
    }

    try {
      final storeCoins = (signed.data!['coins'] as num?)?.toInt();
      if (storeCoins == null) {
        await _mirrorCoinsToStoreState(progress.coins, prefs: prefs);
        return;
      }

      final normalizedCoins = max(0, storeCoins);
      if (normalizedCoins == progress.coins &&
          (_economyProvider == null ||
              !_economyProvider!.loaded ||
              _economyProvider!.coins == normalizedCoins)) {
        return;
      }

      if (_economyProvider != null) {
        await _economyProvider!.setCoins(normalizedCoins, notify: false);
      }
      _progress = progress.copyWith(coins: normalizedCoins);
      await _saveProgress(mirrorStoreCoins: false);
      if (notify) {
        notifyListeners();
      }
    } catch (_) {
      await _mirrorCoinsToStoreState(progress.coins, prefs: prefs);
    }
  }

  Future<void> _saveProgress({bool mirrorStoreCoins = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _progressKey,
      LocalIntegrityService.wrapJson(
        progress.toMap(),
        scope: _progressIntegrityScope,
      ),
    );
    if (mirrorStoreCoins) {
      await _mirrorCoinsToStoreState(progress.coins, prefs: prefs);
    }
  }

  Future<void> _saveUpdatedProgress(
    PuzzleProgressModel updated, {
    bool syncCoins = false,
  }) async {
    if (syncCoins && _economyProvider != null) {
      await _economyProvider!.setCoins(updated.coins, notify: false);
      _progress = updated.copyWith(coins: _economyProvider!.coins);
      await _saveProgress(mirrorStoreCoins: false);
      return;
    }

    _progress = updated;
    await _saveProgress();
  }

  Future<void> _mirrorCoinsToStoreState(
    int coins, {
    SharedPreferences? prefs,
  }) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    final signed = LocalIntegrityService.decodeJson(
      resolvedPrefs.getString(_sharedStoreStateKey),
      scope: _storeIntegrityScope,
    );
    final payload = (signed.isSigned && !signed.isValid)
        ? <String, dynamic>{}
        : <String, dynamic>{...?signed.data};

    payload['coins'] = max(0, coins);
    await resolvedPrefs.setString(
      _sharedStoreStateKey,
      LocalIntegrityService.wrapJson(payload, scope: _storeIntegrityScope),
    );
  }

  void _normalizeUnlockState() {
    _progress = progress.copyWith(nodes: _normalizedNodesFor(progress));
  }

  PuzzleProgressModel _applyUnlockingAndRewards(PuzzleProgressModel current) {
    final nodes = current.nodes.values.toList(growable: false)
      ..sort((a, b) => a.startElo.compareTo(b.startElo));
    final updated = Map<String, EloNodeProgress>.from(current.nodes);
    var unlockedRewards = Set<String>.from(current.unlockedThemeRewards);
    var depthUnlocked = current.depth33To35Unlocked;
    var oracleTriggered = current.grandmasterOracleTriggered;

    for (var index = 0; index < nodes.length; index++) {
      final node = updated[nodes[index].key] ?? nodes[index];

      if (node.solvedCount >= node.unlockTarget && index < nodes.length - 1) {
        final nextNode = updated[nodes[index + 1].key] ?? nodes[index + 1];
        if (!nextNode.unlocked) {
          updated[nextNode.key] = nextNode.copyWith(unlocked: true);
        }
      }

      final completedCount = completedPuzzleCountForNode(node, current);
      final crownAchieved = completedCount >= node.masteryTarget;
      if (crownAchieved && !node.goldCrown) {
        _celebrationNodeKey = node.key;
        updated[node.key] = (updated[node.key] ?? node).copyWith(
          goldCrown: true,
        );
      }

      if (crownAchieved && !(updated[node.key]?.themeRewardUnlocked ?? false)) {
        final rewardId = 'theme_${node.startElo}_${node.endElo}';
        unlockedRewards.add(rewardId);
        updated[node.key] = (updated[node.key] ?? node).copyWith(
          themeRewardUnlocked: true,
        );
      }

      final isFinalTier = node.startElo >= 3000;
      if (isFinalTier && node.solvedCount >= node.masteryTarget) {
        depthUnlocked = true;
        if (!oracleTriggered) {
          _shouldShowGrandmasterOracle = true;
          oracleTriggered = true;
        }
      }
    }

    final normalized = current.copyWith(
      nodes: updated,
      unlockedThemeRewards: unlockedRewards,
      depth33To35Unlocked: depthUnlocked,
      grandmasterOracleTriggered: oracleTriggered,
    );

    return normalized.copyWith(nodes: _normalizedNodesFor(normalized));
  }

  Map<String, EloNodeProgress> _buildInitialNodes(Map<String, int> counts) {
    if (counts.isEmpty) {
      return <String, EloNodeProgress>{
        '450_500': const EloNodeProgress(
          startElo: 450,
          endElo: 500,
          totalPuzzles: 0,
          solvedCount: 0,
          attempts: 0,
          unlocked: true,
          goldCrown: false,
          themeRewardUnlocked: false,
          speedDemon: false,
        ),
      };
    }

    final sortedKeys = counts.keys.toList(growable: false)
      ..sort((a, b) {
        final aStart = int.parse(a.split('_').first);
        final bStart = int.parse(b.split('_').first);
        return aStart.compareTo(bStart);
      });

    final result = <String, EloNodeProgress>{};
    for (var index = 0; index < sortedKeys.length; index++) {
      final key = sortedKeys[index];
      final parts = key.split('_');
      final start = int.parse(parts.first);
      final end = int.parse(parts.last);
      final total = counts[key] ?? 0;
      result[key] = EloNodeProgress(
        startElo: start,
        endElo: end,
        totalPuzzles: total,
        solvedCount: 0,
        attempts: 0,
        unlocked: index == 0,
        goldCrown: false,
        themeRewardUnlocked: false,
        speedDemon: false,
        finalTierTarget: start >= 3000 ? 26 : 500,
      );
    }

    return result;
  }

  Future<Map<String, int>> _loadBasePuzzleCounts() async {
    final raw = await rootBundle.loadString(_basePuzzleAssetPath);
    final counts = <String, int>{};
    for (final match in _ratingPattern.allMatches(raw)) {
      final rating = int.tryParse(match.group(1) ?? '');
      if (rating == null) {
        continue;
      }
      final key = _nodeKeyForRating(rating);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _ensureNodePuzzlesLoaded(Set<String> nodeKeys) async {
    if (nodeKeys.isEmpty) return;

    final pending = <Future<void>>[];
    final missing = <String>{};

    for (final key in nodeKeys) {
      if (_basePuzzleCacheByNode.containsKey(key)) {
        continue;
      }
      final existingLoad = _nodePuzzleLoadFutures[key];
      if (existingLoad != null) {
        pending.add(existingLoad);
        continue;
      }
      missing.add(key);
    }

    if (missing.isNotEmpty) {
      final loadFuture = _loadNodePuzzles(missing);
      for (final key in missing) {
        _nodePuzzleLoadFutures[key] = loadFuture;
      }
      pending.add(loadFuture);
    }

    if (pending.isEmpty) return;
    await Future.wait(pending);
  }

  Future<void> _loadNodePuzzles(Set<String> nodeKeys) async {
    try {
      final raw = await rootBundle.loadString(_basePuzzleAssetPath);
      final loaded = <String, List<PuzzleItem>>{};
      var processed = 0;

      for (final objectSlice in _iterateJsonObjects(raw)) {
        processed += 1;
        if (processed % 250 == 0) {
          await Future<void>.delayed(Duration.zero);
        }

        try {
          final decoded = jsonDecode(objectSlice);
          if (decoded is! Map) {
            continue;
          }

          final map = decoded.cast<String, dynamic>();
          final rating = int.tryParse(map['Rating']?.toString() ?? '');
          if (rating == null) {
            continue;
          }

          final key = _nodeKeyForRating(rating);
          if (!nodeKeys.contains(key)) {
            continue;
          }

          final item = PuzzleItem.fromMap(map);
          if (!_validatePuzzle(item)) {
            continue;
          }

          (loaded[key] ??= <PuzzleItem>[]).add(item);
        } catch (_) {
          continue;
        }
      }

      for (final key in nodeKeys) {
        final items = loaded[key] ?? <PuzzleItem>[];
        items.sort((a, b) {
          final ratingCompare = a.rating.compareTo(b.rating);
          if (ratingCompare != 0) return ratingCompare;
          return a.puzzleId.compareTo(b.puzzleId);
        });
        _basePuzzleCacheByNode[key] = items;
      }
    } finally {
      for (final key in nodeKeys) {
        _nodePuzzleLoadFutures.remove(key);
      }
    }
  }

  Future<List<PuzzleItem>> _loadPuzzleList(String assetPath) async {
    final text = await rootBundle.loadString(assetPath);
    final decoded = await compute(_decodePuzzleMaps, text);
    return decoded.map(PuzzleItem.fromMap).toList(growable: false);
  }

  Future<List<String>> _loadDailyAssetPaths() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final dailyPaths =
        manifest
            .listAssets()
            .where(
              (path) =>
                  path.startsWith('assets/puzzles/daily_puzzles_') &&
                  path.endsWith('.json'),
            )
            .toList(growable: false)
          ..sort();
    return dailyPaths;
  }

  Future<void> _refreshTodayDailyPuzzle({required bool notify}) async {
    if (_serverDateStamp == null) {
      await _initServerDate();
    }
    if (_serverDateStamp == null) {
      _todayDailyPuzzleAssetPath = null;
      _todayDailyPuzzle = null;
      _dailyPuzzles = const <PuzzleItem>[];
      if (notify) notifyListeners();
      return;
    }
    final todayStamp = _todayStamp();
    final matchedPath = _dailyPuzzleAssetPaths.lastWhere(
      (path) => path.contains('daily_puzzles_${todayStamp}_'),
      orElse: () => '',
    );
    _todayDailyPuzzleAssetPath = matchedPath.isEmpty ? null : matchedPath;
    if (_todayDailyPuzzleAssetPath == null) {
      _todayDailyPuzzle = null;
      _dailyPuzzles = const <PuzzleItem>[];
      if (notify) notifyListeners();
      return;
    }

    final puzzles = await _loadPuzzleList(_todayDailyPuzzleAssetPath!);
    _dailyPuzzles = puzzles.take(20).toList(growable: false);
    _todayDailyPuzzle = _dailyPuzzles.isEmpty ? null : _dailyPuzzles.first;
    if (notify) notifyListeners();
  }

  String _dateStamp(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  String _todayStamp() {
    final stamp = _serverDateStamp;
    final fetchedAt = _serverDateFetchedAt;
    if (stamp == null || fetchedAt == null) {
      return _dateStamp(DateTime.now().toUtc());
    }
    final year = int.parse(stamp.substring(0, 4));
    final month = int.parse(stamp.substring(4, 6));
    final day = int.parse(stamp.substring(6, 8));
    final serverMidnight = DateTime.utc(year, month, day);
    final elapsed = DateTime.now().toUtc().difference(fetchedAt);
    return _dateStamp(serverMidnight.add(elapsed));
  }

  static const String _cfBase =
      'https://us-central1-chessiq-89b45.cloudfunctions.net';

  Future<void> _initServerDate() async {
    try {
      final token = await FirebaseAuthService.instance.getIdToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final response = await http
          .post(
            Uri.parse('$_cfBase/getServerDate'),
            headers: headers,
            body: jsonEncode({'data': {}}),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final date = (body['result'] as Map?)?['date'] as String?;
        if (date != null && date.length == 8) {
          _serverDateStamp = date;
          _serverDateFetchedAt = DateTime.now().toUtc();
        }
      }
    } catch (_) {
      // Network unavailable - fall back to device clock silently.
    }
  }
}
