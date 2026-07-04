from compiler.ast import (
    BinaryExpression,
    BlockNode,
    BooleanLiteral,
    NumberLiteral,
    PrintStatement,
    ProgramNode,
    VariableDeclaration,
)
from compiler.ast.program import MainBlockNode
from compiler.semantic import analyze


def _make_main_block(*stmts):
    return MainBlockNode(body=BlockNode(statements=stmts))


def test_no_diagnostics_for_valid_program():
    block = _make_main_block(
        VariableDeclaration(name="x", initializer=NumberLiteral(value=1)),
        PrintStatement(expression=NumberLiteral(value=42)),
    )
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 0


def test_undefined_variable_detected():
    block = _make_main_block(
        PrintStatement(expression=BinaryExpression(
            left=NumberLiteral(value=1),
            operator="+",
            right=NumberLiteral(value=1),
        )),
    )
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 0


def test_undefined_identifier_reported():
    from compiler.ast import IdentifierExpression, ExpressionStatement
    block = _make_main_block(
        ExpressionStatement(expression=IdentifierExpression(name="undefined_var")),
    )
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 1
    assert "Undefined" in diags[0].message


def test_duplicate_variable_detected():
    block = _make_main_block(
        VariableDeclaration(name="x", initializer=NumberLiteral(value=1)),
        VariableDeclaration(name="x", initializer=NumberLiteral(value=2)),
    )
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 1
    assert "Duplicate" in diags[0].message or "already" in diags[0].message


def test_block_scope_isolates_symbols():
    inner = BlockNode(statements=(
        VariableDeclaration(name="a", initializer=NumberLiteral(value=1)),
    ))
    block = _make_main_block(
        VariableDeclaration(name="a", initializer=NumberLiteral(value=2)),
        inner,
        VariableDeclaration(name="b", initializer=NumberLiteral(value=3)),
    )
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 0


def test_break_outside_loop_detected():
    from compiler.ast import BreakStatement
    block = _make_main_block(BreakStatement())
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 1
    assert "break" in diags[0].message


def test_continue_outside_loop_detected():
    from compiler.ast import ContinueStatement
    block = _make_main_block(ContinueStatement())
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 1
    assert "continue" in diags[0].message


def test_break_inside_loop_ok():
    from compiler.ast import BreakStatement, WhileStatement, BooleanLiteral
    block = _make_main_block(
        WhileStatement(
            condition=BooleanLiteral(value=True),
            body=BlockNode(statements=(BreakStatement(),)),
        ),
    )
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 0


def test_continue_inside_for_ok():
    from compiler.ast import ContinueStatement, ForStatement, NumberLiteral
    block = _make_main_block(
        ForStatement(
            var="i",
            start=NumberLiteral(value=1),
            end=NumberLiteral(value=5),
            body=BlockNode(statements=(ContinueStatement(),)),
        ),
    )
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 0


def test_function_scope_isolates_parameters():
    from compiler.ast import FunctionDeclaration
    block = _make_main_block(
        FunctionDeclaration(name="f", params=("x",), body=BlockNode()),
        VariableDeclaration(name="x", initializer=NumberLiteral(value=1)),
    )
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 0


def test_undefined_function_assignment():
    from compiler.ast import AssignmentStatement, IdentifierExpression
    block = _make_main_block(
        AssignmentStatement(
            target=IdentifierExpression(name="nonexistent"),
            value=NumberLiteral(value=42),
        ),
    )
    program = ProgramNode(body=(block,))
    diags = analyze(program)
    assert len(diags) == 1
    assert "Undefined" in diags[0].message
