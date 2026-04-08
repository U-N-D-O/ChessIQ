# ARCHITECTURE

## Purpose
This document is the source-of-truth map for the current Feature-First Flutter structure in `lib/`.

This refactor was structural only:
- Files were relocated into `core/`, `shared/`, and `features/`
- `lib/main.dart` was reduced to app bootstrap only
- Shared models, painters, and services were extracted from the old monolith
- Large Academy screens were split with Dart part files for local widget sections
- Runtime behavior and UI output were intentionally preserved
- Internal Dart imports are standardized on `package:chessiq/...` URIs

## Directory Map

```text
lib/
├── main.dart
├── core/
│   ├── app/
│   │   └── chess_iq_app.dart
│   ├── constants/
│   ├── navigation/
│   │   └── app_routes.dart
│   ├── providers/
│   ├── services/
│   │   └── engine_service.dart
│   └── theme/
│       └── app_theme_provider.dart
├── shared/
│   └── widgets/
│       └── universal_settings_sheet.dart
└── features/
    ├── academy/
    │   ├── models/
    │   │   └── puzzle_progress_model.dart
    │   ├── providers/
    │   │   └── puzzle_academy_provider.dart
    │   ├── screens/
    │   │   ├── puzzle_grid_screen.dart
    │   │   ├── puzzle_map_screen.dart
    │   │   └── puzzle_node_screen.dart
    │   ├── services/
    │   │   └── puzzle_engine_service.dart
    │   └── widgets/
    │       ├── puzzle_map_components.dart
    │       └── puzzle_node_components.dart
    ├── analysis/
    │   ├── models/
    │   │   └── analysis_models.dart
    │   ├── painters/
    │   │   └── energy_arrow_painter.dart
    │   ├── providers/
    │   └── widgets/
    │   └── screens/
    │       └── chess_analysis_page.dart
    ├── main_menu/
    │   ├── providers/
    │   ├── screens/
    │   └── widgets/
    ├── quiz/
    │   ├── models/
    │   │   └── quiz_models.dart
    │   ├── providers/
    │   ├── screens/
    │   └── widgets/
    │   └── painters/
    │       └── quiz_accuracy_trend_painter.dart
    ├── store/
    │   ├── models/
    │   │   └── store_models.dart
    │   ├── providers/
    │   ├── screens/
    │   └── widgets/
    └── vs_bot/
      ├── models/
      │   └── vs_bot_models.dart
      ├── providers/
      ├── screens/
      └── widgets/
```

## Placement Rules
- `core/`: app-wide concerns only. App bootstrap, route constants, theme provider, and universal services belong here.
- `shared/widgets/`: reusable UI that is intentionally cross-feature. Keep these dumb and configurable.
- `features/<name>/models/`: feature-owned enums, immutable data, and view models.
- `features/<name>/providers/`: feature state containers and persistence-facing notifiers.
- `features/<name>/services/`: feature-specific orchestration or IO helpers.
- `features/<name>/screens/`: entry widgets for a feature flow.
- `features/<name>/widgets/`: local widgets or part files that reduce screen size without changing behavior.
- Import standard: prefer `package:chessiq/...` imports for all internal library references.

## Routing Index

### Runtime routing
The app currently boots through `ChessIQApp` in `lib/core/app/chess_iq_app.dart` and uses `AppRoutes` constants from `lib/core/navigation/app_routes.dart`.

Current MaterialApp binding:
- `/analysis`: wired and active as the initial route

Reserved route names for future extraction:
- `/academy`
- `/vs-bot`
- `/quiz`
- `/store`
- `/main-menu`

Important note:
The current production navigation model is still shell-driven inside `ChessAnalysisPage` through `AppSection`. The route constants above are the canonical names to use when navigation is fully extracted later.

### Main screens
- `ChessIQApp` -> `lib/core/app/chess_iq_app.dart`
  - Root `MaterialApp`
  - Initial route: `/analysis`
- `ChessAnalysisPage` -> `lib/features/analysis/screens/chess_analysis_page.dart`
  - Route: `/analysis`
  - Owns the current shell that hosts analysis, vs-bot, quiz, store, academy launch, and main-menu state sections
- `PuzzleMapScreen` -> `lib/features/academy/screens/puzzle_map_screen.dart`
  - Logical route: `/academy`
  - Current navigation: pushed from the analysis shell rather than MaterialApp routes
- `PuzzleGridScreen` -> `lib/features/academy/screens/puzzle_grid_screen.dart`
  - Logical route: `/academy/grid`
  - Current navigation: academy-internal push flow
- `PuzzleNodeScreen` -> `lib/features/academy/screens/puzzle_node_screen.dart`
  - Logical route: `/academy/level`
  - Current navigation: academy-internal push flow

## Terminology Dictionary

### Level
Use `Level` as the product term for Academy progression units.
- The code still contains legacy type names like `EloNodeProgress` and some `node` variable names.
- When describing UX, docs, tickets, or AI prompts, refer to these as `Levels`.
- Translation rule: `Node` in data structures maps to `Level` in player-facing language.

### Hint vs Skip
These are not interchangeable.

`Hint`
- Inventory-backed assistance only
- Consumes `freeHints`
- Does not mark a puzzle as solved
- Does not mark a puzzle as skipped
- Leaves progression state unchanged except for hint inventory

`Skip`
- Inventory-backed bypass action
- Consumes `freeSkips`
- Marks the puzzle ID inside `skippedPuzzleIds`
- Advances the player past the current puzzle without awarding a solve
- A skipped puzzle remains unresolved until it is later completed

### Theme Logic
Theme settings are split across two different systems and should not be conflated.

`UI Theme`
- Controlled by `AppThemeProvider`
- Uses `AppThemeStyle.standard` for Neon and `AppThemeStyle.monochrome` for Mono
- Changes the app chrome, cards, accents, icons, and shared surfaces
- Also synchronizes with the legacy `cinematic_theme_enabled_v1` preference

`Neon`
- Backed by `AppThemeStyle.standard`
- Uses the full accent palette: gold, blue, and green
- This is the colorful default visual mode

`Monochrome`
- Backed by `AppThemeStyle.monochrome`
- Converts the UI to grayscale-oriented theme colors while preserving contrast and hierarchy

`Board Theme`
- Separate from UI Theme
- Chooses the board square palette through the board theme index and `AppBoardPalette`
- A board can use any board palette regardless of whether UI Theme is Neon or Mono
- Piece styling is also separate and selected by piece theme index

Practical rule:
- UI Theme changes the shell and global styling.
- Board Theme changes the chessboard colors.
- Piece Theme changes the piece art treatment.

## Monolith Split Notes
- `lib/main.dart` is now bootstrap-only.
- The former monolith lives under `lib/features/analysis/screens/chess_analysis_page.dart`.
- Shared cross-feature definitions were extracted out of that file into:
  - `lib/core/services/engine_service.dart`
  - `lib/features/analysis/models/analysis_models.dart`
  - `lib/features/vs_bot/models/vs_bot_models.dart`
  - `lib/features/store/models/store_models.dart`
  - `lib/features/quiz/models/quiz_models.dart`
  - `lib/features/analysis/painters/energy_arrow_painter.dart`
  - `lib/features/quiz/painters/quiz_accuracy_trend_painter.dart`
- Large Academy screens were split structurally with Dart part files:
  - `lib/features/academy/screens/puzzle_map_screen.dart` -> `lib/features/academy/widgets/puzzle_map_components.dart`
  - `lib/features/academy/screens/puzzle_node_screen.dart` -> `lib/features/academy/widgets/puzzle_node_components.dart`

## Guardrails For Future Work
- Do not put cross-feature concerns back into a feature screen file.
- If a helper is reused by multiple features, move it to `core/` or `shared/widgets/`.
- If a widget is only used by one feature, keep it under that feature.
- Preserve the product language rule: document Academy `Levels`, not `Nodes`.
- If route extraction continues later, adopt the existing `AppRoutes` names instead of inventing new ones.
