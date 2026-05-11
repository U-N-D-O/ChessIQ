# Academy Leaderboard Moderation

Use the Realtime Database to force a leaderboard nickname change without touching app code.

## Flag a nickname

The easiest path is now a single switch on the offending leaderboard row.

1. Open `academy_scoreboard/global` in the Firebase Realtime Database console.
2. Open the offending handle entry.
3. Add or set `moderated = true` on that row.

That is enough. The backend will copy the block to the private moderation path, remove the public leaderboard entry automatically, and clear the matching `handle_registry` plus `academy_profile_owner` records for that moderated handle.

If you prefer editing raw JSON directly, this also works:

```json
academy_handle_moderation/<handle_key> = true
```

If you need a custom player-facing message later, you can still use the richer object form:

```json
{
  "active": true,
  "playerMessage": "Your ChessIQ leaderboard nickname violated the nickname rules. Choose a new nickname to continue.",
  "reasonCode": "nickname_policy",
  "updatedAt": "2026-05-02T12:00:00Z"
}
```

## What happens next

- A database trigger copies the moderation block to `academy_handle_moderation/<handle_key>`, removes the flagged name from the public global and country leaderboards, and clears the matching private handle ownership records so you do not have to delete four nodes by hand.
- The updated app calls `submitAcademyScoreV2` when Academy opens or a profile is saved.
- If the current nickname matches an active moderation record, the app shows a blocking warning and reopens the nickname dialog until the player picks a different handle or leaves Academy.
- The old nickname stays blocked for everyone while the moderation record remains active.

## Lift a nickname block

- Delete `academy_handle_moderation/<handle_key>`, or set `active` to `false`.
- This does not restore a removed leaderboard row automatically. The player must sync their profile again for it to reappear.