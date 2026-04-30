import 'dart:math';

import 'package:chessiq/features/analysis/models/analysis_models.dart';

enum BotSkillProfile {
  baby,
  nephew,
  bestFriend,
  nerdyGirl,
  teenBoy,
  uncle,
  grandpa,
  interGm,
}

enum BotDifficulty { easy, medium, hard }

extension BotDifficultyX on BotDifficulty {
  String get label {
    switch (this) {
      case BotDifficulty.easy:
        return 'Easy';
      case BotDifficulty.medium:
        return 'Medium';
      case BotDifficulty.hard:
        return 'Hard';
    }
  }

  String get storageKey => name;

  BotDifficulty? get next {
    switch (this) {
      case BotDifficulty.easy:
        return BotDifficulty.medium;
      case BotDifficulty.medium:
        return BotDifficulty.hard;
      case BotDifficulty.hard:
        return null;
    }
  }
}

enum BotSideChoice { white, random, black }

enum GameOutcome { whiteWin, blackWin, draw }

class BotMoveCandidate {
  final EngineLine line;
  final bool isCapture;
  final bool isCheck;

  const BotMoveCandidate({
    required this.line,
    this.isCapture = false,
    this.isCheck = false,
  });

  int evalGapFrom(int bestEval) {
    return max(0, bestEval - line.eval);
  }
}

class BotMoveSelectionPolicy {
  final List<int> rankWeights;
  final int safeEvalGapCp;
  final int nearBestEvalGapCp;
  final int nearBestBonus;
  final int captureBias;
  final int checkBias;
  final int quietBias;

  const BotMoveSelectionPolicy({
    required this.rankWeights,
    required this.safeEvalGapCp,
    this.nearBestEvalGapCp = 0,
    this.nearBestBonus = 0,
    this.captureBias = 0,
    this.checkBias = 0,
    this.quietBias = 0,
  });

  int weightFor(BotMoveCandidate candidate, {required int bestEval}) {
    final baseWeight = _rankWeightFor(candidate.line.multiPv);
    if (baseWeight <= 0) {
      return 0;
    }

    var weight = baseWeight;
    final evalGap = candidate.evalGapFrom(bestEval);
    if (evalGap <= nearBestEvalGapCp) {
      weight += nearBestBonus;
    }
    if (candidate.isCapture) {
      weight += captureBias;
    }
    if (candidate.isCheck) {
      weight += checkBias;
    }
    if (!candidate.isCapture && !candidate.isCheck) {
      weight += quietBias;
    }

    return max(1, weight);
  }

  int _rankWeightFor(int rank) {
    final idx = rank - 1;
    if (idx < 0 || idx >= rankWeights.length) {
      return 0;
    }
    return rankWeights[idx];
  }
}

class BotMoveSelector {
  const BotMoveSelector._();

  static BotMoveCandidate? pickCandidate(
    List<BotMoveCandidate> candidates,
    BotMoveSelectionPolicy policy,
    Random rng,
  ) {
    if (candidates.isEmpty) {
      return null;
    }

    final ordered = List<BotMoveCandidate>.from(candidates)
      ..sort((a, b) => a.line.multiPv.compareTo(b.line.multiPv));

    final bestEval = ordered.first.line.eval;
    final safePool = ordered
        .where(
          (candidate) =>
              candidate.evalGapFrom(bestEval) <= policy.safeEvalGapCp,
        )
        .toList(growable: false);
    final pool = safePool.isNotEmpty
        ? safePool
        : <BotMoveCandidate>[ordered.first];
    if (pool.length == 1) {
      return pool.first;
    }

    final weightedPool = <_WeightedBotMoveCandidate>[];
    var totalWeight = 0;
    for (final candidate in pool) {
      final weight = policy.weightFor(candidate, bestEval: bestEval);
      if (weight <= 0) {
        continue;
      }
      totalWeight += weight;
      weightedPool.add(_WeightedBotMoveCandidate(candidate, totalWeight));
    }

    if (weightedPool.isEmpty) {
      return pool.first;
    }

    final roll = rng.nextInt(totalWeight);
    for (final weightedCandidate in weightedPool) {
      if (roll < weightedCandidate.cumulativeWeight) {
        return weightedCandidate.candidate;
      }
    }

    return weightedPool.last.candidate;
  }

  static String? pickMove(
    List<BotMoveCandidate> candidates,
    BotMoveSelectionPolicy policy,
    Random rng,
  ) {
    return pickCandidate(candidates, policy, rng)?.line.move;
  }
}

class _WeightedBotMoveCandidate {
  final BotMoveCandidate candidate;
  final int cumulativeWeight;

  const _WeightedBotMoveCandidate(this.candidate, this.cumulativeWeight);
}

class BotDifficultySettings {
  final BotDifficulty difficulty;
  final int elo;
  final bool limitStrength;
  final int multiPv;
  final int threads;
  final int? contempt;
  final int? skillLevel;
  final int? searchDepth;
  final int? moveTimeMs;
  final String avatarAsset;
  final BotMoveSelectionPolicy? moveSelectionPolicy;

  const BotDifficultySettings({
    required this.difficulty,
    required this.elo,
    this.limitStrength = true,
    required this.multiPv,
    required this.threads,
    this.contempt,
    this.skillLevel,
    this.searchDepth,
    this.moveTimeMs,
    required this.avatarAsset,
    this.moveSelectionPolicy,
  });
}

class BotCharacter {
  final int rank;
  final String id;
  final String name;
  final String description;
  final BotSkillProfile profile;
  final BotDifficultySettings easy;
  final BotDifficultySettings medium;
  final BotDifficultySettings hard;

  const BotCharacter({
    required this.rank,
    required this.id,
    required this.name,
    required this.description,
    required this.profile,
    required this.easy,
    required this.medium,
    required this.hard,
  });

  BotDifficultySettings settingsFor(BotDifficulty difficulty) {
    switch (difficulty) {
      case BotDifficulty.easy:
        return easy;
      case BotDifficulty.medium:
        return medium;
      case BotDifficulty.hard:
        return hard;
    }
  }

  String? avatarAssetFor(BotDifficulty difficulty) {
    return settingsFor(difficulty).avatarAsset;
  }

  int get elo => easy.elo;
  bool get limitStrength => easy.limitStrength;
  int get multiPv => easy.multiPv;
  int get threads => easy.threads;
  int? get contempt => easy.contempt;
  int? get skillLevel => easy.skillLevel;
  int? get searchDepth => easy.searchDepth;
  int? get moveTimeMs => easy.moveTimeMs;
  String? get avatarAsset => easy.avatarAsset;
}
