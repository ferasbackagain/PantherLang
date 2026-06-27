#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 7.7 PRO - Plugin & Extension System"
echo "============================================================"

ROOT="$(pwd)"
mkdir -p runtime/plugins examples/phase7_plugins tests/phase7_7 scripts

cat > runtime/plugins/plugin_system.py <<'PY'
from dataclasses import dataclass

@dataclass
class Plugin:
    name:str
    version:str
    enabled:bool=True

class PluginManager:
    def __init__(self):
        self.plugins={}

    def register(self,name,version="1.0"):
        self.plugins[name]=Plugin(name,version)

    def load(self,name):
        if name not in self.plugins:
            raise KeyError(name)
        return self.plugins[name]

    def list(self):
        return list(self.plugins.values())
PY

cat > examples/phase7_plugins/plugin_demo.panther <<'EOF'
module panther.plugins

print "Phase 7.7 Plugin & Extension System"
EOF

cat > scripts/verify_phase7_7_plugins.sh <<'EOF'
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
EOF

chmod +x scripts/verify_phase7_7_plugins.sh

echo "[phase7.7] Running verification..."
bash scripts/verify_phase7_7_plugins.sh

echo "============================================================"
echo " Phase 7.7 COMPLETE"
echo " Next: Phase 7.8 Secure Sandbox Runtime"
echo "============================================================"
