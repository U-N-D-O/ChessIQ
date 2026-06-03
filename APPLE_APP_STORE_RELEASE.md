# Apple App Store Release Path

This public file is intentionally minimal.

The detailed App Store release runbook is now local-only and lives under
`.private/release/` on maintainer machines. It is ignored by git and is not
part of the public repository anymore.

Public readers should treat the auditable release surface as:

- `.github/workflows/build_ios_ipa.yml`
- `.github/workflows/build_ios_unsigned_ipa.yml`
- `release_guard.json`
- `tool/release_guard.py`
