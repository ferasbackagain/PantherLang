#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from compiler.lexer import LexerError, lex_source


def main() -> int:
    parser = argparse.ArgumentParser(description="Lex PantherLang source and print tokens.")
    parser.add_argument("source_file")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    source = Path(args.source_file).read_text(encoding="utf-8")
    try:
        tokens = lex_source(source)
    except LexerError as exc:
        if args.json:
            print(json.dumps({"ok": False, "error": exc.message, "line": exc.location.line, "column": exc.location.column}, indent=2))
            return 1
        raise
    if args.json:
        print(json.dumps({"ok": True, "tokens": [
            {"kind": t.kind.value, "lexeme": t.lexeme, "literal": t.literal, "line": t.location.line, "column": t.location.column}
            for t in tokens
        ]}, indent=2))
    else:
        for t in tokens:
            print(f"{t.location.line}:{t.location.column} {t.kind.value} {t.lexeme!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
