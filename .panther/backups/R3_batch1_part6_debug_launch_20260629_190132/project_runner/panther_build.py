#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from tools.project_runner.runner import build_project


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a PantherLang project.")
    parser.add_argument("--project", default=".", help="Project root containing panther.toml")
    parser.add_argument("--output", default=None, help="Build output directory")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = build_project(args.project, args.output)
    if args.json:
        print(json.dumps({
            "ok": result.ok,
            "project": result.project,
            "output_dir": str(result.output_dir),
            "artifact": str(result.artifact),
            "files_written": result.files_written,
        }, indent=2))
    else:
        print(f"✅ Built PantherLang project: {result.project}")
        print(f"Artifact: {result.artifact}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
