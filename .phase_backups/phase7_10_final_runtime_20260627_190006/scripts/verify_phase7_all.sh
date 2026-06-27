#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase7_1_ai_runtime.sh
bash scripts/verify_phase7_2_cli_run.sh
echo "✅ ALL PHASE 7 TESTS PASSED THROUGH 7.2"
