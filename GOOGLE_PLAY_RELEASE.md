# Google Play Release Path

This public file is intentionally minimal.

The detailed Google Play release runbook is now local-only and lives under
`.private/release/` on maintainer machines. It is ignored by git and is not
part of the public repository anymore.

Public readers should treat the auditable release surface as:

- `.github/workflows/build_android_aab.yml`
- `.github/workflows/build_android_emulator_apk.yml`
- `release_guard.json`
- `tool/release_guard.py`