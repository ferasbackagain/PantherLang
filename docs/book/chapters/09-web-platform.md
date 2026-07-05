# Chapter 9: Web Platform

PantherLang includes a full HTTP server with routing, web blocks, and API blocks.

## Running a Web Server

Use `panther run --serve` to start an HTTP server from `.pan` files:

```bash
panther run --serve examples/hello_web/main.pan
```

## Web Block

The `web {}` top-level block contains route declarations. Routes inside `web {}`
serve HTML pages:

```panther
panther main {
    print "Starting web server...";
}

web {
    route GET "/" {
        return "<html><body><h1>Hello, PantherLang!</h1></body></html>";
    }
    route GET "/about" {
        return "<html><body><h1>About</h1></body></html>";
    }
}
```

## API Block

The `api {}` top-level block is identical to `web {}` in structure. Routes return
JSON automatically when handlers return objects:

```panther
api {
    route GET "/api" {
        return { message: "Hello", version: "1.0" };
    }
    route POST "/api/data" {
        return { ok: true };
    }
}
```

## Route Methods

| Method | Support | Notes |
|--------|---------|-------|
| GET | Supported | Body not read |
| POST | Supported | Body passed as `body` parameter |
| PUT | Supported | Body passed as `body` parameter |
| DELETE | Supported | Body not read |

## Route Path Parameters

Use `{name}` syntax for dynamic path segments:

```panther
route GET "/users/{id}" {
    return { user_id: id };
}
```

## Query Parameters

Query string parameters are automatically available as variables in route
handlers:

```panther
route GET "/search" {
    return { query: q, page: page };
}
```

Request to `GET /search?q=panther&page=2` makes `q` and `page` available.

## Response Types

| Handler return type | Content-Type | Status |
|--------------------|--------------|--------|
| `dict` or `list` | `application/json` | 200 |
| `str` starting with `<html` or containing `<body` | `text/html` | 200 |
| `str` (other) | `text/plain` | 200 |
| `None` (no matching route) | `application/json` | 404 |

## Security Middleware (Python API)

Available but not yet wired into the main server pipeline:

```python
from compiler.web.security import (
    SecurityHeaders,
    CSRFProtection,
    RateLimiter,
    CORSValidator,
    SecureRequestHandler,
)
```
