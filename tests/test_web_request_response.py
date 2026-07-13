"""Tests for panther.web Request/Response model with structured API."""

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


def test_req_params_route():
    """Route parameters are accessible via req.params."""
    server = _run_server()
    @server.get("/users/{user_id}")
    def handler(**kwargs):
        return {"user_id": kwargs.get("user_id", "none")}
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/users/42") as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["user_id"] == "42"
    finally:
        server.stop()


def test_req_query_params():
    """Query parameters are accessible."""
    server = _run_server()
    @server.get("/search")
    def handler(**kwargs):
        return {"q": kwargs.get("q", ""), "limit": kwargs.get("limit", "10")}
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/search?q=test&limit=5") as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["q"] == "test"
            assert data["limit"] == "5"
    finally:
        server.stop()


def test_req_method_path():
    """Request method and path are accessible."""
    server = _run_server()
    @server.get("/info")
    def handler(**kwargs):
        from compiler.web.server import _request_context
        return {"method": getattr(_request_context, "method", ""), "path": getattr(_request_context, "path", "")}
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/info") as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["method"] == "GET"
            assert data["path"] == "/info"
    finally:
        server.stop()


def test_req_mixed_params():
    """Route and query params can coexist."""
    server = _run_server()
    @server.get("/items/{item_id}")
    def handler(**kwargs):
        return {"item_id": kwargs.get("item_id", ""), "detail": kwargs.get("detail", "")}
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/items/99?detail=full") as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["item_id"] == "99"
            assert data["detail"] == "full"
    finally:
        server.stop()


def test_req_body_bytes():
    """POST body is accessible."""
    server = _run_server()
    @server.post("/echo")
    def handler(**kwargs):
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


def test_response_object():
    """Response object format is handled."""
    server = _run_server()
    @server.get("/custom")
    def handler(**kwargs):
        return {"_type": "Response", "status": 201, "headers": {"X-Custom": "yes"}, "body": "created"}
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/custom") as resp:
            assert resp.status == 201
            assert resp.headers.get("X-Custom") == "yes"
            assert resp.read().decode() == "created"
    finally:
        server.stop()


def test_response_multiple_routes():
    """Multiple routes with different methods."""
    server = _run_server()
    @server.get("/resource")
    def get_handler(**kwargs):
        return {"action": "get"}
    @server.post("/resource")
    def post_handler(**kwargs):
        return {"action": "post"}
    @server.put("/resource")
    def put_handler(**kwargs):
        return {"action": "put"}
    @server.delete("/resource")
    def delete_handler(**kwargs):
        return {"action": "delete"}
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/resource") as resp:
            assert json.loads(resp.read().decode())["action"] == "get"
        req = urllib.request.Request(f"http://127.0.0.1:{port}/resource", method="POST", data=b"")
        with urllib.request.urlopen(req) as resp:
            assert json.loads(resp.read().decode())["action"] == "post"
        req = urllib.request.Request(f"http://127.0.0.1:{port}/resource", method="PUT", data=b"")
        with urllib.request.urlopen(req) as resp:
            assert json.loads(resp.read().decode())["action"] == "put"
        req = urllib.request.Request(f"http://127.0.0.1:{port}/resource", method="DELETE")
        with urllib.request.urlopen(req) as resp:
            assert json.loads(resp.read().decode())["action"] == "delete"
    finally:
        server.stop()


def test_error_handler_custom_404():
    """Custom 404 error handler returns user-defined response."""
    server = _run_server()
    @server.get("/")
    def index(**kwargs):
        return "OK"
    def not_found(**kwargs):
        return {"_type": "Response", "status": 404, "headers": {"Content-Type": "application/json"}, "body": '{"error": "custom not found"}'}
    server.set_error_handler(404, not_found)
    port = _start_server(server)
    try:
        try:
            urllib.request.urlopen(f"http://127.0.0.1:{port}/nonexistent")
            assert False, "Should have raised HTTPError"
        except urllib.error.HTTPError as e:
            assert e.code == 404
            data = json.loads(e.read().decode())
            assert data["error"] == "custom not found"
    finally:
        server.stop()


def test_logging_flag():
    """Logging flag can be enabled."""
    server = _run_server()
    @server.get("/")
    def index(**kwargs):
        return "OK"
    server.logging = True
    port = _start_server(server)
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/") as resp:
            assert resp.status == 200
    finally:
        server.stop()
