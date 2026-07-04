from compiler.runtime import (
    ExecutionResult,
    StatementExecutor,
    UndefinedVariableError,
    VariableEnvironment,
    execute_source,
)


def test_execute_source_simple():
    result = execute_source('panther main { let x = 42; }')
    assert result.error is None
    assert result.captured_output == []


def test_execute_source_print():
    result = execute_source('panther main { print("hello"); }')
    assert result.error is None
    assert result.captured_output == ["hello"]


def test_execute_source_print_number():
    result = execute_source('panther main { print(42); }')
    assert result.error is None
    assert result.captured_output == ["42"]


def test_execute_source_expression():
    result = execute_source('panther main { let x = 1 + 2 * 3; print(x); }')
    assert result.error is None
    assert result.captured_output == ["7"]


def test_execute_source_function_call():
    result = execute_source('panther main { fn f(): int { return 99; }; let r = f(); print(r); }')
    assert result.error is None
    assert result.captured_output == ["99"]


def test_execute_source_nested_blocks():
    result = execute_source('panther main { let x = 1; { let y = 2; print(x + y); } }')
    assert result.error is None
    assert result.captured_output == ["3"]


def test_execute_source_if_else():
    result = execute_source('panther main { let x = 10; if x > 5 { print("big"); } else { print("small"); } }')
    assert result.error is None
    assert result.captured_output == ["big"]


def test_execute_source_while_loop():
    result = execute_source('panther main { let i = 0; while i < 3 { print(i); i = i + 1; } }')
    assert result.error is None
    assert result.captured_output == ["0", "1", "2"]


def test_execute_source_for_loop():
    result = execute_source('panther main { for i in 1..3 { print(i); } }')
    assert result.error is None
    assert result.captured_output == ["1", "2", "3"]


def test_execute_source_break():
    source = """
    panther main {
        let i = 0;
        while i < 10 {
            if i == 2 { break; }
            print(i);
            i = i + 1;
        }
    }
    """
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["0", "1"]


def test_execute_source_recursion():
    source = """
    panther main {
        fn fact(n: int): int {
            if n <= 1 { return 1; }
            return n * fact(n - 1);
        }
        print(fact(5));
    }
    """
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["120"]


def test_execute_source_parse_error():
    result = execute_source('panther main { } }')
    assert result.error is not None
    assert "Parse error" in str(result.error)


def test_variable_environment_scope_isolation():
    env = VariableEnvironment()
    env.define("x", 10)
    child = VariableEnvironment(parent=env)
    child.define("y", 20)
    assert child.lookup("x") == 10
    assert child.lookup("y") == 20
    assert env.lookup("x") == 10
    try:
        env.lookup("y")
        assert False, "should raise"
    except UndefinedVariableError:
        pass


def test_execute_source_output_isolation():
    result1 = execute_source('panther main { print("a"); }')
    result2 = execute_source('panther main { print("b"); }')
    assert result1.captured_output == ["a"]
    assert result2.captured_output == ["b"]


def test_execute_source_chain():
    env = VariableEnvironment()
    env.define("acc", 0)
    result = execute_source('panther main { print(acc); }', environment=env)
    assert result.error is None
    assert result.captured_output == ["0"]
