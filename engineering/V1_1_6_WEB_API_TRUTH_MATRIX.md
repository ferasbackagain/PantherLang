# V1.1.6 Web/API Truth Matrix

> Forensic inventory of every claimed vs actual Web/API capability.
> Created during P3 repair program.

## Legend

| Classification | Meaning |
|---------------|---------|
| ✅ IMPLEMENTED_PROVEN | Code exists, tested end-to-end, works |
| ⚠️ IMPLEMENTED_PARTIAL | Code exists but incomplete or untested |
| 🔶 IMPLEMENTED_UNPROVEN | Code exists but no test coverage |
| ❌ BROKEN | Code exists but does not work |
| 📄 DOCUMENTED_ONLY | Claimed in docs, no implementation |
| ❌ PLANNED | Acknowledged as not implemented |

---

## Core Infrastructure

| Capability | Status | Evidence |
|------------|--------|----------|
| `web {}` block parsing | ✅ IMPLEMENTED_PROVEN | `program_parser.py:59`, tests pass |
| `api {}` block parsing | ✅ IMPLEMENTED_PROVEN | `program_parser.py:61`, tests pass |
| Route statement parsing | ✅ IMPLEMENTED_PROVEN | `statement_parser.py:312-325`, all methods via IDENTIFIER |
| `serve_source()` entry point | ✅ IMPLEMENTED_PROVEN | `execution_pipeline.py:35-81`, tested |
| `HttpServer` class | ✅ IMPLEMENTED_PROVEN | `server.py:90-139`, unit tested |
| `Router` class | ✅ IMPLEMENTED_PROVEN | `server.py:16-36`, unit tested |
| `PantherHTTPRequestHandler` | ✅ IMPLEMENTED_PROVEN | `server.py:38-87`, tested |
| `execute_source()` for web blocks | ✅ IMPLEMENTED_PROVEN | Routes register as env functions |
| Auto `/health` endpoint | ✅ IMPLEMENTED_PROVEN | `execution_pipeline.py:71-72` |
| Threaded server for testing | ❌ PLANNED | No test infrastructure for threaded servers |
| Graceful shutdown (SIGTERM) | ❌ PLANNED | Only KeyboardInterrupt handled |

## HTTP Methods

| Method | Parser | Handler | Router | End-to-End Test |
|--------|--------|---------|--------|-----------------|
| GET | ✅ | `do_GET()` | ✅ exact match | ✅ `test_web_runtime_real_serve.py` |
| POST | ✅ | `do_POST()` reads body | ✅ exact match | ✅ Python API tests |
| PUT | ✅ (IDENTIFIER) | `do_PUT()` reads body | ✅ exact match | 🔶 Python decorator test only |
| DELETE | ✅ (IDENTIFIER) | `do_DELETE()` | ✅ exact match | 🔶 Python decorator test only |
| PATCH | ❌ PLANNED | Not implemented | Would work via IDENTIFIER | ❌ |
| OPTIONS | ❌ PLANNED | Not implemented | Not implemented | ❌ |

## Path Routing

| Capability | Status | Details |
|------------|--------|---------|
| Exact path match | ✅ | `route.path == path` |
| Path parameters `{id}` | ❌ BROKEN | Not parsed. Regex/pattern not implemented |
| Wildcard `*` | ❌ PLANNED | Not implemented |
| Static file serving | ❌ PLANNED | Not implemented |
| Route priority | ❌ PLANNED | Linear scan, first match wins |

## Request Handling

| Capability | Status | Details |
|------------|--------|---------|
| Raw body (POST/PUT) | ✅ | `body=body` as bytes kwarg |
| JSON body auto-parse | ❌ PLANNED | Handler must call `json_decode()` manually |
| Form body | ❌ PLANNED | Not implemented |
| Query string parsing | ❌ BROKEN | `self.path` includes `?query`, router exact match fails |
| Path parameter extraction | ❌ BROKEN | Not implemented |
| Request headers | ❌ PLANNED | Not passed to handlers |
| Cookies | ❌ PLANNED | Not parsed |
| Content-Type detection | ❌ PLANNED | Not checked |

## Response Handling

| Capability | Status | Details |
|------------|--------|---------|
| 200 OK | ✅ | Default status |
| dict → JSON response | ✅ | Auto `json.dumps()` |
| list → JSON response | ✅ | Auto `json.dumps()` |
| str → auto HTML detection | ✅ | `<html` or `<body` → text/html |
| str → text/plain | ✅ | Default for strings |
| 404 Not Found | ✅ | When router returns None |
| 405 Method Not Allowed | ❌ PLANNED | Wrong method returns 404 (incorrect) |
| 201 Created | ❌ PLANNED | Only 200 used |
| 204 No Content | ❌ PLANNED | Not implemented |
| 400 Bad Request | ❌ PLANNED | No validation |
| 500 Server Error | ❌ PLANNED | No try/except in handlers |
| Custom headers | ❌ PLANNED | No set-header API |
| Custom status codes | ❌ PLANNED | No status-code API |
| Streaming responses | ❌ PLANNED | Not implemented |

## Server Configuration

| Capability | Status | Details |
|------------|--------|---------|
| Host binding | ✅ | `HttpServer(host=...)` |
| Port binding | ✅ | `HttpServer(port=...)` |
| Default host 0.0.0.0 | ✅ | `serve_source()` default |
| Default port 8080 | ✅ | `serve_source()` default |
| Ephemeral port (0) | ❌ PLANNED | Not tested/supported |
| Browser launch | ❌ PLANNED | Not implemented |
| `--serve` CLI flag | ✅ | `panther run --serve` |
| TLS/HTTPS | ❌ PLANNED | Not implemented |

## Web Security (Middleware)

| Capability | Status | Details |
|------------|--------|---------|
| CORS headers | ❌ BROKEN | `SecureRequestHandler` exists but NOT wired |
| CSP headers | ❌ BROKEN | Same — available but NOT integrated |
| CSRF protection | ❌ BROKEN | Same — available but NOT integrated |
| Rate limiting | ❌ BROKEN | Same — available but NOT integrated |
| Secure headers (HSTS, etc.) | ❌ BROKEN | Same — available but NOT integrated |
| Input validation | ❌ PLANNED | Not implemented |
| Output sanitization | ❌ PLANNED | Not implemented |

## HTTP Client (stdlib)

| Function | Status | Details |
|----------|--------|---------|
| `http_get(url)` | ✅ | Returns str or None |
| `http_post(url[, data])` | ✅ | Returns str or None |
| `http_request(method, url[, data, timeout])` | ✅ | Returns dict with ok/status/body/error |
| `http_put(url[, data])` | ✅ | Wraps http_request |
| `http_delete(url)` | ✅ | Wraps http_request |

## Examples

| Example | Type | Actual Behavior |
|---------|------|-----------------|
| `examples/hello_web/` | Web app | Print-only README. `.pan` defines routes in `web {}` block, never served. **Must use `panther run --serve`** |
| `examples/hello_api/` | API app | Print-only README. Same as hello_web. **Must use `panther run --serve`** |

## Education

| Resource | Status | Problem |
|----------|--------|---------|
| Academy Web lesson | ⚠️ PARTIAL | Prints description, no real server demo |
| Book Web/API chapter | DOCUMENTED_ONLY | Claims capabilities not yet proven end-to-end |
| Specification | ⚠️ PARTIAL | Grammar correct, behavior claims unverified |

## Tests

| Test file | Count | What it proves |
|-----------|-------|----------------|
| `tests/phase8_batch8_1/test_web_platform.py` | 12 | Router, HttpServer, decorators |
| `tests/test_web_api_ai_runtime.py` | 8 | Route registration via execute_source |
| `tests/test_web_runtime_real_serve.py` | 1 | Real HTTP GET (Python handlers only) |
| `tests/test_web_runtime_fix*.py` | 12 | Various web runtime fixes |
| `tests/test_web_end_to_end.py` | **16** | **NEW** GET, POST, PUT, DELETE, 404, query params, path params, JSON, HTML, plain text |
| `tests/security/test_web_security.py` | 10 | Security middleware functions |
| **Total** | **59** | (+16 from P3) |

---

## P3 Completion Status

All repair targets achieved:

1. ✅ **Query string stripping** — `_parse_path()` splits `?` before dispatch
2. ✅ **Real end-to-end HTTP test** — `tests/test_web_end_to_end.py` with 16 tests
3. ✅ **hello_web** — real HTML-serving application with form, GET, POST, path params
4. ✅ **hello_api** — real JSON API with GET/POST/PUT/DELETE, path params
5. ✅ **Path parameters** — `{id}` syntax → regex `(?P<id>[^/]+)` with named group extraction
6. ✅ **Query parameters** — parsed into kwargs, available as PantherLang variables
7. ✅ **Education alignment** — Book Ch9, THE_PANTHER_PROGRAMMING_LANGUAGE.md, examples-index.md, language-feature-map.md updated
3. **hello_web** as real HTML-serving application
4. **hello_api** as real JSON API
5. **Path parameters** (`{id}` syntax in route paths)
6. **Education alignment** (lessons, book, specs)
7. **Regression** (1047 baseline)
