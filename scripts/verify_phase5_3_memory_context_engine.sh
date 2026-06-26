#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.3 PRO Verification"
echo "============================================================"

bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency_verify.log
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency_verify.log

test -f architecture/MEMORY_CONTEXT_ENGINE.md
test -f language/memory/core/memory_manifest.json
test -f language/memory/core/memory_types.panther
test -f language/ai/context/context_types.panther
test -f language/memory/policies/default_context.policy.json
test -f language/memory/schemas/memory_record.schema.json
test -x language/memory/runtime/memory_runtime.py
test -f examples/memory/phase5_3_context.panther
test -f examples/memory/phase5_3_practical_expected.txt
test -x scripts/run_phase5_3_practical_demo.sh
test -f tests/phase5_3/test_memory_runtime.py
test -f docs/phase5/PHASE_5_3_STATUS.md
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path

manifest = json.loads(Path("language/memory/core/memory_manifest.json").read_text())
assert manifest["phase"] == "5.3"
assert "5.1" in manifest["depends_on"]
assert "5.2" in manifest["depends_on"]
assert manifest["external_api_required"] is False
assert "practical_demo" in manifest["features"]
assert "negative_tests" in manifest["features"]

policy = json.loads(Path("language/memory/policies/default_context.policy.json").read_text())
assert policy["allow_network"] is False
assert policy["allow_secret_storage"] is False
assert policy["require_audit"] is True
assert policy["retrieval"]["mode"] == "deterministic_keyword"

schema = json.loads(Path("language/memory/schemas/memory_record.schema.json").read_text())
for key in ["key", "scope", "value", "trust", "created_at", "tags", "audit"]:
    assert key in schema["required"]
PY
echo "✅ schema tests passed"

TMP_STORE="/tmp/panther_phase5_3_memory_store_$$.json"
rm -f "$TMP_STORE"

PUT_OUT="$(python3 language/memory/runtime/memory_runtime.py --store "$TMP_STORE" put --key panther.phase --scope project --value "Phase 5.3 Memory Context OK" --trust verified --tags phase5,memory,context)"
echo "$PUT_OUT" | grep -q '"key": "panther.phase"'
echo "$PUT_OUT" | grep -q '"trust": "verified"'
echo "$PUT_OUT" | grep -q '"external_api_used": false'

GET_OUT="$(python3 language/memory/runtime/memory_runtime.py --store "$TMP_STORE" get --key panther.phase --scope project)"
echo "$GET_OUT" | grep -q 'Phase 5.3 Memory Context OK'

SEARCH_OUT="$(python3 language/memory/runtime/memory_runtime.py --store "$TMP_STORE" search --query Memory --scope project)"
echo "$SEARCH_OUT" | grep -q 'panther.phase'

CTX_OUT="$(python3 language/memory/runtime/memory_runtime.py --store "$TMP_STORE" context --query context --scope project)"
echo "$CTX_OUT" | grep -q '"phase": "5.3"'
echo "$CTX_OUT" | grep -q '"context_mode": "deterministic_keyword"'
echo "$CTX_OUT" | grep -q '"external_api_used": false'
echo "$CTX_OUT" | grep -q 'Phase 5.3 Memory Context OK'
rm -f "$TMP_STORE"
echo "✅ runtime tests passed"

DEMO_OUT="$(bash scripts/run_phase5_3_practical_demo.sh)"
echo "$DEMO_OUT" | grep -q 'demo=phase5.3-memory-context'
echo "$DEMO_OUT" | grep -q 'ok=true'
echo "$DEMO_OUT" | grep -q 'external_api_used=false'
echo "$DEMO_OUT" | grep -q 'contains=Memory and Context Engine'
echo "✅ practical PantherLang memory demo passed"

set +e
BAD_OUT="$(python3 language/memory/runtime/memory_runtime.py --store /tmp/panther_bad_scope_$$.json put --key bad --scope forbidden --value x)"
BAD_CODE=$?
set -e
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase5.3][ERROR] invalid scope test should fail with exit code 2"
  exit 1
fi
echo "$BAD_OUT" | grep -q '"ok": false'
echo "$BAD_OUT" | grep -q 'Invalid scope'
echo "✅ negative/failure tests passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase5_3 >/tmp/panther_phase5_3_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile language/memory/runtime/memory_runtime.py
  echo "✅ python compile test passed"
fi

echo "✅ PantherLang Phase 5.3 Memory & Context Engine verification complete."
