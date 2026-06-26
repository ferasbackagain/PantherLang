#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

OUT="$(python3 language/agents/runtime/agent_runtime.py demo)"

python3 - "$OUT" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
assert data["phase"] == "5.4"
assert data["workflow"] == "planner-coder-reviewer"
assert data["ok"] is True
assert data["agents_executed"] == 3
assert data["messages_exchanged"] == 3
assert data["security_violations"] == 0
assert data["runtime_failures"] == 0
assert data["external_api_used"] is False
assert "Reviewer approved PantherLang multi-agent workflow" in data["final_output"]

print("workflow=planner-coder-reviewer")
print("ok=true")
print("agents_executed=3")
print("messages_exchanged=3")
print("security_violations=0")
print("runtime_failures=0")
print("external_api_used=false")
print("contains=Reviewer approved PantherLang multi-agent workflow")
PY
