from compiler.runtime import execute_source


def test_web_block_execute_source_is_silent_route_definition():
    source = '''
web {
    route GET "/" {
        return "<h1>Hello from PantherLang Web</h1>";
    }
    route GET "/health" {
        return { status: "ok", service: "panther-web" };
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == []


def test_api_block_execute_source_is_silent_route_definition():
    source = '''
api {
    route GET "/health" {
        return { status: "ok", service: "panther-api" };
    }
    route GET "/api" {
        return { message: "hello" };
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == []
