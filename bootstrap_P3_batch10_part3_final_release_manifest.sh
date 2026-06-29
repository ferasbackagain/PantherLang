#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 10"
echo " Part 3 - Final Release Manifest"
echo "============================================================"

ROOT="$(pwd)"
B10="$ROOT/.panther/p3_batch10_official_release"
REPORTS="$ROOT/reports/P3/Batch10"
REL="$ROOT/releases/P3_OFFICIAL"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$B10" "$REPORTS" "$REL"

fail(){ echo "[P3-B10-P3][ERROR] $1" >&2; exit 1; }

echo "[1/9] Checking Part 2 gate..."
[ -f "$B10/status_part2_version_stamping.json" ] || fail "Part 2 version stamping status missing."
[ -f "$B10/OFFICIAL_DEBUG_ADAPTER_VERSION.json" ] || fail "Official version file missing."
[ -d "$ROOT/debug_adapter" ] || fail "production debug_adapter missing."

echo "[2/9] Reading official version..."
VERSION="$(python3 - <<'PY'
import json
from pathlib import Path
data=json.loads(Path(".panther/p3_batch10_official_release/OFFICIAL_DEBUG_ADAPTER_VERSION.json").read_text())
print(data["version"])
PY
)"
echo "Version: $VERSION"

echo "[3/9] Static compile production adapter..."
python3 -m py_compile $(find "$ROOT/debug_adapter" -name "*.py")

echo "[4/9] Running canonical regression..."
python3 -m pytest "$ROOT/tests/P2_canonical_debug_adapter" -q
if [ -d "$ROOT/tests/P3_atomic_replacement" ]; then
  python3 -m pytest "$ROOT/tests/P3_atomic_replacement" -q
fi

echo "[5/9] Creating final release manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
b10 = root / ".panther" / "p3_batch10_official_release"
version = "$VERSION"

def hash_tree(path: Path):
    rows = []
    for p in sorted(path.rglob("*")):
        if p.is_file():
            rows.append({
                "path": p.relative_to(root).as_posix(),
                "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
                "size": p.stat().st_size,
            })
    return rows

adapter = hash_tree(root / "debug_adapter")
reports = hash_tree(root / "reports" / "P3") if (root / "reports" / "P3").exists() else []

manifest = {
    "ok": True,
    "product": "PantherLang",
    "component": "Debug Adapter",
    "phase": "P-3",
    "batch": "10",
    "part": "3",
    "name": "Final Release Manifest",
    "version": version,
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": False,
    "production_debug_adapter_file_count": len(adapter),
    "production_debug_adapter_files": adapter,
    "p3_report_file_count": len(reports),
    "p3_reports": reports,
    "verified": [
        "version_stamp",
        "production_compile",
        "p2_canonical_regression",
        "p3_atomic_regression_if_present"
    ],
    "next": "P-3 Batch 10 Part 4 - Official Release Package"
}
(b10 / "FINAL_RELEASE_MANIFEST.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ production files:", len(adapter))
print("✅ report files:", len(reports))
PY

echo "[6/9] Creating human-readable manifest..."
cat > "$REPORTS/P3_BATCH10_PART3_FINAL_RELEASE_MANIFEST.md" <<EOF
# PantherLang P-3 Batch 10 Part 3 - Final Release Manifest

## Status

PASSED

## Version

\`$VERSION\`

## Scope

Production Debug Adapter:

\`debug_adapter/\`

## Manifest

\`.panther/p3_batch10_official_release/FINAL_RELEASE_MANIFEST.json\`

## Verified

- Official version stamp exists
- Production debug_adapter compiles
- P2 canonical regression passes
- P3 atomic replacement tests pass if present
- Final release manifest generated

## Runtime Modification

No runtime source files were modified.

## Next

P-3 Batch 10 Part 4 - Official Release Package.
EOF

echo "[7/9] Copying manifest into release staging..."
cp "$B10/FINAL_RELEASE_MANIFEST.json" "$REL/FINAL_RELEASE_MANIFEST_${VERSION}_${STAMP}.json"

echo "[8/9] Writing status..."
cat > "$B10/status_part3_final_release_manifest.json" <<EOF
{
  "ok": true,
  "phase": "P-3",
  "batch": "10",
  "part": "3",
  "status": "PASSED",
  "name": "Final Release Manifest",
  "version": "$VERSION",
  "runtime_modified": false,
  "manifest": ".panther/p3_batch10_official_release/FINAL_RELEASE_MANIFEST.json",
  "next": "P-3 Batch 10 Part 4 - Official Release Package"
}
EOF

echo "[9/9] Done."
echo "============================================================"
echo "✅ P-3 Batch 10 Part 3 COMPLETE"
echo "Next: P-3 Batch 10 Part 4 - Official Release Package"
echo "============================================================"
