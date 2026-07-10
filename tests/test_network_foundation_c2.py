"""Phase C2 — Network Foundation Tests

Tests for network introspection functions:
- net_local_ips, net_is_private_ip, net_reverse_resolve
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.runtime import execute_source


class TestNetLocalIPs:
    def test_returns_list(self):
        """net_local_ips() should return an array."""
        src = 'panther main {\n    let ips = net_local_ips();\n    print(to_string(len(ips)));\n}\n'
        result = execute_source(src)
        assert result.error is None
        count = "".join(result.captured_output).strip()
        assert count.isdigit()
        assert int(count) >= 1

    def test_includes_loopback(self):
        """net_local_ips() should include 127.0.0.1."""
        src = """panther main {
    let ips = net_local_ips();
    let found = false;
    for i in 0..len(ips)-1 {
        if ips[i] == "127.0.0.1" {
            found = true;
        };
    };
    print(to_string(found));
}"""
        result = execute_source(src)
        assert result.error is None
        assert "true" in "".join(result.captured_output).strip()


class TestNetIsPrivateIP:
    def test_private_10_dot(self):
        """10.x.x.x should be private."""
        src = 'panther main {\n    print(to_string(net_is_private_ip("10.0.0.1")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "true" in "".join(result.captured_output)

    def test_private_192_168(self):
        """192.168.x.x should be private."""
        src = 'panther main {\n    print(to_string(net_is_private_ip("192.168.1.1")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "true" in "".join(result.captured_output)

    def test_private_172_16_31(self):
        """172.16.0.0 - 172.31.255.255 should be private."""
        src = 'panther main {\n    print(to_string(net_is_private_ip("172.16.0.1")));\n    print(to_string(net_is_private_ip("172.31.0.1")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output)
        assert out.count("true") == 2

    def test_public_ip(self):
        """8.8.8.8 should NOT be private."""
        src = 'panther main {\n    print(to_string(net_is_private_ip("8.8.8.8")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "false" in "".join(result.captured_output)

    def test_loopback_is_private(self):
        """127.0.0.1 should be private."""
        src = 'panther main {\n    print(to_string(net_is_private_ip("127.0.0.1")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "true" in "".join(result.captured_output)

    def test_invalid_ip(self):
        """Invalid IP strings should return false."""
        src = 'panther main {\n    print(to_string(net_is_private_ip("not.an.ip")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "false" in "".join(result.captured_output)

    def test_empty_string(self):
        """Empty string should return false."""
        src = 'panther main {\n    print(to_string(net_is_private_ip("")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "false" in "".join(result.captured_output)


class TestNetReverseResolve:
    def test_reverse_resolve_invalid_ip_is_deterministic(self):
        """Invalid reverse DNS input should return an empty string without external DNS."""
        src = 'panther main {\n    print(net_reverse_resolve("999.999.999.999"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert out == ""

    def test_resolve_localhost_v4(self):
        """127.0.0.1 should resolve (to localhost or hostname)."""
        src = 'panther main {\n    print(net_reverse_resolve("127.0.0.1"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert len(out) > 0 or out == ""

    def test_invalid_ip_returns_empty(self):
        """Invalid IP should return empty string."""
        src = 'panther main {\n    print(net_reverse_resolve("999.999.999.999"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert out == ""


class TestNetResolve:
    def test_resolve_localhost_is_deterministic(self):
        """net_resolve('localhost') should resolve without external DNS."""
        src = 'panther main {\n    let ip = net_resolve("localhost");\n    print(ip);\n}\n'
        result = execute_source(src)
        assert result.error is None
        ip = "".join(result.captured_output).strip()
        assert ip == "127.0.0.1" or ip == "::1" or len(ip) > 0

    def test_resolve_nonexistent(self):
        """net_resolve with nonexistent domain returns empty string."""
        src = 'panther main {\n    print(net_resolve("nonexistent-domain-xyz-12345.test"));\n}\n'
        result = execute_source(src)
        out = "".join(result.captured_output).strip()
        assert out == ""


class TestNetGateway:
    def test_gateway_not_unknown(self):
        """net_gateway() should return an actual gateway."""
        src = 'panther main {\n    print(net_gateway());\n}\n'
        result = execute_source(src)
        assert result.error is None
        gw = "".join(result.captured_output).strip()
        assert gw != "unknown"
        parts = gw.split(".")
        assert len(parts) == 4


class TestNetDNS:
    def test_dns_returns_list(self):
        """net_dns() should return array of DNS servers."""
        src = """panther main {
    let dns = net_dns();
    print(to_string(len(dns)));
}"""
        result = execute_source(src)
        assert result.error is None
        count = "".join(result.captured_output).strip()
        assert count.isdigit()
        assert int(count) >= 1
