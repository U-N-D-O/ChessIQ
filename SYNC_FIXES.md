# 1v1 sync and avatar purchase fixes

## Findings and changes

- The VS screen fetched matches every 2–4 seconds and restarted its timers after each response. It now subscribes to authenticated Firebase REST events, receiving moves and both players' avatar IDs as soon as the database publishes them. A reconnecting stream handles complete snapshots, nested updates, keepalives and expired authentication. Polling remains as recovery and for server clock/deadline checks. This uses the existing REST Auth identity and membership rules; no Firebase migration is needed. See [Firebase's streaming protocol](https://firebase.google.com/docs/database/rest/retrieve-data#streaming_from_the_rest_api).
- Older HTTP responses can arrive after newer live events. Snapshot ordering and session checks prevent those responses from rolling the board back. Unchanged snapshots preserve an optimistic move pending acceptance. Completed matches stay subscribed for rematches.
- The local player's portrait now uses their current selection immediately; selecting an avatar requests a match update. The opponent's portrait follows the live match snapshot. Avatar inventory initialization is shared between concurrent callers so startup cannot choose multiple starters.
- The original spend function could interpret an uncached transaction value as a new 120-coin account and reject a 200-coin avatar purchase. It now reads the account before running that check. Firebase documents this [initially uncached transaction behavior](https://firebase.google.com/docs/database/admin/save-data#transaction_function_is_called_multiple_times).
- Avatar rolls now persist a chosen avatar and request ID before payment. The new `purchaseAvatarRoll` callable atomically stores the coin debit and receipt. Repeated requests return the same receipt without another debit. Interrupted purchases resume on startup or from Retry Roll. The purchase button prevents simultaneous rolls and displays errors.
- Avatar ownership, selection and unfinished purchases now live in a separate local preference record, `avatar_inventory_v2`, migrated from the previous shared store record. Coin/settings saves cannot overwrite them. Ownership and purchase completion are saved together.
- The move transaction now resets its acceptance flag on every callback attempt, preventing a speculative move from being reported as accepted after a conflict.

## Validation

- `flutter analyze --no-pub`
- `flutter test --no-pub`: 184 tests passed, including stream reconnect/cancellation, late snapshots, avatar migration and interrupted purchases.
- TypeScript compilation and six Node tests passed. The Node tests invoke the real callable handlers with an in-memory database transport, including an initial null transaction value, both players' moves/avatars and a transaction conflict.
- Live device latency and Android-to-iOS play have not been measured in this workspace. Automated tests do not replace that release check.

## Release order

The source changes have not been deployed. Build and deploy the backend before distributing the updated app:

```powershell
npm --prefix functions run build
firebase deploy --only functions --project chessiq-89b45
```

Deploy the complete function codebase, not only `purchaseAvatarRoll`: existing economy writers must also preserve the new receipt field. Rolling those writers back independently could remove receipts and break retry protection. The backend remains compatible with older app clients. No database rule change is required.

Then build/distribute the updated Flutter app through the existing release process. On two devices, check moves in both directions, changing avatars, background/resume, rematches, and interrupting a purchase after tapping Roll. A resumed roll should deduct coins once and deliver one avatar.

## Scope

This preserves the existing anonymous account and local inventory model. It does not add account linking or inventory restoration on a different installation, and cannot reconstruct purchases lost before these receipts existed. Match avatars sync between opponents; full inventory remains local. Avatar selection and storefront prices retain the existing client-driven economy design.
