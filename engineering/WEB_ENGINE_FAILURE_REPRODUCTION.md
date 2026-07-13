# WEB ENGINE FAILURE REPRODUCTION

**Date:** 2026-07-13
**Project:** PantherLang v1.1.9
**Demo File:** `panther_web_demo.pan`

## Commands Executed

### 1. panther version
```
PantherLang 1.1.9 (PantherLang v1.1.9)
Channel: stable
Debug Adapter: 1.1.9
```

### 2. panther doctor
```
PantherLang v1.1.9 — All OK
```

### 3. panther check panther_web_demo.pan
```
check passed: panther_web_demo.pan
EXIT: 0
```

### 4. panther run panther_web_demo.pan
```
============================================================
 PantherLang v1.1.8 Web Application
============================================================
Server URL : http://127.0.0.1:8080
Routes     : GET /, GET /about, GET /api/status
Runtime    : PantherLang Web/API
============================================================
EXIT: 0
```

### 5. ss -ltnp | grep ':8080'
```
NO LISTENER ON 8080
```

### 6. curl -v http://127.0.0.1:8080/
```
HTTP CODE: 000
CONNECTION REFUSED
```

## Failure Summary

| Check | Expected | Actual | Verdict |
|-------|----------|--------|---------|
| `panther check` | Pass | Pass | OK |
| `panther run` | Server starts | Prints URL, exits | FAIL |
| `ss -ltnp :8080` | LISTEN | No output | FAIL |
| `curl :8080/` | HTTP 200 | Connection refused | FAIL |
| Firefox | Page loads | Cannot connect | FAIL |

## Conclusion

The web engine does not start a real server. The `panther run` command exits immediately after executing the `panther main {}` block, which only contains `print()` statements. No `HttpServer` is created, no socket is allocated, no accept loop runs.
