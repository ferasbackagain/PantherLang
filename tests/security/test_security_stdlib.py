from compiler.security.stdlib_security import (
    PathSafety,
    CryptoUtils,
    SecureRandom,
    InputValidator,
)


def test_path_safety_safe_resolve():
    result = PathSafety.safe_resolve("/tmp", "subdir/file.txt")
    assert result.startswith("/tmp/")


def test_path_safety_traversal_detected():
    try:
        PathSafety.safe_resolve("/tmp/allow", "../../etc/passwd")
        assert False, "Expected ValueError"
    except ValueError:
        pass


def test_path_safety_sanitize_filename():
    clean = PathSafety.sanitize_filename("hello<>world/test.txt")
    assert "/" not in clean
    assert "<" not in clean
    assert ">" not in clean


def test_path_safety_sanitize_filename_clean():
    clean = PathSafety.sanitize_filename("my_file-v2.test.txt")
    assert clean == "my_file-v2.test.txt"


def test_path_safety_is_safe_path():
    assert PathSafety.is_safe_path("/tmp/test.txt")
    assert not PathSafety.is_safe_path("/etc/passwd")


def test_crypto_sha256():
    h = CryptoUtils.hash_sha256("hello")
    assert len(h) == 64
    assert h == CryptoUtils.hash_sha256("hello")


def test_crypto_sha256_bytes():
    h = CryptoUtils.hash_sha256_bytes(b"hello")
    assert len(h) == 64


def test_crypto_hmac():
    h = CryptoUtils.hmac_sha256("key", "message")
    assert len(h) == 64


def test_crypto_secure_compare():
    assert CryptoUtils.secure_compare("abc", "abc")
    assert not CryptoUtils.secure_compare("abc", "xyz")


def test_secure_random_token_bytes():
    t = SecureRandom.token_bytes(16)
    assert len(t) == 32


def test_secure_random_token_urlsafe():
    t = SecureRandom.token_urlsafe(16)
    assert len(t) > 0


def test_secure_random_randbelow():
    r = SecureRandom.randbelow(100)
    assert 0 <= r < 100


def test_secure_random_choice():
    item = SecureRandom.choice(["a", "b", "c"])
    assert item in ["a", "b", "c"]


def test_input_validator_email():
    assert InputValidator.is_valid_email("user@example.com")
    assert not InputValidator.is_valid_email("not-an-email")
    assert not InputValidator.is_valid_email("")


def test_input_validator_sanitize_html():
    result = InputValidator.sanitize_html("<script>alert(1)</script>")
    assert "&lt;" in result
    assert "&gt;" in result


def test_input_validator_strip_control_chars():
    result = InputValidator.strip_control_chars("hello\x00world\x01test")
    assert "\x00" not in result
    assert "\x01" not in result
    assert "hello" in result
