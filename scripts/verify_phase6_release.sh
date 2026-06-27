#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase6_19_fast_regression.sh
bash scripts/verify_phase6_20_production_readiness.sh
echo "✅ PantherLang Phase 6 release verification complete."
