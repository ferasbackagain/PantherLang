#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

bash scripts/verify_phase5_1_ai_native_core.sh
bash scripts/verify_phase5_2_intelligent_type_system.sh
bash scripts/verify_phase5_3_memory_context_engine.sh
bash scripts/verify_phase5_4_multi_agent_runtime.sh
bash scripts/verify_phase5_5_natural_language_programming.sh
bash scripts/verify_phase5_6_ai_optimizing_compiler.sh
bash scripts/verify_phase5_7_distributed_execution.sh
bash scripts/verify_phase5_8_secure_ai_sandbox.sh
bash scripts/verify_phase5_9_ai_package_ecosystem.sh
bash scripts/verify_phase5_10_final_integration.sh

echo "✅ ALL PHASE 5 TESTS PASSED"
