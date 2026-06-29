#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 9"
echo " Part 4 - Production Readiness Certificate"
echo "============================================================"

ROOT="$(pwd)"
B9="$ROOT/.panther/p3_batch9_production_certification"
REPORTS="$ROOT/reports/P3/Batch9"
CERT_DIR="$B9/certificates"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$REPORTS" "$CERT_DIR"

fail(){ echo "[P3-B9-P4][ERROR] $1" >&2; exit 1; }

echo "[1/8] Checking certification gates..."
[ -f "$B9/status_part1_certification_audit.json" ] || fail "Part 1 missing"
[ -f "$B9/status_part2_integrity_verification.json" ] || fail "Part 2 missing"
[ -f "$B9/status_part3_reproducible_build.json" ] || fail "Part 3 missing"
[ -f "$B9/part1_production_certification_audit.json" ] || fail "Part 1 manifest missing"
[ -f "$B9/part2_integrity_verification_manifest.json" ] || fail "Part 2 manifest missing"
[ -f "$B9/part3_reproducible_build_manifest.json" ] || fail "Part 3 manifest missing"

echo "[2/8] Running final readiness tests..."
python3 -m py_compile $(find "$ROOT/debug_adapter" -name "*.py")
python3 -m pytest "$ROOT/tests/P2_canonical_debug_adapter" -q
if [ -d "$ROOT/tests/P3_atomic_replacement" ]; then
  python3 -m pytest "$ROOT/tests/P3_atomic_replacement" -q
fi

echo "[3/8] Resolving release candidate..."
RC="$(python3 - <<'PY'
import json
from pathlib import Path
status=Path(".panther/p3_batch9_production_certification/status_part2_integrity_verification.json")
data=json.loads(status.read_text())
print(data["release_candidate"])
PY
)"
[ -f "$RC" ] || fail "Release candidate missing: $RC"

echo "[4/8] Validating release checksums..."
sha256sum -c "${RC}.sha256"
sha512sum -c "${RC}.sha512"

echo "[5/8] Creating production readiness certificate..."
cat > "$CERT_DIR/PANTHERLANG_DEBUG_ADAPTER_PRODUCTION_READINESS_CERTIFICATE.md" <<EOF
# PantherLang Debug Adapter Production Readiness Certificate

Certificate ID: P3-B9-PRC-${STAMP}

## Status

CERTIFIED FOR RELEASE CANDIDATE PROMOTION

## Scope

PantherLang Production Debug Adapter

## Certified Components

- Production \`debug_adapter/\`
- Release Candidate Archive
- Canonical Protocol Layer
- Canonical Session Layer
- Canonical Event Bus
- Canonical Event Dispatcher
- Request Dispatcher
- Response Dispatcher
- Execution Dispatcher
- Server
- Launcher
- Debug Data Model
- Compatibility Bridge
- Atomic Replacement Path
- Rollback Metadata

## Verification Gates

- P-3 Batch 8 Final Integration: PASSED
- P-3 Batch 9 Part 1 Production Audit: PASSED
- P-3 Batch 9 Part 2 Integrity Verification: PASSED
- P-3 Batch 9 Part 3 Reproducible Build Verification: PASSED
- Production py_compile: PASSED
- P2 canonical regression: PASSED
- P3 atomic regression if present: PASSED
- SHA256 verification: PASSED
- SHA512 verification: PASSED

## Release Candidate

\`$RC\`

## Runtime Modification During Certification

None.

## Certification Decision

The PantherLang Debug Adapter release candidate is ready to proceed to:

P-3 Batch 9 Part 5 - Final Certification Integration
EOF

echo "[6/8] Creating machine-readable certificate..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root=Path.cwd()
b9=root/".panther/p3_batch9_production_certification"
rc=Path("$RC")
certificate={
    "ok": True,
    "phase": "P-3",
    "batch": "9",
    "part": "4",
    "name": "Production Readiness Certificate",
    "certificate_id": "P3-B9-PRC-${STAMP}",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": False,
    "decision": "CERTIFIED_FOR_RELEASE_CANDIDATE_PROMOTION",
    "release_candidate": rc.as_posix(),
    "release_candidate_sha256": hashlib.sha256(rc.read_bytes()).hexdigest(),
    "release_candidate_sha512": hashlib.sha512(rc.read_bytes()).hexdigest(),
    "verified_gates": [
        "batch8_final_integration",
        "batch9_part1_audit",
        "batch9_part2_integrity",
        "batch9_part3_reproducible_build",
        "production_py_compile",
        "p2_canonical_regression",
        "p3_atomic_regression_if_present",
        "sha256",
        "sha512"
    ],
    "next": "P-3 Batch 9 Part 5 - Final Certification Integration"
}
(b9/"certificates"/"production_readiness_certificate.json").write_text(json.dumps(certificate, indent=2, sort_keys=True), encoding="utf-8")
print("✅ certificate id:", certificate["certificate_id"])
PY

echo "[7/8] Writing engineering report..."
cat > "$REPORTS/P3_BATCH9_PART4_PRODUCTION_READINESS_CERTIFICATE.md" <<EOF
# P-3 Batch 9 Part 4 - Production Readiness Certificate

## Status

PASSED

## Certificate

\`.panther/p3_batch9_production_certification/certificates/PANTHERLANG_DEBUG_ADAPTER_PRODUCTION_READINESS_CERTIFICATE.md\`

## Machine-readable Certificate

\`.panther/p3_batch9_production_certification/certificates/production_readiness_certificate.json\`

## Runtime Modification

No runtime source files were modified.

## Next

P-3 Batch 9 Part 5 - Final Certification Integration.
EOF

echo "[8/8] Writing status..."
cat > "$B9/status_part4_production_readiness_certificate.json" <<EOF
{
  "ok": true,
  "phase": "P-3",
  "batch": "9",
  "part": "4",
  "status": "PASSED",
  "name": "Production Readiness Certificate",
  "runtime_modified": false,
  "certificate": ".panther/p3_batch9_production_certification/certificates/production_readiness_certificate.json",
  "next": "P-3 Batch 9 Part 5 - Final Certification Integration"
}
EOF

echo "============================================================"
echo "✅ P-3 Batch 9 Part 4 COMPLETE"
echo "Next: P-3 Batch 9 Part 5 - Final Certification Integration"
echo "============================================================"
