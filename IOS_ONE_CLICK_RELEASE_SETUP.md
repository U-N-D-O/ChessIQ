# One-Click iOS Release Setup

This file explains the iOS/App Store release setup in plain language.

## What These Things Mean

- `APPLE_TEAM_ID`
  This is Apple's ID for your developer team. It belongs to your Apple
  Developer account.

- `APPLE_DISTRIBUTION_CERTIFICATE_BASE64`
  This is your Apple Distribution signing certificate turned into text so
  GitHub can store it securely. The original file is a `.p12` file exported
  from Keychain Access on your Mac.

- `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD`
  This is the password you choose when you export the `.p12` certificate file.

- `APPLE_PROVISIONING_PROFILE_BASE64`
  This is your App Store provisioning profile turned into text so GitHub can
  store it securely. The original file is a `.mobileprovision` file downloaded
  from Apple.

- `APP_STORE_CONNECT_API_KEY_ID`
  This is the short ID of an App Store Connect API key. It lets GitHub upload
  the finished IPA directly to App Store Connect.

- `APP_STORE_CONNECT_API_ISSUER_ID`
  This is the issuer ID that goes with the App Store Connect API key.

- `APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64`
  This is the App Store Connect API private key file (`.p8`) turned into text
  so GitHub can store it securely.

- `release tag`
  This is just a permanent git name for the exact commit you are shipping,
  for example `ios-v1.0.0+42`.

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
4. Make sure you have these Apple files/values ready:
   - Apple Team ID
   - Apple Distribution certificate exported as `.p12`
   - password for that `.p12`
   - App Store provisioning profile as `.mobileprovision`
   - optional: App Store Connect API key `.p8`, key ID, issuer ID
5. Run:

```powershell
powershell -ExecutionPolicy Bypass -File tool/setup_ios_release_secrets.ps1
```

The script will ask for each item in plain prompts and upload the secrets to
GitHub for you.

## Every Release After Setup

When you want to ship a new version:

```powershell
powershell -ExecutionPolicy Bypass -File tool/start_ios_app_store_release.ps1
```

That script will:

1. ask for the release tag
2. optionally ask for build name and build number overrides
3. optionally ask whether to upload directly to App Store Connect
4. create the tag if needed
5. push the tag
6. start the GitHub workflow for the signed IPA

## What Still Comes From Apple

GitHub cannot invent Apple credentials. The following still have to come from
your Apple account once:

- your Team ID
- your signing certificate
- your provisioning profile
- optional App Store Connect API key for automatic upload

The scripts do the conversion, storage, tagging, and workflow triggering so you
do not have to manually base64-encode files or type secret names into GitHub.

If you do not yet have the Apple files themselves, use:

- `APPLE_SIGNING_ASSETS_GUIDE.md`

That guide explains exactly where to click in Apple Developer and App Store
Connect to get the Team ID, `.p12`, `.mobileprovision`, and optional `.p8`
upload key.

## Recommended Goal State

After one-time setup, your normal release flow should be:

1. `powershell -ExecutionPolicy Bypass -File tool/start_ios_app_store_release.ps1`
2. wait for GitHub to build/sign/upload
3. finish the App Store metadata/review steps in App Store Connect