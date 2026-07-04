from pathlib import Path

from compiler.runtime import execute_source


def test_pure_web_block_is_silent_in_execute_source():
    result = execute_source('''
web {
    route GET "/hello" {
        print "hello from web";
    }
}
''')
    assert result.error is None
    assert result.captured_output == []


def test_pure_api_block_is_silent_in_execute_source():
    result = execute_source('''
api {
    route GET "/health" {
        return { status: "ok" };
    }
}
''')
    assert result.error is None
    assert result.captured_output == []


def test_hello_web_example_preview_comes_from_panther_main():
    source = Path("examples/hello_web/main.pan").read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    joined = " ".join(result.captured_output)
    assert "Web" in joined
    assert "localhost:8080" in joined


def test_hello_api_example_preview_comes_from_panther_main():
    source = Path("examples/hello_api/main.pan").read_text(encoding="utf-8")
    result = execute_source(source)
    assert result.error is None
    joined = " ".join(result.captured_output)
    assert "API" in joined
    assert "localhost:8080" in joined
