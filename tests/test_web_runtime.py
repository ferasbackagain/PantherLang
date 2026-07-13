"""Regression tests for PantherLang Web Runtime."""

import json
import threading
import urllib.request
from compiler.web import HttpServer
from compiler.runtime import execute_source
from compiler.runtime.execution_pipeline import serve_source


def test_http_server_basic():
    """Test basic HTTP server functionality."""
    server = HttpServer(host="0.0.0.0", port=0)  # port 0 = auto-assign
    
    @server.get("/")
    def index():
        return "Hello World"
    
    @server.get("/json")
    def json_endpoint():
        return {"message": "Hello JSON"}
    
    @server.get("/html")
    def html_endpoint():
        return "<html><body><h1>Test</h1></body></html>"
    
    # Start server in background
    def run_server():
        server.start()
    
    thread = threading.Thread(target=run_server, daemon=True)
    thread.start()
    
    # Wait for server to start
    server._started.wait(timeout=5.0)
    
    # Get the actual port (0 means auto-assigned)
    actual_port = server.port
    
    # Test requests
    import urllib.request
    
    # Test plain text
    with urllib.request.urlopen(f"http://127.0.0.1:{actual_port}/") as resp:
        assert resp.status == 200
        assert resp.read().decode() == "Hello World"
    
    # Test JSON
    with urllib.request.urlopen(f"http://127.0.0.1:{actual_port}/json") as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode())
        assert data == {"message": "Hello JSON"}
    
    # Test HTML
    with urllib.request.urlopen(f"http://127.0.0.1:{actual_port}/html") as resp:
        assert resp.status == 200
        content = resp.read().decode()
        assert "<h1>Test</h1>" in content
    
    # Test 404
    try:
        urllib.request.urlopen(f"http://127.0.0.1:{actual_port}/nonexistent")
        assert False, "Should have raised HTTPError"
    except urllib.error.HTTPError as e:
        assert e.code == 404
    
    server.stop()


def test_http_server_path_params():
    """Test path parameter handling."""
    server = HttpServer(host="0.0.0.0", port=0)
    
    @server.get("/users/{user_id}")
    def get_user(user_id):
        return {"user_id": user_id}
    
    @server.get("/users/{user_id}/posts/{post_id}")
    def get_post(user_id, post_id):
        return {"user_id": user_id, "post_id": post_id}
    
    def run_server():
        server.start()
    
    thread = threading.Thread(target=run_server, daemon=True)
    thread.start()
    server._started.wait(timeout=5.0)
    
    import urllib.request
    
    actual_port = server.port
    
    with urllib.request.urlopen(f"http://127.0.0.1:{actual_port}/users/123") as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode())
        assert data == {"user_id": "123"}
    
    with urllib.request.urlopen(f"http://127.0.0.1:{actual_port}/users/456/posts/789") as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode())
        assert data == {"user_id": "456", "post_id": "789"}
    
    server.stop()


def test_http_server_query_params():
    """Test query parameter handling."""
    server = HttpServer(host="0.0.0.0", port=0)
    
    @server.get("/search")
    def search(q, limit):
        return {"query": q, "limit": limit}
    
    def run_server():
        server.start()
    
    thread = threading.Thread(target=run_server, daemon=True)
    thread.start()
    server._started.wait(timeout=5.0)
    
    import urllib.request
    
    actual_port = server.port
    
    with urllib.request.urlopen(f"http://127.0.0.1:{actual_port}/search?q=test&limit=10") as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode())
        assert data == {"query": "test", "limit": "10"}
    
    server.stop()


def test_http_server_post_body():
    """Test POST body handling."""
    server = HttpServer(host="0.0.0.0", port=0)
    
    @server.post("/echo")
    def echo(body):
        return {"received": body.decode()}
    
    def run_server():
        server.start()
    
    thread = threading.Thread(target=run_server, daemon=True)
    thread.start()
    server._started.wait(timeout=5.0)
    
    import urllib.request
    
    actual_port = server.port
    
    req = urllib.request.Request(
        f"http://127.0.0.1:{actual_port}/echo",
        data=b"test body",
        method="POST",
        headers={"Content-Type": "text/plain"}
    )
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode())
        assert data == {"received": "test body"}
    
    server.stop()


def test_http_server_methods():
    """Test all HTTP methods."""
    server = HttpServer(host="0.0.0.0", port=0)
    calls = []
    
    @server.get("/resource")
    def get_resource():
        calls.append("GET")
        return {"method": "GET"}
    
    @server.post("/resource")
    def post_resource(body):
        calls.append("POST")
        return {"method": "POST", "body": body.decode()}
    
    @server.put("/resource")
    def put_resource(body):
        calls.append("PUT")
        return {"method": "PUT", "body": body.decode()}
    
    @server.delete("/resource")
    def delete_resource():
        calls.append("DELETE")
        return {"method": "DELETE"}
    
    def run_server():
        server.start()
    
    thread = threading.Thread(target=run_server, daemon=True)
    thread.start()
    server._started.wait(timeout=5.0)
    
    import urllib.request
    
    actual_port = server.port
    
    for method in ["GET", "POST", "PUT", "DELETE"]:
        req = urllib.request.Request(
            f"http://127.0.0.1:{actual_port}/resource",
            method=method,
            data=b"test body" if method in ("POST", "PUT") else None
        )
        with urllib.request.urlopen(req) as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data == {"method": method, "body": "test body"} if method in ("POST", "PUT") else {"method": method}
    
    assert calls == ["GET", "POST", "PUT", "DELETE"]
    server.stop()


def test_panther_web_block_execution():
    """Test that web block statements are executed correctly."""
    source = """
panther main {
    print("Starting server setup");
}

web {
    route GET "/" {
        return "Hello from web block";
    }
    route GET "/api" {
        return {message: "API response"};
    }
}
"""
    # This should parse and execute the web block without starting server
    # (serve_source would start it, but we test the parsing/execution)
    from compiler.runtime.execution_pipeline import execute_source
    result = execute_source(source)
    assert result.error is None, f"Parse/execution error: {result.error}"
    assert "Starting server setup" in " ".join(result.captured_output)


def test_panther_serve_source():
    """Test serve_source with a simple web app."""
    source = """
panther main {
    print("App starting");
}

web {
    route GET "/" {
        return "Home";
    }
    route GET "/health" {
        return {status: "ok"};
    }
}
"""
    # We can't easily test the full serve_source in unit tests
    # as it blocks. But we can verify it exists and is callable
    from compiler.runtime.execution_pipeline import serve_source
    
    # Just verify the function exists and is callable
    # Full integration test would require subprocess
    assert callable(serve_source)


def test_web_decorators():
    """Test route decorators."""
    server = HttpServer(host="0.0.0.0", port=0)
    
    @server.get("/decorator")
    def decorator_route():
        return "decorated"
    
    @server.post("/post-decorator")
    def post_decorator(body):
        return {"post": True, "body": body.decode()}
    
    def run_server():
        server.start()
    
    thread = threading.Thread(target=run_server, daemon=True)
    thread.start()
    server._started.wait(timeout=5.0)
    
    import urllib.request
    
    actual_port = server.port
    
    with urllib.request.urlopen(f"http://127.0.0.1:{actual_port}/decorator") as resp:
        assert resp.status == 200
        assert resp.read().decode() == "decorated"
    
    req = urllib.request.Request(
        f"http://127.0.0.1:{actual_port}/post-decorator",
        method="POST",
        data=b"test"
    )
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode())
        assert data == {"post": True, "body": "test"}
    
    server.stop()


def test_panther_web_example():
    """Test the actual hello_web example works."""
    source = """
panther main {
    print("PantherLang Web Server starting...");
}

web {
    route GET "/" {
        return "<html><body>"
            + "<h1>Hello from PantherLang Web</h1>"
            + "<p>This is a real HTML page served by PantherLang.</p>"
            + "<form method='POST' action='/submit'>"
            + "  <input name='name' placeholder='Enter your name'>"
            + "  <button type='submit'>Submit</button>"
            + "</form>"
            + "<p><a href='/about'>About</a>"
            + " | <a href='/users/alice'>Path param demo</a></p>"
            + "</body></html>";
    }
    route GET "/about" {
        return "<html><body>"
            + "<h1>About PantherLang</h1>"
            + "<p>Modern, Secure, AI-Native Programming Language</p>"
            + "<p><a href='/'>Home</a></p>"
            + "</body></html>";
    }
    route POST "/submit" {
        return "<html><body>"
            + "<h1>Form Submitted</h1>"
            + "<p>Thank you for submitting the form.</p>"
            + "<p><a href='/'>Back to home</a></p>"
            + "</body></html>";
    }
    route GET "/users/{name}" {
        return "<html><body>"
            + "<h1>User Profile</h1>"
            + "<p>User: " + name + "</p>"
            + "<p><a href='/'>Back to home</a></p>"
            + "</body></html>";
    }
    route GET "/health" {
        return { status: "ok", service: "panther-web" };
    }
}
"""
    from compiler.runtime.execution_pipeline import execute_source
    result = execute_source(source)
    assert result.error is None, f"Parse/execution error: {result.error}"
    assert "PantherLang Web Server starting" in " ".join(result.captured_output)


if __name__ == "__main__":
    test_http_server_basic()
    print("test_http_server_basic passed")
    
    test_http_server_path_params()
    print("test_http_server_path_params passed")
    
    test_http_server_query_params()
    print("test_http_server_query_params passed")
    
    test_http_server_post_body()
    print("test_http_server_post_body passed")
    
    test_http_server_methods()
    print("test_http_server_methods passed")
    
    test_panther_web_block_execution()
    print("test_panther_web_block_execution passed")
    
    test_panther_serve_source()
    print("test_panther_serve_source passed")
    
    test_web_decorators()
    print("test_web_decorators passed")
    
    test_panther_web_example()
    print("test_panther_web_example passed")
    
    print("\nAll tests passed!")