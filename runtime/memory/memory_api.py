#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from runtime.memory.memory_store import NativeMemoryStore, PantherMemoryError


def print_json(data: Any) -> None:
    print(json.dumps(data, indent=2, sort_keys=True))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-memory")
    sub = parser.add_subparsers(dest="cmd", required=True)

    demo_p = sub.add_parser("demo")
    set_p = sub.add_parser("set")
    set_p.add_argument("key")
    set_p.add_argument("value")
    get_p = sub.add_parser("get")
    get_p.add_argument("key")

    args = parser.parse_args(argv)
    store = NativeMemoryStore()

    try:
        if args.cmd == "demo":
            store.set("project", "PantherLang")
            store.set("phase", "7.2")
            result = {
                "ok": True,
                "phase": "7.2",
                "demo": "native-memory-model",
                "project": store.get("project"),
                "memory": store.snapshot(),
                "network_used": False,
                "external_api_used": False,
            }
            print_json(result)
            return 0

        if args.cmd == "set":
            cell = store.set(args.key, args.value)
            print_json({"ok": True, "phase": "7.2", "cell": cell.to_dict()})
            return 0

        if args.cmd == "get":
            print_json({"ok": True, "phase": "7.2", "value": store.get(args.key)})
            return 0

    except PantherMemoryError as exc:
        print_json({"ok": False, "phase": "7.2", "error": str(exc)})
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
