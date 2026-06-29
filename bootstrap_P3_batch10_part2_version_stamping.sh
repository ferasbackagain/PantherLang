#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 10"
echo " Part 2 - Version Stamping"
echo "============================================================"

ROOT="$(pwd)"
B10="$ROOT/.panther/p3_batch10_official_release"
REPORTS="$ROOT/reports/P3/Batch10"
VERSION_FILE="$B10/OFFICIAL_DEBUG_ADAPTER_VERSION.json"
STAMP="$(date +%Y%m%d_%H%M%S)"
VERSION="v0.9.10-debug-adapter-official"

mkdir -p "$B10" "$REPORTS"

fail(){ echo "[P3-B10-P2][ERROR] $1" >&2; exit 1; }

echo "[1/8] Checking Part 1 gate..."
[ -f "$B10/status_part1_release_freeze.json" ] || fail "Part 1 release freeze status missing."
[ -d "$ROOT/debug_adapter" ] || fail "production debug_adapter missing."

echo "[2/8] Creating version stamp..."
cat > "$VERSION_FILE" <<EOF
{
  "ok": true,
  "product": "PantherLang",
  "component": "Debug Adapter",
  "release_line": "P-3",
  "batch": "10",
  "part": "2",
  "version": "$VERSION",
  "status": "OFFICIAL_VERSION_STAMPED",
  "created_at_local": "$STAMP",
  "runtime_modified": false,
  "next": "P-3 Batch 10 Part 3 - Final Release Manifest"
}
EOF

echo "[3/8] Mirroring version metadata into release docs..."
cat > "$REPORTS/OFFICIAL_DEBUG_ADAPTER_VERSION.md" <<EOF
# PantherLang Official Debug Adapter Version

Version:

\`$VERSION\`

Status:

OFFICIAL_VERSION_STAMPED

Scope:

Production \`debug_adapter/\`

Next:

P-3 Batch 10 Part 3 - Final Release Manifest
EOF

echo "[4/8] Validating JSON..."
python3 -m json.tool "$VERSION_FILE" >/dev/null

echo "[5/8] Static compile production adapter..."
python3 -m py_compile $(find "$ROOT/debug_adapter" -name "*.py")

echo "[6/8] Running canonical regression..."
python3 -m pytest "$ROOT/tests/P2_canonical_debug_adapter" -q

echo "[7/8] Writing engineering report..."
cat > "$REPORTS/P3_BATCH10_PART2_VERSION_STAMPING.md" <<EOF
# P-3 Batch 10 Part 2 - Version Stamping

## Status

PASSED

## Version

\`$VERSION\`

## Verified

- Part 1 release freeze status exists
- Version JSON generated
- Version markdown generated
- Version JSON validates
- Production debug_adapter compiles
- Canonical regression passes

## Runtime Modification

No runtime source files were modified.

## Next

P-3 Batch 10 Part 3 - Final Release Manifest.
EOF

echo "[8/8] Writing status..."
cat > "$B10/status_part2_version_stamping.json" <<EOF
{
  "ok": true,
  "phase": "P-3",
  "batch": "10",
  "part": "2",
  "status": "PASSED",
  "name": "Version Stamping",
  "version": "$VERSION",
  "runtime_modified": false,
  "version_file": ".panther/p3_batch10_official_release/OFFICIAL_DEBUG_ADAPTER_VERSION.json",
  "next": "P-3 Batch 10 Part 3 - Final Release Manifest"
}
EOF

echo "============================================================"
echo "✅ P-3 Batch 10 Part 2 COMPLETE"
echo "Version: $VERSION"
echo "Next: P-3 Batch 10 Part 3 - Final Release Manifest"
echo "============================================================"
