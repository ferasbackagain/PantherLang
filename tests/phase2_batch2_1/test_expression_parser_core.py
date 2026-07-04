from compiler.ast import BinaryExpression, CallExpression, GroupingExpression, IdentifierExpression, NumberLiteral, UnaryExpression
from compiler.parser import parse_block
from compiler.parser.expression_parser import ExpressionParser
from compiler.lexer import lex_source


def parse_expr(source: str):
    tokens = [token for token in lex_source(source) if token.lexeme]
    result = ExpressionParser(tokens).parse()
    assert result.consumed_all
    return result.expression


def test_pratt_parser_respects_multiplication_precedence():
    expr = parse_expr("1 + 2 * 3")
    assert isinstance(expr, BinaryExpression)
    assert expr.operator == "+"
    assert isinstance(expr.left, NumberLiteral)
    assert expr.left.value == 1
    assert isinstance(expr.right, BinaryExpression)
    assert expr.right.operator == "*"


def test_grouping_overrides_precedence():
    expr = parse_expr("(1 + 2) * 3")
    assert isinstance(expr, BinaryExpression)
    assert expr.operator == "*"
    assert isinstance(expr.left, GroupingExpression)
    assert isinstance(expr.left.expression, BinaryExpression)
    assert expr.left.expression.operator == "+"


def test_unary_expression_wraps_primary():
    expr = parse_expr("-42")
    assert isinstance(expr, UnaryExpression)
    assert expr.operator == "-"
    assert isinstance(expr.operand, NumberLiteral)
    assert expr.operand.value == 42


def test_expression_statement_uses_parser_core_for_binary_expression():
    result = parse_block("{ 1 + 2 * 3; }")
    assert result.ok
    expr = result.node.statements[0].expression
    assert isinstance(expr, BinaryExpression)
    assert expr.operator == "+"
    assert isinstance(expr.right, BinaryExpression)
    assert expr.right.operator == "*"


def test_assignment_statement_parses_binary_value_without_breaking_target():
    result = parse_block("{ answer = 40 + 2; }")
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt.target, IdentifierExpression)
    assert stmt.target.name == "answer"
    assert isinstance(stmt.value, BinaryExpression)
    assert stmt.value.operator == "+"


def test_legacy_call_like_expression_falls_back_to_existing_identifier_shape():
    result = parse_block("{ do_work(); }")
    assert result.ok
    expr = result.node.statements[0].expression
    assert isinstance(expr, CallExpression)
    assert isinstance(expr.callee, IdentifierExpression)
    assert expr.callee.name == "do_work"
    assert expr.arguments == ()
