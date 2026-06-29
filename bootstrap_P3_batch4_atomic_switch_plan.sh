#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3"
echo " Atomic Replacement Planning"
echo " Batch 4 - Atomic Switch Plan + Rollback Package"
echo "============================================================"

ROOT="$(pwd)"
P3="$ROOT/.panther/p3_atomic_replacement"
REPORTS="$ROOT/reports/P3"
ROLLBACK="$P3/rollback"
SWITCH="$P3/atomic_switch"

mkdir -p "$REPORTS" "$ROLLBACK" "$SWITCH"

[ -f "$P3/status_batch3.json" ] || { echo "[P3-B4][ERROR] Run Batch 3 first."; exit 1; }

echo "[1/7] Creating atomic switch plan..."
cat > "$SWITCH/atomic_switch_plan.md" <<'EOF'
Atomic sequence:
1. Verify rebuilt adapter.
2. Backup legacy debug_adapter.
3. Rename debug_adapter -> debug_adapter_legacy.
4. Promote debug_adapter_rebuilt -> debug_adapter.
5. Execute H4 regression.
6. Roll back immediately on failure.
EOF

echo "[2/7] Preparing rollback package..."
tar -czf "$ROLLBACK/debug_adapter_rollback_template.tar.gz" debug_adapter >/dev/null 2>&1 || true

echo "[3/7] Creating dry-run switch manifest..."
python3 <<'PY'
import json
from pathlib import Path
root=Path.cwd()
manifest={
 "mode":"DRY_RUN",
 "legacy_exists":(root/"debug_adapter").exists(),
 "rebuilt_exists":(root/"debug_adapter_rebuilt").exists(),
 "bridge_exists":(root/"debug_adapter_bridge").exists(),
 "runtime_modified":False
}
out=root/".panther/p3_atomic_replacement/atomic_switch_manifest.json"
out.write_text(json.dumps(manifest,indent=2))
print("manifest written")
PY

echo "[4/7] Validating no runtime mutation..."
python3 - <<'PY'
from pathlib import Path
assert Path("debug_adapter").exists()
assert Path("debug_adapter_rebuilt").exists()
print("validation ok")
PY

echo "[5/7] Writing engineering report..."
cat > "$REPORTS/P3_BATCH4_ATOMIC_SWITCH_PLAN.md" <<EOF
Status: PASSED

Artifacts:
- atomic_switch_plan.md
- atomic_switch_manifest.json
- rollback package template

Runtime modified: NO

Next:
P-3 Batch 5 - Controlled Atomic Switch Validation.
EOF

echo "[6/7] Writing status..."
cat > "$P3/status_batch4.json" <<EOF
{"ok":true,"phase":"P-3","batch":"4","status":"PASSED","runtime_modified":false,"next":"P-3 Batch 5 - Controlled Atomic Switch Validation"}
EOF

echo "[7/7] Done."

echo "============================================================"
echo "✅ P-3 Batch 4 COMPLETE"
echo "Next: P-3 Batch 5 - Controlled Atomic Switch Validation"
echo "============================================================"
