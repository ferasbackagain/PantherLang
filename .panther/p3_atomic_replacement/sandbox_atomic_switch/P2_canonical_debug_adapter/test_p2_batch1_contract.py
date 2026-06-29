import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = ROOT / ".panther" / "p2_debug_adapter_rebuild" / "spec"

def test_p2_contract_exists_and_is_machine_readable():
    contract = SPEC / "canonical_debug_adapter_contract.json"
    assert contract.exists()
    data = json.loads(contract.read_text())
    assert data["phase"] == "P-2"
    assert data["batch"] == "1"
    assert data["runtime_modified"] is False
    assert data["target_directory"] == "debug_adapter_rebuilt"
    assert data["atomic_replace_only_after_full_pass"] is True

def test_p2_required_modules_cover_protocol_dispatcher_server_and_data_model():
    data = json.loads((SPEC / "canonical_debug_adapter_contract.json").read_text())
    modules = set(data["required_modules"])
    for name in [
        "protocol.py",
        "session.py",
        "event_bus.py",
        "event_dispatcher.py",
        "request_dispatcher.py",
        "execution_dispatcher.py",
        "server.py",
        "variables_core.py",
        "variable_references.py",
        "variable_store.py",
        "stack_frames.py",
        "threads.py",
        "scopes.py",
        "evaluate.py",
        "watch_expressions.py",
    ]:
        assert name in modules

def test_p2_contract_includes_required_dap_commands_and_capabilities():
    data = json.loads((SPEC / "canonical_debug_adapter_contract.json").read_text())
    commands = set(data["dap_commands"])
    for cmd in ["initialize", "configurationDone", "setBreakpoints", "launch", "continue", "pause", "terminate", "disconnect", "evaluate"]:
        assert cmd in commands
    caps = data["required_capabilities"]
    assert caps["supportsConfigurationDoneRequest"] is True
    assert caps["supportsSetVariable"] is True
    assert caps["panther"]["realDAPFraming"] is True
