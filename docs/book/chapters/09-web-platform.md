# Chapter 9: Web Platform

PantherLang includes a full HTTP server with routing and security middleware.

## HTTP Server (Python API)

```python
from compiler.web.server import HttpServer

server = HttpServer(host="0.0.0.0", port=8080)
server.get("/", lambda req: {"message": "Hello, Panther!"})
server.post("/data", lambda req: {"received": req.body})
server.start()
```

## Route Registration

```python
server.route("GET", "/users", handler)
server.get("/users", handler)
server.post("/users", create_handler)
server.put("/users/1", update_handler)
server.delete("/users/1", delete_handler)
```

## Route Syntax in .pan Files

Route statements can appear in programs:

```panther
route GET "/" {
    return "{ status: ok }";
}
route POST "/api/data" {
    return "{ received: true }";
}
```

## Security Middleware

```python
from compiler.web.security import (
    SecurityHeaders,
    CSRFProtection,
    RateLimiter,
    CORSValidator,
    SecureRequestHandler,
)
```

The `SecureRequestHandler` combines rate limiting, CORS, security headers, CSRF, and XSS sanitization.
