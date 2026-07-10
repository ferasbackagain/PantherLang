from pathlib import Path

from compiler.stdlib.selfhost import apply_selfhosted_stdlib, load_selfhosted_stdlib_source
from compiler.runtime import execute_source
from compiler.lexer import lex_source


ROOT = Path(__file__).resolve().parents[1]


def test_selfhosted_stdlib_files_exist():
    assert (ROOT / "stdlib" / "selfhost" / "network.pan").exists()


def test_selfhosted_stdlib_loader_loads_panther_source():
    source = load_selfhosted_stdlib_source()
    assert "fn net_is_private_ip" in source
    assert "fn net_network_class" in source
    assert "fn net_risk_score" in source


def test_selfhosted_stdlib_injects_into_panther_main():
    user = 'panther main { print net_network_class("192.168.1.1"); }'
    expanded = apply_selfhosted_stdlib(user)
    assert "// PANTHER_STDLIB_SELFHOST_PHASE1" in expanded
    assert "fn net_network_class" in expanded
    assert 'print net_network_class("192.168.1.1");' in expanded


def test_selfhosted_network_logic_executes_from_panther_source():
    source = """
panther main {
    print net_network_class("192.168.1.10");
    print net_network_class("169.254.10.20");
    print net_network_class("8.8.8.8");
    print to_string(net_is_private_ip("172.20.1.2"));
    print to_string(net_is_private_ip("172.40.1.2"));
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == [
        "private",
        "link-local",
        "public-or-external",
        "true",
        "false",
    ]


def test_selfhosted_network_policy_executes_from_panther_source():
    source = """
panther main {
    let score = net_risk_score("8.8.8.8", 8, 1, false);
    print to_string(score);
    print net_security_label(score);
    print net_release_summary("8.8.8.8", score);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == [
        "85",
        "HIGH",
        "network=public-or-external;risk=HIGH",
    ]


def test_lexer_accepts_utf8_bom_source():
    tokens = lex_source('\ufeffpanther main { print "ok"; }')
    assert tokens


def test_selfhost_loader_does_not_inject_into_block_like_text_inside_strings():
    source = """
panther main {
    print "ai {} is a top-level block";
    print "web { is text only";
    print "api { is text only";
}
"""
    expanded = apply_selfhosted_stdlib(source)

    assert expanded.count("// PANTHER_STDLIB_SELFHOST_PHASE1") == 1
    assert '"ai {} is a top-level block"' in expanded
    assert '"web { is text only"' in expanded
    assert '"api { is text only"' in expanded

    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == [
        "ai {} is a top-level block",
        "web { is text only",
        "api { is text only",
    ]


def test_selfhost_loader_injects_real_ai_block_header_only():
    source = """
ai {
    print "real ai block";
}
"""
    expanded = apply_selfhosted_stdlib(source)

    assert expanded.count("// PANTHER_STDLIB_SELFHOST_PHASE1") == 1
    assert "fn net_network_class" in expanded


# Phase 1 self-host expansion tests

def test_selfhost_address_ipv4_validation():
    source = """
panther main {
    print to_string(net_is_valid_ipv4("192.168.1.1"));
    print to_string(net_is_valid_ipv4("0.0.0.0"));
    print to_string(net_is_valid_ipv4("255.255.255.255"));
    print to_string(net_is_valid_ipv4("300.1.1.1"));
    print to_string(net_is_valid_ipv4("abc"));
    print to_string(net_is_valid_ipv4("1.2.3"));
    print to_string(net_is_valid_ipv4("1.2.3.4.5"));
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["true", "true", "true", "false", "false", "false", "false"]


def test_selfhost_address_public_ip():
    source = """
panther main {
    print to_string(net_is_public_ip("8.8.8.8"));
    print to_string(net_is_public_ip("1.1.1.1"));
    print to_string(net_is_public_ip("192.168.1.1"));
    print to_string(net_is_public_ip("127.0.0.1"));
    print to_string(net_is_public_ip("169.254.1.1"));
    print to_string(net_is_public_ip("10.0.0.1"));
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["true", "true", "false", "false", "false", "false"]


def test_selfhost_address_normalize():
    source = """
panther main {
    print net_normalize_ip("1.2.3.4");
    print net_normalize_ip("127.0.0.1");
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["1.2.3.4", "127.0.0.1"]


def test_selfhost_services_port_mapping():
    source = """
panther main {
    print net_port_to_service_name(22);
    print net_port_to_service_name(80);
    print net_port_to_service_name(443);
    print net_port_to_service_name(3306);
    print net_port_to_service_name(5432);
    print net_port_to_service_name(6379);
    print net_port_to_service_name(9999);
    print to_string(net_is_well_known_port(22));
    print to_string(net_is_well_known_port(8080));
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ssh", "http", "https", "mysql", "postgresql", "redis", "abyss", "true", "false"]


def test_selfhost_services_confidence():
    source = """
panther main {
    print net_service_confidence(22, "SSH-2.0");
    print net_service_confidence(22, "");
    print net_service_confidence(80, "HTTP/1.1");
    print net_service_confidence(443, "");
    print net_service_confidence(8080, "");
    print net_service_confidence(9999, "data");
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["high", "medium", "high", "medium", "low", "medium"]


def test_selfhost_discovery_dedup():
    source = """
panther main {
    let items = ["a", "b", "a", "c", "b", "c"];
    let deduped = net_dedup_strings(items);
    print to_string(len(deduped));
    print deduped[0];
    print deduped[1];
    print deduped[2];
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["3", "a", "b", "c"]


def test_selfhost_discovery_empty_input():
    source = """
panther main {
    let empty = [];
    let deduped = net_dedup_strings(empty);
    print to_string(len(deduped));
    print to_string(net_count_open(empty));
    print to_string(net_count_closed(empty));
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["0", "0", "0"]


def test_selfhost_discovery_counting():
    source = """
panther main {
    let states = ["open", "closed", "open", "closed", "filtered"];
    print to_string(net_count_open(states));
    print to_string(net_count_closed(states));
    print net_result_summary(states);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["2", "2", "open=2;closed=2;total=5"]


def test_selfhost_discovery_duration():
    source = """
panther main {
    print net_format_duration(1000, 3500);
    print net_format_duration(0, 500);
    print net_format_duration(0, 0);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["2.500s", "0.500s", "0.0s"]


def test_selfhost_policy_authorized():
    source = """
panther main {
    print to_string(net_is_authorized_target("192.168.1.1"));
    print to_string(net_is_authorized_target("10.0.0.5"));
    print to_string(net_is_authorized_target("127.0.0.1"));
    print to_string(net_is_authorized_target("8.8.8.8"));
    print to_string(net_is_authorized_target("1.1.1.1"));
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["true", "true", "true", "false", "false"]


def test_selfhost_policy_scan_profile():
    source = """
panther main {
    print net_scan_profile("single");
    print net_scan_profile("subnet");
    print net_scan_profile("other");
    print net_open_port_summary(0, 10);
    print net_open_port_summary(10, 10);
    print net_open_port_summary(7, 10);
    print net_open_port_summary(3, 10);
    print net_timeout_status(10, 0);
    print net_timeout_status(10, 10);
    print net_timeout_status(10, 6);
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == [
        "quick", "balanced", "conservative",
        "no-open-ports", "all-open", "mostly-open", "partially-open",
        "no-timeouts", "all-timed-out", "mostly-timed-out",
    ]


def test_selfhost_files_exist():
    from pathlib import Path
    root = Path(__file__).resolve().parents[1]
    for fname in ("address.pan", "services.pan", "discovery.pan", "policy.pan", "network.pan"):
        assert (root / "stdlib" / "selfhost" / fname).exists(), f"Missing {fname}"


def test_selfhost_loader_injects_all_functions():
    source = load_selfhosted_stdlib_source()
    assert "fn net_is_valid_ipv4" in source
    assert "fn net_port_to_service_name" in source
    assert "fn net_dedup_strings" in source
    assert "fn net_is_authorized_target" in source
    assert "fn net_is_loopback_ip" in source
    assert "fn net_network_class" in source


# Phase 2 Host ABI tests

def test_host_abi_capability_available():
    source = """
panther main {
    print to_string(host_capability_available("system_hostname"));
    print to_string(host_capability_available("tcp_connect"));
    print to_string(host_capability_available("nonexistent"));
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["true", "true", "false"]


def test_host_abi_list_capabilities():
    source = """
panther main {
    let caps = host_list_capabilities();
    print to_string(len(caps));
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] != "0"


def test_host_abi_error_message():
    source = """
panther main {
    print host_error_message("TIMEOUT");
    print host_error_message("OK");
    print host_error_message("UNKNOWN");
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["operation timed out", "ok", "unknown error"]


def test_tcp_connect_closed_port():
    source = """
panther main {
    print tcp_connect("127.0.0.1", 1, 100);
    print tcp_connect("127.0.0.1", 65432, 100);
}
"""
    result = execute_source(source)
    assert result.error is None
    for state in result.captured_output:
        assert state in ("connection_refused", "closed", "timeout", "host_unreachable", "network_unreachable")


def test_tcp_connect_invalid_args():
    source = """
panther main {
    print tcp_connect("127.0.0.1", -1, 100);
    print tcp_connect("127.0.0.1", "abc", 100);
}
"""
    result = execute_source(source)
    assert result.error is None


def test_net_primary_ip():
    source = """
panther main {
    let ip = net_primary_ip();
    print to_string(len(ip) > 0);
}
"""
    result = execute_source(source)
    assert result.error is None


def test_net_neighbors():
    source = """
panther main {
    let neighbors = net_neighbors();
    print to_string(len(neighbors) >= 0);
}
"""
    result = execute_source(source)
    assert result.error is None


def test_net_dns_servers():
    source = """
panther main {
    let servers = net_dns_servers();
    print to_string(type_of(servers));
}
"""
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output[0] == "string"

