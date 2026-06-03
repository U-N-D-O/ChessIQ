# One-Click Android Release Setup

This public file is intentionally minimal.

The detailed Android release runbook is local-only and lives under
`.private/release/` on maintainer machines. It is ignored by git and is not
part of the public repository anymore.

Public readers should treat the auditable release surface as:

- `.github/workflows/build_android_aab.yml`
- `release_guard.json`
- `tool/release_guard.py`