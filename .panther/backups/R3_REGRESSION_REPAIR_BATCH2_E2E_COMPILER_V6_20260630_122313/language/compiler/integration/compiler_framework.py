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
