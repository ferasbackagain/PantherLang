from compiler.runtime import execute_source
from compiler.stdlib import get_stdlib_functions


def test_division_by_zero_uses_panther_error_code():
    result = execute_source("""
panther main {
    print 10 / 0;
}
""")
    assert result.error is not None
    assert "PR001" in result.error
    assert "Division by zero" in result.error


def test_type_mismatch_uses_panther_error_code():
    result = execute_source("""
panther main {
    let age = 45;
    let name = "Feras";
    print age + name;
}
""")
    assert result.error is not None
    assert "PT001" in result.error
    assert "implicit conversion" in result.error


def test_explicit_conversion_to_string_works():
    result = execute_source("""
panther main {
    let age = 45;
    print to_string(age);
    print println("Age", age);
    print type_of(age);
}
""")
    assert result.error is None
    assert result.captured_output == ["45", "Age 45", "int"]


def test_stdlib_io_and_conversion_functions_registered():
    fns = get_stdlib_functions()
    for name in ["input", "readline", "println", "to_string", "to_int", "to_float", "to_number", "to_bool", "type_of"]:
        assert name in fns
