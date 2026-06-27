#!/usr/bin/env bash
set -euo pipefail

# PantherLang Phase 6.11 Professional
# Expressions Engine

PHASE="6.11"
ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase6_11_expressions_$STAMP"

echo "============================================================"
echo " PantherLang Phase 6.11 PRO - Expressions Engine"
echo "============================================================"
echo "[phase6.11] Project root: $ROOT"

fail(){ echo "[phase6.11][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_file "panther"
require_file "scripts/verify_phase5_all.sh"
require_file "scripts/verify_phase6_10_final_compiler_integration.sh"
require_file "compiler/pipeline/panther_compiler.py"

echo "[phase6.11] Verifying Phase 5 baseline..."
bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_11_phase5.log

echo "[phase6.11] Verifying Phase 6.10 baseline..."
bash scripts/verify_phase6_10_final_compiler_integration.sh >/tmp/panther_phase6_11_phase6_10.log

mkdir -p "$BACKUP_DIR"
backup_if_exists(){
  local t="$1"
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
}

for t in compiler/expressions compiler/pipeline/panther_compiler.py language/compiler/expressions architecture/EXPRESSIONS_ENGINE.md docs/phase6/PHASE_6_11_STATUS.md examples/phase6_expressions tests/phase6_11 scripts/verify_phase6_11_expressions_engine.sh scripts/run_phase6_11_practical_demo.sh CHANGELOG.md; do
  backup_if_exists "$t"
done

mkdir -p compiler/expressions language/compiler/expressions architecture docs/phase6 examples/phase6_expressions tests/phase6_11 scripts

cat > architecture/EXPRESSIONS_ENGINE.md <<'EOF'
# PantherLang Phase 6.11 — Expressions Engine

Adds deterministic expression support:
- arithmetic: + - * / %
- parentheses
- comparisons
- booleans
- strings
- variable lookup
- print expression evaluation

Rule: No Feature Without Proof.
EOF

cat > language/compiler/expressions/expressions_manifest.json <<'EOF'
{
  "name": "PantherLang Expressions Engine",
  "phase": "6.11",
  "version": "0.6.11-expressions-engine",
  "status": "compiler-language-feature",
  "depends_on": ["5.10", "6.10"],
  "external_api_required": false,
  "network_required": false,
  "features": [
    "integer_expressions",
    "arithmetic",
    "parentheses",
    "comparisons",
    "boolean_literals",
    "string_literals",
    "variable_lookup",
    "print_expression_evaluation",
    "negative_tests"
  ],
  "engineering_rule": "No Feature Without Proof"
}
EOF

cat > compiler/expressions/expression_engine.py <<'EOF'
#!/usr/bin/env python3
from __future__ import annotations

import ast
import operator
import re
from typing import Any


class PantherExpressionError(Exception):
    pass


class ExpressionEngine:
    BIN_OPS = {
        ast.Add: operator.add,
        ast.Sub: operator.sub,
        ast.Mult: operator.mul,
        ast.Div: operator.floordiv,
        ast.Mod: operator.mod,
    }

    CMP_OPS = {
        ast.Eq: operator.eq,
        ast.NotEq: operator.ne,
        ast.Lt: operator.lt,
        ast.LtE: operator.le,
        ast.Gt: operator.gt,
        ast.GtE: operator.ge,
    }

    def __init__(self, symbols: dict[str, Any] | None = None) -> None:
        self.symbols = symbols or {}

    def normalize(self, expr: str) -> str:
        expr = expr.strip()
        expr = re.sub(r"\btrue\b", "True", expr)
        expr = re.sub(r"\bfalse\b", "False", expr)
        return expr

    def evaluate(self, expr: str) -> Any:
        expr = self.normalize(expr)
        if not expr:
            raise PantherExpressionError("Expression cannot be empty")
        try:
            tree = ast.parse(expr, mode="eval")
            return self._eval(tree.body)
        except PantherExpressionError:
            raise
        except Exception as exc:
            raise PantherExpressionError(f"Invalid expression: {expr}") from exc

    def _eval(self, node: ast.AST) -> Any:
        if isinstance(node, ast.Constant):
            if isinstance(node.value, (int, str, bool)):
                return node.value
            raise PantherExpressionError("Unsupported constant type")

        if isinstance(node, ast.Name):
            if node.id in self.symbols:
                return self.symbols[node.id]
            raise PantherExpressionError(f"Undefined symbol: {node.id}")

        if isinstance(node, ast.UnaryOp) and isinstance(node.op, (ast.USub, ast.UAdd)):
            value = self._eval(node.operand)
            if not isinstance(value, int):
                raise PantherExpressionError("Unary operator requires integer")
            return -value if isinstance(node.op, ast.USub) else value

        if isinstance(node, ast.BinOp):
            op_type = type(node.op)
            if op_type not in self.BIN_OPS:
                raise PantherExpressionError("Unsupported binary operator")
            left = self._eval(node.left)
            right = self._eval(node.right)
            if not isinstance(left, int) or not isinstance(right, int):
                raise PantherExpressionError("Arithmetic requires integers")
            if isinstance(node.op, (ast.Div, ast.Mod)) and right == 0:
                raise PantherExpressionError("Division by zero")
            return self.BIN_OPS[op_type](left, right)

        if isinstance(node, ast.Compare):
            current = self._eval(node.left)
            result = True
            for op, comparator in zip(node.ops, node.comparators):
                op_type = type(op)
                if op_type not in self.CMP_OPS:
                    raise PantherExpressionError("Unsupported comparison operator")
                right = self._eval(comparator)
                result = result and self.CMP_OPS[op_type](current, right)
                current = right
            return result

        raise PantherExpressionError(f"Unsupported expression node: {type(node).__name__}")


def panther_format(value: Any) -> str:
    if value is True:
        return "true"
    if value is False:
        return "false"
    return str(value)
EOF

python3 - <<'PY'
from pathlib import Path

p = Path("compiler/pipeline/panther_compiler.py")
txt = p.read_text(encoding="utf-8")

if "from compiler.expressions.expression_engine import ExpressionEngine, PantherExpressionError, panther_format" not in txt:
    txt = txt.replace(
        "from typing import Any\n",
        "from typing import Any\n\nfrom compiler.expressions.expression_engine import ExpressionEngine, PantherExpressionError, panther_format\n"
    )

start = txt.index("    def semantic(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:")
end = txt.index("    def lower_to_ir(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:", start)
txt = txt[:start] + '''    def semantic(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:
        symbols: dict[str, Any] = {}
        diagnostics: list[dict[str, Any]] = []

        for node in ast_nodes:
            try:
                if node["kind"] == "Let":
                    name = node["name"]
                    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
                        diagnostics.append({
                            "level": "error",
                            "code": "PANTHER-COMPILER-001",
                            "message": f"Invalid variable name: {name}",
                            "line": node["line"]
                        })
                        continue
                    engine = ExpressionEngine(symbols)
                    value = engine.evaluate(node["value"])
                    node["evaluated_value"] = value
                    symbols[name] = value

                elif node["kind"] == "Print":
                    engine = ExpressionEngine(symbols)
                    value = engine.evaluate(node["value"])
                    node["evaluated_value"] = panther_format(value)

            except PantherExpressionError as exc:
                diagnostics.append({
                    "level": "error",
                    "code": "PANTHER-EXPR-001",
                    "message": str(exc),
                    "line": node.get("line", 0)
                })

        return diagnostics

''' + txt[end:]

start = txt.index("    def lower_to_ir(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:")
end = txt.index("    def backend(self, ir: list[dict[str, Any]]) -> str:", start)
txt = txt[:start] + '''    def lower_to_ir(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:
        ir: list[dict[str, Any]] = []
        for node in ast_nodes:
            if node["kind"] == "Print":
                ir.append({"op": "PRINT", "value": str(node.get("evaluated_value", node["value"]))})
            elif node["kind"] == "Let":
                ir.append({"op": "STORE", "name": node["name"], "value": str(node.get("evaluated_value", node["value"]))})
            elif node["kind"] == "AgentDecl":
                ir.append({"op": "DECLARE_AGENT", "source": node["source"]})
            elif node["kind"] == "MemoryDecl":
                ir.append({"op": "DECLARE_MEMORY", "source": node["source"]})
            elif node["kind"] == "PackageDecl":
                ir.append({"op": "DECLARE_PACKAGE", "source": node["source"]})
            elif node["kind"] == "IntentDecl":
                ir.append({"op": "DECLARE_INTENT", "source": node["source"]})
        return ir

''' + txt[end:]

p.write_text(txt, encoding="utf-8")
PY

cat > examples/phase6_expressions/expressions_demo.panther <<'EOF'
let a = 10
let b = 5
let sum = a + b
let product = (a + b) * 2
let ok = product == 30

print "Phase 6.11 expressions"
print sum
print product
print ok
EOF

cat > scripts/run_phase6_11_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

OUT="/tmp/panther_phase6_11_expr_artifact_$$.sh"
REPORT="$(./panther compile examples/phase6_expressions/expressions_demo.panther --out "$OUT")"

python3 - "$REPORT" "$OUT" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

report = json.loads(sys.argv[1])
out = Path(sys.argv[2])
assert report["ok"] is True
assert out.exists()

proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "Phase 6.11 expressions" in proc.stdout
assert "15" in proc.stdout
assert "30" in proc.stdout
assert "true" in proc.stdout

print("demo=phase6.11-expressions")
print("ok=true")
print("arithmetic=true")
print("comparisons=true")
print("variables=true")
print("artifact_runs=true")
PY

rm -f "$OUT"
EOF
chmod +x scripts/run_phase6_11_practical_demo.sh

cat > tests/phase6_11/test_expressions_engine.py <<'EOF'
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"


def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)


def test_expression_demo_compile_and_run(tmp_path: Path) -> None:
    out = tmp_path / "expr.sh"
    code, data = run_cmd("compile", "examples/phase6_expressions/expressions_demo.panther", "--out", str(out))
    assert code == 0
    assert data["ok"] is True
    proc = subprocess.run([str(out)], text=True, capture_output=True)
    assert proc.returncode == 0
    assert "15" in proc.stdout
    assert "30" in proc.stdout
    assert "true" in proc.stdout


def test_division_by_zero_fails(tmp_path: Path) -> None:
    src = tmp_path / "bad.panther"
    src.write_text("let x = 10 / 0\nprint x\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
    assert "Division by zero" in data["error"]


def test_undefined_symbol_fails(tmp_path: Path) -> None:
    src = tmp_path / "bad_symbol.panther"
    src.write_text("print missing_value\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad_symbol.sh"))
    assert code == 2
    assert data["ok"] is False
    assert "Undefined symbol" in data["error"]
EOF

cat > docs/phase6/PHASE_6_11_STATUS.md <<'EOF'
# Phase 6.11 Status — Expressions Engine PRO

Completed:
- deterministic expression evaluator
- arithmetic
- parentheses
- comparisons
- booleans
- strings
- variable lookup
- print expression evaluation
- practical demo
- negative tests
- pytest suite

Next: Phase 6.12 — Control Flow.
EOF

cat > scripts/verify_phase6_11_expressions_engine.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 6.11 PRO Expressions Verification"
echo "============================================================"

bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_11_phase5_regression.log
echo "✅ Phase 5 regression tests passed"

bash scripts/verify_phase6_10_final_compiler_integration.sh >/tmp/panther_phase6_11_phase6_10_regression.log
echo "✅ Phase 6.10 regression tests passed"

test -f architecture/EXPRESSIONS_ENGINE.md
test -f language/compiler/expressions/expressions_manifest.json
test -f compiler/expressions/expression_engine.py
test -f examples/phase6_expressions/expressions_demo.panther
test -x scripts/run_phase6_11_practical_demo.sh
test -f tests/phase6_11/test_expressions_engine.py
test -f docs/phase6/PHASE_6_11_STATUS.md
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("language/compiler/expressions/expressions_manifest.json").read_text())
assert m["phase"] == "6.11"
assert m["external_api_required"] is False
assert "arithmetic" in m["features"]
assert "comparisons" in m["features"]
assert "variable_lookup" in m["features"]
PY
echo "✅ manifest tests passed"

OUT="/tmp/panther_phase6_11_verify_expr_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_expressions/expressions_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "✅ compiler expression tests passed"

RUN_OUT="$("$OUT")"
echo "$RUN_OUT" | grep -q 'Phase 6.11 expressions'
echo "$RUN_OUT" | grep -q '^15$'
echo "$RUN_OUT" | grep -q '^30$'
echo "$RUN_OUT" | grep -q '^true$'
rm -f "$OUT"
echo "✅ emitted artifact expression execution tests passed"

TMP_BAD="/tmp/panther_phase6_11_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
let x = 10 / 0
print x
BAD

set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_expr.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_expr.sh

if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.11][ERROR] division by zero should fail"
  exit 1
fi
echo "$BAD_OUT" | grep -q 'Division by zero'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase6_11_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.11-expressions'
echo "$PRACTICAL_OUT" | grep -q 'arithmetic=true'
echo "$PRACTICAL_OUT" | grep -q 'comparisons=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical expressions demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_11 >/tmp/panther_phase6_11_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/expressions/expression_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi

echo "✅ PantherLang Phase 6.11 Expressions Engine verification complete."
EOF
chmod +x scripts/verify_phase6_11_expressions_engine.sh

cat > scripts/verify_phase6_all.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

bash scripts/verify_phase6_10_final_compiler_integration.sh
bash scripts/verify_phase6_11_expressions_engine.sh

echo "✅ ALL PHASE 6 TESTS PASSED THROUGH 6.11"
EOF
chmod +x scripts/verify_phase6_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 6.11 — Expressions Engine PRO

Added deterministic expression support:

- arithmetic expressions
- parentheses
- comparisons
- boolean literals
- string literals
- variable lookup
- print expression evaluation
- practical expressions demo
- negative/failure tests
- pytest suite
- professional verification gates

Next: Phase 6.12 Control Flow.
EOF

echo "[phase6.11] Running professional verification..."
bash scripts/verify_phase6_11_expressions_engine.sh

echo "============================================================"
echo " Phase 6.11 COMPLETE"
echo " Next: Phase 6.12 Control Flow"
echo "============================================================"
