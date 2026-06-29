#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.4 Incremental Compilation Verification"
echo "============================================================"

test -f compiler/incremental/incremental_compiler.py
echo "✅ structure tests passed"

python3 -m py_compile compiler/incremental/incremental_compiler.py
echo "✅ python compile passed"

rm -f .panther_cache/incremental_demo.json
python3 compiler/incremental/incremental_compiler.py examples/phase9_incremental/incremental_demo.panther > /tmp/inc1.json
grep -q '"changed": true' /tmp/inc1.json
echo "✅ first compile detected"

python3 compiler/incremental/incremental_compiler.py examples/phase9_incremental/incremental_demo.panther > /tmp/inc2.json
grep -q '"changed": false' /tmp/inc2.json
echo "✅ cache hit detected"

./panther build examples/phase9_incremental/incremental_demo.panther --release >/tmp/incbuild.json
grep -q '"ok": true' /tmp/incbuild.json
test -f build/release/incremental_demo.sh
bash build/release/incremental_demo.sh | grep -q "Phase 9.4 Incremental Compilation"
echo "✅ release build passed"

echo "✅ PantherLang Phase 9.4 Incremental Compilation verification complete."
