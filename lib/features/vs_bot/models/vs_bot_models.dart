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

enum BotSideChoice { white, random, black }

enum GameOutcome { whiteWin, blackWin, draw }

class BotCharacter {
  final int rank;
  final String name;
  final String description;
  final int elo;
  final bool limitStrength;
  final int multiPv;
  final int threads;
  final int? contempt;
  final int? skillLevel;
  final int? searchDepth;
  final int? moveTimeMs;
  final BotSkillProfile profile;
  final String? avatarAsset;

  const BotCharacter({
    required this.rank,
    required this.name,
    required this.description,
    required this.elo,
    this.limitStrength = true,
    required this.multiPv,
    required this.threads,
    this.contempt,
    this.skillLevel,
    this.searchDepth,
    this.moveTimeMs,
    required this.profile,
    this.avatarAsset,
  });
}
