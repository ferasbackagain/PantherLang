from __future__ import annotations

import json
import re
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Set

try:
    from language.compiler.incremental import IncrementalCompiler
except Exception:  # pragma: no cover
    IncrementalCompiler = None  # type: ignore


class WorkspaceError(RuntimeError):
    """Raised for invalid PantherLang workspace/module operations."""


@dataclass(frozen=True)
class ModuleInfo:
    name: str
    root: str
    sources: List[str]
    imports: List[str] = field(default_factory=list)


@dataclass(frozen=True)
class WorkspaceManifest:
    name: str
    version: str
    modules: List[ModuleInfo]
    entry: Optional[str] = None
    panther_version: str = "0.6.3"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "version": self.version,
            "entry": self.entry,
            "panther_version": self.panther_version,
            "modules": [asdict(m) for m in self.modules],
        }


@dataclass
class WorkspaceBuildResult:
    ok: bool
    phase: str
    version: str
    workspace: str
    build_order: List[str]
    modules_built: List[str]
    module_count: int
    source_count: int
    diagnostics: List[str]
    artifacts: Dict[str, Any]
    duration_ms: float
    external_api_used: bool = False
    network_required: bool = False

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2, sort_keys=True)


class WorkspaceManager:
    """PantherLang Phase 6.3 module/workspace coordinator.

    Responsibilities:
    - discover Panther workspace manifests
    - validate module declarations and source roots
    - extract module imports from .panther source files
    - build deterministic dependency order
    - delegate compilation to Phase 6.2 incremental compiler when available
    - keep all behavior local, deterministic, and offline
    """

    phase = "6.3"
    version = "0.6.3-module-workspace-system"
    manifest_names = ("panther.workspace.json", "panther.json")
    import_pattern = re.compile(r"^\s*import\s+([A-Za-z_][A-Za-z0-9_.]*)\s*;?\s*$", re.MULTILINE)

    def __init__(self, cache_dir: str | Path = "build/workspace_cache", compiler: Any | None = None) -> None:
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        if compiler is not None:
            self.compiler = compiler
        elif IncrementalCompiler is not None:
            self.compiler = IncrementalCompiler(cache_dir=self.cache_dir / "incremental")
        else:
            self.compiler = None

    def find_manifest(self, workspace: str | Path) -> Path:
        root = Path(workspace)
        if root.is_file():
            return root
        for name in self.manifest_names:
            candidate = root / name
            if candidate.exists():
                return candidate
        raise WorkspaceError(f"No Panther workspace manifest found in {root}")

    def load_manifest(self, workspace: str | Path) -> WorkspaceManifest:
        manifest_path = self.find_manifest(workspace)
        try:
            data = json.loads(manifest_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise WorkspaceError(f"Invalid JSON workspace manifest: {manifest_path}") from exc
        if not isinstance(data, dict):
            raise WorkspaceError("Workspace manifest must be a JSON object")
        name = str(data.get("name") or "").strip()
        version = str(data.get("version") or "0.1.0").strip()
        if not name:
            raise WorkspaceError("Workspace manifest requires a non-empty name")
        raw_modules = data.get("modules")
        if not isinstance(raw_modules, list) or not raw_modules:
            raise WorkspaceError("Workspace manifest requires a non-empty modules array")
        modules: List[ModuleInfo] = []
        seen: Set[str] = set()
        for item in raw_modules:
            if not isinstance(item, dict):
                raise WorkspaceError("Each workspace module must be an object")
            module_name = str(item.get("name") or "").strip()
            module_root = str(item.get("root") or "").strip()
            if not module_name or not module_root:
                raise WorkspaceError("Each module requires name and root")
            if module_name in seen:
                raise WorkspaceError(f"Duplicate module name: {module_name}")
            seen.add(module_name)
            sources = item.get("sources", ["**/*.panther"])
            if isinstance(sources, str):
                sources = [sources]
            if not isinstance(sources, list) or not sources:
                raise WorkspaceError(f"Module {module_name} requires source globs")
            modules.append(ModuleInfo(name=module_name, root=module_root, sources=[str(s) for s in sources]))
        return WorkspaceManifest(
            name=name,
            version=version,
            entry=data.get("entry"),
            panther_version=str(data.get("panther_version") or "0.6.3"),
            modules=modules,
        )

    def module_paths(self, workspace: str | Path, manifest: WorkspaceManifest) -> Dict[str, Path]:
        root = Path(workspace)
        if root.is_file():
            root = root.parent
        paths: Dict[str, Path] = {}
        for module in manifest.modules:
            module_root = (root / module.root).resolve()
            if not module_root.exists() or not module_root.is_dir():
                raise WorkspaceError(f"Module root does not exist: {module.name} -> {module.root}")
            paths[module.name] = module_root
        return paths

    def discover_module_sources(self, module_root: Path, globs: Iterable[str]) -> List[Path]:
        sources: List[Path] = []
        for pattern in globs:
            sources.extend(p for p in module_root.glob(pattern) if p.is_file() and p.suffix == ".panther")
        unique = sorted(set(sources))
        if not unique:
            raise WorkspaceError(f"No .panther sources found in module root: {module_root}")
        return unique

    def extract_imports(self, sources: Iterable[Path]) -> List[str]:
        imports: Set[str] = set()
        for source in sources:
            text = source.read_text(encoding="utf-8")
            imports.update(match.group(1).split(".")[0] for match in self.import_pattern.finditer(text))
        return sorted(imports)

    def resolve_modules(self, workspace: str | Path) -> List[ModuleInfo]:
        manifest = self.load_manifest(workspace)
        paths = self.module_paths(workspace, manifest)
        resolved: List[ModuleInfo] = []
        declared = {m.name for m in manifest.modules}
        for module in manifest.modules:
            module_root = paths[module.name]
            source_paths = self.discover_module_sources(module_root, module.sources)
            imports = [imp for imp in self.extract_imports(source_paths) if imp in declared and imp != module.name]
            root_path = Path(workspace)
            base = root_path.parent if root_path.is_file() else root_path
            rel_sources = [str(p.relative_to(base.resolve())) for p in source_paths]
            resolved.append(ModuleInfo(module.name, module.root, rel_sources, imports))
        return resolved

    def dependency_graph(self, modules: Iterable[ModuleInfo]) -> Dict[str, List[str]]:
        graph = {m.name: sorted(set(m.imports)) for m in modules}
        declared = set(graph)
        for name, imports in graph.items():
            missing = [imp for imp in imports if imp not in declared]
            if missing:
                raise WorkspaceError(f"Module {name} imports undeclared modules: {missing}")
        return graph

    def build_order(self, graph: Dict[str, List[str]]) -> List[str]:
        visiting: Set[str] = set()
        visited: Set[str] = set()
        order: List[str] = []

        def visit(node: str) -> None:
            if node in visited:
                return
            if node in visiting:
                raise WorkspaceError(f"Cyclic module dependency detected at {node}")
            visiting.add(node)
            for dep in graph.get(node, []):
                visit(dep)
            visiting.remove(node)
            visited.add(node)
            order.append(node)

        for node in sorted(graph):
            visit(node)
        return order

    def build_workspace(self, workspace: str | Path) -> WorkspaceBuildResult:
        started = time.perf_counter()
        manifest = self.load_manifest(workspace)
        modules = self.resolve_modules(workspace)
        graph = self.dependency_graph(modules)
        order = self.build_order(graph)
        by_name = {m.name: m for m in modules}
        root = Path(workspace)
        base = root.parent if root.is_file() else root
        diagnostics: List[str] = []
        artifacts: Dict[str, Any] = {"modules": {}, "manifest": manifest.to_dict()}
        source_count = 0
        for module_name in order:
            module = by_name[module_name]
            source_count += len(module.sources)
            module_root = base / module.root
            if self.compiler is not None:
                result = self.compiler.build(module_root)
                artifacts["modules"][module_name] = result.to_dict() if hasattr(result, "to_dict") else str(result)
            else:
                artifacts["modules"][module_name] = {"compiled": module.sources, "compiler": "workspace-manifest-only"}
            diagnostics.append(f"built module {module_name} with {len(module.sources)} source(s)")
        duration_ms = round((time.perf_counter() - started) * 1000, 3)
        result = WorkspaceBuildResult(
            ok=True,
            phase=self.phase,
            version=self.version,
            workspace=str(Path(workspace)),
            build_order=order,
            modules_built=order,
            module_count=len(modules),
            source_count=source_count,
            diagnostics=diagnostics,
            artifacts=artifacts,
            duration_ms=duration_ms,
        )
        out = self.cache_dir / "last_workspace_build.json"
        out.write_text(result.to_json(), encoding="utf-8")
        return result

    def validate_workspace(self, workspace: str | Path) -> Dict[str, Any]:
        modules = self.resolve_modules(workspace)
        graph = self.dependency_graph(modules)
        order = self.build_order(graph)
        return {
            "ok": True,
            "phase": self.phase,
            "version": self.version,
            "modules": [asdict(m) for m in modules],
            "graph": graph,
            "build_order": order,
            "external_api_used": False,
            "network_required": False,
        }
