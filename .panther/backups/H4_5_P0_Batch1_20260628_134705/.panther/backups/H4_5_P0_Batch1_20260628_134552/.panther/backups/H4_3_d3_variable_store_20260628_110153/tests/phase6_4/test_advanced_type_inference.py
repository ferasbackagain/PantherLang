from __future__ import annotations
import json
from pathlib import Path
import pytest
from language.compiler.type_inference import AdvancedTypeInferenceEngine, TypeInferenceError

def test_positive_infers_literals_collections_and_functions() -> None:
    src = '''
fn add(a: Int, b: Int) -> Int { return a + b }
let x = 41
let y = 1
let z = add(x, y)
let title = "Panther" + "Lang"
let scores = [1, 2, 3]
let profile = {"name": "Feras", "project": "PantherLang"}
let ready: Bool = true
'''
    result = AdvancedTypeInferenceEngine().analyze_source(src)
    assert result.ok is True
    assert result.phase == "6.4"
    assert result.version == "0.6.4-advanced-type-inference"
    assert result.symbols["x"] == "Int"
    assert result.symbols["z"] == "Int"
    assert result.symbols["title"] == "String"
    assert result.symbols["scores"] == "List<Int>"
    assert result.symbols["profile"] == "Map<String, String>"
    assert result.external_api_used is False
    assert result.network_required is False

def test_typed_assignment_mismatch_is_negative_case() -> None:
    result = AdvancedTypeInferenceEngine().analyze_source('let age: Int = "not an int"\n')
    assert result.ok is False
    assert any(d.code == "PANTHER-TYPE-064-ASSIGN" for d in result.diagnostics)

def test_function_return_mismatch_is_negative_case() -> None:
    result = AdvancedTypeInferenceEngine().analyze_source('fn bad() -> Int { return "wrong" }\n')
    assert result.ok is False
    assert any(d.code == "PANTHER-TYPE-064-RETURN" for d in result.diagnostics)

def test_call_argument_type_mismatch_is_negative_case() -> None:
    src = '''
fn inc(value: Int) -> Int { return value + 1 }
let broken = inc("x")
'''
    result = AdvancedTypeInferenceEngine().analyze_source(src)
    assert result.ok is False
    assert any(d.code == "PANTHER-TYPE-064-ARG" for d in result.diagnostics)

def test_empty_source_fails() -> None:
    with pytest.raises(TypeInferenceError): AdvancedTypeInferenceEngine().analyze_source("   ")

def test_workspace_analysis_uses_phase6_3_workspace(tmp_path: Path) -> None:
    root = tmp_path / "ws"; (root / "core").mkdir(parents=True); (root / "app").mkdir(parents=True)
    (root / "core" / "math.panther").write_text('fn twice(x: Int) -> Int { return x + x }\nlet base = 21\n', encoding="utf-8")
    (root / "app" / "main.panther").write_text('import core\nfn main() -> Int { return 42 }\nlet answer = 42\n', encoding="utf-8")
    (root / "panther.workspace.json").write_text(json.dumps({"name":"phase6_4_ws","version":"0.1.0","entry":"app.main","modules":[{"name":"core","root":"core","sources":["*.panther"]},{"name":"app","root":"app","sources":["*.panther"]}]}), encoding="utf-8")
    report = AdvancedTypeInferenceEngine().analyze_workspace(root)
    assert report["ok"] is True
    assert report["files_analyzed"] == 2
    assert report["external_api_used"] is False
    assert report["network_required"] is False

def test_stress_many_inferences() -> None:
    lines = ["fn add(a: Int, b: Int) -> Int { return a + b }"]
    for i in range(250): lines.append(f"let value_{i} = add({i}, {i + 1})")
    result = AdvancedTypeInferenceEngine().analyze_source("\n".join(lines))
    assert result.ok is True
    assert len(result.symbols) == 250
    assert result.symbols["value_249"] == "Int"
