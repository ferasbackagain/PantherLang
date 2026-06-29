#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " Panther Recovery Engine"
echo " P-1 Batch 2 - Canonical Baseline"
echo "============================================================"

ROOT="$(pwd)"
RECOVERY="$ROOT/.panther/recovery"
REPORTS="$ROOT/reports/recovery"
mkdir -p "$RECOVERY" "$REPORTS"

fail(){ echo "[P-1-B2][ERROR] $1" >&2; exit 1; }

[ -f "$RECOVERY/debug_adapter_manifest.json" ] || fail "Batch 1 manifest missing. Run P-1 Batch 1 first."
[ -f "$RECOVERY/debug_adapter_locations.txt" ] || fail "Batch 1 debug_adapter locations missing."

python3 <<'PY'
from pathlib import Path
import json
from collections import defaultdict
from datetime import datetime, timezone

root = Path.cwd()
recovery = root / ".panther" / "recovery"
reports = root / "reports" / "recovery"

manifest = json.loads((recovery / "debug_adapter_manifest.json").read_text())
locations = [line.strip() for line in (recovery / "debug_adapter_locations.txt").read_text().splitlines() if line.strip()]

live_prefix = "debug_adapter/"
backup_markers = [
    "H4_5_P0_Batch4_v2",
    "H4_5_P0_Batch4_v3",
    "H4_4",
    "H4_3",
    "H4_2",
    "H4_1",
]

by_location = defaultdict(list)
for item in manifest:
    path = item["path"]
    if "/debug_adapter/" in path:
        loc = path.split("/debug_adapter/")[0] + "/debug_adapter"
    elif path.startswith("debug_adapter/"):
        loc = "debug_adapter"
    else:
        loc = "unknown"
    by_location[loc].append(item)

def score_location(loc, files):
    names = {Path(x["path"]).name for x in files}
    score = 0
    reasons = []

    if loc == "debug_adapter":
        score += 1000
        reasons.append("live debug_adapter")
    if ".panther/backups/" in loc:
        score += 100
        reasons.append("backup candidate")
    if "H4_5_P0_Batch4_v2" in loc:
        score += 450
        reasons.append("pre-v2 safety backup likely contains latest H4.3/H4.4 files")
    if "H4_5_P0_Batch4_v3" in loc:
        score -= 100
        reasons.append("post-v3 safety backup, may include mixed state")
    if "H4_4" in loc:
        score += 400
        reasons.append("H4.4 candidate")
    if "H4_3" in loc:
        score += 300
        reasons.append("H4.3 candidate")
    if "H4_2" in loc:
        score += 200
        reasons.append("H4.2 candidate")

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
    present = required & names
    score += len(present) * 25
    if len(present) == len(required):
        score += 500
        reasons.append("contains complete H4.2-H4.4 debug adapter module set")
    else:
        reasons.append(f"contains {len(present)}/{len(required)} required modules")

    score += min(len(files), 100)
    return score, reasons, sorted(required - names), sorted(present)

candidates = []
for loc, files in by_location.items():
    score, reasons, missing, present = score_location(loc, files)
    candidates.append({
        "location": loc,
        "score": score,
        "file_count": len(files),
        "reasons": reasons,
        "missing_required": missing,
        "present_required": present,
    })

candidates.sort(key=lambda x: x["score"], reverse=True)

canonical = candidates[0] if candidates else None

# File-level canonical plan:
# prefer live file if present and no known monkey patch marker;
# otherwise prefer highest-ranked candidate that contains the file.
file_index = defaultdict(list)
for item in manifest:
    name = Path(item["path"]).name
    file_index[name].append(item)

required_files = [
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
]

location_rank = {c["location"]: i for i, c in enumerate(candidates)}

def location_of(path):
    if "/debug_adapter/" in path:
        return path.split("/debug_adapter/")[0] + "/debug_adapter"
    if path.startswith("debug_adapter/"):
        return "debug_adapter"
    return "unknown"

canonical_files = []
for name in required_files:
    entries = file_index.get(name, [])
    if not entries:
        canonical_files.append({
            "file": name,
            "status": "missing_everywhere",
            "selected": None,
            "candidates": [],
        })
        continue

    def entry_key(e):
        loc = location_of(e["path"])
        # prefer canonical candidate, then live, then high score
        base = 0
        if canonical and loc == canonical["location"]:
            base += 10000
        if loc == "debug_adapter":
            base += 5000
        base += 1000 - location_rank.get(loc, 999)
        return base

    selected = sorted(entries, key=entry_key, reverse=True)[0]
    canonical_files.append({
        "file": name,
        "status": "selected",
        "selected": selected,
        "selected_location": location_of(selected["path"]),
        "candidate_count": len(entries),
    })

baseline = {
    "ok": True,
    "phase": "P-1",
    "batch": "2",
    "name": "Canonical Baseline",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "policy": {
        "runtime_modified": False,
        "analysis_only": True,
        "next_batch_may_reconstruct_from_manifest": True,
    },
    "locations_analyzed": len(candidates),
    "top_candidates": candidates[:20],
    "canonical_location": canonical,
    "canonical_files": canonical_files,
}

(recovery / "canonical_baseline.json").write_text(json.dumps(baseline, indent=2, sort_keys=True), encoding="utf-8")

report = ["# Panther Recovery Engine - P-1 Batch 2", "", "## Status", "", "COMPLETE", "", "## Purpose", "", "Build a canonical baseline plan from the workspace census without modifying runtime files.", "", "## Canonical Location", ""]
report.append("```json")
report.append(json.dumps(canonical, indent=2))
report.append("```")
report.append("")
report.append("## Top Candidates")
report.append("")
report.append("```json")
report.append(json.dumps(candidates[:10], indent=2))
report.append("```")
report.append("")
report.append("## Canonical Files")
report.append("")
report.append("```json")
report.append(json.dumps(canonical_files, indent=2))
report.append("```")
report.append("")
report.append("## Next")
report.append("")
report.append("P-1 Batch 3 - Reconstruction Plan.")

(reports / "P1_BATCH2_CANONICAL_BASELINE.md").write_text("\n".join(report), encoding="utf-8")

status = {
    "ok": True,
    "phase": "P-1",
    "batch": "2",
    "status": "COMPLETE",
    "canonical_baseline": ".panther/recovery/canonical_baseline.json",
    "report": "reports/recovery/P1_BATCH2_CANONICAL_BASELINE.md",
    "next": "P-1 Batch 3 - Reconstruction Plan",
}
(recovery / "status_batch2.json").write_text(json.dumps(status, indent=2, sort_keys=True), encoding="utf-8")

print("✅ analyzed locations:", len(candidates))
print("✅ canonical location:", canonical["location"] if canonical else None)
print("✅ canonical file selections:", len(canonical_files))
print("✅ report generated")
PY

echo "============================================================"
echo "✅ P-1 Batch 2 COMPLETE"
echo "Next: P-1 Batch 3 - Reconstruction Plan"
echo "============================================================"
