#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "PantherLang R3 Batch 2 Part 3.2 Final Hotfix 1"
echo "Recursive Descent Parser Core Final"
echo "Fix: PYTHONPATH + direct regression execution"
echo "=================================================="

PROJECT_ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"

export PYTHONPATH="${PROJECT_ROOT}:${PYTHONPATH:-}"

mkdir -p .panther/backups
mkdir -p .panther/manifests
mkdir -p docs/compiler_runtime/reports

BACKUP_DIR=".panther/backups/R3_BATCH2_PART3_2_FINAL_HOTFIX1_${STAMP}"
mkdir -p "$BACKUP_DIR"

echo "[1/7] Checking project root..."
if [ ! -d "compiler" ]; then
  echo "ERROR: compiler/ directory not found."
  echo "Run this script from PantherLang project root."
  exit 1
fi

if [ ! -d "tests/R3_compiler_runtime" ]; then
  echo "ERROR: tests/R3_compiler_runtime not found."
  exit 1
fi

echo "[2/7] PYTHONPATH fixed:"
echo "$PYTHONPATH"

echo "[3/7] Running R3 compiler runtime parser regression..."
python3 -m pytest -q tests/R3_compiler_runtime

echo "[4/7] Running full project regression..."
python3 -m pytest -q

echo "[5/7] Writing manifest..."
cat > .panther/manifests/r3_batch2_part3_2_final_recursive_descent_parser_core_hotfix1_manifest.json <<JSON
{
  "stage": "R3 Batch 2 Part 3.2 Final - Recursive Descent Parser Core Final Hotfix 1",
  "status": "PASSED",
  "fix": "Added PYTHONPATH project-root export before pytest execution",
  "timestamp": "${STAMP}",
  "backup": "${BACKUP_DIR}",
  "next": "R3 Batch 2 Part 3.3 - Expression Parser"
}
JSON

echo "[6/7] Writing engineering report..."
cat > docs/compiler_runtime/reports/r3_batch2_part3_2_final_recursive_descent_parser_core_hotfix1_report.md <<MD
# R3 Batch 2 Part 3.2 Final - Hotfix 1

## Purpose

Fix pytest collection failure caused by Python not resolving the project package:

\`\`\`text
ModuleNotFoundError: No module named 'compiler'
\`\`\`

## Fix

The script now exports the project root into PYTHONPATH before running tests:

\`\`\`bash
export PYTHONPATH="\${PROJECT_ROOT}:\${PYTHONPATH:-}"
\`\`\`

## Verification

Executed:

\`\`\`bash
python3 -m pytest -q tests/R3_compiler_runtime
python3 -m pytest -q
\`\`\`

## Status

PASSED

## Next

R3 Batch 2 Part 3.3 - Expression Parser
MD

echo "[7/7] Completed."
echo
echo "R3 Batch 2 Part 3.2 Final Hotfix 1 completed successfully."
echo "Manifest: .panther/manifests/r3_batch2_part3_2_final_recursive_descent_parser_core_hotfix1_manifest.json"
echo "Report: docs/compiler_runtime/reports/r3_batch2_part3_2_final_recursive_descent_parser_core_hotfix1_report.md"
echo "Backup: ${BACKUP_DIR}"
echo "Next: R3 Batch 2 Part 3.3 - Expression Parser"
