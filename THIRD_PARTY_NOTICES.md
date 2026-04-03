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
- Source markers inside data: values such as `eco_tsv` and `scid` in each entry's `src` field.

Important: keep upstream attribution and license terms for whichever ECO dataset export you used to create these files. If you publish or redistribute this app, include the exact upstream URL(s) and license text(s) for those ECO data sources.

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
