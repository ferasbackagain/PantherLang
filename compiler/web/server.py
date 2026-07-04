from __future__ import annotations

import json
from dataclasses import dataclass, field
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any, Callable


@dataclass
class Route:
    method: str
    path: str
    handler: Callable[..., Any] | None = None


class Router:
    def __init__(self) -> None:
        self._routes: list[Route] = []

    def add_route(self, method: str, path: str, handler: Callable[..., Any]) -> Route:
        route = Route(method=method.upper(), path=path, handler=handler)
        self._routes.append(route)
        return route

    def dispatch(self, method: str, path: str, **kwargs: Any) -> Any:
        for route in self._routes:
            if route.method == method.upper() and route.path == path:
                if route.handler:
                    return route.handler(**kwargs)
                return None
        return None

    @property
    def routes(self) -> list[Route]:
        return list(self._routes)


class PantherHTTPRequestHandler(BaseHTTPRequestHandler):
    router: Router = Router()

    def do_GET(self) -> None:
        result = self.router.dispatch("GET", self.path)
        self._send_response(result)

    def do_POST(self) -> None:
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b""
        result = self.router.dispatch("POST", self.path, body=body)
        self._send_response(result)

    def do_PUT(self) -> None:
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b""
        result = self.router.dispatch("PUT", self.path, body=body)
        self._send_response(result)

    def do_DELETE(self) -> None:
        result = self.router.dispatch("DELETE", self.path)
        self._send_response(result)

    def _send_response(self, result: Any) -> None:
        if result is None:
            self.send_response(404)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.end_headers()
            self.wfile.write(json.dumps({"error": "Not found"}).encode("utf-8"))
            return

        self.send_response(200)
        if isinstance(result, (dict, list)):
            self.send_header("Content-Type", "application/json; charset=utf-8")
            body = json.dumps(result).encode("utf-8")
        elif isinstance(result, str):
            lowered = result.lstrip().lower()
            if lowered.startswith("<html") or "<body" in lowered or lowered.startswith("<!doctype"):
                self.send_header("Content-Type", "text/html; charset=utf-8")
            else:
                self.send_header("Content-Type", "text/plain; charset=utf-8")
            body = result.encode("utf-8")
        else:
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            body = str(result).encode("utf-8")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: Any) -> None:
        pass


class HttpServer:
    def __init__(self, host: str = "0.0.0.0", port: int = 8080) -> None:
        self.host = host
        self.port = port
        self.router = Router()
        self._server: HTTPServer | None = None

    def route(self, method: str, path: str, handler: Callable[..., Any] | None = None) -> Route | Callable[[Callable[..., Any]], Route]:
        if handler is not None:
            return self.router.add_route(method, path, handler)
        def _deco(fn: Callable[..., Any]) -> Route:
            return self.router.add_route(method, path, fn)
        return _deco

    def get(self, path: str, handler: Callable[..., Any] | None = None) -> Route | Callable[[Callable[..., Any]], Route]:
        if handler is not None:
            return self.route("GET", path, handler)
        def _deco(fn: Callable[..., Any]) -> Route:
            return self.route("GET", path, fn)
        return _deco

    def post(self, path: str, handler: Callable[..., Any] | None = None) -> Route | Callable[[Callable[..., Any]], Route]:
        if handler is not None:
            return self.route("POST", path, handler)
        def _deco(fn: Callable[..., Any]) -> Route:
            return self.route("POST", path, fn)
        return _deco

    def put(self, path: str, handler: Callable[..., Any] | None = None) -> Route | Callable[[Callable[..., Any]], Route]:
        if handler is not None:
            return self.route("PUT", path, handler)
        def _deco(fn: Callable[..., Any]) -> Route:
            return self.route("PUT", path, fn)
        return _deco

    def delete(self, path: str, handler: Callable[..., Any] | None = None) -> Route | Callable[[Callable[..., Any]], Route]:
        if handler is not None:
            return self.route("DELETE", path, handler)
        def _deco(fn: Callable[..., Any]) -> Route:
            return self.route("DELETE", path, fn)
        return _deco

    def start(self) -> None:
        PantherHTTPRequestHandler.router = self.router
        self._server = HTTPServer((self.host, self.port), PantherHTTPRequestHandler)
        self._server.serve_forever()

    def stop(self) -> None:
        if self._server:
            self._server.shutdown()


def run_web(host: str = "0.0.0.0", port: int = 8080) -> HttpServer:
    server = HttpServer(host=host, port=port)
    return server
