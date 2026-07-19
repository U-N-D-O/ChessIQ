enum AvatarRarityBucket { normal, rare, epic, legendary, promo }

extension AvatarRarityBucketX on AvatarRarityBucket {
  String get folderName {
    switch (this) {
      case AvatarRarityBucket.normal:
        return '4';
      case AvatarRarityBucket.rare:
        return '1';
      case AvatarRarityBucket.epic:
        return 'oo';
      case AvatarRarityBucket.legendary:
        return 'e 12';
      case AvatarRarityBucket.promo:
        return 'a';
    }
  }

  String get label {
    switch (this) {
      case AvatarRarityBucket.normal:
        return 'Normal';
      case AvatarRarityBucket.rare:
        return 'Rare';
      case AvatarRarityBucket.epic:
        return 'Epic';
      case AvatarRarityBucket.legendary:
        return 'Legendary';
      case AvatarRarityBucket.promo:
        return 'Promo';
    }
  }

  double get paidRollWeight {
    switch (this) {
      case AvatarRarityBucket.normal:
        return 76.5;
      case AvatarRarityBucket.rare:
        return 20.0;
      case AvatarRarityBucket.epic:
        return 2.5;
      case AvatarRarityBucket.legendary:
        return 1.0;
      case AvatarRarityBucket.promo:
        return 0.0;
    }
  }

  bool get starterEligible => this == AvatarRarityBucket.normal;

  bool get paidRollEligible => this != AvatarRarityBucket.promo;
}

class AvatarCatalogEntry {
  const AvatarCatalogEntry({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.bucket,
  });

  final String id;
  final String name;
  final String assetPath;
  final AvatarRarityBucket bucket;

  bool get starterEligible => bucket.starterEligible;

  bool get paidRollEligible => bucket.paidRollEligible;

  bool get promoOnly => bucket == AvatarRarityBucket.promo;
}

class AvatarCatalog {
  const AvatarCatalog._();

  static final List<AvatarCatalogEntry> items = <AvatarCatalogEntry>[
    ..._entriesFor(AvatarRarityBucket.normal, _normalFileNames),
    ..._entriesFor(AvatarRarityBucket.rare, _rareFileNames),
    ..._entriesFor(AvatarRarityBucket.epic, _epicFileNames),
    ..._entriesFor(AvatarRarityBucket.legendary, _legendaryFileNames),
    ..._entriesFor(AvatarRarityBucket.promo, _promoFileNames),
  ];

  static final Map<String, AvatarCatalogEntry> byId =
      <String, AvatarCatalogEntry>{for (final item in items) item.id: item};

  static final Map<String, AvatarCatalogEntry> _byNormalizedName =
      <String, AvatarCatalogEntry>{
        for (final item in items) _normalizeAvatarKey(item.name): item,
        for (final item in items) _normalizeAvatarKey(item.id): item,
      };

  static final Set<String> ids = byId.keys.toSet();

  static final Map<AvatarRarityBucket, List<AvatarCatalogEntry>>
  _itemsByBucket = <AvatarRarityBucket, List<AvatarCatalogEntry>>{
    for (final bucket in AvatarRarityBucket.values)
      bucket: items
          .where((item) => item.bucket == bucket)
          .toList(growable: false),
  };

  static final List<AvatarCatalogEntry> starterPool = items
      .where((item) => item.starterEligible)
      .toList(growable: false);

  static final List<AvatarCatalogEntry> promoPool = items
      .where((item) => item.promoOnly)
      .toList(growable: false);

  static AvatarCatalogEntry? entryFor(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    final trimmed = id.trim();
    final direct = byId[trimmed];
    if (direct != null) {
      return direct;
    }
    return _byNormalizedName[_normalizeAvatarKey(trimmed)];
  }

  static List<AvatarCatalogEntry> entriesForBucket(AvatarRarityBucket bucket) {
    return _itemsByBucket[bucket] ?? const <AvatarCatalogEntry>[];
  }

  static List<AvatarCatalogEntry> ownedEntriesFor(Iterable<String> ownedIds) {
    final ownedSet = ownedIds.toSet();
    return items
        .where((item) => ownedSet.contains(item.id))
        .toList(growable: false);
  }
}

List<AvatarCatalogEntry> _entriesFor(
  AvatarRarityBucket bucket,
  List<String> fileNames,
) {
  return fileNames
      .map((fileName) => _entry(bucket: bucket, fileName: fileName))
      .toList(growable: false);
}

AvatarCatalogEntry _entry({
  required AvatarRarityBucket bucket,
  required String fileName,
}) {
  final name = _displayNameFromFileName(fileName);
  return AvatarCatalogEntry(
    id: '${bucket.name}-${_slugify(name)}',
    name: name,
    assetPath: 'assets/avatars/${bucket.folderName}/$fileName',
    bucket: bucket,
  );
}

String _displayNameFromFileName(String fileName) {
  final withoutExtension = fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
  final withSpaces = withoutExtension.replaceAll('_', ' ');

  final buffer = StringBuffer();
  for (var i = 0; i < withSpaces.length; i++) {
    final char = withSpaces[i];
    if (i > 0 && _isUpperCase(char)) {
      final previous = withSpaces[i - 1];
      if (previous != ' ' && previous != '-' && previous != '_') {
        buffer.write(' ');
      }
    }
    buffer.write(char);
  }

  return buffer.toString().replaceAll('_', ' ').trim();
}

bool _isUpperCase(String char) {
  return char.toUpperCase() == char && char.toLowerCase() != char;
}

String _slugify(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
}

String _normalizeAvatarKey(String value) {
  final withoutExtension = value.replaceFirst(RegExp(r'\.[^.]+$'), '');
  final normalized = withoutExtension.trim().toLowerCase();
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

const List<String> _normalFileNames = <String>[
  'CelicianMara.png',
  'GeneralValerius.png',
  'GeneralValerius_2.png',
  'GeneralValerius_3.png',
  'GoldonPauus.png',
  'GraeMaha.png',
  'PilmanBanin.png',
  'PoweraAltaita.png',
  'RevelatorIsolde.png',
  'RevelatorIsolde_2.png',
  'SacreianBride.png',
  'SacrolanGride.png',
  'TacticianMara.png',
  'TacticianMara_2.png',
  'TacticianMara_3.png',
  'TacticianRaya.png',
  'TurnianHelly.png',
  'VarliordKael.png',
  'WanianBalm.png',
  'WanianBalon.png',
  'WarlordKael.png',
  'WarlordKael_2.png',
  'WarlordKael_3.png',
  'WorldJass.png',
];

const List<String> _rareFileNames = <String>[
  'AgentNova.png',
  'AlchemistGideon.png',
  'BeastTamerLuna.png',
  'ChieftainKor.png',
  'ChronomancerEldritch.png',
  'CommanderThorne.png',
  'EngineerFizzle.png',
  'GeneralValerius.png',
  'HighPriestessKaela.png',
  'MageElara.png',
  'NavigatorLyra.png',
  'OracleSirene.png',
  'RevelatorIsolde.png',
  'RevelatorIsolde_2.png',
  'ScoutJax.png',
  'SentinelAria.png',
  'ShamanOrok.png',
  'SiegeEngineerThorin.png',
  'SpymasterVal.png',
  'StrategistGrok.png',
  'TacticianMara.png',
  'WarChiefRok.png',
  'WarlordKael.png',
  'WarlordKaelen.png',
  'WarlordKael_2.png',
];

const List<String> _epicFileNames = <String>[
  'Algo-StrategistBen.png',
  'ChessGrandmasterElias.png',
  'ColdWarStrategistLeon.png',
  'CyberCommanderRen.png',
  'GeneralAl.png',
  'HighScoreDave.png',
  'MarketSageKate.png',
  'ModelerPete.png',
  'PrivateSecuritySarah.png',
  'RootCommanderMax.png',
  'TheProKai.png',
  'UrbanPlannerChloe.png',
];

const List<String> _legendaryFileNames = <String>[
  'AgentNova.png',
  'CommanderThorne.png',
  'EngineerFizzle.png',
  'GeneralValerius.png',
  'HighPriestessKaela.png',
  'MageElara.png',
  'ScoutJax.png',
  'SentinelAria.png',
  'StrategistGrok.png',
  'TacticianMara.png',
  'WarChiefRok.png',
  'WarlordKaelen.png',
];

const List<String> _promoFileNames = <String>['DemonHunter.png'];
