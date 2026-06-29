#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 9"
echo " Part 1 - Production Certification Audit"
echo "============================================================"

ROOT="$(pwd)"
B8="$ROOT/.panther/p3_batch8_release_candidate"
B9="$ROOT/.panther/p3_batch9_production_certification"
REPORTS="$ROOT/reports/P3/Batch9"
CERT="$B9/certification_audit"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$B9" "$REPORTS" "$CERT"

fail(){ echo "[P3-B9-P1][ERROR] $1" >&2; exit 1; }

echo "[1/9] Certification pre-flight gates..."
[ -f "$B8/status_batch8_final.json" ] || fail "P-3 Batch 8 final status missing."
[ -f "$B8/BATCH8_RELEASE_GATE_PASSED.txt" ] || fail "Batch 8 release gate marker missing."
[ -d "$ROOT/debug_adapter" ] || fail "production debug_adapter missing."
[ -d "$ROOT/tests/P2_canonical_debug_adapter" ] || fail "P2 canonical tests missing."

echo "[2/9] Validating production adapter compile..."
python3 -m py_compile $(find "$ROOT/debug_adapter" -name "*.py")

echo "[3/9] Running production certification baseline tests..."
python3 -m pytest "$ROOT/tests/P2_canonical_debug_adapter" -q
if [ -d "$ROOT/tests/P3_atomic_replacement" ]; then
  python3 -m pytest "$ROOT/tests/P3_atomic_replacement" -q
fi

echo "[4/9] Locating release candidate..."
RC="$(python3 - <<'PY'
import json
from pathlib import Path
status = Path(".panther/p3_batch8_release_candidate/status_batch8_final.json")
data = json.loads(status.read_text())
rc = Path(data["release_candidate"])
print(rc)
PY
)"
[ -f "$RC" ] || fail "Release candidate archive missing: $RC"
echo "RC: $RC"

echo "[5/9] Auditing release metadata..."
[ -f "${RC}.sha256" ] || fail "RC sha256 missing."
[ -f "${RC}.sha512" ] || fail "RC sha512 missing."
sha256sum -c "${RC}.sha256"
sha512sum -c "${RC}.sha512"
tar -tzf "$RC" >/dev/null

echo "[6/9] Creating certification audit manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
b9 = root / ".panther" / "p3_batch9_production_certification"
rc = Path("$RC")

adapter_files = []
for p in sorted((root / "debug_adapter").rglob("*")):
    if p.is_file():
        adapter_files.append({
            "path": p.relative_to(root).as_posix(),
            "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
            "size": p.stat().st_size,
        })

audit = {
    "ok": True,
    "phase": "P-3",
    "batch": "9",
    "part": "1",
    "name": "Production Certification Audit",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": False,
    "release_candidate": rc.as_posix(),
    "release_candidate_size": rc.stat().st_size,
    "release_candidate_sha256": hashlib.sha256(rc.read_bytes()).hexdigest(),
    "production_debug_adapter_file_count": len(adapter_files),
    "production_debug_adapter_files": adapter_files,
    "gates": {
        "batch8_final_status": True,
        "batch8_release_gate": True,
        "production_compile": True,
        "p2_canonical_regression": True,
        "p3_atomic_tests_if_present": True,
        "rc_sha256": True,
        "rc_sha512": True,
        "rc_tar_valid": True
    },
    "next": "P-3 Batch 9 Part 2 - Integrity Verification"
}
(b9 / "part1_production_certification_audit.json").write_text(json.dumps(audit, indent=2, sort_keys=True), encoding="utf-8")
print("✅ audited production files:", len(adapter_files))
PY

echo "[7/9] Creating certification checklist..."
cat > "$CERT/P3_BATCH9_CERTIFICATION_CHECKLIST.md" <<EOF
# P-3 Batch 9 Production Certification Checklist

## Part 1 Audit

Status: PASSED

Checked:
- Batch 8 final status
- Batch 8 release gate marker
- Production debug_adapter compile
- P2 canonical regression
- P3 atomic replacement tests if present
- RC SHA256
- RC SHA512
- RC tar structure

Release Candidate:
\`$RC\`

Next:
P-3 Batch 9 Part 2 - Integrity Verification
EOF

echo "[8/9] Writing engineering report..."
cat > "$REPORTS/P3_BATCH9_PART1_PRODUCTION_CERTIFICATION_AUDIT.md" <<EOF
# P-3 Batch 9 Part 1 - Production Certification Audit

## Status

PASSED

## Purpose

Start production certification by auditing release gates, production adapter integrity, and release candidate metadata.

## Runtime Modification

No runtime source files were modified.

## Release Candidate

\`$RC\`

## Manifest

\`.panther/p3_batch9_production_certification/part1_production_certification_audit.json\`

## Next

P-3 Batch 9 Part 2 - Integrity Verification.
EOF

echo "[9/9] Writing status..."
cat > "$B9/status_part1_certification_audit.json" <<EOF
{
  "ok": true,
  "phase": "P-3",
  "batch": "9",
  "part": "1",
  "status": "PASSED",
  "name": "Production Certification Audit",
  "runtime_modified": false,
  "release_candidate": "$RC",
  "next": "P-3 Batch 9 Part 2 - Integrity Verification"
}
EOF

echo "============================================================"
echo "✅ P-3 Batch 9 Part 1 COMPLETE"
echo "Next: P-3 Batch 9 Part 2 - Integrity Verification"
echo "============================================================"
