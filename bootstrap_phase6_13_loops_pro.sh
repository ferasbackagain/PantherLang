#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase6_13_loops_$STAMP"

echo "============================================================"
echo " PantherLang Phase 6.13 PRO - Loops Engine"
echo "============================================================"
echo "[phase6.13] Project root: $ROOT"

fail(){ echo "[phase6.13][ERROR] $1" >&2; exit 1; }
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
require_file "scripts/verify_phase6_12_control_flow.sh"

mkdir -p "$BACKUP_DIR"
for t in compiler language/compiler/loops architecture/LOOPS_ENGINE.md docs/phase6/PHASE_6_13_STATUS.md examples/phase6_loops tests/phase6_13 scripts/verify_phase6_13_loops.sh scripts/run_phase6_13_practical_demo.sh scripts/verify_phase6_all.sh CHANGELOG.md; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

echo "[phase6.13] Verifying baselines..."
bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_13_phase5.log
echo "✅ Phase 5 baseline passed"
bash scripts/verify_phase6_10_final_compiler_integration.sh >/tmp/panther_phase6_13_phase610.log
echo "✅ Phase 6.10 baseline passed"
bash scripts/verify_phase6_11_expressions_engine.sh >/tmp/panther_phase6_13_phase611.log
echo "✅ Phase 6.11 baseline passed"
bash scripts/verify_phase6_12_control_flow.sh >/tmp/panther_phase6_13_phase612.log
echo "✅ Phase 6.12 baseline passed"

mkdir -p compiler/loops compiler/pipeline language/compiler/loops architecture docs/phase6 examples/phase6_loops tests/phase6_13 scripts
touch compiler/__init__.py compiler/loops/__init__.py compiler/pipeline/__init__.py

cat > architecture/LOOPS_ENGINE.md <<'EOF'
# PantherLang Phase 6.13 — Loops Engine

Adds deterministic `for` loop support.

Supported syntax:

```panther
for i in 1..3 {
    print "Loop iteration"
    print i
}
```

Scope:
- range loop parsing
- loop variable binding
- loop IR
- backend emission
- practical demo
- negative tests

Engineering rule: No Feature Without Proof.
EOF

cat > language/compiler/loops/loops_manifest.json <<'EOF'
{
  "name": "PantherLang Loops Engine",
  "phase": "6.13",
  "version": "0.6.13-loops",
  "status": "compiler-language-feature",
  "depends_on": ["5.10", "6.10", "6.11", "6.12"],
  "external_api_required": false,
  "network_required": false,
  "features": ["for_loop", "range_loop", "loop_variable", "loop_ir", "loop_backend", "negative_tests"],
  "engineering_rule": "No Feature Without Proof"
}
EOF

cat > compiler/loops/loops_engine.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations
import re
from typing import Any

class PantherLoopError(Exception):
    pass

FOR_RE = re.compile(r"^for\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.+)\.\.(.+)\s*\{\s*$")

def _clean(line: str) -> str:
    return line.strip()

def parse_loop_blocks(lines: list[str]) -> list[dict[str, Any]]:
    nodes: list[dict[str, Any]] = []
    i = 0
    while i < len(lines):
        raw = lines[i]
        line = _clean(raw)
        if not line or line.startswith("#"):
            i += 1
            continue
        if not line.startswith("for "):
            nodes.append({"kind": "RawLine", "line": i + 1, "source": raw})
            i += 1
            continue
        m = FOR_RE.match(line)
        if not m:
            raise PantherLoopError(f"Invalid for loop at line {i + 1}. Expected: for i in 1..3 {{")
        var, start_expr, end_expr = m.group(1), m.group(2).strip(), m.group(3).strip()
        i += 1
        body_lines: list[str] = []
        while i < len(lines):
            current = _clean(lines[i])
            if current == "}":
                i += 1
                break
            body_lines.append(lines[i])
            i += 1
        else:
            raise PantherLoopError("Unclosed for loop block")
        nodes.append({"kind": "For", "line": i, "var": var, "start_expr": start_expr, "end_expr": end_expr, "body_lines": body_lines})
    return nodes

def validate_loop_range(start: Any, end: Any) -> tuple[int, int]:
    if not isinstance(start, int) or not isinstance(end, int):
        raise PantherLoopError("Loop range bounds must be integers")
    if end < start:
        raise PantherLoopError("Loop range end must be greater than or equal to start")
    if end - start > 10000:
        raise PantherLoopError("Loop range too large")
    return start, end
PY

cat > /tmp/panther_phase6_13_patch.py <<'PY'
from pathlib import Path

path = Path("compiler/pipeline/panther_compiler.py")
txt = path.read_text(encoding="utf-8")

imp = "from compiler.loops.loops_engine import parse_loop_blocks, validate_loop_range, PantherLoopError\n"
if imp not in txt:
    anchor = "from compiler.control_flow.control_flow_engine import parse_if_blocks, evaluate_condition, PantherControlFlowError\n"
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
        loop_expanded = parse_loop_blocks(lines)
        expanded_nodes: list[dict[str, Any]] = []
        for loop_item in loop_expanded:
            if loop_item["kind"] == "For":
                expanded_nodes.append(loop_item)
            else:
                expanded_nodes.extend(parse_if_blocks([loop_item["source"]]))
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
                ast.append({"kind": "If", "line": item["line"], "condition": item["condition"], "then_ast": self.parse(item["then_lines"]), "else_ast": self.parse(item["else_lines"]) if item.get("else_lines") else []})
            elif item["kind"] == "For":
                ast.append({"kind": "For", "line": item["line"], "var": item["var"], "start_expr": item["start_expr"], "end_expr": item["end_expr"], "body_ast": self.parse(item["body_lines"])})
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

'''
txt = txt[:l] + new_lower + txt[b:]

b = txt.find(backend_sig); c = txt.find(compile_sig, b)
if b == -1 or c == -1: raise SystemExit("backend/compile boundary not found")

new_backend = '''    def backend(self, ir: list[dict[str, Any]]) -> str:
        lines = ["#!/usr/bin/env bash", "set -euo pipefail", 'echo "PantherLang compiled artifact"']
        def emit(items: list[dict[str, Any]], indent: str = "") -> None:
            for item in items:
                if item["op"] == "PRINT":
                    value = item["value"]
                    safe = value.replace("\\\\", "\\\\\\\\").replace('"', '\\\"')
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
        return "\\n".join(lines) + "\\n"

'''
txt = txt[:b] + new_backend + txt[c:]

# Make main catch loop errors too.
txt = txt.replace("except (PantherCompileError, PantherControlFlowError) as exc:", "except (PantherCompileError, PantherControlFlowError, PantherLoopError) as exc:")
txt = txt.replace("except PantherCompileError as exc:", "except (PantherCompileError, PantherControlFlowError, PantherLoopError) as exc:")

path.write_text(txt, encoding="utf-8")
print("✅ compiler pipeline patched for loops")
PY

python3 /tmp/panther_phase6_13_patch.py
python3 -m py_compile compiler/loops/loops_engine.py
python3 -m py_compile compiler/pipeline/panther_compiler.py

cat > examples/phase6_loops/for_loop_demo.panther <<'EOF'
let start = 1
let end = 3

for i in start..end {
    print "Loop iteration"
    print i
}

print "Phase 6.13 loops"
EOF

cat > scripts/run_phase6_13_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_13_loop_$$.sh"
REPORT="$(./panther compile examples/phase6_loops/for_loop_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1]); out = Path(sys.argv[2])
assert report["ok"] is True and out.exists()
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert proc.stdout.count("Loop iteration") == 3
assert "Phase 6.13 loops" in proc.stdout
print("demo=phase6.13-loops")
print("ok=true")
print("for_loop=true")
print("range_loop=true")
print("artifact_runs=true")
PY
rm -f "$OUT"
EOF
chmod +x scripts/run_phase6_13_practical_demo.sh

cat > tests/phase6_13/test_loops.py <<'EOF'
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"
def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)
def test_for_loop_demo(tmp_path: Path) -> None:
    out = tmp_path / "loop.sh"
    code, data = run_cmd("compile", "examples/phase6_loops/for_loop_demo.panther", "--out", str(out))
    assert code == 0 and data["ok"] is True
    proc = subprocess.run([str(out)], text=True, capture_output=True)
    assert proc.returncode == 0
    assert proc.stdout.count("Loop iteration") == 3
def test_bad_loop_range(tmp_path: Path) -> None:
    src = tmp_path / "bad_loop.panther"
    src.write_text("for i in 5..1 {\n    print i\n}\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
EOF

cat > docs/phase6/PHASE_6_13_STATUS.md <<'EOF'
# Phase 6.13 Status — Loops Engine PRO

Completed:
- for loop parsing
- range loop support
- loop variable binding
- loop IR
- backend emission
- practical demo
- negative tests
- pytest suite

Next: Phase 6.14 — Functions.
EOF

cat > scripts/verify_phase6_13_loops.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.13 PRO Loops Verification"
echo "============================================================"
bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_13_phase5.log
echo "✅ Phase 5 regression tests passed"
bash scripts/verify_phase6_10_final_compiler_integration.sh >/tmp/panther_phase6_13_phase610.log
echo "✅ Phase 6.10 regression tests passed"
bash scripts/verify_phase6_11_expressions_engine.sh >/tmp/panther_phase6_13_phase611.log
echo "✅ Phase 6.11 regression tests passed"
bash scripts/verify_phase6_12_control_flow.sh >/tmp/panther_phase6_13_phase612.log
echo "✅ Phase 6.12 regression tests passed"
test -f architecture/LOOPS_ENGINE.md
test -f language/compiler/loops/loops_manifest.json
test -f compiler/loops/loops_engine.py
test -f examples/phase6_loops/for_loop_demo.panther
test -x scripts/run_phase6_13_practical_demo.sh
test -f tests/phase6_13/test_loops.py
test -f docs/phase6/PHASE_6_13_STATUS.md
echo "✅ structure tests passed"
python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("language/compiler/loops/loops_manifest.json").read_text())
assert m["phase"] == "6.13"
assert m["external_api_required"] is False
assert "for_loop" in m["features"]
assert "range_loop" in m["features"]
PY
echo "✅ manifest tests passed"
OUT="/tmp/panther_phase6_13_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_loops/for_loop_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "✅ compiler loop tests passed"
RUN_OUT="$("$OUT")"
test "$(echo "$RUN_OUT" | grep -c 'Loop iteration')" = "3"
echo "$RUN_OUT" | grep -q 'Phase 6.13 loops'
rm -f "$OUT"
echo "✅ emitted artifact loop execution tests passed"
TMP_BAD="/tmp/panther_phase6_13_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
for i in 5..1 {
    print i
}
BAD
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_loop.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_loop.sh
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.13][ERROR] invalid loop should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"
PRACTICAL_OUT="$(bash scripts/run_phase6_13_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.13-loops'
echo "$PRACTICAL_OUT" | grep -q 'for_loop=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical loops demo passed"
if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_13 >/tmp/panther_phase6_13_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/loops/loops_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi
echo "✅ PantherLang Phase 6.13 Loops verification complete."
EOF
chmod +x scripts/verify_phase6_13_loops.sh

cat > scripts/verify_phase6_all.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase6_10_final_compiler_integration.sh
bash scripts/verify_phase6_11_expressions_engine.sh
bash scripts/verify_phase6_12_control_flow.sh
bash scripts/verify_phase6_13_loops.sh
echo "✅ ALL PHASE 6 TESTS PASSED THROUGH 6.13"
EOF
chmod +x scripts/verify_phase6_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 6.13 — Loops Engine PRO

Added loop support:
- for loop parsing
- range loop support
- loop variable binding
- loop IR
- backend emission
- practical demo
- negative/failure tests
- pytest suite

Next: Phase 6.14 Functions.
EOF

echo "[phase6.13] Running professional verification..."
bash scripts/verify_phase6_13_loops.sh

echo "============================================================"
echo " Phase 6.13 COMPLETE"
echo " Next: Phase 6.14 Functions"
echo "============================================================"
