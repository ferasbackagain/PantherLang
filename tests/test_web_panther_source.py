"""Test the panther.web stdlib package via PantherLang source execution."""

import json
import threading
import urllib.request
import urllib.error

from compiler.runtime.execution_pipeline import execute_source
from compiler.web import HttpServer


def test_web_package_functions_exist():
    """Verify that panther.web package functions exist and are callable."""
    source = """
panther main {
    import panther.web as web;
    import panther.core as core;
    
    let s = web.server_create("127.0.0.1", 0);
    let info = web.server_info(s);
    print "Server created: " + core.to_string(info);
}
"""
    result = execute_source(source)
    assert result.error is None, f"Execution error: {result.error}"
    output = " ".join(result.captured_output)
    assert "Server created" in output
    print("test_web_package_functions_exist: OK")


def test_web_package_route_compile():
    """Test that route registration compiles and runs."""
    source = """
panther main {
    import panther.web as web;
    import panther.core as core;
    
    let s = web.server_create("127.0.0.1", 0);
    
    let r1 = web.get(s, "/", fn(req) { return "Hello from .pan"; });
    print "Route / registered: " + core.to_string(r1);
    
    let r2 = web.get(s, "/health", fn(req) { return {status: "ok", source: "panther"}; });
    print "Route /health registered: " + core.to_string(r2);
    
    let info = web.server_info(s);
    print "Info: " + core.to_string(info);
}
"""
    result = execute_source(source)
    assert result.error is None, f"Execution error: {result.error}"
    output = " ".join(result.captured_output)
    assert "Route / registered" in output
    assert "Route /health registered" in output
    print("test_web_package_route_compile: OK")


def test_web_package_serve_requests():
    """Test that the HttpServer class serves real HTTP requests."""
    server = HttpServer(host="127.0.0.1", port=0)

    @server.get("/")
    def index(**kwargs):
        return "PantherLang Web OK"

    @server.get("/health")
    def health(**kwargs):
        return {"status": "ok", "version": "2.0.0"}

    @server.get("/users/{uid}")
    def user(**kwargs):
        return {"user_id": kwargs.get("uid", "")}

    @server.post("/echo")
    def echo(**kwargs):
        body = kwargs.get("body", b"").decode() if isinstance(kwargs.get("body"), bytes) else ""
        return {"echo": body}

    t = threading.Thread(target=server.start, daemon=True)
    t.start()
    server._started.wait(timeout=5.0)
    port = server.port

    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/") as resp:
            assert resp.status == 200
            assert resp.read().decode() == "PantherLang Web OK"

        with urllib.request.urlopen(f"http://127.0.0.1:{port}/health") as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["status"] == "ok"
            assert data["version"] == "2.0.0"

        with urllib.request.urlopen(f"http://127.0.0.1:{port}/users/99") as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["user_id"] == "99"

        req = urllib.request.Request(
            f"http://127.0.0.1:{port}/echo",
            data=b"hello world",
            method="POST",
        )
        with urllib.request.urlopen(req) as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["echo"] == "hello world"

        try:
            urllib.request.urlopen(f"http://127.0.0.1:{port}/no-such-route")
            assert False, "Should have raised HTTPError"
        except urllib.error.HTTPError as e:
            assert e.code == 404

        print("test_web_package_serve_requests: OK")
    finally:
        server.stop()


if __name__ == "__main__":
    test_web_package_functions_exist()
    test_web_package_route_compile()
    test_web_package_serve_requests()
    print("\nAll tests passed!")
