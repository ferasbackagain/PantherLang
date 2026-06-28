#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


KEYWORDS = {
    "module", "import", "struct", "fn", "let", "if", "for", "print",
    "agent", "runtime", "package", "memory", "intent"
}


def diagnostics(source: str) -> list[dict]:
    items = []
    stack = []
    for lineno, line in enumerate(source.splitlines(), start=1):
        stripped = line.strip()
        if stripped.endswith("{"):
            stack.append((lineno, "{"))
        if stripped == "}":
            if stack:
                stack.pop()
            else:
                items.append({
                    "line": lineno,
                    "severity": "error",
                    "message": "Unexpected closing brace"
                })
        if stripped.startswith("let ") and "=" not in stripped:
            items.append({
                "line": lineno,
                "severity": "error",
                "message": "Invalid let statement: missing '='"
            })
    for lineno, _ in stack:
        items.append({
            "line": lineno,
            "severity": "error",
            "message": "Unclosed block"
        })
    return items


def completions(prefix: str = "") -> list[str]:
    return sorted(k for k in KEYWORDS if k.startswith(prefix))


def hover(word: str) -> dict:
    docs = {
        "module": "Declares a PantherLang module.",
        "import": "Imports another Panther module.",
        "struct": "Declares a structured data type.",
        "fn": "Declares a function.",
        "let": "Declares a variable.",
        "print": "Prints a value.",
        "agent": "Declares an AI agent.",
        "runtime": "Declares runtime behavior."
    }
    return {"word": word, "description": docs.get(word, "PantherLang symbol")}


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-lsp")
    sub = parser.add_subparsers(dest="cmd", required=True)

    diag = sub.add_parser("diagnostics")
    diag.add_argument("source")

    comp = sub.add_parser("completions")
    comp.add_argument("--prefix", default="")

    hov = sub.add_parser("hover")
    hov.add_argument("word")

    args = parser.parse_args()

    if args.cmd == "diagnostics":
        src = Path(args.source).read_text(encoding="utf-8")
        print(json.dumps({"ok": True, "diagnostics": diagnostics(src)}, indent=2))
        return 0

    if args.cmd == "completions":
        print(json.dumps({"ok": True, "items": completions(args.prefix)}, indent=2))
        return 0

    if args.cmd == "hover":
        print(json.dumps({"ok": True, "hover": hover(args.word)}, indent=2))
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
