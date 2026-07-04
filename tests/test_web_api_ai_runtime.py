"""Tests for Batch 11.2: native web/API/AI runtime execution."""

from compiler.runtime import execute_source
from compiler.runtime.execution_pipeline import serve_source


def test_web_block_registers_route_handler():
    """WebBlock registers a route handler function without executing body."""
    result = execute_source('''
web {
    route GET "/hello" {
        print "hello from web";
    }
}
''')
    assert result.error is None
    assert result.captured_output == []


def test_api_block_registers_route():
    """ApiBlock registers route handlers without executing body."""
    result = execute_source('''
api {
    route POST "/data" {
        print "data received";
    }
}
''')
    assert result.error is None
    assert result.captured_output == []


def test_ai_block_executes_directly():
    """AiBlock executes statements directly (no route indirection)."""
    result = execute_source('''
ai {
    print "AI block ready";
}
''')
    assert result.error is None
    assert result.captured_output == ["AI block ready"]


def test_mixed_blocks_all_execute():
    """Main, web, and AI blocks all execute their direct statements."""
    result = execute_source('''
panther main {
    print "main";
}
web {
    print "web init";
    route GET "/test" {
        print "web route";
    }
}
ai {
    print "ai setup";
}
''')
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "main" in output
    assert "web init" in output
    assert "ai setup" in output


def test_route_handler_in_environment():
    """Route handler is accessible from the environment after web block."""
    from compiler.runtime.variable_environment import VariableEnvironment
    from compiler.runtime.statement_executor import StatementExecutor
    from compiler.parser import ProgramParser
    from compiler.lexer import lex_source
    from compiler.parser.token_stream import TokenStream

    source = '''
web {
    route GET "/ping" {
        print "pong";
    }
}
'''
    tokens = lex_source(source)
    stream = TokenStream(tokens)
    parser = ProgramParser(stream)
    parse_result = parser.parse()
    assert parse_result.ok

    env = VariableEnvironment.create_default()
    executor = StatementExecutor(env)
    for block in parse_result.node.body:
        if hasattr(block, "body") and block.body is not None:
            result = executor.run(list(block.body.statements))
            assert result.error is None

    assert env.has_function("__route_GET:/ping"), "Route handler should be in environment"

    handler = env.lookup_function("__route_GET:/ping")
    response = handler()
    assert response == {"ok": True}
    assert "pong" in " ".join(executor.output)


def test_multiple_routes():
    """Multiple routes can be registered in the same web block."""
    env, executor, output = _setup_routes('''
web {
    route GET "/a" { print "aa"; }
    route POST "/b" { print "bb"; }
}
''')
    assert env.has_function("__route_GET:/a")
    assert env.has_function("__route_POST:/b")

    env.lookup_function("__route_GET:/a")()
    env.lookup_function("__route_POST:/b")()
    assert len(executor.output) == 2


def test_serve_source_no_web():
    """serve_source works like execute_source when no web/api blocks exist."""
    result = serve_source('panther main { print "no web"; }')
    assert result.error is None
    assert result.captured_output == ["no web"]


def test_http_server_registers_routes():
    """Routes are registered in HttpServer when http_server is passed to executor."""
    from compiler.web import HttpServer
    from compiler.runtime.variable_environment import VariableEnvironment
    from compiler.runtime.statement_executor import StatementExecutor
    from compiler.parser import ProgramParser
    from compiler.lexer import lex_source
    from compiler.parser.token_stream import TokenStream

    server = HttpServer(host="127.0.0.1", port=0)
    env = VariableEnvironment.create_default()
    executor = StatementExecutor(env, http_server=server)

    tokens = lex_source('''
web {
    route GET "/hello" { print "hi"; }
    route POST "/submit" { print "ok"; }
}
''')
    stream = TokenStream(tokens)
    parser = ProgramParser(stream)
    parse_result = parser.parse()
    assert parse_result.ok

    for block in parse_result.node.body:
        if hasattr(block, "body") and block.body is not None:
            result = executor.run(list(block.body.statements))
            assert result.error is None

    routes = server.router.routes
    assert len(routes) == 2
    methods = {r.method for r in routes}
    paths = {r.path for r in routes}
    assert "GET" in methods
    assert "POST" in methods
    assert "/hello" in paths
    assert "/submit" in paths


def _setup_routes(source: str):
    """Helper: parse and execute source, return (env, executor, output)."""
    from compiler.runtime.variable_environment import VariableEnvironment
    from compiler.runtime.statement_executor import StatementExecutor
    from compiler.parser import ProgramParser
    from compiler.lexer import lex_source
    from compiler.parser.token_stream import TokenStream

    tokens = lex_source(source)
    stream = TokenStream(tokens)
    parser = ProgramParser(stream)
    parse_result = parser.parse()
    assert parse_result.ok

    env = VariableEnvironment.create_default()
    executor = StatementExecutor(env)
    for block in parse_result.node.body:
        if hasattr(block, "body") and block.body is not None:
            result = executor.run(list(block.body.statements))
            assert result.error is None

    return env, executor, list(executor.output)
