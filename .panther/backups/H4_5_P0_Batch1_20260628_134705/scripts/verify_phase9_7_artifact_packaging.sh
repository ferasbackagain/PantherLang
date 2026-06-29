#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.7 Artifact Packaging Verification"
echo "============================================================"

test -f toolchain/packager/artifact_packager.py
test -f examples/phase9_packaging/packaging_demo.panther
test -f docs/phase9/PHASE_9_7_STATUS.md
echo "✅ structure tests passed"

python3 -m py_compile toolchain/packager/artifact_packager.py
echo "✅ python compile passed"

./panther build examples/phase9_packaging/packaging_demo.panther --release >/tmp/p97_build.json
grep -q '"ok": true' /tmp/p97_build.json
test -f build/release/packaging_demo.sh
echo "✅ release build passed"

rm -rf /tmp/p97_dist
mkdir -p /tmp/p97_dist

./panther pack pack build/release/packaging_demo.sh --name packaging-demo --version 0.9.7 --out-dir /tmp/p97_dist >/tmp/p97_pack.json
grep -q '"ok": true' /tmp/p97_pack.json
grep -q '"phase": "9.7"' /tmp/p97_pack.json
test -f /tmp/p97_dist/packaging-demo-0.9.7.tar.gz
test -f /tmp/p97_dist/package.manifest.json
echo "✅ artifact packaging tests passed"

./panther pack inspect /tmp/p97_dist/packaging-demo-0.9.7.tar.gz >/tmp/p97_inspect.json
grep -q '"ok": true' /tmp/p97_inspect.json
grep -q '"has_manifest": true' /tmp/p97_inspect.json
grep -q 'packaging_demo.sh' /tmp/p97_inspect.json
echo "✅ package inspection tests passed"

tar -tzf /tmp/p97_dist/packaging-demo-0.9.7.tar.gz | grep -q 'package.manifest.json'
tar -tzf /tmp/p97_dist/packaging-demo-0.9.7.tar.gz | grep -q 'packaging_demo.sh'
echo "✅ tar package content tests passed"

echo "✅ PantherLang Phase 9.7 Artifact Packaging verification complete."
