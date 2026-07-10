"""Phase 6 — Network Mapper Application Tests.

Tests the full PantherLang network mapper example.
Uses localhost only — no external dependencies.
"""

from pathlib import Path

from compiler.runtime import execute_source


MAPPER_PATH = Path(__file__).resolve().parents[1] / "examples" / "network_mapper" / "main.pan"


def test_mapper_file_exists():
    assert MAPPER_PATH.exists(), f"Mapper not found at {MAPPER_PATH}"


def test_mapper_localhost_scan():
    """Run the mapper against localhost with a subset of ports.
    Verifies real output with no errors and no empty values.
    """
    source = f"""
panther main {{
    let target = "127.0.0.1";
    let ports = [22, 80, 443];
    let connect_timeout_ms = 500;
    let banner_timeout_ms = 300;

    print("PantherLang Network Mapper Test");

    let hostname = system_hostname();
    print("hostname:" + hostname);

    let platform_os = system_os();
    print("platform:" + platform_os);

    let primary = net_primary_ip();
    print("ip:" + primary);

    for i in 0..(len(ports) - 1) {{
        let port_num = ports[i];
        let state = tcp_connect(target, port_num, connect_timeout_ms);
        if state == "open" {{
            let banner = tcp_banner(target, port_num, banner_timeout_ms);
            let svc_info = net_infer_service(port_num, banner, "");
            print "open:" + to_string(port_num) + ":" + svc_info.service + ":" + svc_info.confidence;
        }} else {{
            print "state:" + to_string(port_num) + ":" + state;
        }}
    }}
}}
"""
    result = execute_source(source)
    assert result.error is None, f"Mapper error: {result.error}"

    output = result.captured_output
    assert len(output) > 0, "Mapper produced no output"

    header = output[0]
    assert "PantherLang Network Mapper Test" in header

    hostname_line = [l for l in output if l.startswith("hostname:")]
    assert len(hostname_line) > 0, "Missing hostname output"
    assert len(hostname_line[0]) > len("hostname:"), "Empty hostname"

    platform_line = [l for l in output if l.startswith("platform:")]
    assert len(platform_line) > 0, "Missing platform output"
    assert len(platform_line[0]) > len("platform:"), "Empty platform"

    ip_line = [l for l in output if l.startswith("ip:")]
    assert len(ip_line) > 0, "Missing IP output"
    assert len(ip_line[0]) > len("ip:"), "Empty IP"


def test_mapper_collects_banners():
    """Verify banner collection on a controlled test server."""
    source_start = """
panther main {
    let ok = net_tcp_serve_start(21999, "TestBanner-1.0\\n", false);
    print to_string(ok);
}
"""
    r = execute_source(source_start)
    assert r.error is None

    source = """
panther main {
    let state = tcp_connect("127.0.0.1", 21999, 1000);
    if state == "open" {
        let banner = tcp_banner("127.0.0.1", 21999, 1000);
        print "state:" + state;
        print "banner:" + banner;
        let svc = net_infer_service(21999, banner, "");
        print "svc:" + svc.service;
        print "conf:" + svc.confidence;
    } else {
        print "state:" + state;
    }
}
"""
    result = execute_source(source)
    assert result.error is None

    output = result.captured_output
    state_lines = [l for l in output if l.startswith("state:")]
    assert len(state_lines) > 0
    assert state_lines[0] == "state:open"

    banner_lines = [l for l in output if l.startswith("banner:")]
    assert len(banner_lines) > 0
    assert "TestBanner" in banner_lines[0], f"Expected TestBanner in output, got {banner_lines}"

    source_stop = """
panther main {
    net_tcp_serve_stop(21999);
}
"""
    execute_source(source_stop)


def test_mapper_handles_all_closed_ports():
    """Verify graceful handling when all ports are closed."""
    source = """
panther main {
    let ports = [59999, 60000, 60001];
    let open_count = 0;
    for i in 0..(len(ports) - 1) {
        let state = tcp_connect("127.0.0.1", ports[i], 100);
        if state == "open" {
            open_count = open_count + 1;
        }
    }
    print "open:" + to_string(open_count);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "open:0"
