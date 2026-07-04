# Web Runtime Fix 4 — Contract Cleanup

Restores the intended contract:

- `web {}` and `api {}` blocks are route-definition blocks and stay silent during plain `execute_source()`.
- Human preview output belongs in `panther main {}` inside example programs.
- `--serve` remains the dedicated path for starting the HTTP server.
