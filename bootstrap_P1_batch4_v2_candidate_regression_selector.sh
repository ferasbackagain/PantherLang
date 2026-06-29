#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " Panther Recovery Engine"
echo " P-1 Batch 4 v2 - Candidate Regression Selector"
echo "============================================================"

ROOT="$(pwd)"
RECOVERY="$ROOT/.panther/recovery"
REPORTS="$ROOT/reports/recovery"
STAMP="$(date +%Y%m%d_%H%M%S)"
ORIGINAL="$ROOT/.panther/backups/P1_Batch4_v2_original_debug_adapter_${STAMP}"
BEST_DIR="$ROOT/.panther/recovery/best_candidate_debug_adapter"

mkdir -p "$RECOVERY" "$REPORTS" "$ORIGINAL"

fail(){ echo "[P-1-B4-v2][ERROR] $1" >&2; exit 1; }

[ -d "$ROOT/debug_adapter" ] || fail "debug_adapter missing"

echo "[1/7] Saving current debug_adapter..."
cp -a "$ROOT/debug_adapter" "$ORIGINAL/debug_adapter"

echo "[2/7] Building candidate list..."
python3 <<'PY'
from pathlib import Path
import json

root = Path.cwd()
recovery = root / ".panther" / "recovery"

required = {
    "protocol.py",
    "session.py",
    "event_bus.py",
    "event_dispatcher.py",
    "dispatcher.py",
    "server.py",
    "variables_core.py",
    "variable_references.py",
    "variable_store.py",
    "stack_frames.py",
    "threads.py",
    "scopes.py",
    "evaluate.py",
    "execution_dispatcher.py",
}

candidates = []
seen = set()

for d in root.rglob("debug_adapter"):
    if not d.is_dir():
        continue
    rel = d.relative_to(root).as_posix()
    if rel in seen:
        continue
    seen.add(rel)

    names = {p.name for p in d.glob("*.py")}
    missing = sorted(required - names)
    score = len(required - set(missing))
    if rel == "debug_adapter":
        score += 1

    candidates.append({
        "path": rel,
        "present_required": sorted(required & names),
        "missing_required": missing,
        "score": score,
        "file_count": len(list(d.glob("*.py"))),
    })

candidates.sort(key=lambda x: (len(x["missing_required"]), -x["score"], x["path"]))

(recovery / "candidate_regression_list.json").write_text(json.dumps(candidates, indent=2, sort_keys=True))
print("✅ candidates:", len(candidates))
print("✅ top candidate:", candidates[0]["path"] if candidates else None)
PY

echo "[3/7] Running candidate regressions safely..."
python3 <<'PY'
from pathlib import Path
import json, shutil, subprocess, sys, re
from datetime import datetime, timezone

root = Path.cwd()
recovery = root / ".panther" / "recovery"
reports = root / "reports" / "recovery"
original = sorted((root / ".panther" / "backups").glob("P1_Batch4_v2_original_debug_adapter_*/debug_adapter"), key=lambda p: p.stat().st_mtime, reverse=True)[0]

candidates = json.loads((recovery / "candidate_regression_list.json").read_text())

test_files = []
tests_root = root / "tests"
if tests_root.exists():
    for p in sorted(tests_root.rglob("test*.py")):
        s = p.as_posix().lower()
        if "h4" in s or "debug" in s or "dap" in s:
            test_files.append(str(p))

def restore_from(src: Path):
    dst = root / "debug_adapter"
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)

def count_failures(stdout: str):
    # Parse pytest summary like "19 failed, 153 passed" or collection errors.
    failed = 0
    errors = 0
    m = re.search(r"(\d+)\s+failed", stdout)
    if m:
        failed = int(m.group(1))
    m = re.search(r"(\d+)\s+error", stdout)
    if m:
        errors = int(m.group(1))
    return failed, errors

results = []
best = None

for i, cand in enumerate(candidates[:40], start=1):
    src = root / cand["path"]
    if not src.exists():
        continue

    restore_from(src)

    compile_proc = subprocess.run(
        [sys.executable, "-m", "py_compile"] + [str(p) for p in sorted((root / "debug_adapter").rglob("*.py"))],
        cwd=root,
        text=True,
        capture_output=True,
    )

    pytest_proc = None
    if compile_proc.returncode == 0 and test_files:
        pytest_proc = subprocess.run(
            [sys.executable, "-m", "pytest", *test_files, "-q"],
            cwd=root,
            text=True,
            capture_output=True,
        )

    stdout = pytest_proc.stdout if pytest_proc else ""
    stderr = pytest_proc.stderr if pytest_proc else compile_proc.stderr
    failed, errors = count_failures(stdout + "\n" + stderr)

    result = {
        "candidate": cand["path"],
        "candidate_rank": i,
        "missing_required": cand["missing_required"],
        "compile_rc": compile_proc.returncode,
        "pytest_rc": pytest_proc.returncode if pytest_proc else None,
        "failed_count": failed,
        "error_count": errors,
        "stdout_tail": stdout[-6000:],
        "stderr_tail": stderr[-3000:],
    }
    results.append(result)

    metric = (
        0 if compile_proc.returncode == 0 else 1000,
        pytest_proc.returncode if pytest_proc else 999,
        failed + errors,
        len(cand["missing_required"]),
        i,
    )

    if best is None or metric < best["metric"]:
        best = {"metric": metric, "result": result}

    print(f"candidate {i}: {cand['path']} compile={compile_proc.returncode} pytest={pytest_proc.returncode if pytest_proc else 'skip'} fails={failed} errors={errors}")

    if pytest_proc and pytest_proc.returncode == 0:
        break

# Restore original by default.
restore_from(original)

ok_candidate = best and best["result"].get("pytest_rc") == 0 and best["result"].get("compile_rc") == 0

summary = {
    "ok": bool(ok_candidate),
    "phase": "P-1",
    "batch": "4-v2",
    "name": "Candidate Regression Selector",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "tested_candidates": len(results),
    "best": best["result"] if best else None,
    "results": results,
    "policy": {
        "runtime_restored_to_original_after_test": True,
        "apply_candidate_only_if_full_regression_passes": True,
    },
}

(recovery / "candidate_regression_results.json").write_text(json.dumps(summary, indent=2, sort_keys=True))

report = [
    "# Panther Recovery Engine - P-1 Batch 4 v2",
    "",
    "## Status",
    "",
    "PASSED" if ok_candidate else "FAILED - no passing candidate found",
    "",
    "## Purpose",
    "",
    "Evaluate debug_adapter candidates safely and select a fully passing baseline.",
    "",
    "## Best Candidate",
    "",
    "```json",
    json.dumps(best["result"] if best else None, indent=2),
    "```",
    "",
    "## Next",
    "",
    "If PASSED, apply the winning candidate in Batch 4 v3. If FAILED, use the report to identify which specific contracts must be reconstructed.",
]
(reports / "P1_BATCH4_V2_CANDIDATE_REGRESSION_SELECTOR.md").write_text("\n".join(report))

print("✅ tested candidates:", len(results))
print("✅ best candidate:", best["result"]["candidate"] if best else None)
print("✅ best pytest rc:", best["result"]["pytest_rc"] if best else None)

if ok_candidate:
    print("✅ passing candidate found")
else:
    print("⚠️ no fully passing candidate found; current runtime restored to original")
PY

echo "[4/7] Generating status..."
python3 <<'PY'
from pathlib import Path
import json

recovery = Path(".panther/recovery")
summary = json.loads((recovery / "candidate_regression_results.json").read_text())

status = {
    "ok": summary["ok"],
    "phase": "P-1",
    "batch": "4-v2",
    "status": "COMPLETE" if summary["ok"] else "NEEDS_RECONSTRUCTION",
    "summary": ".panther/recovery/candidate_regression_results.json",
    "report": "reports/recovery/P1_BATCH4_V2_CANDIDATE_REGRESSION_SELECTOR.md",
    "next": "P-1 Batch 4 v3 - Apply Passing Candidate" if summary["ok"] else "P-1 Batch 4 v3 - Contract Reconstruction",
}
(recovery / "status_batch4_v2.json").write_text(json.dumps(status, indent=2, sort_keys=True))
print("✅ status:", status["status"])
PY

echo "============================================================"
echo "✅ P-1 Batch 4 v2 COMPLETE"
echo "Check: .panther/recovery/candidate_regression_results.json"
echo "============================================================"
