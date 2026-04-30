# iOS Stockfish Setup (In-Process Native Integration)

The iOS engine now runs in-process (native static library) rather than spawning
an external executable.

## Build and Test

```bash
flutter build ios --release
```

Or run on a connected device:

```bash
flutter run --release
```

The engine will start automatically when the analysis board is opened on iPhone.

---

## How It Works

```
Flutter (Dart)
   ↓ MethodChannel("com.chessiq/stockfish")
Swift StockfishPlugin
   ↓ StockfishBridge.mm
Stockfish static library (in app process)
   ↕ stdin/stdout bridge (native pipes)
Swift StockfishPlugin
   ↓ EventChannel("com.chessiq/stockfish_output")
Flutter (Dart) → _parseOutput()
```

The UCI protocol is identical to the desktop version — all analysis logic in `main.dart` works unchanged.

---

## Build Signed IPA via GitHub

1. Add the required Apple signing secrets described in
    [APPLE_APP_STORE_RELEASE.md](../APPLE_APP_STORE_RELEASE.md)
2. Go to GitHub **Actions** → **Build iOS Signed IPA**
3. Run it with the exact release tag you want to ship
4. Wait for completion, then download artifact **ChessIQ-ios-signed-ipa**
5. Upload `ChessIQ-signed.ipa` to App Store Connect

Notes:
- The workflow compiles and links `libstockfish_ios.a` automatically.
- The workflow signs the archive with the Apple Distribution certificate and
   provisioning profile you supply through GitHub secrets.
- The build is pinned to the tagged repo commit plus the pinned Stockfish
   revision recorded in the release guard and corresponding-source files.

---

## Source Pinning

- The mobile Stockfish workflows are pinned to the Stockfish 18 tag `sf_18`
   at commit `cb3d4ee9b47d0c5aae855b12379378ea1439675c`.
- The iOS static-library workflow now prepares the renamed
   `stockfish_main` entrypoint through the committed helper script
   `tool/prepare_stockfish_ios_entrypoint.sh` instead of hiding the rewrite in
   an inline one-liner.

---

## App Store Release (Signed)

Use the signed GitHub workflow and release process described in
[APPLE_APP_STORE_RELEASE.md](../APPLE_APP_STORE_RELEASE.md).
