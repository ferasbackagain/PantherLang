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
