from compiler.ast import (
    AiBlockNode,
    ApiBlockNode,
    AssignmentStatement,
    BlockNode,
    ExpressionStatement,
    MainBlockNode,
    NumberLiteral,
    PrintStatement,
    ProgramNode,
    ReturnStatement,
    RouteStatement,
    StringLiteral,
    TestBlockNode,
    WebBlockNode,
    ast_to_dict,
)
from compiler.lexer import TokenKind
from compiler.parser import TokenStream, parse_block, parse_program


def test_parser_suite_accepts_complete_current_surface_program():
    source = '''
    panther main {
        print("Hello Panther");
        answer = 42;
        return answer;
    }
    web {
        route GET "/" { print("home"); }
    }
    api {
        route POST "/items" { return 201; }
    }
    ai {
        print("agent");
    }
    test "smoke" {
        print(true);
    }
    '''
    result = parse_program(source)
    assert result.ok
    assert isinstance(result.node, ProgramNode)
    assert [type(node) for node in result.node.body] == [
        MainBlockNode,
        WebBlockNode,
        ApiBlockNode,
        AiBlockNode,
        TestBlockNode,
    ]
    main = result.node.body[0]
    assert len(main.body.statements) == 3
    assert isinstance(main.body.statements[0], PrintStatement)
    assert isinstance(main.body.statements[1], AssignmentStatement)
    assert isinstance(main.body.statements[2], ReturnStatement)


def test_parser_suite_preserves_route_body_statement_ast():
    result = parse_program('web { route GET "/status" { print("ok"); return 0; } }')
    assert result.ok
    route = result.node.body[0].body.statements[0]
    assert isinstance(route, RouteStatement)
    assert route.method == 'GET'
    assert route.path == '/status'
    assert isinstance(route.body, BlockNode)
    assert isinstance(route.body.statements[0], PrintStatement)
    assert isinstance(route.body.statements[1], ReturnStatement)


def test_parser_suite_serialization_contract_for_program_tree():
    result = parse_program('panther main { print("Hello Panther"); }')
    assert result.ok
    payload = ast_to_dict(result.node)
    assert payload['type'] == 'ProgramNode'
    assert payload['body'][0]['type'] == 'MainBlockNode'
    stmt = payload['body'][0]['body']['statements'][0]
    assert stmt['type'] == 'PrintStatement'
    assert stmt['expression']['type'] == 'StringLiteral'
    assert stmt['expression']['value'] == 'Hello Panther'


def test_parser_suite_source_locations_remain_source_aware():
    source = '\n\n  panther main {\n    print("x");\n  }\n'
    result = parse_program(source)
    assert result.ok
    main = result.node.body[0]
    stmt = main.body.statements[0]
    assert main.location.line == 3
    assert main.location.column == 3
    assert stmt.location.line == 4
    assert stmt.location.column == 5


def test_parser_suite_reports_missing_program_block_close():
    result = parse_program('panther main { print("missing close");')
    assert not result.ok
    assert result.diagnostics
    assert any(TokenKind.RIGHT_BRACE in diagnostic.expected for diagnostic in result.diagnostics)


def test_parser_suite_reports_missing_statement_semicolon():
    result = parse_block('{ print("missing") }')
    assert not result.ok
    assert any(TokenKind.SEMICOLON in diagnostic.expected for diagnostic in result.diagnostics)


def test_parser_suite_recovers_after_bad_top_level_and_continues():
    result = parse_program('garbage ; panther main { print("ok"); }')
    assert not result.ok
    assert len(result.node.body) == 1
    assert isinstance(result.node.body[0], MainBlockNode)


def test_parser_suite_empty_program_is_valid_current_contract():
    result = parse_program('')
    assert result.ok
    assert result.node.body == ()


def test_parser_suite_token_stream_checkpoint_still_supports_speculation():
    stream = TokenStream.from_source('panther main { print("x"); }')
    assert stream.check(TokenKind.PANTHER)
    checkpoint = stream.checkpoint()
    assert stream.advance().kind is TokenKind.PANTHER
    assert stream.advance().kind is TokenKind.MAIN
    stream.rollback(checkpoint)
    assert stream.current.kind is TokenKind.PANTHER


def test_parser_suite_expression_statement_placeholder_contract_until_part_3_3():
    result = parse_block('{ do_work(1, 2); }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ExpressionStatement)
    assert stmt.expression.name == 'do_work ( 1 , 2 )'


def test_parser_suite_string_and_number_literals_are_materialized():
    result = parse_block('{ print("x"); return 7; }')
    assert result.ok
    print_stmt, return_stmt = result.node.statements
    assert isinstance(print_stmt.expression, StringLiteral)
    assert print_stmt.expression.value == 'x'
    assert isinstance(return_stmt.expression, NumberLiteral)
    assert return_stmt.expression.value == 7


def test_parser_suite_test_block_name_and_body_are_preserved():
    result = parse_program('test "parser smoke" { print("ok"); }')
    assert result.ok
    block = result.node.body[0]
    assert isinstance(block, TestBlockNode)
    assert block.name == 'parser smoke'
    assert isinstance(block.body.statements[0], PrintStatement)
