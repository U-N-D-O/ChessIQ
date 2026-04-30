# Apple App Store Release Path

This document describes the signed iOS release path for ChessIQ.

## Current State

The GitHub workflow in `.github/workflows/build_ios_ipa.yml` is now the
canonical signed iOS release workflow for ChessIQ. It builds Stockfish, runs
the release guard, archives the app, and exports a signed App Store IPA from a
tagged commit.

## Production Goal

For App Store submission, each release should come from:

- A tagged commit in the public ChessIQ repository
- The pinned Stockfish source used by that tagged commit
- A signed iOS archive built for App Store distribution
- Matching in-app legal/privacy notices and App Store Connect disclosures
- A public privacy policy and corresponding-source location

## Prerequisites

Before submitting to Apple, make sure you have:

- An active Apple Developer Program account
- An App Store Connect app record for ChessIQ
- A valid bundle identifier and signing team in Xcode
- An Apple Distribution certificate and provisioning profile, or a confirmed
  automatic-signing setup in Xcode
- A published privacy notice URL based on `PRIVACY.md`:
  `https://modus.qila.gl/ChessIQ/privacy-notice`
- A public source tag and release notes for the shipped build

## GitHub Signed IPA Workflow

Use GitHub **Actions** -> **Build iOS Signed IPA**.

If you do not know the Apple/GitHub secret names yet, start with:

- `tool/setup_ios_release_secrets.ps1` for one-time setup
- `tool/start_ios_app_store_release.ps1` for each release
- `IOS_ONE_CLICK_RELEASE_SETUP.md` for the plain-language walkthrough

Required workflow inputs:

- `release_tag`: the exact git tag to ship
- `build_name`: optional version name override
- `build_number`: optional build number override

Required GitHub secrets:

- `APPLE_TEAM_ID`
- `APPLE_DISTRIBUTION_CERTIFICATE_BASE64`
- `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD`
- `APPLE_PROVISIONING_PROFILE_BASE64`

Optional GitHub secrets for direct App Store Connect upload:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64`

Workflow output:

- Artifact `ChessIQ-ios-signed-ipa`
- Signed IPA `ChessIQ-signed.ipa`
- Matching exported options plist
- Matching `ChessIQ.xcarchive`

## Recommended Signed Release Path

The simplest production path is the signed GitHub workflow above.

1. Bump the app version and build number for the release.
2. Create a git tag for the exact release commit.
3. Easiest path: run `powershell -ExecutionPolicy Bypass -File tool/start_ios_app_store_release.ps1`.
4. Verify the Stockfish source and workflow inputs are pinned for that tag.
5. Verify the privacy text in the Academy profile dialog, credits, and
   `PRIVACY.md` all match.
6. If automatic upload is enabled, wait for GitHub to upload the signed IPA to
  App Store Connect.
7. Otherwise, download artifact `ChessIQ-ios-signed-ipa` and upload
  `ChessIQ-signed.ipa` manually using Transporter or the Organizer upload flow.
8. Complete App Store Connect metadata, privacy answers, and submission steps.

Xcode archive/upload remains the fallback path if GitHub signing secrets are
not configured.

## App Store Privacy Alignment

App Store Connect privacy answers should match the actual ChessIQ flow.

For the Academy leaderboard flow, the app may:

- Publicly display the chosen nickname and country or region, together with
  score and title
- Send nickname, country or region, score, title, updatedAt, and an anonymous
  Firebase user ID to the backend

Do not claim that only nickname and country are sent.
Do not make absolute claims that no identifiers are shared.
Use the narrower statement that network metadata such as IP address is not
shown on the public leaderboard.

## Release Checklist

Before submission, confirm:

- `PixgamerRegular` is no longer used or bundled for release
- `PixelatedEleganceRegular.ttf` is the active replacement font where planned
- `THIRD_PARTY_NOTICES.md`, `COPYRIGHT.md`, `LICENSE`, and `PRIVACY.md` are up
  to date
- In-app credits expose the same legal/privacy story as the repository
- The public repo tag for the release is available
- The **Build iOS Signed IPA** workflow or `tool/release_guard.py --expected-tag <tag>` passes
- The privacy policy URL in App Store Connect points to the published policy
- The signed archive was produced from the tagged commit

## Secrets Notes

- `APPLE_DISTRIBUTION_CERTIFICATE_BASE64` should be a base64-encoded `.p12`
  Apple Distribution certificate.
- `APPLE_PROVISIONING_PROFILE_BASE64` should be a base64-encoded App Store
  provisioning profile for `com.qila.chessiq`.
- `APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64` should be a base64-encoded `.p8`
  App Store Connect API key if you want GitHub to upload the IPA automatically.
- The workflow validates that the provisioning profile matches the configured
  Apple team ID and bundle identifier before archiving.
