from __future__ import annotations

import ctypes
import ctypes.util
import platform as _platform
import time as _time

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


class TimeSpec(ctypes.Structure):
    _fields_ = [
        ("tv_sec", ctypes.c_long),
        ("tv_nsec", ctypes.c_long),
    ]


def _setup_libc() -> None:
    if _LIBC is None:
        return
    try:
        _LIBC.clock_gettime.argtypes = [ctypes.c_int, ctypes.POINTER(TimeSpec)]
        _LIBC.clock_gettime.restype = ctypes.c_int
    except AttributeError:
        pass
    try:
        _LIBC.nanosleep.argtypes = [ctypes.POINTER(TimeSpec), ctypes.POINTER(TimeSpec)]
        _LIBC.nanosleep.restype = ctypes.c_int
    except AttributeError:
        pass


CLOCK_MONOTONIC = 1
CLOCK_REALTIME = 0


def native_time() -> tuple[float | None, str | None]:
    if not _NATIVE_AVAILABLE or _LIBC is None:
        return _fallback_time()
    _setup_libc()
    try:
        ts = TimeSpec()
        try:
            result = _LIBC.clock_gettime(CLOCK_REALTIME, ctypes.byref(ts))
            if result == 0:
                return ts.tv_sec + ts.tv_nsec / 1_000_000_000, None
        except AttributeError:
            pass
        return _fallback_time()
    except Exception:
        return _fallback_time()


def native_sleep(secs: float) -> tuple[bool, str | None]:
    """Sleep using libc nanosleep. Returns (success, error)."""
    if not _NATIVE_AVAILABLE or _LIBC is None:
        return _fallback_sleep(secs)
    _setup_libc()
    try:
        ts = TimeSpec()
        ts.tv_sec = int(secs)
        ts.tv_nsec = int((secs - ts.tv_sec) * 1_000_000_000)
        try:
            result = _LIBC.nanosleep(ctypes.byref(ts), None)
            if result == 0:
                return True, None
            return True, None
        except AttributeError:
            pass
        return _fallback_sleep(secs)
    except Exception:
        return _fallback_sleep(secs)


def native_monotonic() -> tuple[float | None, str | None]:
    if not _NATIVE_AVAILABLE or _LIBC is None:
        return _time.monotonic(), None
    _setup_libc()
    try:
        ts = TimeSpec()
        try:
            result = _LIBC.clock_gettime(CLOCK_MONOTONIC, ctypes.byref(ts))
            if result == 0:
                return ts.tv_sec + ts.tv_nsec / 1_000_000_000, None
        except AttributeError:
            pass
        return _time.monotonic(), None
    except Exception:
        return _time.monotonic(), None


def _fallback_time() -> tuple[float | None, str | None]:
    try:
        return _time.time(), None
    except Exception as e:
        return None, str(e)


def _fallback_sleep(secs: float) -> tuple[bool, str | None]:
    try:
        _time.sleep(secs)
        return True, None
    except Exception as e:
        return False, str(e)
