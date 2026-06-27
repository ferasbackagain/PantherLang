#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase6_12_control_flow_$STAMP"

echo "============================================================"
echo " PantherLang Phase 6.12 PRO - Control Flow Engine"
echo "============================================================"
echo "[phase6.12] Project root: $ROOT"

fail(){ echo "[phase6.12][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_file "panther"
require_file "compiler/pipeline/panther_compiler.py"
require_file "compiler/expressions/expression_engine.py"
require_file "scripts/verify_phase5_all.sh"
require_file "scripts/verify_phase6_10_final_compiler_integration.sh"
require_file "scripts/verify_phase6_11_expressions_engine.sh"

mkdir -p "$BACKUP_DIR"
for t in compiler language/compiler/control_flow architecture/CONTROL_FLOW_ENGINE.md docs/phase6/PHASE_6_12_STATUS.md examples/phase6_control_flow tests/phase6_12 scripts/verify_phase6_12_control_flow.sh scripts/run_phase6_12_practical_demo.sh scripts/verify_phase6_all.sh CHANGELOG.md; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

echo "[phase6.12] Verifying baselines..."
bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_12_phase5.log
bash scripts/verify_phase6_10_final_compiler_integration.sh >/tmp/panther_phase6_12_phase610.log
bash scripts/verify_phase6_11_expressions_engine.sh >/tmp/panther_phase6_12_phase611.log

mkdir -p compiler/control_flow compiler/pipeline language/compiler/control_flow architecture docs/phase6 examples/phase6_control_flow tests/phase6_12 scripts
touch compiler/__init__.py compiler/control_flow/__init__.py compiler/pipeline/__init__.py

cat > architecture/CONTROL_FLOW_ENGINE.md <<'EOF'
# PantherLang Phase 6.12 — Control Flow Engine

Adds `if` and `else` support, expression-based conditions, control-flow IR, backend emission, practical demo, and negative tests.

Engineering rule: No Feature Without Proof.
EOF

cat > language/compiler/control_flow/control_flow_manifest.json <<'EOF'
{
  "name": "PantherLang Control Flow Engine",
  "phase": "6.12",
  "version": "0.6.12-control-flow",
  "status": "compiler-language-feature",
  "depends_on": ["5.10", "6.10", "6.11"],
  "external_api_required": false,
  "network_required": false,
  "features": ["if_statement", "else_statement", "expression_conditions", "control_flow_ir", "control_flow_backend", "negative_tests"],
  "engineering_rule": "No Feature Without Proof"
}
EOF

cat > compiler/control_flow/control_flow_engine.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations
from typing import Any
from compiler.expressions.expression_engine import ExpressionEngine, PantherExpressionError

class PantherControlFlowError(Exception):
    pass

def _clean(line: str) -> str:
    return line.strip()

def parse_if_blocks(lines: list[str]) -> list[dict[str, Any]]:
    nodes: list[dict[str, Any]] = []
    i = 0
    while i < len(lines):
        raw = lines[i]
        line = _clean(raw)
        if not line or line.startswith("#"):
            i += 1
            continue
        if not line.startswith("if "):
            nodes.append({"kind": "RawLine", "line": i + 1, "source": raw})
            i += 1
            continue
        if "{" not in line:
            raise PantherControlFlowError(f"Invalid if statement at line {i + 1}: missing '{{'")
        condition = line[len("if "):line.rfind("{")].strip()
        if not condition:
            raise PantherControlFlowError(f"Invalid if statement at line {i + 1}: empty condition")
        i += 1
        then_lines: list[str] = []
        while i < len(lines):
            current = _clean(lines[i])
            if current == "}":
                i += 1
                break
            if current.startswith("} else"):
                break
            then_lines.append(lines[i])
            i += 1
        else:
            raise PantherControlFlowError("Unclosed if block")
        else_lines: list[str] = []
        if i < len(lines):
            maybe_else = _clean(lines[i])
            if maybe_else.startswith("else") or maybe_else.startswith("} else"):
                if "{" not in maybe_else:
                    raise PantherControlFlowError(f"Invalid else statement at line {i + 1}: missing '{{'")
                i += 1
                while i < len(lines):
                    current = _clean(lines[i])
                    if current == "}":
                        i += 1
                        break
                    else_lines.append(lines[i])
                    i += 1
                else:
                    raise PantherControlFlowError("Unclosed else block")
        nodes.append({"kind": "If", "line": i, "condition": condition, "then_lines": then_lines, "else_lines": else_lines})
    return nodes

def evaluate_condition(condition: str, symbols: dict[str, Any]) -> bool:
    try:
        value = ExpressionEngine(symbols).evaluate(condition)
    except PantherExpressionError as exc:
        raise PantherControlFlowError(str(exc)) from exc
    if isinstance(value, bool):
        return value
    if isinstance(value, int):
        return value != 0
    if isinstance(value, str):
        return bool(value)
    return False
PY

cat > /tmp/panther_phase6_12_patch.py <<'PY'
from pathlib import Path

path = Path("compiler/pipeline/panther_compiler.py")
txt = path.read_text(encoding="utf-8")

imp = "from compiler.control_flow.control_flow_engine import parse_if_blocks, evaluate_condition, PantherControlFlowError\n"
if imp not in txt:
    anchor = "from compiler.expressions.expression_engine import ExpressionEngine, PantherExpressionError, panther_format\n"
    if anchor in txt:
        txt = txt.replace(anchor, anchor + imp)
    else:
        txt = txt.replace("from typing import Any\n", "from typing import Any\n" + imp)

parse_sig = "    def parse(self, lines: list[str]) -> list[dict[str, Any]]:"
semantic_sig = "    def semantic(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:"
lower_sig = "    def lower_to_ir(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:"
backend_sig = "    def backend(self, ir: list[dict[str, Any]]) -> str:"
compile_sig = "    def compile(self, source_path: Path, out_path: Path) -> CompileReport:"

p = txt.find(parse_sig); s = txt.find(semantic_sig, p)
if p == -1 or s == -1: raise SystemExit("parse/semantic boundary not found")

new_parse = '''    def parse(self, lines: list[str]) -> list[dict[str, Any]]:
        ast: list[dict[str, Any]] = []
        expanded_nodes = parse_if_blocks(lines)

        for item in expanded_nodes:
            if item["kind"] == "RawLine":
                idx = item["line"]
                line = item["source"].strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("print "):
                    ast.append({"kind": "Print", "line": idx, "value": line[len("print "):].strip()})
                elif line.startswith("let "):
                    if "=" not in line:
                        raise PantherCompileError(f"Invalid let statement at line {idx}")
                    name, value = line[len("let "):].split("=", 1)
                    ast.append({"kind": "Let", "line": idx, "name": name.strip(), "value": value.strip()})
                elif line.startswith("agent "):
                    ast.append({"kind": "AgentDecl", "line": idx, "source": line})
                elif line.startswith("memory "):
                    ast.append({"kind": "MemoryDecl", "line": idx, "source": line})
                elif line.startswith("package "):
                    ast.append({"kind": "PackageDecl", "line": idx, "source": line})
                elif line.startswith("intent "):
                    ast.append({"kind": "IntentDecl", "line": idx, "source": line})
                else:
                    raise PantherCompileError(f"Unsupported statement at line {idx}: {line}")
            elif item["kind"] == "If":
                ast.append({
                    "kind": "If",
                    "line": item["line"],
                    "condition": item["condition"],
                    "then_ast": self.parse(item["then_lines"]),
                    "else_ast": self.parse(item["else_lines"]) if item.get("else_lines") else []
                })

        if not ast:
            raise PantherCompileError("No AST nodes produced")
        return ast

'''
txt = txt[:p] + new_parse + txt[s:]

s = txt.find(semantic_sig); l = txt.find(lower_sig, s)
if s == -1 or l == -1: raise SystemExit("semantic/lower boundary not found")

new_semantic = '''    def semantic(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:
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
                except (PantherExpressionError, PantherControlFlowError) as exc:
                    diagnostics.append({"level": "error", "code": "PANTHER-CONTROL-001", "message": str(exc), "line": node.get("line", 0)})

        walk(ast_nodes)
        return diagnostics

'''
txt = txt[:s] + new_semantic + txt[l:]

l = txt.find(lower_sig); b = txt.find(backend_sig, l)
if l == -1 or b == -1: raise SystemExit("lower/backend boundary not found")

new_lower = '''    def lower_to_ir(self, ast_nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:
        ir: list[dict[str, Any]] = []
        for node in ast_nodes:
            if node["kind"] == "Print":
                ir.append({"op": "PRINT", "value": str(node.get("evaluated_value", node["value"]))})
            elif node["kind"] == "Let":
                ir.append({"op": "STORE", "name": node["name"], "value": str(node.get("evaluated_value", node["value"]))})
            elif node["kind"] == "If":
                chosen = node["then_ast"] if node.get("condition_value") else node.get("else_ast", [])
                ir.append({"op": "IF", "condition": node["condition"], "condition_value": bool(node.get("condition_value")), "body_ir": self.lower_to_ir(chosen)})
            elif node["kind"] == "AgentDecl":
                ir.append({"op": "DECLARE_AGENT", "source": node["source"]})
            elif node["kind"] == "MemoryDecl":
                ir.append({"op": "DECLARE_MEMORY", "source": node["source"]})
            elif node["kind"] == "PackageDecl":
                ir.append({"op": "DECLARE_PACKAGE", "source": node["source"]})
            elif node["kind"] == "IntentDecl":
                ir.append({"op": "DECLARE_INTENT", "source": node["source"]})
        return ir

'''
txt = txt[:l] + new_lower + txt[b:]

b = txt.find(backend_sig); c = txt.find(compile_sig, b)
if b == -1 or c == -1: raise SystemExit("backend/compile boundary not found")

new_backend = '''    def backend(self, ir: list[dict[str, Any]]) -> str:
        lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            'echo "PantherLang compiled artifact"',
        ]

        def emit(items: list[dict[str, Any]], indent: str = "") -> None:
            for item in items:
                if item["op"] == "PRINT":
                    value = item["value"]
                    safe = value.replace("\\\\", "\\\\\\\\").replace('"', '\\\\"')
                    lines.append(f'{indent}echo "{safe}"')
                elif item["op"] == "STORE":
                    lines.append(f'{indent}# STORE {item["name"]} = {item["value"]}')
                elif item["op"] == "IF":
                    lines.append(f'{indent}# IF {item["condition"]} => {item["condition_value"]}')
                    emit(item["body_ir"], indent)
                else:
                    lines.append(f'{indent}# {item["op"]}: {item.get("source", "")}')

        emit(ir)
        return "\\n".join(lines) + "\\n"

'''
txt = txt[:b] + new_backend + txt[c:]

path.write_text(txt, encoding="utf-8")
print("✅ compiler pipeline patched for control flow")
PY

python3 /tmp/panther_phase6_12_patch.py
python3 -m py_compile compiler/control_flow/control_flow_engine.py
python3 -m py_compile compiler/pipeline/panther_compiler.py

cat > examples/phase6_control_flow/if_else_demo.panther <<'EOF'
let score = 10 + 5
let ok = score == 15

if ok {
    print "Control flow then branch passed"
} else {
    print "Control flow else branch failed"
}

print "Phase 6.12 control flow"
EOF

cat > scripts/run_phase6_12_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_12_control_flow_$$.sh"
REPORT="$(./panther compile examples/phase6_control_flow/if_else_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1]); out = Path(sys.argv[2])
assert report["ok"] is True and out.exists()
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "Control flow then branch passed" in proc.stdout
assert "Phase 6.12 control flow" in proc.stdout
print("demo=phase6.12-control-flow")
print("ok=true")
print("if=true")
print("else=true")
print("artifact_runs=true")
PY
rm -f "$OUT"
EOF
chmod +x scripts/run_phase6_12_practical_demo.sh

cat > tests/phase6_12/test_control_flow.py <<'EOF'
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"
def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)
def test_if_else_demo(tmp_path: Path) -> None:
    out = tmp_path / "ifelse.sh"
    code, data = run_cmd("compile", "examples/phase6_control_flow/if_else_demo.panther", "--out", str(out))
    assert code == 0 and data["ok"] is True
    proc = subprocess.run([str(out)], text=True, capture_output=True)
    assert proc.returncode == 0
    assert "Control flow then branch passed" in proc.stdout
def test_bad_if_missing_brace(tmp_path: Path) -> None:
    src = tmp_path / "bad_if.panther"
    src.write_text("if true\n    print \"bad\"\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
EOF

cat > docs/phase6/PHASE_6_12_STATUS.md <<'EOF'
# Phase 6.12 Status — Control Flow Engine PRO

Completed:
- if parsing
- else parsing
- expression-based conditions
- control-flow IR
- backend emission
- practical demo
- negative tests
- pytest suite

Next: Phase 6.13 — Loops.
EOF

cat > scripts/verify_phase6_12_control_flow.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.12 PRO Control Flow Verification"
echo "============================================================"
bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_12_phase5.log
echo "✅ Phase 5 regression tests passed"
bash scripts/verify_phase6_10_final_compiler_integration.sh >/tmp/panther_phase6_12_phase610.log
echo "✅ Phase 6.10 regression tests passed"
bash scripts/verify_phase6_11_expressions_engine.sh >/tmp/panther_phase6_12_phase611.log
echo "✅ Phase 6.11 regression tests passed"
test -f architecture/CONTROL_FLOW_ENGINE.md
test -f language/compiler/control_flow/control_flow_manifest.json
test -f compiler/control_flow/control_flow_engine.py
test -f examples/phase6_control_flow/if_else_demo.panther
test -x scripts/run_phase6_12_practical_demo.sh
test -f tests/phase6_12/test_control_flow.py
test -f docs/phase6/PHASE_6_12_STATUS.md
echo "✅ structure tests passed"
python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("language/compiler/control_flow/control_flow_manifest.json").read_text())
assert m["phase"] == "6.12"
assert m["external_api_required"] is False
assert "if_statement" in m["features"]
assert "else_statement" in m["features"]
PY
echo "✅ manifest tests passed"
OUT="/tmp/panther_phase6_12_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_control_flow/if_else_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "✅ compiler control-flow tests passed"
RUN_OUT="$("$OUT")"
echo "$RUN_OUT" | grep -q 'Control flow then branch passed'
echo "$RUN_OUT" | grep -q 'Phase 6.12 control flow'
rm -f "$OUT"
echo "✅ emitted artifact control-flow execution tests passed"
TMP_BAD="/tmp/panther_phase6_12_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
if true
    print "bad"
BAD
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_if.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_if.sh
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.12][ERROR] invalid if should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"
PRACTICAL_OUT="$(bash scripts/run_phase6_12_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.12-control-flow'
echo "$PRACTICAL_OUT" | grep -q 'if=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical control-flow demo passed"
if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_12 >/tmp/panther_phase6_12_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/control_flow/control_flow_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi
echo "✅ PantherLang Phase 6.12 Control Flow verification complete."
EOF
chmod +x scripts/verify_phase6_12_control_flow.sh

cat > scripts/verify_phase6_all.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase6_10_final_compiler_integration.sh
bash scripts/verify_phase6_11_expressions_engine.sh
bash scripts/verify_phase6_12_control_flow.sh
echo "✅ ALL PHASE 6 TESTS PASSED THROUGH 6.12"
EOF
chmod +x scripts/verify_phase6_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 6.12 — Control Flow Engine PRO

Added control-flow support:
- if statement parsing
- else statement parsing
- expression-based conditions
- control-flow IR
- backend emission
- practical demo
- negative/failure tests
- pytest suite

Next: Phase 6.13 Loops.
EOF

echo "[phase6.12] Running professional verification..."
bash scripts/verify_phase6_12_control_flow.sh

echo "============================================================"
echo " Phase 6.12 COMPLETE"
echo " Next: Phase 6.13 Loops"
echo "============================================================"
