# iOS Stockfish Setup

Follow these steps after the GitHub Actions workflow has compiled the binary.

## Step 1 — Trigger the Build Workflow

1. Go to your GitHub repo → **Actions** → **Build Stockfish for iOS**
2. Click **Run workflow** → **Run workflow** (green button)
3. Wait ~5–7 minutes for the job to complete

## Step 2 — Download the Device Binary

1. Open the finished workflow run
2. Under **Artifacts**, download **stockfish-ios-device**
3. Unzip it — you get a file simply named `stockfish` (no extension)

## Step 3 — Add the Binary to Xcode

1. Rename the file to `stockfish` if it isn't already
2. Open `ios/Runner.xcworkspace` in Xcode
3. Drag `stockfish` into the **Runner** group in the Project Navigator
4. In the dialog that appears:
   - ✅ **Copy items if needed**
   - ✅ **Add to targets: Runner**
   - Click **Finish**
5. Select the `stockfish` file in the Project Navigator
6. Open the **File Inspector** (right panel)
7. Under **Target Membership**, confirm **Runner** is checked
8. Go to **Build Phases** → **Copy Bundle Resources** and confirm `stockfish` is listed there
   - If it appears under **Compile Sources** instead, remove it from there and add it to **Copy Bundle Resources**

## Step 4 — Make the Binary Executable

The binary must have execute permission. In a terminal:

```bash
chmod +x ios/Runner/stockfish
```

Or via Xcode: this is handled automatically when the binary is properly code-signed during build.

## Step 5 — Build and Test

```bash
flutter build ios --release
```

Or run on a connected device:

```bash
flutter run --release
```

The engine will start automatically when the analysis board is opened on iPhone.

---

## Simulator Setup (Optional)

For running in the iOS Simulator on Apple Silicon:

1. Download the **stockfish-ios-simulator** artifact instead
2. Rename it to `stockfish`
3. Swap it into `ios/Runner/stockfish` when testing in the simulator

If you need to support both device and simulator simultaneously, create a Universal Binary (xcframework) — ask your AI assistant to help with that step when ready.

---

## How It Works

```
Flutter (Dart)
   ↓ MethodChannel("com.chessiq/stockfish")
Swift StockfishPlugin
   ↓ posix_spawn
Stockfish process (bundled binary)
   ↕ stdin/stdout via pipe
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
