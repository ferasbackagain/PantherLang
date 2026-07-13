# WEB ENGINE ROOT CAUSE ANALYSIS

## Root Cause Chain

### Primary: `execute_source()` never creates an HttpServer

**File:** `compiler/runtime/execution_pipeline.py`, lines 26-52

The `execute_source` function processes all AST blocks sequentially. It creates a
`StatementExecutor` with no `http_server` parameter. When it encounters a
`WebBlockNode` or `ApiBlockNode`, the `route` statements are processed by
`_execute_route()` which checks `if self._http_server:` — since `http_server` is
`None`, routes are registered as environment functions but _no actual routing_
_configuration occurs_. No socket is ever allocated.

### Secondary: `_execute_route` is a no-op without http_server

**File:** `compiler/runtime/statement_executor.py`, lines 455-461

```python
def _execute_route(self, stmt: RouteStatement) -> None:
    if self._http_server:
        handler = lambda **kwargs: self._execute_route_handler(stmt, kwargs)
        self._http_server.router.add_route(stmt.method, stmt.path, handler)
    route_name = f"__route_{stmt.method}:{stmt.path}"
    self._env.define_function(route_name, lambda **kwargs: ...)
```

Without `self._http_server`, the route registration is purely cosmetic — it
defines a function name in the environment but never wires it to any HTTP
listener.

### Tertiary: CLI has no web-block auto-detection

**File:** `cli/panther_cli.py`, lines 162-167

```python
if serve_mode:
    from compiler.runtime.execution_pipeline import serve_source
    result = serve_source(source_text)
else:
    from compiler.runtime import execute_source
    result = execute_source(source_text)
```

`panther run` (without `--serve`) unconditionally calls `execute_source()`,
which has no server logic. `serve_source()` (which does create HttpServer) is
only called when `--serve` is explicitly passed.

### Contributing: Demo file prints URL but never starts server

**File:** `panther_web_demo.pan`, lines 1-9

The `panther main {}` block only contains `print()` statements claiming a server
is running. No server creation, start, or lifecycle function is called. The
program exits immediately after printing.

### Process Model: No background server + no main-thread blocking

`execute_source` returns immediately after processing all blocks. The process
exits with code 0. Any daemon thread that might have been started (if a server
were created) would be killed by process exit.

## Affected Files Summary

| File | Lines | Issue |
|------|-------|-------|
| `execution_pipeline.py` | 26-52 | No HttpServer creation for web blocks |
| `statement_executor.py` | 455-461 | Route registration gated on http_server presence |
| `cli/panther_cli.py` | 162-167 | No auto-detection; --serve required |
| `panther_web_demo.pan` | 1-9 | Misleading print statements, no actual server call |

## Fix Applied

1. Added `start_background()`, `wait()`, `is_ready()` to `HttpServer` (`server.py`)
2. Added `run_source()` function that starts server and blocks (`execution_pipeline.py`)
3. CLI auto-detects `web {}`/`api {}` blocks and uses `run_source` (`panther_cli.py`)
4. Rewrote `panther_web_demo.pan` with proper routes, no fake print statements
