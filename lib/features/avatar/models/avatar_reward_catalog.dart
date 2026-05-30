import 'package:chessiq/features/vs_bot/models/vs_bot_models.dart';

class AvatarRewardCatalog {
  const AvatarRewardCatalog._();

  static const int progressionAvatarCount = 37;

  static const Map<String, List<String>> _vsBotTierRewards =
      <String, List<String>>{
        'mochi-gearheart:easy': <String>[
          'rare-engineer-fizzle',
          'rare-alchemist-gideon',
        ],
        'mochi-gearheart:medium': <String>[
          'rare-chronomancer-eldritch',
          'rare-agent-nova',
        ],
        'mochi-gearheart:hard': <String>[
          'rare-navigator-lyra',
          'legendary-engineer-fizzle',
          'legendary-agent-nova',
        ],
        'checkmate-carl:easy': <String>[
          'rare-commander-thorne',
          'rare-general-valerius',
        ],
        'checkmate-carl:medium': <String>[
          'rare-scout-jax',
          'rare-sentinel-aria',
        ],
        'checkmate-carl:hard': <String>[
          'rare-warlord-kaelen',
          'legendary-commander-thorne',
          'legendary-general-valerius',
        ],
        'rex-halfcheck:easy': <String>[
          'rare-beast-tamer-luna',
          'rare-chieftain-kor',
        ],
        'rex-halfcheck:medium': <String>[
          'rare-war-chief-rok',
          'rare-shaman-orok',
        ],
        'rex-halfcheck:hard': <String>[
          'rare-warlord-kael',
          'legendary-war-chief-rok',
          'legendary-scout-jax',
        ],
        'octavian-inkveil:easy': <String>[
          'rare-mage-elara',
          'rare-revelator-isolde',
        ],
        'octavian-inkveil:medium': <String>[
          'rare-revelator-isolde-2',
          'rare-spymaster-val',
        ],
        'octavian-inkveil:hard': <String>[
          'rare-oracle-sirene',
          'legendary-mage-elara',
          'legendary-high-priestess-kaela',
        ],
        'master-prime:easy': <String>[
          'rare-strategist-grok',
          'rare-tactician-mara',
        ],
        'master-prime:medium': <String>[
          'rare-high-priestess-kaela',
          'rare-warlord-kael-2',
        ],
        'master-prime:hard': <String>[
          'rare-siege-engineer-thorin',
          'legendary-strategist-grok',
          'legendary-tactician-mara',
          'legendary-sentinel-aria',
          'legendary-warlord-kaelen',
        ],
      };

  static Iterable<String> get allVsBotRewardIds => _vsBotTierRewards.values
      .expand((ids) => ids)
      .toSet();

  static List<String> rewardIdsForVsBotTier(
    String botId,
    BotDifficulty difficulty,
  ) {
    return List<String>.unmodifiable(
      _vsBotTierRewards[_rewardKey(botId, difficulty)] ?? const <String>[],
    );
  }

  static String rewardKeyForVsBotTier(String botId, BotDifficulty difficulty) {
    return 'vs_bot_avatar_reward:${_rewardKey(botId, difficulty)}';
  }

  static String _rewardKey(String botId, BotDifficulty difficulty) {
    return '$botId:${difficulty.storageKey}';
  }
}