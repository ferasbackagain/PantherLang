#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 8"
echo " Part 5 - Final Integration"
echo "============================================================"

ROOT="$(pwd)"
B8="$ROOT/.panther/p3_batch8_release_candidate"
REPORTS="$ROOT/reports/P3/Batch8"
REL="$ROOT/releases/P3_RC"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$REPORTS"

fail(){ echo "[P3-B8-P5][ERROR] $1" >&2; exit 1; }

echo "[1/10] Checking Batch 8 gates..."
[ -f "$B8/status_part1_release_freeze.json" ] || fail "Part 1 missing"
[ -f "$B8/status_part2_artifact_assembly.json" ] || fail "Part 2 missing"
[ -f "$B8/status_part3_regression_gate.json" ] || fail "Part 3 missing"
[ -f "$B8/status_part4_packaging.json" ] || fail "Part 4 missing"

echo "[2/10] Validating production adapter..."
[ -d "$ROOT/debug_adapter" ] || fail "debug_adapter missing"
python3 -m py_compile $(find "$ROOT/debug_adapter" -name "*.py")

echo "[3/10] Running P2 canonical regression..."
python3 -m pytest "$ROOT/tests/P2_canonical_debug_adapter" -q

echo "[4/10] Running P3 atomic replacement tests if present..."
if [ -d "$ROOT/tests/P3_atomic_replacement" ]; then
  python3 -m pytest "$ROOT/tests/P3_atomic_replacement" -q
fi

echo "[5/10] Validating release archive metadata..."
RC="$(ls -t "$REL"/PantherLang_RC_*.tar.gz | head -1)"
[ -f "$RC" ] || fail "RC archive missing"
[ -f "${RC}.sha256" ] || fail "SHA256 missing"
[ -f "${RC}.sha512" ] || fail "SHA512 missing"

sha256sum -c "${RC}.sha256"
sha512sum -c "${RC}.sha512"
tar -tzf "$RC" >/dev/null

echo "[6/10] Creating final Batch 8 manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
b8 = root / ".panther" / "p3_batch8_release_candidate"
rc = Path("$RC")

statuses = {}
for p in sorted(b8.glob("status_part*.json")):
    statuses[p.name] = json.loads(p.read_text())

files = []
for p in sorted((root / "debug_adapter").rglob("*")):
    if p.is_file():
        files.append({
            "path": p.relative_to(root).as_posix(),
            "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
            "size": p.stat().st_size
        })

manifest = {
    "ok": True,
    "phase": "P-3",
    "batch": "8",
    "part": "5",
    "name": "Final Integration",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": False,
    "release_candidate": rc.as_posix(),
    "release_candidate_size": rc.stat().st_size,
    "release_candidate_sha256": hashlib.sha256(rc.read_bytes()).hexdigest(),
    "statuses": statuses,
    "production_debug_adapter_file_count": len(files),
    "production_debug_adapter_files": files,
    "next": "P-3 Batch 9 - Production Certification"
}
(b8 / "batch8_final_integration_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ production files:", len(files))
print("✅ rc:", rc)
PY

echo "[7/10] Creating Batch 8 final report..."
cat > "$REPORTS/P3_BATCH8_FINAL_INTEGRATION.md" <<EOF
# P-3 Batch 8 - Final Integration

## Status

PASSED

## Completed Parts

- Part 1: Release Freeze
- Part 2: Release Candidate Artifact Assembly
- Part 3: Release Candidate Regression Gate
- Part 4: Packaging + Release Metadata
- Part 5: Final Integration

## Verified

- Production debug adapter compiles
- P2 canonical regression passes
- P3 atomic replacement tests pass if present
- Release archive SHA256 verified
- Release archive SHA512 verified
- Release archive tar structure verified
- Final integration manifest generated

## Release Candidate

\`$RC\`

## Runtime Modification

No runtime source files were modified during Part 5.

## Next

P-3 Batch 9 - Production Certification.
EOF

echo "[8/10] Writing final Batch 8 status..."
cat > "$B8/status_batch8_final.json" <<EOF
{
  "ok": true,
  "phase": "P-3",
  "batch": "8",
  "status": "COMPLETE",
  "name": "Final Integration",
  "runtime_modified": false,
  "release_candidate": "$RC",
  "manifest": ".panther/p3_batch8_release_candidate/batch8_final_integration_manifest.json",
  "next": "P-3 Batch 9 - Production Certification"
}
EOF

echo "[9/10] Writing release gate marker..."
cat > "$B8/BATCH8_RELEASE_GATE_PASSED.txt" <<EOF
P-3 Batch 8 Release Candidate Gate: PASSED
Timestamp: $STAMP
Release Candidate: $RC
Next: P-3 Batch 9 - Production Certification
EOF

echo "[10/10] Final summary..."
echo "Release Candidate: $RC"
ls -lh "$RC"

echo "============================================================"
echo "✅ P-3 Batch 8 COMPLETE"
echo "✅ Release Candidate Final Integration PASSED"
echo "Next: P-3 Batch 9 - Production Certification"
echo "============================================================"
