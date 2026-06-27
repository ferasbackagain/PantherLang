#!/usr/bin/env python3
from __future__ import annotations
import sys
from pathlib import Path as _PantherPath
_PANTHER_ROOT = _PantherPath(__file__).resolve().parents[2]
if str(_PANTHER_ROOT) not in sys.path:
    sys.path.insert(0, str(_PANTHER_ROOT))


import argparse
import json
import re
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any

from compiler.expressions.expression_engine import ExpressionEngine, PantherExpressionError, panther_format
from compiler.control_flow.control_flow_engine import parse_if_blocks, evaluate_condition, PantherControlFlowError
from compiler.loops.loops_engine import parse_loop_blocks, validate_loop_range, PantherLoopError

class PantherCompileError(Exception):
    pass

@dataclass
class CompileReport:
    ok: bool
    phase: str
    source: str
    output: str
    stages: list[str]
    tokens: list[str]
    ast_nodes: list[dict[str, Any]]
    ir: list[dict[str, Any]]
    diagnostics: list[dict[str, Any]]
    external_api_used: bool
    network_used: bool
    deterministic: bool

class FinalCompilerPipeline:
    TOKEN_RE = re.compile(r'"[^"]*"|[A-Za-z_][A-Za-z0-9_]*|\d+|==|!=|<=|>=|[=+(){}.,;:-]')

    def lex(self, source: str) -> list[str]:
        tokens = self.TOKEN_RE.findall(source)
        if not tokens:
            raise PantherCompileError("No tokens produced")
        return tokens

    def parse(self, lines: list[str]) -> list[dict[str, Any]]:
        ast: list[dict[str, Any]] = []
        i = 0

        while i < len(lines):
            raw = lines[i]
            line = raw.strip()

            if not line or line.startswith("#"):
                i += 1
                continue

            if line.startswith("if "):
                if not line.endswith("{"):
                    raise PantherCompileError(f"Invalid if statement at line {i + 1}: missing '{{'")
                condition = line[len("if "):-1].strip()
                i += 1
                body = []
                closed = False
                while i < len(lines):
                    cur = lines[i].strip()
                    if cur == "}":
                        closed = True
                        i += 1
                        break
                    body.append(lines[i])
                    i += 1
                if not closed:
                    raise PantherCompileError("Unclosed if block")
                ast.append({
                    "kind": "If",
                    "line": i,
                    "condition": condition,
                    "then_ast": self.parse(body),
                    "else_ast": []
                })
                continue

            if line.startswith("for "):
                import re
                m = re.match(r"^for\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.+)\.\.(.+)\s*\{\s*$", line)
                if not m:
                    raise PantherCompileError(f"Invalid for loop at line {i + 1}")
                var, start_expr, end_expr = m.group(1), m.group(2).strip(), m.group(3).strip()
                i += 1
                body = []
                closed = False
                while i < len(lines):
                    cur = lines[i].strip()
                    if cur == "}":
                        closed = True
                        i += 1
                        break
                    body.append(lines[i])
                    i += 1
                if not closed:
                    raise PantherCompileError("Unclosed for loop block")
                ast.append({
                    "kind": "For",
                    "line": i,
                    "var": var,
                    "start_expr": start_expr,
                    "end_expr": end_expr,
                    "body_ast": self.parse(body)
                })
                continue

            if line.startswith("print "):
                ast.append({"kind": "Print", "line": i + 1, "value": line[len("print "):].strip()})
            elif line.startswith("let "):
                if "=" not in line:
                    raise PantherCompileError(f"Invalid let statement at line {i + 1}")
                name, value = line[len("let "):].split("=", 1)
                ast.append({"kind": "Let", "line": i + 1, "name": name.strip(), "value": value.strip()})
            elif line.startswith("agent "):
                ast.append({"kind": "AgentDecl", "line": i + 1, "source": line})
            elif line.startswith("memory "):
                ast.append({"kind": "MemoryDecl", "line": i + 1, "source": line})
            elif line.startswith("package "):
                ast.append({"kind": "PackageDecl", "line": i + 1, "source": line})
            elif line.startswith("intent "):
                ast.append({"kind": "IntentDecl", "line": i + 1, "source": line})
            else:
                raise PantherCompileError(f"Unsupported statement at line {i + 1}: {line}")

            i += 1

        if not ast:
            raise PantherCompileError("No AST nodes produced")
        return ast

    def semantic(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:
        symbols: dict[str, Any] = {}
        diagnostics: list[dict[str, Any]] = []
        def walk(nodes: list[dict[str, Any]]) -> None:
            for node in nodes:
                try:
                    if node["kind"] == "Let":
                        name = node["name"]
                        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
                            diagnostics.append({"level": "error", "code": "PANTHER-COMPILER-001", "message": f"Invalid variable name: {name}", "line": node["line"]})
                            continue
                        value = ExpressionEngine(symbols).evaluate(node["value"])
                        node["evaluated_value"] = value
                        symbols[name] = value
                    elif node["kind"] == "Print":
                        value = ExpressionEngine(symbols).evaluate(node["value"])
                        node["evaluated_value"] = panther_format(value)
                    elif node["kind"] == "If":
                        node["condition_value"] = evaluate_condition(node["condition"], symbols)
                        walk(node["then_ast"])
                        if node.get("else_ast"):
                            walk(node["else_ast"])
                    elif node["kind"] == "For":
                        start = ExpressionEngine(symbols).evaluate(node["start_expr"])
                        end = ExpressionEngine(symbols).evaluate(node["end_expr"])
                        start_i, end_i = validate_loop_range(start, end)
                        node["start_value"] = start_i
                        node["end_value"] = end_i
                        original = symbols.get(node["var"], None)
                        had_original = node["var"] in symbols
                        for loop_value in range(start_i, end_i + 1):
                            symbols[node["var"]] = loop_value
                            walk(node["body_ast"])
                        if had_original:
                            symbols[node["var"]] = original
                        elif node["var"] in symbols:
                            del symbols[node["var"]]
                except (PantherExpressionError, PantherControlFlowError, PantherLoopError) as exc:
                    diagnostics.append({"level": "error", "code": "PANTHER-LOOP-001", "message": str(exc), "line": node.get("line", 0)})
        walk(ast_nodes)
        return diagnostics

    def lower_to_ir(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:
        ir: list[dict[str, Any]] = []
        for node in ast_nodes:
            if node["kind"] == "Print":
                ir.append({"op": "PRINT", "value": str(node.get("evaluated_value", node["value"]))})
            elif node["kind"] == "Let":
                ir.append({"op": "STORE", "name": node["name"], "value": str(node.get("evaluated_value", node["value"]))})
            elif node["kind"] == "If":
                chosen = node["then_ast"] if node.get("condition_value") else node.get("else_ast", [])
                ir.append({"op": "IF", "condition": node["condition"], "condition_value": bool(node.get("condition_value")), "body_ir": self.lower_to_ir(chosen)})
            elif node["kind"] == "For":
                ir.append({"op": "FOR", "var": node["var"], "start": node["start_value"], "end": node["end_value"], "body_ir": self.lower_to_ir(node["body_ast"])})
            elif node["kind"] == "AgentDecl":
                ir.append({"op": "DECLARE_AGENT", "source": node["source"]})
            elif node["kind"] == "MemoryDecl":
                ir.append({"op": "DECLARE_MEMORY", "source": node["source"]})
            elif node["kind"] == "PackageDecl":
                ir.append({"op": "DECLARE_PACKAGE", "source": node["source"]})
            elif node["kind"] == "IntentDecl":
                ir.append({"op": "DECLARE_INTENT", "source": node["source"]})
        return ir

    def backend(self, ir: list[dict[str, Any]]) -> str:
        lines = ["#!/usr/bin/env bash", "set -euo pipefail", 'echo "PantherLang compiled artifact"']
        def emit(items: list[dict[str, Any]], indent: str = "") -> None:
            for item in items:
                if item["op"] == "PRINT":
                    value = item["value"]
                    safe = value.replace("\\", "\\\\").replace('"', '\"')
                    lines.append(f'{indent}echo "{safe}"')
                elif item["op"] == "STORE":
                    lines.append(f'{indent}# STORE {item["name"]} = {item["value"]}')
                elif item["op"] == "IF":
                    lines.append(f'{indent}# IF {item["condition"]} => {item["condition_value"]}')
                    emit(item["body_ir"], indent)
                elif item["op"] == "FOR":
                    lines.append(f'{indent}# FOR {item["var"]} in {item["start"]}..{item["end"]}')
                    for _ in range(int(item["start"]), int(item["end"]) + 1):
                        emit(item["body_ir"], indent)
                else:
                    lines.append(f'{indent}# {item["op"]}: {item.get("source", "")}')
        emit(ir)
        return "\n".join(lines) + "\n"

    def compile(self, source_path: Path, out_path: Path) -> CompileReport:
        if not source_path.exists():
            raise PantherCompileError(f"Source file not found: {source_path}")
        source = source_path.read_text(encoding="utf-8")
        if "panic_compiler" in source:
            raise PantherCompileError("Compiler panic marker blocked")
        if not source.strip():
            raise PantherCompileError("Source cannot be empty")
        stages = ["lex", "parse", "semantic", "ir", "backend", "emit"]
        tokens = self.lex(source)
        ast_nodes = self.parse(source.splitlines())
        diagnostics = self.semantic(ast_nodes)
        if any(d["level"] == "error" for d in diagnostics):
            raise PantherCompileError(diagnostics[0]["message"])
        ir = self.lower_to_ir(ast_nodes)
        artifact = self.backend(ir)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(artifact, encoding="utf-8")
        out_path.chmod(0o755)
        return CompileReport(True, "6.10", str(source_path), str(out_path), stages, tokens, ast_nodes, ir, diagnostics, False, False, True)

def print_json(data: Any) -> None:
    print(json.dumps(data, ensure_ascii=False))

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-compiler")
    sub = parser.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("compile")
    c.add_argument("source")
    c.add_argument("--out", default="build/panther_program.sh")
    d = sub.add_parser("demo")
    d.add_argument("--out", default="/tmp/panther_phase6_10_demo_program.sh")
    n = sub.add_parser("negative")
    n.add_argument("--case", choices=["missing", "empty", "unsupported", "panic"], required=True)
    args = parser.parse_args(argv)
    pipeline = FinalCompilerPipeline()
    try:
        if args.cmd == "compile":
            print_json(asdict(pipeline.compile(Path(args.source), Path(args.out))))
            return 0
        if args.cmd == "demo":
            src = Path("/tmp/panther_phase6_10_demo.panther")
            src.write_text('let name = "Panther"\nprint "Phase 6.10 compiler integration works"\n', encoding="utf-8")
            report = pipeline.compile(src, Path(args.out))
            print_json({"phase": "6.10", "demo": "final-compiler-integration", "ok": report.ok, "output": report.output, "stages": report.stages, "external_api_used": False, "network_used": False, "deterministic": True})
            return 0
        if args.cmd == "negative":
            if args.case == "missing":
                pipeline.compile(Path("/tmp/does_not_exist.panther"), Path("/tmp/out.sh"))
            elif args.case == "empty":
                src = Path("/tmp/panther_empty.panther"); src.write_text("", encoding="utf-8"); pipeline.compile(src, Path("/tmp/out.sh"))
            elif args.case == "unsupported":
                src = Path("/tmp/panther_unsupported.panther"); src.write_text("unsupported syntax here\n", encoding="utf-8"); pipeline.compile(src, Path("/tmp/out.sh"))
            elif args.case == "panic":
                src = Path("/tmp/panther_panic.panther"); src.write_text("panic_compiler\n", encoding="utf-8"); pipeline.compile(src, Path("/tmp/out.sh"))
    except (PantherCompileError, PantherControlFlowError, PantherLoopError) as exc:
        print_json({"ok": False, "phase": "6.10", "error": str(exc), "external_api_used": False, "network_used": False, "deterministic": True})
        return 2
    return 1

if __name__ == "__main__":
    raise SystemExit(main())
