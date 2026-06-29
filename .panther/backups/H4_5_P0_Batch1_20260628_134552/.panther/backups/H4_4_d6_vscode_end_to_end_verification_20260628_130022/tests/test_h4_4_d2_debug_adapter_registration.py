import json
from pathlib import Path

PACKAGE_JSON = Path("./vscode-extension/package.json")
EXT_DIR = PACKAGE_JSON.parent


def test_h44_d2_extension_entrypoints_exist():
    assert (EXT_DIR / "src" / "extension.ts").exists()
    assert (EXT_DIR / "out" / "extension.js").exists()


def test_h44_d2_package_main_points_to_runtime_extension():
    data = json.loads(PACKAGE_JSON.read_text(encoding="utf-8"))
    assert data["main"] == "./out/extension.js"


def test_h44_d2_debug_adapter_descriptor_registered_in_source():
    src = (EXT_DIR / "src" / "extension.ts").read_text(encoding="utf-8")
    out = (EXT_DIR / "out" / "extension.js").read_text(encoding="utf-8")

    assert "registerDebugAdapterDescriptorFactory" in src
    assert "registerDebugConfigurationProvider" in src
    assert "panther" in src
    assert "debug_adapter" in src
    assert "adapter.py" in src

    assert "registerDebugAdapterDescriptorFactory" in out
    assert "registerDebugConfigurationProvider" in out
    assert "panther" in out
    assert "debug_adapter" in out
    assert "adapter.py" in out


def test_h44_d2_debugger_contribution_points_to_extension_runtime():
    data = json.loads(PACKAGE_JSON.read_text(encoding="utf-8"))
    debuggers = data.get("contributes", {}).get("debuggers", [])
    panther = [item for item in debuggers if item.get("type") == "panther"]

    assert len(panther) == 1
    dbg = panther[0]

    assert dbg["program"] == "./out/extension.js"
    assert dbg["runtime"] == "node"
    assert dbg["label"] == "PantherLang Debug"


def test_h44_d2_debug_start_command_registered():
    src = (EXT_DIR / "src" / "extension.ts").read_text(encoding="utf-8")
    out = (EXT_DIR / "out" / "extension.js").read_text(encoding="utf-8")

    assert "panther.debug.start" in src
    assert "startDebugging" in src

    assert "panther.debug.start" in out
    assert "startDebugging" in out


def test_h44_d2_adapter_file_exists_in_project():
    assert Path("debug_adapter/adapter.py").exists()
