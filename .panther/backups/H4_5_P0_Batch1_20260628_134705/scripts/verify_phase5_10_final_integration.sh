#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.10 PRO Final Verification"
echo "============================================================"

for s in \
 scripts/verify_phase5_1_ai_native_core.sh \
 scripts/verify_phase5_2_intelligent_type_system.sh \
 scripts/verify_phase5_3_memory_context_engine.sh \
 scripts/verify_phase5_4_multi_agent_runtime.sh \
 scripts/verify_phase5_5_natural_language_programming.sh \
 scripts/verify_phase5_6_ai_optimizing_compiler.sh \
 scripts/verify_phase5_7_distributed_execution.sh \
 scripts/verify_phase5_8_secure_ai_sandbox.sh \
 scripts/verify_phase5_9_ai_package_ecosystem.sh
do
  test -f "$s"
done
echo "✅ dependency script presence tests passed"

for s in \
 scripts/verify_phase5_1_ai_native_core.sh \
 scripts/verify_phase5_2_intelligent_type_system.sh \
 scripts/verify_phase5_3_memory_context_engine.sh \
 scripts/verify_phase5_4_multi_agent_runtime.sh \
 scripts/verify_phase5_5_natural_language_programming.sh \
 scripts/verify_phase5_6_ai_optimizing_compiler.sh \
 scripts/verify_phase5_7_distributed_execution.sh \
 scripts/verify_phase5_8_secure_ai_sandbox.sh \
 scripts/verify_phase5_9_ai_package_ecosystem.sh
do
  bash "$s" >/tmp/panther_phase5_10_dependency.log
done
echo "✅ full phase regression tests passed"

test -f language/ai_native_foundation.json
test -f docs/phase5/PHASE_5_FINAL_REPORT.md
test -f docs/phase5/AI_NATIVE_ROADMAP.md
test -f docs/phase5/PHASE_5_TEST_MATRIX.md
test -f docs/phase5/PHASE_5_ENGINEERING_STANDARD.md
test -x scripts/run_phase5_final_demo.sh
test -f tests/phase5_10/test_phase5_manifest.py
echo "✅ final integration structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path("language/ai_native_foundation.json").read_text())
assert data["phase"] == "5.10"
assert data["status"] == "phase-5-complete"
assert data["engineering_rule"] == "No Feature Without Proof"
assert data["external_api_required"] is False
assert data["network_required"] is False
assert len(data["completed_phases"]) == 10
PY
echo "✅ final manifest tests passed"

DEMO_OUT="$(bash scripts/run_phase5_final_demo.sh)"
echo "$DEMO_OUT" | grep -q 'demo=phase5-ai-native-foundation'
echo "$DEMO_OUT" | grep -q 'ai_core=ok'
echo "$DEMO_OUT" | grep -q 'types=ok'
echo "$DEMO_OUT" | grep -q 'memory_context=ok'
echo "$DEMO_OUT" | grep -q 'multi_agent=ok'
echo "$DEMO_OUT" | grep -q 'natural_language_programming=ok'
echo "$DEMO_OUT" | grep -q 'ai_optimizer=ok'
echo "$DEMO_OUT" | grep -q 'distributed_execution=ok'
echo "$DEMO_OUT" | grep -q 'secure_sandbox=ok'
echo "$DEMO_OUT" | grep -q 'package_ecosystem=ok'
echo "$DEMO_OUT" | grep -q 'phase5_complete=true'
echo "✅ practical final AI-native foundation demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase5_10 >/tmp/panther_phase5_10_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile tests/phase5_10/test_phase5_manifest.py
  echo "✅ python compile test passed"
fi

echo "✅ PantherLang Phase 5.10 Final Integration verification complete."
echo "✅ PantherLang Phase 5 AI-Native Foundation is COMPLETE."
