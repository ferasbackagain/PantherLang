from __future__ import annotations

import ctypes
import ctypes.util
import hashlib as _hashlib
import hmac as _hmac
import platform as _platform
import secrets as _secrets
import uuid as _uuid

_IS_LINUX = _platform.system() == "Linux"
_NATIVE_AVAILABLE = False
_LIBCRYPTO = None

try:
    if _IS_LINUX:
        lib_name = ctypes.util.find_library("crypto")
        if lib_name:
            _LIBCRYPTO = ctypes.cdll.LoadLibrary(lib_name)
            _NATIVE_AVAILABLE = True
except Exception:
    _LIBCRYPTO = None
    _NATIVE_AVAILABLE = False


def native_available() -> bool:
    return _NATIVE_AVAILABLE


def _setup_libcrypto() -> None:
    if _LIBCRYPTO is None:
        return
    try:
        _LIBCRYPTO.SHA256.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p]
        _LIBCRYPTO.SHA256.restype = ctypes.c_char_p
    except AttributeError:
        pass


def native_sha256(text: str) -> tuple[str | None, str | None]:
    if not _NATIVE_AVAILABLE or _LIBCRYPTO is None:
        return _fallback_sha256(text)
    _setup_libcrypto()
    try:
        data = str(text).encode("utf-8")
        buf = ctypes.create_string_buffer(32)
        try:
            _LIBCRYPTO.SHA256(data, len(data), buf)
            return buf.raw.hex(), None
        except AttributeError:
            return _fallback_sha256(text)
    except Exception:
        return _fallback_sha256(text)


def native_sha512(text: str) -> tuple[str | None, str | None]:
    return _fallback_sha512(text)


def native_md5(text: str) -> tuple[str | None, str | None]:
    return _fallback_md5(text)


def native_uuid() -> tuple[str | None, str | None]:
    try:
        return str(_uuid.uuid4()), None
    except Exception as e:
        return None, str(e)


def native_random_bytes(nbytes: int = 32) -> tuple[str | None, str | None]:
    try:
        return _secrets.token_hex(nbytes), None
    except Exception as e:
        return None, str(e)


def _fallback_sha256(text: str) -> tuple[str | None, str | None]:
    try:
        return _hashlib.sha256(str(text).encode("utf-8")).hexdigest(), None
    except Exception as e:
        return None, str(e)


def _fallback_sha512(text: str) -> tuple[str | None, str | None]:
    try:
        return _hashlib.sha512(str(text).encode("utf-8")).hexdigest(), None
    except Exception as e:
        return None, str(e)


def _fallback_md5(text: str) -> tuple[str | None, str | None]:
    try:
        return _hashlib.md5(str(text).encode("utf-8")).hexdigest(), None
    except Exception as e:
        return None, str(e)
