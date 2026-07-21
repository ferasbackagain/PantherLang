import json
import zipfile
from pathlib import Path

PACKAGE_JSON = Path("./vscode-extension/package.json")
EXT_DIR = PACKAGE_JSON.parent
PACKAGE_ARTIFACT = Path("./vscode-extension/dist/pantherlang-official-2.0.0.vsix")


def _package():
    return json.loads(PACKAGE_JSON.read_text(encoding="utf-8"))


def test_h44_d5_package_metadata_is_valid():
    data = _package()

    assert data["name"]
    assert data["displayName"] == "PantherLang Official"
    assert data["main"] == "./out/extension.js"
    assert "engines" in data
    assert "vscode" in data["engines"]
    assert "Debuggers" in data["categories"]


def test_h44_d5_required_runtime_files_exist():
    required = [
        EXT_DIR / "out" / "extension.js",
        EXT_DIR / "out" / "debugFlow.js",
        EXT_DIR / "src" / "extension.ts",
        EXT_DIR / "src" / "debugFlow.ts",
        EXT_DIR / "package.json",
        EXT_DIR / "language-configuration.json",
        EXT_DIR / ".vscode" / "launch.json",
        EXT_DIR / ".vscode" / "tasks.json",
    ]

    for item in required:
        assert item.exists(), f"Missing extension runtime file: {item}"


def test_h44_d5_package_json_contributes_debugger_and_language():
    data = _package()
    contributes = data.get("contributes", {})

    debuggers = contributes.get("debuggers", [])
    panther_debuggers = [item for item in debuggers if item.get("type") == "panther"]

    assert len(panther_debuggers) == 1
    assert panther_debuggers[0]["label"] == "PantherLang Debug"

    languages = contributes.get("languages", [])
    panther_languages = [item for item in languages if item.get("id") == "panther"]

    assert len(panther_languages) == 1
    assert ".pan" in panther_languages[0]["extensions"]
    assert ".panther" in panther_languages[0]["extensions"]


def test_h44_d5_package_artifact_exists_and_is_zip():
    assert PACKAGE_ARTIFACT.exists()
    assert PACKAGE_ARTIFACT.stat().st_size > 0

    with zipfile.ZipFile(PACKAGE_ARTIFACT, "r") as archive:
        names = set(archive.namelist())

    has_entry = lambda p: p in names or f"extension/{p}" in names
    assert has_entry("package.json"), f"package.json not found in {sorted(names)}"
    assert has_entry("out/extension.js")
    assert has_entry("out/debugFlow.js")
    assert has_entry("src/extension.ts")
    assert has_entry("src/debugFlow.ts")


def test_h44_d5_no_missing_core_debug_adapter_dependency():
    assert Path("debug_adapter/adapter.py").exists()
    assert Path("debug_adapter/dispatcher.py").exists()
    assert Path("debug_adapter/server.py").exists()


def test_h44_d5_workspace_debug_config_still_exists():
    launch = json.loads(Path(".vscode/launch.json").read_text(encoding="utf-8"))
    tasks = json.loads(Path(".vscode/tasks.json").read_text(encoding="utf-8"))

    assert any(config["type"] == "panther" for config in launch["configurations"])
    assert any(task["label"] == "PantherLang: Check" for task in tasks["tasks"])
