#!/usr/bin/env bash
set -euo pipefail

# PantherLang Phase 5.2
# Intelligent Type System Bootstrap
#
# Run from project root:
#   cd ~/pantherlang/PantherLang_Developer_Edition_v0_5
#   bash bootstrap_phase5_2_intelligent_type_system.sh

PHASE="5.2"
PROJECT_ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_ROOT/.phase_backups/phase5_2_$STAMP"

echo "============================================================"
echo " PantherLang Phase 5.2 - Intelligent Type System Bootstrap"
echo "============================================================"
echo "[phase5.2] Project root: $PROJECT_ROOT"

fail() {
  echo "[phase5.2][ERROR] $1" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "Required file missing: $1"
}

require_dir() {
  [ -d "$1" ] || fail "Required directory missing: $1"
}

# Must run from the real PantherLang Developer Edition root.
require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_dir "language"
require_dir "scripts"
require_dir "architecture"

# Phase 5.1 must exist and pass before Phase 5.2.
require_file "scripts/verify_phase5_1_ai_native_core.sh"
require_file "language/ai/core/manifest.json"
require_file "language/ai/runtime/ai_runtime.py"

echo "[phase5.2] Verifying Phase 5.1 dependency..."
bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency.log

mkdir -p "$BACKUP_DIR"

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$target")"
    cp -a "$target" "$BACKUP_DIR/$target"
  fi
}

echo "[phase5.2] Creating backup at: $BACKUP_DIR"

backup_if_exists "language/types"
backup_if_exists "language/ai/types"
backup_if_exists "architecture/INTELLIGENT_TYPE_SYSTEM.md"
backup_if_exists "docs/phase5/PHASE_5_2_STATUS.md"
backup_if_exists "examples/types"
backup_if_exists "scripts/verify_phase5_2_intelligent_type_system.sh"
backup_if_exists "CHANGELOG.md"

echo "[phase5.2] Creating Intelligent Type System directories..."
mkdir -p \
  language/types/core \
  language/types/inference \
  language/types/contracts \
  language/types/static_analysis \
  language/ai/types \
  architecture \
  docs/phase5 \
  examples/types \
  scripts

cat > "architecture/INTELLIGENT_TYPE_SYSTEM.md" <<'MD'
# PantherLang Phase 5.2 — Intelligent Type System

Phase 5.2 introduces the first formal Intelligent Type System layer for PantherLang.

## Goal

The type system must support both traditional software engineering and AI-native programming.

PantherLang types are designed to support:

- static type checking
- type inference
- nullable safety
- union types
- generic types
- Result<T,E>
- Option<T>
- AI-specific types
- prompt contracts
- agent contracts
- semantic validation
- future compiler optimization

## Current Phase Scope

This phase creates a deterministic type-system foundation. It does not replace the full compiler yet.

Implemented in Phase 5.2:

- type system manifest
- core type definitions
- AI type definitions
- type inference rules
- contract rules
- static analyzer prototype
- example Panther type declarations
- verification script

## Relationship to Phase 5.1

Phase 5.1 introduced AI Native Core. Phase 5.2 adds a type layer that can reason about AI inputs, outputs, contracts, and future agent messages.
MD

cat > "language/types/core/type_manifest.json" <<'JSON'
{
  "name": "PantherLang Intelligent Type System",
  "phase": "5.2",
  "version": "0.5.2-intelligent-types",
  "status": "experimental-foundation",
  "depends_on": ["5.1"],
  "features": [
    "primitive_types",
    "nullable_types",
    "union_types",
    "generic_types",
    "option_type",
    "result_type",
    "contract_types",
    "ai_types",
    "static_analysis",
    "inference_rules"
  ]
}
JSON

cat > "language/types/core/core_types.panther" <<'PAN'
# PantherLang Core Type Definitions
# Phase 5.2 syntax foundation

type Int
type Float
type Bool
type String
type Bytes
type Null
type Never
type Any

type Option<T> = Some<T> | None
type Result<T, E> = Ok<T> | Err<E>

type List<T>
type Map<K, V>
type Set<T>

type Nullable<T> = T | Null
PAN

cat > "language/ai/types/ai_types.panther" <<'PAN'
# PantherLang AI Type Definitions
# Phase 5.2 AI-native typing foundation

type Prompt
type PromptContract<TInput, TOutput>
type AIResponse<T>
type AIError
type AgentMessage<T>
type AgentState<T>
type Embedding<VectorDim>
type ToolCall<TInput, TOutput>

type SafeAIResult<T> = Result<AIResponse<T>, AIError>
PAN

cat > "language/types/inference/inference_rules.json" <<'JSON'
{
  "phase": "5.2",
  "rules": [
    {
      "id": "literal-int",
      "pattern": "integer literal",
      "infers": "Int"
    },
    {
      "id": "literal-float",
      "pattern": "floating literal",
      "infers": "Float"
    },
    {
      "id": "literal-string",
      "pattern": "quoted string literal",
      "infers": "String"
    },
    {
      "id": "literal-bool",
      "pattern": "true | false",
      "infers": "Bool"
    },
    {
      "id": "nullable-union",
      "pattern": "T | Null",
      "infers": "Nullable<T>"
    },
    {
      "id": "result-success",
      "pattern": "Ok<T>",
      "infers": "Result<T,E>"
    },
    {
      "id": "ai-generate",
      "pattern": "ai.generate PromptContract<TInput,TOutput>",
      "infers": "SafeAIResult<TOutput>"
    }
  ]
}
JSON

cat > "language/types/contracts/type_contracts.json" <<'JSON'
{
  "phase": "5.2",
  "contracts": [
    {
      "name": "NonEmptyString",
      "base": "String",
      "rule": "len(value) > 0"
    },
    {
      "name": "SafePrompt",
      "base": "Prompt",
      "rule": "policy != null && input.length <= policy.max_prompt_chars"
    },
    {
      "name": "BoundedAIOutput",
      "base": "AIResponse<T>",
      "rule": "output.length <= policy.max_output_chars"
    }
  ]
}
JSON

cat > "language/types/static_analysis/type_analyzer.py" <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass
class Diagnostic:
    level: str
    code: str
    message: str
    line: int

    def to_dict(self) -> dict[str, Any]:
        return {
            "level": self.level,
            "code": self.code,
            "message": self.message,
            "line": self.line,
        }


class PantherTypeAnalyzer:
    """Deterministic Phase 5.2 static type analyzer prototype."""

    def __init__(self) -> None:
        self.symbols: dict[str, str] = {}
        self.diagnostics: list[Diagnostic] = []

    def infer_literal(self, expr: str) -> str:
        expr = expr.strip()
        if re.fullmatch(r"-?\d+", expr):
            return "Int"
        if re.fullmatch(r"-?\d+\.\d+", expr):
            return "Float"
        if re.fullmatch(r'"(?:\\.|[^"\\])*"', expr):
            return "String"
        if expr in {"true", "false"}:
            return "Bool"
        if expr == "null":
            return "Null"
        if expr.startswith("Ok("):
            return "Result<Inferred, InferredError>"
        if expr.startswith("Err("):
            return "Result<InferredOk, Inferred>"
        if expr.startswith("Some("):
            return "Option<Inferred>"
        if expr == "None":
            return "Option<Never>"
        return self.symbols.get(expr, "Unknown")

    def compatible(self, declared: str, inferred: str) -> bool:
        if declared in {"Any", inferred}:
            return True
        if declared.startswith("Nullable<") and inferred == "Null":
            return True
        if "|" in declared:
            return inferred in [part.strip() for part in declared.split("|")]
        if declared.startswith("Option<") and inferred.startswith("Option<"):
            return True
        if declared.startswith("Result<") and inferred.startswith("Result<"):
            return True
        return False

    def analyze_line(self, line: str, number: int) -> None:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            return

        typed_let = re.match(r"let\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^=]+?)\s*=\s*(.+)$", stripped)
        if typed_let:
            name, declared, expr = typed_let.groups()
            declared = declared.strip()
            inferred = self.infer_literal(expr)
            self.symbols[name] = declared
            if not self.compatible(declared, inferred):
                self.diagnostics.append(
                    Diagnostic(
                        "error",
                        "PANTHER-TYPE-001",
                        f"{name} declared as {declared} but expression inferred as {inferred}",
                        number,
                    )
                )
            return

        untyped_let = re.match(r"let\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$", stripped)
        if untyped_let:
            name, expr = untyped_let.groups()
            self.symbols[name] = self.infer_literal(expr)
            return

        if "ai.generate" in stripped and "PromptContract" not in stripped:
            self.diagnostics.append(
                Diagnostic(
                    "warning",
                    "PANTHER-AI-TYPE-001",
                    "ai.generate should be backed by PromptContract<TInput,TOutput>",
                    number,
                )
            )

    def analyze(self, source: str) -> dict[str, Any]:
        for idx, line in enumerate(source.splitlines(), start=1):
            self.analyze_line(line, idx)

        return {
            "phase": "5.2",
            "symbols": self.symbols,
            "diagnostics": [d.to_dict() for d in self.diagnostics],
            "ok": not any(d.level == "error" for d in self.diagnostics),
        }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-type-analyzer")
    parser.add_argument("source", help="Path to Panther source file")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args(argv)

    path = Path(args.source)
    if not path.exists():
        raise SystemExit(f"Source file not found: {path}")

    result = PantherTypeAnalyzer().analyze(path.read_text(encoding="utf-8"))
    print(json.dumps(result, indent=2 if args.pretty else None, ensure_ascii=False))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x "language/types/static_analysis/type_analyzer.py"

cat > "examples/types/phase5_2_types.panther" <<'PAN'
# PantherLang Phase 5.2 type system sample

let name: String = "Feras"
let age: Int = 44
let active: Bool = true
let score = 99.5

let maybe_name: Nullable<String> = null
let result: Result<String, AIError> = Ok("typed AI output")
let optional_value: Option<Int> = Some(7)

# AI typed syntax draft
let contract: PromptContract<String, String> = "hello-ai-contract"
PAN

cat > "examples/types/phase5_2_type_error.panther" <<'PAN'
# Expected to produce one type error

let age: Int = "not an int"
PAN

cat > "docs/phase5/PHASE_5_2_STATUS.md" <<'MD'
# Phase 5.2 Status — Intelligent Type System

## Completed

- Created Intelligent Type System architecture document.
- Created type manifest.
- Created core type definitions.
- Created AI type definitions.
- Created type inference rules.
- Created type contract definitions.
- Created deterministic static analyzer prototype.
- Created valid typed Panther example.
- Created intentional type-error example.
- Created verification script.

## Verification

Run from project root:

```bash
bash scripts/verify_phase5_2_intelligent_type_system.sh
```

Expected final line:

```text
PantherLang Phase 5.2 Intelligent Type System verification complete.
```

## Next Phase

Phase 5.3 — Memory & Context Engine.
MD

cat > "scripts/verify_phase5_2_intelligent_type_system.sh" <<'SH'
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
SH
chmod +x "scripts/verify_phase5_2_intelligent_type_system.sh"

cat >> "CHANGELOG.md" <<'MD'

## Phase 5.2 — Intelligent Type System

Added the first intelligent type-system foundation layer:

- core type definitions
- AI type definitions
- type inference rules
- type contracts
- static analyzer prototype
- typed Panther examples
- intentional type-error fixture
- verification script

Phase 5.2 depends on Phase 5.1 AI Native Core.
MD

echo "[phase5.2] Running verification..."
bash scripts/verify_phase5_2_intelligent_type_system.sh

echo "============================================================"
echo " Phase 5.2 COMPLETE"
echo " Next: Phase 5.3 Memory & Context Engine"
echo "============================================================"
