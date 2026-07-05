# PantherLang v1.1.6 — Capability Evidence Matrix

**Rule:** No capability claim without a corresponding test or executable proof.

---

## Language Core

| Capability | Evidence | Status |
|-----------|----------|--------|
| Variables (`let`) | `academy/lesson02/verify.pan` | ✅ |
| Type inference | `academy/lesson02/main.pan` | ✅ |
| Type annotations | `academy/lesson02/verify.pan` | ✅ |
| Arithmetic operators | `docs/cookbook/recipes/03-arithmetic.pan` | ✅ |
| Comparison operators | `docs/cookbook/recipes/17-comparisons.pan` | ✅ |
| Logical operators | `academy/lesson01/verify.pan` | ✅ |
| String concat (`+`) | `academy/lesson01/verify.pan` | ✅ |
| if/elif/else | `docs/cookbook/recipes/04-control-flow.pan` | ✅ |
| while loops | `docs/cookbook/recipes/04-control-flow.pan` | ✅ |
| for range loops | `docs/cookbook/recipes/04-control-flow.pan` | ✅ |
| loop/break/continue | `docs/cookbook/recipes/04-control-flow.pan` | ✅ |
| Functions (`fn`) | `docs/cookbook/recipes/05-functions.pan` | ✅ |
| Recursion | `docs/cookbook/recipes/05-functions.pan` | ✅ |
| Arrays | `docs/cookbook/recipes/06-arrays.pan` | ✅ |
| Objects/dicts | `docs/cookbook/recipes/07-objects.pan` | ✅ |
| Structs | `academy/lesson06/verify.pan` | ✅ |
| `panther main { }` | All `.pan` files | ✅ |
| `web { }` block | `docs/cookbook/recipes/19-web.pan` | ✅ |

## Standard Library (52 functions)

| Category | Count | Evidence |
|----------|-------|----------|
| String | 11 | `docs/cookbook/recipes/08-strings.pan` |
| Math | 10 | `docs/cookbook/recipes/12-math.pan` |
| JSON | 2 | `docs/cookbook/recipes/10-json.pan` |
| Time | 2 | `docs/cookbook/recipes/12-math.pan` |
| Type Conversion | 3 | `docs/cookbook/recipes/02-types.pan` |
| Crypto | 4 | `docs/cookbook/recipes/11-security.pan` |
| Security | 2 | `docs/cookbook/recipes/11-security.pan` |
| Filesystem | 6 | `docs/cookbook/recipes/09-filesystem.pan` |
| HTTP | 2 | `docs/cookbook/recipes/14-http.pan` |
| Regex | 3 | `docs/cookbook/recipes/13-regex.pan` |
| Collections | 4 | `docs/cookbook/recipes/15-collections.pan` |
| SQLite | 4 | `docs/cookbook/recipes/16-sqlite.pan` |

## Platforms

| Platform | Evidence | Status |
|----------|----------|--------|
| CLI | `python -m cli.panther_cli doctor` | ✅ |
| Web server | `examples/hello_web/main.pan` | ✅ |
| SQLite database | `examples/sqlite_crud/main.pan` | ✅ |
| AI providers | `examples/hello_ai/main.pan` | ⚠️ Mock mode only |
| Security analysis | `examples/security_audit_demo/main.pan` | ✅ |
| HTTPS client | `examples/http_client/main.pan` | ✅ |
| Filesystem | `examples/file_manager/main.pan` | ✅ |
