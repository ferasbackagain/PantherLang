import json
from pathlib import Path

PACKAGE_JSON = Path("vscode-extension/package.json")
EXT_DIR = PACKAGE_JSON.parent


def test_h44_d1_package_json_exists_and_is_valid_json():
    assert PACKAGE_JSON.exists()
    data = json.loads(PACKAGE_JSON.read_text(encoding="utf-8"))
    assert isinstance(data, dict)


def test_h44_d1_debugger_contribution_exists():
    data = json.loads(PACKAGE_JSON.read_text(encoding="utf-8"))
    debuggers = data.get("contributes", {}).get("debuggers", [])
    panther = [item for item in debuggers if item.get("type") == "panther"]

    assert len(panther) == 1
    dbg = panther[0]

    assert dbg["label"] == "PantherLang Debug"
    assert "panther" in dbg["languages"]
    assert "pantherlang" in dbg["languages"]
    assert dbg["configurationAttributes"]["launch"]["properties"]["program"]["type"] == "string"


def test_h44_d1_activation_events_exist():
    data = json.loads(PACKAGE_JSON.read_text(encoding="utf-8"))
    events = set(data.get("activationEvents", []))

    assert "onDebug" in events
    assert "onDebugResolve:panther" in events
    assert "onDebugInitialConfigurations" in events


def test_h44_d1_language_contribution_exists():
    data = json.loads(PACKAGE_JSON.read_text(encoding="utf-8"))
    languages = data.get("contributes", {}).get("languages", [])
    panther = [item for item in languages if item.get("id") == "panther"]

    assert len(panther) == 1
    assert ".pan" in panther[0]["extensions"]
    assert ".panther" in panther[0]["extensions"]


def test_h44_d1_command_contribution_exists():
    data = json.loads(PACKAGE_JSON.read_text(encoding="utf-8"))
    commands = data.get("contributes", {}).get("commands", [])

    assert any(cmd.get("command") == "panther.debug.start" for cmd in commands)


def test_h44_d1_vscode_launch_and_tasks_exist():
    launch = EXT_DIR / ".vscode" / "launch.json"
    tasks = EXT_DIR / ".vscode" / "tasks.json"

    assert launch.exists()
    assert tasks.exists()

    launch_data = json.loads(launch.read_text(encoding="utf-8"))
    tasks_data = json.loads(tasks.read_text(encoding="utf-8"))

    config = launch_data["configurations"][0]
    assert config["type"] == "panther"
    assert config["request"] == "launch"
    assert config["dryRun"] is True

    task = tasks_data["tasks"][0]
    assert task["label"] == "PantherLang: Check"
    assert task["command"] == "Panther"
