#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ast
import json
import re
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any


class PantherOptimizerError(Exception):
    pass


@dataclass
class OptimizationReport:
    ok: bool
    phase: str
    level: str
    passes_applied: list[str]
    before_lines: int
    after_lines: int
    optimized_source: str
    hints: list[str]
    external_api_used: bool
    deterministic: bool


class DeterministicAIOptimizer:
    def validate(self, source: str) -> None:
        if not source.strip():
            raise PantherOptimizerError("Source cannot be empty")
        if "panic_unsafe_optimizer" in source:
            raise PantherOptimizerError("Unsafe optimizer marker blocked")
        balance = 0
        for ch in source:
            if ch == "{":
                balance += 1
            elif ch == "}":
                balance -= 1
            if balance < 0:
                raise PantherOptimizerError("Malformed source: unexpected closing brace")
        if balance != 0:
            raise PantherOptimizerError("Malformed source: unbalanced braces")

    def fold_expr(self, expr: str) -> str:
        expr = expr.strip()
        if not re.fullmatch(r"[0-9+\-*/% ().]+", expr):
            return expr
        try:
            tree = ast.parse(expr, mode="eval")
            allowed = (ast.Expression, ast.BinOp, ast.UnaryOp, ast.Constant, ast.Add, ast.Sub, ast.Mult, ast.Div, ast.Mod, ast.USub, ast.UAdd, ast.Load)
            if not all(isinstance(node, allowed) for node in ast.walk(tree)):
                return expr
            value = eval(compile(tree, "<panther-const-fold>", "eval"), {"__builtins__": {}}, {})
            if isinstance(value, float) and value.is_integer():
                return str(int(value))
            return str(value)
        except Exception:
            return expr

    def optimize(self, source: str, level: str = "AI") -> OptimizationReport:
        self.validate(source)
        original_lines = [line.rstrip() for line in source.splitlines()]
        lines = list(original_lines)
        passes: list[str] = []
        hints: list[str] = []

        # constant folding: let x = 2 + 3 * 4 -> let x = 14
        folded = []
        changed = False
        for line in lines:
            m = re.match(r"(\s*let\s+[A-Za-z_][A-Za-z0-9_]*\s*=\s*)([^#]+)$", line)
            if m:
                new_expr = self.fold_expr(m.group(2))
                new_line = m.group(1) + new_expr
                if new_line != line:
                    changed = True
                folded.append(new_line)
            else:
                folded.append(line)
        if changed:
            passes.append("constant_folding")
            lines = folded

        # let propagation for simple constants used in print
        constants: dict[str, str] = {}
        for line in lines:
            m = re.match(r"\s*let\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([0-9]+|\"[^\"]*\")\s*$", line)
            if m:
                constants[m.group(1)] = m.group(2)

        propagated = []
        changed = False
        for line in lines:
            m = re.match(r"(\s*print\s+)([A-Za-z_][A-Za-z0-9_]*)\s*$", line)
            if m and m.group(2) in constants:
                propagated.append(m.group(1) + constants[m.group(2)])
                changed = True
            else:
                propagated.append(line)
        if changed:
            passes.append("let_propagation")
            lines = propagated

        # dead print elimination: remove print "" and print null
        kept = []
        removed = 0
        for line in lines:
            if re.match(r'\s*print\s+""\s*$', line) or re.match(r"\s*print\s+null\s*$", line):
                removed += 1
                continue
            kept.append(line)
        if removed:
            passes.append("dead_print_elimination")
            lines = kept

        if "AI" in level or level in {"O2", "AI"}:
            passes.append("ai_hints")
            hints.append("AI hint: source is eligible for future semantic optimization.")
            if any("agent " in line for line in lines):
                hints.append("AI hint: multi-agent workflow detected; consider typed workflow validation.")
            if any("intent " in line for line in lines):
                hints.append("AI hint: natural-language intent detected; keep deterministic template audit.")

        optimized_source = "\n".join(lines).strip() + "\n"

        return OptimizationReport(
            ok=True,
            phase="5.6",
            level=level,
            passes_applied=passes,
            before_lines=len([l for l in original_lines if l.strip()]),
            after_lines=len([l for l in lines if l.strip()]),
            optimized_source=optimized_source,
            hints=hints,
            external_api_used=False,
            deterministic=True,
        )


def print_json(data: Any) -> None:
    print(json.dumps(data, ensure_ascii=False))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-ai-optimizer")
    sub = parser.add_subparsers(dest="cmd", required=True)

    opt = sub.add_parser("optimize")
    opt.add_argument("source")
    opt.add_argument("--level", default="AI")
    opt.add_argument("--out")

    demo = sub.add_parser("demo")
    demo.add_argument("--out")

    neg = sub.add_parser("negative")
    neg.add_argument("--case", choices=["empty", "unbalanced", "unsafe"], required=True)

    args = parser.parse_args(argv)
    optimizer = DeterministicAIOptimizer()

    try:
        if args.cmd == "optimize":
            src = Path(args.source).read_text(encoding="utf-8")
            report = optimizer.optimize(src, level=args.level)
            if args.out:
                Path(args.out).write_text(report.optimized_source, encoding="utf-8")
            print_json(asdict(report))
            return 0

        if args.cmd == "demo":
            src = 'let x = 2 + 3 * 4\nprint x\nprint ""\n'
            report = optimizer.optimize(src, level="AI")
            if args.out:
                Path(args.out).write_text(report.optimized_source, encoding="utf-8")
            print_json({
                "phase": "5.6",
                "demo": "ai-optimizing-compiler",
                "ok": report.ok,
                "optimized_source": report.optimized_source,
                "passes_applied": report.passes_applied,
                "external_api_used": False,
                "deterministic": True,
            })
            return 0

        if args.cmd == "negative":
            if args.case == "empty":
                optimizer.optimize("")
            elif args.case == "unbalanced":
                optimizer.optimize("fn bad() {\n print 1\n")
            elif args.case == "unsafe":
                optimizer.optimize("panic_unsafe_optimizer")

    except PantherOptimizerError as exc:
        print_json({
            "ok": False,
            "phase": "5.6",
            "error": str(exc),
            "external_api_used": False,
            "deterministic": True,
        })
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
