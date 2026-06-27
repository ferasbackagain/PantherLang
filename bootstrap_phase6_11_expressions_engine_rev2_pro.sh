#!/usr/bin/env bash
set -euo pipefail
ROOT="$(pwd)"
echo "============================================================"
echo " PantherLang Phase 6.11 Rev2 PRO - Expressions Engine Fix"
echo "============================================================"
echo "[phase6.11-rev2] Project root: $ROOT"

fail(){ echo "[phase6.11-rev2][ERROR] $1" >&2; exit 1; }
[ -f panther ] || fail "Run from PantherLang project root"
[ -f compiler/pipeline/panther_compiler.py ] || fail "compiler/pipeline/panther_compiler.py missing"
[ -f scripts/verify_phase6_10_final_compiler_integration.sh ] || fail "Phase 6.10 verifier missing"

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase6_11_rev2_$STAMP"
mkdir -p "$BACKUP_DIR"
for t in compiler language/compiler/expressions architecture/EXPRESSIONS_ENGINE.md docs/phase6/PHASE_6_11_STATUS.md examples/phase6_expressions tests/phase6_11 scripts/verify_phase6_11_expressions_engine.sh scripts/run_phase6_11_practical_demo.sh scripts/verify_phase6_all.sh CHANGELOG.md; do
  if [ -e "$t" ]; then mkdir -p "$BACKUP_DIR/$(dirname "$t")"; cp -a "$t" "$BACKUP_DIR/$t"; fi
done

bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_11_rev2_phase5.log
bash scripts/verify_phase6_10_final_compiler_integration.sh >/tmp/panther_phase6_11_rev2_phase610.log

mkdir -p compiler/expressions compiler/pipeline language/compiler/expressions architecture docs/phase6 examples/phase6_expressions tests/phase6_11 scripts
touch compiler/__init__.py compiler/expressions/__init__.py compiler/pipeline/__init__.py

cat > architecture/EXPRESSIONS_ENGINE.md <<'EOF'
# PantherLang Phase 6.11 Rev2 — Expressions Engine

Adds deterministic expression support: arithmetic, parentheses, comparisons, booleans, strings, variables, and print expression evaluation.

Engineering rule: No Feature Without Proof.
EOF

cat > language/compiler/expressions/expressions_manifest.json <<'EOF'
{
  "name": "PantherLang Expressions Engine Rev2",
  "phase": "6.11-rev2",
  "version": "0.6.11-rev2-expressions-engine",
  "status": "compiler-language-feature",
  "depends_on": ["5.10", "6.10"],
  "external_api_required": false,
  "network_required": false,
  "features": ["arithmetic", "parentheses", "comparisons", "boolean_literals", "string_literals", "variable_lookup", "print_expression_evaluation", "negative_tests"],
  "engineering_rule": "No Feature Without Proof"
}
EOF

cat > compiler/expressions/expression_engine.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations
import ast, operator, re
from typing import Any

class PantherExpressionError(Exception):
    pass

class ExpressionEngine:
    BIN_OPS = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul, ast.Div: operator.floordiv, ast.Mod: operator.mod}
    CMP_OPS = {ast.Eq: operator.eq, ast.NotEq: operator.ne, ast.Lt: operator.lt, ast.LtE: operator.le, ast.Gt: operator.gt, ast.GtE: operator.ge}
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
            return self._eval(ast.parse(expr, mode="eval").body)
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
            v = self._eval(node.operand)
            if not isinstance(v, int): raise PantherExpressionError("Unary operator requires integer")
            return -v if isinstance(node.op, ast.USub) else v
        if isinstance(node, ast.BinOp):
            op = type(node.op)
            if op not in self.BIN_OPS: raise PantherExpressionError("Unsupported binary operator")
            l, r = self._eval(node.left), self._eval(node.right)
            if not isinstance(l, int) or not isinstance(r, int): raise PantherExpressionError("Arithmetic requires integers")
            if isinstance(node.op, (ast.Div, ast.Mod)) and r == 0: raise PantherExpressionError("Division by zero")
            return self.BIN_OPS[op](l, r)
        if isinstance(node, ast.Compare):
            current = self._eval(node.left); result = True
            for op, comp in zip(node.ops, node.comparators):
                opt = type(op)
                if opt not in self.CMP_OPS: raise PantherExpressionError("Unsupported comparison operator")
                right = self._eval(comp); result = result and self.CMP_OPS[opt](current, right); current = right
            return result
        raise PantherExpressionError(f"Unsupported expression node: {type(node).__name__}")

def panther_format(value: Any) -> str:
    if value is True: return "true"
    if value is False: return "false"
    return str(value)
PY
chmod +x compiler/expressions/expression_engine.py

python3 - <<'PY'
from pathlib import Path
p = Path('compiler/pipeline/panther_compiler.py')
txt = p.read_text()
imp = 'from compiler.expressions.expression_engine import ExpressionEngine, PantherExpressionError, panther_format\n'
if imp not in txt:
    txt = txt.replace('from typing import Any\n', 'from typing import Any\n\n' + imp)
sem_sig = '    def semantic(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:'
low_sig = '    def lower_to_ir(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:'
back_sig = '    def backend(self, ir: list[dict[str, Any]]) -> str:'
s = txt.find(sem_sig); l = txt.find(low_sig, s)
if s < 0 or l < 0: raise SystemExit('compiler methods not found')
new_sem = '''    def semantic(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:\n        symbols: dict[str, Any] = {}\n        diagnostics: list[dict[str, Any]] = []\n        for node in ast_nodes:\n            try:\n                if node["kind"] == "Let":\n                    name = node["name"]\n                    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):\n                        diagnostics.append({"level":"error","code":"PANTHER-COMPILER-001","message":f"Invalid variable name: {name}","line":node["line"]})\n                        continue\n                    value = ExpressionEngine(symbols).evaluate(node["value"])\n                    node["evaluated_value"] = value\n                    symbols[name] = value\n                elif node["kind"] == "Print":\n                    value = ExpressionEngine(symbols).evaluate(node["value"])\n                    node["evaluated_value"] = panther_format(value)\n            except PantherExpressionError as exc:\n                diagnostics.append({"level":"error","code":"PANTHER-EXPR-001","message":str(exc),"line":node.get("line",0)})\n        return diagnostics\n\n'''
txt = txt[:s] + new_sem + txt[l:]
l = txt.find(low_sig); b = txt.find(back_sig, l)
if l < 0 or b < 0: raise SystemExit('compiler methods not found after patch')
new_low = '''    def lower_to_ir(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:\n        ir: list[dict[str, Any]] = []\n        for node in ast_nodes:\n            if node["kind"] == "Print":\n                ir.append({"op":"PRINT","value":str(node.get("evaluated_value", node["value"]))})\n            elif node["kind"] == "Let":\n                ir.append({"op":"STORE","name":node["name"],"value":str(node.get("evaluated_value", node["value"]))})\n            elif node["kind"] == "AgentDecl":\n                ir.append({"op":"DECLARE_AGENT","source":node["source"]})\n            elif node["kind"] == "MemoryDecl":\n                ir.append({"op":"DECLARE_MEMORY","source":node["source"]})\n            elif node["kind"] == "PackageDecl":\n                ir.append({"op":"DECLARE_PACKAGE","source":node["source"]})\n            elif node["kind"] == "IntentDecl":\n                ir.append({"op":"DECLARE_INTENT","source":node["source"]})\n        return ir\n\n'''
txt = txt[:l] + new_low + txt[b:]
p.write_text(txt)
print('✅ compiler pipeline patched for expressions')
PY

python3 -m py_compile compiler/expressions/expression_engine.py
python3 -m py_compile compiler/pipeline/panther_compiler.py

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
import json, subprocess, sys
from pathlib import Path
r=json.loads(sys.argv[1]); out=Path(sys.argv[2]); assert r['ok'] and out.exists()
p=subprocess.run([str(out)], text=True, capture_output=True); assert p.returncode==0
for x in ['Phase 6.11 expressions','15','30','true']: assert x in p.stdout
print('demo=phase6.11-rev2-expressions')
print('ok=true')
print('arithmetic=true')
print('comparisons=true')
print('variables=true')
print('artifact_runs=true')
PY
rm -f "$OUT"
EOF
chmod +x scripts/run_phase6_11_practical_demo.sh

cat > tests/phase6_11/test_expressions_engine.py <<'EOF'
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
COMPILER=ROOT/'compiler'/'pipeline'/'panther_compiler.py'
def run_cmd(*args: str):
    p=subprocess.run([sys.executable,str(COMPILER),*args],cwd=ROOT,text=True,capture_output=True)
    return p.returncode,json.loads(p.stdout)
def test_expression_demo_compile_and_run(tmp_path: Path):
    out=tmp_path/'expr.sh'; code,data=run_cmd('compile','examples/phase6_expressions/expressions_demo.panther','--out',str(out))
    assert code==0 and data['ok']; p=subprocess.run([str(out)],text=True,capture_output=True); assert '15' in p.stdout and '30' in p.stdout and 'true' in p.stdout
def test_division_by_zero_fails(tmp_path: Path):
    src=tmp_path/'bad.panther'; src.write_text('let x = 10 / 0\nprint x\n')
    code,data=run_cmd('compile',str(src),'--out',str(tmp_path/'bad.sh')); assert code==2 and 'Division by zero' in data['error']
def test_undefined_symbol_fails(tmp_path: Path):
    src=tmp_path/'bad_symbol.panther'; src.write_text('print missing_value\n')
    code,data=run_cmd('compile',str(src),'--out',str(tmp_path/'bad_symbol.sh')); assert code==2 and 'Undefined symbol' in data['error']
EOF

cat > docs/phase6/PHASE_6_11_STATUS.md <<'EOF'
# Phase 6.11 Rev2 Status — Expressions Engine PRO

Completed: expression engine, arithmetic, comparisons, variables, print expression evaluation, negative tests, practical demo.

Next: Phase 6.12 — Control Flow.
EOF

cat > scripts/verify_phase6_11_expressions_engine.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.11 Rev2 PRO Expressions Verification"
echo "============================================================"
bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_11_phase5_regression.log
echo "✅ Phase 5 regression tests passed"
bash scripts/verify_phase6_10_final_compiler_integration.sh >/tmp/panther_phase6_11_phase6_10_regression.log
echo "✅ Phase 6.10 regression tests passed"
test -f compiler/expressions/expression_engine.py
test -f examples/phase6_expressions/expressions_demo.panther
test -x scripts/run_phase6_11_practical_demo.sh
echo "✅ structure tests passed"
python3 - <<'PY'
from compiler.expressions.expression_engine import ExpressionEngine, panther_format
e=ExpressionEngine({'a':10,'b':5}); assert e.evaluate('a + b')==15; assert e.evaluate('(a + b) * 2')==30; assert e.evaluate('30 == 30') is True; assert panther_format(False)=='false'
PY
echo "✅ import/self tests passed"
OUT="/tmp/panther_phase6_11_verify_expr_$$.sh"
./panther compile examples/phase6_expressions/expressions_demo.panther --out "$OUT" | grep -q '"ok": true'
echo "✅ compiler expression tests passed"
RUN_OUT="$($OUT)"
echo "$RUN_OUT" | grep -q 'Phase 6.11 expressions'
echo "$RUN_OUT" | grep -q '^15$'
echo "$RUN_OUT" | grep -q '^30$'
echo "$RUN_OUT" | grep -q '^true$'
rm -f "$OUT"
echo "✅ emitted artifact expression execution tests passed"
TMP_BAD="/tmp/panther_phase6_11_bad_$$.panther"
printf 'let x = 10 / 0\nprint x\n' > "$TMP_BAD"
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_expr.sh)"; BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_expr.sh
[ "$BAD_CODE" -eq 2 ] || { echo "division by zero should fail"; exit 1; }
echo "$BAD_OUT" | grep -q 'Division by zero'
echo "✅ negative/failure tests passed"
bash scripts/run_phase6_11_practical_demo.sh | grep -q 'artifact_runs=true'
echo "✅ practical expressions demo passed"
if command -v pytest >/dev/null 2>&1; then pytest -q tests/phase6_11 >/tmp/panther_phase6_11_pytest.log; echo "✅ pytest suite passed"; else python3 -m py_compile compiler/expressions/expression_engine.py compiler/pipeline/panther_compiler.py; echo "✅ python compile tests passed"; fi
echo "✅ PantherLang Phase 6.11 Rev2 Expressions Engine verification complete."
EOF
chmod +x scripts/verify_phase6_11_expressions_engine.sh

cat > scripts/verify_phase6_all.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase6_10_final_compiler_integration.sh
bash scripts/verify_phase6_11_expressions_engine.sh
echo "✅ ALL PHASE 6 TESTS PASSED THROUGH 6.11 REV2"
EOF
chmod +x scripts/verify_phase6_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 6.11 Rev2 — Expressions Engine PRO

Fixed and added deterministic expression support: arithmetic, comparisons, booleans, strings, variables, print expression evaluation, practical demo, and negative tests.
EOF

echo "[phase6.11-rev2] Running professional verification..."
bash scripts/verify_phase6_11_expressions_engine.sh

echo "============================================================"
echo " Phase 6.11 Rev2 COMPLETE"
echo " Next: Phase 6.12 Control Flow"
echo "============================================================"
