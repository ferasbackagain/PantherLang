#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


KEYWORDS = {
    "module", "import", "struct", "fn", "let", "if", "else", "elif",
    "for", "while", "loop", "break", "continue", "return", "print",
    "assert", "trait", "enum", "const", "agent", "runtime", "memory",
    "intent", "true", "false", "null", "and", "or", "not", "in",
}


def diagnostics(source: str) -> list[dict]:
    items: list[dict] = []
    stack: list[tuple[int, str]] = []
    lines = source.splitlines()
    for lineno, line in enumerate(lines, start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.endswith("{"):
            stack.append((lineno, "{"))
        if stripped == "}" or stripped.startswith("}"):
            if stack:
                stack.pop()
            else:
                items.append({
                    "line": lineno,
                    "severity": "error",
                    "message": "Unexpected closing brace",
                })
        if stripped.startswith("let ") and "=" not in stripped:
            items.append({
                "line": lineno,
                "severity": "error",
                "message": "Invalid let statement: missing '='",
            })
        if stripped.startswith("fn ") and not stripped.endswith("{"):
            items.append({
                "line": lineno,
                "severity": "warning",
                "message": "Function declaration should end with '{'",
            })
    for lineno, _ in stack:
        items.append({
            "line": lineno,
            "severity": "error",
            "message": "Unclosed block",
        })
    return items


def completions(prefix: str = "") -> list[str]:
    return sorted(k for k in KEYWORDS if k.startswith(prefix))


def hover(word: str) -> dict:
    docs = {
        "module": "Declares a PantherLang module. Usage: `module name;`",
        "import": "Imports another Panther module.",
        "struct": "Declares a structured data type with named fields.",
        "fn": "Declares a function. Usage: `fn name(params) { body }`",
        "let": "Declares a variable with optional type annotation.",
        "if": "Conditional branch: `if cond { ... } else { ... }`",
        "for": "Iteration: `for i in iterable { ... }`",
        "while": "Conditional loop: `while cond { ... }`",
        "loop": "Infinite loop with `break`/`continue` support.",
        "return": "Returns a value from a function.",
        "print": "Prints a value to stdout.",
        "trait": "Declares a trait (interface).",
        "enum": "Declares an enumeration type.",
        "const": "Declares a compile-time constant.",
        "true": "Boolean literal `true`.",
        "false": "Boolean literal `false`.",
        "null": "Null literal.",
    }
    return {"word": word, "description": docs.get(word, "PantherLang symbol")}


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-lsp", description="PantherLang LSP CLI")
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
