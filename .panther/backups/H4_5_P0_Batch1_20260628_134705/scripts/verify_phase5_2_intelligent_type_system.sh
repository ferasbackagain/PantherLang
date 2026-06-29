#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.2 Verification"
echo "============================================================"

# Dependency check
bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency_verify.log

test -f architecture/INTELLIGENT_TYPE_SYSTEM.md
test -f language/types/core/type_manifest.json
test -f language/types/core/core_types.panther
test -f language/ai/types/ai_types.panther
test -f language/types/inference/inference_rules.json
test -f language/types/contracts/type_contracts.json
test -x language/types/static_analysis/type_analyzer.py
test -f examples/types/phase5_2_types.panther
test -f examples/types/phase5_2_type_error.panther
test -f docs/phase5/PHASE_5_2_STATUS.md

python3 - <<'PY'
import json
from pathlib import Path

manifest = json.loads(Path("language/types/core/type_manifest.json").read_text())
assert manifest["phase"] == "5.2"
assert "5.1" in manifest["depends_on"]
assert "ai_types" in manifest["features"]
assert "static_analysis" in manifest["features"]

rules = json.loads(Path("language/types/inference/inference_rules.json").read_text())
ids = {rule["id"] for rule in rules["rules"]}
assert "literal-int" in ids
assert "literal-string" in ids
assert "ai-generate" in ids

contracts = json.loads(Path("language/types/contracts/type_contracts.json").read_text())
names = {contract["name"] for contract in contracts["contracts"]}
assert "SafePrompt" in names
assert "BoundedAIOutput" in names
PY

VALID_OUT="$(python3 language/types/static_analysis/type_analyzer.py examples/types/phase5_2_types.panther)"
echo "$VALID_OUT" | grep -q '"phase": "5.2"'
echo "$VALID_OUT" | grep -q '"ok": true'
echo "$VALID_OUT" | grep -q '"name": "String"'
echo "$VALID_OUT" | grep -q '"age": "Int"'

set +e
ERROR_OUT="$(python3 language/types/static_analysis/type_analyzer.py examples/types/phase5_2_type_error.panther 2>/tmp/panther_phase5_2_error_stderr.log)"
ERROR_CODE=$?
set -e

if [ "$ERROR_CODE" -eq 0 ]; then
  echo "[verify_phase5.2][ERROR] Expected analyzer to fail for intentional type error."
  exit 1
fi

echo "$ERROR_OUT" | grep -q '"ok": false'
echo "$ERROR_OUT" | grep -q 'PANTHER-TYPE-001'

echo "✅ Phase 5.2 Intelligent Type System tests passed."
echo "✅ PantherLang Phase 5.2 Intelligent Type System verification complete."
