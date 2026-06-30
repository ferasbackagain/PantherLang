#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "PantherLang R3 Batch 2 Part 3.2 Final"
echo "Recursive Descent Parser Core Final"
echo "=================================================="

PROJECT_ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p .panther/backups
mkdir -p .panther/manifests
mkdir -p docs/compiler_runtime/reports

BACKUP_DIR=".panther/backups/R3_BATCH2_PART3_2_FINAL_${STAMP}"
mkdir -p "${BACKUP_DIR}"

echo "[1/5] Running parser regression..."
pytest -q tests/R3_compiler_runtime || exit 1

echo "[2/5] Running full regression..."
pytest -q || exit 1

cat > .panther/manifests/r3_batch2_part3_2_final_recursive_descent_parser_core_manifest.json <<EOF
{
  "stage":"R3 Batch 2 Part 3.2 Final",
  "status":"PASSED",
  "timestamp":"${STAMP}"
}
EOF

cat > docs/compiler_runtime/reports/r3_batch2_part3_2_final_recursive_descent_parser_core_report.md <<EOF
# R3 Batch 2 Part 3.2 Final

- Unified Recursive Descent Parser interface
- End-to-end parser verification
- Regression completed successfully

Status: PASSED
EOF

echo "[3/5] Manifest generated."
echo "[4/5] Report generated."
echo "[5/5] Backup directory: ${BACKUP_DIR}"

echo
echo "R3 Batch 2 Part 3.2 Final completed successfully."
echo "Next: R3 Batch 2 Part 3.3 - Expression Parser"
