from __future__ import annotations

from compiler.ast import (
    AssignmentStatement,
    BlockNode,
    ExpressionStatement,
    ForStatement,
    IdentifierExpression,
    IfStatement,
    NumberLiteral,
    PrintStatement,
    ReturnStatement,
    StringLiteral,
    VariableDeclaration,
    WhileStatement,
    ast_to_dict,
)
from compiler.lexer import TokenKind
from compiler.parser import parse_block, parse_program


def test_parse_let_variable_declaration_with_initializer():
    result = parse_block('{ let x = 42; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, VariableDeclaration)
    assert stmt.name == 'x'
    assert isinstance(stmt.initializer, NumberLiteral)
    assert stmt.initializer.value == 42


def test_parse_let_variable_declaration_with_string():
    result = parse_block('{ let name = "Panther"; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, VariableDeclaration)
    assert stmt.name == 'name'
    assert isinstance(stmt.initializer, StringLiteral)
    assert stmt.initializer.value == 'Panther'


def test_parse_let_variable_declaration_without_initializer():
    result = parse_block('{ let x; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, VariableDeclaration)
    assert stmt.name == 'x'
    assert stmt.initializer is None


def test_parse_if_statement_without_else():
    result = parse_block('{ if x > 0 { print("pos"); } }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, IfStatement)
    assert stmt.condition is not None
    assert isinstance(stmt.then_block, BlockNode)
    assert len(stmt.then_block.statements) == 1
    assert isinstance(stmt.then_block.statements[0], PrintStatement)
    assert stmt.else_block is None


def test_parse_if_else_statement():
    result = parse_block('{ if x > 0 { print("pos"); } else { print("neg"); } }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, IfStatement)
    assert isinstance(stmt.then_block, BlockNode)
    assert isinstance(stmt.else_block, BlockNode)
    assert isinstance(stmt.else_block.statements[0], PrintStatement)


def test_parse_while_statement():
    result = parse_block('{ while x < 10 { print(x); } }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, WhileStatement)
    assert stmt.condition is not None
    assert isinstance(stmt.body, BlockNode)
    assert isinstance(stmt.body.statements[0], PrintStatement)


def test_parse_for_range_statement():
    result = parse_block('{ for i in 1..10 { print(i); } }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ForStatement)
    assert stmt.var == 'i'
    assert stmt.start is not None
    assert stmt.end is not None
    assert isinstance(stmt.body, BlockNode)
    assert isinstance(stmt.body.statements[0], PrintStatement)


def test_parse_for_range_with_expressions():
    result = parse_block('{ for i in a..b { print(i); } }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ForStatement)
    assert stmt.var == 'i'
    assert stmt.start is not None
    assert stmt.end is not None


def test_let_and_print_in_same_block():
    result = parse_block('{ let msg = "hello"; print(msg); }')
    assert result.ok
    assert len(result.node.statements) == 2
    assert isinstance(result.node.statements[0], VariableDeclaration)
    assert isinstance(result.node.statements[1], PrintStatement)


def test_if_inside_while():
    result = parse_block('{ let x = 0; while x < 5 { if x == 3 { print(x); } let x = x + 1; } }')
    assert result.ok
    assert isinstance(result.node.statements[0], VariableDeclaration)
    assert isinstance(result.node.statements[1], WhileStatement)
    while_stmt = result.node.statements[1]
    assert isinstance(while_stmt.body.statements[0], IfStatement)
    assert isinstance(while_stmt.body.statements[1], VariableDeclaration)


def test_for_inside_program():
    result = parse_program('panther main { for i in 1..3 { print(i); } }')
    assert result.ok
    main = result.node.body[0]
    stmt = main.body.statements[0]
    assert isinstance(stmt, ForStatement)
    assert stmt.var == 'i'


def test_let_missing_semicolon_reports_error():
    result = parse_block('{ let x = 42 }')
    assert not result.ok
    assert any(TokenKind.SEMICOLON in diagnostic.expected for diagnostic in result.diagnostics)


def test_if_missing_block_reports_error():
    result = parse_block('{ if x > 0 }')
    assert not result.ok


def test_for_missing_range_dotdot_reports_error():
    result = parse_block('{ for i in 10 { print(i); } }')
    assert not result.ok


def test_statement_parser_let_ast_serializes():
    result = parse_block('{ let x = 42; }')
    payload = ast_to_dict(result.node)
    stmt = payload['statements'][0]
    assert stmt['type'] == 'VariableDeclaration'
    assert stmt['name'] == 'x'
    assert stmt['initializer']['type'] == 'NumberLiteral'
    assert stmt['initializer']['value'] == 42


def test_statement_parser_if_ast_serializes():
    result = parse_block('{ if true { print("ok"); } else { print("nok"); } }')
    payload = ast_to_dict(result.node)
    stmt = payload['statements'][0]
    assert stmt['type'] == 'IfStatement'
    assert 'then_block' in stmt
    assert 'else_block' in stmt


def test_statement_parser_while_ast_serializes():
    result = parse_block('{ while false { print("loop"); } }')
    payload = ast_to_dict(result.node)
    stmt = payload['statements'][0]
    assert stmt['type'] == 'WhileStatement'


def test_statement_parser_for_ast_serializes():
    result = parse_block('{ for i in 1..5 { print(i); } }')
    payload = ast_to_dict(result.node)
    stmt = payload['statements'][0]
    assert stmt['type'] == 'ForStatement'
    assert stmt['var'] == 'i'
    assert stmt['start']['value'] == 1
    assert stmt['end']['value'] == 5


def test_parse_let_with_identifier_initializer():
    result = parse_block('{ let x = y; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, VariableDeclaration)
    assert stmt.name == 'x'
    assert isinstance(stmt.initializer, IdentifierExpression)
    assert stmt.initializer.name == 'y'


def test_while_with_complex_condition():
    result = parse_block('{ while a + b < 100 { print(a); } }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, WhileStatement)
    assert stmt.condition is not None


def test_for_with_expression_bounds():
    result = parse_block('{ for i in a * 2..b + 1 { print(i); } }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ForStatement)
    assert stmt.start is not None
    assert stmt.end is not None


def test_nested_if_else():
    result = parse_block('{ if a { if b { print("a b"); } else { print("a not b"); } } else { print("not a"); } }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, IfStatement)
    assert isinstance(stmt.then_block.statements[0], IfStatement)
    assert stmt.else_block is not None
