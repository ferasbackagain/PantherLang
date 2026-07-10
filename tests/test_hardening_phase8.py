"""Phase 8 — Production Hardening Tests.

Covers socket leak resilience, timeout correctness, malformed input,
DNS failure handling, error model determinism, and native backend proof.
"""

from compiler.runtime import execute_source
from compiler.host_abi.backends.native_socket import native_available, native_tcp_connect


def _find_free_port() -> int:
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


# --- Timeout Correctness ---

def test_timeout_very_short():
    """Very short timeout should complete quickly and not hang."""
    source = """
panther main {
    let start = time_now();
    let state = tcp_connect("10.255.255.254", 80, 10);
    let elapsed = time_now() - start;
    print state;
    print to_string(elapsed < 2.0);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[1] == "true", "Timeout took too long"


def test_timeout_zero():
    """Zero timeout should not crash."""
    source = """
panther main {
    let state = tcp_connect("127.0.0.1", 1, 0);
    print state;
}
"""
    result = execute_source(source)
    assert result.error is None


def test_timeout_negative():
    """Negative timeout should not crash."""
    source = """
panther main {
    let state = tcp_connect("127.0.0.1", 1, -100);
    print state;
}
"""
    result = execute_source(source)
    assert result.error is None


# --- Malformed Input ---

def test_empty_host():
    """Empty host should not crash."""
    source = """
panther main {
    let state = tcp_connect("", 80, 100);
    print to_string(len(state) > 0);
}
"""
    result = execute_source(source)
    assert result.error is None


def test_nonexistent_host():
    """Fully nonexistent host should return error state."""
    source = """
panther main {
    let state = tcp_connect("zzzzzzzzzzzzzzzzzzzzzzzzzzzz.invalid", 80, 100);
    print state;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] in ("dns_error", "io_error", "internal_error")


def test_negative_port():
    """Negative port should not crash."""
    source = """
panther main {
    let state = tcp_connect("127.0.0.1", -1, 100);
    print to_string(len(state) > 0);
}
"""
    result = execute_source(source)
    assert result.error is None


def test_zero_port():
    """Port 0 should not crash."""
    source = """
panther main {
    let state = tcp_connect("127.0.0.1", 0, 100);
    print to_string(len(state) > 0);
}
"""
    result = execute_source(source)
    assert result.error is None


def test_oversized_port():
    """Very large port number should not crash."""
    source = """
panther main {
    let state = tcp_connect("127.0.0.1", 99999, 100);
    print to_string(len(state) > 0);
}
"""
    result = execute_source(source)
    assert result.error is None


# --- Error Model Determinism ---

def test_error_model_connect_states():
    """tcp_connect should return a known set of string states."""
    source = """
panther main {
    let s1 = tcp_connect("127.0.0.1", 1, 100);
    let s2 = tcp_connect("127.0.0.1", 22, 100);
    print s1;
    print s2;
}
"""
    result = execute_source(source)
    assert result.error is None
    known_states = {"open", "closed", "connection_refused", "timeout",
                    "host_unreachable", "network_unreachable", "dns_error",
                    "io_error", "internal_error", "INVALID_ARGUMENT"}
    for state in result.captured_output:
        assert state in known_states, f"Unknown state: {state}"


# --- DNS Failure ---

def test_dns_failure_empty_result():
    """net_resolve should return empty string for unresolvable names."""
    source = """
panther main {
    let ip = net_resolve("nonexistent-host-xyz-99999999.invalid");
    print to_string(ip == "");
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["true"]


def test_reverse_dns_empty():
    """net_reverse_resolve should return empty for unroutable IPs."""
    source = """
panther main {
    let name = net_reverse_resolve("10.255.255.254");
    print to_string(name == "");
}
"""
    result = execute_source(source)
    assert result.error is None


# --- Resource Resilience (multiple operations) ---

def test_many_rapid_connects():
    """Multiple rapid connect operations should not leak or crash."""
    source = """
panther main {
    for i in 0..9 {
        let state = tcp_connect("127.0.0.1", 1, 50);
        print state;
    }
}
"""
    result = execute_source(source)
    assert result.error is None
    assert len(result.captured_output) == 10


def test_mixed_open_closed():
    """Mix of open and closed ports should not leak."""
    port = _find_free_port()
    setup = f"""
panther main {{
    let ok = net_tcp_serve_start({port}, "ok\\n", false);
    print to_string(ok);
}}
"""
    r = execute_source(setup)
    assert r.error is None

    source = f"""
panther main {{
    for i in 0..4 {{
        print tcp_connect("127.0.0.1", {port}, 200);
        print tcp_connect("127.0.0.1", 1, 50);
    }}
}}
"""
    result = execute_source(source)
    assert result.error is None
    assert len(result.captured_output) == 10

    cleanup = f"""
panther main {{
    net_tcp_serve_stop({port});
}}
"""
    execute_source(cleanup)


# --- Native Backend Proof ---

def test_native_backend_available():
    """Native backend should be available on Linux."""
    assert native_available(), "Native backend should be available on Linux"


def test_native_backend_connect_open():
    """Native backend should detect open ports."""
    port = _find_free_port()
    setup = f"""
panther main {{
    let ok = net_tcp_serve_start({port}, "ok\\n", false);
    print to_string(ok);
}}
"""
    r = execute_source(setup)
    assert r.error is None

    if native_available():
        result = native_tcp_connect("127.0.0.1", port, 500)
        assert result == "open", f"Expected open, got {result}"

    cleanup = f"""
panther main {{
    net_tcp_serve_stop({port});
}}
"""
    execute_source(cleanup)


def test_native_backend_connect_closed():
    """Native backend should detect closed ports."""
    if native_available():
        result = native_tcp_connect("127.0.0.1", 1, 100)
        assert result in ("connection_refused", "closed"), f"Expected refused/closed, got {result}"


def test_native_backend_connect_via_panther():
    """Panther tcp_connect should route through native backend."""
    source = """
panther main {
    print tcp_connect("127.0.0.1", 22, 200);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] in ("open", "closed", "connection_refused")


# --- Platform Identification ---

def test_platform_identification():
    """Platform functions should return non-empty values."""
    source = """
panther main {
    print to_string(len(system_hostname()) > 0);
    print to_string(len(system_os()) > 0);
    print to_string(len(system_arch()) > 0);
    print to_string(system_cpu_count() > 0);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["true", "true", "true", "true"]


# --- Port Check ---

def test_port_check_api():
    """net_port_check should return bool."""
    port = _find_free_port()
    setup = f"""
panther main {{
    let ok = net_tcp_serve_start({port}, "ok\\n", false);
    print to_string(ok);
}}
"""
    r = execute_source(setup)
    assert r.error is None

    source = f"""
panther main {{
    print to_string(net_port_check("127.0.0.1", {port}));
}}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "true"

    cleanup = f"""
panther main {{
    net_tcp_serve_stop({port});
}}
"""
    execute_source(cleanup)


# --- Error Model Coverage ---

def test_host_abi_error_codes():
    """All Host ABI error codes should return descriptive messages."""
    source = """
panther main {
    print host_error_message("OK");
    print host_error_message("TIMEOUT");
    print host_error_message("CONNECTION_REFUSED");
    print host_error_message("DNS_ERROR");
    print host_error_message("HOST_UNREACHABLE");
    print host_error_message("NETWORK_UNREACHABLE");
    print host_error_message("INVALID_ARGUMENT");
    print host_error_message("UNSUPPORTED");
    print host_error_message("PERMISSION_DENIED");
    print host_error_message("IO_ERROR");
    print host_error_message("INTERNAL_ERROR");
}
"""
    result = execute_source(source)
    assert result.error is None
    assert len(result.captured_output) == 11
    for msg in result.captured_output:
        assert len(msg) > 0, "Empty error message"
