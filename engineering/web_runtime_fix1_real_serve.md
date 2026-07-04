# PantherLang Web Runtime Fix 1 — Real --serve HTTP Server

## Goal
Make `panther run <web/api file> --serve` start a real blocking HTTP server for actual `web {}` and `api {}` route blocks.

## Changes
- `examples/hello_web/main.pan` now uses a real `web { route ... }` block.
- `examples/hello_api/main.pan` now uses a real `api { route ... }` block.
- `compiler/web/server.py` now returns appropriate content types for HTML, JSON, and text responses.
- `compiler/runtime/execution_pipeline.py` adds a safe default `/health` route when absent and handles Ctrl+C cleanly.
- Added live HTTP server tests with dynamic port binding.

## Manual verification
Run:

```bash
panther run examples/hello_web/main.pan --serve
```

Then in another terminal:

```bash
curl http://localhost:8080
curl http://localhost:8080/health
```

For API:

```bash
panther run examples/hello_api/main.pan --serve
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/api
```

## Expected result
- Server stays running until Ctrl+C.
- `/` returns HTML for web example.
- `/health` returns JSON.
- API routes return JSON.
