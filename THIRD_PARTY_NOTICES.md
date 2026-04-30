# Third-Party Notices

This project incorporates, references, or relies on third-party software, data, and services. The notices below are provided for attribution and licensing transparency.



## 1. Chess Engine

This project integrates the Stockfish chess engine for local analysis and native gameplay workflows.

- Component: Stockfish chess engine
- Website: https://stockfishchess.org/
- Source code: https://github.com/official-stockfish/Stockfish
- License: GNU General Public License v3.0 (GPLv3)
- Project integration: Current native mobile build workflows package Stockfish for local analysis, including platform-specific binaries and the iOS static library path used by the app.

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

## 5. Font Asset Attribution

This project bundles third-party pixel font assets used by the Opening Academy retro interface.

- Asset: `assets/fonts/PixelatedEleganceRegular.ttf`
- Font name: `Pixelated Elegance`
- Source page: https://ggbot.itch.io/pixelated-elegance-font
- Publisher website: https://www.ggbot.net
- License note supplied with the downloaded font package: Creative Commons Zero v1.0 Universal (CC0 1.0), Public Domain

- Asset: `assets/fonts/Cairopixel-Regular.ttf`
- Font name: `Cairopixel`
- Source page: https://www.fontspace.com/cairopixel-font-f155783
- License note supplied with the downloaded font package: SIL Open Font License (OFL)

- Asset: `assets/fonts/PressStart2P-Regular.ttf`
- Font name: `Press Start 2P`
- Source page: https://www.fontspace.com/press-start-2p-font-f11591
- License note supplied with the downloaded font package: SIL Open Font License (OFL)

## 6. Audio Asset Attribution

The following assets are used under royalty-free or free-use licenses:

- move1-8.wav, take1.wav: simone_ds (Freesound)
- coin.mp3: VSokorelos (Freesound)
- coinbag.mp3, coinbag2.mp3, academybuy.mp3: Floraphonic (floraphonic.com)
- kaching.wav: Modestas123123 (Pixabay)
- vs.mp3: Universfield (Freesound)

Proprietary Assets (All Rights Reserved):
- intro.mp3, main.mp3
