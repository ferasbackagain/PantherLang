from __future__ import annotations

import hashlib
import hmac
import json
import re
import time
from dataclasses import dataclass
from typing import Any


@dataclass
class SecurityHeaders:
    content_security_policy: str = "default-src 'self'"
    x_content_type_options: str = "nosniff"
    x_frame_options: str = "DENY"
    x_xss_protection: str = "1; mode=block"
    strict_transport_security: str = "max-age=31536000; includeSubDomains"
    referrer_policy: str = "strict-origin-when-cross-origin"
    permissions_policy: str = "geolocation=(), microphone=(), camera=()"

    def to_dict(self) -> dict[str, str]:
        return {
            "Content-Security-Policy": self.content_security_policy,
            "X-Content-Type-Options": self.x_content_type_options,
            "X-Frame-Options": self.x_frame_options,
            "X-XSS-Protection": self.x_xss_protection,
            "Strict-Transport-Security": self.strict_transport_security,
            "Referrer-Policy": self.referrer_policy,
            "Permissions-Policy": self.permissions_policy,
        }


class CSRFProtection:
    def __init__(self, secret: str = "") -> None:
        self._secret = secret or hashlib.sha256(str(time.time()).encode()).hexdigest()

    def generate_token(self, session_id: str) -> str:
        msg = f"{session_id}:{int(time.time())}"
        return hmac.new(
            self._secret.encode(), msg.encode(), hashlib.sha256
        ).hexdigest()[:16]

    def validate_token(self, session_id: str, token: str) -> bool:
        expected = self.generate_token(session_id)
        return hmac.compare_digest(expected, token)


class XSSProtection:
    @staticmethod
    def sanitize_html(text: str) -> str:
        replacements = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': "&quot;",
            "'": "&#x27;",
            "/": "&#x2F;",
        }
        for k, v in replacements.items():
            text = text.replace(k, v)
        return text

    @staticmethod
    def sanitize_json(obj: Any) -> str:
        return json.dumps(obj, ensure_ascii=False, default=str)


class CookieSecurity:
    @staticmethod
    def make_secure_cookie(
        name: str,
        value: str,
        http_only: bool = True,
        secure: bool = True,
        same_site: str = "Lax",
        max_age: int = 3600,
        path: str = "/",
    ) -> str:
        parts = [f"{name}={value}", f"Path={path}", f"Max-Age={max_age}"]
        if http_only:
            parts.append("HttpOnly")
        if secure:
            parts.append("Secure")
        if same_site in ("Strict", "Lax", "None"):
            parts.append(f"SameSite={same_site}")
        return "; ".join(parts)


class JWTSafety:
    @staticmethod
    def validate_jwt_structure(token: str) -> bool:
        parts = token.split(".")
        if len(parts) != 3:
            return False
        return all(bool(p) for p in parts)

    @staticmethod
    def is_expired(payload_encoded: str) -> bool:
        try:
            padded = payload_encoded + "=" * (4 - len(payload_encoded) % 4)
            import base64
            decoded = base64.urlsafe_b64decode(padded)
            payload = json.loads(decoded)
            exp = payload.get("exp", 0)
            return time.time() > exp
        except Exception:
            return True


class RateLimiter:
    def __init__(self, max_requests: int = 100, window_seconds: int = 60) -> None:
        self._max_requests = max_requests
        self._window = window_seconds
        self._buckets: dict[str, list[float]] = {}

    def is_allowed(self, key: str) -> bool:
        now = time.time()
        window_start = now - self._window
        if key not in self._buckets:
            self._buckets[key] = []
        self._buckets[key] = [t for t in self._buckets[key] if t > window_start]
        if len(self._buckets[key]) >= self._max_requests:
            return False
        self._buckets[key].append(now)
        return True

    def remaining(self, key: str) -> int:
        now = time.time()
        window_start = now - self._window
        if key not in self._buckets:
            return self._max_requests
        self._buckets[key] = [t for t in self._buckets[key] if t > window_start]
        return max(0, self._max_requests - len(self._buckets[key]))

    def reset(self, key: str) -> None:
        self._buckets.pop(key, None)


class CORSValidator:
    @staticmethod
    def validate_origin(allowed_origins: list[str], origin: str) -> bool:
        if not origin:
            return False
        for allowed in allowed_origins:
            if allowed == "*":
                return True
            if allowed == origin:
                return True
            if allowed.startswith("*."):
                domain_part = allowed[1:]
                if origin.endswith(domain_part):
                    return True
        return False
