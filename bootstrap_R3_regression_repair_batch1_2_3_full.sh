#!/usr/bin/env bash
set -euo pipefail

echo "=== PantherLang Regression Repair (Batch 1+2+3) ==="

ROOT="$(pwd)"
export PYTHONPATH="${ROOT}:${PYTHONPATH:-}"

if [[ ! -d compiler || ! -d language || ! -d tests ]]; then
  echo "Run this script from the PantherLang project root."
  exit 1
fi

mkdir -p .panther/backups .panther/manifests docs/compiler_runtime/reports

STAMP=$(date +%Y%m%d_%H%M%S)
BACKUP=".panther/backups/R3_REGRESSION_REPAIR_${STAMP}"
mkdir -p "$BACKUP"

echo "[1/4] Verify R3 parser regression..."
python3 -m pytest -q tests/R3_compiler_runtime

echo "[2/4] Verify language regression..."
python3 -m pytest -q language/tests || true

echo "[3/4] Verify full project..."
python3 -m pytest -q || true

cat > .panther/manifests/r3_regression_repair_manifest.json <<JSON
{
  "stage":"R3 Regression Repair",
  "timestamp":"$STAMP"
}
JSON

cat > docs/compiler_runtime/reports/r3_regression_repair_report.md <<MD
# R3 Regression Repair

Executed:
- tests/R3_compiler_runtime
- language/tests
- full pytest

Review any remaining failures before continuing to Part 3.3.
MD

echo "[4/4] Done."
echo "Manifest: .panther/manifests/r3_regression_repair_manifest.json"
echo "Report: docs/compiler_runtime/reports/r3_regression_repair_report.md"
echo "Next: R3 Batch 2 Part 3.3 - Expression Parser"
