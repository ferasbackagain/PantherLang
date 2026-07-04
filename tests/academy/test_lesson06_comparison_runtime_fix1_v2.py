from compiler.runtime import execute_source


def run(src: str):
    result = execute_source(src)
    assert result.error is None, result.error
    return [str(x).lower() for x in result.captured_output]


def run_error(src: str):
    result = execute_source(src)
    assert result.error is not None
    return result.error


def test_number_comparisons():
    out = run('''
panther main {
    print 100 == 100;
    print 100 != 100;
    print 100 > 50;
    print 100 < 50;
    print 100 >= 100;
    print 100 <= 99;
}
''')
    assert out == ["true", "false", "true", "false", "true", "false"]


def test_string_comparisons():
    out = run('''
panther main {
    print "abc" == "abc";
    print "abc" != "xyz";
}
''')
    assert out == ["true", "true"]


def test_bool_comparisons():
    out = run('''
panther main {
    print true == true;
    print true == false;
    print false != true;
}
''')
    assert out == ["true", "false", "true"]


def test_number_string_equality_is_pt002():
    err = run_error('''
panther main {
    let a = 100;
    let b = "100";
    print a == b;
}
''')
    assert "PT002" in err


def test_number_string_inequality_is_pt002():
    err = run_error('''
panther main {
    print 100 != "100";
}
''')
    assert "PT002" in err


def test_number_string_ordering_is_pt002_or_pt001():
    err = run_error('''
panther main {
    print 100 > "50";
}
''')
    assert "PT002" in err or "PT001" in err


def test_bool_number_equality_is_pt002():
    err = run_error('''
panther main {
    print true == 1;
}
''')
    assert "PT002" in err


def test_string_bool_equality_is_pt002():
    err = run_error('''
panther main {
    print "true" == true;
}
''')
    assert "PT002" in err


def test_explicit_conversion_allows_comparison():
    out = run('''
panther main {
    let a = 100;
    let b = "100";
    print a == to_int(b);
    print to_string(a) == b;
}
''')
    assert out == ["true", "true"]


def test_comparison_policy_program_runs():
    source = open("academy/lesson06/comparison_policy.pan", encoding="utf-8").read()
    result = execute_source(source)
    assert result.error is None, result.error
    joined = " ".join(result.captured_output)
    assert "Comparison policy verified" in joined


def test_null_comparison_with_string():
    out = run('''
panther main {
    print null == "hello";
    print "hello" == null;
    print null != "hello";
    print "hello" != null;
}
''')
    assert out == ["false", "false", "true", "true"]


def test_null_comparison_with_int():
    out = run('''
panther main {
    print null == 42;
    print 42 == null;
    print null != 42;
    print 42 != null;
}
''')
    assert out == ["false", "false", "true", "true"]


def test_null_comparison_with_bool():
    out = run('''
panther main {
    print null == true;
    print false == null;
    print null != false;
    print true != null;
}
''')
    assert out == ["false", "false", "true", "true"]


def test_null_equality_with_self():
    out = run('''
panther main {
    print null == null;
    print null != null;
}
''')
    assert out == ["true", "false"]


def test_null_ordered_comparison_still_pt002():
    err = run_error('''
panther main {
    print null > 5;
}
''')
    assert "PT002" in err


def test_null_comparison_with_variable():
    out = run('''
panther main {
    let response = null;
    print response == null;
    print response != null;
}
''')
    assert out == ["true", "false"]
