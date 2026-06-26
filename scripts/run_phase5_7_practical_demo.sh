#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="$(python3 language/distributed/runtime/distributed_runtime.py demo)"

python3 - "$OUT" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["phase"] == "5.7"
assert data["ok"] is True
assert data["scheduled_tasks"] == 3
assert data["completed_tasks"] == 3
assert data["failed_tasks"] == 0
assert data["external_api_used"] is False
assert data["network_used"] is False
assert data["deterministic"] is True
outputs = [r["output"] for r in data["results"]]
assert "PANTHER DISTRIBUTED EXECUTION" in outputs
assert 42 in outputs
print("demo=distributed-execution")
print("ok=true")
print("scheduled_tasks=3")
print("completed_tasks=3")
print("failed_tasks=0")
print("external_api_used=false")
print("network_used=false")
print("deterministic=true")
print("contains=PANTHER DISTRIBUTED EXECUTION")
print("contains=42")
PY
