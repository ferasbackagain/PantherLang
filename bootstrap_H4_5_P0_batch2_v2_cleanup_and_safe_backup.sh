#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"

echo "============================================================"
echo " PantherLang H4.5 P0 Batch 2 v2"
echo " Cleanup Recursive Backup + Safe Backup Normalization"
echo "============================================================"
echo "[P0-B2-v2] Root: $ROOT"

fail(){ echo "[P0-B2-v2][ERROR] $1" >&2; exit 1; }

if [ ! -f "panther" ] && [ ! -f "Panther" ] && ! command -v Panther >/dev/null 2>&1; then
  fail "Panther CLI not found. Run from live PantherLang project root or install global Panther command."
fi
[ -f ".panther/h4_5_p0/live_workspace_manifest.json" ] || fail "Batch 1 manifest missing. Run Batch 1 first."

mkdir -p .panther/h4_5_p0
mkdir -p .panther/status
mkdir -p reports/H4_5/P0
mkdir -p .panther/safety_backups

echo "[P0-B2-v2] Disk usage before cleanup:"
df -h . || true

echo "[P0-B2-v2] Removing failed recursive Batch 2 safety backups..."
if [ -d ".panther/safety_backups" ]; then
  find .panther/safety_backups -maxdepth 1 -type d -name 'H4_5_P0_Batch2_*' -print -exec rm -rf {} + || true
fi

echo "[P0-B2-v2] Removing empty directories left by failed recursive backup..."
find .panther -type d -empty -delete 2>/dev/null || true

echo "[P0-B2-v2] Disk usage after cleanup:"
df -h . || true

echo "[P0-B2-v2] Creating non-recursive safety backup archive..."

python3 <<'PY'
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import tarfile
from datetime import datetime, timezone
from pathlib import Path

root = Path.cwd().resolve()
stamp = datetime.now().strftime("%Y%m%d_%H%M%S")

p0_dir = root / ".panther" / "h4_5_p0"
status_dir = root / ".panther" / "status"
report_dir = root / "reports" / "H4_5" / "P0"
backup_dir = root / ".panther" / "safety_backups"
p0_dir.mkdir(parents=True, exist_ok=True)
status_dir.mkdir(parents=True, exist_ok=True)
report_dir.mkdir(parents=True, exist_ok=True)
backup_dir.mkdir(parents=True, exist_ok=True)

archive_name = f"H4_5_P0_Batch2_v2_safe_backup_{stamp}.tar.gz"
archive_path = backup_dir / archive_name

EXCLUDE_PREFIXES = (
    ".git/",
    ".pytest_cache/",
    ".phase_backups/",
    ".panther_backups/",
    ".panther/backups/",
    ".panther/safety_backups/",
)
EXCLUDE_NAMES = {"__pycache__", ".pytest_cache", "node_modules", ".venv", "venv"}

def rel(path: Path) -> str:
    return path.relative_to(root).as_posix()

def should_exclude(path: Path) -> bool:
    r = rel(path)
    if r == ".git" or r == ".phase_backups" or r == ".panther_backups":
        return True
    if r == ".panther/backups" or r == ".panther/safety_backups":
        return True
    if any(r.startswith(p) for p in EXCLUDE_PREFIXES):
        return True
    if any(part in EXCLUDE_NAMES for part in path.parts):
        return True
    return False

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

included = []
skipped = []

with tarfile.open(archive_path, "w:gz") as tar:
    for path in sorted(root.rglob("*")):
        if path == archive_path:
            continue
        if should_exclude(path):
            skipped.append(rel(path))
            continue
        if path.is_file():
            r = rel(path)
            tar.add(path, arcname=r)
            included.append({
                "path": r,
                "size": path.stat().st_size,
                "sha256": sha256(path),
            })

archive_sha = sha256(archive_path)

legacy_locations = []
for candidate in [".panther/backups", ".phase_backups", ".panther_backups", ".panther/safety_backups"]:
    p = root / candidate
    legacy_locations.append({
        "path": candidate,
        "exists": p.exists(),
        "entries": sum(1 for _ in p.rglob("*")) if p.exists() and p.is_dir() else 0,
    })

backup_index = {
    "ok": True,
    "phase": "H4.5",
    "milestone": "P0",
    "batch": "Batch 2 v2",
    "name": "Cleanup Recursive Backup + Safe Backup Normalization",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "archive": archive_path.relative_to(root).as_posix(),
    "archive_sha256": archive_sha,
    "included_file_count": len(included),
    "skipped_count": len(skipped),
    "exclusions": sorted(EXCLUDE_PREFIXES),
    "legacy_locations": legacy_locations,
    "safety_property": "Archive excludes .panther/safety_backups to prevent recursive backup growth.",
}

backup_manifest = {
    "ok": True,
    "phase": "H4.5",
    "milestone": "P0",
    "batch": "Batch 2 v2",
    "archive": archive_path.relative_to(root).as_posix(),
    "archive_sha256": archive_sha,
    "files": included,
}

rollback = {
    "ok": True,
    "phase": "H4.5",
    "batch": "Batch 2 v2",
    "restore_command": f"tar -xzf {archive_path.relative_to(root).as_posix()} -C {root.as_posix()}",
    "note": "This backup archive intentionally excludes backup/cache directories to avoid recursive restore noise.",
}

(p0_dir / "backup_index.json").write_text(json.dumps(backup_index, indent=2, sort_keys=True), encoding="utf-8")
(p0_dir / "backup_manifest.json").write_text(json.dumps(backup_manifest, indent=2, sort_keys=True), encoding="utf-8")
(p0_dir / "rollback_metadata.json").write_text(json.dumps(rollback, indent=2, sort_keys=True), encoding="utf-8")

report = f"""# H4.5 P0 Batch 2 v2 Engineering Report

## Status

PASSED

## Purpose

Fix Batch 2 recursive backup architecture and normalize backups safely before H4.5 real debugger work.

## Problem Fixed

The previous Batch 2 copied `.panther` into `.panther/safety_backups`, which caused recursive backup nesting and filled disk space.

## Remediation

- Removed failed `H4_5_P0_Batch2_*` recursive safety backups.
- Created a compressed safety backup archive instead of recursive directory copy.
- Excluded all backup/cache locations:
  - `.panther/safety_backups`
  - `.panther/backups`
  - `.phase_backups`
  - `.panther_backups`
  - `__pycache__`
  - `.pytest_cache`
- Generated backup index.
- Generated backup manifest.
- Generated rollback metadata.

## Archive

`{archive_path.relative_to(root).as_posix()}`

## Archive SHA256

`{archive_sha}`

## Included Files

{len(included)}

## Next

H4.5 P0 Batch 3 — Dry Run + Static Validation.
"""

(report_dir / "H4_5_P0_Batch2_v2_ENGINEERING_REPORT.md").write_text(report, encoding="utf-8")

status = {
    "ok": True,
    "phase": "H4.5",
    "milestone": "P0",
    "batch": "Batch 2 v2",
    "name": "Cleanup Recursive Backup + Safe Backup Normalization",
    "backup_index": ".panther/h4_5_p0/backup_index.json",
    "backup_manifest": ".panther/h4_5_p0/backup_manifest.json",
    "rollback_metadata": ".panther/h4_5_p0/rollback_metadata.json",
    "engineering_report": "reports/H4_5/P0/H4_5_P0_Batch2_v2_ENGINEERING_REPORT.md",
    "next": "H4.5 P0 Batch 3 — Dry Run + Static Validation",
}

(status_dir / "H4_5_P0_Batch2_v2_status.json").write_text(json.dumps(status, indent=2, sort_keys=True), encoding="utf-8")

# Validation assertions
assert archive_path.exists(), "Backup archive was not created"
assert archive_path.stat().st_size > 0, "Backup archive is empty"
assert (p0_dir / "backup_index.json").exists()
assert (p0_dir / "backup_manifest.json").exists()
assert (p0_dir / "rollback_metadata.json").exists()
assert backup_index["ok"] is True
assert backup_manifest["ok"] is True
assert not any(f["path"].startswith(".panther/safety_backups/") for f in included), "Recursive safety backup included"
assert not any(f["path"].startswith(".panther/backups/") for f in included), "Legacy backup included"

print("✅ failed recursive Batch 2 backups cleaned")
print("✅ non-recursive safety backup archive created")
print("✅ backup index generated")
print("✅ backup manifest generated")
print("✅ rollback metadata generated")
print("✅ engineering report generated")
print("✅ status JSON generated")
PY

echo "[P0-B2-v2] Static validation..."
test -f .panther/h4_5_p0/backup_index.json
test -f .panther/h4_5_p0/backup_manifest.json
test -f .panther/h4_5_p0/rollback_metadata.json
test -f reports/H4_5/P0/H4_5_P0_Batch2_v2_ENGINEERING_REPORT.md
test -f .panther/status/H4_5_P0_Batch2_v2_status.json

python3 <<'PY'
import json
from pathlib import Path

idx = json.loads(Path(".panther/h4_5_p0/backup_index.json").read_text())
manifest = json.loads(Path(".panther/h4_5_p0/backup_manifest.json").read_text())
status = json.loads(Path(".panther/status/H4_5_P0_Batch2_v2_status.json").read_text())

assert idx["ok"] is True
assert manifest["ok"] is True
assert status["ok"] is True
assert "safety_backups" in idx["safety_property"]
assert manifest["included_file_count"] if "included_file_count" in manifest else len(manifest["files"]) > 0
for f in manifest["files"]:
    assert not f["path"].startswith(".panther/safety_backups/")
    assert not f["path"].startswith(".panther/backups/")
print("✅ JSON validation passed")
PY

echo "[P0-B2-v2] Archive validation..."
ARCHIVE="$(python3 - <<'PY'
import json
from pathlib import Path
idx=json.loads(Path(".panther/h4_5_p0/backup_index.json").read_text())
print(idx["archive"])
PY
)"

test -f "$ARCHIVE"
tar -tzf "$ARCHIVE" >/tmp/h45_p0_b2_v2_tarlist.txt
if grep -q '^.panther/safety_backups/' /tmp/h45_p0_b2_v2_tarlist.txt; then
  fail "Archive contains recursive .panther/safety_backups path"
fi
if grep -q '^.panther/backups/' /tmp/h45_p0_b2_v2_tarlist.txt; then
  fail "Archive contains legacy .panther/backups path"
fi

echo "✅ archive excludes recursive backup paths"

echo "[P0-B2-v2] Disk usage final:"
df -h . || true

echo "============================================================"
echo "✅ H4.5 P0 Batch 2 v2 COMPLETE"
echo "Next: H4.5 P0 Batch 3 - Dry Run + Static Validation"
echo "============================================================"
