from __future__ import annotations

import hashlib
import hmac
import os
import secrets
from pathlib import Path
from typing import Any


class PathSafety:
    @staticmethod
    def safe_resolve(base_dir: str, user_path: str) -> str:
        base = Path(base_dir).resolve()
        target = (base / user_path).resolve()
        if not str(target).startswith(str(base)):
            raise ValueError(f"Path traversal detected: {user_path}")
        return str(target)

    @staticmethod
    def sanitize_filename(name: str) -> str:
        clean = "".join(c for c in name if c.isalnum() or c in "._- ")
        return clean.strip() or "unnamed"

    @staticmethod
    def is_safe_path(path: str) -> bool:
        resolved = Path(path).resolve()
        denied_prefixes = [
            "/etc", "/sys", "/proc", "/dev", "/boot",
            str(Path.home() / ".ssh"),
            str(Path.home() / ".gnupg"),
            str(Path.home() / ".aws"),
        ]
        return not any(str(resolved).startswith(p) for p in denied_prefixes)


class CryptoUtils:
    @staticmethod
    def hash_sha256(data: str) -> str:
        return hashlib.sha256(data.encode("utf-8")).hexdigest()

    @staticmethod
    def hash_sha256_bytes(data: bytes) -> str:
        return hashlib.sha256(data).hexdigest()

    @staticmethod
    def hash_md5(data: str) -> str:
        return hashlib.md5(data.encode("utf-8")).hexdigest()

    @staticmethod
    def hmac_sha256(key: str, message: str) -> str:
        return hmac.new(
            key.encode("utf-8"),
            message.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

    @staticmethod
    def secure_compare(a: str, b: str) -> bool:
        return hmac.compare_digest(a.encode("utf-8"), b.encode("utf-8"))


class SecureRandom:
    @staticmethod
    def token_bytes(nbytes: int = 32) -> str:
        return secrets.token_hex(nbytes)

    @staticmethod
    def token_urlsafe(nbytes: int = 32) -> str:
        return secrets.token_urlsafe(nbytes)

    @staticmethod
    def randbelow(exclusive_upper: int) -> int:
        return secrets.randbelow(exclusive_upper)

    @staticmethod
    def choice(seq: list[Any]) -> Any:
        return secrets.choice(seq)


class InputValidator:
    @staticmethod
    def is_valid_email(email: str) -> bool:
        import re
        return bool(re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", email))

    @staticmethod
    def sanitize_html(text: str) -> str:
        replacements = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': "&quot;",
            "'": "&#x27;",
        }
        for k, v in replacements.items():
            text = text.replace(k, v)
        return text

    @staticmethod
    def strip_control_chars(text: str) -> str:
        return "".join(c for c in text if c.isprintable() or c in "\n\r\t")
