#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 - <<'PY'
from pathlib import Path
from language.compiler.integration import PantherCompilerIntegrationFramework
source_path = Path("examples/compiler/phase6_1_integration.panther")
report = PantherCompilerIntegrationFramework().compile_file(source_path)
print("demo=phase6_1_compiler_integration_framework")
print(f"ok={str(report.ok).lower()}")
print(f"phase={report.phase}")
print(f"version={report.version}")
print("stages=" + ",".join(stage.name for stage in report.stages))
print(f"source_chars={report.source_chars}")
print(f"external_api_used={str(report.external_api_used).lower()}")
print(f"network_required={str(report.network_required).lower()}")
print(f"artifact_keys={','.join(sorted(report.artifacts.keys()))}")
Path("build/reports").mkdir(parents=True, exist_ok=True)
Path("build/reports/phase6_1_compiler_integration_report.json").write_text(report.to_json() + "\n")
PY
