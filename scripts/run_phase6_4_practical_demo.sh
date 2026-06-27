#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
mkdir -p build/phase6_4_demo_workspace/core build/phase6_4_demo_workspace/app build/reports
cat > build/phase6_4_demo_workspace/core/math.panther <<'PANTHER64'
fn add(a: Int, b: Int) -> Int { return a + b }
fn label(name: String) -> String { return "Hello " + name }
let base = 40
let scores = [1, 2, 3]
PANTHER64
cat > build/phase6_4_demo_workspace/app/main.panther <<'PANTHER64'
import core
let x = 2
let answer = 42
let title = "Panther" + "Lang"
let ready: Bool = true
fn main() -> Int { return 42 }
PANTHER64
cat > build/phase6_4_demo_workspace/panther.workspace.json <<'JSON64'
{"name":"phase6_4_demo_workspace","version":"0.1.0","entry":"app.main","modules":[{"name":"core","root":"core","sources":["*.panther"]},{"name":"app","root":"app","sources":["*.panther"]}]}
JSON64
PYTHONPATH="$ROOT" python3 - <<'PY64RUN'
from language.compiler.type_inference import AdvancedTypeInferenceEngine
report = AdvancedTypeInferenceEngine().analyze_workspace("build/phase6_4_demo_workspace")
print("Phase 6.4 demo ok:", report["ok"]); print("Files analyzed:", report["files_analyzed"]); print("Report: build/reports/phase6_4_last_inference_report.json")
raise SystemExit(0 if report["ok"] else 1)
PY64RUN
