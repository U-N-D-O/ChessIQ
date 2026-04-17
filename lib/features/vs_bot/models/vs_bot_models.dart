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
