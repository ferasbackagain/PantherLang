#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Allow running as:
#   python3 tools/project_wizard/panther_new.py
# without requiring PYTHONPATH to be set.
PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from tools.project_wizard.wizard import available_templates, create_project


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a new PantherLang project.")
    parser.add_argument("name", help="Project name")
    parser.add_argument("--template", default="console", choices=available_templates())
    parser.add_argument("--destination", default=".")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = create_project(args.name, args.template, Path(args.destination))
    if args.json:
        print(json.dumps({
            "ok": True,
            "name": result.name,
            "template": result.template,
            "destination": str(result.destination),
            "files_created": result.files_created,
        }, indent=2))
    else:
        print(f"✅ Created PantherLang {result.template} project: {result.destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
