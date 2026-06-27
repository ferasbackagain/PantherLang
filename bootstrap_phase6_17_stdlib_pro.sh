#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase6_17_stdlib_$STAMP"

echo "============================================================"
echo " PantherLang Phase 6.17 PRO - Standard Library Foundation"
echo "============================================================"
echo "[phase6.17] Project root: $ROOT"

fail(){ echo "[phase6.17][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_file "panther"
require_file "compiler/pipeline/panther_compiler.py"
require_file "compiler/expressions/expression_engine.py"
require_file "scripts/verify_phase6_16_modules.sh"

mkdir -p "$BACKUP_DIR"
for t in compiler language/compiler/stdlib language/stdlib architecture/STANDARD_LIBRARY_FOUNDATION.md docs/phase6/PHASE_6_17_STATUS.md examples/phase6_stdlib tests/phase6_17 scripts/verify_phase6_17_stdlib.sh scripts/run_phase6_17_practical_demo.sh scripts/verify_phase6_all.sh CHANGELOG.md; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

echo "[phase6.17] Verifying Phase 6.16 baseline..."
bash scripts/verify_phase6_16_modules.sh >/tmp/panther_phase6_17_phase616.log

mkdir -p compiler/stdlib compiler/pipeline language/compiler/stdlib language/stdlib/{core,io,math,text,json} architecture docs/phase6 examples/phase6_stdlib tests/phase6_17 scripts
touch compiler/__init__.py compiler/stdlib/__init__.py compiler/pipeline/__init__.py

cat > architecture/STANDARD_LIBRARY_FOUNDATION.md <<'EOF'
# PantherLang Phase 6.17 — Standard Library Foundation

Adds the first deterministic Standard Library foundation.

Supported builtins:

```panther
print std.text.upper("panther")
print std.text.lower("PANTHER")
print std.math.add(10, 5)
print std.math.mul(3, 7)
print std.io.echo("hello")
```

Scope:
- standard library manifest
- builtin function registry
- compile-time stdlib evaluation
- stdlib IR metadata
- backend emission
- practical demo
- negative tests

Engineering rule: No Feature Without Proof.
EOF

cat > language/compiler/stdlib/stdlib_manifest.json <<'EOF'
{
  "name": "PantherLang Standard Library Foundation",
  "phase": "6.17",
  "version": "0.6.17-stdlib-foundation",
  "status": "compiler-language-feature",
  "depends_on": ["5.10", "6.10", "6.11", "6.12", "6.13", "6.14", "6.15", "6.16"],
  "external_api_required": false,
  "network_required": false,
  "features": [
    "stdlib_manifest",
    "builtin_function_registry",
    "text_upper",
    "text_lower",
    "math_add",
    "math_mul",
    "io_echo",
    "compile_time_stdlib_evaluation",
    "negative_tests"
  ],
  "engineering_rule": "No Feature Without Proof"
}
EOF

cat > language/stdlib/core/README.md <<'EOF'
# PantherLang Standard Library Core

Phase 6.17 introduces the first verified standard library foundation.
EOF

cat > language/stdlib/text/README.md <<'EOF'
# std.text

- std.text.upper(value)
- std.text.lower(value)
EOF

cat > language/stdlib/math/README.md <<'EOF'
# std.math

- std.math.add(a, b)
- std.math.mul(a, b)
EOF

cat > language/stdlib/io/README.md <<'EOF'
# std.io

- std.io.echo(value)
EOF

cat > compiler/stdlib/stdlib_engine.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import ast
from typing import Any

class PantherStdlibError(Exception):
    pass

SUPPORTED = {
    "std.text.upper",
    "std.text.lower",
    "std.math.add",
    "std.math.mul",
    "std.io.echo",
}

def _eval_arg(node: ast.AST, symbols: dict[str, Any]) -> Any:
    if isinstance(node, ast.Constant):
        if isinstance(node.value, (str, int, bool)):
            return node.value
        raise PantherStdlibError("Unsupported stdlib argument constant")
    if isinstance(node, ast.Name):
        if node.id in symbols:
            return symbols[node.id]
        raise PantherStdlibError(f"Undefined stdlib argument symbol: {node.id}")
    raise PantherStdlibError("Unsupported stdlib argument expression")

def _name_from_node(node: ast.AST) -> str:
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        return _name_from_node(node.value) + "." + node.attr
    raise PantherStdlibError("Unsupported stdlib call target")

def is_stdlib_call(expr: str) -> bool:
    text = expr.strip()
    return text.startswith("std.")

def evaluate_stdlib_call(expr: str, symbols: dict[str, Any]) -> Any:
    try:
        parsed = ast.parse(expr.strip(), mode="eval")
    except Exception as exc:
        raise PantherStdlibError(f"Invalid stdlib expression: {expr}") from exc

    if not isinstance(parsed.body, ast.Call):
        raise PantherStdlibError(f"Invalid stdlib call: {expr}")

    name = _name_from_node(parsed.body.func)
    if name not in SUPPORTED:
        raise PantherStdlibError(f"Unsupported stdlib function: {name}")

    args = [_eval_arg(arg, symbols) for arg in parsed.body.args]

    if name == "std.text.upper":
        if len(args) != 1:
            raise PantherStdlibError("std.text.upper expects 1 argument")
        return str(args[0]).upper()

    if name == "std.text.lower":
        if len(args) != 1:
            raise PantherStdlibError("std.text.lower expects 1 argument")
        return str(args[0]).lower()

    if name == "std.math.add":
        if len(args) != 2:
            raise PantherStdlibError("std.math.add expects 2 arguments")
        if not all(isinstance(x, int) for x in args):
            raise PantherStdlibError("std.math.add requires integer arguments")
        return args[0] + args[1]

    if name == "std.math.mul":
        if len(args) != 2:
            raise PantherStdlibError("std.math.mul expects 2 arguments")
        if not all(isinstance(x, int) for x in args):
            raise PantherStdlibError("std.math.mul requires integer arguments")
        return args[0] * args[1]

    if name == "std.io.echo":
        if len(args) != 1:
            raise PantherStdlibError("std.io.echo expects 1 argument")
        return str(args[0])

    raise PantherStdlibError(f"Unsupported stdlib function: {name}")
PY

cat > /tmp/panther_phase6_17_patch.py <<'PY'
from pathlib import Path

path = Path("compiler/pipeline/panther_compiler.py")
txt = path.read_text(encoding="utf-8")

imp = "from compiler.stdlib.stdlib_engine import is_stdlib_call, evaluate_stdlib_call, PantherStdlibError\n"
if imp not in txt:
    anchor = "from compiler.modules.modules_engine import validate_module_name, validate_imports, PantherModuleError\n"
    if anchor in txt:
        txt = txt.replace(anchor, anchor + imp)
    else:
        txt = txt.replace("from typing import Any\n", "from typing import Any\n" + imp)

# Patch semantic ExpressionEngine evaluations to support stdlib calls.
txt = txt.replace(
    'value = ExpressionEngine(active_symbols).evaluate(node["value"])',
    'value = evaluate_stdlib_call(node["value"], active_symbols) if is_stdlib_call(node["value"]) else ExpressionEngine(active_symbols).evaluate(node["value"])'
)

txt = txt.replace(
    'value = ExpressionEngine(symbols).evaluate(node["value"])',
    'value = evaluate_stdlib_call(node["value"], symbols) if is_stdlib_call(node["value"]) else ExpressionEngine(symbols).evaluate(node["value"])'
)

txt = txt.replace(
    'call_symbols[param] = ExpressionEngine(active_symbols).evaluate(arg_expr)',
    'call_symbols[param] = evaluate_stdlib_call(arg_expr, active_symbols) if is_stdlib_call(arg_expr) else ExpressionEngine(active_symbols).evaluate(arg_expr)'
)

# Add stdlib errors to semantic and main exception handlers.
exception_tuples = [
    "except (PantherExpressionError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError, PantherModuleError) as exc:",
    "except (PantherCompileError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError, PantherModuleError) as exc:",
]
for old in exception_tuples:
    if old in txt:
        txt = txt.replace(old, old.replace("PantherModuleError", "PantherModuleError, PantherStdlibError"))

if "except PantherCompileError as exc:" in txt:
    txt = txt.replace(
        "except PantherCompileError as exc:",
        "except (PantherCompileError, PantherControlFlowError, PantherLoopError, PantherFunctionError, PantherStructError, PantherModuleError, PantherStdlibError) as exc:"
    )

path.write_text(txt, encoding="utf-8")
print("✅ compiler pipeline patched for stdlib")
PY

python3 /tmp/panther_phase6_17_patch.py
python3 -m py_compile compiler/stdlib/stdlib_engine.py
python3 -m py_compile compiler/pipeline/panther_compiler.py

cat > examples/phase6_stdlib/stdlib_demo.panther <<'EOF'
module panther.stdlib.demo

let name = "panther"
let upper_name = std.text.upper(name)
let lower_name = std.text.lower("PANTHER")
let sum = std.math.add(10, 5)
let product = std.math.mul(3, 7)

print "Standard Library test"
print upper_name
print lower_name
print sum
print product
print std.io.echo("Phase 6.17 stdlib")
EOF

cat > scripts/run_phase6_17_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_17_stdlib_$$.sh"
REPORT="$(./panther compile examples/phase6_stdlib/stdlib_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1]); out = Path(sys.argv[2])
assert report["ok"] is True and out.exists()
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "Standard Library test" in proc.stdout
assert "PANTHER" in proc.stdout
assert "panther" in proc.stdout
assert "15" in proc.stdout
assert "21" in proc.stdout
assert "Phase 6.17 stdlib" in proc.stdout
print("demo=phase6.17-stdlib")
print("ok=true")
print("std_text=true")
print("std_math=true")
print("std_io=true")
print("artifact_runs=true")
PY
rm -f "$OUT"
EOF
chmod +x scripts/run_phase6_17_practical_demo.sh

cat > tests/phase6_17/test_stdlib.py <<'EOF'
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"
def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)
def test_stdlib_demo(tmp_path: Path) -> None:
    out = tmp_path / "stdlib.sh"
    code, data = run_cmd("compile", "examples/phase6_stdlib/stdlib_demo.panther", "--out", str(out))
    assert code == 0 and data["ok"] is True
    proc = subprocess.run([str(out)], text=True, capture_output=True)
    assert proc.returncode == 0
    assert "PANTHER" in proc.stdout
    assert "15" in proc.stdout
    assert "21" in proc.stdout
def test_bad_stdlib_fails(tmp_path: Path) -> None:
    src = tmp_path / "bad_stdlib.panther"
    src.write_text("print std.crypto.hash(\"x\")\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
EOF

cat > docs/phase6/PHASE_6_17_STATUS.md <<'EOF'
# Phase 6.17 Status — Standard Library Foundation PRO

Completed:
- standard library manifest
- stdlib folder layout
- builtin function registry
- std.text.upper
- std.text.lower
- std.math.add
- std.math.mul
- std.io.echo
- compile-time stdlib evaluation
- practical demo
- negative tests
- pytest suite

Next: Phase 6.18 — Runtime Bridge & Build/Run Commands.
EOF

cat > scripts/verify_phase6_17_stdlib.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.17 PRO Standard Library Verification"
echo "============================================================"
test -f compiler/stdlib/stdlib_engine.py
test -f language/compiler/stdlib/stdlib_manifest.json
test -f language/stdlib/text/README.md
test -f language/stdlib/math/README.md
test -f language/stdlib/io/README.md
test -f examples/phase6_stdlib/stdlib_demo.panther
test -x scripts/run_phase6_17_practical_demo.sh
test -f tests/phase6_17/test_stdlib.py
echo "✅ structure tests passed"
OUT="/tmp/panther_phase6_17_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_stdlib/stdlib_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "✅ compiler stdlib tests passed"
RUN_OUT="$("$OUT")"
echo "$RUN_OUT" | grep -q 'Standard Library test'
echo "$RUN_OUT" | grep -q 'PANTHER'
echo "$RUN_OUT" | grep -q '15'
echo "$RUN_OUT" | grep -q '21'
echo "$RUN_OUT" | grep -q 'Phase 6.17 stdlib'
rm -f "$OUT"
echo "✅ emitted artifact stdlib execution tests passed"
TMP_BAD="/tmp/panther_phase6_17_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
print std.crypto.hash("x")
BAD
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_stdlib.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_stdlib.sh
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.17][ERROR] unsupported stdlib call should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"
PRACTICAL_OUT="$(bash scripts/run_phase6_17_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.17-stdlib'
echo "$PRACTICAL_OUT" | grep -q 'std_text=true'
echo "$PRACTICAL_OUT" | grep -q 'std_math=true'
echo "$PRACTICAL_OUT" | grep -q 'std_io=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical stdlib demo passed"
if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_17 >/tmp/panther_phase6_17_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/stdlib/stdlib_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi
echo "✅ PantherLang Phase 6.17 Standard Library verification complete."
EOF
chmod +x scripts/verify_phase6_17_stdlib.sh

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
bash scripts/verify_phase6_17_stdlib.sh
echo "✅ ALL PHASE 6 TESTS PASSED THROUGH 6.17"
EOF
chmod +x scripts/verify_phase6_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 6.17 — Standard Library Foundation PRO

Added standard library foundation:
- stdlib manifest
- stdlib folder layout
- std.text.upper
- std.text.lower
- std.math.add
- std.math.mul
- std.io.echo
- compile-time stdlib evaluation
- practical demo
- negative/failure tests
- pytest suite

Next: Phase 6.18 Runtime Bridge & Build/Run Commands.
EOF

echo "[phase6.17] Running professional verification..."
bash scripts/verify_phase6_17_stdlib.sh

echo "============================================================"
echo " Phase 6.17 COMPLETE"
echo " Next: Phase 6.18 Runtime Bridge & Build/Run Commands"
echo "============================================================"
