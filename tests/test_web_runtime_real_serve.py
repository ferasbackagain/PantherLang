from __future__ import annotations

import json
import threading
import time
import urllib.request

from compiler.web import HttpServer


def test_http_server_returns_html_and_json_routes():
    server = HttpServer(host="127.0.0.1", port=0)
    server.router.add_route("GET", "/", lambda **kwargs: "<html><body><h1>Panther</h1></body></html>")
    server.router.add_route("GET", "/health", lambda **kwargs: {"status": "ok"})

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
                with urllib.request.urlopen(base_url + "/", timeout=1) as response:
                    body = response.read().decode("utf-8")
                    content_type = response.headers.get("Content-Type", "")
                    assert response.status == 200
                    assert "text/html" in content_type
                    assert "Hello" not in body or "Panther" in body
                    assert "Panther" in body
                break
            except Exception as exc:  # pragma: no cover - retry window
                last_error = exc
        time.sleep(0.05)
    else:
        server.stop()
        raise AssertionError(f"HTTP server did not become ready: {last_error}")

    assert base_url is not None
    try:
        with urllib.request.urlopen(base_url + "/health", timeout=1) as response:
            data = json.loads(response.read().decode("utf-8"))
            assert response.status == 200
            assert data["status"] == "ok"
    finally:
        server.stop()
        thread.join(timeout=2)
