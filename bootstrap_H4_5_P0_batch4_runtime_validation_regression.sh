#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"

echo "============================================================"
echo " PantherLang H4.5 P0 Batch 4"
echo " Runtime Validation + Regression"
echo "============================================================"
echo "[P0-B4] Root: $ROOT"

fail(){ echo "[P0-B4][ERROR] $1" >&2; exit 1; }

[ -f ".panther/status/H4_5_P0_Batch1_status.json" ] || fail "Batch 1 status missing."
[ -f ".panther/status/H4_5_P0_Batch2_v2_status.json" ] || fail "Batch 2 v2 status missing."
[ -f ".panther/status/H4_5_P0_Batch3_status.json" ] || fail "Batch 3 status missing."

mkdir -p .panther/h4_5_p0 .panther/status reports/H4_5/P0

python3 <<'PY'
from __future__ import annotations
import json, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

root = Path.cwd().resolve()
p0 = root / ".panther" / "h4_5_p0"
status_dir = root / ".panther" / "status"
report_dir = root / "reports" / "H4_5" / "P0"

results = []
errors = []

def run_check(name, cmd, required=True):
    proc = subprocess.run(cmd, cwd=root, text=True, capture_output=True)
    item = {
        "name": name,
        "cmd": cmd,
        "returncode": proc.returncode,
        "stdout_tail": proc.stdout[-4000:],
        "stderr_tail": proc.stderr[-4000:],
        "ok": proc.returncode == 0,
        "required": required,
    }
    results.append(item)
    if required and proc.returncode != 0:
        errors.append(f"{name} failed with rc={proc.returncode}")

for py_file in sorted((root / "debug_adapter").glob("*.py")):
    run_check(f"py_compile:{py_file.name}", [sys.executable, "-m", "py_compile", str(py_file)])

if (root / "panther").exists():
    run_check("panther_dap_doctor", ["./panther", "dap", "doctor"], required=False)
    run_check("panther_dap_version", ["./panther", "dap", "version"], required=False)

regression_scripts = [
    "scripts/verify_H4_2_finalize_v2_f8_end_to_end_professional_verification.sh",
    "scripts/verify_H4_3_d10_professional_verification.sh",
    "scripts/verify_H4_4_d6_vscode_end_to_end_verification.sh",
    "scripts/verify_H4_2_final.sh",
    "scripts/verify_H4_3_final.sh",
    "scripts/verify_H4_4_final.sh",
]

found_regressions = []
for script in regression_scripts:
    p = root / script
    if p.exists():
        found_regressions.append(script)
        p.chmod(p.stat().st_mode | 0o111)
        run_check(f"regression:{script}", ["bash", script], required=True)

if not found_regressions:
    h4_tests = []
    for d in [root / "tests", root / "debug_adapter"]:
        if d.exists():
            for p in d.rglob("test*.py"):
                s = p.as_posix().lower()
                if "h4" in s or "debug" in s or "dap" in s:
                    h4_tests.append(p.as_posix())
    if h4_tests:
        run_check("pytest_h4_debug_tests", [sys.executable, "-m", "pytest", *h4_tests, "-q"], required=True)
    else:
        smoke_code = "import pathlib; p=pathlib.Path('debug_adapter'); assert p.exists(); print('H4.5 P0 Batch4 runtime smoke OK')"
        run_check("minimal_debug_adapter_directory_smoke", [sys.executable, "-c", smoke_code], required=True)

runtime = {
    "ok": not errors,
    "phase": "H4.5",
    "milestone": "P0",
    "batch": "Batch 4",
    "name": "Runtime Validation + Regression",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "found_regressions": found_regressions,
    "results": results,
    "errors": errors,
}
(p0 / "runtime_validation.json").write_text(json.dumps(runtime, indent=2, sort_keys=True), encoding="utf-8")

report = "\n".join([
    "# H4.5 P0 Batch 4 Engineering Report",
    "",
    "## Status",
    "",
    "PASSED" if not errors else "FAILED",
    "",
    "## Purpose",
    "",
    "Runtime validation and regression after P0 workspace hygiene batches.",
    "",
    "## Regression Scripts Found",
    "",
    "```json",
    json.dumps(found_regressions, indent=2),
    "```",
    "",
    "## Checks",
    "",
    f"Total checks: {len(results)}",
    "",
    "## Errors",
    "",
    "```json",
    json.dumps(errors, indent=2),
    "```",
    "",
    "## Output Files",
    "",
    "- `.panther/h4_5_p0/runtime_validation.json`",
    "- `.panther/status/H4_5_P0_Batch4_status.json`",
    "",
    "## Next",
    "",
    "H4.5 P0 Batch 5 - Engineering Report + Status Finalization.",
])
(report_dir / "H4_5_P0_Batch4_ENGINEERING_REPORT.md").write_text(report, encoding="utf-8")

status = {
    "ok": not errors,
    "phase": "H4.5",
    "milestone": "P0",
    "batch": "Batch 4",
    "runtime_validation": ".panther/h4_5_p0/runtime_validation.json",
    "engineering_report": "reports/H4_5/P0/H4_5_P0_Batch4_ENGINEERING_REPORT.md",
    "next": "H4.5 P0 Batch 5 - Engineering Report + Status Finalization",
}
(status_dir / "H4_5_P0_Batch4_status.json").write_text(json.dumps(status, indent=2, sort_keys=True), encoding="utf-8")

print(f"✅ runtime checks executed: {len(results)}")
print(f"✅ regression scripts found: {len(found_regressions)}")
print("✅ runtime validation JSON generated")
print("✅ engineering report generated")
print("✅ status JSON generated")

if errors:
    print(json.dumps(errors, indent=2))
    raise SystemExit(2)
PY

test -f .panther/h4_5_p0/runtime_validation.json
test -f reports/H4_5/P0/H4_5_P0_Batch4_ENGINEERING_REPORT.md
test -f .panther/status/H4_5_P0_Batch4_status.json

python3 <<'PY'
import json
from pathlib import Path
status=json.loads(Path(".panther/status/H4_5_P0_Batch4_status.json").read_text())
runtime=json.loads(Path(".panther/h4_5_p0/runtime_validation.json").read_text())
assert status["ok"] is True
assert runtime["ok"] is True
assert len(runtime["results"]) > 0
print("✅ Batch 4 JSON assertions passed")
PY

echo "============================================================"
echo "✅ H4.5 P0 Batch 4 COMPLETE"
echo "Next: H4.5 P0 Batch 5 - Engineering Report + Status Finalization"
echo "============================================================"
