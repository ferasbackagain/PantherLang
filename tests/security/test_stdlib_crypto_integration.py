from compiler.stdlib.functions import get_stdlib_functions


def test_sha256_stdlib_function():
    fns = get_stdlib_functions()
    assert "sha256" in fns
    fn = fns["sha256"]
    result = fn.fn("hello")
    assert len(result) == 64
    assert isinstance(result, str)


def test_hmac_sha256_stdlib_function():
    fns = get_stdlib_functions()
    assert "hmac_sha256" in fns
    fn = fns["hmac_sha256"]
    result = fn.fn("key", "message")
    assert len(result) == 64


def test_secure_token_stdlib_function():
    fns = get_stdlib_functions()
    assert "secure_token" in fns
    fn = fns["secure_token"]
    result = fn.fn()
    assert len(result) == 64


def test_secure_token_nbytes():
    fns = get_stdlib_functions()
    fn = fns["secure_token"]
    result = fn.fn(16)
    assert len(result) == 32


def test_secure_compare_stdlib_function():
    fns = get_stdlib_functions()
    assert "secure_compare" in fns
    fn = fns["secure_compare"]
    assert fn.fn("abc", "abc")
    assert not fn.fn("abc", "xyz")


def test_sanitize_path_stdlib_function():
    fns = get_stdlib_functions()
    assert "sanitize_path" in fns
    fn = fns["sanitize_path"]
    result = fn.fn("/tmp", "test.txt")
    assert result == "/tmp/test.txt"


def test_sanitize_path_traversal():
    fns = get_stdlib_functions()
    fn = fns["sanitize_path"]
    try:
        fn.fn("/tmp", "../../etc/passwd")
        assert False, "Expected ValueError"
    except ValueError:
        pass


def test_sanitize_html_stdlib_function():
    fns = get_stdlib_functions()
    assert "sanitize_html" in fns
    fn = fns["sanitize_html"]
    result = fn.fn("<script>alert(1)</script>")
    assert "&lt;" in result
    assert "&gt;" in result


def test_all_security_functions_registered():
    security_fns = {"sha256", "hmac_sha256", "secure_token", "secure_compare", "sanitize_path", "sanitize_html"}
    fns = get_stdlib_functions()
    for name in security_fns:
        assert name in fns, f"Missing stdlib function: {name}"
