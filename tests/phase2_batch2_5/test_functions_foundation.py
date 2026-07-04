from __future__ import annotations

from compiler.ast import (
    BlockNode,
    CallExpression,
    FunctionDeclaration,
    IdentifierExpression,
    NumberLiteral,
    ReturnStatement,
    StringLiteral,
    VariableDeclaration,
)
from compiler.runtime import (
    EvaluationError,
    ExpressionEvaluator,
    StatementExecutor,
    VariableEnvironment,
    execute_source,
)


def test_function_declaration_ast():
    decl = FunctionDeclaration(
        name="greet",
        params=("name",),
        body=BlockNode(),
    )
    assert decl.name == "greet"
    assert decl.params == ("name",)
    assert decl.body is not None


def test_function_declaration_no_params():
    decl = FunctionDeclaration(name="hello", body=BlockNode())
    assert decl.params == ()


def test_function_declaration_children():
    body = BlockNode()
    decl = FunctionDeclaration(name="f", body=body)
    assert decl.children() == (body,)


def test_function_declaration_no_body_children():
    decl = FunctionDeclaration(name="f")
    assert decl.children() == ()


def test_parse_fn_no_params_from_source():
    source = 'panther main { fn hello() { print(42); } hello(); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["42"]


def test_parse_fn_with_params_and_call():
    source = '''
panther main {
    fn double(x) {
        print(x * 2);
    }
    double(5);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["10"]


def test_parse_fn_return_value():
    source = '''
panther main {
    fn add(a, b) {
        return a + b;
    }
    let result = add(3, 4);
    print(result);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["7"]


def test_parse_fn_multiple_calls():
    source = '''
panther main {
    fn inc(x) {
        return x + 1;
    }
    print(inc(1));
    print(inc(5));
    print(inc(10));
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["2", "6", "11"]


def test_parse_fn_no_return():
    source = '''
panther main {
    fn say(msg) {
        print(msg);
    }
    say("hello");
    say("world");
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["hello", "world"]


def test_parse_fn_scoped_variables():
    source = '''
panther main {
    let x = 10;
    fn show() {
        print(x);
    }
    show();
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["10"]


def test_parse_fn_parameter_shadows_outer():
    source = '''
panther main {
    let x = 10;
    fn set_x(x) {
        print(x);
    }
    set_x(99);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["99"]


def test_parse_fn_nested_calls():
    source = '''
panther main {
    fn double(x) {
        return x * 2;
    }
    fn add(a, b) {
        return a + b;
    }
    print(add(double(3), double(4)));
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["14"]


def test_callexpression_ast():
    call = CallExpression(
        callee=IdentifierExpression(name="greet"),
        arguments=(StringLiteral(value="Panther"),),
    )
    assert call.callee is not None
    assert len(call.arguments) == 1


def test_call_with_expression_args():
    source = '''
panther main {
    fn multiply(a, b) {
        return a * b;
    }
    print(multiply(2 + 3, 4));
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["20"]


def test_fn_defined_after_call_in_source():
    source = '''
panther main {
    fn greet(name) {
        print(name);
    }
    greet("world");
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["world"]


def test_execute_fn_declaration_only():
    executor = StatementExecutor()
    decl = FunctionDeclaration(name="noop", body=BlockNode())
    result = executor.execute(decl)
    assert result.error is None
    assert executor.environment.has_function("noop")


def test_parse_fn_with_multiple_params():
    source = '''
panther main {
    fn sum3(a, b, c) {
        return a + b + c;
    }
    print(sum3(1, 2, 3));
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["6"]


def test_parse_fn_empty_body():
    source = 'panther main { fn nothing() { } print("ok"); }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ok"]


def test_parse_fn_parameter_used_in_expression():
    source = '''
panther main {
    fn square(n) {
        return n * n;
    }
    print(square(7));
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["49"]


def test_parse_fn_call_undefined_function():
    source = 'panther main { undefined_fn(); }'
    result = execute_source(source)
    assert result.error is not None
    assert "Undefined function" in result.error


def test_parse_fn_compound_assign_in_body():
    source = '''
panther main {
    fn accumulate() {
        let total = 0;
        total += 10;
        print(total);
    }
    accumulate();
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["10"]


def test_parse_fn_if_inside_body():
    source = '''
panther main {
    fn check(x) {
        if x > 0 {
            print("pos");
        } else {
            print("neg");
        }
    }
    check(5);
    check(-1);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["pos", "neg"]


def test_parse_fn_for_loop_in_body():
    source = '''
panther main {
    fn print_range(n) {
        for i in 1..n {
            print(i);
        }
    }
    print_range(3);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["1", "2", "3"]


def test_parse_fn_while_loop_in_body():
    source = '''
panther main {
    fn countdown(n) {
        while n > 0 {
            print(n);
            n = n - 1;
        }
    }
    countdown(3);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["3", "2", "1"]


def test_parse_fn_recursive():
    source = '''
panther main {
    fn factorial(n) {
        if n <= 1 {
            return 1;
        }
        return n * factorial(n - 1);
    }
    print(factorial(5));
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["120"]


def test_parse_fn_declaration_in_block():
    source = '''
panther main {
    let x = 1;
    fn inc() {
        return x + 1;
    }
    print(inc());
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["2"]


def test_call_expression_in_expression():
    source = '''
panther main {
    fn double(x) {
        return x * 2;
    }
    let result = double(5) + 3;
    print(result);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["13"]
