# ChessIQ

ChessIQ is an open-source chess training and analysis application built with Flutter. The project combines engine-backed analysis, structured puzzle progression, quiz-style study, and guided play modes into a single cross-platform codebase.

The repository is intended to be a serious product workspace, not a demo app. It includes the application source, training content, platform runners, backend functions, release notes, legal notices, and operational documentation used to ship the app.

## What ChessIQ Includes

- Engine-assisted chess analysis workflows
- Puzzle Academy progression and level-based training
- Opening study and quiz-oriented learning flows
- Versus-bot play modes and supporting models
- In-app store and economy systems
- Firebase-backed services and release workflows
- Flutter targets for Android, iOS, web, Windows, macOS, and Linux

## Technology Stack

- Flutter and Dart for the application layer
- Native platform runners for desktop and mobile packaging
- Firebase for backend and application services
- TypeScript-based Cloud Functions in `functions/`
- Feature-first project structure under `lib/`

## Repository Layout

Key areas of the project:

- `lib/` - Flutter application source
- `assets/` - bundled application assets, puzzles, sounds, and images
- `openings/` - ECO and opening-study data
- `functions/` - Firebase Cloud Functions source
- `test/` - automated test suite
- `android/`, `ios/`, `windows/`, `macos/`, `linux/`, `web/` - platform targets
- `tool/` - internal scripts and release helpers

For a more detailed map of the current application structure, see `ARCHITECTURE.md`.

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Git
- Platform-specific toolchains for the targets you intend to build

Desktop Windows development also requires Visual Studio with C++ desktop tooling installed.

### Local Setup

1. Clone the repository.
2. Install dependencies:

	```bash
	flutter pub get
	```

3. Validate the project:

	```bash
	flutter analyze
	```

4. Run the app on a supported target, for example:

	```bash
	flutter run -d windows
	```

### Backend Notes

The repository also contains Firebase-related configuration and Cloud Functions source. If you are working on backend features or deployments, review the release and deployment documentation listed below before making environment changes.

## Development Notes

- The codebase follows a feature-first structure.
- Internal library imports are standardized on `package:chessiq/...`.
- Large product and release workflows are documented in dedicated markdown files rather than being embedded into the README.

## Contributing

ChessIQ is developed in the open, and thoughtful contributions are welcome. Useful contributions include bug fixes, engine and training improvements, UI refinements, documentation updates, and better workflows for testing or release management.

If you plan to make a substantial change, start by reviewing the architecture and release notes so the change fits the current project structure and operational constraints.

## Documentation And Operations

- Architecture overview: `ARCHITECTURE.md`
- Android release setup: `ANDROID_ONE_CLICK_RELEASE_SETUP.md`
- Google Play release flow: `GOOGLE_PLAY_RELEASE.md`
- iOS release setup: `IOS_ONE_CLICK_RELEASE_SETUP.md`
- Apple signing assets: `APPLE_SIGNING_ASSETS_GUIDE.md`
- App Store release flow: `APPLE_APP_STORE_RELEASE.md`
- Deployment notes: `DEPLOYMENT_SUMMARY.md`
- Corresponding source note: `CORRESPONDING_SOURCE.md`

## License And Attribution

- Project license terms: `LICENSE`
- Project record: `COPYRIGHT.md`
- Third-party notices: `THIRD_PARTY_NOTICES.md`
- Privacy policy and leaderboard notice: `PRIVACY.md`
- ECO dataset MIT text: `licenses/eco.json-MIT.txt`
- In-app attribution: Settings -> Credits & Attribution
