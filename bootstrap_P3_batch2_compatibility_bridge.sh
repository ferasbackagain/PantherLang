#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3"
echo " Atomic Replacement Planning"
echo " Batch 2 - Compatibility Bridge"
echo "============================================================"

ROOT="$(pwd)"
P3="$ROOT/.panther/p3_atomic_replacement"
REBUILT="$ROOT/debug_adapter_rebuilt"
BRIDGE="$ROOT/debug_adapter_bridge"
REPORTS="$ROOT/reports/P3"

mkdir -p "$BRIDGE" "$REPORTS"

[ -f "$P3/status_batch1.json" ] || { echo "[P3-B2][ERROR] Run Batch 1 first."; exit 1; }

echo "[1/7] Generating compatibility bridge..."
python3 <<'PY'
from pathlib import Path
root=Path.cwd()
rebuilt=root/"debug_adapter_rebuilt"
bridge=root/"debug_adapter_bridge"
bridge.mkdir(exist_ok=True)
mods=[]
for f in rebuilt.glob("*.py"):
    if f.name=="__init__.py":
        continue
    name=f.stem
    (bridge/f.name).write_text(f"from debug_adapter_rebuilt.{name} import *\n")
    mods.append(name)
(bridge/"__init__.py").write_text("# Compatibility bridge\n")
print("modules:",len(mods))
PY

echo "[2/7] Compile bridge..."
python3 -m py_compile $(find "$BRIDGE" -name "*.py")

echo "[3/7] Smoke import..."
python3 <<'PY'
import importlib, pathlib
b=pathlib.Path("debug_adapter_bridge")
mods=0
for f in b.glob("*.py"):
    if f.name=="__init__.py": continue
    importlib.import_module(f"debug_adapter_bridge.{f.stem}")
    mods+=1
print("imports:",mods)
PY

echo "[4/7] Writing compatibility map..."
cp "$P3/dependency_census.json" "$P3/compatibility_map.json"

echo "[5/7] Engineering report..."
cat > "$REPORTS/P3_BATCH2_COMPATIBILITY_BRIDGE.md" <<EOF
Status: PASSED

Created:
- debug_adapter_bridge/
- compatibility_map.json

Runtime modified: NO

Next:
P-3 Batch 3 - Dry-run import switch.
EOF

echo "[6/7] Status..."
cat > "$P3/status_batch2.json" <<EOF
{"ok":true,"phase":"P-3","batch":"2","status":"PASSED","runtime_modified":false,"next":"P-3 Batch 3 - Dry-run import switch"}
EOF

echo "[7/7] Done."
echo "============================================================"
echo "✅ P-3 Batch 2 COMPLETE"
echo "Next: P-3 Batch 3 - Dry-run Import Switch"
echo "============================================================"
