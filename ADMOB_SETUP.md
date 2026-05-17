# ChessIQ AdMob Setup

This project now supports ad-unit routing by placement instead of treating every
interstitial or rewarded request as one shared bucket.

## Recommended Ad Unit Plan

Create separate ad units for the placements that represent different user
moments and different monetization behavior.

### Interstitials

- Board reset
- Vs Bot match start
- Academy break
- Academy return
- Quiz milestone

### Rewarded

- Store reward
- Academy bonus

This is the right level of split for ChessIQ today.
Do not create a separate ad unit for every method call unless the product flow,
pricing, or policy treatment is genuinely different.

## Suggested AdMob Names

Use consistent names in AdMob so reporting stays readable across iOS and
Android.

### iOS

- `ChessIQ iOS Interstitial - Board Reset`
- `ChessIQ iOS Interstitial - Vs Bot Match Start`
- `ChessIQ iOS Interstitial - Academy Break`
- `ChessIQ iOS Interstitial - Academy Return`
- `ChessIQ iOS Interstitial - Quiz Milestone`
- `ChessIQ iOS Rewarded - Store Reward`
- `ChessIQ iOS Rewarded - Academy Bonus`

### Android

- `ChessIQ Android Interstitial - Board Reset`
- `ChessIQ Android Interstitial - Vs Bot Match Start`
- `ChessIQ Android Interstitial - Academy Break`
- `ChessIQ Android Interstitial - Academy Return`
- `ChessIQ Android Interstitial - Quiz Milestone`
- `ChessIQ Android Rewarded - Store Reward`
- `ChessIQ Android Rewarded - Academy Bonus`

## Current iOS Configuration

- AdMob app ID: `ca-app-pub-8366041710010578~7238643645`
- Board Reset interstitial: `ca-app-pub-8366041710010578/4392988454`
- Vs Bot Match Start interstitial: `ca-app-pub-8366041710010578/5329949968`
- Academy Break interstitial: `ca-app-pub-8366041710010578/2781019694`
- Academy Return interstitial: `ca-app-pub-8366041710010578/9294457153`
- Quiz Milestone interstitial: `ca-app-pub-8366041710010578/3746617002`
- Store Reward rewarded: `ca-app-pub-8366041710010578/4229336921`
- Academy Bonus rewarded: `ca-app-pub-8366041710010578/6532562448`

These iOS placement-specific IDs are now checked into the repo as the default
live values, and the `ADMOB_IOS_*` dart-defines remain available as overrides.

## Placement Routing In Code

Interstitial placements are routed through `InterstitialPlacement` in
`lib/core/services/ad_service.dart`.

- `boardReset`
- `versusBotMatchStart`
- `academyBreak`
- `academyReturn`
- `quizMilestone`

Rewarded placements are routed through `RewardedPlacement` in
`lib/core/services/ad_service.dart`.

- `storeReward`
- `academyBonus`

## Dart Defines For Ad Units

Generic fallback defines:

- `ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID`
- `ADMOB_IOS_REWARDED_AD_UNIT_ID`
- `ADMOB_ANDROID_INTERSTITIAL_AD_UNIT_ID`
- `ADMOB_ANDROID_REWARDED_AD_UNIT_ID`

Placement-specific interstitial defines:

- `ADMOB_IOS_INTERSTITIAL_BOARD_RESET_AD_UNIT_ID`
- `ADMOB_IOS_INTERSTITIAL_VS_BOT_AD_UNIT_ID`
- `ADMOB_IOS_INTERSTITIAL_ACADEMY_BREAK_AD_UNIT_ID`
- `ADMOB_IOS_INTERSTITIAL_ACADEMY_RETURN_AD_UNIT_ID`
- `ADMOB_IOS_INTERSTITIAL_QUIZ_MILESTONE_AD_UNIT_ID`
- `ADMOB_ANDROID_INTERSTITIAL_BOARD_RESET_AD_UNIT_ID`
- `ADMOB_ANDROID_INTERSTITIAL_VS_BOT_AD_UNIT_ID`
- `ADMOB_ANDROID_INTERSTITIAL_ACADEMY_BREAK_AD_UNIT_ID`
- `ADMOB_ANDROID_INTERSTITIAL_ACADEMY_RETURN_AD_UNIT_ID`
- `ADMOB_ANDROID_INTERSTITIAL_QUIZ_MILESTONE_AD_UNIT_ID`

Placement-specific rewarded defines:

- `ADMOB_IOS_REWARDED_STORE_AD_UNIT_ID`
- `ADMOB_IOS_REWARDED_ACADEMY_AD_UNIT_ID`
- `ADMOB_ANDROID_REWARDED_STORE_AD_UNIT_ID`
- `ADMOB_ANDROID_REWARDED_ACADEMY_AD_UNIT_ID`

## Placement To Define Mapping

Create the AdMob unit, then place its ID into the matching define.

### Interstitials

- Board Reset: `ADMOB_IOS_INTERSTITIAL_BOARD_RESET_AD_UNIT_ID` or `ADMOB_ANDROID_INTERSTITIAL_BOARD_RESET_AD_UNIT_ID`
- Vs Bot Match Start: `ADMOB_IOS_INTERSTITIAL_VS_BOT_AD_UNIT_ID` or `ADMOB_ANDROID_INTERSTITIAL_VS_BOT_AD_UNIT_ID`
- Academy Break: `ADMOB_IOS_INTERSTITIAL_ACADEMY_BREAK_AD_UNIT_ID` or `ADMOB_ANDROID_INTERSTITIAL_ACADEMY_BREAK_AD_UNIT_ID`
- Academy Return: `ADMOB_IOS_INTERSTITIAL_ACADEMY_RETURN_AD_UNIT_ID` or `ADMOB_ANDROID_INTERSTITIAL_ACADEMY_RETURN_AD_UNIT_ID`
- Quiz Milestone: `ADMOB_IOS_INTERSTITIAL_QUIZ_MILESTONE_AD_UNIT_ID` or `ADMOB_ANDROID_INTERSTITIAL_QUIZ_MILESTONE_AD_UNIT_ID`

### Rewarded

- Store Reward: `ADMOB_IOS_REWARDED_STORE_AD_UNIT_ID` or `ADMOB_ANDROID_REWARDED_STORE_AD_UNIT_ID`
- Academy Bonus: `ADMOB_IOS_REWARDED_ACADEMY_AD_UNIT_ID` or `ADMOB_ANDROID_REWARDED_ACADEMY_AD_UNIT_ID`

## Android App ID

Android also requires an AdMob app ID in the manifest, not just ad unit IDs.

The Android project now reads the app ID from either:

- environment variable `ADMOB_ANDROID_APP_ID`
- `android/local.properties` key `admobAndroidAppId`

Debug builds fall back to Google's sample Android AdMob app ID.
Android release builds are guarded and should not proceed without a real
Android AdMob app ID.

Example `android/local.properties` entry:

```properties
admobAndroidAppId=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```

## AdMob Console Setup

1. Create the iOS ad units listed above.
2. Create the matching Android ad units in the Android AdMob app.
3. Keep one mediation group per platform and format when the targeting rules
   are the same.
4. Attach the relevant ad units to that mediation group.
5. Add bidding partners only if you are actually integrating those partner
   adapters in the app.

If all interstitial placements use the same bidders, countries, and capping,
you do not need a separate mediation group for every ad unit.
Separate ad units are still useful for reporting, tuning, and future control.

## Linked Services

Linking Google Ads is optional.

You do not need a Google Ads link for standard AdMob monetization,
AdMob mediation, or AdMob bidding.

Link Google Ads only if you plan to:

- run Google Ads app campaigns
- cross-promote your own app inventory
- manage direct-sold campaigns through Google Ads

Linking Firebase is also optional, but it can improve reporting if you already
use Firebase Analytics and want ad reporting context there.

## Test Devices

Keep your physical devices registered as AdMob test devices while verifying new
placements and mediation setup.
Do not rely on simulator or editor behavior alone.

## app-ads.txt

Publish this line at the root of the public developer domain associated with the
store listing:

```text
google.com, pub-8366041710010578, DIRECT, f08c47fec0942fa0
```

For the current public ChessIQ site setup, that should be reachable at:

`https://modus.qila.gl/app-ads.txt`

Not under `/ChessIQ/`.

## Terminal Notes

The website hosting commands for `modus.qila.gl` must be run from the Qila
workspace, not the ChessIQ workspace.

Correct working directory:

```powershell
Set-Location "C:\Qila"
firebase deploy --config firebase.qila-modus.json --only hosting
```

Do not run that command from `C:\ChessIQ`, because that repo does not contain
`firebase.qila-modus.json`.

Likewise, do not run `firebase use --add` in `C:\ChessIQ` when you are trying
to target the Qila hosting project. That changes the active Firebase alias for
the ChessIQ repo and can point it at the wrong project.