#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass
class Diagnostic:
    level: str
    code: str
    message: str
    line: int

    def to_dict(self) -> dict[str, Any]:
        return {
            "level": self.level,
            "code": self.code,
            "message": self.message,
            "line": self.line,
        }


class PantherTypeAnalyzer:
    """Deterministic Phase 5.2 static type analyzer prototype."""

    def __init__(self) -> None:
        self.symbols: dict[str, str] = {}
        self.diagnostics: list[Diagnostic] = []

    def infer_literal(self, expr: str) -> str:
        expr = expr.strip()
        if re.fullmatch(r"-?\d+", expr):
            return "Int"
        if re.fullmatch(r"-?\d+\.\d+", expr):
            return "Float"
        if re.fullmatch(r'"(?:\\.|[^"\\])*"', expr):
            return "String"
        if expr in {"true", "false"}:
            return "Bool"
        if expr == "null":
            return "Null"
        if expr.startswith("Ok("):
            return "Result<Inferred, InferredError>"
        if expr.startswith("Err("):
            return "Result<InferredOk, Inferred>"
        if expr.startswith("Some("):
            return "Option<Inferred>"
        if expr == "None":
            return "Option<Never>"
        return self.symbols.get(expr, "Unknown")

    def compatible(self, declared: str, inferred: str) -> bool:
        if declared in {"Any", inferred}:
            return True
        if declared.startswith("Nullable<") and inferred == "Null":
            return True
        if "|" in declared:
            return inferred in [part.strip() for part in declared.split("|")]
        if declared.startswith("Option<") and inferred.startswith("Option<"):
            return True
        if declared.startswith("Result<") and inferred.startswith("Result<"):
            return True
        return False

    def analyze_line(self, line: str, number: int) -> None:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            return

        typed_let = re.match(r"let\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^=]+?)\s*=\s*(.+)$", stripped)
        if typed_let:
            name, declared, expr = typed_let.groups()
            declared = declared.strip()
            inferred = self.infer_literal(expr)
            self.symbols[name] = declared
            if not self.compatible(declared, inferred):
                self.diagnostics.append(
                    Diagnostic(
                        "error",
                        "PANTHER-TYPE-001",
                        f"{name} declared as {declared} but expression inferred as {inferred}",
                        number,
                    )
                )
            return

        untyped_let = re.match(r"let\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$", stripped)
        if untyped_let:
            name, expr = untyped_let.groups()
            self.symbols[name] = self.infer_literal(expr)
            return

        if "ai.generate" in stripped and "PromptContract" not in stripped:
            self.diagnostics.append(
                Diagnostic(
                    "warning",
                    "PANTHER-AI-TYPE-001",
                    "ai.generate should be backed by PromptContract<TInput,TOutput>",
                    number,
                )
            )

    def analyze(self, source: str) -> dict[str, Any]:
        for idx, line in enumerate(source.splitlines(), start=1):
            self.analyze_line(line, idx)

        return {
            "phase": "5.2",
            "symbols": self.symbols,
            "diagnostics": [d.to_dict() for d in self.diagnostics],
            "ok": not any(d.level == "error" for d in self.diagnostics),
        }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-type-analyzer")
    parser.add_argument("source", help="Path to Panther source file")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args(argv)

    path = Path(args.source)
    if not path.exists():
        raise SystemExit(f"Source file not found: {path}")

    result = PantherTypeAnalyzer().analyze(path.read_text(encoding="utf-8"))
    print(json.dumps(result, indent=2 if args.pretty else None, ensure_ascii=False))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
