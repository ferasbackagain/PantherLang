from compiler.web import HttpServer, Route, Router, run_web


def test_router_add_and_dispatch():
    router = Router()
    router.add_route("GET", "/api/hello", lambda: {"msg": "hello"})
    result = router.dispatch("GET", "/api/hello")
    assert result == {"msg": "hello"}


def test_router_dispatch_not_found():
    router = Router()
    result = router.dispatch("GET", "/nonexistent")
    assert result is None


def test_router_dispatch_wrong_method():
    router = Router()
    router.add_route("GET", "/api/data", lambda: {"data": 42})
    result = router.dispatch("POST", "/api/data")
    assert result is not None
    if isinstance(result, dict):
        assert result.get("status") == 405 or result.get("_type") == "Response"


def test_router_case_insensitive_method():
    router = Router()
    router.add_route("get", "/api/items", lambda: {"items": []})
    result = router.dispatch("GET", "/api/items")
    assert result == {"items": []}


def test_router_multiple_routes():
    router = Router()
    router.add_route("GET", "/a", lambda: {"route": "a"})
    router.add_route("POST", "/b", lambda: {"route": "b"})
    assert router.dispatch("GET", "/a") == {"route": "a"}
    assert router.dispatch("POST", "/b") == {"route": "b"}
    result = router.dispatch("GET", "/b")
    assert result is not None
    if isinstance(result, dict):
        assert result.get("status") == 405 or result.get("_type") == "Response"


def test_router_routes_property():
    router = Router()
    r1 = router.add_route("GET", "/x", lambda: 1)
    r2 = router.add_route("POST", "/y", lambda: 2)
    assert len(router.routes) == 2


def test_route_dataclass():
    route = Route(method="GET", path="/test")
    assert route.method == "GET"
    assert route.path == "/test"
    assert route.handler is None


def test_http_server_create():
    server = HttpServer(host="127.0.0.1", port=9090)
    assert server.host == "127.0.0.1"
    assert server.port == 9090
    assert server.router is not None


def test_http_server_decorator_get():
    server = HttpServer()
    @server.get("/hello")
    def handler():
        return {"msg": "hello"}
    assert len(server.router.routes) == 1
    route = server.router.routes[0]
    assert route.method == "GET"
    assert route.path == "/hello"


def test_http_server_decorator_post():
    server = HttpServer()
    @server.post("/data")
    def handler():
        return {"status": "created"}
    route = server.router.routes[0]
    assert route.method == "POST"
    assert route.path == "/data"


def test_http_server_decorator_put():
    server = HttpServer()
    @server.put("/update")
    def handler():
        return {"status": "updated"}
    route = server.router.routes[0]
    assert route.method == "PUT"


def test_http_server_decorator_delete():
    server = HttpServer()
    @server.delete("/remove")
    def handler():
        return {"status": "deleted"}
    route = server.router.routes[0]
    assert route.method == "DELETE"


def test_run_web_factory():
    server = run_web(host="127.0.0.1", port=9091)
    assert isinstance(server, HttpServer)
    assert server.host == "127.0.0.1"
    assert server.port == 9091


def test_router_dispatch_with_kwargs():
    router = Router()
    router.add_route("POST", "/echo", lambda body: {"echo": body.decode() if isinstance(body, bytes) else str(body)})
    result = router.dispatch("POST", "/echo", body=b"test")
    assert result["echo"] == "test"


def test_router_routes_immutable():
    router = Router()
    router.add_route("GET", "/a", lambda: 1)
    routes_copy = router.routes
    assert len(routes_copy) == 1
    routes_copy.clear()
    assert len(router.routes) == 1
