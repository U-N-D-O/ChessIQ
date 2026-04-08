import 'dart:convert';

class PuzzleProgressModel {
  final int coins;
  final int freeHints;
  final int freeSkips;
  final int streak;
  final int adCounter;
  final bool depth33To35Unlocked;
  final bool grandmasterOracleTriggered;
  final Map<String, EloNodeProgress> nodes;
  final Set<String> seenSemesters;
  final Set<String> completedDailyPuzzleIds;
  final Set<String> skippedPuzzleIds;
  final Set<String> unlockedThemeRewards;
  final Set<String> solvedPuzzleIds;
  final Set<String> speedDemonNodeKeys;
  final Map<String, int> bestSolveTimeMsByPuzzleId;
  final List<AcademyExamResult> examResults;

  const PuzzleProgressModel({
    required this.coins,
    required this.freeHints,
    required this.freeSkips,
    required this.streak,
    required this.adCounter,
    required this.depth33To35Unlocked,
    required this.grandmasterOracleTriggered,
    required this.nodes,
    required this.seenSemesters,
    required this.completedDailyPuzzleIds,
    required this.skippedPuzzleIds,
    required this.unlockedThemeRewards,
    required this.solvedPuzzleIds,
    required this.speedDemonNodeKeys,
    required this.bestSolveTimeMsByPuzzleId,
    required this.examResults,
  });

  factory PuzzleProgressModel.initial({
    required Map<String, EloNodeProgress> nodes,
  }) {
    return PuzzleProgressModel(
      coins: 120,
      freeHints: 3,
      freeSkips: 2,
      streak: 0,
      adCounter: 0,
      depth33To35Unlocked: false,
      grandmasterOracleTriggered: false,
      nodes: nodes,
      seenSemesters: <String>{},
      completedDailyPuzzleIds: <String>{},
      skippedPuzzleIds: <String>{},
      unlockedThemeRewards: <String>{},
      solvedPuzzleIds: <String>{},
      speedDemonNodeKeys: <String>{},
      bestSolveTimeMsByPuzzleId: <String, int>{},
      examResults: const <AcademyExamResult>[],
    );
  }

  PuzzleProgressModel copyWith({
    int? coins,
    int? freeHints,
    int? freeSkips,
    int? streak,
    int? adCounter,
    bool? depth33To35Unlocked,
    bool? grandmasterOracleTriggered,
    Map<String, EloNodeProgress>? nodes,
    Set<String>? seenSemesters,
    Set<String>? completedDailyPuzzleIds,
    Set<String>? skippedPuzzleIds,
    Set<String>? unlockedThemeRewards,
    Set<String>? solvedPuzzleIds,
    Set<String>? speedDemonNodeKeys,
    Map<String, int>? bestSolveTimeMsByPuzzleId,
    List<AcademyExamResult>? examResults,
  }) {
    return PuzzleProgressModel(
      coins: coins ?? this.coins,
      freeHints: freeHints ?? this.freeHints,
      freeSkips: freeSkips ?? this.freeSkips,
      streak: streak ?? this.streak,
      adCounter: adCounter ?? this.adCounter,
      depth33To35Unlocked: depth33To35Unlocked ?? this.depth33To35Unlocked,
      grandmasterOracleTriggered:
          grandmasterOracleTriggered ?? this.grandmasterOracleTriggered,
      nodes: nodes ?? this.nodes,
      seenSemesters: seenSemesters ?? this.seenSemesters,
      completedDailyPuzzleIds:
          completedDailyPuzzleIds ?? this.completedDailyPuzzleIds,
      skippedPuzzleIds: skippedPuzzleIds ?? this.skippedPuzzleIds,
      unlockedThemeRewards: unlockedThemeRewards ?? this.unlockedThemeRewards,
      solvedPuzzleIds: solvedPuzzleIds ?? this.solvedPuzzleIds,
      speedDemonNodeKeys: speedDemonNodeKeys ?? this.speedDemonNodeKeys,
      bestSolveTimeMsByPuzzleId:
          bestSolveTimeMsByPuzzleId ?? this.bestSolveTimeMsByPuzzleId,
      examResults: examResults ?? this.examResults,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'coins': coins,
      'freeHints': freeHints,
      'freeSkips': freeSkips,
      'streak': streak,
      'adCounter': adCounter,
      'depth33To35Unlocked': depth33To35Unlocked,
      'grandmasterOracleTriggered': grandmasterOracleTriggered,
      'nodes': nodes.map((k, v) => MapEntry<String, dynamic>(k, v.toMap())),
      'seenSemesters': seenSemesters.toList(growable: false),
      'completedDailyPuzzleIds': completedDailyPuzzleIds.toList(
        growable: false,
      ),
      'skippedPuzzleIds': skippedPuzzleIds.toList(growable: false),
      'unlockedThemeRewards': unlockedThemeRewards.toList(growable: false),
      'solvedPuzzleIds': solvedPuzzleIds.toList(growable: false),
      'speedDemonNodeKeys': speedDemonNodeKeys.toList(growable: false),
      'bestSolveTimeMsByPuzzleId': bestSolveTimeMsByPuzzleId,
      'examResults': examResults.map((result) => result.toMap()).toList(),
    };
  }

  factory PuzzleProgressModel.fromMap(
    Map<String, dynamic> map, {
    required Map<String, EloNodeProgress> fallbackNodes,
  }) {
    final rawNodes =
        (map['nodes'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final mergedNodes = <String, EloNodeProgress>{};

    for (final entry in fallbackNodes.entries) {
      final raw = rawNodes[entry.key];
      if (raw is Map) {
        mergedNodes[entry.key] =
            EloNodeProgress.fromMap(raw.cast<String, dynamic>()).mergeMeta(
              startElo: entry.value.startElo,
              endElo: entry.value.endElo,
              totalPuzzles: entry.value.totalPuzzles,
              finalTierTarget: entry.value.finalTierTarget,
            );
      } else {
        mergedNodes[entry.key] = entry.value;
      }
    }

    final bestSolveRaw =
        (map['bestSolveTimeMsByPuzzleId'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final examResultsRaw = (map['examResults'] as List?) ?? const <dynamic>[];

    return PuzzleProgressModel(
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      freeHints: (map['freeHints'] as num?)?.toInt() ?? 0,
      freeSkips: (map['freeSkips'] as num?)?.toInt() ?? 0,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      adCounter: (map['adCounter'] as num?)?.toInt() ?? 0,
      depth33To35Unlocked: map['depth33To35Unlocked'] == true,
      grandmasterOracleTriggered: map['grandmasterOracleTriggered'] == true,
      nodes: mergedNodes,
      seenSemesters: ((map['seenSemesters'] as List?) ?? const <dynamic>[])
          .map((e) => e.toString())
          .toSet(),
      completedDailyPuzzleIds:
          ((map['completedDailyPuzzleIds'] as List?) ?? const <dynamic>[])
              .map((e) => e.toString())
              .toSet(),
      skippedPuzzleIds:
          ((map['skippedPuzzleIds'] as List?) ?? const <dynamic>[])
              .map((e) => e.toString())
              .toSet(),
      unlockedThemeRewards:
          ((map['unlockedThemeRewards'] as List?) ?? const <dynamic>[])
              .map((e) => e.toString())
              .toSet(),
      solvedPuzzleIds: ((map['solvedPuzzleIds'] as List?) ?? const <dynamic>[])
          .map((e) => e.toString())
          .toSet(),
      speedDemonNodeKeys:
          ((map['speedDemonNodeKeys'] as List?) ?? const <dynamic>[])
              .map((e) => e.toString())
              .toSet(),
      bestSolveTimeMsByPuzzleId: bestSolveRaw.map(
        (key, value) => MapEntry<String, int>(key, (value as num).toInt()),
      ),
      examResults: examResultsRaw
          .whereType<Map>()
          .map(
            (entry) => AcademyExamResult.fromMap(entry.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PuzzleProgressModel.fromJson(
    String source, {
    required Map<String, EloNodeProgress> fallbackNodes,
  }) {
    return PuzzleProgressModel.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
      fallbackNodes: fallbackNodes,
    );
  }
}

class EloNodeProgress {
  final int startElo;
  final int endElo;
  final int totalPuzzles;
  final int solvedCount;
  final int attempts;
  final bool unlocked;
  final bool goldCrown;
  final bool themeRewardUnlocked;
  final bool speedDemon;
  final int finalTierTarget;

  const EloNodeProgress({
    required this.startElo,
    required this.endElo,
    required this.totalPuzzles,
    required this.solvedCount,
    required this.attempts,
    required this.unlocked,
    required this.goldCrown,
    required this.themeRewardUnlocked,
    required this.speedDemon,
    this.finalTierTarget = 26,
  });

  String get key => '${startElo}_$endElo';

  String get title => '$startElo-$endElo';

  int get unlockTarget => totalPuzzles <= 26 ? totalPuzzles : 100;

  int get masteryTarget {
    if (startElo >= 3000) {
      return finalTierTarget;
    }
    return totalPuzzles >= 500 ? 500 : totalPuzzles;
  }

  double get unlockProgress {
    final target = unlockTarget <= 0 ? 1 : unlockTarget;
    return (solvedCount.clamp(0, target) / target).clamp(0.0, 1.0);
  }

  double get masteryProgress {
    final target = masteryTarget <= 0 ? 1 : masteryTarget;
    return (solvedCount.clamp(0, target) / target).clamp(0.0, 1.0);
  }

  EloNodeProgress copyWith({
    int? startElo,
    int? endElo,
    int? totalPuzzles,
    int? solvedCount,
    int? attempts,
    bool? unlocked,
    bool? goldCrown,
    bool? themeRewardUnlocked,
    bool? speedDemon,
    int? finalTierTarget,
  }) {
    return EloNodeProgress(
      startElo: startElo ?? this.startElo,
      endElo: endElo ?? this.endElo,
      totalPuzzles: totalPuzzles ?? this.totalPuzzles,
      solvedCount: solvedCount ?? this.solvedCount,
      attempts: attempts ?? this.attempts,
      unlocked: unlocked ?? this.unlocked,
      goldCrown: goldCrown ?? this.goldCrown,
      themeRewardUnlocked: themeRewardUnlocked ?? this.themeRewardUnlocked,
      speedDemon: speedDemon ?? this.speedDemon,
      finalTierTarget: finalTierTarget ?? this.finalTierTarget,
    );
  }

  EloNodeProgress mergeMeta({
    required int startElo,
    required int endElo,
    required int totalPuzzles,
    required int finalTierTarget,
  }) {
    return copyWith(
      startElo: startElo,
      endElo: endElo,
      totalPuzzles: totalPuzzles,
      finalTierTarget: finalTierTarget,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startElo': startElo,
      'endElo': endElo,
      'totalPuzzles': totalPuzzles,
      'solvedCount': solvedCount,
      'attempts': attempts,
      'unlocked': unlocked,
      'goldCrown': goldCrown,
      'themeRewardUnlocked': themeRewardUnlocked,
      'speedDemon': speedDemon,
      'finalTierTarget': finalTierTarget,
    };
  }

  factory EloNodeProgress.fromMap(Map<String, dynamic> map) {
    return EloNodeProgress(
      startElo: (map['startElo'] as num?)?.toInt() ?? 0,
      endElo: (map['endElo'] as num?)?.toInt() ?? 0,
      totalPuzzles: (map['totalPuzzles'] as num?)?.toInt() ?? 0,
      solvedCount: (map['solvedCount'] as num?)?.toInt() ?? 0,
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      unlocked: map['unlocked'] == true,
      goldCrown: map['goldCrown'] == true,
      themeRewardUnlocked: map['themeRewardUnlocked'] == true,
      speedDemon: map['speedDemon'] == true,
      finalTierTarget: (map['finalTierTarget'] as num?)?.toInt() ?? 26,
    );
  }
}

class SemesterRange {
  final String id;
  final String title;
  final int minElo;
  final int maxElo;
  final String intro;
  final String description;

  const SemesterRange({
    required this.id,
    required this.title,
    required this.minElo,
    required this.maxElo,
    required this.intro,
    String? description,
  }) : description = description ?? intro;

  bool includes(int elo) => elo >= minElo && elo <= maxElo;
}

class PuzzleItem {
  final String puzzleId;
  final String fen;
  final List<String> moves;
  final int rating;
  final String gameUrl;
  final List<String> themes;
  final List<String> openingTags;

  const PuzzleItem({
    required this.puzzleId,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.gameUrl,
    required this.themes,
    required this.openingTags,
  });

  factory PuzzleItem.fromMap(Map<String, dynamic> map) {
    return PuzzleItem(
      puzzleId: map['PuzzleId']?.toString() ?? '',
      fen: map['FEN']?.toString() ?? '',
      moves: (map['Moves']?.toString() ?? '')
          .split(RegExp(r'\s+'))
          .where((m) => m.trim().isNotEmpty)
          .toList(growable: false),
      rating: int.tryParse(map['Rating']?.toString() ?? '') ?? 0,
      gameUrl: map['GameUrl']?.toString() ?? '',
      themes: (map['Themes']?.toString() ?? '')
          .split(RegExp(r'\s+'))
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false),
      openingTags: (map['OpeningTags']?.toString() ?? '')
          .split(RegExp(r'\s+'))
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false),
    );
  }
}

class AcademyExamResult {
  final String nodeKey;
  final int score;
  final int correctCount;
  final int totalCount;
  final int elapsedMs;
  final int timeLimitMs;
  final int completedAtMs;

  const AcademyExamResult({
    required this.nodeKey,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.elapsedMs,
    required this.timeLimitMs,
    required this.completedAtMs,
  });

  double get accuracy => totalCount <= 0 ? 0.0 : correctCount / totalCount;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nodeKey': nodeKey,
      'score': score,
      'correctCount': correctCount,
      'totalCount': totalCount,
      'elapsedMs': elapsedMs,
      'timeLimitMs': timeLimitMs,
      'completedAtMs': completedAtMs,
    };
  }

  factory AcademyExamResult.fromMap(Map<String, dynamic> map) {
    return AcademyExamResult(
      nodeKey: map['nodeKey']?.toString() ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      correctCount: (map['correctCount'] as num?)?.toInt() ?? 0,
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
      elapsedMs: (map['elapsedMs'] as num?)?.toInt() ?? 0,
      timeLimitMs: (map['timeLimitMs'] as num?)?.toInt() ?? 0,
      completedAtMs: (map['completedAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String handle;
  final int score;
  final String title;

  const LeaderboardEntry({
    required this.rank,
    required this.handle,
    required this.score,
    required this.title,
  });
}
