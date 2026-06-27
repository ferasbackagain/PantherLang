#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 6.20 PRO Production Readiness Verification"
echo "============================================================"

test -f production/production_manifest.json
test -f docs/phase6/PHASE_6_20_STATUS.md
test -f docs/PHASE_6_COMPLETION_REPORT.md
test -f release/PHASE_6_RELEASE_NOTES.md
test -f examples/phase6_production/production_demo.panther
test -x scripts/run_phase6_20_practical_demo.sh
test -f tests/phase6_20/test_production_readiness.py
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("production/production_manifest.json").read_text())
assert m["phase"] == "6.20"
assert m["status"] == "phase-6-production-ready"
assert m["external_api_required"] is False
assert "compiler_pipeline" in m["capabilities"]
assert "runtime_bridge" in m["capabilities"]
assert "fast_regression" in m["capabilities"]
print("✅ manifest tests passed")
PY

OUT="/tmp/panther_phase6_20_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_production/production_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "✅ compiler release tests passed"

RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Production readiness demo'
echo "$RUN_OUT" | grep -q 'PantherLang'
echo "$RUN_OUT" | grep -q '0.6.20'
echo "$RUN_OUT" | grep -q 'Phase 6.20 production readiness'
rm -f "$OUT"
echo "✅ emitted artifact release execution tests passed"

bash scripts/verify_phase6_19_fast_regression.sh >/tmp/panther_phase6_20_fast_regression.log
echo "✅ fast regression baseline passed"

PRACTICAL_OUT="$(bash scripts/run_phase6_20_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.20-production-readiness'
echo "$PRACTICAL_OUT" | grep -q 'release_ready=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical production demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_20 >/tmp/panther_phase6_20_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi

echo "✅ PantherLang Phase 6.20 Production Readiness verification complete."
