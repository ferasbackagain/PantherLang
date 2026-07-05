from __future__ import annotations

import json
import re
import urllib.parse
from dataclasses import dataclass, field
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any, Callable, Pattern


@dataclass
class Route:
    method: str
    path: str
    handler: Callable[..., Any] | None = None
    _pattern: Pattern | None = None
    _param_names: tuple[str, ...] = ()


def _compile_route_pattern(path: str) -> tuple[Pattern | None, tuple[str, ...]]:
    """Convert a route path with {param} placeholders to a regex pattern."""
    if "{" not in path:
        return None, ()
    param_names: list[str] = []
    regex_parts: list[str] = []
    i = 0
    while i < len(path):
        if path[i] == "{":
            end = path.find("}", i)
            if end == -1:
                return None, ()
            name = path[i + 1 : end]
            param_names.append(name)
            regex_parts.append(r"(?P<" + name + r">[^/]+)")
            i = end + 1
        else:
            regex_parts.append(re.escape(path[i]))
            i += 1
    pattern = re.compile("^" + "".join(regex_parts) + "$")
    return pattern, tuple(param_names)


class Router:
    def __init__(self) -> None:
        self._routes: list[Route] = []

    def add_route(self, method: str, path: str, handler: Callable[..., Any]) -> Route:
        pattern, param_names = _compile_route_pattern(path)
        route = Route(
            method=method.upper(),
            path=path,
            handler=handler,
            _pattern=pattern,
            _param_names=param_names,
        )
        self._routes.append(route)
        return route

    def dispatch(self, method: str, path: str, **kwargs: Any) -> Any:
        for route in self._routes:
            if route.method != method.upper():
                continue
            if route._pattern:
                match = route._pattern.match(path)
                if match:
                    for name in route._param_names:
                        kwargs[name] = match.group(name)
                    if route.handler:
                        return route.handler(**kwargs)
                    return None
            elif route.path == path:
                if route.handler:
                    return route.handler(**kwargs)
                return None
        return None

    @property
    def routes(self) -> list[Route]:
        return list(self._routes)


class PantherHTTPRequestHandler(BaseHTTPRequestHandler):
    router: Router = Router()

    def _parse_path(self, raw_path: str) -> tuple[str, dict[str, str]]:
        if "?" in raw_path:
            path_part, query_part = raw_path.split("?", 1)
            params = dict(urllib.parse.parse_qsl(query_part))
        else:
            path_part = raw_path
            params = {}
        return path_part, params

    def do_GET(self) -> None:
        path_part, params = self._parse_path(self.path)
        result = self.router.dispatch("GET", path_part, **params)
        self._send_response(result)

    def do_POST(self) -> None:
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b""
        path_part, params = self._parse_path(self.path)
        kwargs: dict[str, Any] = dict(params)
        kwargs["body"] = body
        result = self.router.dispatch("POST", path_part, **kwargs)
        self._send_response(result)

    def do_PUT(self) -> None:
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b""
        path_part, params = self._parse_path(self.path)
        kwargs: dict[str, Any] = dict(params)
        kwargs["body"] = body
        result = self.router.dispatch("PUT", path_part, **kwargs)
        self._send_response(result)

    def do_DELETE(self) -> None:
        path_part, params = self._parse_path(self.path)
        result = self.router.dispatch("DELETE", path_part, **params)
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
