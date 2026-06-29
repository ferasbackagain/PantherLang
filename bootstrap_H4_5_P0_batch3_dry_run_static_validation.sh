#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"

echo "============================================================"
echo " PantherLang H4.5 P0 Batch 3"
echo " Dry Run + Static Validation"
echo "============================================================"
echo "[P0-B3] Root: $ROOT"

fail(){ echo "[P0-B3][ERROR] $1" >&2; exit 1; }

[ -f ".panther/status/H4_5_P0_Batch1_status.json" ] || fail "Batch 1 status missing."
[ -f ".panther/status/H4_5_P0_Batch2_v2_status.json" ] || fail "Batch 2 v2 status missing."
[ -f ".panther/h4_5_p0/live_workspace_manifest.json" ] || fail "Live workspace manifest missing."
[ -f ".panther/h4_5_p0/backup_index.json" ] || fail "Backup index missing."
[ -f ".panther/h4_5_p0/backup_manifest.json" ] || fail "Backup manifest missing."
[ -f ".panther/h4_5_p0/rollback_metadata.json" ] || fail "Rollback metadata missing."

mkdir -p .panther/h4_5_p0 .panther/status reports/H4_5/P0

python3 <<'PY'
from __future__ import annotations

import ast
import json
from datetime import datetime, timezone
from pathlib import Path

root = Path.cwd().resolve()
p0 = root / ".panther" / "h4_5_p0"
status_dir = root / ".panther" / "status"
report_dir = root / "reports" / "H4_5" / "P0"

ignore_prefixes = [
    ".git/",
    ".panther/backups/",
    ".panther/safety_backups/",
    ".phase_backups/",
    ".panther_backups/",
    ".pytest_cache/",
]
ignore_names = {"__pycache__", "node_modules", ".venv", "venv"}

errors = []
warnings = []

required_json = [
    ".panther/status/H4_5_P0_Batch1_status.json",
    ".panther/status/H4_5_P0_Batch2_v2_status.json",
    ".panther/h4_5_p0/live_workspace_manifest.json",
    ".panther/h4_5_p0/sha256_manifest.json",
    ".panther/h4_5_p0/backup_index.json",
    ".panther/h4_5_p0/backup_manifest.json",
    ".panther/h4_5_p0/rollback_metadata.json",
]

def load(path: str) -> dict:
    return json.loads((root / path).read_text(encoding="utf-8"))

def rel(path: Path) -> str:
    return path.relative_to(root).as_posix()

def ignored(path: Path) -> bool:
    r = rel(path)
    if any(r.startswith(x) for x in ignore_prefixes):
        return True
    if any(part in ignore_names for part in path.parts):
        return True
    return False

for item in required_json:
    if not (root / item).exists():
        errors.append(f"missing:{item}")
        continue
    try:
        data = load(item)
        if data.get("ok") is not True:
            errors.append(f"not-ok:{item}")
    except Exception as exc:
        errors.append(f"json-error:{item}:{exc}")

for p in ["debug_adapter", ".panther", "reports", "scripts"]:
    if not (root / p).exists():
        errors.append(f"missing-critical:{p}")

if not ((root / "vscode-extension").exists() or (root / "vscode_extension").exists()):
    errors.append("missing-critical:vscode-extension-or-vscode_extension")

backup_manifest = load(".panther/h4_5_p0/backup_manifest.json")
for f in backup_manifest.get("files", []):
    path = f.get("path", "")
    if path.startswith(".panther/safety_backups/") or path.startswith(".panther/backups/"):
        errors.append(f"recursive-backup-path-in-manifest:{path}")

py_checked = []
py_failed = []
if (root / "debug_adapter").exists():
    for py in sorted((root / "debug_adapter").rglob("*.py")):
        if ignored(py):
            continue
        try:
            ast.parse(py.read_text(encoding="utf-8"))
            py_checked.append(rel(py))
        except Exception as exc:
            py_failed.append({"path": rel(py), "error": str(exc)})

if py_failed:
    errors.append(f"python-syntax-failures:{py_failed}")

shell_checked = []
for pattern in ["bootstrap_H4_5_P0_*.sh", "bootstrap_H4_5_*.sh"]:
    for sh in sorted(root.glob(pattern)):
        if sh.is_file():
            txt = sh.read_text(encoding="utf-8", errors="ignore")
            dangerous_lines = []
            for lineno, line in enumerate(txt.splitlines(), start=1):
                stripped = line.strip()
                if stripped.startswith("rm -rf /") or stripped.startswith("sudo rm -rf /"):
                    dangerous_lines.append(lineno)
            if dangerous_lines:
                errors.append(f"dangerous-rm:{rel(sh)}:lines={dangerous_lines}")
            shell_checked.append(rel(sh))

dry_run = {
    "ok": True,
    "phase": "H4.5",
    "milestone": "P0",
    "batch": "Batch 3",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "will_modify_live_source": False,
    "will_delete_files": False,
    "planned_actions": [
        "validate P0 manifests",
        "validate backup recursion guard",
        "validate debug_adapter Python syntax",
        "validate H4.5 shell scripts for dangerous rm pattern",
    ],
}

validation = {
    "ok": not errors,
    "phase": "H4.5",
    "milestone": "P0",
    "batch": "Batch 3",
    "errors": errors,
    "warnings": warnings,
    "python_checked_count": len(py_checked),
    "python_checked": py_checked,
    "shell_checked_count": len(shell_checked),
    "shell_checked": shell_checked,
    "ignored_prefixes": ignore_prefixes,
    "backup_recursion_guard": True,
}

(p0 / "dry_run_plan.json").write_text(json.dumps(dry_run, indent=2, sort_keys=True), encoding="utf-8")
(p0 / "static_validation.json").write_text(json.dumps(validation, indent=2, sort_keys=True), encoding="utf-8")

report = f"""# H4.5 P0 Batch 3 Engineering Report

## Status

{'PASSED' if not errors else 'FAILED'}

## Purpose

Dry Run + Static Validation before any H4.5 debugger implementation.

## Validated

- P0 Batch 1 status
- P0 Batch 2 v2 status
- Live workspace manifest
- Backup index and manifest
- Rollback metadata
- Backup recursion guard
- Debug adapter Python syntax
- H4.5 shell script dangerous-rm scan

## Results

- Python files checked: {len(py_checked)}
- Shell files checked: {len(shell_checked)}
- Errors: {len(errors)}
- Warnings: {len(warnings)}

## Errors

```json
{json.dumps(errors, indent=2)}
```

## Next

H4.5 P0 Batch 4 — Runtime Validation + Regression.
"""
(report_dir / "H4_5_P0_Batch3_ENGINEERING_REPORT.md").write_text(report, encoding="utf-8")

status = {
    "ok": not errors,
    "phase": "H4.5",
    "milestone": "P0",
    "batch": "Batch 3",
    "dry_run_plan": ".panther/h4_5_p0/dry_run_plan.json",
    "static_validation": ".panther/h4_5_p0/static_validation.json",
    "engineering_report": "reports/H4_5/P0/H4_5_P0_Batch3_ENGINEERING_REPORT.md",
    "next": "H4.5 P0 Batch 4 — Runtime Validation + Regression",
}
(status_dir / "H4_5_P0_Batch3_status.json").write_text(json.dumps(status, indent=2, sort_keys=True), encoding="utf-8")

print("✅ dry-run plan generated")
print("✅ static validation generated")
print(f"✅ Python files checked: {len(py_checked)}")
print(f"✅ Shell files checked: {len(shell_checked)}")
print("✅ engineering report generated")
print("✅ status JSON generated")

if errors:
    print(json.dumps(errors, indent=2))
    raise SystemExit(2)
PY

test -f .panther/h4_5_p0/dry_run_plan.json
test -f .panther/h4_5_p0/static_validation.json
test -f reports/H4_5/P0/H4_5_P0_Batch3_ENGINEERING_REPORT.md
test -f .panther/status/H4_5_P0_Batch3_status.json

python3 <<'PY'
import json
from pathlib import Path
status=json.loads(Path(".panther/status/H4_5_P0_Batch3_status.json").read_text())
dry=json.loads(Path(".panther/h4_5_p0/dry_run_plan.json").read_text())
static=json.loads(Path(".panther/h4_5_p0/static_validation.json").read_text())
assert status["ok"] is True
assert dry["ok"] is True
assert dry["will_modify_live_source"] is False
assert dry["will_delete_files"] is False
assert static["ok"] is True
assert static["backup_recursion_guard"] is True
print("✅ Batch 3 JSON assertions passed")
PY

echo "============================================================"
echo "✅ H4.5 P0 Batch 3 COMPLETE"
echo "Next: H4.5 P0 Batch 4 - Runtime Validation + Regression"
echo "============================================================"
