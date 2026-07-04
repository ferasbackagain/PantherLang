from compiler.ast import BlockNode, BreakStatement, LoopStatement
from compiler.runtime import execute_source


def test_loop_statement_ast():
    stmt = LoopStatement(body=BlockNode())
    assert stmt.body is not None
    assert stmt.children() == (stmt.body,)


def test_loop_empty_body():
    stmt = LoopStatement()
    assert stmt.children() == ()


def test_loop_basic():
    source = '''
panther main {
    let i = 0;
    loop {
        i = i + 1;
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


def test_loop_continue():
    source = '''
panther main {
    let i = 0;
    loop {
        i = i + 1;
        if i == 3 {
            continue;
        }
        if i > 5 {
            break;
        }
        print(i);
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["1", "2", "4", "5"]


def test_loop_break_immediately():
    source = 'panther main { loop { break; } }'
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == []


def test_loop_nested_break():
    source = '''
panther main {
    let out = 0;
    loop {
        out = out + 1;
        let inner = 0;
        loop {
            inner = inner + 1;
            if inner == 2 {
                break;
            }
        }
        if out == 3 {
            break;
        }
    }
    print(out);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["3"]


def test_loop_inside_while():
    source = '''
panther main {
    let i = 0;
    while i < 3 {
        let j = 0;
        loop {
            j = j + 1;
            print(i * 10 + j);
            if j == 2 {
                break;
            }
        }
        i = i + 1;
    }
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["1", "2", "11", "12", "21", "22"]


def test_loop_with_return():
    source = '''
panther main {
    fn find() {
        let i = 0;
        loop {
            i = i + 1;
            if i == 5 {
                return i;
            }
        }
    }
    print(find());
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["5"]
