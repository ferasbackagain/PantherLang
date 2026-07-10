#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

INDENT = "  "


def format_source(source: str) -> str:
    lines = source.splitlines()
    out: list[str] = []
    depth = 0

    for raw in lines:
        line = raw.rstrip()
        stripped = line.strip()

        if not stripped or stripped.startswith("#"):
            out.append(line)
            continue

        dedent = 0
        tokens = stripped.split()
        first = tokens[0] if tokens else ""

        if first in ("}", ");", "]") or first.startswith("}") or first.startswith(")"):
            dedent = 1
        if first in ("else", "elif"):
            dedent = 1

        depth = max(0, depth - dedent)
        out.append(INDENT * depth + stripped)

        if stripped.endswith("{") or stripped.endswith("(") or stripped.endswith("["):
            depth += 1
        if stripped.endswith("};"):
            depth = max(0, depth - 1)

    return "\n".join(out) + "\n" if out else ""


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-fmt", description="PantherLang code formatter")
    parser.add_argument("source", help="Panther source file to format")
    parser.add_argument("--write", action="store_true", help="Write formatted output back to file")
    args = parser.parse_args()

    src = Path(args.source)
    if not src.exists():
        print(f"error: file not found: {src}", file=sys.stderr)
        return 1

    text = src.read_text(encoding="utf-8")
    formatted = format_source(text)

    if args.write:
        src.write_text(formatted, encoding="utf-8")
        print(f"formatted:{src}")
    else:
        print(formatted, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
