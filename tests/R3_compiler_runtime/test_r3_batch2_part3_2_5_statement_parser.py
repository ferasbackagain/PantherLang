from compiler.ast import (
    AssignmentStatement,
    BlockNode,
    BooleanLiteral,
    ExpressionStatement,
    IdentifierExpression,
    MainBlockNode,
    NumberLiteral,
    PrintStatement,
    ProgramNode,
    ReturnStatement,
    RouteStatement,
    StringLiteral,
    ast_to_dict,
)
from compiler.lexer import TokenKind
from compiler.parser import parse_block, parse_program


def test_block_parser_builds_print_statement_ast():
    result = parse_block('{ print("Hello Panther"); }')
    assert result.ok
    assert isinstance(result.node, BlockNode)
    assert len(result.node.statements) == 1
    stmt = result.node.statements[0]
    assert isinstance(stmt, PrintStatement)
    assert isinstance(stmt.expression, StringLiteral)
    assert stmt.expression.value == 'Hello Panther'


def test_block_parser_builds_return_statement_with_number_literal():
    result = parse_block('{ return 42; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ReturnStatement)
    assert isinstance(stmt.expression, NumberLiteral)
    assert stmt.expression.value == 42


def test_block_parser_builds_empty_return_statement():
    result = parse_block('{ return; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ReturnStatement)
    assert stmt.expression is None


def test_block_parser_builds_route_statement_with_nested_body():
    result = parse_block('{ route GET "/" { print("home"); } }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, RouteStatement)
    assert stmt.method == 'GET'
    assert stmt.path == '/'
    assert isinstance(stmt.body, BlockNode)
    assert isinstance(stmt.body.statements[0], PrintStatement)


def test_block_parser_builds_assignment_statement():
    result = parse_block('{ answer = 42; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, AssignmentStatement)
    assert isinstance(stmt.target, IdentifierExpression)
    assert stmt.target.name == 'answer'
    assert isinstance(stmt.value, NumberLiteral)
    assert stmt.value.value == 42


def test_block_parser_builds_expression_statement():
    result = parse_block('{ do_work(); }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ExpressionStatement)
    assert stmt.expression is not None


def test_boolean_literal_statement_expression():
    result = parse_block('{ print(true); print(false); }')
    assert result.ok
    first, second = result.node.statements
    assert isinstance(first.expression, BooleanLiteral)
    assert first.expression.value is True
    assert isinstance(second.expression, BooleanLiteral)
    assert second.expression.value is False


def test_program_parser_now_preserves_main_block_statements():
    result = parse_program('panther main { print("Hello Panther"); return 0; }')
    assert result.ok
    assert isinstance(result.node, ProgramNode)
    main = result.node.body[0]
    assert isinstance(main, MainBlockNode)
    assert len(main.body.statements) == 2
    assert isinstance(main.body.statements[0], PrintStatement)
    assert isinstance(main.body.statements[1], ReturnStatement)


def test_statement_ast_serializes_through_program():
    result = parse_program('panther main { print("Hello Panther"); }')
    payload = ast_to_dict(result.node)
    stmt = payload['body'][0]['body']['statements'][0]
    assert stmt['type'] == 'PrintStatement'
    assert stmt['expression']['type'] == 'StringLiteral'
    assert stmt['expression']['value'] == 'Hello Panther'


def test_statement_parser_reports_missing_semicolon():
    result = parse_block('{ print("missing") }')
    assert not result.ok
    assert any(TokenKind.SEMICOLON in diagnostic.expected for diagnostic in result.diagnostics)
