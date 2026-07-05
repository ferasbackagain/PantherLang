from __future__ import annotations

import json
import threading
import time
import urllib.request
import urllib.error

from compiler.web import HttpServer


def _start_server(server: HttpServer) -> str:
    """Start server on loopback with ephemeral port, return base URL."""
    server.host = "127.0.0.1"
    server.port = 0
    server.router.add_route("GET", "/ping", lambda **kw: "pong")
    thread = threading.Thread(target=server.start, daemon=True)
    thread.start()
    deadline = time.time() + 5
    last_error = None
    base_url = None
    while time.time() < deadline:
        if server._server is not None:
            port = server._server.server_address[1]
            base_url = f"http://127.0.0.1:{port}"
            try:
                with urllib.request.urlopen(base_url + "/ping", timeout=1) as resp:
                    if resp.status == 200:
                        return base_url
            except Exception as exc:
                last_error = exc
        time.sleep(0.05)
    server.stop()
    raise RuntimeError(f"Server did not become ready: {last_error}")


def _get(url: str, timeout: int = 2) -> tuple[int, str, dict[str, str]]:
    req = urllib.request.Request(url, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
            headers = dict(resp.headers)
            return resp.status, body, headers
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8") if exc.fp else ""
        return exc.code, body, dict(exc.headers)


def _post(url: str, data: str = "", content_type: str = "application/json", timeout: int = 2) -> tuple[int, str, dict[str, str]]:
    req = urllib.request.Request(url, data=data.encode("utf-8"), method="POST")
    req.add_header("Content-Type", content_type)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
            headers = dict(resp.headers)
            return resp.status, body, headers
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8") if exc.fp else ""
        return exc.code, body, dict(exc.headers)


def _put(url: str, data: str = "", content_type: str = "application/json", timeout: int = 2) -> tuple[int, str, dict[str, str]]:
    req = urllib.request.Request(url, data=data.encode("utf-8"), method="PUT")
    req.add_header("Content-Type", content_type)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
            headers = dict(resp.headers)
            return resp.status, body, headers
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8") if exc.fp else ""
        return exc.code, body, dict(exc.headers)


def _delete(url: str, timeout: int = 2) -> tuple[int, str, dict[str, str]]:
    req = urllib.request.Request(url, method="DELETE")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
            headers = dict(resp.headers)
            return resp.status, body, headers
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8") if exc.fp else ""
        return exc.code, body, dict(exc.headers)


# ---- Tests ----

def test_get_route_returns_body() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/hello", lambda **kw: "Hello, World!")
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/hello")
        assert status == 200, f"Expected 200, got {status}"
        assert body == "Hello, World!", f"Unexpected body: {body}"
    finally:
        server.stop()


def test_get_route_returns_json() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/data", lambda **kw: {"key": "value", "num": 42})
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/data")
        assert status == 200
        data = json.loads(body)
        assert data["key"] == "value"
        assert data["num"] == 42
        ct = headers.get("Content-Type", "")
        assert "application/json" in ct
    finally:
        server.stop()


def test_post_receives_body() -> None:
    server = HttpServer()
    server.router.add_route("POST", "/echo", lambda **kw: kw.get("body", b"").decode("utf-8"))
    base = _start_server(server)
    try:
        status, body, headers = _post(base + "/echo", "hello panther")
        assert status == 200
        assert "hello panther" in body
    finally:
        server.stop()


def test_put_receives_body() -> None:
    server = HttpServer()
    server.router.add_route("PUT", "/resource", lambda **kw: {"updated": kw.get("body", b"").decode("utf-8")})
    base = _start_server(server)
    try:
        status, body, headers = _put(base + "/resource", '{"name":"test"}')
        assert status == 200
        data = json.loads(body)
        assert "test" in data["updated"]
    finally:
        server.stop()


def test_delete_route() -> None:
    server = HttpServer()
    server.router.add_route("DELETE", "/resource/1", lambda **kw: {"deleted": True})
    base = _start_server(server)
    try:
        status, body, headers = _delete(base + "/resource/1")
        assert status == 200
        data = json.loads(body)
        assert data["deleted"] is True
    finally:
        server.stop()


def test_unknown_route_returns_404() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/known", lambda **kw: "ok")
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/nonexistent")
        assert status == 404, f"Expected 404, got {status}"
        data = json.loads(body)
        assert "error" in data
    finally:
        server.stop()


def test_wrong_method_returns_404() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/only-get", lambda **kw: "get only")
    base = _start_server(server)
    try:
        status, body, headers = _post(base + "/only-get", "data")
        assert status == 404, f"Expected 404, got {status}"
    finally:
        server.stop()


def test_query_parameters_are_passed_to_handler() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/search", lambda **kw: {"q": kw.get("q", ""), "page": kw.get("page", "")})
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/search?q=panther&page=2")
        assert status == 200
        data = json.loads(body)
        assert data["q"] == "panther", f"Expected q=panther, got {data}"
        assert data["page"] == "2", f"Expected page=2, got {data}"
    finally:
        server.stop()


def test_query_parameters_missing_key() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/search", lambda **kw: kw.get("q", "default"))
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/search?page=3")
        assert status == 200
        assert body == "default"
    finally:
        server.stop()


def test_path_parameter_single() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/users/{id}", lambda **kw: {"user_id": kw.get("id", "")})
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/users/42")
        assert status == 200
        data = json.loads(body)
        assert data["user_id"] == "42", f"Expected user_id=42, got {data}"
    finally:
        server.stop()


def test_path_parameter_multiple() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/{resource}/{id}", lambda **kw: {"resource": kw.get("resource", ""), "id": kw.get("id", "")})
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/users/99")
        assert status == 200
        data = json.loads(body)
        assert data["resource"] == "users"
        assert data["id"] == "99"
    finally:
        server.stop()


def test_path_parameter_non_match() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/users/{id}", lambda **kw: {"user_id": kw.get("id", "")})
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/users/42/comments")
        assert status == 404, f"Expected 404 for non-matching path, got {status}"
    finally:
        server.stop()


def test_static_route_beats_path_parameter() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/users/me", lambda **kw: {"special": "me"})
    server.router.add_route("GET", "/users/{id}", lambda **kw: {"user_id": kw.get("id", "")})
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/users/me")
        assert status == 200
        data = json.loads(body)
        assert data["special"] == "me", f"Static route should win: {data}"
    finally:
        server.stop()


def test_json_response_from_dict() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/api/info", lambda **kw: {"version": "1.0", "name": "Panther"})
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/api/info")
        assert status == 200
        data = json.loads(body)
        assert data["version"] == "1.0"
        assert data["name"] == "Panther"
        assert "application/json" in headers.get("Content-Type", "")
    finally:
        server.stop()


def test_html_response_auto_detect() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/page", lambda **kw: "<html><body><h1>PantherLang</h1></body></html>")
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/page")
        assert status == 200
        assert "PantherLang" in body
        assert "text/html" in headers.get("Content-Type", "")
    finally:
        server.stop()


def test_plain_text_response() -> None:
    server = HttpServer()
    server.router.add_route("GET", "/text", lambda **kw: "just text")
    base = _start_server(server)
    try:
        status, body, headers = _get(base + "/text")
        assert status == 200
        assert body == "just text"
        assert "text/plain" in headers.get("Content-Type", "")
    finally:
        server.stop()
