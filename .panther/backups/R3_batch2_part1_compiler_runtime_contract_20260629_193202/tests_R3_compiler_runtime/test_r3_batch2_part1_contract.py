import json
from pathlib import Path

from compiler.runtime_contract.contract import get_contract, COMPILER_RUNTIME_VERSION
from runtime.panther_vm import PantherVM, PantherRuntimeResult


def test_compiler_runtime_contract_shape():
    contract = get_contract()
    assert contract.version == COMPILER_RUNTIME_VERSION
    assert ".panther" in contract.source_extensions
    assert ".pan" in contract.source_extensions
    assert "main" in contract.entrypoints
    assert "parse" in contract.stages
    assert contract.build_artifact_format == "panther-build-json-v1"


def test_contract_json_exists_and_matches():
    data = json.loads(Path(".panther/R3_compiler_runtime/compiler_runtime_contract.json").read_text())
    assert data["ok"] is True
    assert data["phase"] == "R3"
    assert data["batch"] == "2"
    assert data["part"] == "1"
    assert ".panther" in data["source_extensions"]
    assert "runtime_execute" in data["pipeline"]


def test_runtime_vm_scaffold_contract():
    vm = PantherVM()
    result = vm.execute_source('panther main { print("hi") }')
    assert isinstance(result, PantherRuntimeResult)
    assert result.ok is True
    assert result.exit_code == 0
    assert "accepted source" in result.output
