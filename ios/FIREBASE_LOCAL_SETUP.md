# Local Firebase iOS Config

`ios/Runner/GoogleService-Info.plist` is required for iOS builds, but it must
stay local-only.

## Replace the local plist

1. Open Firebase Console.
2. Go to Project settings.
3. Select the ChessIQ iOS app for bundle ID `com.qila.chessiq`.
4. Download `GoogleService-Info.plist`.
5. Save it at `ios/Runner/GoogleService-Info.plist`.

## Repo policy

- The real plist is ignored by git.
- The repo should only contain the example file:
  `ios/Runner/GoogleService-Info.plist.example`.
- If you rotate Firebase config, replace the local plist with the newly
  downloaded file and keep it uncommitted.

## Important note

This plist contains Firebase client configuration, not a server credential.
It should not live in the git repo, but it will still be visible inside the
shipped iOS app bundle. Real protection comes from Firebase rules, App Check,
and backend validation.