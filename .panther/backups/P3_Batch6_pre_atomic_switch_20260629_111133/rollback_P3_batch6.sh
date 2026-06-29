#!/usr/bin/env bash
set -euo pipefail
ROOT="$(pwd)"
echo "Rolling back P-3 Batch 6..."
[ -d "/home/panther/pantherlang/PantherLang_Developer_Edition_v0_5/.panther/backups/P3_Batch6_pre_atomic_switch_20260629_111133/debug_adapter_legacy_before_switch" ] || { echo "rollback source missing"; exit 1; }
rm -rf "$ROOT/debug_adapter"
cp -a "/home/panther/pantherlang/PantherLang_Developer_Edition_v0_5/.panther/backups/P3_Batch6_pre_atomic_switch_20260629_111133/debug_adapter_legacy_before_switch" "$ROOT/debug_adapter"
python3 -m py_compile $(find "$ROOT/debug_adapter" -name "*.py")
echo "✅ rollback complete"
