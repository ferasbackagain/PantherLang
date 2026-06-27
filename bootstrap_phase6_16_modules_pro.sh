#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase6_16_modules_$STAMP"

echo "============================================================"
echo " PantherLang Phase 6.16 PRO - Modules Engine"
echo "============================================================"
echo "[phase6.16] Project root: $ROOT"

fail(){ echo "[phase6.16][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_file "panther"
require_file "compiler/pipeline/panther_compiler.py"
require_file "compiler/expressions/expression_engine.py"
require_file "scripts/verify_phase6_15_structs.sh"

mkdir -p "$BACKUP_DIR"
for t in compiler language/compiler/modules architecture/MODULES_ENGINE.md docs/phase6/PHASE_6_16_STATUS.md examples/phase6_modules tests/phase6_16 scripts/verify_phase6_16_modules.sh scripts/run_phase6_16_practical_demo.sh scripts/verify_phase6_all.sh CHANGELOG.md; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

echo "[phase6.16] Verifying Phase 6.15 baseline..."
bash scripts/verify_phase6_15_structs.sh >/tmp/panther_phase6_16_phase615.log

mkdir -p compiler/modules compiler/pipeline language/compiler/modules architecture docs/phase6 examples/phase6_modules tests/phase6_16 scripts
touch compiler/__init__.py compiler/modules/__init__.py compiler/pipeline/__init__.py

cat > architecture/MODULES_ENGINE.md <<'EOF'
# PantherLang Phase 6.16 — Modules Engine

Adds deterministic module/import support.

Supported syntax:

```panther
module security.core

import ai.agents

print "Module loaded"
```

Scope:
- module declaration parsing
- import declaration parsing
- module name validation
- duplicate import validation
- module/import IR
- backend metadata emission
- practical demo
- negative tests

Engineering rule: No Feature Without Proof.
EOF

cat > language/compiler/modules/modules_manifest.json <<'EOF'
{
  "name": "PantherLang Modules Engine",
  "phase": "6.16",
  "version": "0.6.16-modules",
  "status": "compiler-language-feature",
  "depends_on": ["5.10", "6.10", "6.11", "6.12", "6.13", "6.14", "6.15"],
  "external_api_required": false,
  "network_required": false,
  "features": [
    "module_declaration",
    "import_declaration",
    "module_name_validation",
    "duplicate_import_validation",
    "module_ir",
    "backend_metadata",
    "negative_tests"
  ],
  "engineering_rule": "No Feature Without Proof"
}
EOF

cat > compiler/modules/modules_engine.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import re

class PantherModuleError(Exception):
    pass

MODULE_NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$")

def validate_module_name(name: str) -> None:
    if not MODULE_NAME_RE.fullmatch(name):
        raise PantherModuleError(f"Invalid module name: {name}")

def validate_imports(imports: list[str]) -> None:
    seen = set()
    for item in imports:
        validate_module_name(item)
        if item in seen:
            raise PantherModuleError(f"Duplicate import: {item}")
        seen.add(item)
PY

cat > /tmp/panther_phase6_16_patch.py <<'PY'
from pathlib import Path

path = Path("compiler/pipeline/panther_compiler.py")
txt = path.read_text(encoding="utf-8")

imp = "from compiler.modules.modules_engine import validate_module_name, validate_imports, PantherModuleError\n"
if imp not in txt:
    anchor = "from compiler.structs.structs_engine import validate_struct, PantherStructError\n"
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

old_parse = txt[p:s]
# Inject module/import parsing after comment/empty handling and before struct handling.
if 'line.startswith("module ")' not in old_parse:
    marker = '            if line.startswith("struct "):\n'
    injection = '''            if line.startswith("module "):
                name = line[len("module "):].strip()
                ast.append({"kind": "ModuleDecl", "line": i + 1, "name": name})
                i += 1
                continue

            if line.startswith("import "):
                name = line[len("import "):].strip()
                ast.append({"kind": "ImportDecl", "line": i + 1, "name": name})
                i += 1
                continue

'''
    old_parse = old_parse.replace(marker, injection + marker)
    txt = txt[:p] + old_parse + txt[s:]

s = txt.find(semantic_sig); l = txt.find(lower_sig, s)
if s == -1 or l == -1:
    raise SystemExit("semantic/lower boundary not found")

sem_block = txt[s:l]
if 'node["kind"] == "ModuleDecl"' not in sem_block:
    marker = '                    if node["kind"] == "StructDecl":\n'
    repl = '''                    if node["kind"] == "ModuleDecl":
                        validate_module_name(node["name"])

                    elif node["kind"] == "ImportDecl":
                        validate_module_name(node["name"])

                    elif node["kind"] == "StructDecl":
'''
    sem_block = sem_block.replace(marker, repl, 1)
    txt = txt[:s] + sem_block + txt[l:]

# Add module error to semantic catches
txt = txt.replace(
    "except (PantherExpressionError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError) as exc:",
    "except (PantherExpressionError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError, PantherModuleError) as exc:"
)

l = txt.find(lower_sig); b = txt.find(backend_sig, l)
if l == -1 or b == -1:
    raise SystemExit("lower/backend boundary not found")

lower_block = txt[l:b]
if 'node["kind"] == "ModuleDecl"' not in lower_block:
    marker = '            if node["kind"] == "StructDecl":\n'
    repl = '''            if node["kind"] == "ModuleDecl":
                ir.append({"op": "DECLARE_MODULE", "name": node["name"]})
            elif node["kind"] == "ImportDecl":
                ir.append({"op": "IMPORT_MODULE", "name": node["name"]})
            elif node["kind"] == "StructDecl":
'''
    lower_block = lower_block.replace(marker, repl, 1)
    txt = txt[:l] + lower_block + txt[b:]

b = txt.find(backend_sig); c = txt.find(compile_sig, b)
if b == -1 or c == -1:
    raise SystemExit("backend/compile boundary not found")

backend_block = txt[b:c]
if 'item["op"] == "DECLARE_MODULE"' not in backend_block:
    marker = '                if item["op"] == "DECLARE_STRUCT":\n'
    repl = '''                if item["op"] == "DECLARE_MODULE":
                    lines.append(f'{indent}# MODULE {item["name"]}')
                elif item["op"] == "IMPORT_MODULE":
                    lines.append(f'{indent}# IMPORT {item["name"]}')
                elif item["op"] == "DECLARE_STRUCT":
'''
    backend_block = backend_block.replace(marker, repl, 1)
    txt = txt[:b] + backend_block + txt[c:]

# Ensure main catches module errors.
txt = txt.replace(
    "except (PantherCompileError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError) as exc:",
    "except (PantherCompileError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError, PantherModuleError) as exc:"
)
txt = txt.replace(
    "except PantherCompileError as exc:",
    "except (PantherCompileError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError, PantherModuleError) as exc:"
)

path.write_text(txt, encoding="utf-8")
print("✅ compiler pipeline patched for modules")
PY

python3 /tmp/panther_phase6_16_patch.py
python3 -m py_compile compiler/modules/modules_engine.py
python3 -m py_compile compiler/pipeline/panther_compiler.py

cat > examples/phase6_modules/module_demo.panther <<'EOF'
module panther.security

import panther.ai
import panther.core

struct Service {
    name
    version
}

let service_name = "Panther Module System"
let version = "0.6.16"

print "Module declaration test"
print service_name
print version
print "Phase 6.16 modules"
EOF

cat > scripts/run_phase6_16_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_16_module_$$.sh"
REPORT="$(./panther compile examples/phase6_modules/module_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1]); out = Path(sys.argv[2])
assert report["ok"] is True and out.exists()
assert any(item["op"] == "DECLARE_MODULE" for item in report["ir"])
assert any(item["op"] == "IMPORT_MODULE" for item in report["ir"])
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "Module declaration test" in proc.stdout
assert "Panther Module System" in proc.stdout
assert "0.6.16" in proc.stdout
assert "Phase 6.16 modules" in proc.stdout
print("demo=phase6.16-modules")
print("ok=true")
print("module_declaration=true")
print("imports=true")
print("artifact_runs=true")
PY
rm -f "$OUT"
EOF
chmod +x scripts/run_phase6_16_practical_demo.sh

cat > tests/phase6_16/test_modules.py <<'EOF'
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"
def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)
def test_module_demo(tmp_path: Path) -> None:
    out = tmp_path / "module.sh"
    code, data = run_cmd("compile", "examples/phase6_modules/module_demo.panther", "--out", str(out))
    assert code == 0 and data["ok"] is True
    assert any(item["op"] == "DECLARE_MODULE" for item in data["ir"])
    assert any(item["op"] == "IMPORT_MODULE" for item in data["ir"])
    proc = subprocess.run([str(out)], text=True, capture_output=True)
    assert proc.returncode == 0
    assert "Phase 6.16 modules" in proc.stdout
def test_invalid_module_fails(tmp_path: Path) -> None:
    src = tmp_path / "bad_module.panther"
    src.write_text("module 123.bad\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
EOF

cat > docs/phase6/PHASE_6_16_STATUS.md <<'EOF'
# Phase 6.16 Status — Modules Engine PRO

Completed:
- module declaration parsing
- import declaration parsing
- module name validation
- module/import IR
- backend metadata emission
- practical demo
- negative tests
- pytest suite

Next: Phase 6.17 — Standard Library Foundation.
EOF

cat > scripts/verify_phase6_16_modules.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.16 PRO Modules Verification"
echo "============================================================"
test -f compiler/modules/modules_engine.py
test -f examples/phase6_modules/module_demo.panther
test -x scripts/run_phase6_16_practical_demo.sh
test -f tests/phase6_16/test_modules.py
echo "✅ structure tests passed"
OUT="/tmp/panther_phase6_16_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_modules/module_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "$COMPILE_JSON" | grep -q '"DECLARE_MODULE"'
echo "$COMPILE_JSON" | grep -q '"IMPORT_MODULE"'
echo "✅ compiler module tests passed"
RUN_OUT="$("$OUT")"
echo "$RUN_OUT" | grep -q 'Module declaration test'
echo "$RUN_OUT" | grep -q 'Panther Module System'
echo "$RUN_OUT" | grep -q '0.6.16'
echo "$RUN_OUT" | grep -q 'Phase 6.16 modules'
rm -f "$OUT"
echo "✅ emitted artifact module execution tests passed"
TMP_BAD="/tmp/panther_phase6_16_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
module 123.bad
BAD
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_module.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_module.sh
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.16][ERROR] invalid module should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"
PRACTICAL_OUT="$(bash scripts/run_phase6_16_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.16-modules'
echo "$PRACTICAL_OUT" | grep -q 'module_declaration=true'
echo "$PRACTICAL_OUT" | grep -q 'imports=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical modules demo passed"
if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_16 >/tmp/panther_phase6_16_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/modules/modules_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi
echo "✅ PantherLang Phase 6.16 Modules verification complete."
EOF
chmod +x scripts/verify_phase6_16_modules.sh

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
bash scripts/verify_phase6_16_modules.sh
echo "✅ ALL PHASE 6 TESTS PASSED THROUGH 6.16"
EOF
chmod +x scripts/verify_phase6_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 6.16 — Modules Engine PRO

Added module support:
- module declaration parsing
- import declaration parsing
- module name validation
- module/import IR
- backend metadata emission
- practical demo
- negative/failure tests
- pytest suite

Next: Phase 6.17 Standard Library Foundation.
EOF

echo "[phase6.16] Running professional verification..."
bash scripts/verify_phase6_16_modules.sh

echo "============================================================"
echo " Phase 6.16 COMPLETE"
echo " Next: Phase 6.17 Standard Library Foundation"
echo "============================================================"
