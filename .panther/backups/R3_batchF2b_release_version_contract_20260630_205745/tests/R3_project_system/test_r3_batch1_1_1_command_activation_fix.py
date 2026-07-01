import json
from pathlib import Path

REQUIRED_COMMANDS = [
    "pantherlang.newProject",
    "pantherlang.newConsoleProject",
    "pantherlang.newWebProject",
    "pantherlang.newApiProject",
    "pantherlang.newAiProject",
    "pantherlang.runCurrentFile",
    "pantherlang.runFile",
    "pantherlang.buildProject",
    "pantherlang.debugProject",
    "pantherlang.doctor",
    "pantherlang.openAgentGuide",
]

def test_package_json_declares_all_commands_and_activation_events():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}
    activation = set(pkg.get("activationEvents", []))
    for command in REQUIRED_COMMANDS:
        assert command in commands
        assert f"onCommand:{command}" in activation
    assert pkg["version"] == "1.1.2"
    assert pkg["main"] == "./out/extension.js"

def test_extension_js_registers_all_commands():
    text = Path("vscode-extension/src/extension.js").read_text()
    for command in REQUIRED_COMMANDS:
        assert command in text
    assert "registerCommand" in text
    assert "PantherLang 1.1.2 activated" in text

def test_out_extension_matches_runtime_source():
    assert Path("vscode-extension/src/extension.js").read_text() == Path("vscode-extension/out/extension.js").read_text()
