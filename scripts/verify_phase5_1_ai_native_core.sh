#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.1 Verification"
echo "============================================================"

test -f architecture/AI_NATIVE_CORE.md
test -f language/ai/core/manifest.json
test -f language/ai/core/capabilities.panther
test -f language/ai/policies/default_safe.policy.json
test -f language/ai/policies/code_safe.policy.json
test -f language/ai/prompts/prompt_contract.schema.json
test -x language/ai/runtime/ai_runtime.py
test -f examples/ai_native/hello_ai_contract.json
test -f examples/ai_native/hello_ai.panther
test -f docs/phase5/PHASE_5_1_STATUS.md

python3 - <<'PY'
import json
from pathlib import Path

manifest = json.loads(Path("language/ai/core/manifest.json").read_text())
assert manifest["phase"] == "5.1"
assert manifest["external_api_required"] is False
assert "prompt_contracts" in manifest["capabilities"]

policy = json.loads(Path("language/ai/policies/default_safe.policy.json").read_text())
assert policy["network"] is False
assert policy["secrets"] == "deny"
assert policy["audit_required"] is True

schema = json.loads(Path("language/ai/prompts/prompt_contract.schema.json").read_text())
assert "id" in schema["required"]
assert "capability" in schema["required"]
assert "policy" in schema["required"]

contract = json.loads(Path("examples/ai_native/hello_ai_contract.json").read_text())
assert contract["capability"] == "ai.text.generate"
assert contract["policy"] == "default_safe"
PY

OUT="$(python3 language/ai/runtime/ai_runtime.py examples/ai_native/hello_ai_contract.json)"
echo "$OUT" | grep -q '"provider": "deterministic_mock"'
echo "$OUT" | grep -q '"phase": "5.1"'
echo "$OUT" | grep -q '"external_api_used": false'
echo "$OUT" | grep -q 'Hello from PantherLang Phase 5.1 AI Native Core.'

echo "✅ Phase 5.1 AI Native Core tests passed."
echo "✅ PantherLang Phase 5.1 AI Native Core verification complete."
