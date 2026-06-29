import json
from pathlib import Path

PACKAGE_JSON = Path("./vscode-extension/package.json")
EXT_DIR = PACKAGE_JSON.parent


def _json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def test_h44_d4_debug_flow_files_exist():
    assert (EXT_DIR / "src" / "debugFlow.ts").exists()
    assert (EXT_DIR / "out" / "debugFlow.js").exists()
    assert (EXT_DIR / "out" / "extension.js").exists()


def test_h44_d4_debug_flow_exports_f5_helpers():
    js = (EXT_DIR / "out" / "debugFlow.js").read_text(encoding="utf-8")

    assert "createPantherF5DebugConfiguration" in js
    assert "startPantherF5Debug" in js
    assert "PantherLang: F5 Debug Current File" in js
    assert "type: \"panther\"" in js or 'type: "panther"' in js
    assert "preLaunchTask" in js


def test_h44_d4_extension_registers_f5_command_flow():
    js = (EXT_DIR / "out" / "extension.js").read_text(encoding="utf-8")

    assert 'require("./debugFlow")' in js
    assert "panther.debug.start" in js
    assert "startPantherF5Debug" in js
    assert "provideDebugConfigurations" in js
    assert "PantherLang: F5 Debug Current File" in js


def test_h44_d4_workspace_launch_has_f5_configuration():
    launch = _json(".vscode/launch.json")
    configs = launch["configurations"]
    names = {config["name"]: config for config in configs}

    assert "PantherLang: F5 Debug Current File" in names

    config = names["PantherLang: F5 Debug Current File"]
    assert config["type"] == "panther"
    assert config["request"] == "launch"
    assert config["program"] == "${file}"
    assert config["preLaunchTask"] == "PantherLang: Check"
    assert config["stopOnEntry"] is True
    assert config["dryRun"] is True


def test_h44_d4_workspace_tasks_keep_compatibility_order():
    tasks = _json(".vscode/tasks.json")["tasks"]

    assert tasks[0]["label"] == "PantherLang: Check"
    assert tasks[0]["command"] == "Panther"
    assert tasks[0]["args"] == ["check", "${file}"]

    labels = {task["label"] for task in tasks}
    assert "PantherLang: Check Current File" in labels
    assert "PantherLang: Check Example" in labels
    assert "PantherLang: Run Current File" in labels


def test_h44_d4_example_program_exists():
    assert Path("examples/hello.pan").exists()
