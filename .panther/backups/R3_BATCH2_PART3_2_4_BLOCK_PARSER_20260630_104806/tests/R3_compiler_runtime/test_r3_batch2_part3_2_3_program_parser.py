from compiler.ast import AiBlockNode, ApiBlockNode, MainBlockNode, ProgramNode, TestBlockNode, WebBlockNode, ast_to_dict
from compiler.lexer import TokenKind
from compiler.parser import ProgramParser, parse_program


def test_parse_minimal_panther_main_program():
    result = parse_program('panther main { }')
    assert result.ok
    assert isinstance(result.node, ProgramNode)
    assert len(result.node.body) == 1
    assert isinstance(result.node.body[0], MainBlockNode)
    assert result.node.body[0].body.statements == ()


def test_parse_panther_main_with_placeholder_statement_content():
    result = parse_program('panther main { print("Hello Panther"); }')
    assert result.ok
    assert isinstance(result.node.body[0], MainBlockNode)
    assert result.node.body[0].body is not None


def test_parse_multiple_top_level_blocks():
    source = '''
    panther main { print("x"); }
    web { route GET "/" { } }
    api { route POST "/v1" { } }
    ai { prompt "hello"; }
    test "smoke" { assert true; }
    '''
    result = parse_program(source)
    assert result.ok
    assert [type(node) for node in result.node.body] == [
        MainBlockNode,
        WebBlockNode,
        ApiBlockNode,
        AiBlockNode,
        TestBlockNode,
    ]
    assert result.node.body[-1].name == "smoke"


def test_program_parser_records_missing_main_after_panther():
    result = parse_program('panther { }')
    assert not result.ok
    assert result.node.body == ()
    assert any(item.expected == (TokenKind.MAIN,) for item in result.diagnostics)


def test_program_parser_records_unknown_top_level_token_and_recovers():
    result = parse_program('print("bad"); panther main { }')
    assert not result.ok
    assert len(result.node.body) == 1
    assert isinstance(result.node.body[0], MainBlockNode)
    assert any('Expected top-level' in item.message for item in result.diagnostics)


def test_program_parser_rejects_unterminated_block():
    result = parse_program('panther main { print("x");')
    assert not result.ok
    assert result.node.body == ()
    assert any('Unterminated block' in item.message for item in result.diagnostics)


def test_program_ast_serializes_top_level_shape():
    result = parse_program('panther main { }')
    payload = ast_to_dict(result.node)
    assert payload['type'] == 'ProgramNode'
    assert payload['body'][0]['type'] == 'MainBlockNode'
    assert payload['body'][0]['body']['type'] == 'BlockNode'


def test_program_parser_class_parse_entrypoint():
    parser = ProgramParser.from_source('web { }')
    result = parser.parse()
    assert result.ok
    assert isinstance(result.node.body[0], WebBlockNode)
