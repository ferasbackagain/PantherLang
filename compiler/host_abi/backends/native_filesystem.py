from __future__ import annotations

import ctypes
import ctypes.util
import os as _os
import platform as _platform
import shutil as _shutil
from pathlib import Path as _Path

_IS_LINUX = _platform.system() == "Linux"
_NATIVE_AVAILABLE = False
_LIBC = None

try:
    if _IS_LINUX:
        libc_name = ctypes.util.find_library("c")
        if libc_name:
            _LIBC = ctypes.cdll.LoadLibrary(libc_name)
            _NATIVE_AVAILABLE = True
except Exception:
    _LIBC = None
    _NATIVE_AVAILABLE = False


def native_available() -> bool:
    return _NATIVE_AVAILABLE


O_RDONLY = 0
O_WRONLY = 1
O_RDWR = 2
O_CREAT = 64
O_TRUNC = 512
O_APPEND = 1024
S_IRUSR = 256
S_IWUSR = 128
S_IRGRP = 32
S_IROTH = 4


def _setup_libc() -> None:
    if _LIBC is None:
        return
    _LIBC.open.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.c_int]
    _LIBC.open.restype = ctypes.c_int
    _LIBC.read.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t]
    _LIBC.read.restype = ctypes.c_ssize_t
    _LIBC.write.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t]
    _LIBC.write.restype = ctypes.c_ssize_t
    _LIBC.close.argtypes = [ctypes.c_int]
    _LIBC.close.restype = ctypes.c_int
    _LIBC.mkdir.argtypes = [ctypes.c_char_p, ctypes.c_int]
    _LIBC.mkdir.restype = ctypes.c_int
    _LIBC.unlink.argtypes = [ctypes.c_char_p]
    _LIBC.unlink.restype = ctypes.c_int
    _LIBC.rename.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
    _LIBC.rename.restype = ctypes.c_int
    _LIBC.access.argtypes = [ctypes.c_char_p, ctypes.c_int]
    _LIBC.access.restype = ctypes.c_int


def native_read_file(path: str) -> tuple[str | None, str | None]:
    if not _NATIVE_AVAILABLE or _LIBC is None:
        return _fallback_read_file(path)
    _setup_libc()
    try:
        p = str(path).encode("utf-8")
        fd = _LIBC.open(p, O_RDONLY, 0)
        if fd < 0:
            return None, f"cannot open {path}"
        chunks = []
        buf = ctypes.create_string_buffer(4096)
        while True:
            n = _LIBC.read(fd, buf, 4096)
            if n <= 0:
                break
            chunks.append(buf.raw[:n])
        _LIBC.close(fd)
        return b"".join(chunks).decode("utf-8", errors="replace"), None
    except Exception:
        return _fallback_read_file(path)


def native_write_file(path: str, content: str) -> tuple[bool, str | None]:
    if not _NATIVE_AVAILABLE or _LIBC is None:
        return _fallback_write_file(path, content)
    _setup_libc()
    try:
        p = str(path).encode("utf-8")
        data = str(content).encode("utf-8")
        fd = _LIBC.open(p, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
        if fd < 0:
            return False, f"cannot open {path} for writing"
        total = 0
        while total < len(data):
            n = _LIBC.write(fd, data[total:], len(data) - total)
            if n <= 0:
                _LIBC.close(fd)
                return False, "write error"
            total += n
        _LIBC.close(fd)
        return True, None
    except Exception:
        return _fallback_write_file(path, content)


def native_file_exists(path: str) -> bool:
    if not _NATIVE_AVAILABLE or _LIBC is None:
        return _fallback_file_exists(path)
    _setup_libc()
    try:
        p = str(path).encode("utf-8")
        return _LIBC.access(p, 0) == 0
    except Exception:
        return _fallback_file_exists(path)


def native_mkdir(path: str) -> tuple[bool, str | None]:
    if not _NATIVE_AVAILABLE or _LIBC is None:
        return _fallback_mkdir(path)
    _setup_libc()
    try:
        p = str(path).encode("utf-8")
        result = _LIBC.mkdir(p, 0o755)
        if result == 0:
            return True, None
        errno = ctypes.get_errno()
        if errno == 17:
            return True, None
        return False, f"mkdir failed (errno={errno})"
    except Exception:
        return _fallback_mkdir(path)


def native_remove_file(path: str) -> tuple[bool, str | None]:
    if not _NATIVE_AVAILABLE or _LIBC is None:
        return _fallback_remove_file(path)
    _setup_libc()
    try:
        p = str(path).encode("utf-8")
        result = _LIBC.unlink(p)
        if result == 0:
            return True, None
        return False, f"unlink failed (errno={ctypes.get_errno()})"
    except Exception:
        return _fallback_remove_file(path)


def _fallback_read_file(path: str) -> tuple[str | None, str | None]:
    try:
        return _Path(path).read_text(encoding="utf-8"), None
    except Exception as e:
        return None, str(e)


def _fallback_write_file(path: str, content: str) -> tuple[bool, str | None]:
    try:
        _Path(path).parent.mkdir(parents=True, exist_ok=True)
        _Path(path).write_text(str(content), encoding="utf-8")
        return True, None
    except Exception as e:
        return False, str(e)


def _fallback_file_exists(path: str) -> bool:
    return _Path(path).exists()


def _fallback_mkdir(path: str) -> tuple[bool, str | None]:
    try:
        _Path(path).mkdir(parents=True, exist_ok=True)
        return True, None
    except Exception as e:
        return False, str(e)


def _fallback_remove_file(path: str) -> tuple[bool, str | None]:
    try:
        p = _Path(path)
        if p.is_dir():
            _shutil.rmtree(p)
        else:
            p.unlink()
        return True, None
    except Exception as e:
        return False, str(e)
