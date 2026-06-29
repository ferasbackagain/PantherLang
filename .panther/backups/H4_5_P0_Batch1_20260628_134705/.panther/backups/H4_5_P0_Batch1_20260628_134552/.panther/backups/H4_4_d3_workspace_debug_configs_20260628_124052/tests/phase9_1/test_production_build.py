from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_project_local_build(tmp_path: Path) -> None:
    project_name = "App"
    project = tmp_path / project_name
    subprocess.run([str(ROOT / "panther"), "new", "console", project_name], cwd=tmp_path, check=True)
    proc = subprocess.run([str(ROOT / "panther"), "build"], cwd=project, text=True, capture_output=True)
    assert proc.returncode == 0
    assert (project / "build" / "main.sh").exists()
    assert (project / "build" / "build_manifest.json").exists()
    manifest = json.loads((project / "build" / "build_manifest.json").read_text())
    assert manifest["phase"] == "9.1"
    assert manifest["local_build_output"] is True
