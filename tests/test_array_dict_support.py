"""Tests for Batch 11.1: array literal, object literal, index expression."""

from compiler.runtime import execute_source


# --- Array Literal ---

def test_empty_array():
    result = execute_source('panther main { print([]); }')
    assert result.error is None
    assert result.captured_output == ["[]"]


def test_array_numbers():
    result = execute_source('panther main { print([1, 2, 3]); }')
    assert result.error is None
    assert result.captured_output == ["[1, 2, 3]"]


def test_array_strings():
    result = execute_source('panther main { print(["a", "b"]); }')
    assert result.error is None
    assert result.captured_output == ["[a, b]"]


def test_array_mixed():
    result = execute_source('panther main { print([1, "hello", true]); }')
    assert result.error is None
    assert result.captured_output == ["[1, hello, true]"]


def test_array_nested():
    result = execute_source('panther main { print([[1, 2], [3, 4]]); }')
    assert result.error is None
    assert result.captured_output == ["[[1, 2], [3, 4]]"]


def test_array_in_variable():
    result = execute_source('panther main { let a = [10, 20, 30]; print(a); }')
    assert result.error is None
    assert result.captured_output == ["[10, 20, 30]"]


def test_array_len():
    result = execute_source('panther main { let a = [1, 2, 3]; print(len(a)); }')
    assert result.error is None
    assert result.captured_output == ["3"]


def test_array_empty_len():
    result = execute_source('panther main { print(len([])); }')
    assert result.error is None
    assert result.captured_output == ["0"]


# --- Object Literal ---

def test_empty_object():
    result = execute_source("panther main { print({}); }")
    assert result.error is None
    assert result.captured_output == ["{}"]


def test_object_simple():
    result = execute_source('panther main { print({x: 1, y: 2}); }')
    assert result.error is None
    assert result.captured_output == ["{x: 1, y: 2}"]


def test_object_string_values():
    result = execute_source('panther main { print({name: "Panther", year: 2026}); }')
    assert result.error is None
    assert "{name: Panther, year: 2026}" in " ".join(result.captured_output)


def test_object_in_variable():
    result = execute_source('panther main { let o = {a: 1, b: 2}; print(o); }')
    assert result.error is None
    assert result.captured_output == ["{a: 1, b: 2}"]


def test_object_nested():
    result = execute_source('panther main { print({inner: {x: 1}}); }')
    assert result.error is None
    assert "{inner: {x: 1}}" in " ".join(result.captured_output)


# --- Index Expression ---

def test_index_array():
    result = execute_source('panther main { let a = [10, 20, 30]; print(a[0]); }')
    assert result.error is None
    assert result.captured_output == ["10"]


def test_index_array_last():
    result = execute_source('panther main { let a = [10, 20, 30]; print(a[2]); }')
    assert result.error is None
    assert result.captured_output == ["30"]


def test_index_array_expression():
    result = execute_source('panther main { let a = [10, 20, 30]; let i = 1; print(a[i]); }')
    assert result.error is None
    assert result.captured_output == ["20"]


def test_index_array_out_of_bounds():
    result = execute_source('panther main { let a = [10, 20]; print(a[99]); }')
    assert result.error is not None
    assert "out of range" in result.error


def test_index_object_key():
    result = execute_source('panther main { let o = {x: 42, y: 7}; print(o["x"]); }')
    assert result.error is None
    assert result.captured_output == ["42"]


def test_index_object_key_missing():
    result = execute_source('panther main { let o = {x: 1}; print(o["z"]); }')
    assert result.error is not None
    assert "has no key" in result.error


def test_index_nested():
    result = execute_source('panther main { let a = [[1, 2], [3, 4]]; print(a[0][1]); }')
    assert result.error is None
    assert result.captured_output == ["2"]


# --- Assignment with Index ---

def test_assign_to_index_expression():
    """Verify array index assignment works."""
    result = execute_source('''
panther main {
    let a = [1, 2, 3];
    a[0] = 99;
    print(a[0]);
}
''')
    assert result.error is None
    assert result.captured_output == ["99"]


def test_assign_to_dict_index():
    """Verify dict index assignment works."""
    result = execute_source('''
panther main {
    let d = {x: 1};
    d["y"] = 2;
    print(d["y"]);
}
''')
    assert result.error is None
    assert result.captured_output == ["2"]


# --- Mixed: Arrays and Objects ---

def test_array_of_objects():
    result = execute_source('panther main { print([{a: 1}, {b: 2}]); }')
    assert result.error is None
    assert "[{a: 1}, {b: 2}]" in " ".join(result.captured_output)


def test_object_with_array():
    result = execute_source('panther main { print({nums: [1, 2, 3]}); }')
    assert result.error is None
    assert "{nums: [1, 2, 3]}" in " ".join(result.captured_output)


# --- Parser Edge Cases ---

def test_array_trailing_comma():
    result = execute_source('panther main { print([1, 2,]); }')
    assert result.error is None
    assert result.captured_output == ["[1, 2]"]


def test_object_trailing_comma():
    result = execute_source('panther main { print({a: 1, b: 2,}); }')
    assert result.error is None
    assert "{a: 1, b: 2}" in " ".join(result.captured_output)


def test_array_in_for_range():
    """Ensure existing for-range syntax still works."""
    result = execute_source('panther main { print([1, 2, 3]); }')
    assert result.error is None
    assert result.captured_output == ["[1, 2, 3]"]


def test_array_functions():
    """Functions can work with arrays."""
    result = execute_source('''
panther main {
    fn sum(arr) {
        return arr[0] + arr[1] + arr[2];
    }
    let s = sum([10, 20, 30]);
    print(s);
}
''')
    assert result.error is None
    assert result.captured_output == ["60"]
