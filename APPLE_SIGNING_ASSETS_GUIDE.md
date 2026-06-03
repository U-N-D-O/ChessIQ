# Apple Signing Assets Guide

This public file is intentionally minimal.

The detailed Apple signing runbook is now local-only and lives under
`.private/release/` on maintainer machines. It is ignored by git and is not
part of the public repository anymore.

Public readers should treat the auditable release surface as:

- `.github/workflows/build_ios_ipa.yml`
- `ios/ExportOptions-AppStore.plist.template`
- `release_guard.json`
- `tool/release_guard.py`