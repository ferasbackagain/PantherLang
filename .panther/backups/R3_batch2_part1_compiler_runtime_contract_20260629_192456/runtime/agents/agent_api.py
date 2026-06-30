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

from runtime.agents.agent import PantherAgentError
from runtime.agents.agent_executor import AgentExecutor


def print_json(data: Any) -> None:
    print(json.dumps(data, indent=2, sort_keys=True))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-agent")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("demo")
    run_p = sub.add_parser("run")
    run_p.add_argument("name")
    run_p.add_argument("instruction")
    run_p.add_argument("--role", default="worker")
    run_p.add_argument("--goal", default="")

    args = parser.parse_args(argv)
    executor = AgentExecutor()

    try:
        if args.cmd == "demo":
            print_json(executor.demo())
            return 0

        if args.cmd == "run":
            executor.register_agent(args.name, role=args.role, goal=args.goal)
            print_json(executor.execute(args.name, args.instruction))
            return 0

    except PantherAgentError as exc:
        print_json({"ok": False, "phase": "7.3", "error": str(exc)})
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
