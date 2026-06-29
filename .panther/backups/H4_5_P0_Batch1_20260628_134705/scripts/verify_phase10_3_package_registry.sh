#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 10.3 Package Registry Verification"
echo "============================================================"

test -f registry/registry_cli.py
test -f registry/registry_manifest.json
test -f docs/phase10/PHASE_10_3_STATUS.md
test -f examples/phase10_registry/registry_demo.panther
echo "✅ registry structure tests passed"

python3 -m py_compile registry/registry_cli.py
echo "✅ python compile passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("registry/registry_manifest.json").read_text())
assert m["phase"] == "10.3"
assert m["version"] == "1.0.0-rc1"
assert m["status"] == "local-official-registry-foundation"
assert m["registry_type"] == "local-first"
assert m["network_required"] is False
print("✅ registry manifest tests passed")
PY

Panther registry init >/tmp/panther_phase10_3_registry_init.json
grep -q '"ok": true' /tmp/panther_phase10_3_registry_init.json
test -f registry/index.json
echo "✅ registry init passed"

TMPPKG="$(mktemp -d)"
mkdir -p "$TMPPKG/panther_ai"
cat > "$TMPPKG/panther_ai/package.panther" <<'PKG'
print "panther ai package"
PKG

Panther registry publish "$TMPPKG/panther_ai" --name panther.ai --version 0.1.0 --description "AI foundation package" >/tmp/panther_phase10_3_publish.json
grep -q '"ok": true' /tmp/panther_phase10_3_publish.json
grep -q 'panther.ai@0.1.0' registry/index.json
echo "✅ registry publish passed"

Panther registry search ai >/tmp/panther_phase10_3_search.json
grep -q '"ok": true' /tmp/panther_phase10_3_search.json
grep -q 'panther.ai@0.1.0' /tmp/panther_phase10_3_search.json
echo "✅ registry search passed"

rm -rf /tmp/panther_phase10_3_install
Panther registry install panther.ai --version 0.1.0 --dest /tmp/panther_phase10_3_install >/tmp/panther_phase10_3_install.json
grep -q '"ok": true' /tmp/panther_phase10_3_install.json
test -f /tmp/panther_phase10_3_install/panther_ai/package.panther
echo "✅ registry install passed"

Panther run examples/phase10_registry/registry_demo.panther >/tmp/panther_phase10_3_run.log
grep -q 'Phase 10.3 Official Package Registry' /tmp/panther_phase10_3_run.log
grep -q 'Local-first registry ready' /tmp/panther_phase10_3_run.log
echo "✅ registry demo run passed"

Panther build examples/phase10_registry/registry_demo.panther --release >/tmp/panther_phase10_3_build.json
grep -q '"ok": true' /tmp/panther_phase10_3_build.json
test -f build/release/registry_demo.sh
bash build/release/registry_demo.sh | grep -q 'Phase 10.3 Official Package Registry'
echo "✅ registry release build passed"

rm -rf "$TMPPKG"

echo "✅ PantherLang Phase 10.3 Official Package Registry verification complete."
