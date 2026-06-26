#!/usr/bin/env bash
set -euo pipefail

# PantherLang Phase 5.3 Professional
# Memory & Context Engine + Strong Practical Test Suite
#
# Run from project root:
#   cd ~/pantherlang/PantherLang_Developer_Edition_v0_5
#   bash bootstrap_phase5_3_memory_context_engine_pro.sh

PHASE="5.3"
PROJECT_ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_ROOT/.phase_backups/phase5_3_pro_$STAMP"

echo "============================================================"
echo " PantherLang Phase 5.3 PRO - Memory & Context Engine"
echo "============================================================"
echo "[phase5.3] Project root: $PROJECT_ROOT"

fail() {
  echo "[phase5.3][ERROR] $1" >&2
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
require_file "language/ai/core/manifest.json"
require_file "language/types/core/type_manifest.json"

echo "[phase5.3] Verifying Phase 5.1 dependency..."
bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency.log

echo "[phase5.3] Verifying Phase 5.2 dependency..."
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency.log

mkdir -p "$BACKUP_DIR"

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$target")"
    cp -a "$target" "$BACKUP_DIR/$target"
  fi
}

echo "[phase5.3] Creating backup at: $BACKUP_DIR"

backup_if_exists "language/memory"
backup_if_exists "language/ai/context"
backup_if_exists "architecture/MEMORY_CONTEXT_ENGINE.md"
backup_if_exists "docs/phase5/PHASE_5_3_STATUS.md"
backup_if_exists "examples/memory"
backup_if_exists "tests/phase5_3"
backup_if_exists "scripts/verify_phase5_3_memory_context_engine.sh"
backup_if_exists "scripts/run_phase5_3_practical_demo.sh"
backup_if_exists "CHANGELOG.md"

echo "[phase5.3] Creating Memory & Context Engine directories..."
mkdir -p \
  language/memory/core \
  language/memory/runtime \
  language/memory/policies \
  language/memory/schemas \
  language/ai/context \
  architecture \
  docs/phase5 \
  examples/memory \
  tests/phase5_3 \
  scripts

cat > "architecture/MEMORY_CONTEXT_ENGINE.md" <<'MD'
# PantherLang Phase 5.3 — Memory & Context Engine

Phase 5.3 introduces a deterministic, auditable Memory & Context Engine for PantherLang.

## Design Goal

PantherLang must provide practical results in every serious run. This phase begins that rule by making memory and context testable, repeatable, and observable.

The engine supports:

- project memory
- session memory
- agent memory
- typed records
- trust levels
- deterministic retrieval
- context assembly
- audit metadata
- safe local-only operation
- practical demos with expected outputs

## Professional Testing Standard

Every phase from 5.3 forward must include:

1. structure verification
2. schema validation
3. runtime unit tests
4. negative/failure tests
5. practical language-facing demo
6. deterministic expected output checks

## Offline Guarantee

Phase 5.3 does not call external APIs. It does not require OpenAI, Gemini, Claude, or any provider key.
MD

cat > "language/memory/core/memory_manifest.json" <<'JSON'
{
  "name": "PantherLang Memory & Context Engine",
  "phase": "5.3",
  "version": "0.5.3-memory-context-pro",
  "status": "experimental-foundation",
  "depends_on": ["5.1", "5.2"],
  "external_api_required": false,
  "features": [
    "typed_memory_records",
    "execution_context",
    "ai_context_window",
    "context_policies",
    "local_memory_runtime",
    "audit_metadata",
    "deterministic_retrieval",
    "practical_demo",
    "negative_tests"
  ],
  "testing_standard": [
    "structure",
    "schema",
    "runtime",
    "negative",
    "practical"
  ]
}
JSON

cat > "language/memory/core/memory_types.panther" <<'PAN'
# PantherLang Memory & Context Types
# Phase 5.3 syntax foundation

type MemoryKey = String
type MemoryScope = "local" | "project" | "agent" | "session"
type MemoryTrust = "low" | "medium" | "high" | "verified"

type MemoryRecord<T> {
  key: MemoryKey
  scope: MemoryScope
  value: T
  trust: MemoryTrust
  created_at: String
  tags: List<String>
}

type ContextWindow<T> {
  id: String
  max_records: Int
  records: List<MemoryRecord<T>>
}

type RetrievalQuery {
  text: String
  scope: MemoryScope
  limit: Int
}
PAN

cat > "language/ai/context/context_types.panther" <<'PAN'
# PantherLang AI Context Types
# Phase 5.3 AI-native context foundation

type AIContext<T> = ContextWindow<T>
type PromptMemory<T> = MemoryRecord<T>
type AgentMemory<T> = MemoryRecord<T>

type ContextPolicy {
  name: String
  allow_long_term: Bool
  allow_cross_agent: Bool
  max_records: Int
  require_audit: Bool
}
PAN

cat > "language/memory/policies/default_context.policy.json" <<'JSON'
{
  "name": "default_context",
  "phase": "5.3",
  "allow_long_term": true,
  "allow_cross_agent": false,
  "allow_network": false,
  "allow_secret_storage": false,
  "max_records": 1000,
  "max_value_chars": 12000,
  "require_audit": true,
  "retrieval": {
    "mode": "deterministic_keyword",
    "default_limit": 5
  }
}
JSON

cat > "language/memory/schemas/memory_record.schema.json" <<'JSON'
{
  "title": "PantherLang Memory Record",
  "phase": "5.3",
  "type": "object",
  "required": ["key", "scope", "value", "trust", "created_at", "tags", "audit"],
  "properties": {
    "key": { "type": "string" },
    "scope": {
      "type": "string",
      "enum": ["local", "project", "agent", "session"]
    },
    "value": {
      "type": ["string", "number", "boolean", "object", "array", "null"]
    },
    "trust": {
      "type": "string",
      "enum": ["low", "medium", "high", "verified"]
    },
    "created_at": { "type": "string" },
    "tags": {
      "type": "array",
      "items": { "type": "string" }
    },
    "audit": { "type": "object" }
  }
}
JSON

cat > "language/memory/runtime/memory_runtime.py" <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


class PantherMemoryError(Exception):
    pass


@dataclass
class MemoryRecord:
    key: str
    scope: str
    value: Any
    trust: str
    created_at: str
    tags: list[str]
    audit: dict[str, Any]


class LocalMemoryStore:
    """Deterministic local memory store for PantherLang Phase 5.3."""

    VALID_SCOPES = {"local", "project", "agent", "session"}
    VALID_TRUST = {"low", "medium", "high", "verified"}

    def __init__(self, path: Path) -> None:
        self.path = path
        self.records: list[MemoryRecord] = []
        self.load()

    def load(self) -> None:
        if not self.path.exists():
            self.records = []
            return
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        self.records = [MemoryRecord(**item) for item in raw.get("records", [])]

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        data = {
            "phase": "5.3",
            "engine": "local_deterministic_memory",
            "records": [asdict(r) for r in self.records],
        }
        self.path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

    def put(self, key: str, scope: str, value: Any, trust: str, tags: list[str]) -> MemoryRecord:
        if scope not in self.VALID_SCOPES:
            raise PantherMemoryError(f"Invalid scope: {scope}")
        if trust not in self.VALID_TRUST:
            raise PantherMemoryError(f"Invalid trust: {trust}")
        if not key.strip():
            raise PantherMemoryError("Memory key cannot be empty")

        record = MemoryRecord(
            key=key,
            scope=scope,
            value=value,
            trust=trust,
            created_at=datetime.now(timezone.utc).isoformat(),
            tags=tags,
            audit={
                "created_by": "panther-memory-runtime",
                "phase": "5.3",
                "external_api_used": False,
                "deterministic": True,
            },
        )

        self.records = [r for r in self.records if not (r.key == key and r.scope == scope)]
        self.records.append(record)
        self.save()
        return record

    def get(self, key: str, scope: str | None = None) -> list[MemoryRecord]:
        return [
            r for r in self.records
            if r.key == key and (scope is None or r.scope == scope)
        ]

    def search(self, query: str, scope: str | None = None, limit: int = 5) -> list[MemoryRecord]:
        q = query.lower().strip()
        hits: list[tuple[int, MemoryRecord]] = []
        for record in self.records:
            if scope is not None and record.scope != scope:
                continue
            haystack = " ".join([
                record.key,
                str(record.value),
                " ".join(record.tags),
                record.trust,
                record.scope,
            ]).lower()
            score = haystack.count(q) if q else 0
            if score > 0:
                hits.append((score, record))
        hits.sort(key=lambda item: (-item[0], item[1].key))
        return [record for _, record in hits[:limit]]

    def context(self, query: str, scope: str | None = None, limit: int = 5) -> dict[str, Any]:
        hits = self.search(query=query, scope=scope, limit=limit)
        assembled = "\n".join(f"- [{r.scope}/{r.trust}] {r.key}: {r.value}" for r in hits)
        return {
            "phase": "5.3",
            "context_mode": "deterministic_keyword",
            "query": query,
            "scope": scope,
            "record_count": len(hits),
            "assembled_context": assembled,
            "records": [asdict(r) for r in hits],
            "external_api_used": False,
        }


def parse_tags(raw: str) -> list[str]:
    return [item.strip() for item in raw.split(",") if item.strip()]


def print_json(data: Any) -> None:
    print(json.dumps(data, ensure_ascii=False))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-memory-runtime")
    parser.add_argument("--store", default=".panther_memory/memory_store.json")

    sub = parser.add_subparsers(dest="cmd", required=True)

    put_p = sub.add_parser("put")
    put_p.add_argument("--key", required=True)
    put_p.add_argument("--scope", default="project")
    put_p.add_argument("--value", required=True)
    put_p.add_argument("--trust", default="medium")
    put_p.add_argument("--tags", default="")

    get_p = sub.add_parser("get")
    get_p.add_argument("--key", required=True)
    get_p.add_argument("--scope")

    search_p = sub.add_parser("search")
    search_p.add_argument("--query", required=True)
    search_p.add_argument("--scope")
    search_p.add_argument("--limit", type=int, default=5)

    ctx_p = sub.add_parser("context")
    ctx_p.add_argument("--query", required=True)
    ctx_p.add_argument("--scope")
    ctx_p.add_argument("--limit", type=int, default=5)

    demo_p = sub.add_parser("demo")
    demo_p.add_argument("--reset", action="store_true")

    args = parser.parse_args(argv)
    store_path = Path(args.store)

    if args.cmd == "demo" and args.reset and store_path.exists():
        store_path.unlink()

    store = LocalMemoryStore(store_path)

    try:
        if args.cmd == "put":
            print_json(asdict(store.put(
                key=args.key,
                scope=args.scope,
                value=args.value,
                trust=args.trust,
                tags=parse_tags(args.tags),
            )))
            return 0

        if args.cmd == "get":
            print_json([asdict(r) for r in store.get(key=args.key, scope=args.scope)])
            return 0

        if args.cmd == "search":
            print_json([asdict(r) for r in store.search(query=args.query, scope=args.scope, limit=args.limit)])
            return 0

        if args.cmd == "context":
            print_json(store.context(query=args.query, scope=args.scope, limit=args.limit))
            return 0

        if args.cmd == "demo":
            store.put("project.goal", "project", "Build PantherLang into an AI-native programming language.", "verified", ["pantherlang", "goal", "ai"])
            store.put("phase.5.3", "project", "Memory and Context Engine provides deterministic context retrieval.", "verified", ["phase5", "memory", "context"])
            store.put("runtime.rule", "project", "Every professional phase must include practical tests and negative tests.", "high", ["testing", "quality", "policy"])
            result = store.context(query="context", scope="project", limit=5)
            print_json({
                "demo": "phase5.3-memory-context",
                "ok": result["record_count"] >= 1,
                "practical_result": result["assembled_context"],
                "record_count": result["record_count"],
                "external_api_used": False
            })
            return 0

    except PantherMemoryError as exc:
        print_json({
            "ok": False,
            "error": str(exc),
            "phase": "5.3"
        })
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x "language/memory/runtime/memory_runtime.py"

cat > "examples/memory/phase5_3_context.panther" <<'PAN'
# PantherLang Phase 5.3 Memory & Context practical language-facing example

memory project remember "project.goal" =
  "Build PantherLang into an AI-native programming language."
  trust verified
  tags ["pantherlang", "goal", "ai"]

memory project remember "phase.5.3" =
  "Memory and Context Engine provides deterministic context retrieval."
  trust verified
  tags ["phase5", "memory", "context"]

let ctx: AIContext<String> = context.search {
  query: "context"
  scope: "project"
  limit: 5
}

print ctx
PAN

cat > "examples/memory/phase5_3_practical_expected.txt" <<'TXT'
demo=phase5.3-memory-context
ok=true
record_count>=1
external_api_used=false
contains=Memory and Context Engine
TXT

cat > "scripts/run_phase5_3_practical_demo.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

STORE="/tmp/panther_phase5_3_practical_demo_store_$$.json"
rm -f "$STORE"

OUT="$(python3 language/memory/runtime/memory_runtime.py --store "$STORE" demo --reset)"

python3 - "$OUT" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
assert data["demo"] == "phase5.3-memory-context"
assert data["ok"] is True
assert data["record_count"] >= 1
assert data["external_api_used"] is False
assert "Memory and Context Engine" in data["practical_result"]

print("demo=phase5.3-memory-context")
print("ok=true")
print(f"record_count={data['record_count']}")
print("external_api_used=false")
print("contains=Memory and Context Engine")
PY

rm -f "$STORE"
SH
chmod +x "scripts/run_phase5_3_practical_demo.sh"

cat > "tests/phase5_3/test_memory_runtime.py" <<'PY'
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "memory" / "runtime" / "memory_runtime.py"


def run_cmd(*args: str) -> tuple[int, dict | list]:
    proc = subprocess.run(
        [sys.executable, str(RUNTIME), *args],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    payload = json.loads(proc.stdout)
    return proc.returncode, payload


def test_memory_put_get_search_context(tmp_path: Path) -> None:
    store = tmp_path / "store.json"

    code, put = run_cmd("--store", str(store), "put", "--key", "alpha", "--scope", "project", "--value", "Panther context memory", "--trust", "verified", "--tags", "memory,context")
    assert code == 0
    assert put["key"] == "alpha"
    assert put["trust"] == "verified"

    code, got = run_cmd("--store", str(store), "get", "--key", "alpha", "--scope", "project")
    assert code == 0
    assert got[0]["value"] == "Panther context memory"

    code, hits = run_cmd("--store", str(store), "search", "--query", "context", "--scope", "project")
    assert code == 0
    assert hits[0]["key"] == "alpha"

    code, ctx = run_cmd("--store", str(store), "context", "--query", "context", "--scope", "project")
    assert code == 0
    assert ctx["phase"] == "5.3"
    assert ctx["external_api_used"] is False
    assert "Panther context memory" in ctx["assembled_context"]


def test_invalid_scope_fails(tmp_path: Path) -> None:
    store = tmp_path / "store.json"
    proc = subprocess.run(
        [
            sys.executable,
            str(RUNTIME),
            "--store",
            str(store),
            "put",
            "--key",
            "bad",
            "--scope",
            "illegal",
            "--value",
            "x",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 2
    payload = json.loads(proc.stdout)
    assert payload["ok"] is False
    assert "Invalid scope" in payload["error"]
PY

cat > "docs/phase5/PHASE_5_3_STATUS.md" <<'MD'
# Phase 5.3 Status — Memory & Context Engine PRO

## Completed

- Memory architecture document.
- Memory manifest.
- Memory and AI context type definitions.
- Default memory/context policy.
- Memory record schema.
- Deterministic local memory runtime.
- Practical language-facing `.panther` example.
- Practical demo runner.
- Python runtime unit tests.
- Negative/failure test for invalid scope.
- Professional verification script.

## Verification

Run from project root:

```bash
bash scripts/verify_phase5_3_memory_context_engine.sh
```

Expected final lines:

```text
✅ structure tests passed
✅ schema tests passed
✅ runtime tests passed
✅ practical PantherLang memory demo passed
✅ negative/failure tests passed
✅ PantherLang Phase 5.3 Memory & Context Engine verification complete.
```

## Next Phase

Phase 5.4 — Multi-Agent Runtime.
MD

cat > "scripts/verify_phase5_3_memory_context_engine.sh" <<'SH'
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
SH
chmod +x "scripts/verify_phase5_3_memory_context_engine.sh"

cat >> "CHANGELOG.md" <<'MD'

## Phase 5.3 — Memory & Context Engine PRO

Added a deterministic, auditable Memory & Context Engine with a stronger professional test standard:

- memory manifest
- memory/context types
- AI context types
- default context policy
- memory record schema
- local deterministic memory runtime
- practical language-facing memory example
- practical demo runner
- unit test file
- negative/failure test
- professional verification gates

Phase 5.3 depends on Phase 5.1 and Phase 5.2.
MD

echo "[phase5.3] Running professional verification..."
bash scripts/verify_phase5_3_memory_context_engine.sh

echo "============================================================"
echo " Phase 5.3 COMPLETE"
echo " Next: Phase 5.4 Multi-Agent Runtime"
echo "============================================================"
