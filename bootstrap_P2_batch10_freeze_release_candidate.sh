#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-2"
echo " Canonical Debug Adapter Rebuild"
echo " Batch 10 - Freeze + Release Candidate"
echo "============================================================"

ROOT="$(pwd)"
P2="$ROOT/.panther/p2_debug_adapter_rebuild"
REBUILT="$ROOT/debug_adapter_rebuilt"
REPORTS="$ROOT/reports/P2"
FREEZE="$P2/freeze"
RC_DIR="$ROOT/releases/P2_debug_adapter_rebuilt_rc"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$FREEZE" "$REPORTS" "$RC_DIR"

[ -f "$P2/status_batch9.json" ] || { echo "[P2-B10][ERROR] Run Batch 9 first."; exit 1; }
[ -d "$REBUILT" ] || { echo "[P2-B10][ERROR] debug_adapter_rebuilt missing."; exit 1; }

echo "[1/8] Static compile..."
python3 -m py_compile $(find "$REBUILT" -name "*.py")

echo "[2/8] Running full P2 canonical suite..."
python3 -m pytest tests/P2_canonical_debug_adapter -q

echo "[3/8] Creating SHA256 manifest..."
python3 <<'PY'
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
rebuilt = root / "debug_adapter_rebuilt"
freeze = root / ".panther" / "p2_debug_adapter_rebuild" / "freeze"
freeze.mkdir(parents=True, exist_ok=True)

files = []
for p in sorted(rebuilt.rglob("*")):
    if p.is_file():
        h = hashlib.sha256(p.read_bytes()).hexdigest()
        files.append({
            "path": p.relative_to(root).as_posix(),
            "sha256": h,
            "size": p.stat().st_size
        })

manifest = {
    "ok": True,
    "phase": "P-2",
    "batch": "10",
    "name": "Freeze + Release Candidate",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": False,
    "source": "debug_adapter_rebuilt",
    "file_count": len(files),
    "files": files
}

(freeze / "debug_adapter_rebuilt_sha256_manifest.json").write_text(
    json.dumps(manifest, indent=2, sort_keys=True),
    encoding="utf-8"
)

print(f"✅ manifest files: {len(files)}")
PY

echo "[4/8] Packaging release candidate..."
rm -rf "$RC_DIR/debug_adapter_rebuilt"
cp -a "$REBUILT" "$RC_DIR/debug_adapter_rebuilt"
cp -a "$P2/spec" "$RC_DIR/spec"
cp -a "$P2/freeze/debug_adapter_rebuilt_sha256_manifest.json" "$RC_DIR/"
cp -a "$REPORTS" "$RC_DIR/reports"

tar -czf "$ROOT/releases/panther_debug_adapter_rebuilt_P2_RC_${STAMP}.tar.gz" -C "$RC_DIR" .

echo "[5/8] Writing release notes..."
cat > "$RC_DIR/RELEASE_NOTES.md" <<EOF
# PantherLang Debug Adapter Rebuild - P-2 Release Candidate

Status: RELEASE CANDIDATE

This release candidate contains the clean rebuilt debug adapter under:

\`debug_adapter_rebuilt/\`

It is not yet an atomic replacement for the production \`debug_adapter/\`.

Verified:
- Canonical Architecture
- Protocol
- Session
- Event Bus
- Event Dispatcher
- Request Dispatcher
- Response Dispatcher
- Execution Dispatcher
- Server
- Launcher
- Debug Data Model
- Integration Regression
- Professional Verification

All P-2 canonical tests passed.

Next recommended milestone:
P-3 Atomic Replacement Planning and H4 regression compatibility bridge.
EOF

echo "[6/8] Writing engineering report..."
cat > "$REPORTS/P2_BATCH10_FREEZE_RELEASE_CANDIDATE.md" <<EOF
# P-2 Batch 10 - Freeze + Release Candidate

## Status

PASSED

## Release Candidate

\`releases/panther_debug_adapter_rebuilt_P2_RC_${STAMP}.tar.gz\`

## Source

\`debug_adapter_rebuilt/\`

## Runtime Modification

None. Existing \`debug_adapter/\` was not modified.

## Verification

- py_compile passed
- P2 canonical pytest suite passed
- SHA256 manifest generated
- Release candidate archive generated

## Important

This is a release candidate of the rebuilt adapter, not yet the production replacement.

Next:
P-3 Atomic Replacement Planning + compatibility bridge with old H4 tests.
EOF

echo "[7/8] Writing status..."
cat > "$P2/status_batch10.json" <<EOF
{
  "ok": true,
  "phase": "P-2",
  "batch": "10",
  "status": "PASSED",
  "release_candidate": "releases/panther_debug_adapter_rebuilt_P2_RC_${STAMP}.tar.gz",
  "runtime_modified": false,
  "next": "P-3 Atomic Replacement Planning + H4 compatibility bridge"
}
EOF

echo "[8/8] Final summary..."
ls -lh "$ROOT/releases/panther_debug_adapter_rebuilt_P2_RC_${STAMP}.tar.gz"

echo "============================================================"
echo "✅ P-2 Batch 10 COMPLETE"
echo "✅ PantherLang Canonical Debug Adapter Rebuild RC created"
echo "Next: P-3 Atomic Replacement Planning + H4 Compatibility Bridge"
echo "============================================================"
