#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import zipapp
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

TARGETS = {
    "linux-x64": {"filename": "Panther", "kind": "posix"},
    "macos-arm64": {"filename": "Panther.command", "kind": "posix"},
    "windows-x64": {"filename": "Panther.cmd", "kind": "windows"},
}


def _create_zipapp_entry(out_dir: Path, standalone: bool = False) -> Path:
    """Create a zipapp-compatible __main__.py that invokes the CLI."""
    app_dir = out_dir / "_zipapp"
    app_dir.mkdir(parents=True, exist_ok=True)

    main_py = app_dir / "__main__.py"
    main_py.write_text(
        "import sys, os\n"
        "from pathlib import Path\n"
        "_this = Path(__file__).parent\n"
        "sys.path.insert(0, str(_this))\n"
        "os.environ.setdefault('PANTHER_HOME', str(_this))\n"
        "from cli.panther_cli import main_entry\n"
        "sys.exit(main_entry())\n",
        encoding="utf-8",
    )

    if not standalone:
        pth = app_dir / "panther.pth"
        pth.write_text(str(ROOT) + "\n", encoding="utf-8")
    else:
        _bundle_compiler(app_dir)

    return app_dir


def _bundle_compiler(app_dir: Path) -> None:
    """Copy the full compiler + cli tree into the zipapp directory."""
    for src_dir in ["compiler", "cli", "panther_core", "stdlib"]:
        src = ROOT / src_dir
        if src.is_dir():
            dst = app_dir / src_dir
            dst.mkdir(parents=True, exist_ok=True)
            for entry in src.rglob("*"):
                if entry.is_file() and entry.suffix == ".py":
                    rel = entry.relative_to(ROOT)
                    target = app_dir / rel
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text(entry.read_text(encoding="utf-8"), encoding="utf-8")
    (app_dir / "panther").write_text(
        "#!/usr/bin/env python3\nimport sys\nfrom cli.panther_cli import main_entry\nsys.exit(main_entry())\n",
        encoding="utf-8",
    )


def _build_zipapp(app_dir: Path, out_path: Path) -> None:
    """Build a self-contained zipapp executable."""
    zipapp.create_archive(str(app_dir), str(out_path), interpreter="/usr/bin/env python3")
    out_path.chmod(0o755)


def build_target(target: str, out_dir: Path, standalone: bool = False) -> dict:
    if target not in TARGETS:
        raise SystemExit(f"Unknown target: {target}")

    spec = TARGETS[target]
    target_dir = out_dir / target
    target_dir.mkdir(parents=True, exist_ok=True)
    artifact = target_dir / spec["filename"]

    zipapp_path = target_dir / "Panther.pyz"
    try:
        app_dir = _create_zipapp_entry(out_dir, standalone=standalone)
        _build_zipapp(app_dir, zipapp_path)
        zipapp_size = zipapp_path.stat().st_size
        shutil.rmtree(app_dir, ignore_errors=True)
    except Exception as e:
        zipapp_path = None
        zipapp_size = 0

    if spec["kind"] == "windows":
        panther_home = "%PANTHER_HOME%"
        artifact.write_text(
            "@echo off\r\n"
            f'set PANTHER_HOME=%~dp0\\..\\..\\\r\n'
            f'python "{panther_home}\\panther" %*\r\n',
            encoding="utf-8",
        )
    else:
        artifact.write_text(
            "#!/usr/bin/env bash\n"
            "set -euo pipefail\n"
            'SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\n'
            f'PYZ="$SCRIPT_DIR/Panther.pyz"\n'
            f'if [ -f "$PYZ" ]; then\n'
            f'  exec python3 "$PYZ" "$@"\n'
            f'fi\n'
            f'PANTHER_HOME="$(cd "$SCRIPT_DIR/../../.." && pwd)"\n'
            f'exec "$PANTHER_HOME/panther" "$@"\n',
            encoding="utf-8",
        )
        artifact.chmod(0o755)

    if zipapp_path:
        manifest = {
            "ok": True,
            "target": target,
            "artifact": str(artifact),
            "zipapp": str(zipapp_path),
            "zipapp_size_bytes": zipapp_size,
            "kind": spec["kind"],
            "mode": "zipapp + launcher",
        }
    else:
        manifest = {
            "ok": True,
            "target": target,
            "artifact": str(artifact),
            "zipapp": None,
            "kind": spec["kind"],
            "mode": "launcher (zipapp build failed, using fallback)",
        }

    (target_dir / "native.manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8"
    )
    return manifest


def build_all(out_dir: Path, standalone: bool = False) -> dict:
    results = [build_target(target, out_dir, standalone=standalone) for target in TARGETS]
    return {"ok": all(item["ok"] for item in results), "targets": results}


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-native-builder")
    parser.add_argument("--target", choices=sorted(TARGETS), default=None)
    parser.add_argument("--out-dir", default="dist/native")
    parser.add_argument("--standalone", action="store_true", help="Bundle all compiler code into the zipapp")
    args = parser.parse_args()
    out_dir = Path(args.out_dir)
    if args.target:
        result = build_target(args.target, out_dir, standalone=args.standalone)
    else:
        result = build_all(out_dir, standalone=args.standalone)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
