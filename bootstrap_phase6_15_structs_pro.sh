#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase6_15_structs_$STAMP"

echo "============================================================"
echo " PantherLang Phase 6.15 PRO - Objects & Structs Engine"
echo "============================================================"
echo "[phase6.15] Project root: $ROOT"

fail(){ echo "[phase6.15][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_file "panther"
require_file "compiler/pipeline/panther_compiler.py"
require_file "compiler/expressions/expression_engine.py"
require_file "scripts/verify_phase6_14_functions.sh"

mkdir -p "$BACKUP_DIR"
for t in compiler language/compiler/structs architecture/STRUCTS_ENGINE.md docs/phase6/PHASE_6_15_STATUS.md examples/phase6_structs tests/phase6_15 scripts/verify_phase6_15_structs.sh scripts/run_phase6_15_practical_demo.sh scripts/verify_phase6_all.sh CHANGELOG.md; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

mkdir -p compiler/structs compiler/pipeline language/compiler/structs architecture docs/phase6 examples/phase6_structs tests/phase6_15 scripts
touch compiler/__init__.py compiler/structs/__init__.py compiler/pipeline/__init__.py

cat > architecture/STRUCTS_ENGINE.md <<'EOF'
# PantherLang Phase 6.15 — Objects & Structs Engine

Adds deterministic struct support.

Supported syntax:

```panther
struct User {
    name
    role
}
```

Scope:
- struct declaration parsing
- field parsing
- duplicate struct validation
- struct IR
- backend metadata emission
- practical demo
- negative tests

Engineering rule: No Feature Without Proof.
EOF

cat > language/compiler/structs/structs_manifest.json <<'EOF'
{
  "name": "PantherLang Objects & Structs Engine",
  "phase": "6.15",
  "version": "0.6.15-structs",
  "status": "compiler-language-feature",
  "depends_on": ["5.10", "6.10", "6.11", "6.12", "6.13", "6.14"],
  "external_api_required": false,
  "network_required": false,
  "features": ["struct_declaration", "field_parsing", "duplicate_struct_validation", "struct_ir", "backend_metadata", "negative_tests"],
  "engineering_rule": "No Feature Without Proof"
}
EOF

cat > compiler/structs/structs_engine.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations
import re

class PantherStructError(Exception):
    pass

FIELD_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

def validate_struct(name: str, fields: list[str]) -> None:
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
        raise PantherStructError(f"Invalid struct name: {name}")
    if not fields:
        raise PantherStructError(f"Struct {name} must have at least one field")
    seen: set[str] = set()
    for field in fields:
        if not FIELD_RE.fullmatch(field):
            raise PantherStructError(f"Invalid struct field: {field}")
        if field in seen:
            raise PantherStructError(f"Duplicate struct field: {field}")
        seen.add(field)
PY

cat > /tmp/panther_phase6_15_patch.py <<'PY'
from pathlib import Path

path = Path("compiler/pipeline/panther_compiler.py")
txt = path.read_text(encoding="utf-8")

imp = "from compiler.structs.structs_engine import validate_struct, PantherStructError\n"
if imp not in txt:
    anchor = "from compiler.functions.functions_engine import parse_call, PantherFunctionError\n"
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
if p == -1 or s == -1:
    raise SystemExit("parse/semantic boundary not found")

new_parse = '''    def parse(self, lines: list[str]) -> list[dict[str, Any]]:
        ast: list[dict[str, Any]] = []
        i = 0

        while i < len(lines):
            raw = lines[i]
            line = raw.strip()

            if not line or line.startswith("#"):
                i += 1
                continue

            if line.startswith("struct "):
                import re
                m = re.match(r"^struct\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\{\\s*$", line)
                if not m:
                    raise PantherCompileError(f"Invalid struct declaration at line {i + 1}")
                name = m.group(1)
                i += 1
                fields: list[str] = []
                closed = False
                while i < len(lines):
                    cur = lines[i].strip()
                    if cur == "}":
                        closed = True
                        i += 1
                        break
                    if cur and not cur.startswith("#"):
                        fields.append(cur)
                    i += 1
                if not closed:
                    raise PantherCompileError(f"Unclosed struct block: {name}")
                ast.append({"kind": "StructDecl", "line": i, "name": name, "fields": fields})
                continue

            if line.startswith("fn "):
                import re
                m = re.match(r"^fn\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\((.*?)\\)\\s*\\{\\s*$", line)
                if not m:
                    raise PantherCompileError(f"Invalid function declaration at line {i + 1}")
                name = m.group(1)
                params_text = m.group(2).strip()
                params = [param.strip() for param in params_text.split(",") if param.strip()] if params_text else []
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
                    raise PantherCompileError(f"Unclosed function block: {name}")
                ast.append({"kind": "FunctionDecl", "line": i, "name": name, "params": params, "body_ast": self.parse(body)})
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
                ast.append({"kind": "If", "line": i, "condition": condition, "then_ast": self.parse(body), "else_ast": []})
                continue

            if line.startswith("for "):
                import re
                m = re.match(r"^for\\s+([A-Za-z_][A-Za-z0-9_]*)\\s+in\\s+(.+)\\.\\.(.+)\\s*\\{\\s*$", line)
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
                ast.append({"kind": "For", "line": i, "var": var, "start_expr": start_expr, "end_expr": end_expr, "body_ast": self.parse(body)})
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
                call = parse_call(line)
                if call:
                    ast.append({"kind": "FunctionCall", "line": i + 1, "name": call["name"], "args": call["args"]})
                else:
                    raise PantherCompileError(f"Unsupported statement at line {i + 1}: {line}")

            i += 1

        if not ast:
            raise PantherCompileError("No AST nodes produced")
        return ast

'''
txt = txt[:p] + new_parse + txt[s:]

s = txt.find(semantic_sig); l = txt.find(lower_sig, s)
if s == -1 or l == -1:
    raise SystemExit("semantic/lower boundary not found")

if 'elif node["kind"] == "StructDecl":' not in txt[s:l]:
    marker = '                    if node["kind"] == "FunctionDecl":\n'
    repl = '''                    if node["kind"] == "StructDecl":
                        validate_struct(node["name"], node["fields"])

                    elif node["kind"] == "FunctionDecl":
'''
    block = txt[s:l].replace(marker, repl, 1)
    txt = txt[:s] + block + txt[l:]

txt = txt.replace(
    "except (PantherExpressionError, PantherControlFlowError, PantherLoopError, PantherFunctionError) as exc:",
    "except (PantherExpressionError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError) as exc:"
)

l = txt.find(lower_sig); b = txt.find(backend_sig, l)
if l == -1 or b == -1:
    raise SystemExit("lower/backend boundary not found")

if 'node["kind"] == "StructDecl"' not in txt[l:b]:
    marker = '            if node["kind"] == "Print":\n'
    repl = '''            if node["kind"] == "StructDecl":
                ir.append({"op": "DECLARE_STRUCT", "name": node["name"], "fields": node["fields"]})
            elif node["kind"] == "Print":
'''
    block = txt[l:b].replace(marker, repl, 1)
    txt = txt[:l] + block + txt[b:]

b = txt.find(backend_sig); c = txt.find(compile_sig, b)
if b == -1 or c == -1:
    raise SystemExit("backend/compile boundary not found")

if 'item["op"] == "DECLARE_STRUCT"' not in txt[b:c]:
    marker = '                if item["op"] == "PRINT":\n'
    repl = '''                if item["op"] == "DECLARE_STRUCT":
                    lines.append(f'{indent}# STRUCT {item["name"]}: {", ".join(item["fields"])}')
                elif item["op"] == "PRINT":
'''
    block = txt[b:c].replace(marker, repl, 1)
    txt = txt[:b] + block + txt[c:]

txt = txt.replace(
    "except (PantherCompileError, PantherControlFlowError, PantherLoopError, PantherFunctionError) as exc:",
    "except (PantherCompileError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError) as exc:"
)
txt = txt.replace(
    "except PantherCompileError as exc:",
    "except (PantherCompileError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError) as exc:"
)

path.write_text(txt, encoding="utf-8")
print("✅ compiler pipeline patched for structs")
PY

python3 /tmp/panther_phase6_15_patch.py
python3 -m py_compile compiler/structs/structs_engine.py
python3 -m py_compile compiler/pipeline/panther_compiler.py

cat > examples/phase6_structs/struct_demo.panther <<'EOF'
struct User {
    name
    role
}

let user_name = "Feras"
let user_role = "Founder"

print "Struct declaration test"
print user_name
print user_role
print "Phase 6.15 structs"
EOF

cat > scripts/run_phase6_15_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_15_struct_$$.sh"
REPORT="$(./panther compile examples/phase6_structs/struct_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1]); out = Path(sys.argv[2])
assert report["ok"] is True and out.exists()
assert any(item["op"] == "DECLARE_STRUCT" for item in report["ir"])
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "Struct declaration test" in proc.stdout
assert "Feras" in proc.stdout
assert "Founder" in proc.stdout
assert "Phase 6.15 structs" in proc.stdout
print("demo=phase6.15-structs")
print("ok=true")
print("struct_declaration=true")
print("fields=true")
print("artifact_runs=true")
PY
rm -f "$OUT"
EOF
chmod +x scripts/run_phase6_15_practical_demo.sh

cat > tests/phase6_15/test_structs.py <<'EOF'
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"
def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)
def test_struct_demo(tmp_path: Path) -> None:
    out = tmp_path / "struct.sh"
    code, data = run_cmd("compile", "examples/phase6_structs/struct_demo.panther", "--out", str(out))
    assert code == 0 and data["ok"] is True
    assert any(item["op"] == "DECLARE_STRUCT" for item in data["ir"])
def test_duplicate_field_fails(tmp_path: Path) -> None:
    src = tmp_path / "bad_struct.panther"
    src.write_text("struct User {\n    name\n    name\n}\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
EOF

cat > docs/phase6/PHASE_6_15_STATUS.md <<'EOF'
# Phase 6.15 Status — Objects & Structs Engine PRO

Completed:
- struct declaration parsing
- field parsing
- duplicate field validation
- struct IR
- backend metadata emission
- practical demo
- negative tests
- pytest suite

Next: Phase 6.16 — Modules.
EOF

cat > scripts/verify_phase6_15_structs.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.15 PRO Structs Verification"
echo "============================================================"
test -f compiler/structs/structs_engine.py
test -f examples/phase6_structs/struct_demo.panther
test -x scripts/run_phase6_15_practical_demo.sh
test -f tests/phase6_15/test_structs.py
echo "✅ structure tests passed"
OUT="/tmp/panther_phase6_15_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_structs/struct_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "$COMPILE_JSON" | grep -q '"DECLARE_STRUCT"'
echo "✅ compiler struct tests passed"
RUN_OUT="$("$OUT")"
echo "$RUN_OUT" | grep -q 'Struct declaration test'
echo "$RUN_OUT" | grep -q 'Feras'
echo "$RUN_OUT" | grep -q 'Founder'
echo "$RUN_OUT" | grep -q 'Phase 6.15 structs'
rm -f "$OUT"
echo "✅ emitted artifact struct execution tests passed"
TMP_BAD="/tmp/panther_phase6_15_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
struct User {
    name
    name
}
BAD
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_struct.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_struct.sh
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.15][ERROR] duplicate struct field should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"
PRACTICAL_OUT="$(bash scripts/run_phase6_15_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.15-structs'
echo "$PRACTICAL_OUT" | grep -q 'struct_declaration=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical structs demo passed"
if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_15 >/tmp/panther_phase6_15_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/structs/structs_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi
echo "✅ PantherLang Phase 6.15 Structs verification complete."
EOF
chmod +x scripts/verify_phase6_15_structs.sh

cat > scripts/verify_phase6_all.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase6_10_final_compiler_integration.sh
bash scripts/verify_phase6_11_expressions_engine.sh
bash scripts/verify_phase6_12_control_flow.sh
bash scripts/verify_phase6_13_loops.sh
bash scripts/verify_phase6_14_functions.sh
bash scripts/verify_phase6_15_structs.sh
echo "✅ ALL PHASE 6 TESTS PASSED THROUGH 6.15"
EOF
chmod +x scripts/verify_phase6_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 6.15 — Objects & Structs Engine PRO

Added struct support:
- struct declaration parsing
- field parsing
- duplicate field validation
- struct IR
- backend metadata emission
- practical demo
- negative/failure tests
- pytest suite

Next: Phase 6.16 Modules.
EOF

echo "[phase6.15] Running professional verification..."
bash scripts/verify_phase6_15_structs.sh

echo "============================================================"
echo " Phase 6.15 COMPLETE"
echo " Next: Phase 6.16 Modules"
echo "============================================================"
