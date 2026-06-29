#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.9 PRO Verification"
echo "============================================================"

for s in \
 scripts/verify_phase5_1_ai_native_core.sh \
 scripts/verify_phase5_2_intelligent_type_system.sh \
 scripts/verify_phase5_3_memory_context_engine.sh \
 scripts/verify_phase5_4_multi_agent_runtime.sh \
 scripts/verify_phase5_5_natural_language_programming.sh \
 scripts/verify_phase5_6_ai_optimizing_compiler.sh \
 scripts/verify_phase5_7_distributed_execution.sh \
 scripts/verify_phase5_8_secure_ai_sandbox.sh
do
  bash "$s" >/tmp/panther_phase5_9_dependency_verify.log
done

test -f architecture/AI_PACKAGE_ECOSYSTEM.md
test -f language/packages/core/package_manifest.json
test -f language/packages/core/package_types.panther
test -f language/ai/packages/ai_package_types.panther
test -f language/packages/policies/default_package.policy.json
test -f language/packages/schemas/package.schema.json
test -x language/packages/runtime/package_manager.py
test -f examples/packages/phase5_9_package.panther
test -f examples/packages/phase5_9_practical_expected.txt
test -x scripts/run_phase5_9_practical_demo.sh
test -f tests/phase5_9/test_package_manager.py
test -f docs/phase5/PHASE_5_9_STATUS.md
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("language/packages/core/package_manifest.json").read_text())
assert m["phase"] == "5.9"
for dep in ["5.1","5.2","5.3","5.4","5.5","5.6","5.7","5.8"]:
    assert dep in m["depends_on"]
assert m["external_api_required"] is False
assert m["network_required"] is False
assert "local_registry" in m["features"]
assert "signature_simulation" in m["features"]
p = json.loads(Path("language/packages/policies/default_package.policy.json").read_text())
assert p["allow_network_registry"] is False
assert p["allow_unsigned_packages"] is False
assert p["require_integrity_hash"] is True
assert p["require_sandbox_policy"] is True
s = json.loads(Path("language/packages/schemas/package.schema.json").read_text())
for key in ["name","version","kind","entry","dependencies","integrity","signature","sandbox_policy"]:
    assert key in s["required"]
PY
echo "✅ schema tests passed"

REG="/tmp/panther_phase5_9_verify_registry_$$"
DEMO_JSON="$(python3 language/packages/runtime/package_manager.py --registry "$REG" demo)"
echo "$DEMO_JSON" | grep -q '"phase": "5.9"'
echo "$DEMO_JSON" | grep -q '"ok": true'
echo "$DEMO_JSON" | grep -q '"published": true'
echo "$DEMO_JSON" | grep -q '"installed": true'
echo "$DEMO_JSON" | grep -q '"integrity_verified": true'
echo "$DEMO_JSON" | grep -q '"signature_verified": true'
echo "$DEMO_JSON" | grep -q '"sandbox_policy_attached": true'
echo "$DEMO_JSON" | grep -q '"network_used": false'
echo "✅ package manager runtime tests passed"

set +e
BAD_MISSING="$(python3 language/packages/runtime/package_manager.py --registry /tmp/panther_phase5_9_missing_$$ negative --case missing)"
BAD_MISSING_CODE=$?
BAD_KIND="$(python3 language/packages/runtime/package_manager.py --registry /tmp/panther_phase5_9_badkind_$$ negative --case bad-kind)"
BAD_KIND_CODE=$?
BAD_BLOCK="$(python3 language/packages/runtime/package_manager.py --registry /tmp/panther_phase5_9_block_$$ negative --case blocked)"
BAD_BLOCK_CODE=$?
BAD_TAMPER="$(python3 language/packages/runtime/package_manager.py --registry /tmp/panther_phase5_9_tamper_$$ negative --case tamper)"
BAD_TAMPER_CODE=$?
set -e
if [ "$BAD_MISSING_CODE" -ne 2 ] || [ "$BAD_KIND_CODE" -ne 2 ] || [ "$BAD_BLOCK_CODE" -ne 2 ] || [ "$BAD_TAMPER_CODE" -ne 2 ]; then
  echo "[verify_phase5.9][ERROR] negative tests must fail with exit code 2"
  exit 1
fi
echo "$BAD_MISSING" | grep -q 'Package not found'
echo "$BAD_KIND" | grep -q 'Invalid package kind'
echo "$BAD_BLOCK" | grep -q 'Blocked package name'
echo "$BAD_TAMPER" | grep -q 'integrity mismatch'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase5_9_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=ai-package-ecosystem'
echo "$PRACTICAL_OUT" | grep -q 'published=true'
echo "$PRACTICAL_OUT" | grep -q 'installed=true'
echo "$PRACTICAL_OUT" | grep -q 'integrity_verified=true'
echo "$PRACTICAL_OUT" | grep -q 'signature_verified=true'
echo "$PRACTICAL_OUT" | grep -q 'sandbox_policy_attached=true'
echo "✅ practical AI package ecosystem demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase5_9 >/tmp/panther_phase5_9_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile language/packages/runtime/package_manager.py
  echo "✅ python compile test passed"
fi

rm -rf "$REG"
echo "✅ PantherLang Phase 5.9 AI Package Ecosystem verification complete."
