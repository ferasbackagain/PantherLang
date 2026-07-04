from __future__ import annotations

from compiler.ast import (
    AssignmentStatement,
    BinaryExpression,
    IdentifierExpression,
    NumberLiteral,
    StringLiteral,
    VariableDeclaration,
)
from compiler.runtime import (
    ExecutionResult,
    ExpressionEvaluator,
    RedeclarationError,
    StatementExecutor,
    UndefinedVariableError,
    VariableEnvironment,
    execute_source,
)


def test_simple_assignment_execution():
    executor = StatementExecutor()
    executor.environment.define("x", 10)
    target = IdentifierExpression(name="x")
    value = NumberLiteral(value=99)
    stmt = AssignmentStatement(target=target, value=value)
    result = executor.execute(stmt)
    assert result.error is None
    assert executor.environment.lookup("x") == 99


def test_assignment_operator_default():
    stmt = AssignmentStatement(
        target=IdentifierExpression(name="x"),
        value=NumberLiteral(value=5),
    )
    assert stmt.operator == "="


def test_assignment_operator_custom():
    stmt = AssignmentStatement(
        target=IdentifierExpression(name="x"),
        value=NumberLiteral(value=5),
        operator="+=",
    )
    assert stmt.operator == "+="


def test_compound_assign_plus():
    executor = StatementExecutor()
    executor.environment.define("x", 10)
    stmt = AssignmentStatement(
        target=IdentifierExpression(name="x"),
        value=NumberLiteral(value=3),
        operator="+=",
    )
    executor.execute(stmt)
    assert executor.environment.lookup("x") == 13


def test_compound_assign_minus():
    executor = StatementExecutor()
    executor.environment.define("x", 10)
    stmt = AssignmentStatement(
        target=IdentifierExpression(name="x"),
        value=NumberLiteral(value=4),
        operator="-=",
    )
    executor.execute(stmt)
    assert executor.environment.lookup("x") == 6


def test_compound_assign_multiply():
    executor = StatementExecutor()
    executor.environment.define("x", 5)
    stmt = AssignmentStatement(
        target=IdentifierExpression(name="x"),
        value=NumberLiteral(value=3),
        operator="*=",
    )
    executor.execute(stmt)
    assert executor.environment.lookup("x") == 15


def test_compound_assign_divide():
    executor = StatementExecutor()
    executor.environment.define("x", 10)
    stmt = AssignmentStatement(
        target=IdentifierExpression(name="x"),
        value=NumberLiteral(value=3),
        operator="/=",
    )
    executor.execute(stmt)
    assert executor.environment.lookup("x") == 3


def test_compound_assign_modulo():
    executor = StatementExecutor()
    executor.environment.define("x", 10)
    stmt = AssignmentStatement(
        target=IdentifierExpression(name="x"),
        value=NumberLiteral(value=3),
        operator="%=",
    )
    executor.execute(stmt)
    assert executor.environment.lookup("x") == 1


def test_compound_assign_undefined_raises():
    executor = StatementExecutor()
    stmt = AssignmentStatement(
        target=IdentifierExpression(name="unknown"),
        value=NumberLiteral(value=1),
        operator="+=",
    )
    result = executor.execute(stmt)
    assert result.error is not None
    assert "Undefined variable" in result.error


def test_compound_assign_with_expression_rhs():
    executor = StatementExecutor()
    executor.environment.define("x", 2)
    executor.environment.define("y", 3)
    rhs = BinaryExpression(
        left=IdentifierExpression(name="y"),
        operator="+",
        right=NumberLiteral(value=1),
    )
    stmt = AssignmentStatement(
        target=IdentifierExpression(name="x"),
        value=rhs,
        operator="*=",
    )
    executor.execute(stmt)
    assert executor.environment.lookup("x") == 8  # 2 * (3 + 1)


def test_execute_source_let_and_print():
    source = '''
panther main {
    let x = 42;
    print(x);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["42"]


def test_execute_source_let_string():
    source = 'panther main { let name = "Panther"; print(name); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["Panther"]


def test_execute_source_assignment():
    source = '''
panther main {
    let x = 10;
    x = 99;
    print(x);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["99"]


def test_execute_source_compound_assign():
    source = '''
panther main {
    let x = 10;
    x += 5;
    print(x);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["15"]


def test_execute_source_multiple_compound_assigns():
    source = '''
panther main {
    let x = 100;
    x -= 20;
    print(x);
    x *= 2;
    print(x);
    x /= 5;
    print(x);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["80", "160", "32"]


def test_execute_source_let_no_initializer():
    source = 'panther main { let x; x = 42; print(x); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["42"]


def test_execute_source_return_ends_execution():
    source = '''
panther main {
    let x = 1;
    return;
    x = 99;
    print(x);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.return_value is None


def test_execute_source_syntax_error():
    source = 'panther main { let x = 1 }'
    result = execute_source(source)
    assert result.error is not None
    assert "Parse error" in result.error


def test_execute_source_undefined_variable():
    source = 'panther main { print(z); }'
    result = execute_source(source)
    assert result.error is not None
    assert "Undefined variable" in result.error


def test_execute_source_multiple_blocks():
    source = '''
panther main {
    let msg = "hello";
    print(msg);
}
test "verify" {
    print("test");
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["hello", "test"]


def test_execute_source_boolean_print():
    source = 'panther main { let a = true; let b = false; print(a); print(b); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["true", "false"]


def test_execute_source_null_print():
    source = 'panther main { let n = null; print(n); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["null"]


def test_execute_source_if_true():
    source = '''
panther main {
    let x = 5;
    if x > 3 {
        print("big");
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["big"]


def test_execute_source_if_else():
    source = '''
panther main {
    let x = 1;
    if x > 3 {
        print("big");
    } else {
        print("small");
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["small"]


def test_execute_source_while_loop():
    source = '''
panther main {
    let i = 0;
    while i < 3 {
        print(i);
        i = i + 1;
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["0", "1", "2"]


def test_execute_source_for_range():
    source = '''
panther main {
    for i in 1..3 {
        print(i);
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["1", "2", "3"]


def test_execute_source_for_with_compound_inside():
    source = '''
panther main {
    let total = 0;
    for i in 1..5 {
        total += i;
    }
    print(total);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["15"]


def test_execute_source_program_with_environment():
    env = VariableEnvironment()
    env.define("initial", 100)
    source = 'panther main { print(initial); }'
    result = execute_source(source, env)
    assert result.error is None
    assert result.captured_output == ["100"]


def test_execute_source_empty_program():
    source = 'panther main { }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == []


def test_execute_source_expression_statement():
    source = 'panther main { let x = 10; x + 5; print(x); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["10"]


def test_assignment_statement_ast_operator_serialized():
    from compiler.ast import ast_to_dict
    stmt = AssignmentStatement(
        target=IdentifierExpression(name="x"),
        value=NumberLiteral(value=5),
        operator="+=",
    )
    data = ast_to_dict(stmt)
    assert data["operator"] == "+="


def test_execute_source_modulo_compound():
    source = '''
panther main {
    let x = 17;
    x %= 5;
    print(x);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["2"]


def test_execute_source_divide_by_zero():
    source = '''
panther main {
    let x = 10;
    x /= 0;
}
'''
    result = execute_source(source)
    assert result.error is not None
