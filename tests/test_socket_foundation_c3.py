"""Phase C3 — Socket Foundation Tests

Tests for TCP/UDP socket primitives:
- net_tcp_send, net_tcp_serve_start, net_tcp_serve_stop, net_udp_send
"""

from __future__ import annotations

import socket as _socket
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.runtime import execute_source


def _free_port() -> int:
    """Allocate a free TCP port on loopback."""
    s = _socket.socket(_socket.AF_INET, _socket.SOCK_STREAM)
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


class TestTCPSend:
    def test_tcp_send_receive(self):
        """TCP client should send data and receive response from echo server."""
        p = _free_port()
        src = f"""panther main {{
    net_tcp_serve_start({p}, "echo:ok", true);
    let resp = net_tcp_send("127.0.0.1", {p}, "hello");
    print(resp);
    net_tcp_serve_stop({p});
}}"""
        result = execute_source(src)
        assert result.error is None
        assert len(result.captured_output) >= 1
        assert result.captured_output[0].strip() == "echo:ok"

    def test_tcp_no_server_returns_empty(self):
        """TCP send with no server should return empty string."""
        p = _free_port()
        src = f"""panther main {{
    let resp = net_tcp_send("127.0.0.1", {p}, "test");
    print("[" + resp + "]");
}}"""
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert out == "[]"


class TestTCPServer:
    def test_start_stop(self):
        """TCP server should start and stop cleanly."""
        p = _free_port()
        src = f"""panther main {{
    let started = net_tcp_serve_start({p}, "ok", true);
    print(to_string(started));
    let stopped = net_tcp_serve_stop({p});
    print(to_string(stopped));
}}"""
        result = execute_source(src)
        assert result.error is None
        out = result.captured_output
        assert len(out) == 2
        assert out[0].strip() == "true"
        assert out[1].strip() == "true"

    def test_multiple_messages(self):
        """Multiple TCP messages should work sequentially."""
        p = _free_port()
        src = f"""panther main {{
    net_tcp_serve_start({p}, "resp", false);
    let r1 = net_tcp_send("127.0.0.1", {p}, "msg1");
    print(r1);
    let r2 = net_tcp_send("127.0.0.1", {p}, "msg2");
    print(r2);
    net_tcp_serve_stop({p});
}}"""
        result = execute_source(src)
        assert result.error is None
        out = result.captured_output
        assert len(out) == 2
        assert out[0].strip() == "resp"
        assert out[1].strip() == "resp"

    def test_custom_response(self):
        """TCP server should return the configured response."""
        p = _free_port()
        src = f"""panther main {{
    net_tcp_serve_start({p}, "custom-data", true);
    let r = net_tcp_send("127.0.0.1", {p}, "any");
    print(r);
    net_tcp_serve_stop({p});
}}"""
        result = execute_source(src)
        assert result.error is None
        assert len(result.captured_output) >= 1
        assert result.captured_output[0].strip() == "custom-data"


class TestUDPSend:
    def test_udp_no_server_returns_empty(self):
        """UDP send with no listener should return empty string."""
        p = _free_port()
        src = f"""panther main {{
    let resp = net_udp_send("127.0.0.1", {p}, "test");
    print("[" + resp + "]");
}}"""
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert out == "[]"
