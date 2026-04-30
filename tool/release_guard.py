#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = REPO_ROOT / "release_guard.json"


def _load_config() -> dict:
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def _read_text(relative_path: str) -> str:
    return (REPO_ROOT / relative_path).read_text(encoding="utf-8")


def _git_output(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "git command failed")
    return result.stdout.strip()


def _expect(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def _check_contains(errors: list[str], relative_path: str, *needles: str) -> None:
    text = _read_text(relative_path)
    for needle in needles:
        _expect(errors, needle in text, f"{relative_path} is missing: {needle}")


def _normalize_tag(tag: str) -> str:
    if tag.startswith("refs/tags/"):
        return tag[len("refs/tags/") :]
    return tag


def _emit_github_env(config: dict) -> int:
    stockfish = config["stockfish"]
    print(f"STOCKFISH_REPO={stockfish['repo']}")
    print(f"STOCKFISH_TAG={stockfish['tag_ref']}")
    print(f"STOCKFISH_COMMIT={stockfish['commit']}")
    print(f"CHESSIQ_PRIVACY_NOTICE_URL={config['privacy_notice_url']}")
    print(f"CHESSIQ_IOS_BUNDLE_ID={config['ios_bundle_identifier']}")
    return 0


def _run_checks(config: dict, expected_tag: str | None) -> int:
    errors: list[str] = []
    privacy_url = config["privacy_notice_url"]
    ios_bundle_identifier = config["ios_bundle_identifier"]
    stockfish = config["stockfish"]

    _expect(errors, CONFIG_PATH.exists(), "release_guard.json is missing")

    for relative_path in config["required_documents"]:
        _expect(errors, (REPO_ROOT / relative_path).exists(), f"Required document missing: {relative_path}")

    _expect(errors, (REPO_ROOT / "IOS_ONE_CLICK_RELEASE_SETUP.md").exists(), "IOS_ONE_CLICK_RELEASE_SETUP.md is missing")
    _expect(errors, (REPO_ROOT / "APPLE_SIGNING_ASSETS_GUIDE.md").exists(), "APPLE_SIGNING_ASSETS_GUIDE.md is missing")

    license_text = _read_text("LICENSE")
    _expect(errors, "GNU GENERAL PUBLIC LICENSE" in license_text, "LICENSE must contain the GNU GPL text")
    _expect(errors, "Version 3, 29 June 2007" in license_text, "LICENSE must contain GPLv3 version text")

    _check_contains(
        errors,
        "COPYRIGHT.md",
        "GNU General Public License v3.0",
        "Recipient rights are governed by that license",
    )
    _check_contains(
        errors,
        "THIRD_PARTY_NOTICES.md",
        "Stockfish chess engine",
        "GNU General Public License v3.0 (GPLv3)",
        "Current native mobile build workflows package Stockfish",
    )
    _check_contains(
        errors,
        "CORRESPONDING_SOURCE.md",
        stockfish["commit"],
        "tool/prepare_stockfish_ios_entrypoint.sh",
        "tool/release_guard.py",
    )
    _check_contains(
        errors,
        "APPLE_APP_STORE_RELEASE.md",
        "Build iOS Signed IPA",
        "APPLE_DISTRIBUTION_CERTIFICATE_BASE64",
        "tool/setup_ios_release_secrets.ps1",
        "tool/start_ios_app_store_release.ps1",
        "tool/release_guard.py --expected-tag",
        privacy_url,
        "The public repo tag for the release is available",
    )
    _check_contains(
        errors,
        "README.md",
        "LICENSE",
        "PRIVACY.md",
        "CORRESPONDING_SOURCE.md",
        "APPLE_APP_STORE_RELEASE.md",
        "IOS_ONE_CLICK_RELEASE_SETUP.md",
        "APPLE_SIGNING_ASSETS_GUIDE.md",
    )
    _check_contains(
        errors,
        "IOS_ONE_CLICK_RELEASE_SETUP.md",
        "tool/setup_ios_release_secrets.ps1",
        "tool/start_ios_app_store_release.ps1",
        "APP_STORE_CONNECT_API_KEY_ID",
        "APPLE_SIGNING_ASSETS_GUIDE.md",
    )
    _check_contains(
        errors,
        "APPLE_SIGNING_ASSETS_GUIDE.md",
        "com.qila.chessiq",
        "tool/setup_ios_release_secrets.ps1",
        "tool/start_ios_app_store_release.ps1",
        "App Store Connect API",
    )

    pubspec = _read_text("pubspec.yaml")
    _expect(errors, "url_launcher:" in pubspec, "pubspec.yaml must include url_launcher")
    _expect(errors, "PixgamerRegular" not in pubspec, "pubspec.yaml must not bundle PixgamerRegular")
    for asset_path in config["bundled_legal_assets"]:
        _expect(errors, f"- {asset_path}" in pubspec, f"pubspec.yaml must bundle {asset_path}")

    _check_contains(
        errors,
        "lib/core/constants/legal_links.dart",
        privacy_url,
        "chessIqPrivacyNoticeUri",
    )
    _check_contains(
        errors,
        "ios/Runner/Info.plist",
        "$(PRODUCT_BUNDLE_IDENTIFIER)",
    )
    _check_contains(
        errors,
        "ios/Runner.xcodeproj/project.pbxproj",
        ios_bundle_identifier,
    )
    _check_contains(
        errors,
        "ios/ExportOptions-AppStore.plist.template",
        "__TEAM_ID__",
        "__BUNDLE_IDENTIFIER__",
        "__PROFILE_NAME__",
        "<string>app-store</string>",
    )
    _check_contains(
        errors,
        "lib/features/academy/screens/puzzle_map_screen.dart",
        "READ PRIVACY NOTICE",
        "chessIqPrivacyNoticeUri",
        "launchUrl(chessIqPrivacyNoticeUri)",
    )
    _check_contains(
        errors,
        "lib/features/analysis/chess_analysis/base_state.dart",
        "Privacy Notice",
        "chessIqPrivacyNoticeUri",
        "launchUrl(chessIqPrivacyNoticeUri)",
    )

    for workflow_path in config["build_workflows"]:
        _check_contains(
            errors,
            workflow_path,
            "python3 tool/release_guard.py --emit-github-env",
            "python3 tool/release_guard.py",
        )

    _check_contains(
        errors,
        ".github/workflows/ci.yml",
        "python3 tool/release_guard.py",
        "Verify release guard",
    )
    _check_contains(
        errors,
        ".github/workflows/release_guard.yml",
        "python3 tool/release_guard.py",
        "release_tag",
    )
    _check_contains(
        errors,
        ".github/workflows/build_ios_ipa.yml",
        "APPLE_DISTRIBUTION_CERTIFICATE_BASE64",
        "APPLE_PROVISIONING_PROFILE_BASE64",
        "APPLE_TEAM_ID",
        "APP_STORE_CONNECT_API_KEY_ID",
        "APP_STORE_CONNECT_API_ISSUER_ID",
        "APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64",
        "ios/ExportOptions-AppStore.plist.template",
        "xcodebuild",
        "-exportArchive",
        "Upload IPA to App Store Connect",
        "xcrun altool",
        "CODE_SIGN_STYLE=Manual",
        "Apple Distribution",
        "refs/tags/${{ inputs.release_tag }}",
    )
    _check_contains(
        errors,
        "tool/setup_ios_release_secrets.ps1",
        "gh secret set",
        "APPLE_DISTRIBUTION_CERTIFICATE_BASE64",
        "APP_STORE_CONNECT_API_KEY_ID",
    )
    _check_contains(
        errors,
        "tool/start_ios_app_store_release.ps1",
        "'workflow', 'run', 'build_ios_ipa.yml'",
        "build_ios_ipa.yml",
        "upload_to_app_store",
    )

    if expected_tag:
        normalized_tag = _normalize_tag(expected_tag)
        try:
            head_commit = _git_output("rev-parse", "HEAD")
            tag_commit = _git_output("rev-list", "-n", "1", f"refs/tags/{normalized_tag}")
        except RuntimeError as error:
            errors.append(f"Git tag validation failed: {error}")
        else:
            _expect(
                errors,
                head_commit == tag_commit,
                f"HEAD does not match refs/tags/{normalized_tag}",
            )

    if errors:
        print("Release guard failed:", file=sys.stderr)
        for message in errors:
            print(f"- {message}", file=sys.stderr)
        return 1

    print("Release guard passed.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify ChessIQ release-compliance guardrails.")
    parser.add_argument("--emit-github-env", action="store_true", help="Print workflow env values from release_guard.json")
    parser.add_argument("--expected-tag", help="Require HEAD to match the given git tag")
    args = parser.parse_args()

    config = _load_config()
    if args.emit_github_env:
        return _emit_github_env(config)
    return _run_checks(config, args.expected_tag)


if __name__ == "__main__":
    raise SystemExit(main())