#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 6.10 PRO Final Compiler Verification"
echo "============================================================"

bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_10_phase5_regression.log
echo "✅ Phase 5 regression tests passed"

test -f architecture/FINAL_COMPILER_INTEGRATION.md
test -f language/compiler/final/compiler_final_manifest.json
test -f compiler/pipeline/panther_compiler.py
test -f compiler/diagnostics/diagnostics.py
test -f compiler/runtime_bridge/runtime_bridge.py
test -f examples/phase6_final/hello_phase6_10.panther
test -f examples/phase6_final/phase6_10_expected.txt
test -x scripts/run_phase6_10_practical_demo.sh
test -f tests/phase6_10/test_final_compiler.py
test -f docs/phase6/PHASE_6_10_STATUS.md
test -f docs/phase6/PHASE_6_FINAL_REPORT.md
test -f docs/phase6/PHASE_6_TEST_MATRIX.md
test -f docs/phase6/COMPILER_RELEASE_NOTES.md
test -x panther
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
manifest = json.loads(Path("language/compiler/final/compiler_final_manifest.json").read_text())
assert manifest["phase"] == "6.10"
assert manifest["status"] == "phase-6-final"
assert manifest["engineering_rule"] == "No Feature Without Proof"
assert manifest["external_api_required"] is False
assert manifest["network_required"] is False
for feature in ["compiler_pipeline", "diagnostics", "runtime_bridge", "cli_compile", "practical_demo", "negative_tests"]:
    assert feature in manifest["features"]
PY
echo "✅ manifest tests passed"

OUT="/tmp/panther_phase6_10_verify_artifact_$$.sh"
COMPILE_JSON="$(python3 compiler/pipeline/panther_compiler.py compile examples/phase6_final/hello_phase6_10.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"phase": "6.10"'
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "$COMPILE_JSON" | grep -q '"external_api_used": false'
echo "$COMPILE_JSON" | grep -q '"network_used": false'
echo "✅ compiler pipeline tests passed"

RUN_OUT="$("$OUT")"
echo "$RUN_OUT" | grep -q 'PantherLang compiled artifact'
echo "$RUN_OUT" | grep -q 'Phase 6.10 compiler integration works'
rm -f "$OUT"
echo "✅ emitted artifact execution tests passed"

set +e
BAD_EMPTY="$(python3 compiler/pipeline/panther_compiler.py negative --case empty)"
BAD_EMPTY_CODE=$?
BAD_UNSUPPORTED="$(python3 compiler/pipeline/panther_compiler.py negative --case unsupported)"
BAD_UNSUPPORTED_CODE=$?
BAD_PANIC="$(python3 compiler/pipeline/panther_compiler.py negative --case panic)"
BAD_PANIC_CODE=$?
set -e
if [ "$BAD_EMPTY_CODE" -ne 2 ] || [ "$BAD_UNSUPPORTED_CODE" -ne 2 ] || [ "$BAD_PANIC_CODE" -ne 2 ]; then
  echo "[verify_phase6.10][ERROR] negative tests must fail with exit code 2"
  exit 1
fi
echo "$BAD_EMPTY" | grep -q 'Source cannot be empty'
echo "$BAD_UNSUPPORTED" | grep -q 'Unsupported statement'
echo "$BAD_PANIC" | grep -q 'Compiler panic marker blocked'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase6_10_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=final-compiler-integration'
echo "$PRACTICAL_OUT" | grep -q 'ok=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "$PRACTICAL_OUT" | grep -q 'contains=Phase 6.10 compiler integration works'
echo "✅ practical final compiler demo passed"

./panther doctor | grep -q 'PantherLang doctor: OK'
CLI_OUT="/tmp/panther_phase6_10_cli_artifact_$$.sh"
./panther compile examples/phase6_final/hello_phase6_10.panther --out "$CLI_OUT" >/tmp/panther_phase6_10_cli_compile.log
"$CLI_OUT" | grep -q 'Phase 6.10 compiler integration works'
rm -f "$CLI_OUT"
echo "✅ CLI integration tests passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_10 >/tmp/panther_phase6_10_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  python3 -m py_compile compiler/diagnostics/diagnostics.py
  python3 -m py_compile compiler/runtime_bridge/runtime_bridge.py
  echo "✅ python compile tests passed"
fi

echo "✅ PantherLang Phase 6.10 Final Compiler Integration verification complete."
