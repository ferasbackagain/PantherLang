# Phase 0 — Forensic Audit

## Objective
Full repository inspection to assess current state of every PantherLang package, engine, and runtime component.

## Key Findings

### Web Engine (`panther.web`, `compiler/web/`)
- **Real server exists**: `compiler/web/server.py` has `HttpServer` backed by Python `http.server.HTTPServer`
- **Web block syntax works**: `web { route GET "/" { ... } }` parsed and executed via `serve_source()` in `execution_pipeline.py`
- **Stdlib package is API_SHAPE_ONLY**: `stdlib/panther/web/__init__.pan` functions return dicts, do NOT start real servers
- **No Python backend for web package**: No `_web_*` functions registered in `compiler/stdlib/functions.py`

### HTTP Client (`panther.http`, `compiler/stdlib/functions.py`)
- **Real Python backend exists**: `http_get`, `http_post`, `http_request`, `http_put`, `http_delete` use `urllib.request`
- **Stdlib package works**: `stdlib/panther/http/__init__.pan` calls Python backend functions

### Async/Concurrency
- **Real Python backends exist**: `_concurrent_*` (threading.Thread, queue.Queue) and `_async_*` (ThreadPoolExecutor) registered
- **Stdlib packages work**: `stdlib/panther/concurrent/__init__.pan` and `stdlib/panther/async/__init__.pan` call Python backends

### AI Engine
- **Python backend exists with stubs**: `_ai_chat`, `_ai_provider`, `_ai_model` mostly return error dicts for real providers
- **Mock provider works**: `_ai_mock_chat` returns deterministic response
- **All external providers return simulated errors**: "not implemented"

### Database
- **Real SQLite backend**: `_db_open`, `_db_execute`, `_db_query`, etc. using `sqlite3`
- **Transactions work**: `_db_begin`, `_db_commit`, `_db_rollback`

### Process Engine
- **PARTIAL**: Current-process functions only (`self_pid`, `self_cwd`, `self_env`)
- **No subprocess execution**: `process.spawn`, `process.run` not implemented

### Cloud/Container
- **API_SHAPE_ONLY**: Data structures only, no real backend

### Other Packages
- core, math, text, net, crypto, json, time, collections, files, security, logging, system, testing, storage, serialization, cli all **VERIFIED_EXECUTABLE** with Python backends

## Architecture Summary
- **Formal pipeline**: Lexer → Parser → AST → Semantic → Type Check → Runtime (tree-walking interpreter)
- **Host ABI**: Python functions registered as stdlib, called from .pan code by name
- **Self-hosted stdlib**: .pan files loaded and injected into user source before execution

## Critical Gap
The `panther.web` stdlib package is API_SHAPE_ONLY — functions return placeholder dicts instead of starting a real HTTP server. The `web { route ... }` syntax works but the `panther.web.*` API does not.

## Classification
All packages classified truthfully in README maturity matrix.
