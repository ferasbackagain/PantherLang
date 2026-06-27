from __future__ import annotations

import hashlib
import json
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

try:
    from language.compiler.integration import PantherCompilerIntegrationFramework
except Exception:  # pragma: no cover
    PantherCompilerIntegrationFramework = None  # type: ignore


class IncrementalBuildError(RuntimeError):
    """Raised when the incremental compiler receives invalid input."""


@dataclass(frozen=True)
class SourceUnit:
    path: str
    sha256: str
    size_bytes: int
    mtime_ns: int


@dataclass
class IncrementalBuildPlan:
    changed: List[str]
    unchanged: List[str]
    removed: List[str]
    total_sources: int
    cache_hit_ratio: float


@dataclass
class IncrementalBuildResult:
    ok: bool
    phase: str
    version: str
    workspace: str
    plan: IncrementalBuildPlan
    compiled: List[str]
    reused: List[str]
    removed: List[str]
    artifacts: Dict[str, str]
    duration_ms: float
    cache_path: str
    external_api_used: bool = False
    network_required: bool = False
    diagnostics: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        data["plan"] = asdict(self.plan)
        return data

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2, sort_keys=True)


class IncrementalCompiler:
    """Deterministic incremental compiler wrapper for PantherLang Phase 6.2.

    It tracks Panther source fingerprints in a JSON state file, recompiles only changed
    sources, reuses unchanged artifacts, records removed sources, and keeps the system
    fully local/offline.
    """

    phase = "6.2"
    version = "0.6.2-incremental-compilation"

    def __init__(self, cache_dir: str | Path = "build/incremental_cache", compiler: Any | None = None) -> None:
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.state_path = self.cache_dir / "phase6_2_state.json"
        self.artifact_dir = self.cache_dir / "artifacts"
        self.artifact_dir.mkdir(parents=True, exist_ok=True)
        if compiler is not None:
            self.compiler = compiler
        elif PantherCompilerIntegrationFramework is not None:
            self.compiler = PantherCompilerIntegrationFramework()
        else:
            self.compiler = None

    @staticmethod
    def sha256_text(text: str) -> str:
        return hashlib.sha256(text.encode("utf-8")).hexdigest()

    @staticmethod
    def sha256_file(path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as fh:
            for chunk in iter(lambda: fh.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def _load_state(self) -> Dict[str, Any]:
        if not self.state_path.exists():
            return {"version": self.version, "sources": {}, "artifacts": {}}
        try:
            data = json.loads(self.state_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise IncrementalBuildError(f"Corrupt incremental cache: {self.state_path}") from exc
        if not isinstance(data, dict):
            raise IncrementalBuildError("Invalid incremental cache format")
        data.setdefault("sources", {})
        data.setdefault("artifacts", {})
        return data

    def _save_state(self, state: Dict[str, Any]) -> None:
        tmp = self.state_path.with_suffix(".tmp")
        tmp.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")
        tmp.replace(self.state_path)

    def discover_sources(self, workspace: str | Path) -> List[Path]:
        root = Path(workspace)
        if not root.exists():
            raise IncrementalBuildError(f"Workspace does not exist: {root}")
        if root.is_file():
            if root.suffix != ".panther":
                raise IncrementalBuildError("Incremental compiler accepts .panther files only")
            return [root]
        sources = sorted(p for p in root.rglob("*.panther") if p.is_file())
        if not sources:
            raise IncrementalBuildError(f"No .panther sources found in workspace: {root}")
        return sources

    def fingerprint_sources(self, workspace: str | Path) -> Dict[str, SourceUnit]:
        root = Path(workspace)
        sources = self.discover_sources(root)
        units: Dict[str, SourceUnit] = {}
        base = root if root.is_dir() else root.parent
        for path in sources:
            stat = path.stat()
            rel = str(path.relative_to(base) if path.is_relative_to(base) else path)
            units[rel] = SourceUnit(
                path=rel,
                sha256=self.sha256_file(path),
                size_bytes=stat.st_size,
                mtime_ns=stat.st_mtime_ns,
            )
        return units

    def plan(self, workspace: str | Path) -> IncrementalBuildPlan:
        state = self._load_state()
        current = self.fingerprint_sources(workspace)
        previous = state.get("sources", {})
        changed = sorted(k for k, unit in current.items() if previous.get(k, {}).get("sha256") != unit.sha256)
        unchanged = sorted(k for k, unit in current.items() if previous.get(k, {}).get("sha256") == unit.sha256)
        removed = sorted(k for k in previous.keys() if k not in current)
        total = len(current)
        hit_ratio = (len(unchanged) / total) if total else 0.0
        return IncrementalBuildPlan(changed, unchanged, removed, total, round(hit_ratio, 4))

    def _compile_unit(self, absolute_path: Path, rel_path: str) -> str:
        source = absolute_path.read_text(encoding="utf-8")
        if not source.strip():
            raise IncrementalBuildError(f"Empty Panther source: {rel_path}")
        if "panic_incremental_compiler" in source:
            raise IncrementalBuildError(f"Blocked incremental marker detected in {rel_path}")
        artifact_name = self.sha256_text(rel_path)[:16] + ".artifact.json"
        artifact_path = self.artifact_dir / artifact_name
        if self.compiler is not None:
            report = self.compiler.compile_source(source)
            payload: Dict[str, Any] = {
                "source": rel_path,
                "phase": self.phase,
                "compiler_report": report.to_dict() if hasattr(report, "to_dict") else str(report),
                "compiled_at": time.time(),
            }
        else:
            payload = {
                "source": rel_path,
                "phase": self.phase,
                "source_sha256": self.sha256_text(source),
                "compiled_at": time.time(),
            }
        artifact_path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
        return str(artifact_path)

    def build(self, workspace: str | Path) -> IncrementalBuildResult:
        start = time.perf_counter()
        root = Path(workspace)
        base = root if root.is_dir() else root.parent
        current = self.fingerprint_sources(root)
        build_plan = self.plan(root)
        state = self._load_state()
        artifacts: Dict[str, str] = dict(state.get("artifacts", {}))
        compiled: List[str] = []
        diagnostics: List[str] = []

        for removed in build_plan.removed:
            artifacts.pop(removed, None)
            diagnostics.append(f"removed:{removed}")

        for rel in build_plan.changed:
            absolute = (base / rel).resolve()
            artifacts[rel] = self._compile_unit(absolute, rel)
            compiled.append(rel)

        state = {
            "version": self.version,
            "phase": self.phase,
            "workspace": str(root),
            "sources": {k: asdict(v) for k, v in current.items()},
            "artifacts": artifacts,
            "last_build_unix": time.time(),
        }
        self._save_state(state)
        duration_ms = (time.perf_counter() - start) * 1000
        return IncrementalBuildResult(
            ok=True,
            phase=self.phase,
            version=self.version,
            workspace=str(root),
            plan=build_plan,
            compiled=compiled,
            reused=build_plan.unchanged,
            removed=build_plan.removed,
            artifacts=artifacts,
            duration_ms=round(duration_ms, 3),
            cache_path=str(self.state_path),
            diagnostics=diagnostics,
        )

    def clean(self) -> None:
        if self.state_path.exists():
            self.state_path.unlink()
        for artifact in self.artifact_dir.glob("*.artifact.json"):
            artifact.unlink()
