from pathlib import Path
import json
import subprocess
import sys

from tools.project_wizard.wizard import create_project
from tools.project_runner.runner import build_project, read_project_manifest


def test_build_runner_creates_artifact(tmp_path):
    result = create_project("build-demo", "console", tmp_path)
    build = build_project(result.destination)
    assert build.ok is True
    assert build.artifact.exists()
    data = json.loads(build.artifact.read_text())
    assert data["project"] == "build-demo"
    assert data["stage"] == "r3_build_scaffold"


def test_build_cli_json_output(tmp_path):
    result = create_project("build-cli-demo", "api", tmp_path)
    proc = subprocess.run(
        [
            sys.executable,
            "tools/project_runner/panther_build.py",
            "--project",
            str(result.destination),
            "--json",
        ],
        text=True,
        capture_output=True,
        check=True,
    )
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["project"] == "build-cli-demo"
    assert Path(data["artifact"]).exists()


def test_vscode_build_command_registered():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}
    assert "pantherlang.buildProject" in commands
    assert pkg["version"] == "1.0.5"
    src = Path("vscode-extension/src/build_command.js").read_text()
    assert "panther_build.py" in src
    assert "Building PantherLang project" in src
