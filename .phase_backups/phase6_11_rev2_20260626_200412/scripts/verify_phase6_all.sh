#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

bash scripts/verify_phase6_10_final_compiler_integration.sh
bash scripts/verify_phase6_11_expressions_engine.sh

echo "✅ ALL PHASE 6 TESTS PASSED THROUGH 6.11"
