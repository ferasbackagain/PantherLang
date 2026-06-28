#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.9 Release Engineering Verification"
echo "============================================================"

test -f release_engineering/release_engine.py
test -f docs/phase9/PHASE_9_9_STATUS.md
test -f examples/phase9_release/release_demo.panther
echo "✅ structure tests passed"

python3 -m py_compile release_engineering/release_engine.py
echo "✅ python compile passed"

./panther build examples/phase9_release/release_demo.panther --release >/tmp/p99_build.json
grep -q '"ok": true' /tmp/p99_build.json
test -f build/release/release_demo.sh
bash build/release/release_demo.sh | grep -q "Phase 9.9 Release Engineering"
echo "✅ release demo build passed"

rm -rf /tmp/p99_release
./panther release create --version 0.9.9 --channel developer --out-dir /tmp/p99_release >/tmp/p99_release.json
grep -q '"ok": true' /tmp/p99_release.json
grep -q '"phase": "9.9"' /tmp/p99_release.json
test -f /tmp/p99_release/release.manifest.json
test -f /tmp/p99_release/RELEASE_NOTES.md
test -f /tmp/p99_release.tar.gz
grep -q '"version": "0.9.9"' /tmp/p99_release/release.manifest.json
grep -q 'PantherLang 0.9.9' /tmp/p99_release/RELEASE_NOTES.md
echo "✅ release creation tests passed"

tar -tzf /tmp/p99_release.tar.gz | grep -q 'release.manifest.json'
tar -tzf /tmp/p99_release.tar.gz | grep -q 'RELEASE_NOTES.md'
echo "✅ release archive tests passed"

echo "✅ PantherLang Phase 9.9 Release Engineering verification complete."
