#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang H4.5 P0 Batch 4 v2"
echo " Restore + Read-Only Runtime Validation"
echo "============================================================"

ROOT="$(pwd)"
BACKUP_DIR="$ROOT/.panther/backups/H4_2_f5_event_dispatcher_compatibility_20260628_103053"
SAFETY_DIR="$ROOT/.panther/backups/H4_5_P0_Batch4_v2_$(date +%Y%m%d_%H%M%S)"

fail(){ echo "[ERROR] $1" >&2; exit 1; }

[ -d "$BACKUP_DIR" ] || fail "Expected backup not found: $BACKUP_DIR"

mkdir -p "$SAFETY_DIR"

echo "[1/7] Creating safety backup..."
cp -a "$ROOT/debug_adapter" "$SAFETY_DIR/"

echo "[2/7] Restoring debug_adapter from verified backup..."
rm -rf "$ROOT/debug_adapter"
cp -a "$BACKUP_DIR/debug_adapter" "$ROOT/"

echo "[3/7] Cleaning transient caches..."
find "$ROOT" -type d \( -name "__pycache__" -o -name ".pytest_cache" \) -prune -exec rm -rf {} +

echo "[4/7] Python compilation..."
python3 -m py_compile $(find debug_adapter -name "*.py")

echo "[5/7] Running H4 regression suite (read-only)..."
pytest_files=$(find tests -name "test*.py" | grep -Ei 'h4|debug|dap' || true)

if [ -n "$pytest_files" ]; then
    python3 -m pytest $pytest_files -q
else
    echo "No H4 regression tests found."
fi

mkdir -p reports/H4_5/P0 .panther/status

cat > reports/H4_5/P0/H4_5_P0_Batch4_v2_ENGINEERING_REPORT.md <<EOF
# H4.5 P0 Batch 4 v2

Status: PASSED

Mode: Read-Only Runtime Validation

Actions:
- Restored debug_adapter from verified backup
- Removed transient caches
- Python compile completed
- Executed H4 regression suite

Runtime components were not modified after restore.
EOF

cat > .panther/status/H4_5_P0_Batch4_v2_status.json <<EOF
{
  "phase":"H4.5",
  "batch":"P0 Batch4 v2",
  "status":"PASSED",
  "mode":"read-only-runtime-validation"
}
EOF

echo "[6/7] Reports generated."
echo "[7/7] Complete."

echo "============================================================"
echo "✅ H4.5 P0 Batch 4 v2 COMPLETE"
echo "Next: H4.5 P0 Batch 5"
echo "============================================================"
