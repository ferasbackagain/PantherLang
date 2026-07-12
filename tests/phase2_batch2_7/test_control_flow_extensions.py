from compiler.ast import (
    BinaryExpression,
    BlockNode,
    BooleanLiteral,
    BreakStatement,
    ContinueStatement,
    ElifBranch,
    ExpressionStatement,
    ForStatement,
    IdentifierExpression,
    IfStatement,
    NumberLiteral,
    PrintStatement,
    StringLiteral,
    VariableDeclaration,
    WhileStatement,
)
from compiler.runtime import StatementExecutor, execute_source


def test_break_statement_ast():
    stmt = BreakStatement()
    assert stmt is not None
    assert stmt.children() == ()


def test_continue_statement_ast():
    stmt = ContinueStatement()
    assert stmt is not None
    assert stmt.children() == ()


def test_elif_branch_ast():
    branch = ElifBranch(
        condition=BooleanLiteral(value=True),
        body=BlockNode(),
    )
    assert branch.condition is not None
    assert branch.body is not None


def test_while_break():
    source = '''
panther main {
    let i = 0;
    while i < 10 {
        if i == 3 {
            break;
        }
        print(i);
        i = i + 1;
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["0", "1", "2"]


def test_while_continue():
    source = '''
panther main {
    let i = 0;
    while i < 5 {
        i = i + 1;
        if i == 3 {
            continue;
        }
        print(i);
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["1", "2", "4", "5"]


def test_for_break():
    source = '''
panther main {
    for i in 1..5 {
        if i == 3 {
            break;
        }
        print(i);
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["1", "2"]


def test_for_continue():
    source = '''
panther main {
    for i in 1..5 {
        if i == 3 {
            continue;
        }
        print(i);
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["1", "2", "4", "5"]


def test_break_in_nested_block():
    from compiler.ast import AssignmentStatement
    executor = StatementExecutor()
    executor.environment.define("x", 0)
    while_stmt = WhileStatement(
        condition=BooleanLiteral(value=True),
        body=BlockNode(statements=(
            IfStatement(
                condition=BinaryExpression(
                    left=IdentifierExpression(name="x"),
                    operator=">=",
                    right=NumberLiteral(value=3),
                ),
                then_block=BlockNode(statements=(BreakStatement(),)),
            ),
            PrintStatement(expression=IdentifierExpression(name="x")),
            AssignmentStatement(
                target=IdentifierExpression(name="x"),
                value=BinaryExpression(
                    left=IdentifierExpression(name="x"),
                    operator="+",
                    right=NumberLiteral(value=1),
                ),
            ),
        )),
    )
    result = executor.execute(while_stmt)
    assert result.error is None
    assert result.captured_output == ["0", "1", "2"]


def test_continue_skips_rest_of_iteration():
    from compiler.ast import AssignmentStatement
    executor = StatementExecutor()
    executor.environment.define("i", 0)
    while_stmt = WhileStatement(
        condition=BinaryExpression(
            left=IdentifierExpression(name="i"),
            operator="<",
            right=NumberLiteral(value=5),
        ),
        body=BlockNode(statements=(
            AssignmentStatement(
                target=IdentifierExpression(name="i"),
                value=BinaryExpression(
                    left=IdentifierExpression(name="i"),
                    operator="+",
                    right=NumberLiteral(value=1),
                ),
            ),
            IfStatement(
                condition=BinaryExpression(
                    left=IdentifierExpression(name="i"),
                    operator="==",
                    right=NumberLiteral(value=3),
                ),
                then_block=BlockNode(statements=(ContinueStatement(),)),
            ),
            PrintStatement(expression=IdentifierExpression(name="i")),
        )),
    )
    result = executor.execute(while_stmt)
    assert result.error is None
    assert result.captured_output == ["1", "2", "4", "5"]


def test_elif_single_branch():
    source = '''
panther main {
    let x = 5;
    if x > 10 {
        print("big");
    } elif x > 3 {
        print("medium");
    } else {
        print("small");
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["medium"]


def test_elif_multiple_branches():
    source = '''
panther main {
    let x = 0;
    if x > 10 {
        print("big");
    } elif x > 5 {
        print("medium");
    } elif x > 0 {
        print("small");
    } else {
        print("zero");
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["zero"]


def test_elif_no_else():
    source = '''
panther main {
    let x = 7;
    if x > 10 {
        print("big");
    } elif x > 5 {
        print("medium");
    } elif x > 0 {
        print("small");
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["medium"]


def test_elif_first_branch_taken():
    source = '''
panther main {
    let x = 15;
    if x > 10 {
        print("first");
    } elif x > 5 {
        print("second");
    } elif x > 0 {
        print("third");
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["first"]


def test_elif_second_branch_taken():
    source = '''
panther main {
    let x = 7;
    if x > 10 {
        print("first");
    } elif x > 5 {
        print("second");
    } elif x > 0 {
        print("third");
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["second"]


def test_break_outside_loop_errors():
    source = 'panther main { break; }'
    result = execute_source(source)
    assert result.error is not None


def test_error_in_if_body_propagates():
    """Verify errors inside if body propagate (regression for silent swallow)."""
    result = execute_source('''
panther main {
    if true {
        let x = 1 / 0;
    }
}
''')
    assert result.error is not None
    assert "Division by zero" in result.error


def test_error_in_while_body_propagates():
    """Verify errors inside while body propagate (regression for silent swallow)."""
    result = execute_source('''
panther main {
    let i = 0;
    while i < 3 {
        if i == 1 {
            let x = 1 / 0;
        }
        i = i + 1;
    }
}
''')
    assert result.error is not None
    assert "Division by zero" in result.error


def test_continue_outside_loop_errors():
    source = 'panther main { continue; }'
    result = execute_source(source)
    assert result.error is not None


def test_parse_break_from_source():
    result = execute_source('panther main { while true { break; } }')
    assert result.error is None


def test_parse_continue_from_source():
    result = execute_source('''
panther main {
    let i = 0;
    while i < 3 {
        i = i + 1;
        if i == 2 { continue; }
        print(i);
    }
}
''')
    assert result.error is None
    assert result.captured_output == ["1", "3"]


def test_elif_with_break():
    source = '''
panther main {
    for i in 1..5 {
        if i == 1 {
            print("one");
        } elif i == 3 {
            print("three");
        } elif i == 5 {
            break;
        } else {
            print(i);
        }
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["one", "2", "three", "4"]


def test_while_true_break():
    source = '''
panther main {
    let i = 0;
    while true {
        i = i + 1;
        if i > 3 {
            break;
        }
        print(i);
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["1", "2", "3"]
