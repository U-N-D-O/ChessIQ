# Google Play Release Path

This document describes the signed Android release path for ChessIQ.

## Current State

The GitHub workflow in `.github/workflows/build_android_aab.yml` is now the
canonical signed Android release workflow for ChessIQ. It builds Stockfish,
runs the release guard, signs the Android App Bundle, and exports a release
artifact from a tagged commit.

## Production Goal

For Google Play submission, each release should come from:

- a tagged commit in the public ChessIQ repository
- the pinned Stockfish source used by that tagged commit
- a signed Android App Bundle for `com.qila.chessiq`
- matching in-app legal/privacy notices and Play Console disclosures
- a public privacy notice URL based on `PRIVACY.md`:
  `https://modus.qila.gl/ChessIQ/privacy-notice/`

## Prerequisites

Before submitting to Google Play, make sure you have:

- a Google Play Console app record for `com.qila.chessiq`
- an Android upload keystore already registered for Play App Signing
- GitHub repository secrets containing the upload keystore and passwords
- a published privacy notice URL matching `PRIVACY.md`
- a public source tag and release notes for the shipped build

## GitHub Signed AAB Workflow

Use GitHub **Actions** -> **Build Android Signed AAB**.

If you do not know the Android/GitHub secret names yet, start with:

- `tool/setup_android_release_secrets.ps1` for one-time setup
- `tool/start_android_play_release.ps1` for each release
- `ANDROID_ONE_CLICK_RELEASE_SETUP.md` for the plain-language walkthrough

Required workflow inputs:

- `release_tag`: the exact git tag to ship
- `build_name`: optional version name override
- `build_number`: optional build number override

Required GitHub secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Workflow output:

- Artifact `ChessIQ-android-signed-aab`
- Signed bundle `build/app/outputs/bundle/release/app-release.aab`

## Recommended Signed Release Path

The simplest production path is the signed GitHub workflow above.

1. Bump the app version and build number for the release.
2. Create a git tag for the exact release commit.
3. Easiest path: run `powershell -ExecutionPolicy Bypass -File tool/start_android_play_release.ps1`.
4. Verify the Stockfish source and workflow inputs are pinned for that tag.
5. Verify the privacy text in the Academy profile dialog, credits, and
   `PRIVACY.md` all match.
6. Wait for GitHub to produce the signed AAB artifact.
7. Download `ChessIQ-android-signed-aab` and upload `app-release.aab` manually
   in Google Play Console.

If you later want direct Play upload from GitHub, add a Play service account in
another step. That is intentionally not part of the current workflow.

## Release Checklist

Before submission, confirm:

- `THIRD_PARTY_NOTICES.md`, `COPYRIGHT.md`, `LICENSE`, and `PRIVACY.md` are up
  to date
- in-app credits expose the same legal/privacy story as the repository
- the public repo tag for the release is available
- the **Build Android Signed AAB** workflow or `tool/release_guard.py --expected-tag <tag>` passes
- the privacy policy URL in Google Play Console points to the published policy
- the signed bundle was produced from the tagged commit

## Secrets Notes

- `ANDROID_KEYSTORE_BASE64` should be a base64-encoded Android upload keystore.
- `ANDROID_KEYSTORE_PASSWORD` should unlock the keystore file.
- `ANDROID_KEY_ALIAS` should match the upload key alias inside the keystore.
- `ANDROID_KEY_PASSWORD` should unlock that upload key alias.