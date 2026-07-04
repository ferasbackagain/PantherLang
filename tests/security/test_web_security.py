import time
import json

from compiler.security.web_security import (
    SecurityHeaders,
    CSRFProtection,
    XSSProtection,
    CookieSecurity,
    JWTSafety,
    RateLimiter,
    CORSValidator,
)


def test_security_headers_default():
    headers = SecurityHeaders()
    d = headers.to_dict()
    assert "Content-Security-Policy" in d
    assert d["X-Content-Type-Options"] == "nosniff"
    assert d["X-Frame-Options"] == "DENY"
    assert "Strict-Transport-Security" in d


def test_csrf_generate_and_validate():
    csrf = CSRFProtection(secret="test-secret")
    token = csrf.generate_token("session-123")
    assert csrf.validate_token("session-123", token)
    assert not csrf.validate_token("session-456", token)


def test_csrf_different_secret():
    csrf1 = CSRFProtection(secret="secret1")
    csrf2 = CSRFProtection(secret="secret2")
    token = csrf1.generate_token("session-1")
    assert not csrf2.validate_token("session-1", token)


def test_xss_sanitize_html():
    sanitized = XSSProtection.sanitize_html("<script>alert('xss')</script>")
    assert "&lt;" in sanitized
    assert "&gt;" in sanitized
    assert "<script>" not in sanitized


def test_xss_sanitize_json():
    data = {"msg": "<script>alert(1)</script>"}
    result = XSSProtection.sanitize_json(data)
    parsed = json.loads(result)
    assert parsed["msg"] == "<script>alert(1)</script>"


def test_cookie_secure_defaults():
    cookie = CookieSecurity.make_secure_cookie("session", "abc123")
    assert "HttpOnly" in cookie
    assert "Secure" in cookie
    assert "SameSite=Lax" in cookie


def test_cookie_custom_samesite():
    cookie = CookieSecurity.make_secure_cookie("session", "abc123", same_site="Strict")
    assert "SameSite=Strict" in cookie


def test_jwt_validate_structure():
    assert JWTSafety.validate_jwt_structure("header.payload.signature")
    assert not JWTSafety.validate_jwt_structure("invalid")
    assert not JWTSafety.validate_jwt_structure("a.b.c.d")


def test_jwt_expired():
    import base64, json
    expired_payload = base64.urlsafe_b64encode(
        json.dumps({"exp": 0}).encode()
    ).decode().rstrip("=")
    assert JWTSafety.is_expired(expired_payload)


def test_jwt_not_expired():
    import base64, json
    future_payload = base64.urlsafe_b64encode(
        json.dumps({"exp": time.time() + 3600}).encode()
    ).decode().rstrip("=")
    assert not JWTSafety.is_expired(future_payload)


def test_rate_limiter_allows_first_request():
    limiter = RateLimiter(max_requests=5, window_seconds=60)
    assert limiter.is_allowed("client-1")


def test_rate_limiter_blocks_excess():
    limiter = RateLimiter(max_requests=3, window_seconds=60)
    for _ in range(3):
        assert limiter.is_allowed("client-1")
    assert not limiter.is_allowed("client-1")


def test_rate_limiter_remaining():
    limiter = RateLimiter(max_requests=5, window_seconds=60)
    for _ in range(3):
        limiter.is_allowed("client-1")
    assert limiter.remaining("client-1") == 2


def test_rate_limiter_reset():
    limiter = RateLimiter(max_requests=2, window_seconds=60)
    limiter.is_allowed("client-1")
    limiter.is_allowed("client-1")
    assert not limiter.is_allowed("client-1")
    limiter.reset("client-1")
    assert limiter.is_allowed("client-1")


def test_cors_validate_exact_origin():
    assert CORSValidator.validate_origin(["https://example.com"], "https://example.com")


def test_cors_validate_wildcard():
    assert CORSValidator.validate_origin(["*"], "https://any-origin.com")


def test_cors_validate_wildcard_domain():
    assert CORSValidator.validate_origin(["*.example.com"], "sub.example.com")
    assert not CORSValidator.validate_origin(["*.example.com"], "evil.com")


def test_cors_validate_reject():
    assert not CORSValidator.validate_origin(["https://allowed.com"], "https://evil.com")
