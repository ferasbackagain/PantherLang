#!/usr/bin/env bash
set -euo pipefail

# PantherLang Phase 6.1 Professional
# Compiler Integration Framework

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase6_1_compiler_integration_$STAMP"

echo "============================================================"
echo " PantherLang Phase 6.1 PRO - Compiler Integration Framework"
echo "============================================================"
echo "[phase6.1] Project root: $ROOT"

fail(){ echo "[phase6.1][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }
require_dir(){ [ -d "$1" ] || fail "Required directory missing: $1"; }
backup_if_exists(){ local t="$1"; if [ -e "$t" ]; then mkdir -p "$BACKUP_DIR/$(dirname "$t")"; cp -a "$t" "$BACKUP_DIR/$t"; fi; }

require_file "README.md"
require_file "CHANGELOG.md"
require_dir "language"
require_dir "language/compiler"
require_dir "scripts"
require_dir "docs"

mkdir -p "$BACKUP_DIR"
echo "[phase6.1] Creating backup at: $BACKUP_DIR"

for t in \
  language/compiler/integration/__init__.py \
  language/compiler/integration/compiler_framework.py \
  language/compiler/integration/phase6_1_manifest.json \
  docs/phase6/PHASE_6_1_COMPILER_INTEGRATION_FRAMEWORK.md \
  architecture/compiler/COMPILER_INTEGRATION_FRAMEWORK.md \
  examples/compiler/phase6_1_integration.panther \
  examples/compiler/phase6_1_expected.json \
  scripts/run_phase6_1_practical_demo.sh \
  scripts/verify_phase6_1_compiler_integration.sh \
  tests/phase6_1 \
  CHANGELOG.md
do backup_if_exists "$t"; done

mkdir -p language/compiler/integration docs/phase6 architecture/compiler examples/compiler scripts tests/phase6_1 build/reports

cat > language/compiler/integration/phase6_1_manifest.json <<'EOF_JSON'
{
  "name": "PantherLang Compiler Integration Framework",
  "phase": "6.1",
  "version": "0.6.1-compiler-integration-framework",
  "status": "implemented",
  "depends_on": ["5.10 AI-Native Foundation"],
  "external_api_required": false,
  "network_required": false,
  "purpose": "Provide a deterministic compiler pipeline contract connecting source, tokens, AST, semantic analysis, IR/code generation, AI optimization, diagnostics, and artifacts.",
  "stages": ["source", "tokenize", "ast", "semantic", "ir", "codegen", "ai_optimize", "artifacts"],
  "testing_standard": ["structure", "manifest", "positive_pipeline", "negative_pipeline", "practical_demo", "regression", "stress"],
  "engineering_rule": "No Feature Without Proof"
}
EOF_JSON

cat > language/compiler/integration/compiler_framework.py <<'EOF_PY'
from __future__ import annotations

import hashlib
import json
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class CompilerStageResult:
    name: str
    ok: bool
    duration_ms: float
    details: dict[str, Any] = field(default_factory=dict)
    error: str = ""


@dataclass
class CompilerIntegrationReport:
    ok: bool
    phase: str
    version: str
    source_sha256: str
    source_chars: int
    stages: list[CompilerStageResult] = field(default_factory=list)
    diagnostics: list[str] = field(default_factory=list)
    artifacts: dict[str, Any] = field(default_factory=dict)
    external_api_used: bool = False
    network_required: bool = False

    def to_dict(self) -> dict[str, Any]:
        data = asdict(self)
        data["stages"] = [asdict(stage) for stage in self.stages]
        return data

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2, sort_keys=True)


class CompilerIntegrationError(Exception):
    pass


class PantherCompilerIntegrationFramework:
    """Phase 6.1 deterministic compiler integration framework."""

    phase = "6.1"
    version = "0.6.1-compiler-integration-framework"

    def __init__(self, enable_ai_optimizer: bool = True):
        self.enable_ai_optimizer = enable_ai_optimizer

    def _stage(self, report: CompilerIntegrationReport, name: str, fn):
        started = time.perf_counter()
        try:
            details = fn()
            duration_ms = round((time.perf_counter() - started) * 1000, 3)
            report.stages.append(CompilerStageResult(name=name, ok=True, duration_ms=duration_ms, details=details or {}))
            return details
        except Exception as exc:
            duration_ms = round((time.perf_counter() - started) * 1000, 3)
            message = f"{name}: {exc.__class__.__name__}: {exc}"
            report.stages.append(CompilerStageResult(name=name, ok=False, duration_ms=duration_ms, error=message))
            report.diagnostics.append(message)
            report.ok = False
            raise CompilerIntegrationError(message) from exc

    def compile_source(self, source: str, *, path: str = "<memory>") -> CompilerIntegrationReport:
        if not isinstance(source, str):
            raise TypeError("source must be a string")
        if not source.strip():
            raise CompilerIntegrationError("source cannot be empty")
        if "panic_compiler_integration" in source:
            raise CompilerIntegrationError("blocked unsafe integration marker")

        report = CompilerIntegrationReport(
            ok=True,
            phase=self.phase,
            version=self.version,
            source_sha256=hashlib.sha256(source.encode("utf-8")).hexdigest(),
            source_chars=len(source),
        )
        context: dict[str, Any] = {"source": source, "path": path}

        self._stage(report, "source", lambda: {"path": path, "chars": len(source), "lines": len(source.splitlines())})

        def tokenize_stage():
            try:
                from language.compiler.core.tokenizer import tokenize
            except Exception:
                from language.compiler.core.lexer import tokenize
            tokens = tokenize(source)
            context["tokens"] = tokens
            return {"token_count": len(tokens), "token_preview": [getattr(t, "value", str(t)) for t in tokens[:8]]}
        self._stage(report, "tokenize", tokenize_stage)

        def ast_stage():
            from language.compiler.ast.ast_builder import RealASTBuilder
            ast_program = RealASTBuilder().build(source)
            context["ast"] = ast_program
            return {
                "has_app": bool(getattr(ast_program, "app", None)),
                "models": len(getattr(ast_program, "models", [])),
                "apis": len(getattr(ast_program, "apis", [])),
                "pages": len(getattr(ast_program, "pages", [])),
                "agents": len(getattr(ast_program, "agents", [])),
            }
        self._stage(report, "ast", ast_stage)

        def semantic_stage():
            ast_program = context["ast"]
            known_builtin = {"any", "int", "float", "string", "bool", "json", "date", "time", "uuid", "bytes"}
            known_models = {m.name for m in getattr(ast_program, "models", [])}
            semantic_models = []
            errors = []
            for model in getattr(ast_program, "models", []):
                fields = []
                for field in getattr(model, "fields", []):
                    type_name = getattr(field, "type_name", "any")
                    clean_type = type_name[:-1] if type_name.endswith("?") else type_name
                    if clean_type not in known_builtin and clean_type not in known_models:
                        errors.append(f"Unknown type {type_name} in model {model.name}.{field.name}")
                    fields.append({"name": field.name, "type_name": type_name, "required": bool(getattr(field, "required", False)), "default": getattr(field, "default", "")})
                semantic_models.append({"name": model.name, "fields": fields})
            if errors:
                raise ValueError("; ".join(errors))
            context["semantic_models"] = semantic_models
            return {"semantic_ok": True, "models": len(semantic_models), "fields": sum(len(m["fields"]) for m in semantic_models)}
        self._stage(report, "semantic", semantic_stage)

        def ir_stage():
            app = getattr(context["ast"], "app", None)
            app_name = getattr(app, "name", None) or "PantherApp"
            ir = {"kind": "PantherIR", "version": self.version, "name": app_name, "models": context["semantic_models"]}
            context["ir"] = ir
            return {"ir_type": "dict", "app_name": app_name, "models": len(ir["models"])}
        self._stage(report, "ir", ir_stage)

        def codegen_stage():
            ir = context["ir"]
            lines = ["# Generated by PantherLang Phase 6.1", f"APP_NAME = {ir['name']!r}", "", "MODELS = {}"]
            for model in ir.get("models", []):
                fields = [field["name"] for field in model.get("fields", [])]
                lines.append(f"MODELS[{model['name']!r}] = {fields!r}")
            lines.extend(["", "def describe():", "    return {'app': APP_NAME, 'models': MODELS}", ""])
            code = "\n".join(lines)
            context["code"] = code
            return {"target": "python", "code_chars": len(code), "code_sha256": hashlib.sha256(code.encode()).hexdigest()}
        self._stage(report, "codegen", codegen_stage)

        def ai_optimize_stage():
            if not self.enable_ai_optimizer:
                context["optimized_code"] = context["code"]
                return {"enabled": False, "optimized": False}
            try:
                from language.compiler.ai_optimizer.runtime.ai_optimizer import DeterministicAIOptimizer
                optimized = DeterministicAIOptimizer().optimize(context["code"], level="AI")
                context["optimized_code"] = optimized.optimized_source
                return {"enabled": True, "optimized": True, "passes_applied": optimized.passes_applied, "external_api_used": optimized.external_api_used, "deterministic": optimized.deterministic}
            except Exception as exc:
                context["optimized_code"] = context["code"]
                report.diagnostics.append(f"ai_optimize warning: {exc}")
                return {"enabled": True, "optimized": False, "warning": str(exc)}
        self._stage(report, "ai_optimize", ai_optimize_stage)

        def artifacts_stage():
            report.artifacts = {
                "python_code": context.get("code", ""),
                "optimized_code": context.get("optimized_code", context.get("code", "")),
                "stage_count": len(report.stages) + 1,
            }
            return {"artifact_keys": sorted(report.artifacts.keys())}
        self._stage(report, "artifacts", artifacts_stage)
        return report

    def compile_file(self, path: str | Path) -> CompilerIntegrationReport:
        path = Path(path)
        return self.compile_source(path.read_text(encoding="utf-8"), path=str(path))

    def write_report(self, source: str, output_path: str | Path) -> CompilerIntegrationReport:
        report = self.compile_source(source)
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(report.to_json() + "\n", encoding="utf-8")
        return report
EOF_PY

cat > language/compiler/integration/__init__.py <<'EOF_PY'
from .compiler_framework import (
    CompilerIntegrationError,
    CompilerIntegrationReport,
    CompilerStageResult,
    PantherCompilerIntegrationFramework,
)

try:
    from .e2e_compiler import PantherEndToEndCompiler
except Exception:
    PantherEndToEndCompiler = None

__all__ = [
    "CompilerIntegrationError",
    "CompilerIntegrationReport",
    "CompilerStageResult",
    "PantherCompilerIntegrationFramework",
    "PantherEndToEndCompiler",
]
EOF_PY

cat > examples/compiler/phase6_1_integration.panther <<'EOF_PANTHER'
app PhaseSixCompilerDemo {
  version "0.6.1"
}

model User {
  id: int required
  name: string required
  email: string
}

api GET /users {
  return User
}

page UsersPage {
  title "Users"
  table User
}

agent CompilerAgent {
  purpose "Validate the compiler integration framework"
  memory local
  tools compiler, diagnostics
}
EOF_PANTHER

cat > examples/compiler/phase6_1_expected.json <<'EOF_JSON'
{
  "phase": "6.1",
  "ok": true,
  "required_stages": ["source", "tokenize", "ast", "semantic", "ir", "codegen", "ai_optimize", "artifacts"],
  "minimum_stage_count": 8,
  "external_api_used": false,
  "network_required": false
}
EOF_JSON

cat > scripts/run_phase6_1_practical_demo.sh <<'EOF_SH'
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
EOF_SH
chmod +x scripts/run_phase6_1_practical_demo.sh

cat > docs/phase6/PHASE_6_1_COMPILER_INTEGRATION_FRAMEWORK.md <<'EOF_MD'
# PantherLang Phase 6.1 — Compiler Integration Framework

## Status
Implemented.

## Objective
Phase 6.1 introduces a deterministic compiler integration framework that connects PantherLang source code to a stable compiler pipeline contract.

## Pipeline Contract
1. source
2. tokenize
3. ast
4. semantic
5. ir
6. codegen
7. ai_optimize
8. artifacts

## Engineering Properties
- Deterministic execution
- No external API requirement
- No network requirement
- Stage-level diagnostics
- JSON report output
- Practical demo
- Positive tests
- Negative tests
- Stress tests
- Regression check

## Verification
```bash
bash scripts/verify_phase6_1_compiler_integration.sh
```

## Practical Demo
```bash
bash scripts/run_phase6_1_practical_demo.sh
```
EOF_MD

cat > architecture/compiler/COMPILER_INTEGRATION_FRAMEWORK.md <<'EOF_MD'
# Compiler Integration Framework Architecture

Panther Source → Source Stage → Tokenizer → AST Builder → Semantic Integration → IR Integration → Code Generation → AI Optimizer Integration → Artifacts + Report

## Future Extension Points
- incremental compiler cache
- workspace graph
- module resolver
- type inference graph
- async runtime lowering
- native backend
- WebAssembly backend
- IDE/LSP diagnostics
- cross-platform toolchain
EOF_MD

cat > tests/phase6_1/test_compiler_integration_framework.py <<'EOF_PY'
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
EOF_PY

cat > scripts/verify_phase6_1_compiler_integration.sh <<'EOF_SH'
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
EOF_SH
chmod +x scripts/verify_phase6_1_compiler_integration.sh

cat >> CHANGELOG.md <<'EOF_MD'

## Phase 6.1 — Compiler Integration Framework

- Added deterministic compiler integration framework.
- Added stage-level compiler pipeline contract: source, tokenize, AST, semantic, IR, codegen, AI optimization, artifacts.
- Added structured JSON integration reports.
- Added practical demo and generated report output.
- Added positive, negative, regression, and stress tests.
- Added Phase 6.1 architecture and documentation.
EOF_MD

echo "[phase6.1] Running verification..."
bash scripts/verify_phase6_1_compiler_integration.sh

echo "============================================================"
echo "✅ PantherLang Phase 6.1 installed and verified successfully."
echo "Next commands:"
echo "  bash scripts/run_phase6_1_practical_demo.sh"
echo "  bash scripts/verify_phase6_1_compiler_integration.sh"
echo "  git add . && git commit -m 'Add Phase 6.1 Compiler Integration Framework'"
echo "  git push origin main"
echo "============================================================"
