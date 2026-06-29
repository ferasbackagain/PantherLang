#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
COMPILER = PROJECT_ROOT / "compiler" / "pipeline" / "panther_compiler.py"


class PantherToolchainError(Exception):
    pass


@dataclass
class BuildProfile:
    name: str
    optimize: bool
    debug_symbols: bool
    output_dir: str


PROFILES = {
    "debug": BuildProfile("debug", optimize=False, debug_symbols=True, output_dir="build/debug"),
    "release": BuildProfile("release", optimize=True, debug_symbols=False, output_dir="build/release"),
}


def project_entry(cwd: Path) -> Path:
    manifest = cwd / "panther.toml"
    if manifest.exists():
        for line in manifest.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith("entry") and "=" in line:
                entry = line.split("=", 1)[1].strip().strip('"')
                candidate = cwd / entry
                if candidate.exists():
                    return candidate

    default = cwd / "src" / "main.panther"
    if default.exists():
        return default

    raise PantherToolchainError("No Panther entry found. Expected src/main.panther or panther.toml entry.")


def build(source: Path | None = None, profile: str = "debug", cwd: Path | None = None) -> dict[str, Any]:
    cwd = (cwd or Path.cwd()).resolve()
    if profile not in PROFILES:
        raise PantherToolchainError(f"Unknown build profile: {profile}")

    src = (source.expanduser().resolve() if source else project_entry(cwd))
    if not src.exists():
        raise PantherToolchainError(f"Source file not found: {src}")

    config = PROFILES[profile]
    out_dir = cwd / config.output_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    artifact = out_dir / f"{src.stem}.sh"

    proc = subprocess.run(
        [sys.executable, str(COMPILER), "compile", str(src), "--out", str(artifact)],
        cwd=PROJECT_ROOT,
        text=True,
        capture_output=True,
    )

    if proc.returncode != 0:
        return {
            "ok": False,
            "phase": "9.2",
            "profile": profile,
            "source": str(src),
            "artifact": str(artifact),
            "compiler_stdout": proc.stdout,
            "compiler_stderr": proc.stderr,
        }

    report = json.loads(proc.stdout)
    metadata = {
        "ok": True,
        "phase": "9.2",
        "profile": profile,
        "source": str(src),
        "artifact": str(artifact),
        "toolchain": asdict(config),
        "compiler_report": report,
        "project_local_build": str(artifact).startswith(str(cwd / "build")),
    }

    meta_path = artifact.with_suffix(".build.json")
    meta_path.write_text(json.dumps(metadata, indent=2, sort_keys=True), encoding="utf-8")
    return metadata


def clean(cwd: Path | None = None) -> dict[str, Any]:
    cwd = (cwd or Path.cwd()).resolve()
    build_dir = cwd / "build"
    if build_dir.exists():
        shutil.rmtree(build_dir)
    return {"ok": True, "phase": "9.2", "cleaned": str(build_dir)}


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(prog="panther-toolchain")
    sub = parser.add_subparsers(dest="cmd", required=True)

    build_p = sub.add_parser("build")
    build_p.add_argument("source", nargs="?")
    build_p.add_argument("--profile", choices=sorted(PROFILES), default="debug")
    build_p.add_argument("--release", action="store_true")

    sub.add_parser("clean")

    args = parser.parse_args()

    try:
        if args.cmd == "build":
            profile = "release" if args.release else args.profile
            result = build(Path(args.source) if args.source else None, profile=profile)
            print(json.dumps(result, indent=2, sort_keys=True))
            return 0 if result["ok"] else 2

        if args.cmd == "clean":
            print(json.dumps(clean(), indent=2, sort_keys=True))
            return 0

    except PantherToolchainError as exc:
        print(json.dumps({"ok": False, "phase": "9.2", "error": str(exc)}, indent=2))
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
