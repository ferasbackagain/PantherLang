import json
from pathlib import Path

ROOT = Path(".")
EXT_DIR = Path("./vscode-extension")


def _json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def test_h44_d3_workspace_launch_json_exists_and_is_valid():
    path = ROOT / ".vscode" / "launch.json"
    assert path.exists()

    data = _json(path)
    assert data["version"] == "0.2.0"
    assert len(data["configurations"]) >= 2


def test_h44_d3_current_file_debug_config_is_panther():
    data = _json(ROOT / ".vscode" / "launch.json")
    config = data["configurations"][0]

    assert config["name"] == "PantherLang: Debug Current File"
    assert config["type"] == "panther"
    assert config["request"] == "launch"
    assert config["program"] == "${file}"
    assert config["cwd"] == "${workspaceFolder}"
    assert config["dryRun"] is True
    assert config["preLaunchTask"] == "PantherLang: Check Current File"


def test_h44_d3_example_debug_config_is_panther():
    data = _json(ROOT / ".vscode" / "launch.json")
    config = data["configurations"][1]

    assert config["name"] == "PantherLang: Debug Example hello.pan"
    assert config["type"] == "panther"
    assert config["program"].endswith("/examples/hello.pan")
    assert config["preLaunchTask"] == "PantherLang: Check Example"


def test_h44_d3_workspace_tasks_json_exists_and_has_panther_tasks():
    data = _json(ROOT / ".vscode" / "tasks.json")
    labels = {task["label"]: task for task in data["tasks"]}

    assert "PantherLang: Check Current File" in labels
    assert "PantherLang: Check Example" in labels
    assert "PantherLang: Run Current File" in labels

    assert labels["PantherLang: Check Current File"]["command"] == "Panther"
    assert labels["PantherLang: Check Current File"]["args"] == ["check", "${file}"]

    assert labels["PantherLang: Run Current File"]["args"] == ["run", "${file}"]


def test_h44_d3_workspace_settings_associate_panther_extensions():
    data = _json(ROOT / ".vscode" / "settings.json")
    assoc = data["files.associations"]

    assert assoc["*.pan"] == "panther"
    assert assoc["*.panther"] == "panther"
    assert data["debug.allowBreakpointsEverywhere"] is True


def test_h44_d3_extension_sample_configs_synced():
    assert (EXT_DIR / ".vscode" / "launch.json").exists()
    assert (EXT_DIR / ".vscode" / "tasks.json").exists()

    root_launch = _json(ROOT / ".vscode" / "launch.json")
    ext_launch = _json(EXT_DIR / ".vscode" / "launch.json")

    assert root_launch == ext_launch
