# WEB ENGINE ARCHITECTURE

## Server Lifecycle

```
┌──────────────────────────────────────────────────────────┐
│  panther run panther_web_demo.pan                        │
├──────────────────────────────────────────────────────────┤
│  1. CLI reads source text                                │
│  2. Detects "web {" in source → uses run_source()        │
│  3. execute_source() → parse → semantic check            │
│  4. Detects WebBlockNode → creates HttpServer            │
│     (host="127.0.0.1", port=8080)                        │
│  5. StatementExecutor created with http_server=server    │
│  6. Executes all blocks:                                 │
│     a. panther main {} → print statements (captured)     │
│     b. web {} → route statements register on server      │
│  7. Auto-adds /health route if missing                   │
│  8. run_source() → calls start_background()              │
│     → creates daemon thread → HTTPServer.serve_forever() │
│  9. run_source() → calls wait() → blocks on _stopped    │
│  10. Ctrl+C → stop() → shutdown() → server_close()      │
│  11. Port released, process exits                        │
└──────────────────────────────────────────────────────────┘
```

## Process Model

| Mode | Blocking? | Server Thread | Process Lifetime |
|------|-----------|---------------|------------------|
| `panther run` (no web block) | No | None | Exits after execution |
| `panther run` (with web block) | Yes (on `wait()`) | Background daemon | Alive until Ctrl+C |
| `panther run --serve` | Yes (foreground) | Main thread | Alive until Ctrl+C |

## HttpServer Class

```
HttpServer
├── host: str = "127.0.0.1" (default)
├── port: int = 8080
├── router: Router
│   ├── _routes: list[Route]
│   └── dispatch(method, path, **kwargs) → Any
├── _server: HTTPServer | None
├── _started: threading.Event
├── _stopped: threading.Event
├── start() → blocks forever (serve_forever)
├── start_background() → daemon thread, returns immediately
├── wait() → blocks until _stopped
├── is_ready(timeout_ms) → bool
├── stop() → shutdown + server_close
├── set_error_handler(status, handler)
└── logging: bool
```

## Route Dispatch

```
HTTP Request → PantherHTTPRequestHandler
  → _try_dispatch(method, **kwargs)
    → _parse_path() → (path_part, query_params)
    → Router.dispatch(method, path, **query_params)
      → Matches route by method + pattern
      → Extracts path params (/{name}/ → kwargs["name"])
      → Calls handler(**merged_kwargs)
    → _send_response(result)
      → Handles: str, dict, bytes, Response object
      → Sets Content-Type, status, headers
      → Returns proper HTTP response
```

## Data Flow: panther main → web block

1. Source: `panther main { ... } web { route GET "/" { ... } }`
2. Parser produces: `[BlockNode, WebBlockNode]`
3. `execute_source` creates `StatementExecutor(env, http_server=server)`
4. Executes BlockNode: `print` calls get captured
5. Executes WebBlockNode: `route` statements call `_execute_route`
6. `_execute_route`: `server.router.add_route("GET", "/", handler_func)`
7. `run_source` calls `server.start_background()` → daemon thread
8. Daemon thread: `HTTPServer.serve_forever()`
9. `run_source` calls `server.wait()` → blocks main thread
10. On HTTP request: handler function is called, result is sent back
