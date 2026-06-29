#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.10 Final Production Toolchain Verification"
echo "============================================================"

test -f toolchain/final/final_toolchain.py
echo "✅ structure tests passed"

python3 -m py_compile toolchain/final/final_toolchain.py
echo "✅ python compile passed"

python3 toolchain/final/final_toolchain.py >/tmp/p910.json
grep -q '"ok": true' /tmp/p910.json
grep -q '"ready_for_phase10": true' /tmp/p910.json
echo "✅ integrated toolchain tests passed"

./panther build examples/phase9_final/final_demo.panther --release >/tmp/p910_build.json
grep -q '"ok": true' /tmp/p910_build.json
test -f build/release/final_demo.sh
bash build/release/final_demo.sh | grep -q "Phase 9.10 Final Production Toolchain"
echo "✅ release pipeline passed"

./panther release create --version 0.9.10 --channel production >/tmp/p910_release.json
grep -q '"ok": true' /tmp/p910_release.json
echo "✅ production release pipeline passed"

echo "✅ PantherLang Phase 9.10 Final Production Toolchain verification complete."
echo "✅ PantherLang Phase 9 is COMPLETE."
