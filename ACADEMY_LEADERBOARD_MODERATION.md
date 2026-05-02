# Academy Leaderboard Moderation

Use the Realtime Database to force a leaderboard nickname change without touching app code.

## Flag a nickname

1. Open `academy_scoreboard/global` in the Firebase Realtime Database console.
2. Find the offending entry and copy its key. The key is the sanitized leaderboard handle key already used by the app.
3. Create or update `academy_handle_moderation/<that_handle_key>` with a record like this:

```json
{
  "active": true,
  "displayHandle": "BadName",
  "playerMessage": "Your ChessIQ leaderboard nickname violated the nickname rules. Choose a new nickname to continue.",
  "reasonCode": "nickname_policy",
  "updatedAt": "2026-05-02T12:00:00Z"
}
```

## What happens next

- A database trigger removes the flagged name from the public global and country leaderboards immediately.
- The updated app calls `submitAcademyScoreV2` when Academy opens or a profile is saved.
- If the current nickname matches an active moderation record, the app shows a blocking warning and reopens the nickname dialog until the player picks a different handle or leaves Academy.
- The old nickname stays blocked for everyone while the moderation record remains active.

## Lift a nickname block

- Delete `academy_handle_moderation/<handle_key>`, or set `active` to `false`.
- This does not restore a removed leaderboard row automatically. The player must sync their profile again for it to reappear.