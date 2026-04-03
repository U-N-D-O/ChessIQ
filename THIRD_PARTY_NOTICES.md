# Third-Party Notices

This project includes or depends on third-party software, data, and services.

## 1) Chess Engine

- Component: Stockfish chess engine
- Website: https://stockfishchess.org/
- Source: https://github.com/official-stockfish/Stockfish
- License: GNU General Public License v3.0 (GPL-3.0)
- Usage in this project: optional local engine binary expected at `engine/stockfish.exe` for native analysis.

Note: this repository does not currently distribute `engine/stockfish.exe`.

## 2) Opening Database Files

- Files: `openings/ecoA.json`, `openings/ecoB.json`, `openings/ecoC.json`, `openings/ecoD.json`, `openings/ecoE.json`
- Purpose: Encyclopaedia of Chess Openings (ECO) move/name lookup.
- Upstream repository used for these files:
  - https://github.com/hayatbiralem/eco.json (archived)
  - file examples: `ecoA.json` through `ecoE.json`
- License: MIT
- License text source: https://raw.githubusercontent.com/hayatbiralem/eco.json/master/LICENSE
- Local copy of license text: `licenses/eco.json-MIT.txt`

Upstream project notes indicate active development moved to:

- https://github.com/JeffML/eco.json

Acknowledgements from upstream README include:

- Ömur Yanıkoğlu (original eco.json compilation)
- Shane Hudson (original SCID opening data credit)
- niklasf/eco project acknowledgements

Data provenance note:

- These ECO files are a collation that may include source markers such as `eco_tsv`, `scid`, `eco_wikip`, `ct`, `chessGraph`, `icsbot`, and others inside entries.

## 3) Flutter, Dart, and Pub Packages

- Flutter SDK (includes Material/Cupertino frameworks)
  - Website: https://flutter.dev/
  - License: BSD-style license (see Flutter repository)
- Dart SDK
  - Website: https://dart.dev/
  - License: BSD-style license

Direct pub dependencies used by this app:

- `cupertino_icons` - https://pub.dev/packages/cupertino_icons
- `shared_preferences` - https://pub.dev/packages/shared_preferences
- `google_fonts` - https://pub.dev/packages/google_fonts
- `audioplayers` - https://pub.dev/packages/audioplayers

Each package remains under its own license. See pub.dev package pages and bundled license metadata for details.
