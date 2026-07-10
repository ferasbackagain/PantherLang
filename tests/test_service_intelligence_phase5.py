"""Phase 5 — Service Intelligence Tests.

Tests evidence-based service inference, confidence scoring, and
structured result formatting.
"""

from compiler.runtime import execute_source


def test_infer_service_ssh_with_banner():
    """SSH port 22 with SSH banner returns high confidence."""
    source = """
panther main {
    let r = net_infer_service(22, "SSH-2.0-OpenSSH_8.9", "");
    print r.service;
    print r.confidence;
    print r.evidence;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ssh", "high", "port+banner"]


def test_infer_service_ssh_port_no_banner():
    """SSH port 22 without banner returns medium confidence."""
    source = """
panther main {
    let r = net_infer_service(22, "", "");
    print r.service;
    print r.confidence;
    print r.evidence;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ssh", "medium", "port"]


def test_infer_service_http_port_no_banner():
    """HTTP port 80 without banner returns medium confidence."""
    source = """
panther main {
    let r = net_infer_service(80, "", "");
    print r.service;
    print r.confidence;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["http", "medium"]


def test_infer_service_https_port():
    """HTTPS port 443 returns medium confidence."""
    source = """
panther main {
    let r = net_infer_service(443, "", "");
    print r.service;
    print r.confidence;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["https", "medium"]


def test_infer_service_unknown_port_no_banner():
    """Unknown port without banner returns low confidence."""
    source = """
panther main {
    let r = net_infer_service(65535, "", "");
    print r.service;
    print r.confidence;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["unknown", "low"]


def test_infer_service_unknown_port_with_http_banner():
    """Unknown port with HTTP-like banner infers http at medium."""
    source = """
panther main {
    let r = net_infer_service(8888, "HTTP/1.1 200 OK", "");
    print r.service;
    print r.confidence;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["http", "medium"]


def test_infer_service_unknown_port_with_ssh_banner():
    """Unknown port with SSH-like banner infers ssh at medium."""
    source = """
panther main {
    let r = net_infer_service(2222, "SSH-2.0-something", "");
    print r.service;
    print r.confidence;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ssh", "medium"]


def test_http_probe_no_server():
    """HTTP probe on closed port returns negative result."""
    source = """
panther main {
    let r = net_probe_http("127.0.0.1", 1, 100);
    print to_string(r.http);
    print r.banner;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "false"
    assert result.captured_output[1] == ""


def test_format_service_result_ssh():
    """Structured result for SSH port."""
    source = """
panther main {
    let r = net_format_service_result("127.0.0.1", 22, "open", 3, "SSH-2.0");
    print r.target;
    print to_string(r.port);
    print r.state;
    print to_string(r.latency_ms);
    print r.service;
    print r.confidence;
    print r.evidence;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "127.0.0.1"
    assert result.captured_output[1] == "22"
    assert result.captured_output[2] == "open"
    assert result.captured_output[3] == "3"
    assert result.captured_output[4] == "ssh"
    assert result.captured_output[5] == "high"
    assert result.captured_output[6] == "port+banner"


def test_format_service_result_closed():
    """Structured result for closed port."""
    source = """
panther main {
    let r = net_format_service_result("10.0.0.1", 443, "closed", 0, "");
    print r.state;
    print r.service;
    print r.confidence;
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "closed"


def test_infer_service_with_reverse_dns():
    """Service inference considering reverse DNS."""
    source = """
panther main {
    let r = net_infer_service(22, "", "ssh.example.com");
    print r.service;
    print r.confidence;
    print r.evidence;
}
"""
    result = execute_source(source)
    assert result.error is None
    # reverse DNS contains "ssh" matches port 22 service
    assert r"ssh" in result.captured_output[0]
