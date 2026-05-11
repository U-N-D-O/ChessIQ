# ChessIQ Apple Pre-Submission Checklist

Use this with `APPLE_APP_STORE_RELEASE.md` right before sending a build to Apple.
This file is the product and backend preflight list: StoreKit, ads, leaderboard,
Firebase functions, privacy, and final smoke tests.

## Current Repo Findings

- [ ] Replace the Google test AdMob unit IDs in `lib/core/services/ad_service.dart` before submission.
  Current interstitial: `ca-app-pub-3940256099942544/4411468910`
  Current rewarded: `ca-app-pub-3940256099942544/1712485313`
- [ ] Stop hardcoding App Store prices in `lib/features/analysis/chess_analysis/base_state.dart`.
  The Store currently shows fixed strings like `$4.99`, `$9.99`, and `$6.99`
  instead of StoreKit's localized `ProductDetails.price`.
- [ ] Expand `PRIVACY.md` and the public privacy notice URL.
  The current policy is leaderboard-specific and does not yet cover AdMob,
  in-app purchases, anonymous Firebase Auth, or Firebase backend processing.
- [ ] Review `ios/Runner/Info.plist` ad config before launch.
  The AdMob app ID is present, but the plist currently contains only one
  `SKAdNetworkIdentifier` entry.

## Must Change Before Submission

- [ ] Replace the test interstitial and rewarded ad unit IDs in
  `lib/core/services/ad_service.dart` with your live iOS AdMob unit IDs.
- [ ] Keep `ios/Runner/Info.plist` `GADApplicationIdentifier` aligned with the
  same AdMob app as the live unit IDs.
- [ ] Remove hardcoded IAP prices from
  `lib/features/analysis/chess_analysis/base_state.dart` and render the live,
  localized StoreKit prices returned by `PurchaseService`.
- [ ] Update `PRIVACY.md` and the published privacy policy page so it covers:
  ads and AdMob, in-app purchases, anonymous Firebase Auth, Realtime Database,
  Cloud Functions, and user deletion/removal flows.
- [ ] Decide your ATT/tracking stance before review.
  If you plan to request tracking permission, add
  `NSUserTrackingUsageDescription` and the ATT prompt flow.
  If you do not plan to request tracking permission, verify the app and App
  Store Connect privacy answers are configured accordingly.
- [ ] Review `SKAdNetworkItems` in `ios/Runner/Info.plist` against the current
  Google Mobile Ads guidance and add the required identifiers for your setup.
- [ ] Bump the release version and build number before submission.
  Source of truth in repo: `pubspec.yaml`

## Store And In-App Purchases

- [ ] Confirm these App Store Connect product IDs exist and are ready for
  review:
  `com.qila.chessiq.coins_s`
  `com.qila.chessiq.coins_l`
  `com.qila.chessiq.reset_board_pass`
  `com.qila.chessiq.academy_pass`
- [ ] Verify `PurchaseService.instance.initialize()` loads product details on a
  physical iPhone and logs no `products not found` errors.
- [ ] Test `Coin Pack S` and confirm one completed purchase grants exactly
  `1500` coins.
- [ ] Test `Coin Pack L` and confirm one completed purchase grants exactly
  `5000` coins.
- [ ] Test `Clean Play No-Ad Pass` and confirm it unlocks ad-free analysis
  resets, bot rematches, and new bot matches.
- [ ] Test `Academy Tuition Pass` and confirm it skips Academy brain-break and
  daily challenge reward ads.
- [ ] Test `Restore Purchases` after reinstalling the app and on a second
  device using the same Apple ID.
- [ ] Test failed, cancelled, pending, and offline purchase paths so the UI
  does not silently mislead the user or double-credit coins.
- [ ] Verify the prices shown in the Store match the prices configured in App
  Store Connect for every locale you plan to ship.
- [ ] Add or review App Review notes describing how to reach the Store and test
  restoring non-consumables.
- [ ] Confirm App Store Connect metadata, screenshots, and review attachments
  for the IAP products are complete.

## Ads

- [ ] Replace the test ad unit IDs before generating the submission build.
- [ ] Confirm interstitial ads show correctly on iOS in the live flows you use:
  analysis reset, bot rematch/new match, Academy placements, and any other
  release-facing trigger.
- [ ] Confirm rewarded ads grant the reward only after the reward callback and
  never on a failed or dismissed ad.
- [ ] Verify the Store rewarded-ad flow still grants `+120` coins after a full
  view and fails cleanly when ads are unavailable.
- [ ] Verify the interstitial cooldown behavior still feels correct in release:
  board reset cooldown `90s`, repeat grace `10s`.
- [ ] Test a fresh install on iPhone with the final AdMob config, not just in a
  development environment.
- [ ] Verify the App Store privacy answers cover the ad SDK data collection you
  actually use.

## Leaderboard

- [ ] Confirm Anonymous Sign-In is enabled in Firebase Authentication.
- [ ] Deploy `firebase_rtdb_rules.json` before launch and verify the rules are
  active in production.
- [ ] Deploy and smoke-test these callable functions:
  `submitAcademyScoreV2`
  `checkHandleAvailabilityV2`
  `deleteAcademyProfile`
- [ ] Confirm the moderation-triggered function paths are active:
  `academy_handle_moderation`
  `academy_scoreboard/global`
- [ ] Test creating a new leaderboard profile on a clean install.
- [ ] Test handle availability checks for: available, taken, and moderated.
- [ ] Test submitting a valid score and confirm the public leaderboard updates.
- [ ] Test global and country leaderboards and verify sorting, rank numbering,
  and duplicate suppression look correct.
- [ ] Test deleting the Academy profile and confirm it removes the public entry,
  clears ownership, and rotates the anonymous auth identity when requested.
- [ ] Test offline and backend-failure cases so leaderboard issues do not block
  normal play.
- [ ] Verify the in-app leaderboard privacy copy still matches the published
  privacy policy and App Store Connect disclosures.

## Firebase Functions And Backend

- [ ] Deploy the `functions` project to the production Firebase project before
  submission.
- [ ] Confirm the hardcoded Cloud Functions base URL in the app still points to
  the intended production project: `https://us-central1-chessiq-89b45.cloudfunctions.net`
- [ ] Smoke-test `getServerDate`, because Puzzle Academy daily-challenge timing
  depends on it.
- [ ] Confirm the iOS Firebase app config, Realtime Database URL, and Cloud
  Functions base all point to the same production Firebase project.
- [ ] Review recent function logs for auth failures, `401/403/404`, timeouts,
  and HTML error pages.
- [ ] If you redeploy functions or rules, rerun the full leaderboard create,
  submit, and delete tests afterward.
- [ ] Check your Firebase plan, quotas, and billing posture before launch if
  you expect traffic spikes.

## Apple And App Store Connect

- [ ] Confirm the signed IPA is produced from the final tagged commit.
- [ ] Confirm the release version and build number match the App Store Connect
  upload.
- [ ] Confirm the bundle ID remains `com.qila.chessiq`.
- [ ] Confirm your privacy policy URL is live and public:
  `https://modus.qila.gl/ChessIQ/privacy-notice/`
- [ ] Update App Store Connect privacy answers for ads, purchases,
  leaderboard/profile data, and anonymous identifiers.
- [ ] Confirm the legal documents are current:
  `PRIVACY.md`
  `COPYRIGHT.md`
  `THIRD_PARTY_NOTICES.md`
  `LICENSE`
- [ ] Add App Review notes for any flow that is not obvious, especially the
  leaderboard profile flow and premium/unlock testing.
- [ ] Run at least one final TestFlight smoke test on a real iPhone on the iOS
  version you plan to support.

## Final Pre-Apple Smoke Test

- [ ] Fresh install on iPhone.
- [ ] App launches cleanly.
- [ ] Anonymous Firebase auth provisions successfully.
- [ ] Store product details load successfully.
- [ ] Live ads initialize successfully.
- [ ] Buy `Coin Pack S`.
- [ ] Restore purchases.
- [ ] Create a leaderboard profile.
- [ ] Submit a leaderboard score.
- [ ] Delete the leaderboard profile.
- [ ] Verify the daily challenge still loads with the server-date path.
- [ ] Run the signed iOS release workflow or the release guard one final time.
