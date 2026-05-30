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
      <String, AvatarCatalogEntry>{
        for (final item in items) item.id: item,
      };

  static final Set<String> ids = byId.keys.toSet();

  static final Map<AvatarRarityBucket, List<AvatarCatalogEntry>> _itemsByBucket =
      <AvatarRarityBucket, List<AvatarCatalogEntry>>{
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
    return byId[id];
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
  final withoutExtension = fileName.replaceFirst(RegExp(r'\.[^.]+4'), '');
  return withoutExtension.replaceAll('_', ' ');
}

String _slugify(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return normalized.replaceAll(RegExp(r'^-+|-+4'), '');
}

const List<String> _normalFileNames = <String>[
  'Celician Mara.png',
  'General Valerius.png',
  'General Valerius_2.png',
  'General Valerius_3.png',
  'Goldon Pauus.png',
  'Grae Maha.png',
  'Pilman Banin.png',
  'Powera Altaita.png',
  'Revelator Isolde.png',
  'Revelator Isolde_2.png',
  'Sacreian Bride.png',
  'Sacrolan Gride.png',
  'Tactician Mara.png',
  'Tactician Mara_2.png',
  'Tactician Mara_3.png',
  'Tactician Raya.png',
  'Turnian Helly.png',
  'Varliord Kael.png',
  'Wanian Balm.png',
  'Wanian Balon.png',
  'Warlord Kael.png',
  'Warlord Kael_2.png',
  'Warlord Kael_3.png',
  'World Jass.png',
];

const List<String> _rareFileNames = <String>[
  'Agent Nova.png',
  'Alchemist Gideon.png',
  'Beast Tamer Luna.png',
  'Chieftain Kor.png',
  'Chronomancer Eldritch.png',
  'Commander Thorne.png',
  'Engineer Fizzle.png',
  'General Valerius.png',
  'High Priestess Kaela.png',
  'Mage Elara.png',
  'Navigator Lyra.png',
  'Oracle Sirene.png',
  'Revelator Isolde.png',
  'Revelator Isolde_2.png',
  'Scout Jax.png',
  'Sentinel Aria.png',
  'Shaman Orok.png',
  'Siege Engineer Thorin.png',
  'Spymaster Val.png',
  'Strategist Grok.png',
  'Tactician Mara.png',
  'War Chief Rok.png',
  'Warlord Kael.png',
  'Warlord Kael_2.png',
  'Warlord Kaelen.png',
];

const List<String> _epicFileNames = <String>[
  'Algo-Strategist Ben.png',
  'Chess Grandmaster Elias.png',
  'Cold War Strategist Leon.png',
  'Cyber Commander Ren.png',
  'General Al.png',
  'High Score Dave.png',
  'Market Sage Kate.png',
  'Modeler Pete.png',
  'Private Security Sarah.png',
  'Root Commander Max.png',
  'The Pro Kai.png',
  'Urban Planner Chloe.png',
];

const List<String> _legendaryFileNames = <String>[
  'Agent Nova.png',
  'Commander Thorne.png',
  'Engineer Fizzle.png',
  'General Valerius.png',
  'High Priestess Kaela.png',
  'Mage Elara.png',
  'Scout Jax.png',
  'Sentinel Aria.png',
  'Strategist Grok.png',
  'Tactician Mara.png',
  'War Chief Rok.png',
  'Warlord Kaelen.png',
];

const List<String> _promoFileNames = <String>['Demon Hunter.png'];