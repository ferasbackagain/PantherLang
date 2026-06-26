#!/usr/bin/env bash
set -euo pipefail

# PantherLang Phase 5.6 Professional
# AI Optimizing Compiler + Deterministic Optimization Passes + Strong Practical Test Suite

PHASE="5.6"
PROJECT_ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_ROOT/.phase_backups/phase5_6_pro_$STAMP"

echo "============================================================"
echo " PantherLang Phase 5.6 PRO - AI Optimizing Compiler"
echo "============================================================"
echo "[phase5.6] Project root: $PROJECT_ROOT"

fail(){ echo "[phase5.6][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }
require_dir(){ [ -d "$1" ] || fail "Required directory missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_dir "language"
require_dir "scripts"
require_dir "architecture"

for s in \
  scripts/verify_phase5_1_ai_native_core.sh \
  scripts/verify_phase5_2_intelligent_type_system.sh \
  scripts/verify_phase5_3_memory_context_engine.sh \
  scripts/verify_phase5_4_multi_agent_runtime.sh \
  scripts/verify_phase5_5_natural_language_programming.sh
do
  require_file "$s"
done

echo "[phase5.6] Verifying Phase 5.1 dependency..."
bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency.log
echo "[phase5.6] Verifying Phase 5.2 dependency..."
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency.log
echo "[phase5.6] Verifying Phase 5.3 dependency..."
bash scripts/verify_phase5_3_memory_context_engine.sh >/tmp/panther_phase5_3_dependency.log
echo "[phase5.6] Verifying Phase 5.4 dependency..."
bash scripts/verify_phase5_4_multi_agent_runtime.sh >/tmp/panther_phase5_4_dependency.log
echo "[phase5.6] Verifying Phase 5.5 dependency..."
bash scripts/verify_phase5_5_natural_language_programming.sh >/tmp/panther_phase5_5_dependency.log

mkdir -p "$BACKUP_DIR"
backup_if_exists(){ local t="$1"; if [ -e "$t" ]; then mkdir -p "$BACKUP_DIR/$(dirname "$t")"; cp -a "$t" "$BACKUP_DIR/$t"; fi; }

echo "[phase5.6] Creating backup at: $BACKUP_DIR"
for t in language/compiler/ai_optimizer language/ai/compiler architecture/AI_OPTIMIZING_COMPILER.md docs/phase5/PHASE_5_6_STATUS.md examples/compiler tests/phase5_6 scripts/verify_phase5_6_ai_optimizing_compiler.sh scripts/run_phase5_6_practical_demo.sh CHANGELOG.md; do
  backup_if_exists "$t"
done

echo "[phase5.6] Creating AI Optimizing Compiler directories..."
mkdir -p language/compiler/ai_optimizer/{core,passes,runtime,schemas,policies} language/ai/compiler architecture docs/phase5 examples/compiler tests/phase5_6 scripts

cat > architecture/AI_OPTIMIZING_COMPILER.md <<'MD'
# PantherLang Phase 5.6 — AI Optimizing Compiler

Phase 5.6 introduces a deterministic AI-aware optimizing compiler foundation.

## Mission

PantherLang must optimize source code using auditable compiler passes before any real AI-provider integration.

This phase creates local deterministic passes:

- constant folding
- dead print elimination
- simple let propagation
- AI hint generation
- optimization report generation
- practical compile/optimize demo
- negative tests for malformed source

## Rule

No phase is complete without practical proof.

Phase 5.6 includes structure, schema, runtime, optimization, negative, practical, and pytest/compile tests.
MD

cat > language/compiler/ai_optimizer/core/optimizer_manifest.json <<'JSON'
{
  "name": "PantherLang AI Optimizing Compiler",
  "phase": "5.6",
  "version": "0.5.6-ai-optimizing-compiler-pro",
  "status": "experimental-foundation",
  "depends_on": ["5.1", "5.2", "5.3", "5.4", "5.5"],
  "external_api_required": false,
  "features": [
    "constant_folding",
    "dead_print_elimination",
    "let_propagation",
    "ai_optimization_hints",
    "optimization_reports",
    "practical_demo",
    "negative_tests"
  ],
  "testing_standard": ["structure", "schema", "runtime", "optimization", "negative", "practical"]
}
JSON

cat > language/compiler/ai_optimizer/core/optimizer_types.panther <<'PAN'
# PantherLang AI Optimizing Compiler Types
# Phase 5.6 syntax foundation

type OptimizationPass = "constant_folding" | "dead_print_elimination" | "let_propagation" | "ai_hints"
type OptimizationLevel = "O0" | "O1" | "O2" | "AI"

type OptimizationReport {
  ok: Bool
  phase: String
  level: OptimizationLevel
  passes_applied: List<OptimizationPass>
  before_lines: Int
  after_lines: Int
  hints: List<String>
}
PAN

cat > language/ai/compiler/compiler_ai_types.panther <<'PAN'
# PantherLang AI Compiler Types
# Phase 5.6 AI-aware compiler foundation

type AIOptimizationHint {
  kind: String
  message: String
  confidence: Float
}

type AICompilerAnalysis {
  deterministic: Bool
  external_api_used: Bool
  hints: List<AIOptimizationHint>
}
PAN

cat > language/compiler/ai_optimizer/policies/default_optimizer.policy.json <<'JSON'
{
  "name": "default_optimizer",
  "phase": "5.6",
  "allow_network": false,
  "allow_external_ai": false,
  "allow_shell_execution": false,
  "require_deterministic_passes": true,
  "max_source_chars": 200000,
  "audit_required": true,
  "enabled_passes": [
    "constant_folding",
    "dead_print_elimination",
    "let_propagation",
    "ai_hints"
  ]
}
JSON

cat > language/compiler/ai_optimizer/schemas/optimization_report.schema.json <<'JSON'
{
  "title": "PantherLang Optimization Report",
  "phase": "5.6",
  "type": "object",
  "required": ["ok", "phase", "level", "passes_applied", "before_lines", "after_lines", "optimized_source", "hints", "external_api_used", "deterministic"],
  "properties": {
    "ok": { "type": "boolean" },
    "phase": { "type": "string" },
    "level": { "type": "string" },
    "passes_applied": { "type": "array", "items": { "type": "string" } },
    "before_lines": { "type": "number" },
    "after_lines": { "type": "number" },
    "optimized_source": { "type": "string" },
    "hints": { "type": "array", "items": { "type": "string" } },
    "external_api_used": { "type": "boolean" },
    "deterministic": { "type": "boolean" }
  }
}
JSON

cat > language/compiler/ai_optimizer/runtime/ai_optimizer.py <<'PY'
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
PY
chmod +x language/compiler/ai_optimizer/runtime/ai_optimizer.py

cat > examples/compiler/phase5_6_unoptimized.panther <<'PAN'
# PantherLang Phase 5.6 optimizer practical input

let x = 2 + 3 * 4
print x
print ""
PAN

cat > examples/compiler/phase5_6_practical_expected.txt <<'TXT'
demo=ai-optimizing-compiler
ok=true
external_api_used=false
deterministic=true
contains=let x = 14
contains=print 14
not_contains=print ""
TXT

cat > scripts/run_phase5_6_practical_demo.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

OUT_FILE="/tmp/panther_phase5_6_optimized_$$.panther"
OUT="$(python3 language/compiler/ai_optimizer/runtime/ai_optimizer.py demo --out "$OUT_FILE")"

python3 - "$OUT" "$OUT_FILE" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(sys.argv[1])
source = Path(sys.argv[2]).read_text()
assert data["phase"] == "5.6"
assert data["demo"] == "ai-optimizing-compiler"
assert data["ok"] is True
assert data["external_api_used"] is False
assert data["deterministic"] is True
assert "constant_folding" in data["passes_applied"]
assert "let_propagation" in data["passes_applied"]
assert "dead_print_elimination" in data["passes_applied"]
assert "let x = 14" in source
assert "print 14" in source
assert 'print ""' not in source
print("demo=ai-optimizing-compiler")
print("ok=true")
print("external_api_used=false")
print("deterministic=true")
print("contains=let x = 14")
print("contains=print 14")
print('not_contains=print ""')
PY

rm -f "$OUT_FILE"
SH
chmod +x scripts/run_phase5_6_practical_demo.sh

cat > tests/phase5_6/test_ai_optimizer.py <<'PY'
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "compiler" / "ai_optimizer" / "runtime" / "ai_optimizer.py"

def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(RUNTIME), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)

def test_demo_optimizer() -> None:
    code, data = run_cmd("demo")
    assert code == 0
    assert data["ok"] is True
    assert "let x = 14" in data["optimized_source"]
    assert "print 14" in data["optimized_source"]
    assert 'print ""' not in data["optimized_source"]

def test_negative_empty() -> None:
    code, data = run_cmd("negative", "--case", "empty")
    assert code == 2
    assert data["ok"] is False
    assert "Source cannot be empty" in data["error"]

def test_negative_unbalanced() -> None:
    code, data = run_cmd("negative", "--case", "unbalanced")
    assert code == 2
    assert data["ok"] is False
    assert "unbalanced braces" in data["error"]

def test_negative_unsafe() -> None:
    code, data = run_cmd("negative", "--case", "unsafe")
    assert code == 2
    assert data["ok"] is False
    assert "Unsafe optimizer marker blocked" in data["error"]
PY

cat > docs/phase5/PHASE_5_6_STATUS.md <<'MD'
# Phase 5.6 Status — AI Optimizing Compiler PRO

## Completed

- AI Optimizing Compiler architecture.
- Optimizer manifest.
- Optimizer type definitions.
- AI compiler type definitions.
- Default optimizer policy.
- Optimization report schema.
- Deterministic optimizer runtime.
- Constant folding.
- Let propagation.
- Dead print elimination.
- AI optimization hints.
- Practical optimizer demo.
- Negative tests.
- Pytest suite.
- Professional verification script.

## Next Phase

Phase 5.7 — Distributed Execution.
MD

cat > scripts/verify_phase5_6_ai_optimizing_compiler.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.6 PRO Verification"
echo "============================================================"

bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency_verify.log
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency_verify.log
bash scripts/verify_phase5_3_memory_context_engine.sh >/tmp/panther_phase5_3_dependency_verify.log
bash scripts/verify_phase5_4_multi_agent_runtime.sh >/tmp/panther_phase5_4_dependency_verify.log
bash scripts/verify_phase5_5_natural_language_programming.sh >/tmp/panther_phase5_5_dependency_verify.log

test -f architecture/AI_OPTIMIZING_COMPILER.md
test -f language/compiler/ai_optimizer/core/optimizer_manifest.json
test -f language/compiler/ai_optimizer/core/optimizer_types.panther
test -f language/ai/compiler/compiler_ai_types.panther
test -f language/compiler/ai_optimizer/policies/default_optimizer.policy.json
test -f language/compiler/ai_optimizer/schemas/optimization_report.schema.json
test -x language/compiler/ai_optimizer/runtime/ai_optimizer.py
test -f examples/compiler/phase5_6_unoptimized.panther
test -f examples/compiler/phase5_6_practical_expected.txt
test -x scripts/run_phase5_6_practical_demo.sh
test -f tests/phase5_6/test_ai_optimizer.py
test -f docs/phase5/PHASE_5_6_STATUS.md
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("language/compiler/ai_optimizer/core/optimizer_manifest.json").read_text())
assert m["phase"] == "5.6"
for dep in ["5.1","5.2","5.3","5.4","5.5"]:
    assert dep in m["depends_on"]
assert m["external_api_required"] is False
assert "constant_folding" in m["features"]
assert "negative_tests" in m["features"]
p = json.loads(Path("language/compiler/ai_optimizer/policies/default_optimizer.policy.json").read_text())
assert p["allow_network"] is False
assert p["allow_external_ai"] is False
assert p["require_deterministic_passes"] is True
s = json.loads(Path("language/compiler/ai_optimizer/schemas/optimization_report.schema.json").read_text())
for key in ["ok","phase","level","passes_applied","before_lines","after_lines","optimized_source","hints","external_api_used","deterministic"]:
    assert key in s["required"]
PY
echo "✅ schema tests passed"

OUT_FILE="/tmp/panther_phase5_6_verify_$$.panther"
OPT_JSON="$(python3 language/compiler/ai_optimizer/runtime/ai_optimizer.py optimize examples/compiler/phase5_6_unoptimized.panther --out "$OUT_FILE")"
echo "$OPT_JSON" | grep -q '"phase": "5.6"'
echo "$OPT_JSON" | grep -q '"ok": true'
echo "$OPT_JSON" | grep -q '"external_api_used": false'
echo "$OPT_JSON" | grep -q '"deterministic": true'
echo "✅ runtime optimizer tests passed"

grep -q 'let x = 14' "$OUT_FILE"
grep -q 'print 14' "$OUT_FILE"
if grep -q 'print ""' "$OUT_FILE"; then
  echo "[verify_phase5.6][ERROR] dead print was not eliminated"
  exit 1
fi
rm -f "$OUT_FILE"
echo "✅ optimization pass tests passed"

set +e
BAD_EMPTY="$(python3 language/compiler/ai_optimizer/runtime/ai_optimizer.py negative --case empty)"
BAD_EMPTY_CODE=$?
BAD_UNBAL="$(python3 language/compiler/ai_optimizer/runtime/ai_optimizer.py negative --case unbalanced)"
BAD_UNBAL_CODE=$?
BAD_UNSAFE="$(python3 language/compiler/ai_optimizer/runtime/ai_optimizer.py negative --case unsafe)"
BAD_UNSAFE_CODE=$?
set -e
if [ "$BAD_EMPTY_CODE" -ne 2 ] || [ "$BAD_UNBAL_CODE" -ne 2 ] || [ "$BAD_UNSAFE_CODE" -ne 2 ]; then
  echo "[verify_phase5.6][ERROR] negative tests must fail with exit code 2"
  exit 1
fi
echo "$BAD_EMPTY" | grep -q 'Source cannot be empty'
echo "$BAD_UNBAL" | grep -q 'unbalanced braces'
echo "$BAD_UNSAFE" | grep -q 'Unsafe optimizer marker blocked'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase5_6_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=ai-optimizing-compiler'
echo "$PRACTICAL_OUT" | grep -q 'ok=true'
echo "$PRACTICAL_OUT" | grep -q 'contains=let x = 14'
echo "$PRACTICAL_OUT" | grep -q 'contains=print 14'
echo "✅ practical AI optimizing compiler demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase5_6 >/tmp/panther_phase5_6_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile language/compiler/ai_optimizer/runtime/ai_optimizer.py
  echo "✅ python compile test passed"
fi

echo "✅ PantherLang Phase 5.6 AI Optimizing Compiler verification complete."
SH
chmod +x scripts/verify_phase5_6_ai_optimizing_compiler.sh

cat >> CHANGELOG.md <<'MD'

## Phase 5.6 — AI Optimizing Compiler PRO

Added deterministic AI-aware optimizing compiler foundation:

- optimizer manifest
- optimizer and AI compiler type definitions
- optimizer policy
- optimization report schema
- deterministic optimizer runtime
- constant folding
- let propagation
- dead print elimination
- AI hints
- practical optimization demo
- negative tests
- pytest suite
- professional verification gates

Phase 5.6 depends on Phase 5.1 through Phase 5.5.
MD

echo "[phase5.6] Running professional verification..."
bash scripts/verify_phase5_6_ai_optimizing_compiler.sh

echo "============================================================"
echo " Phase 5.6 COMPLETE"
echo " Next: Phase 5.7 Distributed Execution"
echo "============================================================"
