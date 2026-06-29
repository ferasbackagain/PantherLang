#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.6 PRO Verification"
echo "============================================================"

bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency_verify.log
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency_verify.log
bash scripts/verify_phase5_3_memory_context_engine.sh >/tmp/panther_phase5_3_dependency_verify.log
bash scripts/verify_phase5_4_multi_agent_runtime.sh >/tmp/panther_phase5_4_dependency_verify.log
bash scripts/verify_phase5_5_natural_language_programming.sh >/tmp/panther_phase5_5_dependency_verify.log

test -f architecture/AI_OPTIMIZING_COMPILER.md
test -f language/compiler/ai_optimizer/core/optimizer_manifest.json
test -f language/compiler/ai_optimizer/core/optimizer_types.panther
test -f language/ai/compiler/compiler_ai_types.panther
test -f language/compiler/ai_optimizer/policies/default_optimizer.policy.json
test -f language/compiler/ai_optimizer/schemas/optimization_report.schema.json
test -x language/compiler/ai_optimizer/runtime/ai_optimizer.py
test -f examples/compiler/phase5_6_unoptimized.panther
test -f examples/compiler/phase5_6_practical_expected.txt
test -x scripts/run_phase5_6_practical_demo.sh
test -f tests/phase5_6/test_ai_optimizer.py
test -f docs/phase5/PHASE_5_6_STATUS.md
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("language/compiler/ai_optimizer/core/optimizer_manifest.json").read_text())
assert m["phase"] == "5.6"
for dep in ["5.1","5.2","5.3","5.4","5.5"]:
    assert dep in m["depends_on"]
assert m["external_api_required"] is False
assert "constant_folding" in m["features"]
assert "negative_tests" in m["features"]
p = json.loads(Path("language/compiler/ai_optimizer/policies/default_optimizer.policy.json").read_text())
assert p["allow_network"] is False
assert p["allow_external_ai"] is False
assert p["require_deterministic_passes"] is True
s = json.loads(Path("language/compiler/ai_optimizer/schemas/optimization_report.schema.json").read_text())
for key in ["ok","phase","level","passes_applied","before_lines","after_lines","optimized_source","hints","external_api_used","deterministic"]:
    assert key in s["required"]
PY
echo "✅ schema tests passed"

OUT_FILE="/tmp/panther_phase5_6_verify_$$.panther"
OPT_JSON="$(python3 language/compiler/ai_optimizer/runtime/ai_optimizer.py optimize examples/compiler/phase5_6_unoptimized.panther --out "$OUT_FILE")"
echo "$OPT_JSON" | grep -q '"phase": "5.6"'
echo "$OPT_JSON" | grep -q '"ok": true'
echo "$OPT_JSON" | grep -q '"external_api_used": false'
echo "$OPT_JSON" | grep -q '"deterministic": true'
echo "✅ runtime optimizer tests passed"

grep -q 'let x = 14' "$OUT_FILE"
grep -q 'print 14' "$OUT_FILE"
if grep -q 'print ""' "$OUT_FILE"; then
  echo "[verify_phase5.6][ERROR] dead print was not eliminated"
  exit 1
fi
rm -f "$OUT_FILE"
echo "✅ optimization pass tests passed"

set +e
BAD_EMPTY="$(python3 language/compiler/ai_optimizer/runtime/ai_optimizer.py negative --case empty)"
BAD_EMPTY_CODE=$?
BAD_UNBAL="$(python3 language/compiler/ai_optimizer/runtime/ai_optimizer.py negative --case unbalanced)"
BAD_UNBAL_CODE=$?
BAD_UNSAFE="$(python3 language/compiler/ai_optimizer/runtime/ai_optimizer.py negative --case unsafe)"
BAD_UNSAFE_CODE=$?
set -e
if [ "$BAD_EMPTY_CODE" -ne 2 ] || [ "$BAD_UNBAL_CODE" -ne 2 ] || [ "$BAD_UNSAFE_CODE" -ne 2 ]; then
  echo "[verify_phase5.6][ERROR] negative tests must fail with exit code 2"
  exit 1
fi
echo "$BAD_EMPTY" | grep -q 'Source cannot be empty'
echo "$BAD_UNBAL" | grep -q 'unbalanced braces'
echo "$BAD_UNSAFE" | grep -q 'Unsafe optimizer marker blocked'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase5_6_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=ai-optimizing-compiler'
echo "$PRACTICAL_OUT" | grep -q 'ok=true'
echo "$PRACTICAL_OUT" | grep -q 'contains=let x = 14'
echo "$PRACTICAL_OUT" | grep -q 'contains=print 14'
echo "✅ practical AI optimizing compiler demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase5_6 >/tmp/panther_phase5_6_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile language/compiler/ai_optimizer/runtime/ai_optimizer.py
  echo "✅ python compile test passed"
fi

echo "✅ PantherLang Phase 5.6 AI Optimizing Compiler verification complete."
