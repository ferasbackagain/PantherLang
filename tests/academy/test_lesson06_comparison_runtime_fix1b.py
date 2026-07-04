from compiler.runtime import execute_source


def run_ok(src: str):
    result = execute_source(src)
    assert result.error is None, result.error
    return result.captured_output


def run_error(src: str):
    result = execute_source(src)
    assert result.error is not None
    return result.error


def test_number_comparisons_work():
    out = run_ok('''
panther main {
    print 100 == 100;
    print 100 != 50;
    print 100 > 50;
    print 100 < 50;
    print 100 >= 100;
    print 50 <= 100;
}
''')
    assert out == ["true", "true", "true", "false", "true", "true"]


def test_string_comparisons_work():
    out = run_ok('''
panther main {
    print "abc" == "abc";
    print "abc" != "xyz";
}
''')
    assert out == ["true", "true"]


def test_boolean_comparisons_work():
    out = run_ok('''
panther main {
    print true == true;
    print true == false;
    print true != false;
}
''')
    assert out == ["true", "false", "true"]


def test_number_string_equality_is_pt002():
    err = run_error('''
panther main {
    print 100 == "100";
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


def test_explicit_conversion_then_comparison_works():
    out = run_ok('''
panther main {
    print to_int("100") == 100;
    print to_string(100) == "100";
}
''')
    assert out == ["true", "true"]


def test_comparison_policy_example_runs():
    source = open("academy/lesson06/comparison_policy.pan", encoding="utf-8").read()
    out = run_ok(source)
    joined = " ".join(out)
    assert "Comparison policy verified" in joined
