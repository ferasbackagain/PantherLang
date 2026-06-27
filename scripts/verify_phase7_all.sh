#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase7_1_ai_runtime.sh
bash scripts/verify_phase7_2_cli_run.sh
bash scripts/verify_phase7_3_agent_execution.sh
bash scripts/verify_phase7_4_task_scheduler.sh
bash scripts/verify_phase7_5_multi_agent.sh
bash scripts/verify_phase7_6_context_state.sh
bash scripts/verify_phase7_7_plugins.sh
bash scripts/verify_phase7_8_secure_sandbox.sh
bash scripts/verify_phase7_9_distributed_runtime.sh
bash scripts/verify_phase7_10_final_runtime.sh
echo "✅ ALL PHASE 7 TESTS PASSED"
echo "✅ PantherLang Phase 7 is COMPLETE"
