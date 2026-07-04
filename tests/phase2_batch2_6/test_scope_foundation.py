from compiler.ast import (
    AssignmentStatement,
    BlockNode,
    BooleanLiteral,
    IdentifierExpression,
    IfStatement,
    NumberLiteral,
    PrintStatement,
    StringLiteral,
    VariableDeclaration,
    WhileStatement,
)
from compiler.runtime import StatementExecutor, VariableEnvironment, execute_source


def test_block_scope_isolates_variables():
    executor = StatementExecutor()
    executor.environment.define("outer", 1)
    block = BlockNode(statements=(
        VariableDeclaration(name="inner", initializer=NumberLiteral(value=2)),
        PrintStatement(expression=IdentifierExpression(name="inner")),
    ))
    result = executor.execute(block)
    assert result.error is None
    assert result.captured_output == ["2"]
    assert not executor.environment.has("inner")
    assert executor.environment.lookup("outer") == 1


def test_block_scope_outer_variable_accessible_inside():
    executor = StatementExecutor()
    executor.environment.define("x", 10)
    block = BlockNode(statements=(
        PrintStatement(expression=IdentifierExpression(name="x")),
    ))
    result = executor.execute(block)
    assert result.error is None
    assert result.captured_output == ["10"]


def test_block_scope_assign_updates_outer():
    executor = StatementExecutor()
    executor.environment.define("counter", 0)
    block = BlockNode(statements=(
        AssignmentStatement(
            target=IdentifierExpression(name="counter"),
            value=NumberLiteral(value=99),
        ),
    ))
    result = executor.execute(block)
    assert result.error is None
    assert executor.environment.lookup("counter") == 99


def test_nested_block_scopes():
    executor = StatementExecutor()
    executor.environment.define("a", 1)
    outer = BlockNode(statements=(
        VariableDeclaration(name="b", initializer=NumberLiteral(value=2)),
        BlockNode(statements=(
            VariableDeclaration(name="c", initializer=NumberLiteral(value=3)),
            PrintStatement(expression=IdentifierExpression(name="a")),
            PrintStatement(expression=IdentifierExpression(name="b")),
            PrintStatement(expression=IdentifierExpression(name="c")),
        )),
        PrintStatement(expression=IdentifierExpression(name="b")),
    ))
    result = executor.execute(outer)
    assert result.error is None
    assert result.captured_output == ["1", "2", "3", "2"]
    assert not executor.environment.has("b")
    assert not executor.environment.has("c")
    assert executor.environment.lookup("a") == 1


def test_block_scope_redeclares_outer():
    executor = StatementExecutor()
    executor.environment.define("x", 1)
    block = BlockNode(statements=(
        VariableDeclaration(name="x", initializer=NumberLiteral(value=2)),
        PrintStatement(expression=IdentifierExpression(name="x")),
    ))
    result = executor.execute(block)
    assert result.error is None
    assert result.captured_output == ["2"]
    assert executor.environment.lookup("x") == 1


def test_if_branch_block_scope():
    executor = StatementExecutor()
    if_stmt = IfStatement(
        condition=BooleanLiteral(value=True),
        then_block=BlockNode(statements=(
            VariableDeclaration(name="tmp", initializer=NumberLiteral(value=42)),
        )),
    )
    result = executor.execute(if_stmt)
    assert result.error is None
    assert not executor.environment.has("tmp")


def test_if_else_block_scope():
    executor = StatementExecutor()
    if_stmt = IfStatement(
        condition=BooleanLiteral(value=False),
        then_block=BlockNode(statements=(
            VariableDeclaration(name="val", initializer=StringLiteral(value="then")),
        )),
        else_block=BlockNode(statements=(
            VariableDeclaration(name="val", initializer=StringLiteral(value="else")),
        )),
    )
    result = executor.execute(if_stmt)
    assert result.error is None
    assert not executor.environment.has("val")


def test_while_body_block_scope():
    executor = StatementExecutor()
    executor.environment.define("i", 0)
    while_stmt = WhileStatement(
        condition=BooleanLiteral(value=False),
        body=BlockNode(statements=(
            VariableDeclaration(name="tmp", initializer=NumberLiteral(value=999)),
        )),
    )
    result = executor.execute(while_stmt)
    assert result.error is None
    assert not executor.environment.has("tmp")


def test_if_branch_can_assign_outer_variable():
    executor = StatementExecutor()
    executor.environment.define("flag", "no")
    if_stmt = IfStatement(
        condition=BooleanLiteral(value=True),
        then_block=BlockNode(statements=(
            AssignmentStatement(
                target=IdentifierExpression(name="flag"),
                value=StringLiteral(value="yes"),
            ),
        )),
    )
    result = executor.execute(if_stmt)
    assert result.error is None
    assert executor.environment.lookup("flag") == "yes"


def test_block_from_source():
    source = 'panther main { let x = 1; { let x = 2; print(x); } print(x); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["2", "1"]


def test_scope_chain_lookup_nested_blocks():
    executor = StatementExecutor()
    executor.environment.define("level0", "root")
    block1 = BlockNode(statements=(
        VariableDeclaration(name="level1", initializer=StringLiteral(value="block1")),
        BlockNode(statements=(
            VariableDeclaration(name="level2", initializer=StringLiteral(value="block2")),
            PrintStatement(expression=IdentifierExpression(name="level0")),
            PrintStatement(expression=IdentifierExpression(name="level1")),
            PrintStatement(expression=IdentifierExpression(name="level2")),
        )),
    ))
    result = executor.execute(block1)
    assert result.error is None
    assert result.captured_output == ["root", "block1", "block2"]


def test_block_scope_sibling_blocks():
    executor = StatementExecutor()
    outer = BlockNode(statements=(
        BlockNode(statements=(
            VariableDeclaration(name="a", initializer=NumberLiteral(value=1)),
        )),
        BlockNode(statements=(
            VariableDeclaration(name="b", initializer=NumberLiteral(value=2)),
        )),
    ))
    result = executor.execute(outer)
    assert result.error is None
    assert not executor.environment.has("a")
    assert not executor.environment.has("b")
