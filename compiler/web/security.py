from __future__ import annotations

import json
from http.server import BaseHTTPRequestHandler
from typing import Any

from compiler.security.web_security import (
    CORSValidator,
    CookieSecurity,
    CSRFProtection,
    RateLimiter,
    SecurityHeaders,
    XSSProtection,
)

_SECURITY_HEADERS = SecurityHeaders()
_RATE_LIMITER = RateLimiter(max_requests=200, window_seconds=60)
_CSRF = CSRFProtection()


class SecureRequestHandler(BaseHTTPRequestHandler):
    cors_origins: list[str] = ["*"]

    def send_secure_response(
        self,
        data: Any,
        status: int = 200,
        content_type: str = "application/json",
        cookies: list[str] | None = None,
    ) -> None:
        self.send_response(status)
        for header, value in _SECURITY_HEADERS.to_dict().items():
            self.send_header(header, value)
        origin = self.headers.get("Origin", "")
        if CORSValidator.validate_origin(self.cors_origins, origin):
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-CSRF-Token")
            self.send_header("Access-Control-Allow-Credentials", "true")
            self.send_header("Vary", "Origin")
        self.send_header("Content-Type", content_type)
        if cookies:
            for cookie in cookies:
                self.send_header("Set-Cookie", cookie)
        self.end_headers()
        sanitized = XSSProtection.sanitize_json(data)
        self.wfile.write(sanitized.encode("utf-8"))

    def send_secure_error(self, status: int, message: str) -> None:
        self.send_secure_response({"error": message}, status=status)

    def check_rate_limit(self) -> bool:
        client_ip = self.client_address[0] if self.client_address else "unknown"
        return _RATE_LIMITER.is_allowed(client_ip)

    def verify_csrf(self) -> bool:
        token = self.headers.get("X-CSRF-Token", "")
        session_id = self.headers.get("X-Session-ID", "")
        if not token or not session_id:
            return False
        return _CSRF.validate_token(session_id, token)

    def log_message(self, format: str, *args: Any) -> None:
        pass


def apply_security_middleware(handler_class: type) -> type:
    original_do_GET = getattr(handler_class, "do_GET", None)
    original_do_POST = getattr(handler_class, "do_POST", None)
    original_do_PUT = getattr(handler_class, "do_PUT", None)
    original_do_DELETE = getattr(handler_class, "do_DELETE", None)

    def _wrap(method_name: str, original: Any) -> Any:
        def _secured(self: Any, *args: Any, **kwargs: Any) -> None:
            if not self.check_rate_limit():
                self.send_secure_error(429, "Rate limit exceeded")
                return
            if original:
                original(self, *args, **kwargs)
        return _secured

    for method in ["do_GET", "do_POST", "do_PUT", "do_DELETE"]:
        original = getattr(handler_class, method, None)
        if original:
            setattr(handler_class, method, _wrap(method, original))

    return handler_class
