from pathlib import Path

from cli.panther_cli import main

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = [
    ("console_hello", ROOT / "examples" / "console_hello" / "main.pan"),
    ("calculator", ROOT / "examples" / "calculator" / "calc.pan"),
    ("hello_api", ROOT / "examples" / "hello_api" / "main.pan"),
    ("hello_web", ROOT / "examples" / "hello_web" / "main.pan"),
    ("hello_ai", ROOT / "examples" / "hello_ai" / "main.pan"),
    ("security_audit_demo", ROOT / "examples" / "security_audit_demo" / "main.pan"),
    ("file_manager", ROOT / "examples" / "file_manager" / "main.pan"),
    ("sqlite_crud", ROOT / "examples" / "sqlite_crud" / "main.pan"),
    ("http_client", ROOT / "examples" / "http_client" / "main.pan"),
    ("json_parser", ROOT / "examples" / "json_parser" / "main.pan"),
    ("config_loader", ROOT / "examples" / "config_loader" / "main.pan"),
]


def test_all_example_files_exist():
    for name, path in EXAMPLES:
        assert path.exists(), f"Example {name} not found at {path}"


def test_all_example_readmes_exist():
    for name, path in EXAMPLES:
        readme = path.parent / "README.md"
        assert readme.exists(), f"README for {name} not found at {readme}"


def test_examples_run():
    for name, path in EXAMPLES:
        result = main(["run", str(path)])
        assert result == 0, f"Example {name} failed with code {result}"


def test_console_hello_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[0][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "PantherLang" in " ".join(result.captured_output)


def test_calculator_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[1][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "5040" in " ".join(result.captured_output)


def test_api_placeholder_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[2][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "API" in " ".join(result.captured_output)


def test_web_placeholder_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[3][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "Web" in " ".join(result.captured_output)


def test_ai_placeholder_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[4][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "AI" in " ".join(result.captured_output)


def test_security_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[5][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "Security" in " ".join(result.captured_output)


def test_file_manager_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[6][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "File Manager" in " ".join(result.captured_output)


def test_sqlite_crud_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[7][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "SQLite CRUD" in " ".join(result.captured_output)


def test_http_client_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[8][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "HTTP Client" in " ".join(result.captured_output)


def test_json_parser_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[9][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "JSON Parser" in " ".join(result.captured_output)


def test_config_loader_output():
    from compiler.runtime import execute_source
    source = EXAMPLES[10][1].read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    assert "Config" in " ".join(result.captured_output)
