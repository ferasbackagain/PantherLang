#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.3 Compiler Optimization Verification"
echo "============================================================"

test -f optimizer/compiler_optimizer.py
echo "✅ structure tests passed"

python3 -m py_compile optimizer/compiler_optimizer.py
echo "✅ python compile passed"

python3 optimizer/compiler_optimizer.py | grep -q '"phase": "9.3"'
echo "✅ optimizer engine tests passed"

./panther build examples/phase9_optimizer/optimizer_demo.panther --release >/tmp/p93.json
grep -q '"ok": true' /tmp/p93.json
test -f build/release/optimizer_demo.sh
bash build/release/optimizer_demo.sh | grep -q "Phase 9.3 Compiler Optimization"
echo "✅ release optimization build passed"

echo "✅ PantherLang Phase 9.3 Compiler Optimization verification complete."
