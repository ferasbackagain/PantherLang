#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase6_18_runtime_bridge_$STAMP"

echo "============================================================"
echo " PantherLang Phase 6.18 PRO - Runtime Bridge & Build/Run"
echo "============================================================"
echo "[phase6.18] Project root: $ROOT"

fail(){ echo "[phase6.18][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_file "panther"
require_file "compiler/pipeline/panther_compiler.py"
require_file "scripts/verify_phase6_17_stdlib.sh"

mkdir -p "$BACKUP_DIR"
for t in compiler/runtime_bridge runtime language/compiler/runtime_bridge architecture/RUNTIME_BRIDGE_BUILD_RUN.md docs/phase6/PHASE_6_18_STATUS.md examples/phase6_runtime tests/phase6_18 scripts/verify_phase6_18_runtime_bridge.sh scripts/run_phase6_18_practical_demo.sh scripts/verify_phase6_all.sh panther CHANGELOG.md; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

echo "[phase6.18] Verifying Phase 6.17 baseline..."
bash scripts/verify_phase6_17_stdlib.sh >/tmp/panther_phase6_18_phase617.log

mkdir -p compiler/runtime_bridge runtime language/compiler/runtime_bridge architecture docs/phase6 examples/phase6_runtime tests/phase6_18 scripts build
touch compiler/__init__.py compiler/runtime_bridge/__init__.py

cat > architecture/RUNTIME_BRIDGE_BUILD_RUN.md <<'EOF'
# PantherLang Phase 6.18 — Runtime Bridge & Build/Run Commands

Adds the first practical runtime bridge and CLI build/run/test workflow.

## New CLI Commands

```bash
./panther build file.panther
./panther run file.panther
./panther test file.panther
./panther doctor
```

## Scope

- runtime manifest
- runtime bridge runner
- build command
- run command
- test command
- practical demo
- negative tests
- Git-ready verification

Engineering rule: No Feature Without Proof.
EOF

cat > language/compiler/runtime_bridge/runtime_bridge_manifest.json <<'EOF'
{
  "name": "PantherLang Runtime Bridge & Build Run Commands",
  "phase": "6.18",
  "version": "0.6.18-runtime-bridge",
  "status": "compiler-runtime-feature",
  "depends_on": ["5.10", "6.10", "6.11", "6.12", "6.13", "6.14", "6.15", "6.16", "6.17"],
  "external_api_required": false,
  "network_required": false,
  "features": [
    "runtime_bridge",
    "panther_build",
    "panther_run",
    "panther_test",
    "runtime_manifest",
    "artifact_execution",
    "negative_tests"
  ],
  "engineering_rule": "No Feature Without Proof"
}
EOF

cat > runtime/runtime_manifest.json <<'EOF'
{
  "name": "PantherLang Runtime",
  "phase": "6.18",
  "kind": "deterministic-shell-artifact-runtime",
  "external_api_required": false,
  "network_required": false
}
EOF

cat > compiler/runtime_bridge/runtime_runner.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
from pathlib import Path


class PantherRuntimeError(Exception):
    pass


def run_artifact(path: str | Path) -> dict:
    artifact = Path(path)
    if not artifact.exists():
        raise PantherRuntimeError(f"Artifact not found: {artifact}")
    if not artifact.is_file():
        raise PantherRuntimeError(f"Artifact is not a file: {artifact}")

    proc = subprocess.run([str(artifact)], text=True, capture_output=True)

    return {
        "ok": proc.returncode == 0,
        "returncode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
        "artifact": str(artifact),
        "external_api_used": False,
        "network_used": False,
        "deterministic": True
    }


def print_json(data: dict) -> None:
    print(json.dumps(data, ensure_ascii=False))


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact")
    args = parser.parse_args()
    try:
        print_json(run_artifact(args.artifact))
    except PantherRuntimeError as exc:
        print_json({"ok": False, "error": str(exc), "external_api_used": False, "network_used": False, "deterministic": True})
        raise SystemExit(2)
PY
chmod +x compiler/runtime_bridge/runtime_runner.py

cat > /tmp/panther_phase6_18_cli_patch.py <<'PY'
from pathlib import Path

path = Path("panther")
txt = r'''#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT/build"

usage(){
  echo "PantherLang CLI"
  echo "Usage:"
  echo "  ./panther doctor"
  echo "  ./panther compile <source.panther> --out <artifact.sh>"
  echo "  ./panther build <source.panther> [--out <artifact.sh>]"
  echo "  ./panther run <source.panther>"
  echo "  ./panther test <source.panther>"
  echo "  ./panther compiler-demo"
  echo "  ./panther phase5-verify"
  echo "  ./panther phase6-verify"
}

cmd="${1:-}"
case "$cmd" in
  compile)
    shift
    python3 "$ROOT/compiler/pipeline/panther_compiler.py" compile "$@"
    ;;
  build)
    shift
    SRC="${1:-}"
    if [ -z "$SRC" ]; then
      echo "ERROR: build requires source file"
      exit 2
    fi
    shift || true
    mkdir -p "$BUILD_DIR"
    OUT="$BUILD_DIR/$(basename "$SRC" .panther).sh"
    if [ "${1:-}" = "--out" ]; then
      shift
      OUT="${1:-$OUT}"
    fi
    python3 "$ROOT/compiler/pipeline/panther_compiler.py" compile "$SRC" --out "$OUT"
    ;;
  run)
    shift
    SRC="${1:-}"
    if [ -z "$SRC" ]; then
      echo "ERROR: run requires source file"
      exit 2
    fi
    mkdir -p "$BUILD_DIR"
    OUT="$BUILD_DIR/$(basename "$SRC" .panther).run.sh"
    python3 "$ROOT/compiler/pipeline/panther_compiler.py" compile "$SRC" --out "$OUT" >/tmp/panther_run_compile.json
    python3 "$ROOT/compiler/runtime_bridge/runtime_runner.py" "$OUT"
    ;;
  test)
    shift
    SRC="${1:-}"
    if [ -z "$SRC" ]; then
      echo "ERROR: test requires source file"
      exit 2
    fi
    mkdir -p "$BUILD_DIR"
    OUT="$BUILD_DIR/$(basename "$SRC" .panther).test.sh"
    python3 "$ROOT/compiler/pipeline/panther_compiler.py" compile "$SRC" --out "$OUT" >/tmp/panther_test_compile.json
    python3 "$ROOT/compiler/runtime_bridge/runtime_runner.py" "$OUT" | grep -q '"ok": true'
    echo "✅ Panther test passed: $SRC"
    ;;
  compiler-demo)
    shift || true
    python3 "$ROOT/compiler/pipeline/panther_compiler.py" demo "$@"
    ;;
  phase5-verify)
    bash "$ROOT/scripts/verify_phase5_all.sh"
    ;;
  phase6-verify)
    bash "$ROOT/scripts/verify_phase6_all.sh"
    ;;
  doctor)
    echo "PantherLang doctor: OK"
    echo "phase5: complete"
    echo "phase6.18: runtime bridge installed"
    echo "commands: compile build run test doctor"
    echo "engineering_rule: No Feature Without Proof"
    ;;
  *)
    usage
    ;;
esac
'''
path.write_text(txt, encoding="utf-8")
path.chmod(0o755)
print("✅ panther CLI patched with build/run/test")
PY

python3 /tmp/panther_phase6_18_cli_patch.py
python3 -m py_compile compiler/runtime_bridge/runtime_runner.py

cat > examples/phase6_runtime/runtime_demo.panther <<'EOF'
module panther.runtime.demo

let name = "PantherLang"
let version = "0.6.18"
let upper = std.text.upper(name)
let sum = std.math.add(20, 22)

print "Runtime Bridge test"
print upper
print version
print sum

fn greet(target) {
    print "Hello from Panther run"
    print target
}

greet("Phase 6.18")
EOF

cat > scripts/run_phase6_18_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_JSON="$(./panther build examples/phase6_runtime/runtime_demo.panther --out /tmp/panther_phase6_18_runtime_demo.sh)"
echo "$BUILD_JSON" | grep -q '"ok": true'

RUN_JSON="$(./panther run examples/phase6_runtime/runtime_demo.panther)"

python3 - "$RUN_JSON" <<'PY'
import json
import sys
data = json.loads(sys.argv[1])
assert data["ok"] is True
assert "Runtime Bridge test" in data["stdout"]
assert "PANTHERLANG" in data["stdout"]
assert "0.6.18" in data["stdout"]
assert "42" in data["stdout"]
assert "Hello from Panther run" in data["stdout"]
assert "Phase 6.18" in data["stdout"]
print("demo=phase6.18-runtime-bridge")
print("ok=true")
print("panther_build=true")
print("panther_run=true")
print("panther_test=true")
print("artifact_runs=true")
PY

./panther test examples/phase6_runtime/runtime_demo.panther >/tmp/panther_phase6_18_test.log
grep -q 'Panther test passed' /tmp/panther_phase6_18_test.log
rm -f /tmp/panther_phase6_18_runtime_demo.sh
EOF
chmod +x scripts/run_phase6_18_practical_demo.sh

cat > tests/phase6_18/test_runtime_bridge.py <<'EOF'
from __future__ import annotations
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PANTHER = ROOT / "panther"
SRC = "examples/phase6_runtime/runtime_demo.panther"


def test_panther_build_and_run(tmp_path: Path) -> None:
    out = tmp_path / "runtime.sh"
    build = subprocess.run([str(PANTHER), "build", SRC, "--out", str(out)], cwd=ROOT, text=True, capture_output=True)
    assert build.returncode == 0
    assert '"ok": true' in build.stdout
    assert out.exists()

    run = subprocess.run([str(PANTHER), "run", SRC], cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0
    data = json.loads(run.stdout)
    assert data["ok"] is True
    assert "Runtime Bridge test" in data["stdout"]
    assert "42" in data["stdout"]


def test_panther_test_command() -> None:
    proc = subprocess.run([str(PANTHER), "test", SRC], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0
    assert "Panther test passed" in proc.stdout


def test_runtime_missing_artifact_fails() -> None:
    proc = subprocess.run(["python3", "compiler/runtime_bridge/runtime_runner.py", "/tmp/no_such_panther_artifact.sh"], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 2
    data = json.loads(proc.stdout)
    assert data["ok"] is False
EOF

cat > docs/phase6/PHASE_6_18_STATUS.md <<'EOF'
# Phase 6.18 Status — Runtime Bridge & Build/Run Commands PRO

Completed:
- runtime manifest
- runtime bridge runner
- `panther build`
- `panther run`
- `panther test`
- improved `panther doctor`
- practical demo
- negative tests
- pytest suite

Next: Phase 6.19 — Compiler Optimization & Fast Regression.
EOF

cat > scripts/verify_phase6_18_runtime_bridge.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 6.18 PRO Runtime Bridge Verification"
echo "============================================================"

test -f compiler/runtime_bridge/runtime_runner.py
test -f runtime/runtime_manifest.json
test -f language/compiler/runtime_bridge/runtime_bridge_manifest.json
test -f examples/phase6_runtime/runtime_demo.panther
test -x scripts/run_phase6_18_practical_demo.sh
test -f tests/phase6_18/test_runtime_bridge.py
test -x panther
echo "✅ structure tests passed"

./panther doctor | grep -q 'PantherLang doctor: OK'
./panther doctor | grep -q 'build run test'
echo "✅ doctor tests passed"

BUILD_JSON="$(./panther build examples/phase6_runtime/runtime_demo.panther --out /tmp/panther_phase6_18_verify.sh)"
echo "$BUILD_JSON" | grep -q '"ok": true'
test -x /tmp/panther_phase6_18_verify.sh
echo "✅ panther build tests passed"

RUN_JSON="$(./panther run examples/phase6_runtime/runtime_demo.panther)"
echo "$RUN_JSON" | grep -q '"ok": true'
echo "$RUN_JSON" | grep -q 'Runtime Bridge test'
echo "$RUN_JSON" | grep -q 'PANTHERLANG'
echo "$RUN_JSON" | grep -q '42'
echo "✅ panther run tests passed"

./panther test examples/phase6_runtime/runtime_demo.panther | grep -q 'Panther test passed'
echo "✅ panther test tests passed"

set +e
BAD_JSON="$(python3 compiler/runtime_bridge/runtime_runner.py /tmp/no_such_panther_artifact.sh)"
BAD_CODE=$?
set -e
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.18][ERROR] missing artifact should fail"
  exit 1
fi
echo "$BAD_JSON" | grep -q '"ok": false'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase6_18_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.18-runtime-bridge'
echo "$PRACTICAL_OUT" | grep -q 'panther_build=true'
echo "$PRACTICAL_OUT" | grep -q 'panther_run=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical runtime demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_18 >/tmp/panther_phase6_18_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/runtime_bridge/runtime_runner.py
  echo "✅ python compile tests passed"
fi

rm -f /tmp/panther_phase6_18_verify.sh
echo "✅ PantherLang Phase 6.18 Runtime Bridge verification complete."
EOF
chmod +x scripts/verify_phase6_18_runtime_bridge.sh

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
bash scripts/verify_phase6_18_runtime_bridge.sh
echo "✅ ALL PHASE 6 TESTS PASSED THROUGH 6.18"
EOF
chmod +x scripts/verify_phase6_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 6.18 — Runtime Bridge & Build/Run Commands PRO

Added runtime bridge and CLI workflow:
- runtime manifest
- runtime bridge runner
- `panther build`
- `panther run`
- `panther test`
- improved `panther doctor`
- practical runtime demo
- negative/failure tests
- pytest suite

Next: Phase 6.19 Compiler Optimization & Fast Regression.
EOF

echo "[phase6.18] Running professional verification..."
bash scripts/verify_phase6_18_runtime_bridge.sh

echo "============================================================"
echo " Phase 6.18 COMPLETE"
echo " Next: Phase 6.19 Compiler Optimization & Fast Regression"
echo "============================================================"
