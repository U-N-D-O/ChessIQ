# Official Privacy Notice

Published notice: https://modus.qila.gl/ChessIQ/privacy-notice/

This notice explains what information ChessIQ may show publicly for the Academy leaderboard, what data may be sent to QILA Modus backend services for leaderboard, promo code, economy, and related networked features, how in-app purchases are fulfilled, and how Google AdMob may process advertising-related data when ChessIQ shows interstitial and rewarded ads.

Separated by design. ChessIQ keeps leaderboard profile data intentionally minimal. Advertising-related processing is handled separately through Google AdMob and relevant platform privacy settings.

## Applies To

- Academy leaderboard profile setup and deletion
- Promo code redemption
- In-app purchases and purchase restoration
- Economy-backed rewards and related backend fulfillment
- Ads shown in ChessIQ
- Anonymous Firebase authentication used to access authenticated backend features

## Operator

- QILA Modus

## Last Updated

- May 30, 2026

## Information Used Or Processed

Leaderboard data, promo redemption tracking, economy fulfillment, and purchase handling support core features. Advertising-related data may also be processed by Google AdMob when ads are requested or shown. Some app state is also stored locally on your device to remember entitlements, settings, and progression.

- Nickname
- Country or region
- Score
- Title
- Update timestamp
- Anonymous Firebase user ID
- Redeemed promo code and promo claim timestamp
- Academy nickname, title, and the country or region selected during Academy setup in private promo claim records when that Academy profile is already attached to the same anonymous Firebase user ID
- In-app purchase product identifiers, purchase status, and platform transaction or verification data needed to fulfill or restore a purchase
- Purchase delivery fingerprints, entitlement flags, and reward-claim state used to avoid duplicate grants
- Economy data such as coin balance, reward cooldown state, promo fulfillment state, and related timestamps when backend-backed economy features are used
- Local app state stored on the device, such as selected settings, owned unlocks, avatar inventory, and similar progression records
- Advertising identifier via Google AdMob, when available under platform settings
- Ad/device interaction data via Google AdMob when ads are requested or shown

## Information We Do Not Ask You To Enter

ChessIQ does not ask you to type direct personal identifiers for leaderboard setup.

- Email address
- Real name
- Precise location

ChessIQ does not request location permission and does not collect or use device GPS or other device-location data. The only country or region value ChessIQ uses for Academy features or promo claim records is the one selected during Academy setup.

## Public Leaderboard Display

If you choose to join the Academy leaderboard, ChessIQ may display the following information publicly inside the app:

- Nickname
- Country or region
- Score
- Title

This public display is used for global and country-based leaderboard views.

## Data Sent To Backend Services

When the app registers or updates an Academy leaderboard profile, ChessIQ may send the following data to QILA Modus backend services:

- Nickname
- Country or region
- Score
- Title
- Update timestamp
- Anonymous Firebase user ID

The anonymous Firebase user ID is used to manage ownership of a leaderboard entry and related backend checks.

When the app redeems a promo code, claims backend-backed rewards, or fulfills purchase-related economy delivery, ChessIQ may send or store the following data in private backend records:

- Redeemed promo code
- Claim timestamp
- Anonymous Firebase user ID
- Academy nickname, title, and the country or region already selected during Academy setup and attached to that anonymous Firebase user ID, if available
- Promo reward details needed to fulfill the redemption
- Product identifiers, purchase delivery fingerprints, or equivalent fulfillment markers needed to grant coins or permanent unlocks without duplicating delivery
- Economy state and reward-tracking records needed to enforce cooldowns, one-time rewards, and similar backend-controlled rules

These private backend records are used to prevent duplicate claims, deliver purchases and rewards correctly, and help QILA Modus review operational issues. They are not shown publicly in the leaderboard.

Where this notice refers to country or region in promo claim records, it means only the country or region the user selected during Academy setup. It is not inferred from IP address, device location, or similar location signals.

## Information We Do Not Request For The Leaderboard

For Academy leaderboard participation, ChessIQ does not ask you to enter:

- Email address
- Real name
- Precise location

ChessIQ does not currently present a separate in-app advertising consent form. Leaderboard setup is separate from any platform or ad-partner permission handling.

## Network And Service Metadata

Backend services and infrastructure providers may process standard network metadata, such as IP address, as part of normal request handling and security operations.

ChessIQ does not show this network metadata on the public leaderboard, and it is not requested from you as part of the Academy profile form.

This network metadata handling does not mean ChessIQ accesses device GPS or other device-location services.

## Anonymous Firebase Authentication And Backend Services

ChessIQ may provision an anonymous Firebase Authentication account on the device when backend-backed features are used.

That anonymous Firebase user ID helps ChessIQ:

- Own and update a leaderboard profile
- Redeem promo codes once per anonymous profile where applicable
- Call authenticated Cloud Functions for economy, purchase fulfillment, and similar backend-backed features
- Support profile deletion or identity rotation flows when required by the app

ChessIQ does not require you to create a traditional account with an email address or password to use these anonymous backend features.

## In-App Purchases

ChessIQ offers in-app purchases through the platform store on your device, such as Apple App Store or Google Play.

When you start, complete, restore, or fail a purchase, ChessIQ and the platform store may process:

- Product identifier
- Purchase state or restore state
- Transaction or verification data provided by the platform store
- Local entitlement records and non-duplicate delivery markers needed to fulfill the purchase correctly

QILA Modus does not ask you to enter payment card details directly into ChessIQ. Payment credentials are handled by the platform store provider.

## Realtime Database And Cloud Functions

ChessIQ uses Firebase Realtime Database and Cloud Functions for selected backend-backed features.

These services may be used to process or store data needed for:

- Academy leaderboard registration, updates, moderation, and deletion
- Promo code redemption and reward fulfillment
- Economy-backed reward claims, purchase fulfillment, and cooldown enforcement
- Date or timing checks used by live or daily content paths

The app may keep some related state only on your device and may keep other state in backend records when that is necessary to make a networked feature work reliably.

## Advertising And Consent

ChessIQ may display interstitial and rewarded ads to support the app.

ChessIQ does not currently present a dedicated in-app advertising consent or withdrawal screen.

Depending on your platform, region, and Google AdMob behavior, ads may be served using contextual, non-personalized, or other platform-limited signals.

ChessIQ does not currently request App Tracking Transparency permission on iOS.

The exact advertising experience may depend on your platform, app version, and active ad partner setup.

## Third-Party Ad Networks

At the time of this notice, ChessIQ uses only Google AdMob to serve ads.

QILA Modus has not yet activated mediation or additional ad network partners in the shipped app. If that changes, this notice will be updated to identify the active partners before or when those integrations go live.

When identifier-based or personalized advertising signals are available, Google AdMob and its providers may process data such as:

- Advertising identifier such as IDFA on iOS or the Android advertising ID or similar platform identifier
- IP address and approximate location
- Device model, OS version, language, and app interaction signals
- Ad impressions, clicks, diagnostics, and fraud-prevention signals

These signals are generally collected directly by the advertising partner SDK. QILA Modus does not use the ChessIQ leaderboard database to store your advertising identifier or build its own advertising profile from this data.

ChessIQ itself does not request or use device GPS or similar device-location services for ads.

## Changing Or Withdrawing Ad Consent

ChessIQ does not currently offer a dedicated in-app screen to revisit ad-consent settings.

Ad-related permissions or identifiers may instead be controlled by your device platform or Google-provided controls, where available.

On iOS, ChessIQ does not currently present an App Tracking Transparency prompt in this version.

Changing or limiting platform-level ad identifiers affects ad personalization and related tracking. It does not by itself remove an Academy leaderboard entry.

## Your Choice

Joining the Academy leaderboard is optional. Ads may still be shown whether or not you join the leaderboard. If you do not want to publish a nickname and country or region on the leaderboard, do not complete leaderboard profile setup. If you want to limit ad-related identifiers where your platform supports that, use the relevant device privacy settings.

If you later want to remove that Academy leaderboard identity, you can delete the Academy profile from Puzzle Academy settings. This removes the live leaderboard profile and clears the local saved Academy profile and exam history used for leaderboard participation.

Where the app offers anonymous-identity rotation as part of that flow, ChessIQ may also discard the current anonymous Firebase identity on the device and provision a fresh anonymous identity for future backend use.

Deleting an Academy leaderboard profile does not itself revoke platform-store purchases. Purchase ownership and restore behavior continue to depend on the platform store account used for those purchases.

## Contact

For privacy or data questions related to ChessIQ, contact QILA Modus at modus@qila.gl.

Questions about advertising consent or ad partners can also be sent to modus@qila.gl.

For product feedback, ideas for improvement, or bug reports, use the ChessIQ feedback page.
