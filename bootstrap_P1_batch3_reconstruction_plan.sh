#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " Panther Recovery Engine"
echo " P-1 Batch 3 - Reconstruction Plan"
echo "============================================================"

ROOT="$(pwd)"
RECOVERY="$ROOT/.panther/recovery"
OUT="$RECOVERY/reconstruction_plan"
mkdir -p "$OUT"

[ -f "$RECOVERY/canonical_baseline.json" ] || {
  echo "[ERROR] Run P-1 Batch 2 first."
  exit 1
}

python3 <<'PY'
from pathlib import Path
import json
from datetime import datetime, timezone

root = Path.cwd()
recovery = root/".panther"/"recovery"

baseline = json.loads((recovery/"canonical_baseline.json").read_text())

plan = {
    "created_at": datetime.now(timezone.utc).isoformat(),
    "phase": "P-1",
    "batch": "3",
    "mode": "PLAN_ONLY",
    "runtime_modified": False,
    "canonical_location": baseline["canonical_location"]["location"],
    "actions": [],
}

for f in baseline["canonical_files"]:
    if f["status"] != "selected":
        plan["actions"].append({
            "file": f["file"],
            "action": "manual_review",
            "reason": "Missing everywhere"
        })
        continue

    loc = f["selected_location"]
    if loc == "debug_adapter":
        action = "keep_live"
    else:
        action = "copy_from_candidate"

    plan["actions"].append({
        "file": f["file"],
        "action": action,
        "source": loc,
        "candidate_count": f.get("candidate_count", 1)
    })

(recovery/"reconstruction_plan.json").write_text(
    json.dumps(plan, indent=2), encoding="utf-8"
)

lines = [
"# Panther Recovery Engine - Reconstruction Plan",
"",
"Status: COMPLETE",
"",
"Mode: PLAN ONLY (no runtime modifications)",
"",
f"Canonical Location: {plan['canonical_location']}",
"",
"| File | Planned Action | Source |",
"|------|----------------|--------|"
]
for a in plan["actions"]:
    lines.append(f"| {a['file']} | {a['action']} | {a.get('source','-')} |")

(root/"reports"/"recovery").mkdir(parents=True, exist_ok=True)
(root/"reports"/"recovery"/"P1_BATCH3_RECONSTRUCTION_PLAN.md").write_text(
    "\n".join(lines), encoding="utf-8"
)

(recovery/"status_batch3.json").write_text(json.dumps({
    "ok": True,
    "phase":"P-1",
    "batch":"3",
    "status":"COMPLETE",
    "next":"P-1 Batch 4 - Controlled Reconstruction"
}, indent=2), encoding="utf-8")

print("✅ Reconstruction actions:", len(plan["actions"]))
print("✅ Plan only. No runtime files modified.")
PY

echo "============================================================"
echo "✅ P-1 Batch 3 COMPLETE"
echo "Next: P-1 Batch 4 - Controlled Reconstruction"
echo "============================================================"
