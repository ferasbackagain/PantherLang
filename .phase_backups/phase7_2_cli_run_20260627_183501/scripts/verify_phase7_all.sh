#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase7_1_ai_runtime.sh
bash scripts/verify_phase7_2_native_memory.sh
bash scripts/verify_phase7_3_agent_execution.sh
echo "✅ ALL PHASE 7 TESTS PASSED THROUGH 7.3"
