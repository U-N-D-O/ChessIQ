# Apple Signing Assets Guide

This is the missing one-time Apple setup for the ChessIQ iOS release flow.

After you finish this once, the repo scripts can do the GitHub secret upload,
tag creation, signed IPA build, and optional App Store Connect upload.

## What You Need To End Up With

You need these items:

1. Your Apple Team ID
2. An Apple Distribution certificate exported as a `.p12` file
3. The password for that `.p12` file
4. An App Store provisioning profile as a `.mobileprovision` file
5. Optional but recommended: an App Store Connect API key `.p8` file,
   plus its key ID and issuer ID, so GitHub can upload automatically

## Before You Start

Make sure you can sign into:

- Apple Developer
- App Store Connect

You also need access to a Mac for the certificate export step.

## 1. Find Your Apple Team ID

1. Sign into Apple Developer.
2. Open **Membership**.
3. Find **Team ID**.
4. Save that value. This becomes `APPLE_TEAM_ID`.

## 2. Create Or Confirm The App ID

You want the bundle identifier used by this repo:

- `com.qila.chessiq`

In Apple Developer:

1. Open **Certificates, Identifiers & Profiles**.
2. Open **Identifiers**.
3. Check whether App ID `com.qila.chessiq` already exists.
4. If it does not exist:
   - click **+**
   - choose **App IDs**
   - choose **App**
   - enter a name like `ChessIQ`
   - set the bundle identifier to `com.qila.chessiq`
   - save it

## 3. Create The Apple Distribution Certificate

This step is easiest on a Mac.

### On The Mac

1. Open **Keychain Access**.
2. In the menu bar, choose:
   **Keychain Access -> Certificate Assistant -> Request a Certificate From a Certificate Authority**
3. Enter your Apple account email.
4. Use any sensible common name like `ChessIQ Distribution`.
5. Choose **Saved to disk**.
6. Save the `.certSigningRequest` file.

### In Apple Developer

1. Open **Certificates, Identifiers & Profiles**.
2. Open **Certificates**.
3. Click **+**.
4. Choose **Apple Distribution**.
5. Upload the `.certSigningRequest` file.
6. Download the generated certificate.

### Back On The Mac

1. Open the downloaded certificate so it is added to Keychain Access.
2. In Keychain Access, find the certificate and its private key.
3. Select both.
4. Right-click and choose **Export 2 items...**
5. Export as a `.p12` file.
6. Choose a password and remember it.

You now have:

- the `.p12` file
- the password for that `.p12`

These become:

- `APPLE_DISTRIBUTION_CERTIFICATE_BASE64` after the setup script converts it
- `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD`

## 4. Create The App Store Provisioning Profile

In Apple Developer:

1. Open **Certificates, Identifiers & Profiles**.
2. Open **Profiles**.
3. Click **+**.
4. Choose **App Store** under distribution.
5. Select App ID `com.qila.chessiq`.
6. Select the Apple Distribution certificate you just created.
7. Name the profile something obvious like `ChessIQ App Store`.
8. Generate it.
9. Download the `.mobileprovision` file.

This becomes `APPLE_PROVISIONING_PROFILE_BASE64` after the setup script
converts it.

## 5. Create The App Store Connect API Key For Automatic Upload

This part is optional, but if you do it, GitHub can upload the IPA to App
Store Connect automatically.

In App Store Connect:

1. Open **Users and Access**.
2. Open the **Keys** tab.
3. Open **App Store Connect API**.
4. Click **Generate API Key**.
5. Give it a name like `ChessIQ Release Upload`.
6. Use a role with permission to upload builds.
7. Download the `.p8` key file.
8. Save the **Key ID**.
9. Save the **Issuer ID**.

These become:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64` after the setup script converts
  the `.p8` file

Important:

- Apple only lets you download the `.p8` file once.
- Save it somewhere safe before closing the page.

## 6. Feed Everything Into The Repo Automation

Once you have the files and values, go back to the repo folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File tool/setup_ios_release_secrets.ps1
```

That script will ask for:

- your GitHub repo
- your Apple Team ID
- the `.p12` file path
- the `.p12` password
- the `.mobileprovision` file path
- optionally the `.p8` file path, key ID, and issuer ID

It will upload the GitHub secrets for you.

## 7. Start The Actual Release

After the one-time setup above is done, the recurring release command is:

```powershell
powershell -ExecutionPolicy Bypass -File tool/start_ios_app_store_release.ps1
```

That script will:

1. make or reuse the exact release tag
2. push the tag
3. start the signed GitHub workflow
4. optionally request direct App Store Connect upload

## Short Reality Check

The one part that cannot be invented by automation is Apple's signing material.
You must obtain those once from Apple. After that, the repo automation takes
over.