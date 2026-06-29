#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang H4.5 P0 Batch 4 v3"
echo " Selective Runtime Restore + Read-Only Regression"
echo "============================================================"

ROOT="$(pwd)"
P0_DIR="$ROOT/.panther/h4_5_p0"
STATUS_DIR="$ROOT/.panther/status"
REPORT_DIR="$ROOT/reports/H4_5/P0"
STAMP="$(date +%Y%m%d_%H%M%S)"
SAFETY_DIR="$ROOT/.panther/backups/H4_5_P0_Batch4_v3_${STAMP}"

fail(){ echo "[P0-B4-v3][ERROR] $1" >&2; exit 1; }

[ -d "$ROOT/debug_adapter" ] || fail "debug_adapter missing"
[ -d "$ROOT/.panther/backups" ] || fail ".panther/backups missing"

mkdir -p "$P0_DIR" "$STATUS_DIR" "$REPORT_DIR" "$SAFETY_DIR"

echo "[1/8] Creating safety backup before selective restore..."
cp -a "$ROOT/debug_adapter" "$SAFETY_DIR/debug_adapter_before_v3"

echo "[2/8] Locating Batch4 v2 safety backup that contains H4.3/H4.4 files..."
python3 <<'PY'
from pathlib import Path
import json, shutil, subprocess, sys
from datetime import datetime, timezone

root = Path.cwd().resolve()
p0 = root / ".panther" / "h4_5_p0"
status_dir = root / ".panther" / "status"
report_dir = root / "reports" / "H4_5" / "P0"

current = root / "debug_adapter"

# Find the newest safety backup created by failed Batch4 v2. This backup was created BEFORE v2 overwrote debug_adapter.
candidates = sorted(
    (root / ".panther" / "backups").glob("H4_5_P0_Batch4_v2_*/debug_adapter"),
    key=lambda p: p.stat().st_mtime if p.exists() else 0,
    reverse=True
)

if not candidates:
    raise SystemExit("No H4_5_P0_Batch4_v2_* debug_adapter safety backup found")

source = candidates[0]

required_h43_modules = [
    "variables_core.py",
    "variable_references.py",
    "variable_store.py",
    "stack_frames.py",
    "threads.py",
    "scopes.py",
    "evaluate.py",
    "execution_dispatcher.py",
]

copied = []
already_present = []
missing_from_source = []

# Recover only missing modules from the pre-v2 safety backup.
# Do NOT overwrite existing H4.2 files restored by v2.
for name in required_h43_modules:
    src = source / name
    dst = current / name
    if dst.exists():
        already_present.append(name)
        continue
    if src.exists():
        shutil.copy2(src, dst)
        copied.append(name)
    else:
        missing_from_source.append(name)

# Recover any other files that exist in source but are missing now, without overwriting existing files.
extra_copied = []
for src in source.glob("*.py"):
    dst = current / src.name
    if not dst.exists():
        shutil.copy2(src, dst)
        extra_copied.append(src.name)

# Remove transient caches
for d in root.rglob("__pycache__"):
    shutil.rmtree(d, ignore_errors=True)
for d in root.rglob(".pytest_cache"):
    shutil.rmtree(d, ignore_errors=True)

# Compile all debug_adapter files
compile_cmd = [sys.executable, "-m", "py_compile"] + [str(p) for p in sorted(current.rglob("*.py"))]
compile_proc = subprocess.run(compile_cmd, cwd=root, text=True, capture_output=True)

# Run focused H4 regression only after recovery
test_files = []
tests_dir = root / "tests"
if tests_dir.exists():
    for p in sorted(tests_dir.rglob("test*.py")):
        s = p.as_posix().lower()
        if "h4" in s or "debug" in s or "dap" in s:
            test_files.append(str(p))

pytest_proc = None
if test_files:
    pytest_proc = subprocess.run(
        [sys.executable, "-m", "pytest", *test_files, "-q"],
        cwd=root,
        text=True,
        capture_output=True,
    )

errors = []
if compile_proc.returncode != 0:
    errors.append("py_compile failed")
if pytest_proc is not None and pytest_proc.returncode != 0:
    errors.append("H4 regression failed")
if missing_from_source:
    errors.append(f"missing required H4.3 modules from source backup: {missing_from_source}")

status_ok = not errors

summary = {
    "ok": status_ok,
    "phase": "H4.5",
    "milestone": "P0",
    "batch": "Batch 4 v3",
    "name": "Selective Runtime Restore + Read-Only Regression",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "source_backup": str(source.relative_to(root)),
    "copied_required_modules": copied,
    "already_present_required_modules": already_present,
    "missing_from_source": missing_from_source,
    "extra_copied_missing_files": extra_copied,
    "compile": {
        "returncode": compile_proc.returncode,
        "stdout_tail": compile_proc.stdout[-4000:],
        "stderr_tail": compile_proc.stderr[-4000:],
    },
    "pytest": None if pytest_proc is None else {
        "returncode": pytest_proc.returncode,
        "stdout_tail": pytest_proc.stdout[-12000:],
        "stderr_tail": pytest_proc.stderr[-4000:],
        "test_file_count": len(test_files),
    },
    "errors": errors,
    "policy": {
        "selective_restore_only": True,
        "overwrite_existing_runtime_files": False,
        "restore_missing_h43_h44_modules": True,
        "no_monkey_patch_generation": True,
    }
}

(p0 / "runtime_validation_batch4_v3.json").write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")

report = f"""# H4.5 P0 Batch 4 v3 Engineering Report

## Status

{'PASSED' if status_ok else 'FAILED'}

## Mode

Selective Runtime Restore + Read-Only Regression.

## Why v3 exists

Batch 4 v2 restored the entire `debug_adapter` directory from an H4.2-era backup, which removed later H4.3/H4.4 modules. Batch 4 v3 fixes that by restoring only missing H4.3/H4.4 modules from the pre-v2 safety backup without overwriting existing runtime files.

## Source Backup

`{source.relative_to(root)}`

## Copied Required Modules

```json
{json.dumps(copied, indent=2)}
```

## Already Present Required Modules

```json
{json.dumps(already_present, indent=2)}
```

## Missing From Source

```json
{json.dumps(missing_from_source, indent=2)}
```

## Extra Missing Files Recovered

```json
{json.dumps(extra_copied, indent=2)}
```

## Compile Return Code

`{compile_proc.returncode}`

## Pytest Return Code

`{pytest_proc.returncode if pytest_proc else 'no-tests'}`

## Errors

```json
{json.dumps(errors, indent=2)}
```

## Next

If PASSED: H4.5 P0 Batch 5 - Final P0 Report + Status Gate.
If FAILED: inspect `.panther/h4_5_p0/runtime_validation_batch4_v3.json`.
"""
(report_dir / "H4_5_P0_Batch4_v3_ENGINEERING_REPORT.md").write_text(report, encoding="utf-8")

status = {
    "ok": status_ok,
    "phase": "H4.5",
    "milestone": "P0",
    "batch": "Batch 4 v3",
    "runtime_validation": ".panther/h4_5_p0/runtime_validation_batch4_v3.json",
    "engineering_report": "reports/H4_5/P0/H4_5_P0_Batch4_v3_ENGINEERING_REPORT.md",
    "next": "H4.5 P0 Batch 5 - Final P0 Report + Status Gate" if status_ok else "Inspect Batch 4 v3 regression output",
}
(status_dir / "H4_5_P0_Batch4_v3_status.json").write_text(json.dumps(status, indent=2, sort_keys=True), encoding="utf-8")

print("✅ source backup:", source.relative_to(root))
print("✅ copied required modules:", copied)
print("✅ extra missing files recovered:", extra_copied)
print("✅ py_compile rc:", compile_proc.returncode)
if pytest_proc is not None:
    print("✅ pytest rc:", pytest_proc.returncode)
    print(pytest_proc.stdout[-6000:])
    if pytest_proc.stderr:
        print(pytest_proc.stderr[-2000:])

if errors:
    print("❌ errors:", errors)
    raise SystemExit(2)
PY

echo "[3/8] Verifying output files..."
test -f "$P0_DIR/runtime_validation_batch4_v3.json"
test -f "$REPORT_DIR/H4_5_P0_Batch4_v3_ENGINEERING_REPORT.md"
test -f "$STATUS_DIR/H4_5_P0_Batch4_v3_status.json"

echo "[4/8] Status assertion..."
python3 <<'PY'
import json
from pathlib import Path
status = json.loads(Path(".panther/status/H4_5_P0_Batch4_v3_status.json").read_text())
summary = json.loads(Path(".panther/h4_5_p0/runtime_validation_batch4_v3.json").read_text())
assert status["ok"] is True, summary.get("errors")
assert summary["ok"] is True, summary.get("errors")
print("✅ Batch 4 v3 JSON assertions passed")
PY

echo "============================================================"
echo "✅ H4.5 P0 Batch 4 v3 COMPLETE"
echo "Next: H4.5 P0 Batch 5 - Final P0 Report + Status Gate"
echo "============================================================"
