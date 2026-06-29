#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.1 Verification"
echo "============================================================"

test -x installer/install.sh
echo "✅ installer exists"

grep -q "/usr/local/bin/Panther" installer/install.sh
echo "✅ installs Panther globally"

./panther run examples/phase8_cli/install_demo.panther | grep -q "Phase 8.1 Global CLI Installer"
echo "✅ compiler/runtime bridge"

python3 -m py_compile cli/panther_cli_v2.py
echo "✅ python compile"

echo "✅ PantherLang Phase 8.1 Global CLI Installer verification complete."
