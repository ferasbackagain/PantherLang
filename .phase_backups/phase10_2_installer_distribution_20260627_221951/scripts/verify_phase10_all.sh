#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase10_1_stable_release.sh
echo "✅ ALL PHASE 10 TESTS PASSED THROUGH 10.1"
