from pathlib import Path
import json
import subprocess
import sys

from tools.project_wizard.wizard import create_project


def test_debug_helper_json_output(tmp_path):
    result = create_project("debug-demo", "console", tmp_path)
    proc = subprocess.run(
        [
            sys.executable,
            "tools/project_runner/panther_debug.py",
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
    assert data["project"] == "debug-demo"
    assert data["stage"] == "r3_debug_launch_scaffold"


def test_vscode_debug_command_registered():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}
    assert "pantherlang.debugProject" in commands
    assert pkg["version"] >= "1.0.6"
    assert any(d.get("type") == "pantherlang" for d in pkg["contributes"].get("debuggers", []))


def test_debug_command_implementation_contains_start_debugging():
    text = Path("vscode-extension/src/debug_command.js").read_text()
    assert "startDebugging" in text
    assert "panther_debug.py" in text
    assert "pantherlang" in text


def test_templates_have_debug_launch_config():
    for launch in Path("project_templates").glob("*/.vscode/launch.json"):
        data = json.loads(launch.read_text())
        cfg = data["configurations"][0]
        assert cfg["type"] == "pantherlang"
        assert cfg["program"] == "${workspaceFolder}/src/main.panther"
