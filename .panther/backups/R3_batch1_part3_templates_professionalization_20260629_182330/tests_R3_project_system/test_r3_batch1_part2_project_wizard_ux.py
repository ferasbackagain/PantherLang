import json
from pathlib import Path

from tools.project_wizard.wizard import template_metadata


def test_template_metadata_for_vscode_quickpick():
    metadata = template_metadata()
    ids = [x["id"] for x in metadata]
    assert ids == ["console", "web", "api", "ai"]
    for item in metadata:
        assert item["label"]
        assert item["description"]


def test_vscode_extension_registers_project_wizard_commands():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}
    assert "pantherlang.newProject" in commands
    assert "pantherlang.newConsoleProject" in commands
    assert "pantherlang.newWebProject" in commands
    assert "pantherlang.newApiProject" in commands
    assert "pantherlang.newAiProject" in commands
    assert pkg["version"] == "1.0.2"


def test_extension_implementation_contains_ux_flow():
    text = Path("vscode-extension/src/extension.js").read_text()
    assert "showQuickPick" in text
    assert "showInputBox" in text
    assert "showOpenDialog" in text
    assert "withProgress" in text
    assert "Open Project" in text
