# PantherLang Engineering Report

Phase: Release Validation
Batch: Web Runtime Fix 1
Part: AST Export Repair
Title: Restore compiler.ast statement exports
Status: READY

## Root cause
The runtime imports `BreakStatement`, `ContinueStatement`, and other statement nodes from `compiler.ast`. The local `compiler/ast/__init__.py` was missing one or more required exports, causing pytest collection to fail before web runtime tests could run.

## Fix
Restore the canonical `compiler.ast` public exports, including statement nodes, program nodes, expression nodes, literals, visitor, and serializer.

## Validation
Targeted command:

```bash
python -m pytest tests/test_web_api_ai_runtime.py -q
```

Expected: collection succeeds and tests run.

## Next
After this patch passes, rerun Web Runtime Fix 1 server checks:

```bash
panther run examples/hello_web/main.pan --serve
curl http://localhost:8080
curl http://localhost:8080/health
```
