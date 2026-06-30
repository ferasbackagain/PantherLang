#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from tools.project_runner.runner import read_project_manifest


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare PantherLang debug launch metadata.")
    parser.add_argument("--project", default=".", help="Project root containing panther.toml")
    parser.add_argument("--program", default=None, help="Program to debug")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    manifest = read_project_manifest(args.project)
    program = Path(args.program).resolve() if args.program else manifest.main

    data = {
        "ok": True,
        "project": manifest.name,
        "type": manifest.kind,
        "program": str(program),
        "debug_adapter": "debug_adapter",
        "stage": "r3_debug_launch_scaffold",
        "note": "VS Code debug launch is wired; full runtime stepping continues in later R3 debug batches."
    }

    if args.json:
        print(json.dumps(data, indent=2))
    else:
        print(f"✅ PantherLang debug ready: {program}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
