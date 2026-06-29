#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 6.1 PRO Verification"
echo "============================================================"

test -f language/compiler/integration/compiler_framework.py
test -f language/compiler/integration/phase6_1_manifest.json
test -f docs/phase6/PHASE_6_1_COMPILER_INTEGRATION_FRAMEWORK.md
test -f architecture/compiler/COMPILER_INTEGRATION_FRAMEWORK.md
test -f examples/compiler/phase6_1_integration.panther
test -f examples/compiler/phase6_1_expected.json
test -x scripts/run_phase6_1_practical_demo.sh
test -f tests/phase6_1/test_compiler_integration_framework.py
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
manifest = json.loads(Path("language/compiler/integration/phase6_1_manifest.json").read_text())
assert manifest["phase"] == "6.1"
assert manifest["status"] == "implemented"
assert manifest["external_api_required"] is False
assert manifest["network_required"] is False
assert "tokenize" in manifest["stages"]
assert "artifacts" in manifest["stages"]
assert manifest["engineering_rule"] == "No Feature Without Proof"
PY
echo "✅ manifest tests passed"

python3 - <<'PY'
from language.compiler.integration import PantherCompilerIntegrationFramework
source = open("examples/compiler/phase6_1_integration.panther").read()
report = PantherCompilerIntegrationFramework().compile_source(source)
assert report.ok is True
assert len(report.stages) == 8
assert [s.name for s in report.stages][0] == "source"
assert [s.name for s in report.stages][-1] == "artifacts"
assert "python_code" in report.artifacts
assert report.external_api_used is False
assert report.network_required is False
PY
echo "✅ positive pipeline tests passed"

python3 - <<'PY'
from language.compiler.integration import CompilerIntegrationError, PantherCompilerIntegrationFramework
fw = PantherCompilerIntegrationFramework()
for bad in ["", "   \n", "panic_compiler_integration"]:
    try:
        fw.compile_source(bad)
        raise AssertionError("bad source unexpectedly compiled")
    except CompilerIntegrationError:
        pass
PY
echo "✅ negative tests passed"

DEMO_OUT="$(bash scripts/run_phase6_1_practical_demo.sh)"
echo "$DEMO_OUT" | grep -q 'demo=phase6_1_compiler_integration_framework'
echo "$DEMO_OUT" | grep -q 'ok=true'
echo "$DEMO_OUT" | grep -q 'phase=6.1'
echo "$DEMO_OUT" | grep -q 'stages=source,tokenize,ast,semantic,ir,codegen,ai_optimize,artifacts'
echo "$DEMO_OUT" | grep -q 'external_api_used=false'
echo "$DEMO_OUT" | grep -q 'network_required=false'
test -f build/reports/phase6_1_compiler_integration_report.json
echo "✅ practical demo passed"

python3 - <<'PY'
from language.compiler.integration import PantherCompilerIntegrationFramework
models = [f"model Stress{i} {{\n  id: int required\n  name: string\n}}" for i in range(75)]
source = 'app StressCompiler { version "0.6.1" }\n' + "\n".join(models)
report = PantherCompilerIntegrationFramework(enable_ai_optimizer=False).compile_source(source)
assert report.ok is True
ast_stage = [s for s in report.stages if s.name == "ast"][0]
assert ast_stage.details["models"] == 75
PY
echo "✅ stress tests passed"

if command -v pytest >/dev/null 2>&1; then
  PYTHONPATH="$PWD:${PYTHONPATH:-}" pytest -q tests/phase6_1
  echo "✅ pytest regression suite passed"
else
  python3 -m py_compile tests/phase6_1/test_compiler_integration_framework.py
  echo "✅ python compile regression passed"
fi

echo "✅ PantherLang Phase 6.1 Compiler Integration Framework verification complete."
