from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import json
import re


@dataclass(frozen=True)
class ProjectManifest:
    root: Path
    name: str
    kind: str
    main: Path


@dataclass(frozen=True)
class BuildResult:
    ok: bool
    project: str
    output_dir: Path
    artifact: Path
    files_written: int


def _extract_toml_string(text: str, key: str, default: str = "") -> str:
    match = re.search(rf"^\s*{re.escape(key)}\s*=\s*\"([^\"]*)\"", text, re.MULTILINE)
    return match.group(1) if match else default


def read_project_manifest(project_root: str | Path = ".") -> ProjectManifest:
    root = Path(project_root).resolve()
    manifest = root / "panther.toml"
    if not manifest.exists():
        raise FileNotFoundError(f"panther.toml not found in {root}")

    text = manifest.read_text(encoding="utf-8")
    name = _extract_toml_string(text, "name", root.name)
    kind = _extract_toml_string(text, "type", "console")
    main_raw = _extract_toml_string(text, "main", "src/main.panther")
    main = (root / main_raw).resolve()

    return ProjectManifest(root=root, name=name, kind=kind, main=main)


def build_project(project_root: str | Path = ".", output_dir: str | Path | None = None) -> BuildResult:
    manifest = read_project_manifest(project_root)
    if not manifest.main.exists():
        raise FileNotFoundError(f"main PantherLang file not found: {manifest.main}")

    out_dir = Path(output_dir).resolve() if output_dir else manifest.root / "build"
    out_dir.mkdir(parents=True, exist_ok=True)

    source = manifest.main.read_text(encoding="utf-8")
    artifact = out_dir / f"{manifest.name}.build.json"
    artifact.write_text(json.dumps({
        "ok": True,
        "project": manifest.name,
        "type": manifest.kind,
        "main": manifest.main.relative_to(manifest.root).as_posix(),
        "source_bytes": len(source.encode("utf-8")),
        "stage": "r3_build_scaffold",
        "note": "Compiler backend integration comes next; this artifact validates project build wiring."
    }, indent=2), encoding="utf-8")

    return BuildResult(ok=True, project=manifest.name, output_dir=out_dir, artifact=artifact, files_written=1)


def run_project(project_root: str | Path = ".") -> str:
    result = build_project(project_root)
    return f"PantherLang run scaffold OK: {result.project} -> {result.artifact}"
