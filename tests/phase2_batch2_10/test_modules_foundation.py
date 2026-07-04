from compiler.ast import ImportStatement
from compiler.runtime import execute_source


def test_import_statement_ast():
    stmt = ImportStatement(module_name="math")
    assert stmt.module_name == "math"
    assert stmt.alias is None
    assert stmt.children() == ()


def test_import_statement_with_alias():
    stmt = ImportStatement(module_name="math", alias="m")
    assert stmt.alias == "m"


def test_parse_import_simple():
    source = 'panther main { import math; print("ok"); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ok"]


def test_parse_import_dotted_path():
    source = 'panther main { import std.math; print("ok"); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ok"]


def test_parse_import_deep_path():
    source = 'panther main { import org.example.utils; print("ok"); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ok"]


def test_parse_import_with_alias():
    source = 'panther main { import math as m; print("ok"); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ok"]


def test_parse_import_dotted_with_alias():
    source = 'panther main { import std.collections as col; print("ok"); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ok"]


def test_import_defines_variable():
    source = 'panther main { import math; print(math.__module); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["math"]


def test_import_alias_defines_variable():
    source = 'panther main { import std.math as m; print(m.__module); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["std.math"]


def test_multiple_imports():
    source = '''
panther main {
    import math;
    import fs;
    import json;
    print("all");
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["all"]
