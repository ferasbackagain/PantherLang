import json
import os
import zipfile
from pathlib import Path

PACKAGE_JSON = Path("./vscode-extension/package.json")
EXT_DIR = PACKAGE_JSON.parent
TRACE_PATH = Path(os.environ.get("PANTHER_H44_D6_TRACE_FILE", "docs/hardening/H4_4_D6_VSCODE_E2E_TRACE_20260628_130022.json"))


def _json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def test_h44_d6_complete_vscode_debug_integration_chain():
    trace = []

    package = _json(PACKAGE_JSON)
    launch = _json(".vscode/launch.json")
    tasks = _json(".vscode/tasks.json")

    trace.append({"step": "package.loaded", "package": str(PACKAGE_JSON)})
    trace.append({"step": "workspace.launch.loaded", "configCount": len(launch["configurations"])})
    trace.append({"step": "workspace.tasks.loaded", "taskCount": len(tasks["tasks"])})

    debuggers = package.get("contributes", {}).get("debuggers", [])
    panther_debuggers = [dbg for dbg in debuggers if dbg.get("type") == "panther"]

    assert len(panther_debuggers) == 1
    debugger = panther_debuggers[0]

    assert debugger["type"] == "panther"
    assert debugger["label"] == "PantherLang Debug"
    assert debugger["program"] == "./out/extension.js"
    assert debugger["runtime"] == "node"

    trace.append({"step": "debugger.contribution.verified", "debugger": debugger})

    languages = package.get("contributes", {}).get("languages", [])
    panther_languages = [lang for lang in languages if lang.get("id") == "panther"]

    assert len(panther_languages) == 1
    assert ".pan" in panther_languages[0]["extensions"]
    assert ".panther" in panther_languages[0]["extensions"]

    trace.append({"step": "language.contribution.verified", "language": panther_languages[0]})

    activation_events = set(package.get("activationEvents", []))
    assert "onDebug" in activation_events
    assert "onDebugResolve:panther" in activation_events
    assert "onDebugInitialConfigurations" in activation_events
    assert "onCommand:panther.debug.start" in activation_events

    trace.append({"step": "activation.events.verified", "events": sorted(activation_events)})

    config_names = {config["name"]: config for config in launch["configurations"]}

    assert "PantherLang: Debug Current File" in config_names
    assert "PantherLang: Debug Example hello.pan" in config_names
    assert "PantherLang: F5 Debug Current File" in config_names

    current = config_names["PantherLang: Debug Current File"]
    f5 = config_names["PantherLang: F5 Debug Current File"]

    assert current["type"] == "panther"
    assert current["request"] == "launch"
    assert current["program"] == "${file}"
    assert current["preLaunchTask"] == "PantherLang: Check Current File"

    assert f5["type"] == "panther"
    assert f5["request"] == "launch"
    assert f5["program"] == "${file}"
    assert f5["preLaunchTask"] == "PantherLang: Check"

    trace.append({"step": "launch.configs.verified", "names": sorted(config_names)})

    task_labels = {task["label"]: task for task in tasks["tasks"]}

    assert "PantherLang: Check" in task_labels
    assert "PantherLang: Check Current File" in task_labels
    assert "PantherLang: Check Example" in task_labels
    assert "PantherLang: Run Current File" in task_labels

    assert task_labels["PantherLang: Check"]["command"] == "Panther"
    assert task_labels["PantherLang: Check"]["args"] == ["check", "${file}"]

    trace.append({"step": "tasks.verified", "labels": sorted(task_labels)})

    src_extension = (EXT_DIR / "src" / "extension.ts").read_text(encoding="utf-8")
    out_extension = (EXT_DIR / "out" / "extension.js").read_text(encoding="utf-8")
    out_debug_flow = (EXT_DIR / "out" / "debugFlow.js").read_text(encoding="utf-8")

    assert "registerDebugAdapterDescriptorFactory" in src_extension
    assert "registerDebugConfigurationProvider" in src_extension
    assert "panther.debug.start" in src_extension
    assert "startDebugging" in src_extension
    assert "debug_adapter" in src_extension
    assert "adapter.py" in src_extension

    assert "registerDebugAdapterDescriptorFactory" in out_extension
    assert "registerDebugConfigurationProvider" in out_extension
    assert "panther.debug.start" in out_extension
    assert "startDebugging" in out_extension
    assert "debug_adapter" in out_extension
    assert "adapter.py" in out_extension

    assert "createPantherF5DebugConfiguration" in out_debug_flow
    assert "startPantherF5Debug" in out_debug_flow
    assert "PantherLang: F5 Debug Current File" in out_debug_flow

    trace.append({"step": "extension.runtime.verified"})

    assert Path("debug_adapter/adapter.py").exists()
    assert Path("debug_adapter/dispatcher.py").exists()
    assert Path("debug_adapter/server.py").exists()

    assert Path("docs/hardening/H4_3_OFFICIAL_COMPLETION.md").exists()
    assert Path("docs/hardening/H4_2_OFFICIAL_COMPLETION.md").exists()

    trace.append({"step": "debug.adapter.and.prior.milestones.verified"})

    TRACE_PATH.parent.mkdir(parents=True, exist_ok=True)
    TRACE_PATH.write_text(json.dumps(trace, indent=2), encoding="utf-8")


def test_h44_d6_package_artifact_is_present_and_contains_runtime_files():
    dist = EXT_DIR / "dist"
    artifacts = sorted(dist.glob("*.vsix.zip"))

    assert artifacts, "No VSIX-like package artifact found"

    artifact = artifacts[-1]
    assert artifact.stat().st_size > 0

    with zipfile.ZipFile(artifact, "r") as archive:
        names = set(archive.namelist())

    assert "package.json" in names
    assert "out/extension.js" in names
    assert "out/debugFlow.js" in names
    assert "src/extension.ts" in names
    assert "src/debugFlow.ts" in names


def test_h44_d6_status_chain_complete():
    required = [
        ".panther/phase_status/H4_4_d1_vscode_debugger_contribution.json",
        ".panther/phase_status/H4_4_d2_debug_adapter_registration.json",
        ".panther/phase_status/H4_4_d3_workspace_debug_configs.json",
        ".panther/phase_status/H4_4_d4_f5_debug_flow.json",
        ".panther/phase_status/H4_4_d5_vscode_extension_package_verification.json",
        ".panther/phase_status/H4_3_d10_professional_verification.json",
        ".panther/phase_status/H4_2_finalize_v2_f8_end_to_end_professional_verification.json",
    ]

    for item in required:
        assert Path(item).exists(), f"Missing status file: {item}"
