"""Native socket backend using ctypes to call libc directly.

This bypasses Python's socket module and calls OS socket APIs directly.
Provides a fallback mechanism: if native ctypes call fails, falls back
to Python socket module.

Architecture:
  Panther .pan -> Python stdlib -> native_socket (ctypes -> libc) -> OS
"""

from __future__ import annotations

import ctypes
import ctypes.util
import platform as _platform
import socket as _socket
from typing import Any

_IS_LINUX = _platform.system() == "Linux"
_NATIVE_AVAILABLE = False
_LIBC = None

# Load libc
try:
    if _IS_LINUX:
        libc_name = ctypes.util.find_library("c")
        if libc_name:
            _LIBC = ctypes.CDLL(libc_name, use_errno=True)
            _NATIVE_AVAILABLE = True
except Exception:
    _LIBC = None
    _NATIVE_AVAILABLE = False

# Constants
AF_INET = 2
SOCK_STREAM = 1
SOL_SOCKET = 1
SO_RCVTIMEO = 20
SO_SNDTIMEO = 21

# Error codes
EADDRNOTAVAIL = 99
EAFNOSUPPORT = 97
ECONNREFUSED = 111
ECONNRESET = 104
EHOSTUNREACH = 113
EINPROGRESS = 115
EINVAL = 22
EISCONN = 106
ENETUNREACH = 101
ETIMEDOUT = 110


def native_available() -> bool:
    return _NATIVE_AVAILABLE


def _setup_libc() -> None:
    if _LIBC is None:
        return

    # Set return types for socket functions
    _LIBC.socket.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_int]
    _LIBC.socket.restype = ctypes.c_int

    _LIBC.connect.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_int]
    _LIBC.connect.restype = ctypes.c_int

    _LIBC.close.argtypes = [ctypes.c_int]
    _LIBC.close.restype = ctypes.c_int

    _LIBC.setsockopt.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_int]
    _LIBC.setsockopt.restype = ctypes.c_int


class SockAddrIn(ctypes.Structure):
    """struct sockaddr_in for IPv4."""
    _fields_ = [
        ("sin_family", ctypes.c_ushort),   # AF_INET
        ("sin_port", ctypes.c_ushort),     # Network byte order
        ("sin_addr", ctypes.c_ubyte * 4),   # IPv4 address
        ("sin_zero", ctypes.c_byte * 8),   # Padding
    ]


def _ip_to_struct_addr(ip_str: str) -> tuple[bytes, bytes]:
    """Convert IPv4 string to sin_addr bytes and sockaddr_in bytes."""
    parts = ip_str.split(".")
    if len(parts) != 4:
        raise ValueError(f"Invalid IPv4: {ip_str}")
    addr_bytes = bytes(int(p) for p in parts)
    return addr_bytes, addr_bytes


def native_tcp_connect(host: str, port: int, timeout_ms: int = 500) -> str:
    """Native non-blocking TCP connect with a strict timeout."""

    if not _NATIVE_AVAILABLE or _LIBC is None:
        return _fallback_tcp_connect(host, port, timeout_ms)

    fd = -1

    try:
        import errno

        host_text = str(host).strip()
        port_value = int(port)
        timeout_value = max(0, int(timeout_ms))

        if not host_text:
            return "INVALID_ARGUMENT"

        if port_value < 1 or port_value > 65535:
            return "INVALID_ARGUMENT"

        # Resolve through the existing safe resolver behavior.
        try:
            ip = _socket.gethostbyname(host_text)
        except _socket.gaierror:
            return "dns_error"
        except Exception:
            return "io_error"

        octets = [int(part) for part in ip.split(".")]

        if len(octets) != 4:
            return "INVALID_ARGUMENT"

        if any(value < 0 or value > 255 for value in octets):
            return "INVALID_ARGUMENT"

        AF_INET_LOCAL = 2
        SOCK_STREAM_LOCAL = 1

        F_GETFL = 3
        F_SETFL = 4
        O_NONBLOCK = 0x800

        SOL_SOCKET_LOCAL = 1
        SO_ERROR = 4

        POLLOUT = 0x004
        POLLERR = 0x008
        POLLHUP = 0x010
        POLLNVAL = 0x020

        class PollFD(ctypes.Structure):
            _fields_ = [
                ("fd", ctypes.c_int),
                ("events", ctypes.c_short),
                ("revents", ctypes.c_short),
            ]

        _LIBC.socket.argtypes = [
            ctypes.c_int,
            ctypes.c_int,
            ctypes.c_int,
        ]
        _LIBC.socket.restype = ctypes.c_int

        _LIBC.fcntl.argtypes = [
            ctypes.c_int,
            ctypes.c_int,
            ctypes.c_int,
        ]
        _LIBC.fcntl.restype = ctypes.c_int

        _LIBC.connect.argtypes = [
            ctypes.c_int,
            ctypes.c_void_p,
            ctypes.c_uint,
        ]
        _LIBC.connect.restype = ctypes.c_int

        _LIBC.poll.argtypes = [
            ctypes.POINTER(PollFD),
            ctypes.c_ulong,
            ctypes.c_int,
        ]
        _LIBC.poll.restype = ctypes.c_int

        _LIBC.getsockopt.argtypes = [
            ctypes.c_int,
            ctypes.c_int,
            ctypes.c_int,
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_uint),
        ]
        _LIBC.getsockopt.restype = ctypes.c_int

        _LIBC.close.argtypes = [ctypes.c_int]
        _LIBC.close.restype = ctypes.c_int

        ctypes.set_errno(0)

        fd = _LIBC.socket(
            AF_INET_LOCAL,
            SOCK_STREAM_LOCAL,
            0,
        )

        if fd < 0:
            return "io_error"

        flags = _LIBC.fcntl(fd, F_GETFL, 0)

        if flags < 0:
            return "io_error"

        if _LIBC.fcntl(
            fd,
            F_SETFL,
            flags | O_NONBLOCK,
        ) < 0:
            return "io_error"

        address = SockAddrIn()
        address.sin_family = AF_INET_LOCAL
        address.sin_port = _socket.htons(port_value)

        for index, value in enumerate(octets):
            address.sin_addr[index] = value

        ctypes.set_errno(0)

        connect_result = _LIBC.connect(
            fd,
            ctypes.byref(address),
            ctypes.sizeof(address),
        )

        if connect_result == 0:
            return "open"

        connect_errno = ctypes.get_errno()

        if connect_errno == errno.ECONNREFUSED:
            return "connection_refused"

        if connect_errno == errno.EHOSTUNREACH:
            return "host_unreachable"

        if connect_errno == errno.ENETUNREACH:
            return "network_unreachable"

        if connect_errno == errno.ETIMEDOUT:
            return "timeout"

        pending_errors = {
            errno.EINPROGRESS,
            errno.EWOULDBLOCK,
            errno.EAGAIN,
            errno.EALREADY,
        }

        if connect_errno not in pending_errors:
            return "io_error"

        poll_fd = PollFD(
            fd=fd,
            events=POLLOUT | POLLERR | POLLHUP,
            revents=0,
        )

        poll_result = _LIBC.poll(
            ctypes.byref(poll_fd),
            1,
            timeout_value,
        )

        if poll_result == 0:
            return "timeout"

        if poll_result < 0:
            return "io_error"

        if poll_fd.revents & POLLNVAL:
            return "io_error"

        socket_error = ctypes.c_int(0)
        socket_error_length = ctypes.c_uint(
            ctypes.sizeof(socket_error)
        )

        get_error_result = _LIBC.getsockopt(
            fd,
            SOL_SOCKET_LOCAL,
            SO_ERROR,
            ctypes.byref(socket_error),
            ctypes.byref(socket_error_length),
        )

        if get_error_result < 0:
            return "io_error"

        error_value = socket_error.value

        if error_value == 0:
            return "open"

        if error_value == errno.ECONNREFUSED:
            return "connection_refused"

        if error_value == errno.EHOSTUNREACH:
            return "host_unreachable"

        if error_value == errno.ENETUNREACH:
            return "network_unreachable"

        if error_value in {
            errno.ETIMEDOUT,
            errno.EINPROGRESS,
            errno.EALREADY,
        }:
            return "timeout"

        return "io_error"

    except (TypeError, ValueError, OverflowError):
        return "INVALID_ARGUMENT"

    except Exception:
        return "internal_error"

    finally:
        if fd >= 0:
            try:
                _LIBC.close(fd)
            except Exception:
                pass


def native_tcp_close(fd: int) -> bool:
    """Close a native socket via libc."""
    if not _NATIVE_AVAILABLE or _LIBC is None:
        return False
    try:
        _setup_libc()
        _LIBC.close(ctypes.c_int(fd))
        return True
    except Exception:
        return False


def _fallback_tcp_connect(host: str, port: int, timeout_ms: int = 500) -> str:
    """Fallback using Python socket module."""
    try:
        timeout = float(timeout_ms) / 1000.0
        s = _socket.socket(_socket.AF_INET, _socket.SOCK_STREAM)
        s.settimeout(timeout)
        try:
            code = s.connect_ex((str(host), int(port)))
            if code == 0:
                return "open"
            if code == ECONNREFUSED:
                return "connection_refused"
            if code in (ETIMEDOUT, EINPROGRESS):
                return "timeout"
            if code == EHOSTUNREACH:
                return "host_unreachable"
            if code == ENETUNREACH:
                return "network_unreachable"
            return "closed"
        except _socket.timeout:
            return "timeout"
        except _socket.gaierror:
            return "dns_error"
        except OSError as e:
            msg = str(e).lower()
            if "refused" in msg:
                return "connection_refused"
            if "unreachable" in msg:
                return "host_unreachable"
            return "io_error"
        except Exception:
            return "internal_error"
        finally:
            try:
                s.close()
            except Exception:
                pass
    except Exception:
        return "internal_error"


def native_tcp_banner(host: str, port: int, timeout_ms: int = 1000) -> str:
    """Read TCP banner using native socket."""
    if not _NATIVE_AVAILABLE or _LIBC is None:
        return _fallback_tcp_banner(host, port, timeout_ms)

    _setup_libc()

    try:
        host_str = str(host).strip()
        try:
            ip = _socket.gethostbyname(host_str)
        except Exception:
            return ""
        port_int = int(port)
        timeout_sec = float(timeout_ms) / 1000.0

        fd = _LIBC.socket(AF_INET, SOCK_STREAM, 0)
        if fd < 0:
            return _fallback_tcp_banner(host, port, timeout_ms)

        # Set timeout
        tv_buf = (ctypes.c_int * 2)(int(timeout_sec), int((timeout_sec - int(timeout_sec)) * 1000000))
        _LIBC.setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, tv_buf, ctypes.sizeof(tv_buf))
        _LIBC.setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, tv_buf, ctypes.sizeof(tv_buf))

        # Connect
        addr_bytes = bytes(int(x) for x in ip.split("."))
        sockaddr = SockAddrIn()
        sockaddr.sin_family = AF_INET
        for i in range(4):
            sockaddr.sin_addr[i] = addr_bytes[i]

        result = _LIBC.connect(fd, ctypes.byref(sockaddr), ctypes.sizeof(sockaddr))
        if result != 0:
            _LIBC.close(fd)
            return ""

        try:
            _LIBC.send(fd, b"\r\n", 2, 0)
        except Exception:
            pass

        buf = ctypes.create_string_buffer(256)
        n = _LIBC.recv(fd, buf, 256, 0)
        _LIBC.close(fd)

        if n > 0:
            return buf.raw[:n].decode("utf-8", errors="replace").strip()
        return ""
    except Exception:
        return _fallback_tcp_banner(host, port, timeout_ms)


def _fallback_tcp_banner(host: str, port: int, timeout_ms: int = 1000) -> str:
    """Fallback using Python socket module."""
    try:
        timeout = float(timeout_ms) / 1000.0
        s = _socket.socket(_socket.AF_INET, _socket.SOCK_STREAM)
        s.settimeout(timeout)
        try:
            code = s.connect_ex((str(host), int(port)))
            if code != 0:
                return ""
            try:
                s.sendall(b"\r\n")
            except Exception:
                pass
            data = s.recv(256)
            return data.decode("utf-8", errors="replace").strip()
        except Exception:
            return ""
        finally:
            try:
                s.close()
            except Exception:
                pass
    except Exception:
        return ""
