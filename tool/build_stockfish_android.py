#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = REPO_ROOT / "release_guard.json"
DEFAULT_ASSETS_DIR = REPO_ROOT / "android" / "app" / "src" / "main" / "jniLibs"
ANDROID_ABIS: dict[str, str] = {
    "arm64-v8a": "armv8",
    "armeabi-v7a": "armv7",
    "x86_64": "x86-64",
    "x86": "x86-32",
}
DEFAULT_ANDROID_ABIS = ["arm64-v8a", "armeabi-v7a", "x86_64"]


def _load_config() -> dict:
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def _normalize_ref(tag_ref: str) -> str:
    if tag_ref.startswith("refs/tags/"):
        return tag_ref[len("refs/tags/") :]
    return tag_ref


def _run(command: list[str], *, cwd: Path | None = None, env: dict[str, str] | None = None) -> None:
    print("+", " ".join(command))
    subprocess.run(command, cwd=cwd, env=env, check=True)


def _capture(command: list[str], *, cwd: Path | None = None, env: dict[str, str] | None = None) -> str:
    result = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def _read_local_properties() -> dict[str, str]:
    local_properties = REPO_ROOT / "android" / "local.properties"
    values: dict[str, str] = {}
    if not local_properties.exists():
        return values

    for line in local_properties.read_text(encoding="utf-8").splitlines():
        if not line or line.lstrip().startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().replace("\\\\", "\\")
    return values


def _resolve_android_sdk() -> Path | None:
    local_properties = _read_local_properties()
    candidates = [
        local_properties.get("sdk.dir"),
        os.environ.get("ANDROID_SDK_ROOT"),
        os.environ.get("ANDROID_HOME"),
        os.path.join(os.environ.get("LOCALAPPDATA", ""), "Android", "Sdk"),
    ]
    for candidate in candidates:
        if not candidate:
            continue
        path = Path(candidate)
        if path.exists():
            return path.resolve()
    return None


def _version_key(path: Path) -> tuple[int, ...]:
    parts: list[int] = []
    for fragment in path.name.replace("-", ".").split("."):
        if fragment.isdigit():
            parts.append(int(fragment))
    return tuple(parts)


def _resolve_android_ndk(ndk_override: str | None) -> Path:
    if ndk_override:
        ndk_path = Path(ndk_override)
        if not ndk_path.exists():
            raise FileNotFoundError(f"Android NDK path does not exist: {ndk_path}")
        return ndk_path.resolve()

    env_candidates = [
        os.environ.get("ANDROID_NDK_ROOT"),
        os.environ.get("ANDROID_NDK_HOME"),
    ]
    for candidate in env_candidates:
        if not candidate:
            continue
        ndk_path = Path(candidate)
        if ndk_path.exists():
            return ndk_path.resolve()

    sdk_path = _resolve_android_sdk()
    if sdk_path is None:
        raise FileNotFoundError(
            "Android SDK was not found. Set ANDROID_SDK_ROOT or sdk.dir in android/local.properties.",
        )

    ndk_root = sdk_path / "ndk"
    if not ndk_root.exists():
        raise FileNotFoundError(f"No Android NDK installation was found under {ndk_root}")

    installed = sorted((path for path in ndk_root.iterdir() if path.is_dir()), key=_version_key, reverse=True)
    if not installed:
        raise FileNotFoundError(f"No Android NDK installation was found under {ndk_root}")
    return installed[0].resolve()


def _resolve_git_shell() -> Path | None:
    shell_candidates = [
        shutil.which("sh"),
        shutil.which("bash"),
        r"C:\src\Git\usr\bin\sh.exe",
        r"C:\src\Git\bin\sh.exe",
        r"C:\src\Git\usr\bin\bash.exe",
        r"C:\src\Git\bin\bash.exe",
        r"C:\Program Files\Git\usr\bin\sh.exe",
        r"C:\Program Files\Git\bin\sh.exe",
        r"C:\Program Files\Git\usr\bin\bash.exe",
        r"C:\Program Files\Git\bin\bash.exe",
        r"C:\Program Files (x86)\Git\usr\bin\sh.exe",
        r"C:\Program Files (x86)\Git\bin\sh.exe",
        r"C:\Program Files (x86)\Git\usr\bin\bash.exe",
        r"C:\Program Files (x86)\Git\bin\bash.exe",
    ]
    for candidate in shell_candidates:
        if not candidate:
            continue
        shell_path = Path(candidate)
        if shell_path.exists():
            return shell_path.resolve()
    return None


def _prepare_make_env() -> dict[str, str]:
    env = os.environ.copy()
    if os.name != "nt":
        return env

    shell_path = _resolve_git_shell()
    if shell_path is None:
        raise FileNotFoundError(
            "Git for Windows shell was not found. Install Git for Windows or add sh.exe to PATH.",
        )

    env["SHELL"] = str(shell_path)
    path_entries = [str(shell_path.parent)]
    git_root = shell_path.parents[2] if shell_path.parent.name == "bin" and shell_path.parent.parent.name == "usr" else shell_path.parents[1]
    for relative in (Path("usr") / "bin", Path("bin"), Path("cmd")):
        candidate = git_root / relative
        if candidate.exists():
            path_entries.append(str(candidate))
    env["PATH"] = os.pathsep.join(path_entries + [env.get("PATH", "")])
    return env


def _resolve_ndk_toolchain_bin(ndk_path: Path) -> Path:
    prebuilt_root = ndk_path / "toolchains" / "llvm" / "prebuilt"
    if not prebuilt_root.exists():
        raise FileNotFoundError(f"LLVM toolchain directory was not found under {prebuilt_root}")

    prebuilt_dirs = sorted(path for path in prebuilt_root.iterdir() if path.is_dir())
    if not prebuilt_dirs:
        raise FileNotFoundError(f"No LLVM prebuilt directories were found under {prebuilt_root}")

    toolchain_bin = prebuilt_dirs[0] / "bin"
    if not toolchain_bin.exists():
        raise FileNotFoundError(f"LLVM toolchain bin directory was not found under {toolchain_bin}")
    return toolchain_bin.resolve()


def _ensure_pinned_checkout(config: dict, source_dir: Path | None) -> tuple[Path, tempfile.TemporaryDirectory[str] | None]:
    stockfish = config["stockfish"]
    if source_dir is not None:
        if not source_dir.exists():
            raise FileNotFoundError(f"Stockfish source directory does not exist: {source_dir}")
        head = _capture(["git", "-C", str(source_dir), "rev-parse", "HEAD"])
        if head != stockfish["commit"]:
            raise RuntimeError(
                f"Stockfish checkout is at {head}, expected pinned commit {stockfish['commit']}",
            )
        return source_dir.resolve(), None

    temp_dir = tempfile.TemporaryDirectory(prefix="chessiq-stockfish-android-")
    checkout_dir = Path(temp_dir.name) / "Stockfish"
    clone_ref = _normalize_ref(stockfish["tag_ref"])
    _run(["git", "clone", "--depth", "1", "--branch", clone_ref, stockfish["repo"], str(checkout_dir)])
    _run(["git", "-C", str(checkout_dir), "checkout", "--detach", stockfish["commit"]])
    head = _capture(["git", "-C", str(checkout_dir), "rev-parse", "HEAD"])
    if head != stockfish["commit"]:
        raise RuntimeError(f"Cloned Stockfish checkout is at {head}, expected {stockfish['commit']}")
    return checkout_dir, temp_dir


def build_android_stockfish(*, source_dir: Path | None, assets_dir: Path, ndk_path: Path, jobs: int, abis: list[str]) -> None:
    config = _load_config()
    make_path = shutil.which("make")
    if make_path is None:
        raise FileNotFoundError("GNU make was not found on PATH.")

    make_env = _prepare_make_env()
    stockfish_root, temp_dir = _ensure_pinned_checkout(config, source_dir)
    source_root = stockfish_root / "src"
    assets_dir.mkdir(parents=True, exist_ok=True)

    try:
        ndk_value = ndk_path.as_posix()
        toolchain_bin = _resolve_ndk_toolchain_bin(ndk_path)
        make_env["PATH"] = os.pathsep.join([str(toolchain_bin), make_env.get("PATH", "")])
        for abi in abis:
            arch = ANDROID_ABIS[abi]
            _run([make_path, "clean"], cwd=source_root, env=make_env)
            _run(
                [
                    make_path,
                    f"-j{jobs}",
                    "build",
                    "COMP=ndk",
                    f"ARCH={arch}",
                    f"NDK={ndk_value}",
                ],
                cwd=source_root,
                env=make_env,
            )

            built_binary = source_root / "stockfish"
            if not built_binary.exists():
                raise FileNotFoundError(f"Expected Stockfish binary was not produced for {abi}")

            destination_dir = assets_dir / abi
            destination_dir.mkdir(parents=True, exist_ok=True)
            destination = destination_dir / "libstockfish.so"
            shutil.copy2(built_binary, destination)
            print(f"Copied {abi} binary to {destination}")
    finally:
        if temp_dir is not None:
            temp_dir.cleanup()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build pinned Android Stockfish assets for ChessIQ.")
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=None,
        help="Existing Stockfish checkout at the pinned commit. If omitted, the script clones the pinned tag to a temporary folder.",
    )
    parser.add_argument(
        "--jni-libs-dir",
        "--assets-dir",
        dest="assets_dir",
        type=Path,
        default=DEFAULT_ASSETS_DIR,
        help="Directory that receives the built Android Stockfish libraries.",
    )
    parser.add_argument(
        "--ndk",
        default=None,
        help="Explicit Android NDK path. Defaults to ANDROID_NDK_ROOT/ANDROID_NDK_HOME or the newest SDK-installed NDK.",
    )
    parser.add_argument(
        "--jobs",
        type=int,
        default=os.cpu_count() or 4,
        help="Parallel make job count.",
    )
    parser.add_argument(
        "--abis",
        nargs="+",
        choices=list(ANDROID_ABIS.keys()),
        default=DEFAULT_ANDROID_ABIS,
        help="Android ABIs to build.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        ndk_path = _resolve_android_ndk(args.ndk)
        build_android_stockfish(
            source_dir=args.source_dir,
            assets_dir=args.assets_dir.resolve(),
            ndk_path=ndk_path,
            jobs=max(args.jobs, 1),
            abis=args.abis,
        )
    except (FileNotFoundError, RuntimeError, subprocess.CalledProcessError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())