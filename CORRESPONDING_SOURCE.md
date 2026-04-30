# Corresponding Source

This document describes how ChessIQ intends to map Stockfish-enabled mobile
releases to their matching source materials.

## Goal

For each shipped iOS or Android release that includes Stockfish, the public
ChessIQ repository should identify the exact corresponding source for that
release.

## Release Mapping

Each Stockfish-enabled mobile release should be tied to:

- A public ChessIQ git tag for the exact release commit
- Release notes or a GitHub Release for that tag
- The pinned Stockfish source revision used by the workflows
- The in-repo build inputs that produce the shipped engine integration

## Current Stockfish Pin

The mobile workflows are currently pinned to the Stockfish 18 tag `sf_18` at:

- `cb3d4ee9b47d0c5aae855b12379378ea1439675c`

## iOS-Specific Build Input

The iOS workflow builds an in-process static library and uses the committed
helper script below to prepare the renamed Stockfish entrypoint:

- `tool/prepare_stockfish_ios_entrypoint.sh`

That helper is part of the release source footprint for iOS builds.

## Minimum Release Checklist

Before shipping a Stockfish-enabled mobile build:

1. Create the release tag in the public ChessIQ repository.
2. Run `python3 tool/release_guard.py --expected-tag <tag>` or the
   **Release Guard** workflow for that tag.
3. Verify the mobile workflows still point at the intended pinned Stockfish
   revision.
4. Verify the iOS helper script and workflow inputs in the repo match the
   shipped build.
5. Verify legal notices, privacy notices, and release notes point back to the
   tagged public source.
6. Preserve the release materials so users can identify the exact source for
   the shipped binary.

## Scope Note

This document is a release-source mapping note. It does not replace the
applicable release license, third-party notices, or privacy policy.
