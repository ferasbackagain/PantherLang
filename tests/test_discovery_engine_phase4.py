"""Phase 4 — Panther Network Discovery Engine Tests.

Tests the PantherLang-based discovery engine using localhost TCP servers.
"""

from compiler.runtime import execute_source


def _find_free_port() -> int:
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def test_discovery_local_system_info():
    """Verify local system info returns real values."""
    source = """
panther main {
    let info = net_local_system_info();
    print to_string(len(info.hostname) > 0);
    print to_string(len(info.platform) > 0);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["true", "true"]


def test_discovery_host_open_port():
    """Verify discovery detects an open port."""
    port = _find_free_port()
    setup = f"""
panther main {{
    let ok = net_tcp_serve_start({port}, "test\\n", false);
    print to_string(ok);
}}
"""
    r = execute_source(setup)
    assert r.error is None

    source = f"""
panther main {{
    let ports = [{port}];
    let results = net_discover_host("127.0.0.1", ports, 1000);
    print to_string(len(results));
    print results[0].state;
    print results[0].port;
}}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "1"
    assert result.captured_output[1] == "open"
    assert int(result.captured_output[2]) == port

    cleanup = f"""
panther main {{
    net_tcp_serve_stop({port});
}}
"""
    execute_source(cleanup)


def test_discovery_host_closed_port():
    """Verify discovery detects closed ports."""
    source = """
panther main {
    let ports = [1, 2, 3];
    let results = net_discover_host("127.0.0.1", ports, 200);
    print to_string(len(results));
    for i in 0..2 {
        print results[i].state;
    }
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "3"
    for state in result.captured_output[1:]:
        assert state in ("connection_refused", "closed"), f"Expected refused/closed, got {state}"


def test_discovery_open_ports_filter():
    """Verify open port filtering works with mixed ports."""
    port = _find_free_port()
    setup = f"""
panther main {{
    let ok = net_tcp_serve_start({port}, "test\\n", false);
    print to_string(ok);
}}
"""
    r = execute_source(setup)
    assert r.error is None

    source = f"""
panther main {{
    let ports = [{port}, 1, 2];
    let results = net_discover_host("127.0.0.1", ports, 500);
    let open = net_open_ports(results);
    print to_string(len(open));
    if len(open) > 0 {{
        print to_string(open[0].port == {port});
    }}
}}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "1"

    cleanup = f"""
panther main {{
    net_tcp_serve_stop({port});
}}
"""
    execute_source(cleanup)


def test_discovery_services_on_open_ports():
    """Verify service names are attached to open ports."""
    port = _find_free_port()
    setup = f"""
panther main {{
    let ok = net_tcp_serve_start({port}, "test\\n", false);
    print to_string(ok);
}}
"""
    r = execute_source(setup)
    assert r.error is None

    source = f"""
panther main {{
    let ports = [{port}];
    let results = net_discover_host("127.0.0.1", ports, 500);
    let open = net_open_ports(results);
    let svcs = net_open_ports_with_services(open);
    print to_string(len(svcs));
    print svcs[0].service;
}}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "1"

    cleanup = f"""
panther main {{
    net_tcp_serve_stop({port});
}}
"""
    execute_source(cleanup)


def test_discovery_full_scan():
    """Verify complete scan_host returns structured summary."""
    port = _find_free_port()
    setup = f"""
panther main {{
    let ok = net_tcp_serve_start({port}, "SSH-2.0\\n", false);
    print to_string(ok);
}}
"""
    r = execute_source(setup)
    assert r.error is None

    source = f"""
panther main {{
    let ports = [{port}, 1];
    let summary = net_scan_host("127.0.0.1", ports, 500, 500);
    print summary.target;
    print to_string(summary.total_ports);
    print to_string(summary.open_count);
    print to_string(summary.closed_count);
    if len(summary.results) > 0 {{
        print to_string(summary.results[0].port == {port});
    }}
}}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "127.0.0.1"
    assert result.captured_output[1] == "2"
    assert result.captured_output[2] == "1"
    assert result.captured_output[3] == "1"

    cleanup = f"""
panther main {{
    net_tcp_serve_stop({port});
}}
"""
    execute_source(cleanup)


def test_discovery_format_result():
    """Verify result formatting."""
    source = """
panther main {
    let r = {port: 22, state: "open", latency_ms: 3, service: "ssh", banner: "SSH-2.0", confidence: "high"};
    print net_format_result(r);
    let r2 = {port: 443, state: "closed", latency_ms: 0, service: "", banner: "", confidence: ""};
    print net_format_result(r2);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert "/tcp" in result.captured_output[0]
    assert "State: open" in result.captured_output[0]
    assert "State: closed" in result.captured_output[1]
