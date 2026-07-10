from __future__ import annotations


class HostError:
    OK = "OK"
    INVALID_ARGUMENT = "INVALID_ARGUMENT"
    UNSUPPORTED = "UNSUPPORTED"
    PERMISSION_DENIED = "PERMISSION_DENIED"
    TIMEOUT = "TIMEOUT"
    CONNECTION_REFUSED = "CONNECTION_REFUSED"
    NETWORK_UNREACHABLE = "NETWORK_UNREACHABLE"
    HOST_UNREACHABLE = "HOST_UNREACHABLE"
    DNS_ERROR = "DNS_ERROR"
    IO_ERROR = "IO_ERROR"
    INTERNAL_ERROR = "INTERNAL_ERROR"


_ERROR_MESSAGES: dict[str, str] = {
    HostError.OK: "ok",
    HostError.INVALID_ARGUMENT: "invalid argument",
    HostError.UNSUPPORTED: "unsupported on this platform",
    HostError.PERMISSION_DENIED: "permission denied",
    HostError.TIMEOUT: "operation timed out",
    HostError.CONNECTION_REFUSED: "connection refused",
    HostError.NETWORK_UNREACHABLE: "network unreachable",
    HostError.HOST_UNREACHABLE: "host unreachable",
    HostError.DNS_ERROR: "dns resolution failed",
    HostError.IO_ERROR: "input/output error",
    HostError.INTERNAL_ERROR: "internal error",
}


def error_message(code: str) -> str:
    return _ERROR_MESSAGES.get(code, "unknown error")


def error_name(code: int) -> str:
    mapping = {
        0: HostError.OK,
        1: HostError.INVALID_ARGUMENT,
        2: HostError.UNSUPPORTED,
        3: HostError.PERMISSION_DENIED,
        4: HostError.TIMEOUT,
        5: HostError.CONNECTION_REFUSED,
        6: HostError.NETWORK_UNREACHABLE,
        7: HostError.HOST_UNREACHABLE,
        8: HostError.DNS_ERROR,
        9: HostError.IO_ERROR,
        10: HostError.INTERNAL_ERROR,
    }
    return mapping.get(code, HostError.INTERNAL_ERROR)
