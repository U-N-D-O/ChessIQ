import argparse
import json
import os
import shutil
import re
import subprocess
import sys
from pathlib import Path


_FILE_PATTERN = re.compile(r"^daily_puzzles_(\d{8})_\d+\.json$")


def _load_daily_payload(source_dir: Path) -> tuple[dict[str, list[object]], int]:
    payload: dict[str, list[object]] = {}
    total_puzzles = 0

    for path in sorted(source_dir.glob("daily_puzzles_*.json")):
        match = _FILE_PATTERN.match(path.name)
        if match is None:
            continue

        date_stamp = match.group(1)
        raw = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(raw, list):
            raise ValueError(f"Expected a list in {path}")
        if date_stamp in payload:
            raise ValueError(f"Duplicate daily challenge date detected: {date_stamp}")

        payload[date_stamp] = raw
        total_puzzles += len(raw)

    if not payload:
        raise ValueError(f"No daily puzzle files found in {source_dir}")

    return payload, total_puzzles


def _write_payload(output_path: Path, payload: dict[str, list[object]]) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(payload, separators=(",", ":"), ensure_ascii=False),
        encoding="utf-8",
    )


def _upload_payload(output_path: Path, project_id: str) -> None:
    firebase_executable = shutil.which("firebase.cmd") or shutil.which("firebase")
    if firebase_executable is None:
        raise FileNotFoundError("Unable to locate firebase CLI executable.")

    env = dict(os.environ)
    env.pop("FIREBASE_TOKEN", None)

    command = [
        firebase_executable,
        "--project",
        project_id,
        "database:set",
        "/daily_challenges_public/v1",
        str(output_path),
        "-f",
        "--disable-triggers",
    ]
    subprocess.run(command, check=True, env=env)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Bundle and optionally upload ChessIQ daily challenge JSON files.",
    )
    parser.add_argument(
        "--source-dir",
        default="assets/puzzles",
        help="Directory containing daily_puzzles_YYYYMMDD_*.json files.",
    )
    parser.add_argument(
        "--output",
        default="build/daily_challenges_public_v1.json",
        help="Where to write the aggregated RTDB payload.",
    )
    parser.add_argument(
        "--project",
        default="chessiq-89b45",
        help="Firebase project id used when --upload is supplied.",
    )
    parser.add_argument(
        "--upload",
        action="store_true",
        help="Upload the generated payload to /daily_challenges_public/v1 in RTDB.",
    )
    args = parser.parse_args()

    source_dir = Path(args.source_dir)
    output_path = Path(args.output)

    payload, total_puzzles = _load_daily_payload(source_dir)
    _write_payload(output_path, payload)

    print(
        "Prepared",
        len(payload),
        "daily challenge files with",
        total_puzzles,
        "puzzles at",
        output_path,
    )

    if args.upload:
        _upload_payload(output_path, args.project)
        print(
            "Uploaded daily challenge payload to",
            f"/daily_challenges_public/v1 for {args.project}",
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())