from compiler.lexer import lex_source
from compiler.parser import ProgramParser
from compiler.parser.token_stream import TokenStream
from compiler.runtime.execution_pipeline import execute_source


def parse_ok(source: str):
    result = ProgramParser(TokenStream(lex_source(source))).parse()
    assert result.ok, result.diagnostics
    return result.node


def test_return_object_literal_inside_web_route_parses():
    source = '''
web {
    route GET "/health" {
        return { status: "ok", service: "panther-web" };
    }
}
'''
    program = parse_ok(source)
    assert len(program.body) == 1


def test_return_array_literal_inside_route_parses():
    source = '''
api {
    route GET "/items" {
        return [1, 2, 3];
    }
}
'''
    program = parse_ok(source)
    assert len(program.body) == 1


def test_object_literal_assignment_still_executes():
    source = '''
panther main {
    let user = { name: "Feras", role: "founder" };
    print user["name"];
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["Feras"]
