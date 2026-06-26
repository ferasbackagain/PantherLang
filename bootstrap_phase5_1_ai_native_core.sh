#!/usr/bin/env bash
set -euo pipefail

# PantherLang Phase 5.1
# AI Native Language Foundation - AI Core Bootstrap
#
# Run from the PantherLang Developer Edition project root:
#   cd ~/pantherlang/PantherLang_Developer_Edition_v0_5
#   bash bootstrap_phase5_1_ai_native_core.sh

PHASE="5.1"
PROJECT_ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_ROOT/.phase_backups/phase5_1_$STAMP"

echo "============================================================"
echo " PantherLang Phase 5.1 - AI Native Core Bootstrap"
echo "============================================================"
echo "[phase5.1] Project root: $PROJECT_ROOT"

fail() {
  echo "[phase5.1][ERROR] $1" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "Required file missing: $1"
}

require_dir() {
  [ -d "$1" ] || fail "Required directory missing: $1"
}

# Safety checks: this script must run from the real Developer Edition root.
require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_dir "language"
require_dir "scripts"
require_dir "architecture"

if [ ! -f "scripts/verify_phase4_31_to_40.sh" ]; then
  fail "This does not look like the PantherLang Developer Edition root. cd into PantherLang_Developer_Edition_v0_5 first."
fi

mkdir -p "$BACKUP_DIR"

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$target")"
    cp -a "$target" "$BACKUP_DIR/$target"
  fi
}

echo "[phase5.1] Creating backup at: $BACKUP_DIR"

backup_if_exists "language/ai"
backup_if_exists "architecture/AI_NATIVE_CORE.md"
backup_if_exists "docs/phase5"
backup_if_exists "examples/ai_native"
backup_if_exists "scripts/verify_phase5_1_ai_native_core.sh"
backup_if_exists "CHANGELOG.md"

echo "[phase5.1] Creating AI Native Core directories..."
mkdir -p \
  language/ai/core \
  language/ai/runtime \
  language/ai/policies \
  language/ai/prompts \
  architecture \
  docs/phase5 \
  examples/ai_native \
  scripts

cat > "architecture/AI_NATIVE_CORE.md" <<'MD'
# PantherLang Phase 5.1 — AI Native Core

Phase 5.1 introduces the first official AI-native layer for PantherLang.

## Goal

PantherLang should not treat AI as an external plugin only. The language must contain a stable AI abstraction layer that can later support:

- AI-aware compiler passes
- Prompt contracts
- agent declarations
- secure tool execution
- memory/context handling
- deterministic fallbacks
- policy-controlled execution

## Current Phase Scope

This phase does **not** connect to paid APIs or external services. It creates the internal language foundation only.

Implemented in Phase 5.1:

- AI core metadata
- AI capability model
- AI policy model
- prompt contract format
- local deterministic mock provider
- AI runtime entrypoint
- example AI-native Panther source
- verification script

## Future Expansion

Phase 5.2 will build the Intelligent Type System on top of this layer.
MD

cat > "language/ai/core/manifest.json" <<'JSON'
{
  "name": "PantherLang AI Native Core",
  "phase": "5.1",
  "version": "0.5.1-ai-core",
  "status": "experimental-foundation",
  "external_api_required": false,
  "capabilities": [
    "prompt_contracts",
    "capability_declarations",
    "policy_guardrails",
    "deterministic_mock_provider",
    "runtime_entrypoint"
  ]
}
JSON

cat > "language/ai/core/capabilities.panther" <<'PAN'
# PantherLang AI Native Capability Declarations
# Phase 5.1 foundation syntax draft

capability ai.text.generate {
  description: "Generate text from a prompt contract"
  deterministic: false
  policy: "default_safe"
}

capability ai.text.classify {
  description: "Classify text using a declared schema"
  deterministic: false
  policy: "default_safe"
}

capability ai.code.explain {
  description: "Explain source code with bounded context"
  deterministic: false
  policy: "code_safe"
}
PAN

cat > "language/ai/policies/default_safe.policy.json" <<'JSON'
{
  "name": "default_safe",
  "phase": "5.1",
  "network": false,
  "filesystem": "read_project_only",
  "secrets": "deny",
  "max_prompt_chars": 8000,
  "max_output_chars": 4000,
  "allow_tools": false,
  "audit_required": true
}
JSON

cat > "language/ai/policies/code_safe.policy.json" <<'JSON'
{
  "name": "code_safe",
  "phase": "5.1",
  "network": false,
  "filesystem": "read_project_only",
  "secrets": "deny",
  "max_prompt_chars": 12000,
  "max_output_chars": 6000,
  "allow_tools": false,
  "audit_required": true,
  "code_execution": false
}
JSON

cat > "language/ai/prompts/prompt_contract.schema.json" <<'JSON'
{
  "title": "PantherLang Prompt Contract",
  "phase": "5.1",
  "type": "object",
  "required": ["id", "capability", "input", "policy"],
  "properties": {
    "id": {
      "type": "string"
    },
    "capability": {
      "type": "string"
    },
    "input": {
      "type": "string"
    },
    "policy": {
      "type": "string"
    },
    "output_schema": {
      "type": "object"
    },
    "deterministic_fallback": {
      "type": "string"
    }
  }
}
JSON

cat > "language/ai/runtime/ai_runtime.py" <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


class PantherAIRuntimeError(Exception):
    pass


class DeterministicMockProvider:
    """Local provider for Phase 5.1.

    It intentionally does not call external APIs. This gives PantherLang a
    stable testable AI runtime boundary before real providers are integrated.
    """

    def run(self, contract: dict[str, Any]) -> dict[str, Any]:
        required = ["id", "capability", "input", "policy"]
        missing = [key for key in required if key not in contract]
        if missing:
            raise PantherAIRuntimeError(f"Missing prompt contract keys: {', '.join(missing)}")

        text = str(contract["input"]).strip()
        capability = str(contract["capability"])

        if capability == "ai.text.classify":
            result = "non_empty" if text else "empty"
        elif capability == "ai.code.explain":
            result = "Phase 5.1 mock explanation: source received and bounded by policy."
        else:
            fallback = contract.get("deterministic_fallback")
            result = fallback or f"Phase 5.1 mock response for: {text[:80]}"

        return {
            "provider": "deterministic_mock",
            "phase": "5.1",
            "contract_id": contract["id"],
            "capability": capability,
            "policy": contract["policy"],
            "result": result,
            "external_api_used": False
        }


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise PantherAIRuntimeError(f"Invalid JSON in {path}: {exc}") from exc


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-ai-runtime")
    parser.add_argument("contract", help="Path to prompt contract JSON")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output")
    args = parser.parse_args(argv)

    contract_path = Path(args.contract)
    if not contract_path.exists():
        raise SystemExit(f"Prompt contract not found: {contract_path}")

    contract = load_json(contract_path)
    output = DeterministicMockProvider().run(contract)

    if args.pretty:
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        print(json.dumps(output, ensure_ascii=False))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x "language/ai/runtime/ai_runtime.py"

cat > "examples/ai_native/hello_ai_contract.json" <<'JSON'
{
  "id": "hello-ai-phase-5-1",
  "capability": "ai.text.generate",
  "input": "Say hello from PantherLang AI Native Core.",
  "policy": "default_safe",
  "deterministic_fallback": "Hello from PantherLang Phase 5.1 AI Native Core."
}
JSON

cat > "examples/ai_native/hello_ai.panther" <<'PAN'
# PantherLang Phase 5.1 AI Native syntax draft

ai use capability ai.text.generate with policy default_safe

let message = ai.generate {
  input: "Say hello from PantherLang AI Native Core."
  fallback: "Hello from PantherLang Phase 5.1 AI Native Core."
}

print message
PAN

cat > "docs/phase5/PHASE_5_1_STATUS.md" <<'MD'
# Phase 5.1 Status — AI Native Core

## Completed

- Created AI core manifest.
- Created AI capability declarations.
- Created default AI safety policies.
- Created prompt contract schema.
- Created local deterministic mock provider.
- Created example AI-native contract.
- Created example `.panther` syntax draft.
- Created verification script.

## Important

This phase is intentionally offline and deterministic. No OpenAI key, Gemini key, Claude key, or other provider key is required.

## Verification

Run from project root:

```bash
bash scripts/verify_phase5_1_ai_native_core.sh
```

Expected final line:

```text
PantherLang Phase 5.1 AI Native Core verification complete.
```

## Next Phase

Phase 5.2 — Intelligent Type System.
MD

cat > "scripts/verify_phase5_1_ai_native_core.sh" <<'SH'
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
SH
chmod +x "scripts/verify_phase5_1_ai_native_core.sh"

cat >> "CHANGELOG.md" <<'MD'

## Phase 5.1 — AI Native Core

Added the first AI-native foundation layer:

- AI core manifest
- capability declarations
- safety policy files
- prompt contract schema
- deterministic local AI mock provider
- AI-native example contract
- AI-native syntax draft
- verification script

This phase does not use external AI APIs.
MD

echo "[phase5.1] Running verification..."
bash scripts/verify_phase5_1_ai_native_core.sh

echo "============================================================"
echo " Phase 5.1 COMPLETE"
echo " Next: Phase 5.2 Intelligent Type System"
echo "============================================================"
