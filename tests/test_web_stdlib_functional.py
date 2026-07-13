"""Tests for panther.web stdlib functional API with real HTTP server."""

import json
import threading
import urllib.request
import urllib.error


def _run_server(name="test"):
    from compiler.web import HttpServer
    server = HttpServer(host="127.0.0.1", port=0)
    return server


def _start_server(server):
    t = threading.Thread(target=server.start, daemon=True)
    t.start()
    server._started.wait(timeout=5.0)
    return server.port


def test_server_basic_text():
    server = _run_server()
    @server.get("/")
    def index(**kwargs):
        return "Hello World"
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/") as resp:
            assert resp.status == 200
            assert resp.read().decode() == "Hello World"
    finally:
        server.stop()


def test_server_health_json():
    server = _run_server()
    @server.get("/health")
    def health(**kwargs):
        return {"status": "ok", "service": "panther-test"}
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/health") as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["status"] == "ok"
            assert data["service"] == "panther-test"
    finally:
        server.stop()


def test_server_post_body():
    server = _run_server()
    @server.post("/echo")
    def echo(**kwargs):
        body = kwargs.get("body", b"")
        return {"received": body.decode() if isinstance(body, bytes) else str(body)}
    port = _start_server(server)
    try:
        req = urllib.request.Request(
            f"http://127.0.0.1:{port}/echo",
            data=b"Hello Panther",
            method="POST",
        )
        with urllib.request.urlopen(req) as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["received"] == "Hello Panther"
    finally:
        server.stop()


def test_server_path_params():
    server = _run_server()
    @server.get("/users/{user_id}")
    def get_user(**kwargs):
        return {"user_id": kwargs.get("user_id", "unknown")}
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/users/42") as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["user_id"] == "42"
    finally:
        server.stop()


def test_server_query_params():
    server = _run_server()
    @server.get("/search")
    def search(**kwargs):
        return {"query": kwargs.get("q", ""), "limit": kwargs.get("limit", "10")}
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/search?q=panther&limit=5") as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["query"] == "panther"
            assert data["limit"] == "5"
    finally:
        server.stop()


def test_server_404():
    server = _run_server()
    @server.get("/")
    def index(**kwargs):
        return "OK"
    port = _start_server(server)
    try:
        try:
            urllib.request.urlopen(f"http://127.0.0.1:{port}/nonexistent")
            assert False, "Should have raised HTTPError"
        except urllib.error.HTTPError as e:
            assert e.code == 404
    finally:
        server.stop()


def test_server_stop_and_restart():
    """Test stop then start a new server."""
    server = _run_server()
    @server.get("/")
    def index(**kwargs):
        return "First"
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/") as resp:
            assert resp.read().decode() == "First"
    finally:
        server.stop()

    # Start a new server on auto port
    server2 = _run_server()
    @server2.get("/")
    def index2(**kwargs):
        return "Second"
    port2 = _start_server(server2)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port2}/") as resp:
            assert resp.status == 200
            assert resp.read().decode() == "Second"
    finally:
        server2.stop()


def test_multiple_routes():
    """Test that multiple routes work together."""
    server = _run_server()
    @server.get("/a")
    def route_a(**kwargs):
        return "A"
    @server.get("/b")
    def route_b(**kwargs):
        return "B"
    @server.post("/c")
    def route_c(**kwargs):
        return {"posted": True}
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/a") as resp:
            assert resp.read().decode() == "A"
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/b") as resp:
            assert resp.read().decode() == "B"
        req = urllib.request.Request(f"http://127.0.0.1:{port}/c", method="POST", data=b"")
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())
            assert data["posted"] is True
    finally:
        server.stop()


if __name__ == "__main__":
    test_server_basic_text()
    print("test_server_basic_text passed")
    test_server_health_json()
    print("test_server_health_json passed")
    test_server_post_body()
    print("test_server_post_body passed")
    test_server_path_params()
    print("test_server_path_params passed")
    test_server_query_params()
    print("test_server_query_params passed")
    test_server_404()
    print("test_server_404 passed")
    test_server_stop_and_restart()
    print("test_server_stop_and_restart passed")
    test_multiple_routes()
    print("test_multiple_routes passed")
    print("\nAll tests passed!")
