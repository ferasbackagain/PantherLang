#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

TARGETS = {
    "linux-x64": {
        "filename": "Panther",
        "kind": "posix",
        "shebang": "#!/usr/bin/env bash",
    },
    "macos-arm64": {
        "filename": "Panther.command",
        "kind": "posix",
        "shebang": "#!/usr/bin/env bash",
    },
    "windows-x64": {
        "filename": "Panther.cmd",
        "kind": "windows",
        "shebang": None,
    },
}


def build_target(target: str, out_dir: Path) -> dict:
    if target not in TARGETS:
        raise SystemExit(f"Unknown target: {target}")

    spec = TARGETS[target]
    target_dir = out_dir / target
    target_dir.mkdir(parents=True, exist_ok=True)
    artifact = target_dir / spec["filename"]

    if spec["kind"] == "windows":
        artifact.write_text(
            "@echo off\r\n"
            "set PANTHER_HOME=%~dp0\\..\\..\\\r\n"
            "python \"%PANTHER_HOME%\\panther\" %*\r\n",
            encoding="utf-8",
        )
    else:
        artifact.write_text(
            f"{spec['shebang']}\n"
            "set -euo pipefail\n"
            "SCRIPT_DIR=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\"\n"
            "PANTHER_HOME=\"$(cd \"$SCRIPT_DIR/../../..\" && pwd)\"\n"
            "exec \"$PANTHER_HOME/panther\" \"$@\"\n",
            encoding="utf-8",
        )
        artifact.chmod(0o755)

    manifest = {
        "ok": True,
        "stage": "H2",
        "target": target,
        "artifact": str(artifact),
        "kind": spec["kind"],
        "native_launcher": True,
        "python_free_goal": True,
        "current_mode": "launcher wraps Panther CLI until H2 binary compiler packaging matures",
    }

    (target_dir / "native.manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
    return manifest


def build_all(out_dir: Path) -> dict:
    results = [build_target(target, out_dir) for target in TARGETS]
    return {
        "ok": all(item["ok"] for item in results),
        "stage": "H2",
        "targets": results,
    }


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-native-builder")
    parser.add_argument("--target", choices=sorted(TARGETS), default=None)
    parser.add_argument("--out-dir", default="dist/native")
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    result = build_target(args.target, out_dir) if args.target else build_all(out_dir)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
