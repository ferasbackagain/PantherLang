#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase10_1_stable_release.sh
bash scripts/verify_phase10_2_installer_distribution.sh
bash scripts/verify_phase10_3_package_registry.sh
echo "✅ ALL PHASE 10 TESTS PASSED THROUGH 10.3"
