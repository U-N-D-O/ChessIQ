# Third-Party Notices

This project incorporates, references, or relies on third-party software, data, and services. The notices below are provided for attribution and licensing transparency.



## 1. Chess Engine

This project is designed to support the Stockfish chess engine for local analysis.

- Component: Stockfish chess engine
- Website: https://stockfishchess.org/
- Source code: https://github.com/official-stockfish/Stockfish
- License: GNU General Public License v3.0 (GPL-3.0)
- Project integration: Optional local Stockfish mechanism may be used for native analysis workflows (for example, platform-specific integrations/build artifacts).

This repository does not distribute the Stockfish mechanism/binaries.

## 2. Opening Database Files

This project includes ECO opening data files for move and opening-name lookup.

- Included files: `openings/ecoA.json`, `openings/ecoB.json`, `openings/ecoC.json`, `openings/ecoD.json`, `openings/ecoE.json`
- Historical upstream repository: https://github.com/hayatbiralem/eco.json (archived)
- Current upstream continuation noted by maintainers: https://github.com/JeffML/eco.json
- License: MIT
- Upstream license text URL: https://raw.githubusercontent.com/hayatbiralem/eco.json/master/LICENSE
- Local license copy: `licenses/eco.json-MIT.txt`

Acknowledgements referenced in upstream project materials include Ömur Yanıkoğlu (original eco.json compilation), Shane Hudson (SCID opening data credit), and contributors acknowledged by the `niklasf/eco` project.

These ECO files are collated datasets and may contain source markers within entries, including `eco_tsv`, `scid`, `eco_wikip`, `ct`, `chessGraph`, and `icsbot`.

## 3. Puzzle Data

This project sources chess puzzle data from the public Lichess puzzle database for Academy and related puzzle workflows.

- Source: Lichess puzzle database
- Website: https://database.lichess.org/#puzzles
- Provider: Lichess.org
- License: Creative Commons CC0 1.0 Universal
- License URL: https://creativecommons.org/publicdomain/zero/1.0/
- Usage note: Puzzle records may be transformed, filtered, or reorganized for in-app Academy progression, daily challenge selection, and exam flows.

## 4. Flutter, Dart, and Pub Packages

This application is built with the Flutter and Dart ecosystems and depends on third-party packages from pub.dev.

- Flutter SDK (including Material and Cupertino frameworks)
  - Website: https://flutter.dev/
  - License: BSD-style license (see the Flutter repository for full terms)
- Dart SDK
  - Website: https://dart.dev/
  - License: BSD-style license

Direct pub dependencies used by this app include:

- `cupertino_icons`: https://pub.dev/packages/cupertino_icons
- `shared_preferences`: https://pub.dev/packages/shared_preferences
- `google_fonts`: https://pub.dev/packages/google_fonts
- `audioplayers`: https://pub.dev/packages/audioplayers
- `flutter_svg`: https://pub.dev/packages/flutter_svg

Each third-party package remains licensed under its own terms. For complete and current licensing details, refer to each package page on pub.dev and bundled license metadata where applicable.

## 5. Audio Asset Attribution

This project includes third-party audio assets used chess sound effects, coin sound effects and rewards feedback.

- Assets: `assets/sounds/move1.mp3` – `move8.mp3`, `assets/sounds/take1.mp3`
- Title: `Chess-pieces, Owi, Boardgames`
- Creator: simone_ds
- Source platform: Freesound
- Description / usage note: Chess pieces sound effects. Free for use.

- Asset: `assets/sounds/coin.mp3`
- Title: `Coin Drop`
- Creator: VSokorelos
- Source platform: Freesound
- Description / usage note: Iekdelta, Drop, Coin sound effect. Free for use.

- Asset: `assets/sounds/coinbag.mp3`
- Title: `Coin and Money Bag 3`
- Creator: Floraphonic
- License / usage note: Free for use. Royalty Free Audio
- Source website: https://www.floraphonic.com/

- Asset: `assets/sounds/academybuy.mp3`
- Title: `Wood Surface Single Coin Payout 4`
- Creator: floraphonic
- Description / usage note: Coin, Toss, Flip sound effect. Free for use.
