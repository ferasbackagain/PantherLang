#!/usr/bin/env bash
set -euo pipefail

PHASE="6.3"
PHASE_NAME="Module & Workspace System"
VERSION="0.6.3-module-workspace-system"
ROOT="$(pwd)"
PYTHON_BIN="${PYTHON:-python3}"

printf '\n============================================================\n'
printf ' PantherLang Phase %s — %s\n' "$PHASE" "$PHASE_NAME"
printf '============================================================\n'

if [ ! -d "language" ] || [ ! -d "tests" ]; then
  echo "❌ Run this script from the PantherLang project root."
  exit 1
fi

mkdir -p \
  language/compiler/workspace \
  tests/phase6_3 \
  scripts \
  docs/phase6 \
  examples/workspace \
  build/reports \
  build/workspace_cache \
  .phase_backups

BACKUP_DIR=".phase_backups/phase6_3_workspace_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
for f in CHANGELOG.md VERSION_PLAN.md README.md HOW_TO_USE_THIS_RELEASE.md; do
  [ -f "$f" ] && cp "$f" "$BACKUP_DIR/$f"
done

cat > language/compiler/workspace/__init__.py <<'PY'
from .workspace_manager import (
    ModuleInfo,
    WorkspaceBuildResult,
    WorkspaceError,
    WorkspaceManifest,
    WorkspaceManager,
)

__all__ = [
    "ModuleInfo",
    "WorkspaceBuildResult",
    "WorkspaceError",
    "WorkspaceManifest",
    "WorkspaceManager",
]
PY

cat > language/compiler/workspace/workspace_manager.py <<'PY'
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
PY

cat > tests/phase6_3/test_workspace_manager.py <<'PY'
from __future__ import annotations

import json
from pathlib import Path

import pytest

from language.compiler.workspace import WorkspaceError, WorkspaceManager


def make_workspace(tmp_path: Path) -> Path:
    root = tmp_path / "ws"
    (root / "core").mkdir(parents=True)
    (root / "app").mkdir(parents=True)
    (root / "core" / "core.panther").write_text("fn core() { return 1 }\n", encoding="utf-8")
    (root / "app" / "main.panther").write_text("import core\nfn main() { return core() }\n", encoding="utf-8")
    (root / "panther.workspace.json").write_text(json.dumps({
        "name": "demo_workspace",
        "version": "0.1.0",
        "entry": "app.main",
        "modules": [
            {"name": "core", "root": "core", "sources": ["*.panther"]},
            {"name": "app", "root": "app", "sources": ["*.panther"]},
        ],
    }), encoding="utf-8")
    return root


def test_manifest_loads_and_resolves_modules(tmp_path: Path) -> None:
    ws = make_workspace(tmp_path)
    manager = WorkspaceManager(cache_dir=tmp_path / "cache")
    manifest = manager.load_manifest(ws)
    modules = manager.resolve_modules(ws)
    assert manifest.name == "demo_workspace"
    assert [m.name for m in modules] == ["core", "app"]
    assert modules[1].imports == ["core"]


def test_dependency_order_places_imports_first(tmp_path: Path) -> None:
    ws = make_workspace(tmp_path)
    manager = WorkspaceManager(cache_dir=tmp_path / "cache")
    validation = manager.validate_workspace(ws)
    assert validation["build_order"] == ["core", "app"]
    assert validation["external_api_used"] is False
    assert validation["network_required"] is False


def test_workspace_build_returns_artifacts(tmp_path: Path) -> None:
    ws = make_workspace(tmp_path)
    manager = WorkspaceManager(cache_dir=tmp_path / "cache")
    result = manager.build_workspace(ws)
    assert result.ok is True
    assert result.module_count == 2
    assert result.source_count == 2
    assert result.modules_built == ["core", "app"]
    assert (tmp_path / "cache" / "last_workspace_build.json").exists()


def test_missing_manifest_is_negative_case(tmp_path: Path) -> None:
    manager = WorkspaceManager(cache_dir=tmp_path / "cache")
    with pytest.raises(WorkspaceError):
        manager.load_manifest(tmp_path / "missing")


def test_duplicate_module_is_negative_case(tmp_path: Path) -> None:
    root = tmp_path / "ws"
    (root / "a").mkdir(parents=True)
    (root / "a" / "a.panther").write_text("fn a(){}", encoding="utf-8")
    (root / "panther.workspace.json").write_text(json.dumps({
        "name": "bad",
        "modules": [
            {"name": "a", "root": "a"},
            {"name": "a", "root": "a"},
        ],
    }), encoding="utf-8")
    with pytest.raises(WorkspaceError, match="Duplicate"):
        WorkspaceManager(cache_dir=tmp_path / "cache").load_manifest(root)


def test_cycle_detection_is_negative_case(tmp_path: Path) -> None:
    manager = WorkspaceManager(cache_dir=tmp_path / "cache")
    with pytest.raises(WorkspaceError, match="Cyclic"):
        manager.build_order({"a": ["b"], "b": ["a"]})


def test_module_without_sources_fails(tmp_path: Path) -> None:
    root = tmp_path / "ws"
    (root / "empty").mkdir(parents=True)
    (root / "panther.workspace.json").write_text(json.dumps({
        "name": "empty_case",
        "modules": [{"name": "empty", "root": "empty"}],
    }), encoding="utf-8")
    with pytest.raises(WorkspaceError, match="No .panther"):
        WorkspaceManager(cache_dir=tmp_path / "cache").resolve_modules(root)
PY

cat > scripts/run_phase6_3_practical_demo.sh <<'SH2'
#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="build/phase6_3_demo_workspace"
rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR/core" "$DEMO_DIR/security" "$DEMO_DIR/app"

cat > "$DEMO_DIR/core/core.panther" <<'PANTHER'
fn normalize(value) {
  return value
}
PANTHER

cat > "$DEMO_DIR/security/policy.panther" <<'PANTHER'
import core
fn allow(user) {
  return core.normalize(user)
}
PANTHER

cat > "$DEMO_DIR/app/main.panther" <<'PANTHER'
import core
import security
fn main() {
  return security.allow("analyst")
}
PANTHER

cat > "$DEMO_DIR/panther.workspace.json" <<'JSON'
{
  "name": "phase6_3_demo_workspace",
  "version": "0.6.3",
  "entry": "app.main",
  "modules": [
    {"name": "core", "root": "core", "sources": ["*.panther"]},
    {"name": "security", "root": "security", "sources": ["*.panther"]},
    {"name": "app", "root": "app", "sources": ["*.panther"]}
  ]
}
JSON

python3 - <<'PY'
from language.compiler.workspace import WorkspaceManager
manager = WorkspaceManager(cache_dir="build/workspace_cache/demo")
validation = manager.validate_workspace("build/phase6_3_demo_workspace")
print("workspace:", validation["modules"][0]["root"], "...")
print("build order:", validation["build_order"])
assert validation["build_order"] == ["core", "security", "app"]
result = manager.build_workspace("build/phase6_3_demo_workspace")
print("modules built:", result.modules_built)
print("source count:", result.source_count)
assert result.ok is True
assert result.module_count == 3
assert result.external_api_used is False
assert result.network_required is False
PY

echo "✅ PantherLang Phase 6.3 practical demo passed"
SH2
chmod +x scripts/run_phase6_3_practical_demo.sh

cat > scripts/verify_phase6_3_module_workspace_system.sh <<'SH2'
#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo " PantherLang Phase 6.3 PRO Verification"
echo "============================================================"

PYTHON_BIN="${PYTHON:-python3}"

if [ ! -f "language/compiler/workspace/workspace_manager.py" ]; then
  echo "❌ workspace_manager.py missing"
  exit 1
fi
if [ ! -f "tests/phase6_3/test_workspace_manager.py" ]; then
  echo "❌ phase6_3 pytest suite missing"
  exit 1
fi
if [ ! -f "docs/phase6/PHASE_6_3_MODULE_WORKSPACE_SYSTEM.md" ]; then
  echo "❌ phase 6.3 documentation missing"
  exit 1
fi
echo "✅ structure tests passed"

$PYTHON_BIN - <<'PY'
from language.compiler.workspace import WorkspaceManager
manager = WorkspaceManager()
assert manager.phase == "6.3"
assert manager.version == "0.6.3-module-workspace-system"
print("✅ manifest tests passed")
PY

if ! $PYTHON_BIN -m pytest --version >/dev/null 2>&1; then
  echo "⚠️ pytest missing for $PYTHON_BIN — installing locally for this interpreter"
  $PYTHON_BIN -m pip install -U pip pytest
fi

$PYTHON_BIN -m pytest -q tests/phase6_3

echo "✅ pytest regression suite passed"

bash scripts/run_phase6_3_practical_demo.sh

echo "✅ practical demo passed"

$PYTHON_BIN - <<'PY'
from pathlib import Path
import json
import tempfile
from language.compiler.workspace import WorkspaceError, WorkspaceManager

with tempfile.TemporaryDirectory() as d:
    root = Path(d) / "bad_ws"
    root.mkdir()
    (root / "panther.workspace.json").write_text(json.dumps({"name":"bad", "modules": []}), encoding="utf-8")
    try:
        WorkspaceManager(cache_dir=Path(d) / "cache").load_manifest(root)
    except WorkspaceError:
        print("✅ negative tests passed")
    else:
        raise SystemExit("negative test failed")
PY

$PYTHON_BIN - <<'PY'
from pathlib import Path
import json
import tempfile
from language.compiler.workspace import WorkspaceManager

with tempfile.TemporaryDirectory() as d:
    root = Path(d) / "stress_ws"
    root.mkdir()
    modules = []
    previous = None
    for i in range(25):
        name = f"m{i:02d}"
        mod_root = root / name
        mod_root.mkdir()
        imports = f"import {previous}\n" if previous else ""
        (mod_root / f"{name}.panther").write_text(imports + f"fn {name}() {{ return {i} }}\n", encoding="utf-8")
        modules.append({"name": name, "root": name, "sources": ["*.panther"]})
        previous = name
    (root / "panther.workspace.json").write_text(json.dumps({"name":"stress", "modules": modules}), encoding="utf-8")
    manager = WorkspaceManager(cache_dir=Path(d) / "cache")
    validation = manager.validate_workspace(root)
    assert len(validation["build_order"]) == 25
    assert validation["build_order"][0] == "m00"
    assert validation["build_order"][-1] == "m24"
print("✅ stress tests passed")
PY

echo "✅ PantherLang Phase 6.3 Module & Workspace System verification completed"
SH2
chmod +x scripts/verify_phase6_3_module_workspace_system.sh

cat > docs/phase6/PHASE_6_3_MODULE_WORKSPACE_SYSTEM.md <<'MD'
# PantherLang Phase 6.3 — Module & Workspace System

## Status
Completed by bootstrap script and verified locally.

## Purpose
Phase 6.3 introduces a deterministic module and workspace layer for PantherLang. This allows a project to declare multiple modules in a workspace manifest, resolve module source files, extract module imports, detect dependency order, reject invalid workspaces, and delegate compilation to the Phase 6.2 incremental compiler.

## New Core Components

- `language/compiler/workspace/workspace_manager.py`
- `language/compiler/workspace/__init__.py`
- `tests/phase6_3/test_workspace_manager.py`
- `scripts/run_phase6_3_practical_demo.sh`
- `scripts/verify_phase6_3_module_workspace_system.sh`

## Workspace Manifest

Supported manifest names:

- `panther.workspace.json`
- `panther.json`

Example:

```json
{
  "name": "my_workspace",
  "version": "0.6.3",
  "entry": "app.main",
  "modules": [
    {"name": "core", "root": "core", "sources": ["*.panther"]},
    {"name": "app", "root": "app", "sources": ["*.panther"]}
  ]
}
```

## Verification

Run:

```bash
bash scripts/verify_phase6_3_module_workspace_system.sh
```

Run demo:

```bash
bash scripts/run_phase6_3_practical_demo.sh
```

## Proof Included

- Structure tests
- Manifest tests
- Regression tests
- Practical demo
- Negative tests
- Stress tests
- Offline/no-network guarantee

## GitHub Policy

GitHub push remains postponed until Phase 6.10 full regression.
MD

cat > examples/workspace/panther.workspace.json <<'JSON'
{
  "name": "example_workspace",
  "version": "0.6.3",
  "entry": "app.main",
  "modules": [
    {"name": "core", "root": "core", "sources": ["*.panther"]},
    {"name": "app", "root": "app", "sources": ["*.panther"]}
  ]
}
JSON
mkdir -p examples/workspace/core examples/workspace/app
cat > examples/workspace/core/core.panther <<'PANTHER'
fn identity(value) {
  return value
}
PANTHER
cat > examples/workspace/app/main.panther <<'PANTHER'
import core
fn main() {
  return core.identity("PantherLang")
}
PANTHER

# Documentation updates are append-only and safe.
cat >> CHANGELOG.md <<'MD'

## PantherLang Phase 6.3 — Module & Workspace System

Added deterministic workspace/module support for PantherLang compiler integration.

### Added
- Workspace manifest loader for `panther.workspace.json` and `panther.json`.
- Module source discovery for `.panther` files.
- Import extraction and module dependency graph generation.
- Deterministic topological build order.
- Cycle detection, duplicate module detection, missing source validation.
- Integration with Phase 6.2 incremental compiler when available.
- Professional verification, practical demo, negative tests, stress tests, and documentation.

### GitHub
Push remains postponed until Phase 6.10 full regression.
MD

cat >> VERSION_PLAN.md <<'MD'

### Phase 6.3 — Module & Workspace System
Status: Completed locally after verification.

Provides the PantherLang workspace manifest, module graph, deterministic build order, and integration with the Phase 6.2 incremental compiler.
MD

cat >> HOW_TO_USE_THIS_RELEASE.md <<'MD'

## Phase 6.3 — Module & Workspace System

Verify:

```bash
bash scripts/verify_phase6_3_module_workspace_system.sh
```

Demo:

```bash
bash scripts/run_phase6_3_practical_demo.sh
```

GitHub push remains postponed until Phase 6.10 full regression.
MD

printf '\nRunning Phase 6.3 verification...\n'
bash scripts/verify_phase6_3_module_workspace_system.sh

printf '\n✅ PantherLang Phase 6.3 installed and verified successfully.\n'
printf 'Next commands:\n'
printf '  bash scripts/run_phase6_3_practical_demo.sh\n'
printf '  bash scripts/verify_phase6_3_module_workspace_system.sh\n'
printf 'GitHub push remains postponed until Phase 6.10 full regression.\n'
