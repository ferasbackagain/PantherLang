#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import json
from typing import Any

from runtime.ai_runtime.ai_runtime import PantherAIRuntime, PantherAIRuntimeError


def _json_safe(value: Any) -> Any:
    if isinstance(value, dict):
        return {str(k): _json_safe(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_json_safe(v) for v in value]
    if isinstance(value, tuple):
        return [_json_safe(v) for v in value]
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    if hasattr(value, "to_dict"):
        return _json_safe(value.to_dict())
    if hasattr(value, "__dict__"):
        return _json_safe(value.__dict__)
    return str(value)


def print_json(data: Any) -> None:
    print(json.dumps(_json_safe(data), indent=2, sort_keys=True))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-runtime")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("start")
    exec_p = sub.add_parser("execute")
    exec_p.add_argument("instruction")
    sub.add_parser("demo")
    sub.add_parser("status")

    args = parser.parse_args(argv)

    try:
        runtime = PantherAIRuntime()

        if args.cmd == "start":
            print_json(runtime.initialize())
            return 0

        if args.cmd == "execute":
            runtime.initialize()
            print_json(runtime.execute(args.instruction))
            runtime.shutdown()
            return 0

        if args.cmd == "demo":
            runtime.initialize()
            result = runtime.execute("phase7.1.demo")
            status = runtime.shutdown()
            print_json({
                "ok": True,
                "phase": "7.1",
                "demo": "ai-runtime-foundation",
                "execute_result": result,
                "shutdown_status": status,
                "network_used": False,
                "external_api_used": False,
            })
            return 0

        if args.cmd == "status":
            print_json(runtime.status())
            return 0

    except PantherAIRuntimeError as exc:
        print_json({
            "ok": False,
            "phase": "7.1",
            "error": str(exc),
            "network_used": False,
            "external_api_used": False,
        })
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
