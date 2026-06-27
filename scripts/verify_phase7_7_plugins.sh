#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.7 PRO Plugin Verification FAST"
echo "============================================================"

test -f runtime/plugins/plugin_system.py
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.plugins.plugin_system import PluginManager
pm=PluginManager()
pm.register("security")
pm.register("ai")
assert len(pm.list())==2
assert pm.load("security").enabled
print("✅ plugin manager tests passed")
PY

./panther run examples/phase7_plugins/plugin_demo.panther | grep -q "Phase 7.7 Plugin & Extension System"
echo "✅ CLI bridge tests passed"

python3 -m py_compile runtime/plugins/plugin_system.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 7.7 Plugin & Extension System verification complete."
