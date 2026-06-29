from __future__ import annotations
import json
from pathlib import Path
import pytest
from language.compiler.integration import CompilerIntegrationError, PantherCompilerIntegrationFramework

SAMPLE = '''
app PhaseSixCompilerDemo {
  version "0.6.1"
}

model User {
  id: int required
  name: string required
}

agent CompilerAgent {
  purpose "Validate compiler integration"
  memory local
  tools compiler, diagnostics
}
'''

def test_positive_pipeline_contract():
    report = PantherCompilerIntegrationFramework().compile_source(SAMPLE)
    assert report.ok is True
    assert report.phase == "6.1"
    assert report.version == "0.6.1-compiler-integration-framework"
    assert report.external_api_used is False
    assert report.network_required is False
    assert [stage.name for stage in report.stages] == ["source", "tokenize", "ast", "semantic", "ir", "codegen", "ai_optimize", "artifacts"]
    assert "python_code" in report.artifacts
    assert report.source_sha256

def test_json_report_is_serializable():
    report = PantherCompilerIntegrationFramework().compile_source(SAMPLE)
    data = json.loads(report.to_json())
    assert data["ok"] is True
    assert data["phase"] == "6.1"
    assert len(data["stages"]) == 8

def test_negative_empty_source():
    with pytest.raises(CompilerIntegrationError):
        PantherCompilerIntegrationFramework().compile_source("   \n")

def test_negative_blocked_marker():
    with pytest.raises(CompilerIntegrationError):
        PantherCompilerIntegrationFramework().compile_source("panic_compiler_integration")

def test_compile_file_example():
    path = Path("examples/compiler/phase6_1_integration.panther")
    report = PantherCompilerIntegrationFramework().compile_file(path)
    assert report.ok is True
    assert any(stage.name == "ast" and stage.details["models"] >= 1 for stage in report.stages)

def test_stress_many_models():
    models = [f"model M{i} {{\n  id: int required\n  name: string\n}}" for i in range(50)]
    source = 'app StressApp { version "0.6.1" }\n' + "\n".join(models)
    report = PantherCompilerIntegrationFramework(enable_ai_optimizer=False).compile_source(source)
    assert report.ok is True
    assert any(stage.name == "ast" and stage.details["models"] == 50 for stage in report.stages)
