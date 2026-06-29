#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " Panther Recovery Engine"
echo " P-1 Batch 4 - Controlled Reconstruction"
echo "============================================================"

ROOT="$(pwd)"
RECOVERY="$ROOT/.panther/recovery"
REPORTS="$ROOT/reports/recovery"
STAMP="$(date +%Y%m%d_%H%M%S)"
SAFETY="$ROOT/.panther/backups/P1_Batch4_controlled_reconstruction_${STAMP}"

fail(){ echo "[P-1-B4][ERROR] $1" >&2; exit 1; }

[ -f "$RECOVERY/reconstruction_plan.json" ] || fail "Missing reconstruction plan. Run P-1 Batch 3 first."
[ -d "$ROOT/debug_adapter" ] || fail "debug_adapter missing."

mkdir -p "$REPORTS" "$SAFETY"

echo "[1/6] Creating safety backup..."
cp -a "$ROOT/debug_adapter" "$SAFETY/debug_adapter_before_controlled_reconstruction"

echo "[2/6] Executing reconstruction plan..."
python3 <<'PY'
from pathlib import Path
import json, shutil, subprocess, sys
from datetime import datetime, timezone

root = Path.cwd()
recovery = root / ".panther" / "recovery"
reports = root / "reports" / "recovery"

plan = json.loads((recovery / "reconstruction_plan.json").read_text())
executed = []
errors = []

for action in plan["actions"]:
    file_name = action["file"]
    act = action["action"]
    source = action.get("source")
    dst = root / "debug_adapter" / file_name

    if act == "keep_live":
        if dst.exists():
            executed.append({"file": file_name, "action": "kept_live"})
        else:
            errors.append(f"live file missing: {file_name}")
        continue

    if act == "copy_from_candidate":
        if not source:
            errors.append(f"missing source for {file_name}")
            continue
        src = root / source / file_name if source.endswith("debug_adapter") else root / source / "debug_adapter" / file_name
        if not src.exists() and action.get("selected", {}).get("path"):
            src = root / action["selected"]["path"]
        if not src.exists():
            errors.append(f"source missing for {file_name}: {source}")
            continue
        shutil.copy2(src, dst)
        executed.append({"file": file_name, "action": "copied", "source": str(src.relative_to(root))})
        continue

    if act == "manual_review":
        errors.append(f"manual review required: {file_name}")
        continue

    errors.append(f"unknown action {act} for {file_name}")

for d in root.rglob("__pycache__"):
    shutil.rmtree(d, ignore_errors=True)
for d in root.rglob(".pytest_cache"):
    shutil.rmtree(d, ignore_errors=True)

compile_proc = subprocess.run(
    [sys.executable, "-m", "py_compile"] + [str(p) for p in sorted((root / "debug_adapter").rglob("*.py"))],
    cwd=root,
    text=True,
    capture_output=True,
)

if compile_proc.returncode != 0:
    errors.append("py_compile failed")

test_files = []
tests_root = root / "tests"
if tests_root.exists():
    for p in sorted(tests_root.rglob("test*.py")):
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
    if pytest_proc.returncode != 0:
        errors.append("H4 regression failed")

ok = not errors

summary = {
    "ok": ok,
    "phase": "P-1",
    "batch": "4",
    "name": "Controlled Reconstruction",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": True,
    "executed": executed,
    "errors": errors,
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
    "next": "P-1 Batch 5 - Freeze Baseline" if ok else "Inspect controlled reconstruction report",
}

(recovery / "controlled_reconstruction_summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")

report = [
    "# Panther Recovery Engine - P-1 Batch 4",
    "",
    "## Status",
    "",
    "PASSED" if ok else "FAILED",
    "",
    "## Purpose",
    "",
    "Execute the reconstruction plan safely with a safety backup, then run compile and H4 regression.",
    "",
    "## Executed Actions",
    "",
    "```json",
    json.dumps(executed, indent=2),
    "```",
    "",
    "## Errors",
    "",
    "```json",
    json.dumps(errors, indent=2),
    "```",
    "",
    "## Compile Return Code",
    "",
    str(compile_proc.returncode),
    "",
    "## Pytest Return Code",
    "",
    str(pytest_proc.returncode if pytest_proc else "no-tests"),
    "",
    "## Next",
    "",
    "P-1 Batch 5 - Freeze Baseline" if ok else "Inspect controlled reconstruction summary.",
]
(reports / "P1_BATCH4_CONTROLLED_RECONSTRUCTION.md").write_text("\n".join(report), encoding="utf-8")

status = {
    "ok": ok,
    "phase": "P-1",
    "batch": "4",
    "status": "COMPLETE" if ok else "FAILED",
    "summary": ".panther/recovery/controlled_reconstruction_summary.json",
    "report": "reports/recovery/P1_BATCH4_CONTROLLED_RECONSTRUCTION.md",
    "next": "P-1 Batch 5 - Freeze Baseline" if ok else "Inspect controlled reconstruction summary",
}
(recovery / "status_batch4.json").write_text(json.dumps(status, indent=2, sort_keys=True), encoding="utf-8")

print("✅ executed actions:", len(executed))
print("✅ py_compile rc:", compile_proc.returncode)
if pytest_proc is not None:
    print("✅ pytest rc:", pytest_proc.returncode)
    print(pytest_proc.stdout[-6000:])
if errors:
    print("❌ errors:", errors)
    raise SystemExit(2)
PY

echo "[3/6] Verifying status..."
python3 <<'PY'
import json
from pathlib import Path
status = json.loads(Path(".panther/recovery/status_batch4.json").read_text())
summary = json.loads(Path(".panther/recovery/controlled_reconstruction_summary.json").read_text())
assert status["ok"] is True, summary.get("errors")
assert summary["ok"] is True, summary.get("errors")
print("✅ Batch 4 status assertion passed")
PY

echo "============================================================"
echo "✅ P-1 Batch 4 COMPLETE"
echo "Next: P-1 Batch 5 - Freeze Baseline"
echo "============================================================"
