#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 2 - Compiler Runtime"
echo " Part 1 - Compiler Runtime Contract"
echo "============================================================"

ROOT="$(pwd)"
R3="$ROOT/.panther/R3_production_developer_experience"
R32="$ROOT/.panther/R3_compiler_runtime"
REPORTS="$ROOT/reports/R3_compiler_runtime"
BACKUP="$ROOT/.panther/backups/R3_batch2_part1_compiler_runtime_contract_$(date +%Y%m%d_%H%M%S)"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R32" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B2-P1][ERROR] $1" >&2; exit 1; }

echo "[1/10] Pre-flight gates..."
[ -d ".git" ] || fail "Run from PantherLang project root."
[ -f "$R3/status_batch1_final_developer_experience_release.json" ] || fail "R3 Batch 1 Final status missing."
[ -d "project_templates" ] || fail "project_templates missing."
[ -d "tools/project_runner" ] || fail "tools/project_runner missing."

echo "[2/10] Safety backup..."
[ -d compiler ] && cp -a compiler "$BACKUP/compiler" || true
[ -d runtime ] && cp -a runtime "$BACKUP/runtime" || true
[ -d language ] && cp -a language "$BACKUP/language" || true
[ -d tests/R3_compiler_runtime ] && cp -a tests/R3_compiler_runtime "$BACKUP/tests_R3_compiler_runtime" || true

echo "[3/10] Baseline regression..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q
python3 -m pytest tests/R3_project_system -q

echo "[4/10] Creating compiler-runtime contract..."
mkdir -p compiler/runtime_contract runtime/panther_vm tests/R3_compiler_runtime docs/compiler_runtime

cat > compiler/runtime_contract/__init__.py <<'PY'
from .contract import (
    COMPILER_RUNTIME_VERSION,
    SUPPORTED_ENTRYPOINTS,
    CompilerRuntimeContract,
    get_contract,
)

__all__ = [
    "COMPILER_RUNTIME_VERSION",
    "SUPPORTED_ENTRYPOINTS",
    "CompilerRuntimeContract",
    "get_contract",
]
PY

cat > compiler/runtime_contract/contract.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Literal


COMPILER_RUNTIME_VERSION = "0.1.0-r3-b2"
SUPPORTED_ENTRYPOINTS = ("main", "web", "api", "ai", "test")


@dataclass(frozen=True)
class CompilerRuntimeContract:
    version: str
    source_extensions: tuple[str, ...]
    manifest_file: str
    entrypoints: tuple[str, ...]
    stages: tuple[str, ...]
    build_artifact_format: str


def get_contract() -> CompilerRuntimeContract:
    return CompilerRuntimeContract(
        version=COMPILER_RUNTIME_VERSION,
        source_extensions=(".panther", ".pan"),
        manifest_file="panther.toml",
        entrypoints=SUPPORTED_ENTRYPOINTS,
        stages=(
            "lex",
            "parse",
            "ast",
            "semantic_check",
            "ir",
            "runtime_execute",
            "artifact_emit",
        ),
        build_artifact_format="panther-build-json-v1",
    )


def contract_as_dict() -> dict:
    return asdict(get_contract())
PY

cat > "$R32/compiler_runtime_contract.json" <<'EOF'
{
  "ok": true,
  "phase": "R3",
  "batch": "2",
  "part": "1",
  "name": "Compiler Runtime Contract",
  "version": "0.1.0-r3-b2",
  "source_extensions": [".panther", ".pan"],
  "manifest_file": "panther.toml",
  "supported_entrypoints": ["main", "web", "api", "ai", "test"],
  "pipeline": [
    "lex",
    "parse",
    "ast",
    "semantic_check",
    "ir",
    "runtime_execute",
    "artifact_emit"
  ],
  "artifact_format": "panther-build-json-v1",
  "next": "R3 Batch 2 Part 2 - Lexer Foundation"
}
EOF

echo "[5/10] Creating runtime VM scaffold..."
cat > runtime/panther_vm/__init__.py <<'PY'
from .vm import PantherVM, PantherRuntimeResult

__all__ = ["PantherVM", "PantherRuntimeResult"]
PY

cat > runtime/panther_vm/vm.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PantherRuntimeResult:
    ok: bool
    output: str
    exit_code: int = 0


class PantherVM:
    """Minimal runtime VM contract scaffold for R3 Batch 2.

    This is not the final interpreter. It defines the execution boundary used by
    later lexer/parser/AST stages.
    """

    def execute_source(self, source: str) -> PantherRuntimeResult:
        if not isinstance(source, str):
            raise TypeError("source must be a string")
        return PantherRuntimeResult(
            ok=True,
            output="PantherVM scaffold accepted source",
            exit_code=0,
        )
PY

echo "[6/10] Documentation..."
cat > docs/compiler_runtime/COMPILER_RUNTIME_CONTRACT.md <<'EOF'
# PantherLang Compiler Runtime Contract

## Purpose

R3 Batch 2 starts the real compiler/runtime line.

The goal is to move from VS Code command wiring and build scaffolds into a real language execution pipeline.

## Pipeline

1. Lex
2. Parse
3. AST
4. Semantic Check
5. IR
6. Runtime Execute
7. Artifact Emit

## Supported Source Files

- `.panther`
- `.pan`

## Supported Entrypoints

- `panther main`
- `panther web`
- `panther api`
- `panther ai`
- `panther test`

## Current Part

Part 1 creates the contract only. Real lexer/parser work starts in Part 2.
EOF

echo "[7/10] Creating tests..."
cat > tests/R3_compiler_runtime/test_r3_batch2_part1_contract.py <<'PY'
import json
from pathlib import Path

from compiler.runtime_contract.contract import get_contract, COMPILER_RUNTIME_VERSION
from runtime.panther_vm import PantherVM, PantherRuntimeResult


def test_compiler_runtime_contract_shape():
    contract = get_contract()
    assert contract.version == COMPILER_RUNTIME_VERSION
    assert ".panther" in contract.source_extensions
    assert ".pan" in contract.source_extensions
    assert "main" in contract.entrypoints
    assert "parse" in contract.stages
    assert contract.build_artifact_format == "panther-build-json-v1"


def test_contract_json_exists_and_matches():
    data = json.loads(Path(".panther/R3_compiler_runtime/compiler_runtime_contract.json").read_text())
    assert data["ok"] is True
    assert data["phase"] == "R3"
    assert data["batch"] == "2"
    assert data["part"] == "1"
    assert ".panther" in data["source_extensions"]
    assert "runtime_execute" in data["pipeline"]


def test_runtime_vm_scaffold_contract():
    vm = PantherVM()
    result = vm.execute_source('panther main { print("hi") }')
    assert isinstance(result, PantherRuntimeResult)
    assert result.ok is True
    assert result.exit_code == 0
    assert "accepted source" in result.output
PY

echo "[8/10] Validation..."
python3 -m py_compile \
  compiler/runtime_contract/__init__.py \
  compiler/runtime_contract/contract.py \
  runtime/panther_vm/__init__.py \
  runtime/panther_vm/vm.py \
  tests/R3_compiler_runtime/test_r3_batch2_part1_contract.py

python3 -m pytest tests/R3_compiler_runtime -q

echo "[9/10] Writing manifest/report..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r32 = root / ".panther/R3_compiler_runtime"
files = [
    "compiler/runtime_contract/__init__.py",
    "compiler/runtime_contract/contract.py",
    "runtime/panther_vm/__init__.py",
    "runtime/panther_vm/vm.py",
    "docs/compiler_runtime/COMPILER_RUNTIME_CONTRACT.md",
    "tests/R3_compiler_runtime/test_r3_batch2_part1_contract.py",
    ".panther/R3_compiler_runtime/compiler_runtime_contract.json",
]
manifest = {
    "ok": True,
    "phase": "R3",
    "batch": "2",
    "part": "1",
    "name": "Compiler Runtime Contract",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": True,
    "contract_version": "0.1.0-r3-b2",
    "files": [
        {
            "path": f,
            "sha256": hashlib.sha256((root / f).read_bytes()).hexdigest(),
            "size": (root / f).stat().st_size
        }
        for f in files if (root / f).exists()
    ],
    "next": "R3 Batch 2 Part 2 - Lexer Foundation"
}
(r32 / "batch2_part1_compiler_runtime_contract_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R3_BATCH2_PART1_COMPILER_RUNTIME_CONTRACT.md" <<'EOF'
# R3 Batch 2 Part 1 - Compiler Runtime Contract

## Status

PASSED

## Added

- Compiler/runtime contract
- PantherVM scaffold
- Compiler runtime documentation
- R3 Batch 2 contract tests

## Next

R3 Batch 2 Part 2 - Lexer Foundation.
EOF

echo "[10/10] Writing status..."
cat > "$R32/status_batch2_part1_compiler_runtime_contract.json" <<'EOF'
{
  "ok": true,
  "phase": "R3",
  "batch": "2",
  "part": "1",
  "status": "PASSED",
  "name": "Compiler Runtime Contract",
  "runtime_modified": true,
  "next": "R3 Batch 2 Part 2 - Lexer Foundation"
}
EOF

echo "============================================================"
echo "✅ R3 Batch 2 Part 1 COMPLETE"
echo "✅ Compiler Runtime Contract READY"
echo "Next: R3 Batch 2 Part 2 - Lexer Foundation"
echo "============================================================"
