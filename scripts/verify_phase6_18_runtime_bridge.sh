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
