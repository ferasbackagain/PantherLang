from compiler.runtime import VariableEnvironment, execute_source
from compiler.stdlib import StdlibFunction, get_stdlib_functions


def test_stdlib_contains_builtins():
    fns = get_stdlib_functions()
    assert "len" in fns
    assert "abs" in fns
    assert "json_encode" in fns
    assert "time" in fns
    assert "int" in fns


def test_stdlib_len():
    result = execute_source('panther main { print(len("hello")); }')
    assert result.error is None
    assert result.captured_output == ["5"]


def test_stdlib_upper():
    result = execute_source('panther main { print(upper("hello")); }')
    assert result.error is None
    assert result.captured_output == ["HELLO"]


def test_stdlib_lower():
    result = execute_source('panther main { print(lower("HELLO")); }')
    assert result.error is None
    assert result.captured_output == ["hello"]


def test_stdlib_trim():
    result = execute_source('panther main { print(trim("  hi  ")); }')
    assert result.error is None
    assert result.captured_output == ["hi"]


def test_stdlib_contains():
    result = execute_source('panther main { print(contains("hello", "ell")); }')
    assert result.error is None
    assert result.captured_output == ["true"]


def test_stdlib_replace():
    result = execute_source('panther main { print(replace("hello", "l", "x")); }')
    assert result.error is None
    assert result.captured_output == ["hexxo"]


def test_stdlib_substring():
    result = execute_source('panther main { print(substring("hello", 1, 4)); }')
    assert result.error is None
    assert result.captured_output == ["ell"]


def test_stdlib_split():
    result = execute_source('panther main { print(split("a b c")); }')
    assert result.error is None
    assert result.captured_output == ["[a, b, c]"]


def test_stdlib_abs():
    result = execute_source('panther main { print(abs(-5)); }')
    assert result.error is None
    assert result.captured_output == ["5"]


def test_stdlib_max():
    result = execute_source('panther main { print(max(3, 7, 5)); }')
    assert result.error is None
    assert result.captured_output == ["7"]


def test_stdlib_min():
    result = execute_source('panther main { print(min(3, 7, 5)); }')
    assert result.error is None
    assert result.captured_output == ["3"]


def test_stdlib_pow():
    result = execute_source('panther main { print(pow(2, 3)); }')
    assert result.error is None
    assert result.captured_output == ["8"]


def test_stdlib_sqrt():
    result = execute_source('panther main { print(sqrt(9)); }')
    assert result.error is None
    assert result.captured_output == ["3.0"]


def test_stdlib_floor():
    result = execute_source('panther main { print(floor(3.7)); }')
    assert result.error is None
    assert result.captured_output == ["3"]


def test_stdlib_ceil():
    result = execute_source('panther main { print(ceil(3.2)); }')
    assert result.error is None
    assert result.captured_output == ["4"]


def test_stdlib_round():
    result = execute_source('panther main { print(round(3.14159, 2)); }')
    assert result.error is None
    assert result.captured_output == ["3.14"]


def test_stdlib_randint():
    result = execute_source('panther main { print(randint(1, 10)); }')
    assert result.error is None
    v = int(result.captured_output[0])
    assert 1 <= v <= 10


def test_stdlib_json_encode_string():
    result = execute_source('panther main { print(json_encode("hello")); }')
    assert result.error is None
    assert result.captured_output == ['"hello"']


def test_stdlib_json_decode():
    result = execute_source('panther main { print(json_decode("42")); }')
    assert result.error is None
    assert result.captured_output == ["42"]


def test_stdlib_time():
    result = execute_source('panther main { print(time()); }')
    assert result.error is None
    v = float(result.captured_output[0])
    assert v > 1_700_000_000


def test_stdlib_type_conversion_int():
    result = execute_source('panther main { print(int(3.14)); }')
    assert result.error is None
    assert result.captured_output == ["3"]


def test_stdlib_type_conversion_float():
    result = execute_source('panther main { print(float("3.14")); }')
    assert result.error is None
    assert result.captured_output == ["3.14"]


def test_stdlib_type_conversion_string():
    result = execute_source('panther main { print(string(42)); }')
    assert result.error is None
    assert result.captured_output == ["42"]


def test_stdlib_default_environment():
    env = VariableEnvironment.create_default()
    assert env.has_function("len")
    assert env.has_function("abs")
    assert env.has_function("json_encode")


def test_stdlib_works_with_chained_env():
    env = VariableEnvironment.create_default()
    result = execute_source('panther main { print(len("abc")); }', environment=env)
    assert result.error is None
    assert result.captured_output == ["3"]


def test_stdlib_starts_with():
    result = execute_source('panther main { print(starts_with("hello", "he")); }')
    assert result.error is None
    assert result.captured_output == ["true"]


def test_stdlib_ends_with():
    result = execute_source('panther main { print(ends_with("hello", "lo")); }')
    assert result.error is None
    assert result.captured_output == ["true"]


def test_stdlib_random():
    result = execute_source('panther main { print(random()); }')
    assert result.error is None
    v = float(result.captured_output[0])
    assert 0 <= v <= 1


def test_stdlib_len_on_variable():
    result = execute_source('panther main { let s = "abcde"; print(len(s)); }')
    assert result.error is None
    assert result.captured_output == ["5"]


def test_stdlib_abs_on_expression():
    result = execute_source('panther main { print(abs(3 - 7)); }')
    assert result.error is None
    assert result.captured_output == ["4"]
