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

## Build Test IPA via GitHub (No Apple Login in CI)

1. Go to GitHub **Actions** → **Build iOS IPA (No Sign)**
2. Click **Run workflow**
3. Wait for completion, then download artifact **ChessIQ-ipa-no-sign**
4. Open Sideloadly and select `ChessIQ.ipa`
5. Sign with your Apple ID locally in Sideloadly and install to your iPhone

Notes:
- This IPA is unsigned by GitHub on purpose; Sideloadly handles local signing.
- Rebuild whenever you change app code or Stockfish integration.
- The workflow now compiles and links `libstockfish_ios.a` automatically.
