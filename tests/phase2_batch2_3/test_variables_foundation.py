from __future__ import annotations

from compiler.ast import (
    AssignmentStatement,
    BinaryExpression,
    BlockNode,
    BooleanLiteral,
    ExpressionStatement,
    ForStatement,
    IdentifierExpression,
    IfStatement,
    NullLiteral,
    NumberLiteral,
    PrintStatement,
    ReturnStatement,
    StringLiteral,
    UnaryExpression,
    VariableDeclaration,
    WhileStatement,
)
from compiler.runtime import (
    EvaluationError,
    ExpressionEvaluator,
    RedeclarationError,
    StatementExecutor,
    UndefinedVariableError,
    VariableEnvironment,
)


def test_variable_environment_define_and_lookup():
    env = VariableEnvironment()
    env.define("x", 42)
    assert env.lookup("x") == 42
    assert env.has("x")


def test_variable_environment_define_without_value():
    env = VariableEnvironment()
    env.define("y")
    assert env.lookup("y") is None
    assert env.has("y")


def test_variable_environment_redeclaration_raises():
    env = VariableEnvironment()
    env.define("x", 1)
    try:
        env.define("x", 2)
        assert False, "Expected RedeclarationError"
    except RedeclarationError:
        pass


def test_variable_environment_assign():
    env = VariableEnvironment()
    env.define("x", 1)
    env.assign("x", 99)
    assert env.lookup("x") == 99


def test_variable_environment_assign_undefined_raises():
    env = VariableEnvironment()
    try:
        env.assign("nonexistent", 42)
        assert False, "Expected UndefinedVariableError"
    except UndefinedVariableError:
        pass


def test_variable_environment_lookup_undefined_raises():
    env = VariableEnvironment()
    try:
        env.lookup("unknown")
        assert False, "Expected UndefinedVariableError"
    except UndefinedVariableError:
        pass


def test_variable_environment_snapshot():
    env = VariableEnvironment()
    env.define("a", 1)
    env.define("b", "two")
    snap = env.snapshot()
    assert snap == {"a": 1, "b": "two"}


def test_expression_evaluator_number_literal():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    assert ev.evaluate(NumberLiteral(value=42)) == 42
    assert ev.evaluate(NumberLiteral(value=3.14)) == 3.14


def test_expression_evaluator_string_literal():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    assert ev.evaluate(StringLiteral(value="hello")) == "hello"


def test_expression_evaluator_boolean_literal():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    assert ev.evaluate(BooleanLiteral(value=True)) is True
    assert ev.evaluate(BooleanLiteral(value=False)) is False


def test_expression_evaluator_null_literal():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    assert ev.evaluate(NullLiteral()) is None


def test_expression_evaluator_identifier():
    env = VariableEnvironment()
    env.define("x", 100)
    ev = ExpressionEvaluator(env)
    assert ev.evaluate(IdentifierExpression(name="x")) == 100


def test_expression_evaluator_identifier_undefined():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    try:
        ev.evaluate(IdentifierExpression(name="unknown"))
        assert False, "Expected UndefinedVariableError"
    except UndefinedVariableError:
        pass


def test_expression_evaluator_unary_minus():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    expr = UnaryExpression(operator="-", operand=NumberLiteral(value=5))
    assert ev.evaluate(expr) == -5


def test_expression_evaluator_unary_not():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    expr = UnaryExpression(operator="!", operand=BooleanLiteral(value=True))
    assert ev.evaluate(expr) is False


def test_expression_evaluator_binary_addition():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    expr = BinaryExpression(
        left=NumberLiteral(value=3),
        operator="+",
        right=NumberLiteral(value=4),
    )
    assert ev.evaluate(expr) == 7


def test_expression_evaluator_binary_comparison():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    expr = BinaryExpression(
        left=NumberLiteral(value=10),
        operator=">",
        right=NumberLiteral(value=5),
    )
    assert ev.evaluate(expr) is True


def test_expression_evaluator_binary_equality():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    expr = BinaryExpression(
        left=StringLiteral(value="abc"),
        operator="==",
        right=StringLiteral(value="abc"),
    )
    assert ev.evaluate(expr) is True


def test_expression_evaluator_binary_logical_and():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    expr = BinaryExpression(
        left=BooleanLiteral(value=True),
        operator="&&",
        right=BooleanLiteral(value=False),
    )
    assert ev.evaluate(expr) is False


def test_expression_evaluator_grouping():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    inner = BinaryExpression(
        left=NumberLiteral(value=1),
        operator="+",
        right=NumberLiteral(value=2),
    )
    grouped = GroupingExpression(expression=inner)
    assert ev.evaluate(grouped) == 3


def test_expression_evaluator_complex_expression():
    env = VariableEnvironment()
    env.define("x", 10)
    ev = ExpressionEvaluator(env)
    expr = BinaryExpression(
        left=BinaryExpression(
            left=IdentifierExpression(name="x"),
            operator="*",
            right=NumberLiteral(value=2),
        ),
        operator="+",
        right=NumberLiteral(value=5),
    )
    assert ev.evaluate(expr) == 25


def test_execute_variable_declaration():
    executor = StatementExecutor()
    stmt = VariableDeclaration(name="x", initializer=NumberLiteral(value=42))
    result = executor.execute(stmt)
    assert result.error is None
    assert executor.environment.lookup("x") == 42


def test_execute_variable_declaration_no_initializer():
    executor = StatementExecutor()
    stmt = VariableDeclaration(name="x")
    result = executor.execute(stmt)
    assert result.error is None
    assert executor.environment.lookup("x") is None


def test_execute_print():
    executor = StatementExecutor()
    executor.environment.define("msg", "hello")
    stmt = PrintStatement(expression=IdentifierExpression(name="msg"))
    result = executor.execute(stmt)
    assert result.error is None
    assert result.captured_output == ["hello"]


def test_execute_print_number():
    executor = StatementExecutor()
    stmt = PrintStatement(expression=NumberLiteral(value=99))
    result = executor.execute(stmt)
    assert result.captured_output == ["99"]


def test_execute_print_boolean():
    executor = StatementExecutor()
    stmt = PrintStatement(expression=BooleanLiteral(value=True))
    result = executor.execute(stmt)
    assert result.captured_output == ["true"]


def test_execute_print_null():
    executor = StatementExecutor()
    stmt = PrintStatement(expression=NullLiteral())
    result = executor.execute(stmt)
    assert result.captured_output == ["null"]


def test_execute_assignment():
    executor = StatementExecutor()
    executor.environment.define("x", 1)
    target = IdentifierExpression(name="x")
    value = NumberLiteral(value=100)
    stmt = AssignmentStatement(target=target, value=value)
    result = executor.execute(stmt)
    assert result.error is None
    assert executor.environment.lookup("x") == 100


def test_execute_assignment_undefined_raises():
    executor = StatementExecutor()
    target = IdentifierExpression(name="nonexistent")
    stmt = AssignmentStatement(target=target, value=NumberLiteral(value=1))
    result = executor.execute(stmt)
    assert result.error is not None
    assert "Undefined variable" in result.error


def test_execute_block():
    executor = StatementExecutor()
    block = BlockNode(statements=(
        VariableDeclaration(name="a", initializer=NumberLiteral(value=1)),
        VariableDeclaration(name="b", initializer=NumberLiteral(value=2)),
        PrintStatement(expression=IdentifierExpression(name="a")),
    ))
    result = executor.execute(block)
    assert result.error is None
    assert result.captured_output == ["1"]
    assert not executor.environment.has("a")
    assert not executor.environment.has("b")


def test_execute_if_true_branch():
    executor = StatementExecutor()
    if_stmt = IfStatement(
        condition=BooleanLiteral(value=True),
        then_block=BlockNode(statements=(
            VariableDeclaration(name="result", initializer=StringLiteral(value="then")),
        )),
    )
    result = executor.execute(if_stmt)
    assert result.error is None
    assert not executor.environment.has("result")


def test_execute_if_false_no_else():
    executor = StatementExecutor()
    if_stmt = IfStatement(
        condition=BooleanLiteral(value=False),
        then_block=BlockNode(statements=(
            VariableDeclaration(name="result", initializer=StringLiteral(value="then")),
        )),
    )
    result = executor.execute(if_stmt)
    assert result.error is None
    assert not executor.environment.has("result")


def test_execute_if_else_branch():
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


def test_execute_while_loop():
    executor = StatementExecutor()
    executor.environment.define("counter", 0)
    while_stmt = WhileStatement(
        condition=BinaryExpression(
            left=IdentifierExpression(name="counter"),
            operator="<",
            right=NumberLiteral(value=3),
        ),
        body=BlockNode(statements=(
            PrintStatement(expression=IdentifierExpression(name="counter")),
            AssignmentStatement(
                target=IdentifierExpression(name="counter"),
                value=BinaryExpression(
                    left=IdentifierExpression(name="counter"),
                    operator="+",
                    right=NumberLiteral(value=1),
                ),
            ),
        )),
    )
    result = executor.execute(while_stmt)
    assert result.error is None
    assert executor.environment.lookup("counter") == 3
    assert result.captured_output == ["0", "1", "2"]


def test_execute_for_range_loop():
    executor = StatementExecutor()
    for_stmt = ForStatement(
        var="i",
        start=NumberLiteral(value=1),
        end=NumberLiteral(value=3),
        body=BlockNode(statements=(
            PrintStatement(expression=IdentifierExpression(name="i")),
        )),
    )
    result = executor.execute(for_stmt)
    assert result.error is None
    assert result.captured_output == ["1", "2", "3"]


def test_execute_return_statement():
    executor = StatementExecutor()
    stmt = ReturnStatement(expression=NumberLiteral(value=42))
    result = executor.execute(stmt)
    assert result.return_value == 42


def test_execute_return_without_value():
    executor = StatementExecutor()
    stmt = ReturnStatement()
    result = executor.execute(stmt)
    assert result.return_value is None


def test_execute_program_multiple_statements():
    executor = StatementExecutor()
    stmts = [
        VariableDeclaration(name="x", initializer=NumberLiteral(value=10)),
        VariableDeclaration(name="y", initializer=NumberLiteral(value=20)),
        PrintStatement(expression=IdentifierExpression(name="x")),
        AssignmentStatement(
            target=IdentifierExpression(name="x"),
            value=BinaryExpression(
                left=IdentifierExpression(name="x"),
                operator="+",
                right=IdentifierExpression(name="y"),
            ),
        ),
        PrintStatement(expression=IdentifierExpression(name="x")),
    ]
    result = executor.run(stmts)
    assert result.error is None
    assert result.captured_output == ["10", "30"]


def test_execute_let_with_identifier_expression():
    executor = StatementExecutor()
    executor.environment.define("base", 5)
    stmt = VariableDeclaration(
        name="derived",
        initializer=BinaryExpression(
            left=IdentifierExpression(name="base"),
            operator="*",
            right=NumberLiteral(value=2),
        ),
    )
    result = executor.execute(stmt)
    assert result.error is None
    assert executor.environment.lookup("derived") == 10


def test_execute_nested_blocks_preserve_output():
    executor = StatementExecutor()
    outer_block = BlockNode(statements=(
        VariableDeclaration(name="a", initializer=NumberLiteral(value=1)),
        BlockNode(statements=(
            PrintStatement(expression=IdentifierExpression(name="a")),
        )),
    ))
    result = executor.execute(outer_block)
    assert result.error is None
    assert result.captured_output == ["1"]


def test_expression_evaluator_binary_multiplication():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    expr = BinaryExpression(
        left=NumberLiteral(value=6),
        operator="*",
        right=NumberLiteral(value=7),
    )
    assert ev.evaluate(expr) == 42


def test_expression_evaluator_binary_subtraction():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    expr = BinaryExpression(
        left=NumberLiteral(value=10),
        operator="-",
        right=NumberLiteral(value=3),
    )
    assert ev.evaluate(expr) == 7


def test_for_loop_empty_body():
    executor = StatementExecutor()
    for_stmt = ForStatement(
        var="i",
        start=NumberLiteral(value=1),
        end=NumberLiteral(value=0),
    )
    result = executor.execute(for_stmt)
    assert result.error is None


def test_execute_if_with_complex_condition():
    executor = StatementExecutor()
    executor.environment.define("x", 5)
    if_stmt = IfStatement(
        condition=BinaryExpression(
            left=IdentifierExpression(name="x"),
            operator=">",
            right=NumberLiteral(value=3),
        ),
        then_block=BlockNode(statements=(
            VariableDeclaration(name="status", initializer=StringLiteral(value="big")),
        )),
    )
    result = executor.execute(if_stmt)
    assert result.error is None
    assert not executor.environment.has("status")


def test_while_never_enters():
    executor = StatementExecutor()
    executor.environment.define("x", 0)
    while_stmt = WhileStatement(
        condition=BinaryExpression(
            left=IdentifierExpression(name="x"),
            operator=">",
            right=NumberLiteral(value=100),
        ),
        body=BlockNode(statements=(
            VariableDeclaration(name="side", initializer=NumberLiteral(value=999)),
        )),
    )
    result = executor.execute(while_stmt)
    assert result.error is None
    assert not executor.environment.has("side")


def test_for_loop_with_variable_end():
    executor = StatementExecutor()
    executor.environment.define("limit", 2)
    for_stmt = ForStatement(
        var="i",
        start=NumberLiteral(value=1),
        end=IdentifierExpression(name="limit"),
        body=BlockNode(statements=(
            PrintStatement(expression=IdentifierExpression(name="i")),
        )),
    )
    result = executor.execute(for_stmt)
    assert result.error is None
    assert result.captured_output == ["1", "2"]


from compiler.ast import GroupingExpression


def test_execute_program_with_all_statement_types():
    executor = StatementExecutor()
    stmts = [
        VariableDeclaration(name="total", initializer=NumberLiteral(value=0)),
        VariableDeclaration(name="i", initializer=NumberLiteral(value=1)),
        WhileStatement(
            condition=BinaryExpression(
                left=IdentifierExpression(name="i"),
                operator="<=",
                right=NumberLiteral(value=3),
            ),
            body=BlockNode(statements=(
                AssignmentStatement(
                    target=IdentifierExpression(name="total"),
                    value=BinaryExpression(
                        left=IdentifierExpression(name="total"),
                        operator="+",
                        right=IdentifierExpression(name="i"),
                    ),
                ),
                AssignmentStatement(
                    target=IdentifierExpression(name="i"),
                    value=BinaryExpression(
                        left=IdentifierExpression(name="i"),
                        operator="+",
                        right=NumberLiteral(value=1),
                    ),
                ),
            )),
        ),
        PrintStatement(expression=IdentifierExpression(name="total")),
    ]
    result = executor.run(stmts)
    assert result.error is None
    assert result.captured_output == ["6"]


def test_expression_evaluator_unsupported_operator():
    env = VariableEnvironment()
    ev = ExpressionEvaluator(env)
    expr = BinaryExpression(
        left=NumberLiteral(value=1),
        operator=">>>",
        right=NumberLiteral(value=2),
    )
    try:
        ev.evaluate(expr)
        assert False, "Expected EvaluationError"
    except EvaluationError:
        pass


def test_execute_expression_statement():
    executor = StatementExecutor()
    executor.environment.define("x", 5)
    stmt = ExpressionStatement(expression=IdentifierExpression(name="x"))
    result = executor.execute(stmt)
    assert result.error is None
