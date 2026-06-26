#!/usr/bin/env bash
set -euo pipefail

# PantherLang Phase 5.5 Professional
# Natural Language Programming + Intent Compiler + Strong Practical Test Suite
#
# Run from project root:
#   cd ~/pantherlang/PantherLang_Developer_Edition_v0_5
#   bash bootstrap_phase5_5_natural_language_programming_pro.sh

PHASE="5.5"
PROJECT_ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_ROOT/.phase_backups/phase5_5_pro_$STAMP"

echo "============================================================"
echo " PantherLang Phase 5.5 PRO - Natural Language Programming"
echo "============================================================"
echo "[phase5.5] Project root: $PROJECT_ROOT"

fail() {
  echo "[phase5.5][ERROR] $1" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "Required file missing: $1"
}

require_dir() {
  [ -d "$1" ] || fail "Required directory missing: $1"
}

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_dir "language"
require_dir "scripts"
require_dir "architecture"

require_file "scripts/verify_phase5_1_ai_native_core.sh"
require_file "scripts/verify_phase5_2_intelligent_type_system.sh"
require_file "scripts/verify_phase5_3_memory_context_engine.sh"
require_file "scripts/verify_phase5_4_multi_agent_runtime.sh"
require_file "language/ai/core/manifest.json"
require_file "language/types/core/type_manifest.json"
require_file "language/memory/core/memory_manifest.json"
require_file "language/agents/core/agent_manifest.json"

echo "[phase5.5] Verifying Phase 5.1 dependency..."
bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency.log

echo "[phase5.5] Verifying Phase 5.2 dependency..."
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency.log

echo "[phase5.5] Verifying Phase 5.3 dependency..."
bash scripts/verify_phase5_3_memory_context_engine.sh >/tmp/panther_phase5_3_dependency.log

echo "[phase5.5] Verifying Phase 5.4 dependency..."
bash scripts/verify_phase5_4_multi_agent_runtime.sh >/tmp/panther_phase5_4_dependency.log

mkdir -p "$BACKUP_DIR"

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$target")"
    cp -a "$target" "$BACKUP_DIR/$target"
  fi
}

echo "[phase5.5] Creating backup at: $BACKUP_DIR"

backup_if_exists "language/nlp"
backup_if_exists "language/ai/nlp"
backup_if_exists "architecture/NATURAL_LANGUAGE_PROGRAMMING.md"
backup_if_exists "docs/phase5/PHASE_5_5_STATUS.md"
backup_if_exists "examples/nlp"
backup_if_exists "tests/phase5_5"
backup_if_exists "scripts/verify_phase5_5_natural_language_programming.sh"
backup_if_exists "scripts/run_phase5_5_practical_demo.sh"
backup_if_exists "CHANGELOG.md"

echo "[phase5.5] Creating Natural Language Programming directories..."
mkdir -p \
  language/nlp/core \
  language/nlp/runtime \
  language/nlp/policies \
  language/nlp/schemas \
  language/ai/nlp \
  architecture \
  docs/phase5 \
  examples/nlp \
  tests/phase5_5 \
  scripts

cat > "architecture/NATURAL_LANGUAGE_PROGRAMMING.md" <<'MD'
# PantherLang Phase 5.5 — Natural Language Programming

Phase 5.5 introduces deterministic Natural Language Programming foundations.

## Mission

PantherLang should let developers express safe, bounded natural-language intent and convert that intent into auditable PantherLang code templates.

This phase is not a free-form AI code generator. It is a deterministic, policy-controlled intent compiler.

## Core Concepts

- Natural-language intent
- Intent classification
- Deterministic template generation
- Intent-to-Panther source translation
- Policy guardrails
- Ambiguity detection
- Practical executable examples
- Negative tests for unsafe or ambiguous intent

## Professional Testing Standard

Phase 5.5 includes:

1. structure verification
2. schema validation
3. runtime intent compiler tests
4. deterministic code generation tests
5. ambiguity/negative tests
6. practical Natural Language → PantherLang demo
7. pytest suite or compile fallback
8. final verification report

## Offline Guarantee

Phase 5.5 does not call external AI APIs. No OpenAI/Gemini/Claude key is needed.
MD

cat > "language/nlp/core/nlp_manifest.json" <<'JSON'
{
  "name": "PantherLang Natural Language Programming",
  "phase": "5.5",
  "version": "0.5.5-natural-language-programming-pro",
  "status": "experimental-foundation",
  "depends_on": ["5.1", "5.2", "5.3", "5.4"],
  "external_api_required": false,
  "features": [
    "intent_classification",
    "deterministic_intent_compiler",
    "template_generation",
    "ambiguity_detection",
    "policy_guardrails",
    "practical_demo",
    "negative_tests"
  ],
  "testing_standard": [
    "structure",
    "schema",
    "runtime",
    "code_generation",
    "negative",
    "practical"
  ]
}
JSON

cat > "language/nlp/core/nlp_types.panther" <<'PAN'
# PantherLang Natural Language Programming Types
# Phase 5.5 syntax foundation

type IntentText = String
type IntentKind = "print" | "variable" | "function" | "workflow" | "unknown"
type IntentConfidence = Float

type NaturalIntent {
  id: String
  text: IntentText
  kind: IntentKind
  confidence: IntentConfidence
  safe: Bool
}

type IntentCompilationResult {
  ok: Bool
  intent_kind: IntentKind
  generated_source: String
  diagnostics: List<String>
}
PAN

cat > "language/ai/nlp/nlp_agent_types.panther" <<'PAN'
# PantherLang NLP Agent Types
# Phase 5.5 AI-native NLP foundation

type IntentPlannerAgent = Agent
type IntentCompilerAgent = Agent
type IntentReviewerAgent = Agent

type NLWorkflowResult {
  ok: Bool
  source: String
  review: String
  deterministic: Bool
}
PAN

cat > "language/nlp/policies/default_nlp.policy.json" <<'JSON'
{
  "name": "default_nlp",
  "phase": "5.5",
  "allow_network": false,
  "allow_secret_access": false,
  "allow_shell_execution": false,
  "max_intent_chars": 2000,
  "require_deterministic_templates": true,
  "reject_ambiguous_intent": true,
  "reject_unsafe_intent": true,
  "audit_required": true,
  "allowed_intents": [
    "print",
    "variable",
    "function",
    "workflow"
  ],
  "blocked_terms": [
    "delete system",
    "steal",
    "exfiltrate",
    "malware",
    "reverse shell"
  ]
}
JSON

cat > "language/nlp/schemas/natural_intent.schema.json" <<'JSON'
{
  "title": "PantherLang Natural Intent",
  "phase": "5.5",
  "type": "object",
  "required": ["id", "text", "policy"],
  "properties": {
    "id": { "type": "string" },
    "text": { "type": "string" },
    "policy": { "type": "string" },
    "expected_kind": { "type": "string" }
  }
}
JSON

cat > "language/nlp/runtime/intent_compiler.py" <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any


class PantherIntentError(Exception):
    pass


@dataclass
class CompiledIntent:
    ok: bool
    phase: str
    intent_kind: str
    confidence: float
    generated_source: str
    diagnostics: list[str]
    external_api_used: bool
    deterministic: bool


class DeterministicIntentCompiler:
    BLOCKED_TERMS = ["delete system", "steal", "exfiltrate", "malware", "reverse shell"]

    def normalize(self, text: str) -> str:
        return re.sub(r"\s+", " ", text.strip().lower())

    def check_safe(self, text: str) -> None:
        low = self.normalize(text)
        for term in self.BLOCKED_TERMS:
            if term in low:
                raise PantherIntentError(f"Unsafe intent blocked: {term}")

    def classify(self, text: str) -> tuple[str, float]:
        low = self.normalize(text)
        if not low:
            raise PantherIntentError("Intent text cannot be empty")

        if any(x in low for x in ["print", "say", "show", "display"]):
            return "print", 0.92
        if any(x in low for x in ["variable", "store", "remember value", "set value"]):
            return "variable", 0.87
        if any(x in low for x in ["function", "create function", "make function"]):
            return "function", 0.89
        if any(x in low for x in ["workflow", "agent", "planner", "coder", "reviewer"]):
            return "workflow", 0.9

        raise PantherIntentError("Ambiguous intent: no deterministic template matched")

    def compile_print(self, text: str) -> str:
        quoted = "Hello from PantherLang"
        match = re.search(r'["“](.+?)["”]', text)
        if match:
            quoted = match.group(1)
        elif "hello" in self.normalize(text):
            quoted = "Hello from PantherLang"
        return f'print "{quoted}"\n'

    def compile_variable(self, text: str) -> str:
        low = self.normalize(text)
        if "name" in low:
            return 'let name = "PantherLang"\nprint name\n'
        if "version" in low:
            return 'let version = "0.5.5"\nprint version\n'
        return 'let value = "generated by natural intent"\nprint value\n'

    def compile_function(self, text: str) -> str:
        low = self.normalize(text)
        if "add" in low or "sum" in low:
            return 'fn add(a, b) {\n  return a + b\n}\n\nprint add(2, 3)\n'
        return 'fn generated() {\n  return "generated by PantherLang intent compiler"\n}\n\nprint generated()\n'

    def compile_workflow(self, text: str) -> str:
        return (
            'agent planner role planner permissions ["plan", "message"]\n'
            'agent coder role coder permissions ["code", "message"]\n'
            'agent reviewer role reviewer permissions ["review", "message"]\n\n'
            'workflow generated_feature {\n'
            '  planner -> coder: "Create feature from natural language intent."\n'
            '  coder -> reviewer: "Generated deterministic PantherLang source."\n'
            '  reviewer -> planner: "APPROVED: intent workflow completed."\n'
            '}\n'
        )

    def compile(self, text: str) -> CompiledIntent:
        self.check_safe(text)
        kind, confidence = self.classify(text)

        if kind == "print":
            src = self.compile_print(text)
        elif kind == "variable":
            src = self.compile_variable(text)
        elif kind == "function":
            src = self.compile_function(text)
        elif kind == "workflow":
            src = self.compile_workflow(text)
        else:
            raise PantherIntentError("Unsupported intent kind")

        return CompiledIntent(
            ok=True,
            phase="5.5",
            intent_kind=kind,
            confidence=confidence,
            generated_source=src,
            diagnostics=[],
            external_api_used=False,
            deterministic=True,
        )


def print_json(data: Any) -> None:
    print(json.dumps(data, ensure_ascii=False))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-intent-compiler")
    sub = parser.add_subparsers(dest="cmd", required=True)

    compile_p = sub.add_parser("compile")
    compile_p.add_argument("--text", required=True)
    compile_p.add_argument("--out")

    demo_p = sub.add_parser("demo")
    demo_p.add_argument("--out")

    neg_p = sub.add_parser("negative")
    neg_p.add_argument("--case", choices=["ambiguous", "unsafe", "empty"], required=True)

    args = parser.parse_args(argv)
    compiler = DeterministicIntentCompiler()

    try:
        if args.cmd == "compile":
            result = compiler.compile(args.text)
            if args.out:
                Path(args.out).write_text(result.generated_source, encoding="utf-8")
            print_json(asdict(result))
            return 0

        if args.cmd == "demo":
            text = 'Create a function that adds two numbers and print the result.'
            result = compiler.compile(text)
            if args.out:
                Path(args.out).write_text(result.generated_source, encoding="utf-8")
            print_json({
                "phase": "5.5",
                "demo": "natural-language-to-pantherlang",
                "ok": result.ok,
                "intent_kind": result.intent_kind,
                "generated_source": result.generated_source,
                "external_api_used": False,
                "deterministic": True,
            })
            return 0

        if args.cmd == "negative":
            if args.case == "ambiguous":
                compiler.compile("make it better")
            elif args.case == "unsafe":
                compiler.compile("create malware to steal secrets")
            elif args.case == "empty":
                compiler.compile("")

    except PantherIntentError as exc:
        print_json({
            "ok": False,
            "phase": "5.5",
            "error": str(exc),
            "external_api_used": False,
            "deterministic": True,
        })
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x "language/nlp/runtime/intent_compiler.py"

cat > "examples/nlp/phase5_5_intent.json" <<'JSON'
{
  "id": "phase5-5-demo-intent",
  "text": "Create a function that adds two numbers and print the result.",
  "policy": "default_nlp",
  "expected_kind": "function"
}
JSON

cat > "examples/nlp/phase5_5_natural_language.panther" <<'PAN'
# PantherLang Phase 5.5 Natural Language Programming syntax draft

intent "Create a function that adds two numbers and print the result."

compile intent to panther source

run generated source
PAN

cat > "examples/nlp/phase5_5_practical_expected.txt" <<'TXT'
demo=natural-language-to-pantherlang
ok=true
intent_kind=function
external_api_used=false
deterministic=true
contains=fn add
contains=print add(2, 3)
TXT

cat > "scripts/run_phase5_5_practical_demo.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_FILE="/tmp/panther_phase5_5_generated_$$.panther"
OUT="$(python3 language/nlp/runtime/intent_compiler.py demo --out "$OUT_FILE")"

python3 - "$OUT" "$OUT_FILE" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(sys.argv[1])
source = Path(sys.argv[2]).read_text()

assert data["phase"] == "5.5"
assert data["demo"] == "natural-language-to-pantherlang"
assert data["ok"] is True
assert data["intent_kind"] == "function"
assert data["external_api_used"] is False
assert data["deterministic"] is True
assert "fn add" in source
assert "print add(2, 3)" in source

print("demo=natural-language-to-pantherlang")
print("ok=true")
print("intent_kind=function")
print("external_api_used=false")
print("deterministic=true")
print("contains=fn add")
print("contains=print add(2, 3)")
PY

rm -f "$OUT_FILE"
SH
chmod +x "scripts/run_phase5_5_practical_demo.sh"

cat > "tests/phase5_5/test_intent_compiler.py" <<'PY'
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "nlp" / "runtime" / "intent_compiler.py"


def run_cmd(*args: str):
    proc = subprocess.run(
        [sys.executable, str(RUNTIME), *args],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    return proc.returncode, json.loads(proc.stdout)


def test_compile_function_intent() -> None:
    code, data = run_cmd("compile", "--text", "Create a function that adds two numbers and print the result.")
    assert code == 0
    assert data["ok"] is True
    assert data["intent_kind"] == "function"
    assert data["external_api_used"] is False
    assert data["deterministic"] is True
    assert "fn add" in data["generated_source"]


def test_compile_print_intent() -> None:
    code, data = run_cmd("compile", "--text", 'Print "PantherLang is alive"')
    assert code == 0
    assert data["intent_kind"] == "print"
    assert 'print "PantherLang is alive"' in data["generated_source"]


def test_ambiguous_intent_fails() -> None:
    code, data = run_cmd("negative", "--case", "ambiguous")
    assert code == 2
    assert data["ok"] is False
    assert "Ambiguous intent" in data["error"]


def test_unsafe_intent_fails() -> None:
    code, data = run_cmd("negative", "--case", "unsafe")
    assert code == 2
    assert data["ok"] is False
    assert "Unsafe intent blocked" in data["error"]
PY

cat > "docs/phase5/PHASE_5_5_STATUS.md" <<'MD'
# Phase 5.5 Status — Natural Language Programming PRO

## Completed

- Natural Language Programming architecture document.
- NLP manifest.
- Natural intent type definitions.
- NLP agent type definitions.
- Default NLP safety policy.
- Natural intent schema.
- Deterministic intent compiler.
- Natural Language → PantherLang practical demo.
- Ambiguity negative test.
- Unsafe intent negative test.
- Pytest suite.
- Professional verification script.

## Verification

Run from project root:

```bash
bash scripts/verify_phase5_5_natural_language_programming.sh
```

Expected final lines:

```text
✅ structure tests passed
✅ schema tests passed
✅ runtime intent compiler tests passed
✅ code generation tests passed
✅ negative/failure tests passed
✅ practical Natural Language to PantherLang demo passed
✅ PantherLang Phase 5.5 Natural Language Programming verification complete.
```

## Next Phase

Phase 5.6 — AI Optimizing Compiler.
MD

cat > "scripts/verify_phase5_5_natural_language_programming.sh" <<'SH'
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
SH
chmod +x "scripts/verify_phase5_5_natural_language_programming.sh"

cat >> "CHANGELOG.md" <<'MD'

## Phase 5.5 — Natural Language Programming PRO

Added the first deterministic Natural Language Programming foundation:

- NLP manifest
- natural intent type definitions
- NLP agent type definitions
- default NLP safety policy
- natural intent schema
- deterministic intent compiler
- Natural Language → PantherLang practical demo
- ambiguity and unsafe-intent negative tests
- pytest suite
- professional verification gates

Phase 5.5 depends on Phase 5.1, Phase 5.2, Phase 5.3, and Phase 5.4.
MD

echo "[phase5.5] Running professional verification..."
bash scripts/verify_phase5_5_natural_language_programming.sh

echo "============================================================"
echo " Phase 5.5 COMPLETE"
echo " Next: Phase 5.6 AI Optimizing Compiler"
echo "============================================================"
