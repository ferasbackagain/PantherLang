#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " Panther Recovery Engine"
echo " P-1 Batch 4 v3 - Safe Candidate Regression Selector"
echo "============================================================"

ROOT="$(pwd)"
RECOVERY="$ROOT/.panther/recovery"
REPORTS="$ROOT/reports/recovery"
STAMP="$(date +%Y%m%d_%H%M%S)"
ORIGINAL="$ROOT/.panther/backups/P1_Batch4_v3_original_debug_adapter_${STAMP}"
WORKDIR="/tmp/panther_recovery_candidates_${STAMP}"

mkdir -p "$RECOVERY" "$REPORTS" "$ORIGINAL" "$WORKDIR"

fail(){ echo "[P-1-B4-v3][ERROR] $1" >&2; exit 1; }

[ -d "$ROOT/debug_adapter" ] || fail "debug_adapter missing"

echo "[1/8] Saving current debug_adapter..."
cp -a "$ROOT/debug_adapter" "$ORIGINAL/debug_adapter"

echo "[2/8] Building immutable candidate snapshots in /tmp..."
python3 <<'PY'
from pathlib import Path
import json, shutil, os

root = Path.cwd()
recovery = root / ".panther" / "recovery"
workdirs = sorted(Path("/tmp").glob("panther_recovery_candidates_*"), key=lambda p: p.stat().st_mtime, reverse=True)
work = workdirs[0]
candidate_root = work / "candidates"
candidate_root.mkdir(parents=True, exist_ok=True)

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
seen_real = set()

for d in root.rglob("debug_adapter"):
    if not d.is_dir():
        continue
    # Do not scan inside new recovery candidate temp paths (not under root normally, but safe)
    rel = d.relative_to(root).as_posix()
    real = str(d.resolve())
    if real in seen_real:
        continue
    seen_real.add(real)

    names = {p.name for p in d.glob("*.py")}
    missing = sorted(required - names)

    safe_name = rel.replace("/", "__").replace(".", "_")
    snap = candidate_root / safe_name
    if snap.exists():
        shutil.rmtree(snap)
    shutil.copytree(d, snap)

    score = len(required - set(missing))
    if rel == "debug_adapter":
        # live is allowed, but only from immutable snapshot in /tmp
        score += 1

    candidates.append({
        "source_path": rel,
        "snapshot_path": snap.as_posix(),
        "present_required": sorted(required & names),
        "missing_required": missing,
        "score": score,
        "file_count": len(list(d.glob("*.py"))),
    })

candidates.sort(key=lambda x: (len(x["missing_required"]), -x["score"], x["source_path"]))

(recovery / "candidate_regression_list_v3.json").write_text(json.dumps({
    "ok": True,
    "candidate_count": len(candidates),
    "workdir": work.as_posix(),
    "candidates": candidates,
}, indent=2, sort_keys=True))

print("✅ immutable candidates:", len(candidates))
print("✅ workdir:", work)
print("✅ top candidate:", candidates[0]["source_path"] if candidates else None)
PY

echo "[3/8] Running candidate regressions from immutable snapshots..."
python3 <<'PY'
from pathlib import Path
import json, shutil, subprocess, sys, re
from datetime import datetime, timezone

root = Path.cwd()
recovery = root / ".panther" / "recovery"
reports = root / "reports" / "recovery"
original = sorted((root / ".panther" / "backups").glob("P1_Batch4_v3_original_debug_adapter_*/debug_adapter"), key=lambda p: p.stat().st_mtime, reverse=True)[0]

data = json.loads((recovery / "candidate_regression_list_v3.json").read_text())
candidates = data["candidates"]

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

def parse_counts(text: str):
    failed = errors = 0
    m = re.search(r"(\d+)\s+failed", text)
    if m: failed = int(m.group(1))
    m = re.search(r"(\d+)\s+error", text)
    if m: errors = int(m.group(1))
    return failed, errors

results = []
best = None

try:
    for i, cand in enumerate(candidates[:60], start=1):
        src = Path(cand["snapshot_path"])
        if not src.exists():
            continue

        restore_from(src)

        compile_proc = subprocess.run(
            [sys.executable, "-m", "py_compile"] + [str(p) for p in sorted((root / "debug_adapter").rglob("*.py"))],
            cwd=root, text=True, capture_output=True
        )

        pytest_proc = None
        if compile_proc.returncode == 0 and test_files:
            pytest_proc = subprocess.run(
                [sys.executable, "-m", "pytest", *test_files, "-q"],
                cwd=root, text=True, capture_output=True
            )

        combined = ""
        if pytest_proc:
            combined = pytest_proc.stdout + "\n" + pytest_proc.stderr
        else:
            combined = compile_proc.stdout + "\n" + compile_proc.stderr

        failed, errors = parse_counts(combined)
        pytest_rc = pytest_proc.returncode if pytest_proc else None

        result = {
            "source_path": cand["source_path"],
            "snapshot_path": cand["snapshot_path"],
            "rank": i,
            "compile_rc": compile_proc.returncode,
            "pytest_rc": pytest_rc,
            "failed_count": failed,
            "error_count": errors,
            "missing_required": cand["missing_required"],
            "stdout_tail": (pytest_proc.stdout if pytest_proc else compile_proc.stdout)[-8000:],
            "stderr_tail": (pytest_proc.stderr if pytest_proc else compile_proc.stderr)[-4000:],
        }
        results.append(result)

        metric = (
            0 if compile_proc.returncode == 0 else 1000,
            0 if pytest_rc == 0 else 100,
            failed + errors,
            len(cand["missing_required"]),
            i,
        )
        if best is None or metric < best["metric"]:
            best = {"metric": metric, "result": result}

        print(f"candidate {i}: {cand['source_path']} compile={compile_proc.returncode} pytest={pytest_rc} fails={failed} errors={errors}")

        if pytest_rc == 0:
            break
finally:
    # Always restore original live runtime after candidate testing.
    restore_from(original)

ok_candidate = bool(best and best["result"]["compile_rc"] == 0 and best["result"]["pytest_rc"] == 0)

summary = {
    "ok": ok_candidate,
    "phase": "P-1",
    "batch": "4-v3",
    "name": "Safe Candidate Regression Selector",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "tested_candidates": len(results),
    "best": best["result"] if best else None,
    "results": results,
    "policy": {
        "candidate_snapshots_are_immutable": True,
        "runtime_restored_to_original_after_test": True,
        "no_candidate_uses_live_path_directly": True,
    },
}

(recovery / "candidate_regression_results_v3.json").write_text(json.dumps(summary, indent=2, sort_keys=True))

report = [
    "# Panther Recovery Engine - P-1 Batch 4 v3",
    "",
    "## Status",
    "",
    "PASSED" if ok_candidate else "NEEDS_RECONSTRUCTION",
    "",
    "## Purpose",
    "",
    "Safely test immutable debug_adapter candidate snapshots without deleting the live candidate source.",
    "",
    "## Best Candidate",
    "",
    "```json",
    json.dumps(best["result"] if best else None, indent=2),
    "```",
    "",
    "## Tested Candidates",
    "",
    str(len(results)),
]
(reports / "P1_BATCH4_V3_SAFE_CANDIDATE_SELECTOR.md").write_text("\n".join(report))

print("✅ tested candidates:", len(results))
print("✅ best candidate:", best["result"]["source_path"] if best else None)
print("✅ best pytest rc:", best["result"]["pytest_rc"] if best else None)

if ok_candidate:
    print("✅ passing candidate found")
else:
    print("⚠️ no fully passing candidate found; live runtime restored to original")
PY

echo "[4/8] Generating status..."
python3 <<'PY'
from pathlib import Path
import json

recovery = Path(".panther/recovery")
summary = json.loads((recovery / "candidate_regression_results_v3.json").read_text())
status = {
    "ok": summary["ok"],
    "phase": "P-1",
    "batch": "4-v3",
    "status": "PASSING_CANDIDATE_FOUND" if summary["ok"] else "NEEDS_CONTRACT_RECONSTRUCTION",
    "summary": ".panther/recovery/candidate_regression_results_v3.json",
    "report": "reports/recovery/P1_BATCH4_V3_SAFE_CANDIDATE_SELECTOR.md",
    "next": "P-1 Batch 4 v4 - Apply Passing Candidate" if summary["ok"] else "P-1 Batch 4 v4 - Contract Reconstruction",
}
(recovery / "status_batch4_v3.json").write_text(json.dumps(status, indent=2, sort_keys=True))
print("✅ status:", status["status"])
PY

echo "============================================================"
echo "✅ P-1 Batch 4 v3 COMPLETE"
echo "Check: .panther/recovery/candidate_regression_results_v3.json"
echo "============================================================"
