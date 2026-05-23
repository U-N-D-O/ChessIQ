# One-Click Android Release Setup

This file explains the Android/Google Play release setup in plain language.

## What These Things Mean

- `ANDROID_KEYSTORE_BASE64`
  This is your Android upload keystore turned into text so GitHub can store it
  securely. The original file is usually a `.jks` or `.keystore` file.

- `ANDROID_KEYSTORE_PASSWORD`
  This is the password for the keystore file itself.

- `ANDROID_KEY_ALIAS`
  This is the alias name of the upload key inside the keystore.

- `ANDROID_KEY_PASSWORD`
  This is the password for the upload key alias.

- `release tag`
  This is just a permanent git name for the exact commit you are shipping,
  for example `android-v1.0.0+42`.

## Where These Values Go

They do **not** go into your code files.

They go into **GitHub repository secrets** for this repo:

- `U-N-D-O/ChessIQ`

The setup script below uploads them for you.

## One-Time Setup

You do this one time, then releases become much smoother.

1. Install GitHub CLI from https://cli.github.com/
2. Open PowerShell in the repo folder.
3. Run `gh auth login` and sign into GitHub.
4. Make sure you have these Android signing values ready:
   - your Android upload keystore file (`.jks` or `.keystore`)
   - the keystore password
   - the key alias
   - the key password
5. Run:

```powershell
powershell -ExecutionPolicy Bypass -File tool/setup_android_release_secrets.ps1
```

The script will ask for each item in plain prompts and upload the secrets to
GitHub for you.

## Every Release After Setup

When you want to generate a signed Google Play bundle:

```powershell
powershell -ExecutionPolicy Bypass -File tool/start_android_play_release.ps1
```

That script will:

1. ask for the release tag
2. optionally ask for build name and build number overrides
3. create the tag if needed
4. push the tag
5. start the GitHub workflow for the signed Android App Bundle

## Local Android Stockfish Prep

For emulator or device testing that needs the native Android Stockfish assets,
run this from the repo root after the Android SDK/NDK and Git for Windows are
installed:

```powershell
powershell -ExecutionPolicy Bypass -File tool/build_stockfish_android.ps1
```

That script clones the pinned Stockfish release from `release_guard.json` and
copies the Android binaries for `arm64-v8a`, `armeabi-v7a`, and `x86_64` into
`android/app/src/main/assets` for local Flutter builds.

## What Still Comes From Google Play

GitHub cannot invent your Android upload key. The following still have to come
from your existing Play Console/App Signing setup once:

- your upload keystore file
- the keystore password
- the key alias
- the key password

The scripts do the conversion, storage, tagging, and workflow triggering so you
do not have to manually base64-encode files or type secret names into GitHub.

## Recommended Goal State

After one-time setup, your normal Android release flow should be:

1. `powershell -ExecutionPolicy Bypass -File tool/start_android_play_release.ps1`
2. wait for GitHub to build/sign the AAB
3. download the artifact and upload it in Google Play Console

Direct Play Console upload is not automated yet. This workflow is currently for
producing the signed `.aab` artifact cleanly from a tagged commit.