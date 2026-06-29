from __future__ import annotations
from pathlib import Path
import json
import pytest
from language.compiler.incremental import IncrementalBuildError, IncrementalCompiler

ALPHA = '''
app Alpha { version "0.6.2" }
model User { id: int required name: string }
'''
BETA = '''
agent Worker { purpose "Incremental test" memory local tools compiler }
'''

def write_workspace(tmp_path: Path) -> Path:
    ws = tmp_path / "ws"
    ws.mkdir()
    (ws / "alpha.panther").write_text(ALPHA, encoding="utf-8")
    (ws / "beta.panther").write_text(BETA, encoding="utf-8")
    return ws

def test_first_build_compiles_all_sources(tmp_path: Path):
    ws = write_workspace(tmp_path)
    result = IncrementalCompiler(cache_dir=tmp_path / "cache").build(ws)
    assert result.ok is True
    assert result.phase == "6.2"
    assert result.version == "0.6.2-incremental-compilation"
    assert sorted(result.compiled) == ["alpha.panther", "beta.panther"]
    assert result.reused == []
    assert result.external_api_used is False
    assert result.network_required is False


def test_second_build_reuses_unchanged_sources(tmp_path: Path):
    ws = write_workspace(tmp_path)
    compiler = IncrementalCompiler(cache_dir=tmp_path / "cache")
    compiler.build(ws)
    second = compiler.build(ws)
    assert second.compiled == []
    assert sorted(second.reused) == ["alpha.panther", "beta.panther"]
    assert second.plan.cache_hit_ratio == 1.0


def test_edit_rebuilds_only_changed_file(tmp_path: Path):
    ws = write_workspace(tmp_path)
    compiler = IncrementalCompiler(cache_dir=tmp_path / "cache")
    compiler.build(ws)
    (ws / "beta.panther").write_text(BETA + "\nmodel Extra { id: int required }\n", encoding="utf-8")
    result = compiler.build(ws)
    assert result.compiled == ["beta.panther"]
    assert result.reused == ["alpha.panther"]


def test_removed_file_is_recorded(tmp_path: Path):
    ws = write_workspace(tmp_path)
    compiler = IncrementalCompiler(cache_dir=tmp_path / "cache")
    compiler.build(ws)
    (ws / "alpha.panther").unlink()
    result = compiler.build(ws)
    assert result.removed == ["alpha.panther"]
    assert "alpha.panther" not in result.artifacts


def test_negative_missing_workspace(tmp_path: Path):
    with pytest.raises(IncrementalBuildError):
        IncrementalCompiler(cache_dir=tmp_path / "cache").build(tmp_path / "missing")


def test_negative_empty_source(tmp_path: Path):
    ws = tmp_path / "ws"
    ws.mkdir()
    (ws / "empty.panther").write_text("   \n", encoding="utf-8")
    with pytest.raises(IncrementalBuildError):
        IncrementalCompiler(cache_dir=tmp_path / "cache").build(ws)


def test_negative_blocked_marker(tmp_path: Path):
    ws = tmp_path / "ws"
    ws.mkdir()
    (ws / "bad.panther").write_text("panic_incremental_compiler", encoding="utf-8")
    with pytest.raises(IncrementalBuildError):
        IncrementalCompiler(cache_dir=tmp_path / "cache").build(ws)


def test_report_json_serializable(tmp_path: Path):
    ws = write_workspace(tmp_path)
    result = IncrementalCompiler(cache_dir=tmp_path / "cache").build(ws)
    data = json.loads(result.to_json())
    assert data["ok"] is True
    assert data["plan"]["total_sources"] == 2


def test_stress_many_files_incremental(tmp_path: Path):
    ws = tmp_path / "stress"
    ws.mkdir()
    for i in range(75):
        (ws / f"m{i}.panther").write_text(f"model M{i} {{ id: int required }}\n", encoding="utf-8")
    compiler = IncrementalCompiler(cache_dir=tmp_path / "cache")
    first = compiler.build(ws)
    second = compiler.build(ws)
    assert len(first.compiled) == 75
    assert second.compiled == []
    assert len(second.reused) == 75
