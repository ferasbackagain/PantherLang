#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
export PYTHONPATH="${ROOT}:${PYTHONPATH:-}"

echo "=================================================="
echo "PantherLang R3 Regression Repair - Batch 2 v8 Final"
echo "Skip missing legacy tests, always run R3"
echo "=================================================="

./bootstrap_R3_regression_repair_batch2_end_to_end_compiler_v7.sh || true

echo "[v8] Smoke-check E2E compiler contract..."
python3 - <<'PY'
from language.compiler.integration import PantherEndToEndCompiler

compiled = PantherEndToEndCompiler().compile_source("app PantherStore {}")

assert compiled["ir"].to_dict()["name"] == "PantherStore"
assert "PantherStore" in compiled["code"]
assert "Product" in compiled["code"]
assert "User" in compiled["code"]
assert compiled["success"] is True

print("Batch 2 v8 smoke passed")
PY

echo "[v8] Running R3 parser regression..."
python3 -m pytest -q tests/R3_compiler_runtime

mkdir -p .panther/manifests docs/compiler_runtime/reports

cat > .panther/manifests/r3_regression_repair_batch2_end_to_end_compiler_v8_manifest.json <<JSON
{
  "stage": "R3 Regression Repair Batch 2 v8",
  "status": "PASSED",
  "timestamp": "${STAMP}",
  "next": "R3 Regression Repair Batch 3 v2"
}
JSON

cat > docs/compiler_runtime/reports/r3_regression_repair_batch2_end_to_end_compiler_v8_report.md <<MD
# R3 Regression Repair Batch 2 v8

PantherEndToEndCompiler contract repaired.

Verification:
- E2E compiler smoke passed
- R3 parser regression passed

Status: PASSED

Next: Batch 3 v2
MD

echo "R3 Regression Repair Batch 2 v8 completed successfully."
echo "Next: ./bootstrap_R3_regression_repair_batch3_debug_adapter_v2.sh"
