import 'package:chessiq/features/vs_bot/models/vs_bot_models.dart';

const BotMoveSelectionPolicy _rexHardSelectionPolicy = BotMoveSelectionPolicy(
  rankWeights: <int>[5, 6, 4, 2, 1],
  safeEvalGapCp: 110,
  nearBestEvalGapCp: 18,
  nearBestBonus: 2,
  captureBias: 3,
  checkBias: 2,
);

const BotMoveSelectionPolicy _octavianEasySelectionPolicy =
    BotMoveSelectionPolicy(
      rankWeights: <int>[5, 6, 4, 2, 1],
      safeEvalGapCp: 90,
      nearBestEvalGapCp: 16,
      nearBestBonus: 2,
      captureBias: -1,
      quietBias: 2,
    );

const BotMoveSelectionPolicy _octavianMediumSelectionPolicy =
    BotMoveSelectionPolicy(
      rankWeights: <int>[7, 5, 3, 1],
      safeEvalGapCp: 70,
      nearBestEvalGapCp: 14,
      nearBestBonus: 2,
      captureBias: -1,
      quietBias: 2,
    );

const BotMoveSelectionPolicy _octavianHardSelectionPolicy =
    BotMoveSelectionPolicy(
      rankWeights: <int>[9, 5, 2, 1],
      safeEvalGapCp: 55,
      nearBestEvalGapCp: 12,
      nearBestBonus: 2,
      captureBias: -1,
      quietBias: 2,
    );

const BotMoveSelectionPolicy _masterPrimeEasySelectionPolicy =
    BotMoveSelectionPolicy(
      rankWeights: <int>[10, 5, 2, 1],
      safeEvalGapCp: 60,
      nearBestEvalGapCp: 10,
      nearBestBonus: 2,
      quietBias: 1,
    );

const BotMoveSelectionPolicy _masterPrimeMediumSelectionPolicy =
    BotMoveSelectionPolicy(
      rankWeights: <int>[12, 4, 1, 1],
      safeEvalGapCp: 45,
      nearBestEvalGapCp: 8,
      nearBestBonus: 3,
      quietBias: 1,
    );

const BotMoveSelectionPolicy _masterPrimeHardSelectionPolicy =
    BotMoveSelectionPolicy(
      rankWeights: <int>[18, 4, 1],
      safeEvalGapCp: 35,
      nearBestEvalGapCp: 4,
      nearBestBonus: 3,
      quietBias: 1,
    );

const List<BotCharacter> botRoster = <BotCharacter>[
  BotCharacter(
    rank: 1,
    id: 'mochi-gearheart',
    name: 'Mochi Gearheart',
    description: 'I just wanted to see the pretty wooden pieces...',
    profile: BotSkillProfile.baby,
    easy: BotDifficultySettings(
      difficulty: BotDifficulty.easy,
      elo: 100,
      multiPv: 20,
      threads: 1,
      skillLevel: 0,
      searchDepth: 1,
      moveTimeMs: 800,
      avatarAsset: 'assets/bots/hammy.png',
    ),
    medium: BotDifficultySettings(
      difficulty: BotDifficulty.medium,
      elo: 300,
      multiPv: 12,
      threads: 1,
      skillLevel: 3,
      searchDepth: 3,
      moveTimeMs: 1000,
      avatarAsset: 'assets/bots/hammy2.png',
    ),
    hard: BotDifficultySettings(
      difficulty: BotDifficulty.hard,
      elo: 525,
      multiPv: 6,
      threads: 1,
      skillLevel: 6,
      searchDepth: 5,
      moveTimeMs: 1250,
      avatarAsset: 'assets/bots/hammy3.png',
    ),
  ),
  BotCharacter(
    rank: 2,
    id: 'checkmate-carl',
    name: 'Checkmate Carl',
    description: 'Mate in three? 👍.',
    profile: BotSkillProfile.nephew,
    easy: BotDifficultySettings(
      difficulty: BotDifficulty.easy,
      elo: 450,
      multiPv: 8,
      threads: 1,
      skillLevel: 2,
      searchDepth: 2,
      moveTimeMs: 500,
      avatarAsset: 'assets/bots/ok.png',
    ),
    medium: BotDifficultySettings(
      difficulty: BotDifficulty.medium,
      elo: 700,
      multiPv: 6,
      threads: 1,
      skillLevel: 5,
      searchDepth: 5,
      moveTimeMs: 850,
      avatarAsset: 'assets/bots/ok2.png',
    ),
    hard: BotDifficultySettings(
      difficulty: BotDifficulty.hard,
      elo: 900,
      multiPv: 4,
      threads: 1,
      skillLevel: 8,
      searchDepth: 7,
      moveTimeMs: 1100,
      avatarAsset: 'assets/bots/ok3.png',
    ),
  ),
  BotCharacter(
    rank: 3,
    id: 'rex-halfcheck',
    name: 'Rex Halfcheck',
    description:
        'Do you even lift (your pieces), bro? I\'m going to crush your center like it\'s leg day.',
    profile: BotSkillProfile.teenBoy,
    easy: BotDifficultySettings(
      difficulty: BotDifficulty.easy,
      elo: 800,
      multiPv: 3,
      threads: 1,
      skillLevel: 8,
      searchDepth: 6,
      moveTimeMs: 900,
      avatarAsset: 'assets/bots/doggo.png',
    ),
    medium: BotDifficultySettings(
      difficulty: BotDifficulty.medium,
      elo: 975,
      multiPv: 3,
      threads: 1,
      skillLevel: 10,
      searchDepth: 8,
      moveTimeMs: 1100,
      avatarAsset: 'assets/bots/doggo2.png',
    ),
    hard: BotDifficultySettings(
      difficulty: BotDifficulty.hard,
      elo: 1150,
      multiPv: 5,
      threads: 1,
      skillLevel: 12,
      searchDepth: 10,
      moveTimeMs: 1400,
      avatarAsset: 'assets/bots/doggo3.png',
      moveSelectionPolicy: _rexHardSelectionPolicy,
    ),
  ),
  BotCharacter(
    rank: 4,
    id: 'octavian-inkveil',
    name: 'Octavian Inkveil',
    description:
        'Oh, please. Your opening is so unrefined. Witness true brilliance.',
    profile: BotSkillProfile.grandpa,
    easy: BotDifficultySettings(
      difficulty: BotDifficulty.easy,
      elo: 1150,
      multiPv: 5,
      threads: 2,
      skillLevel: 12,
      searchDepth: 10,
      moveTimeMs: 1000,
      avatarAsset: 'assets/bots/goodlooking.png',
      moveSelectionPolicy: _octavianEasySelectionPolicy,
    ),
    medium: BotDifficultySettings(
      difficulty: BotDifficulty.medium,
      elo: 1325,
      multiPv: 4,
      threads: 2,
      skillLevel: 14,
      searchDepth: 12,
      moveTimeMs: 1300,
      avatarAsset: 'assets/bots/goodlooking2.png',
      moveSelectionPolicy: _octavianMediumSelectionPolicy,
    ),
    hard: BotDifficultySettings(
      difficulty: BotDifficulty.hard,
      elo: 1500,
      multiPv: 4,
      threads: 2,
      skillLevel: 16,
      searchDepth: 14,
      moveTimeMs: 1600,
      avatarAsset: 'assets/bots/goodlooking3.png',
      moveSelectionPolicy: _octavianHardSelectionPolicy,
    ),
  ),
  BotCharacter(
    rank: 5,
    id: 'master-prime',
    name: 'Master Prime',
    description: 'The engine predicted your defeat ten moves ago.',
    profile: BotSkillProfile.interGm,
    easy: BotDifficultySettings(
      difficulty: BotDifficulty.easy,
      elo: 1350,
      multiPv: 4,
      threads: 2,
      skillLevel: 15,
      searchDepth: 13,
      moveTimeMs: 1500,
      avatarAsset: 'assets/bots/chudmaster.png',
      moveSelectionPolicy: _masterPrimeEasySelectionPolicy,
    ),
    medium: BotDifficultySettings(
      difficulty: BotDifficulty.medium,
      elo: 1550,
      multiPv: 4,
      threads: 2,
      skillLevel: 17,
      searchDepth: 16,
      moveTimeMs: 1900,
      avatarAsset: 'assets/bots/chudmaster2.png',
      moveSelectionPolicy: _masterPrimeMediumSelectionPolicy,
    ),
    hard: BotDifficultySettings(
      difficulty: BotDifficulty.hard,
      elo: 1750,
      multiPv: 3,
      threads: 2,
      skillLevel: 19,
      searchDepth: 18,
      moveTimeMs: 2300,
      avatarAsset: 'assets/bots/chudmaster3.png',
      moveSelectionPolicy: _masterPrimeHardSelectionPolicy,
    ),
  ),
];
