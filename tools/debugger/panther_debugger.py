#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


class PantherDebugger:
    def __init__(self, source: Path):
        self.source = source
        self.lines = source.read_text(encoding="utf-8").splitlines()
        self.breakpoints: set[int] = set()

    def add_breakpoint(self, line: int) -> None:
        if line < 1 or line > len(self.lines):
            raise ValueError(f"Invalid breakpoint line: {line}")
        self.breakpoints.add(line)

    def trace(self) -> list[dict]:
        events = []
        for index, line in enumerate(self.lines, start=1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            events.append({
                "line": index,
                "source": stripped,
                "breakpoint": index in self.breakpoints
            })
        return events


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-debugger")
    parser.add_argument("source")
    parser.add_argument("--breakpoint", type=int, action="append", default=[])
    args = parser.parse_args()

    dbg = PantherDebugger(Path(args.source))
    for bp in args.breakpoint:
        dbg.add_breakpoint(bp)

    print(json.dumps({
        "ok": True,
        "phase": "8.9",
        "source": args.source,
        "breakpoints": sorted(dbg.breakpoints),
        "trace": dbg.trace()
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
