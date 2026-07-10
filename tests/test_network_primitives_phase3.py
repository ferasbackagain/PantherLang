"""Phase 3 — Real Network Primitive Foundation Tests.

Tests use only localhost — no external internet dependency.
A temporary TCP server is started for open-port tests.
"""

from compiler.runtime import execute_source


def _find_free_port() -> int:
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def test_tcp_connect_open_port():
    """Start a local TCP server and verify tcp_connect detects it as open."""
    port = _find_free_port()
    setup = f"""
panther main {{
    let ok = net_tcp_serve_start({port}, "hello\\n", false);
    print to_string(ok);
}}
"""
    r = execute_source(setup)
    assert r.error is None
    assert r.captured_output == ["true"]

    source = f"""
panther main {{
    let state = tcp_connect("127.0.0.1", {port}, 2000);
    print state;
}}
"""
    result = execute_source(source)
    assert result.error is None, f"Error: {result.error}"
    assert result.captured_output == ["open"], f"Expected open, got {result.captured_output}"

    # Cleanup
    cleanup = f"""
panther main {{
    net_tcp_serve_stop({port});
}}
"""
    execute_source(cleanup)


def test_tcp_banner_local_server():
    """Start a local TCP server and read its banner."""
    port = _find_free_port()
    setup = f"""
panther main {{
    let ok = net_tcp_serve_start({port}, "SSH-2.0-OpenSSH\\n", false);
    print to_string(ok);
}}
"""
    r = execute_source(setup)
    assert r.error is None

    source = f"""
panther main {{
    let banner = tcp_banner("127.0.0.1", {port}, 2000);
    print banner;
}}
"""
    result = execute_source(source)
    assert result.error is None
    # The server sends back the full response including what we send + response
    assert len(result.captured_output[0]) > 0, "Banner should not be empty"

    cleanup = f"""
panther main {{
    net_tcp_serve_stop({port});
}}
"""
    execute_source(cleanup)


def test_tcp_connect_closed_port():
    """Verify a closed port returns connection_refused."""
    source = """
panther main {
    let state = tcp_connect("127.0.0.1", 1, 500);
    print state;
}
"""
    result = execute_source(source)
    assert result.error is None
    state = result.captured_output[0]
    assert state in ("connection_refused", "closed"), f"Expected refused/closed, got {state}"


def test_tcp_connect_invalid_host():
    """Verify invalid hostname returns appropriate error state."""
    source = """
panther main {
    let state = tcp_connect("zzzzzzzzzzzzzzzzzzzz.invalid", 80, 500);
    print state;
}
"""
    result = execute_source(source)
    assert result.error is None
    state = result.captured_output[0]
    assert state in ("dns_error", "io_error", "internal_error"), f"Expected dns/io error, got {state}"


def test_tcp_connect_invalid_port():
    """Verify invalid port returns INVALID_ARGUMENT."""
    source = """
panther main {
    print tcp_connect("127.0.0.1", -1, 100);
    print tcp_connect("127.0.0.1", "abc", 100);
}
"""
    result = execute_source(source)
    assert result.error is None
    # First call: -1 might be accepted by OS as valid port, or return error
    # Second call: "abc" should return INVALID_ARGUMENT
    assert "INVALID_ARGUMENT" in result.captured_output


def test_tcp_repeated_operations():
    """Verify multiple socket operations can be performed."""
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
    let r1 = tcp_banner("127.0.0.1", {port}, 1000);
    let r2 = tcp_banner("127.0.0.1", {port}, 1000);
    let r3 = tcp_connect("127.0.0.1", {port}, 1000);
    print to_string(len(r1) > 0);
    print to_string(len(r2) > 0);
    print r3;
}}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[:2] == ["true", "true"]
    assert result.captured_output[2] == "open"

    cleanup = f"""
panther main {{
    net_tcp_serve_stop({port});
}}
"""
    execute_source(cleanup)


def test_tcp_connect_timeout():
    """Verify timeout behavior with a very short timeout on an unrouted IP."""
    source = """
panther main {
    let state = tcp_connect("10.255.255.254", 80, 50);
    print state;
}
"""
    result = execute_source(source)
    assert result.error is None
    state = result.captured_output[0]
    assert state in ("timeout", "host_unreachable", "network_unreachable", "connection_refused", "closed", "io_error"), \
        f"Expected timeout-like state, got {state}"


def test_dns_localhost_resolve():
    """Verify DNS resolution works for localhost."""
    source = """
panther main {
    let ip = net_resolve("localhost");
    print to_string(len(ip) > 0);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["true"]


def test_dns_invalid_host():
    """Verify DNS resolution failure for invalid host."""
    source = """
panther main {
    let ip = net_resolve("nonexistent-host-xyz-999.local");
    print ip;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == [""], "Should return empty for unresolvable host"


def test_resource_cleanup():
    """Verify repeated start/stop cycles work without resource leaks."""
    for i in range(3):
        port = _find_free_port()
        source_start = f"""
panther main {{
    let ok = net_tcp_serve_start({port}, "ok\\n", true);
    print to_string(ok);
}}
"""
        result = execute_source(source_start)
        assert result.error is None

        source_stop = f"""
panther main {{
    let ok = net_tcp_serve_stop({port});
    print to_string(ok);
}}
"""
        result = execute_source(source_stop)
        assert result.error is None
