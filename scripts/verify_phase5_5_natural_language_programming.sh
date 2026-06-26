#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.5 PRO Verification"
echo "============================================================"

bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency_verify.log
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency_verify.log
bash scripts/verify_phase5_3_memory_context_engine.sh >/tmp/panther_phase5_3_dependency_verify.log
bash scripts/verify_phase5_4_multi_agent_runtime.sh >/tmp/panther_phase5_4_dependency_verify.log

test -f architecture/NATURAL_LANGUAGE_PROGRAMMING.md
test -f language/nlp/core/nlp_manifest.json
test -f language/nlp/core/nlp_types.panther
test -f language/ai/nlp/nlp_agent_types.panther
test -f language/nlp/policies/default_nlp.policy.json
test -f language/nlp/schemas/natural_intent.schema.json
test -x language/nlp/runtime/intent_compiler.py
test -f examples/nlp/phase5_5_intent.json
test -f examples/nlp/phase5_5_natural_language.panther
test -f examples/nlp/phase5_5_practical_expected.txt
test -x scripts/run_phase5_5_practical_demo.sh
test -f tests/phase5_5/test_intent_compiler.py
test -f docs/phase5/PHASE_5_5_STATUS.md
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path

manifest = json.loads(Path("language/nlp/core/nlp_manifest.json").read_text())
assert manifest["phase"] == "5.5"
for dep in ["5.1", "5.2", "5.3", "5.4"]:
    assert dep in manifest["depends_on"]
assert manifest["external_api_required"] is False
assert "deterministic_intent_compiler" in manifest["features"]
assert "negative_tests" in manifest["features"]

policy = json.loads(Path("language/nlp/policies/default_nlp.policy.json").read_text())
assert policy["allow_network"] is False
assert policy["allow_secret_access"] is False
assert policy["allow_shell_execution"] is False
assert policy["require_deterministic_templates"] is True
assert "malware" in policy["blocked_terms"]

schema = json.loads(Path("language/nlp/schemas/natural_intent.schema.json").read_text())
for key in ["id", "text", "policy"]:
    assert key in schema["required"]
PY
echo "✅ schema tests passed"

FUNC_JSON="$(python3 language/nlp/runtime/intent_compiler.py compile --text "Create a function that adds two numbers and print the result.")"
echo "$FUNC_JSON" | grep -q '"phase": "5.5"'
echo "$FUNC_JSON" | grep -q '"ok": true'
echo "$FUNC_JSON" | grep -q '"intent_kind": "function"'
echo "$FUNC_JSON" | grep -q '"external_api_used": false'
echo "$FUNC_JSON" | grep -q '"deterministic": true'
echo "✅ runtime intent compiler tests passed"

python3 - "$FUNC_JSON" <<'PY'
import json
import sys
data = json.loads(sys.argv[1])
src = data["generated_source"]
assert "fn add" in src
assert "return a + b" in src
assert "print add(2, 3)" in src
PY
echo "✅ code generation tests passed"

set +e
BAD_AMBIG="$(python3 language/nlp/runtime/intent_compiler.py negative --case ambiguous)"
BAD_AMBIG_CODE=$?
BAD_UNSAFE="$(python3 language/nlp/runtime/intent_compiler.py negative --case unsafe)"
BAD_UNSAFE_CODE=$?
BAD_EMPTY="$(python3 language/nlp/runtime/intent_compiler.py negative --case empty)"
BAD_EMPTY_CODE=$?
set -e

if [ "$BAD_AMBIG_CODE" -ne 2 ] || [ "$BAD_UNSAFE_CODE" -ne 2 ] || [ "$BAD_EMPTY_CODE" -ne 2 ]; then
  echo "[verify_phase5.5][ERROR] negative tests must fail with exit code 2"
  exit 1
fi
echo "$BAD_AMBIG" | grep -q 'Ambiguous intent'
echo "$BAD_UNSAFE" | grep -q 'Unsafe intent blocked'
echo "$BAD_EMPTY" | grep -q 'Intent text cannot be empty'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase5_5_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=natural-language-to-pantherlang'
echo "$PRACTICAL_OUT" | grep -q 'ok=true'
echo "$PRACTICAL_OUT" | grep -q 'intent_kind=function'
echo "$PRACTICAL_OUT" | grep -q 'external_api_used=false'
echo "$PRACTICAL_OUT" | grep -q 'deterministic=true'
echo "$PRACTICAL_OUT" | grep -q 'contains=fn add'
echo "$PRACTICAL_OUT" | grep -q 'contains=print add(2, 3)'
echo "✅ practical Natural Language to PantherLang demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase5_5 >/tmp/panther_phase5_5_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile language/nlp/runtime/intent_compiler.py
  echo "✅ python compile test passed"
fi

echo "✅ PantherLang Phase 5.5 Natural Language Programming verification complete."
