from pathlib import Path
import json
import subprocess
import sys

from tools.project_wizard.wizard import create_project
from tools.project_runner.runner import build_project


def test_r3_batch1_final_full_project_cycle(tmp_path):
    result = create_project("final-cycle", "console", tmp_path)
    project = result.destination

    assert (project / "README.md").exists()
    assert (project / ".vscode" / "tasks.json").exists()
    assert (project / ".vscode" / "launch.json").exists()

    build = build_project(project)
    assert build.ok is True
    assert build.artifact.exists()

    debug = subprocess.run(
        [
            sys.executable,
            "tools/project_runner/panther_debug.py",
            "--project",
            str(project),
            "--json",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    data = json.loads(debug.stdout)
    assert data["ok"] is True
    assert data["stage"] == "r3_debug_launch_scaffold"


def test_r3_batch1_final_vscode_commands_present():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}

    required = {
        "pantherlang.newProject",
        "pantherlang.runFile",
        "pantherlang.buildProject",
        "pantherlang.debugProject",
        "pantherlang.openAgentGuide",
        "pantherlang.doctor",
    }
    assert required.issubset(commands)
    assert pkg["version"] >= "1.1.0"


def test_r3_batch1_final_agent_docs_present():
    assert Path("docs/agent_knowledge/PANTHERLANG_AGENT_GUIDE.md").exists()
    assert Path(".github/copilot/instructions.md").exists()
