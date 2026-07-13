from __future__ import annotations

import json
import re
import threading
import urllib.parse
from dataclasses import dataclass, field
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any, Callable, Pattern

# Thread-local request context for route handlers
_request_context = threading.local()


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

    def _path_matches(self, path: str, route: Route) -> bool:
        if route._pattern:
            return route._pattern.match(path) is not None
        return route.path == path

    def dispatch(self, method: str, path: str, **kwargs: Any) -> Any:
        path_exists = False
        for route in self._routes:
            if route.method != method.upper():
                if not path_exists and self._path_matches(path, route):
                    path_exists = True
                continue
            if route._pattern:
                match = route._pattern.match(path)
                if match:
                    route_params: dict[str, str] = {}
                    for name in route._param_names:
                        val = match.group(name)
                        kwargs[name] = val
                        route_params[name] = val
                    _request_context._route_param_names = route._param_names
                    _request_context._route_params = route_params
                    if route.handler:
                        return route.handler(**kwargs)
                    return None
            elif route.path == path:
                _request_context._route_param_names = ()
                _request_context._route_params = {}
                if route.handler:
                    return route.handler(**kwargs)
                return None
        if path_exists:
            return {"_type": "Response", "status": 405, "body": {"error": "Method Not Allowed"}}
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

    def _error_handler_result(self, status: int) -> Any:
        if hasattr(self.__class__, "error_handlers"):
            handler = self.__class__.error_handlers.get(status)
            if handler:
                return handler(status=status, path=self.path, method=self._get_method())
        return None

    def _get_method(self) -> str:
        return "GET"

    def _set_context(self, method: str, path_part: str) -> None:
        _request_context.method = method
        _request_context.path = path_part
        _request_context.headers = dict(self.headers)
        _request_context._route_param_names = ()

    def _try_dispatch(self, method: str, **kwargs: Any) -> Any:
        path_part, qparams = self._parse_path(self.path)
        self._set_context(method, path_part)
        merged = {**dict(qparams), **kwargs}
        result = self.router.dispatch(method, path_part, **merged)
        if result is not None:
            return result
        # Try error handler before returning 404
        err_result = self._error_handler_result(404)
        if err_result is not None:
            return err_result
        return None

    def do_GET(self) -> None:
        result = self._try_dispatch("GET")
        self._send_response(result)

    def do_POST(self) -> None:
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b""
        result = self._try_dispatch("POST", body=body)
        self._send_response(result)

    def do_PUT(self) -> None:
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b""
        result = self._try_dispatch("PUT", body=body)
        self._send_response(result)

    def do_DELETE(self) -> None:
        result = self._try_dispatch("DELETE")
        self._send_response(result)

    def _send_response(self, result: Any) -> None:
        if result is None:
            self.send_response(404)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.end_headers()
            self.wfile.write(json.dumps({"error": "Not found"}).encode("utf-8"))
            return

        status = 200
        response_headers: dict[str, str] = {}
        content_type = "text/plain; charset=utf-8"
        body = b""

        # Handle Response objects: {"_type": "Response", "status": ..., "headers": ..., "body": ...}
        if isinstance(result, dict) and result.get("_type") == "Response":
            status = int(result.get("status", 200))
            resp_headers = result.get("headers", {})
            if isinstance(resp_headers, dict):
                for k, v in resp_headers.items():
                    if k.lower() != "content-type":
                        response_headers[k] = str(v)
                    else:
                        content_type = str(v)
            body_raw = result.get("body", "")
            body = body_raw.encode("utf-8") if isinstance(body_raw, str) else json.dumps(body_raw).encode("utf-8")
        elif isinstance(result, dict):
            if "status" in result and "error" in result:
                # Error format: {status: 4xx, error: "message"}
                try:
                    status = int(result["status"])
                except (ValueError, TypeError):
                    status = 500
                body = json.dumps({"error": result["error"]}).encode("utf-8")
                content_type = "application/json; charset=utf-8"
            elif "status" in result and isinstance(result.get("status"), (int, str)) and str(result["status"]).isdigit():
                status = int(result["status"])
                body = json.dumps(result).encode("utf-8")
                content_type = "application/json; charset=utf-8"
            elif "redirect" in result:
                status = 302
                body = b""
                content_type = "text/plain; charset=utf-8"
                response_headers["Location"] = result["redirect"]
            else:
                body = json.dumps(result).encode("utf-8")
                content_type = "application/json; charset=utf-8"
        elif isinstance(result, str):
            lowered = result.lstrip().lower()
            if lowered.startswith("<html") or "<body" in lowered or lowered.startswith("<!doctype"):
                content_type = "text/html; charset=utf-8"
            else:
                content_type = "text/plain; charset=utf-8"
            body = result.encode("utf-8")
        elif isinstance(result, bytes):
            # Raw bytes response
            body = result
            content_type = "application/octet-stream"
        else:
            # Try to encode as default
            try:
                body = str(result).encode("utf-8")
            except Exception:
                body = b""
            content_type = "text/plain; charset=utf-8"

        self.send_response(status)
        self.send_header("Content-Type", content_type)
        for k, v in response_headers.items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: Any) -> None:
        if hasattr(self, "logging_enabled") and self.logging_enabled:
            import sys
            sys.stderr.write(f"[Panther] {args[0]} {args[1]} {args[2]}\n")


class HttpServer:
    def __init__(self, host: str = "0.0.0.0", port: int = 8080) -> None:
        self.host = host
        self._requested_port = port
        self.port = port
        self.router = Router()
        self._server: HTTPServer | None = None
        self._started = threading.Event()
        self._stopped = threading.Event()
        self._fatal_error: Exception | None = None
        self.logging = False
        self.error_handlers: dict[int, Callable[..., Any]] = {}

    def set_error_handler(self, status: int, handler: Callable[..., Any]) -> None:
        self.error_handlers[int(status)] = handler

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

    def start(self, enable_logging: bool = False) -> None:
        PantherHTTPRequestHandler.router = self.router
        PantherHTTPRequestHandler.error_handlers = self.error_handlers
        try:
            class ReusableHTTPServer(HTTPServer):
                allow_reuse_address = True
            self._server = ReusableHTTPServer((self.host, self._requested_port), PantherHTTPRequestHandler)
        except OSError as e:
            self._fatal_error = e
            self._started.set()
            self._stopped.set()
            return
        if self._requested_port == 0:
            self.port = self._server.server_address[1]
        PantherHTTPRequestHandler.logging_enabled = enable_logging or self.logging
        self._started.set()
        self._stopped.clear()
        try:
            self._server.serve_forever()
        finally:
            self._stopped.set()

    def start_background(self, enable_logging: bool = False) -> threading.Thread:
        thread = threading.Thread(
            target=self.start,
            args=(enable_logging,),
            daemon=True,
            name=f"panther-web-{self.host}:{self._requested_port}",
        )
        thread.start()
        self._started.wait(timeout=5.0)
        if self._fatal_error:
            self._stopped.set()
        return thread

    def wait(self, timeout: float | None = None) -> None:
        self._stopped.wait(timeout=timeout)

    def is_ready(self, timeout_ms: int = 3000) -> bool:
        ready = self._started.wait(timeout=timeout_ms / 1000.0)
        if self._fatal_error:
            return False
        return ready and self._server is not None

    def stop(self) -> None:
        if self._server:
            try:
                self._server.shutdown()
                self._server.server_close()
            except Exception:
                pass
            self._server = None


def run_web(host: str = "0.0.0.0", port: int = 8080) -> HttpServer:
    server = HttpServer(host=host, port=port)
    return server
