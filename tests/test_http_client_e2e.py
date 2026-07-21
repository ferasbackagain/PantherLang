"""E2E tests: panther.http client against panther.web server."""

import json
import threading
import urllib.request

from compiler.runtime.execution_pipeline import execute_source
from compiler.web import HttpServer


def _start_server():
    server = HttpServer(host="127.0.0.1", port=0)

    @server.get("/")
    def index(**kwargs):
        return "Hello World"

    @server.get("/health")
    def health(**kwargs):
        return {"status": "ok", "version": "2.0.0"}

    @server.get("/users/{uid}")
    def user(**kwargs):
        return {"user_id": kwargs.get("uid", "")}

    @server.post("/echo")
    def echo(**kwargs):
        body = kwargs.get("body", b"")
        body_str = body.decode() if isinstance(body, bytes) else str(body)
        return {"echo": body_str}

    t = threading.Thread(target=server.start, daemon=True)
    t.start()
    server._started.wait(timeout=5.0)
    return server, server.port


def test_http_get_from_pan():
    """panther.http.get() makes a real HTTP GET request."""
    server, port = _start_server()
    try:
        source = f"""
panther main {{
    import panther.http as http;
    let result = http.get("http://127.0.0.1:{port}/", 5);
    print "result: " + result;
}}
"""
        result = execute_source(source)
        assert result.error is None, f"Execution error: {result.error}"
        output = " ".join(result.captured_output)
        assert "Hello World" in output, f"Expected 'Hello World' in output, got: {output}"
    finally:
        server.stop()


def test_http_get_json_from_pan():
    """panther.http.get_json() returns parsed JSON."""
    server, port = _start_server()
    try:
        source = f"""
panther main {{
    import panther.http as http;
    import panther.core as core;
    let data = http.get_json("http://127.0.0.1:{port}/health", 5);
    print "raw: " + core.to_string(data);
    if data != null {{
        print "status: " + core.to_string(data["status"]);
    }}
}}
"""
        result = execute_source(source)
        assert result.error is None, f"Execution error: {result.error}"
        output = " ".join(result.captured_output)
        assert "status:" in output, f"Expected 'status:' in output, got: {output}"
        assert "ok" in output, f"Expected 'ok' in output, got: {output}"
    finally:
        server.stop()


def test_http_post_from_pan():
    """panther.http.post() sends data to the server."""
    server, port = _start_server()
    try:
        source = f"""
panther main {{
    import panther.http as http;
    import panther.core as core;
    let body = http.post("http://127.0.0.1:{port}/echo", "hello", 5);
    print "echo: " + body;
}}
"""
        result = execute_source(source)
        assert result.error is None, f"Execution error: {result.error}"
        output = " ".join(result.captured_output)
        assert "hello" in output, f"Expected 'hello' in output, got: {output}"
    finally:
        server.stop()


def test_http_request_structured():
    """panther.http.request() returns structured response with ok/status/body."""
    server, port = _start_server()
    try:
        source = f"""
panther main {{
    import panther.http as http;
    import panther.core as core;
    let resp = http.request("GET", "http://127.0.0.1:{port}/", "", 5);
    print "ok: " + core.to_string(resp.ok);
    print "status: " + core.to_string(resp.status);
    print "body: " + resp.body;
}}
"""
        result = execute_source(source)
        assert result.error is None, f"Execution error: {result.error}"
        output = " ".join(result.captured_output)
        assert "ok: true" in output, f"Expected 'ok: true' in output, got: {output}"
        assert "status: 200" in output, f"Expected 'status: 200' in output, got: {output}"
        assert "Hello World" in output, f"Expected 'Hello World' in output, got: {output}"
    finally:
        server.stop()


def test_http_request_404():
    """panther.http.request() returns ok: false for 404."""
    server, port = _start_server()
    try:
        source = f"""
panther main {{
    import panther.http as http;
    import panther.core as core;
    let resp = http.request("GET", "http://127.0.0.1:{port}/nonexistent", "", 5);
    print "ok: " + core.to_string(resp.ok);
    print "status: " + core.to_string(resp.status);
}}
"""
        result = execute_source(source)
        assert result.error is None, f"Execution error: {result.error}"
        output = " ".join(result.captured_output)
        assert "ok: false" in output, f"Expected 'ok: false' in output, got: {output}"
    finally:
        server.stop()


def test_http_fetch_convenience():
    """panther.http.fetch() wraps http.request with convenience."""
    server, port = _start_server()
    try:
        source = f"""
panther main {{
    import panther.http as http;
    import panther.core as core;
    let resp = http.fetch("http://127.0.0.1:{port}/health", "GET", "", 5);
    print "ok: " + core.to_string(resp.ok);
    print "status: " + core.to_string(resp.status);
}}
"""
        result = execute_source(source)
        assert result.error is None, f"Execution error: {result.error}"
        output = " ".join(result.captured_output)
        assert "ok: true" in output, f"Expected 'ok: true' in output, got: {output}"
        assert "status: 200" in output, f"Expected 'status: 200' in output, got: {output}"
    finally:
        server.stop()
