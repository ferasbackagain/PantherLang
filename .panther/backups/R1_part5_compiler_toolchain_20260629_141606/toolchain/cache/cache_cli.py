#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from toolchain.cache.build_cache import BuildCache


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-cache")
    sub = parser.add_subparsers(dest="cmd", required=True)

    status_p = sub.add_parser("status")
    status_p.add_argument("source")
    status_p.add_argument("--profile", default="debug")

    update_p = sub.add_parser("update")
    update_p.add_argument("source")
    update_p.add_argument("--profile", default="debug")
    update_p.add_argument("--artifact", default=None)

    sub.add_parser("clear")

    args = parser.parse_args()
    cache = BuildCache(Path.cwd())

    if args.cmd == "status":
        print(json.dumps(cache.status(Path(args.source), args.profile), indent=2, sort_keys=True))
        return 0

    if args.cmd == "update":
        print(json.dumps(cache.update(Path(args.source), args.profile, args.artifact), indent=2, sort_keys=True))
        return 0

    if args.cmd == "clear":
        print(json.dumps(cache.clear(), indent=2, sort_keys=True))
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
