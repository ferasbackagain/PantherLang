#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "PantherLang R3 Regression Repair - Batch 1"
echo "compiler.core Compatibility Layer"
echo "=================================================="

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
export PYTHONPATH="${ROOT}:${PYTHONPATH:-}"

if [[ ! -d compiler || ! -d language || ! -d tests ]]; then
  echo "ERROR: Run this script from PantherLang project root."
  exit 1
fi

mkdir -p .panther/backups .panther/manifests docs/compiler_runtime/reports
BACKUP=".panther/backups/R3_REGRESSION_REPAIR_BATCH1_COMPILER_CORE_${STAMP}"
mkdir -p "$BACKUP"

echo "[1/6] Backup current compiler/core if present..."
if [[ -d compiler/core ]]; then
  mkdir -p "$BACKUP/compiler"
  cp -a compiler/core "$BACKUP/compiler/core"
fi

echo "[2/6] Creating compiler.core compatibility layer..."
python3 <<'PY'
from pathlib import Path
import shutil

root = Path.cwd()
src = root / "language/compiler/core"
dst = root / "compiler/core"
dst.mkdir(parents=True, exist_ok=True)

files = [
    "__init__.py",
    "tokens.py",
    "lexer.py",
    "tokenizer.py",
    "parser.py",
    "ast.py",
    "ir.py",
    "ir_nodes.py",
    "ir_builder.py",
    "ir_serializer.py",
    "codegen.py",
    "diagnostics.py",
    "semantic_types.py",
    "semantic.py",
    "semantic_engine.py",
    "scope.py",
    "symbol_table.py",
    "type_checker.py",
    "compiler.py",
]

for name in files:
    src_file = src / name
    dst_file = dst / name
    if src_file.exists():
        shutil.copy2(src_file, dst_file)

if not (dst / "__init__.py").exists():
    (dst / "__init__.py").write_text("", encoding="utf-8")

# Ensure compiler is a package
compiler_init = root / "compiler/__init__.py"
if not compiler_init.exists():
    compiler_init.write_text("", encoding="utf-8")
PY

echo "[3/6] Running compiler.core focused tests..."
python3 -m pytest -q \
  language/tests/test_phase1_lexer.py \
  language/tests/test_phase1_parser.py \
  language/tests/test_phase1_ir.py \
  language/tests/test_phase1_codegen.py \
  language/tests/test_phase1_compiler.py \
  language/tests/test_phase1_models.py \
  language/tests/test_phase1_semantic.py \
  language/tests/test_phase2_1_source_pipeline.py \
  language/tests/test_v0_5.py

echo "[4/6] Running R3 parser regression..."
python3 -m pytest -q tests/R3_compiler_runtime

echo "[5/6] Writing manifest/report..."
cat > .panther/manifests/r3_regression_repair_batch1_compiler_core_manifest.json <<JSON
{
  "stage": "R3 Regression Repair Batch 1 - compiler.core Compatibility Layer",
  "status": "PASSED",
  "timestamp": "${STAMP}",
  "backup": "${BACKUP}",
  "next": "R3 Regression Repair Batch 2 - PantherEndToEndCompiler Integration"
}
JSON

cat > docs/compiler_runtime/reports/r3_regression_repair_batch1_compiler_core_report.md <<MD
# R3 Regression Repair Batch 1

## Scope

Restored \`compiler.core\` compatibility layer from \`language/compiler/core\`.

## Verification

- language phase1/phase2/v0.5 import tests
- R3 compiler runtime parser regression

## Status

PASSED

## Next

R3 Regression Repair Batch 2 - PantherEndToEndCompiler Integration
MD

echo "[6/6] Completed."
echo "R3 Regression Repair Batch 1 completed successfully."
echo "Manifest: .panther/manifests/r3_regression_repair_batch1_compiler_core_manifest.json"
echo "Report: docs/compiler_runtime/reports/r3_regression_repair_batch1_compiler_core_report.md"
echo "Backup: ${BACKUP}"
echo "Next: R3 Regression Repair Batch 2 - PantherEndToEndCompiler Integration"
