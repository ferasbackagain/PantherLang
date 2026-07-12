# PantherLang Architecture Status

This document explains the architectural layers of PantherLang v1.1.8, what runs in PantherLang, what runs in the Host (Python), and the path toward implementation independence.

---

## Layer Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PantherLang Source (.pan)                 │
├─────────────────────────────────────────────────────────────┤
│  Package Imports → Symbol Resolution → Host ABI Calls       │
├─────────────────────────────────────────────────────────────┤
│                        Host ABI (Runtime)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │ Built-in     │  │ Stdlib       │  │ Native/FFI         │  │
│  │ Functions    │  │ Registrations│  │ (future)           │  │
│  └──────────────┘  └──────────────┘  └────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    Python Bootstrap Runtime                  │
│  • Tree-walking interpreter (compiler/runtime/execution)    │
│  • Host function registry (C-ABI style)                     │
│  • Python stdlib for I/O, crypto, networking, SQLite       │
│  • _async_*, _concurrent_* primitives                       │
└─────────────────────────────────────────────────────────────┘
```

---

## What Is PantherLang Code

**Application source** — every `.pan`/`.panther` file you write — is PantherLang code.

**Standard Library 2.0 packages** (`panther.*`) are **also PantherLang code**. They live in `stdlib/panther/<name>/__init__.pan` and export functions using the `panther_<package>_<function>` naming convention.

**The compiler pipeline** (lexer, parser, semantic analysis, type checking) is **Python code** in `compiler/`.

**The runtime** (tree-walking interpreter, variable environment, Host ABI) is **Python code** in `compiler/runtime/`.

---

## Host ABI (Host Application Binary Interface)

The Host ABI is the bridge between PantherLang execution and Python-backed capabilities.

### How It Works

1. A Panther function calls a "builtin" (e.g., `print`, `len`, `db_open`)
2. The runtime looks up the name in the **Host Function Registry**
3. The registered Python function executes with Panther values converted to Python
4. Result is converted back to Panther value and returned

### Registration Points

- **Core builtins:** `compiler/runtime/builtins.py` — `print`, `len`, `type_of`, `to_string`, etc.
- **Stdlib packages:** Each `panther_<package>` function is registered at import time via `compiler/stdlib/registry.py`
- **Host modules:** `compiler/runtime/host_functions/` — crypto, filesystem, network, database, HTTP, time, system, etc.

### Current Host Functions (Representative)

| Category | Functions | Implementation |
|----------|-----------|----------------|
| I/O | `print`, `println`, `input`, `readline` | Python `print`/`input` |
| Conversion | `to_int`, `to_float`, `to_string`, `to_bool`, `type_of` | Python `int()`/`float()`/`str()`/`bool()`/`type()` |
| Collections | `array_push`, `array_pop`, `array_reverse`, `array_sort`, `len` | Python list ops |
| Crypto | `sha256`, `hmac_sha256`, `secure_token`, `uuid`, `base64_encode` | Python `hashlib`, `hmac`, `secrets`, `uuid`, `base64` |
| Filesystem | `read_file`, `write_file`, `file_exists`, `mkdir`, `list_dir` | Python `pathlib`, `open()` |
| Network | `net_local_ip`, `net_resolve`, `net_port_check`, `tcp_connect` | Python `socket`, `psutil`, `dns.resolver` |
| Database | `db_open`, `db_execute`, `db_query`, `db_begin`, `db_commit` | Python `sqlite3` |
| HTTP | `http_get`, `http_post`, `http_request` | Python `requests` |
| Time | `time_now`, `time_sleep`, `datetime_format`, `datetime_parse` | Python `time`, `datetime` |
| System | `system_hostname`, `system_os`, `system_env`, `system_cpu_count` | Python `platform`, `os`, `psutil` |
| Random | `random`, `randint` | Python `random` |
| JSON | `json_parse`, `json_stringify`, `json_pretty` | Python `json` |
| Regex | `regex_match`, `regex_findall`, `regex_replace` | Python `re` |
| Async/Concurrent | `_async_task`, `_async_run`, `_async_await`, `_concurrent_spawn` | Python `asyncio`, `threading` |

---

## Python Bootstrap Responsibilities

The following **currently require Python** and are not implemented in PantherLang:

| Area | What Python Provides | PantherLang Status |
|------|---------------------|-------------------|
| Lexer | Tokenization, Unicode handling | Not self-hosted |
| Parser | Pratt expression + recursive descent | Not self-hosted |
| Semantic Analysis | Symbol tables, scope, diagnostics | Not self-hosted |
| Type Checking | T001, inference, compatibility | Not self-hosted |
| Interpreter | Tree-walking execution, call frames | Not self-hosted |
| Host ABI | Function registry, value conversion | Not self-hosted |
| Async Runtime | `_async_*`, `_concurrent_*` | Delegates to Python `asyncio`/`threading` |
| Stdlib I/O | File, network, crypto, DB, HTTP | Delegates to Python stdlib |
| Package Loading | Import resolution, registration | Python-driven |
| CLI | Argument parsing, command dispatch | Python `argparse`-style |
| VS Code Extension | Language server, debugger, syntax | TypeScript/Node.js |

---

## Implementation Independence Trajectory

| Release | Milestone |
|---------|-----------|
| v1.0 | Python compiler + runtime; Panther stdlib via Host ABI |
| v1.1 | Standard Library 2.0 (25 packages); package imports |
| v1.1.8 | Version alignment; README/CLI/extension/docs truthfulness |
| **v1.2 (target)** | **PantherLang parser in PantherLang**; expanded type system |
| **v1.3 (target)** | **Native async runtime in PantherLang**; HTTP server hardening |
| **v2.0 (target)** | **Package registry**; incremental compilation; LSP completion |

---

## What "Self-Hosted" Means Here

| Claim | Current Reality |
|-------|-----------------|
| "PantherLang is written in PantherLang" | ❌ False. Compiler/runtime are Python. Stdlib packages are PantherLang. |
| "Zero Python dependency" | ❌ False. `pip install -e .` installs Python package. |
| "Fully native compiler" | ❌ False. No native codegen; tree-walking interpreter in Python. |
| "Stdlib is PantherLang" | ✅ True. 25 packages, ~500 functions in `.pan` files. |
| "Applications are PantherLang" | ✅ True. All user code is `.pan`/`.panther`. |

---

## Distributable Artifacts (v1.1.8)

| Artifact | Contains Python? | Notes |
|----------|-----------------|-------|
| `pantherlang-1.1.8.tar.gz` / `.whl` | Yes | Source + bytecode; requires Python 3.10+ |
| VSIX extension | No (Node.js) | `pantherlang-official-1.1.8.vsix` |
| Installer scripts | Bash/PowerShell/Batch | Bootstrap venv + pip install |

---

## Honest Claims Checklist

| Claim | Status | Evidence |
|-------|--------|----------|
| "Applications are written in PantherLang" | ✅ | All examples, tests, stdlib packages are `.pan` |
| "25 packages with verified APIs" | ✅ | `PACKAGE_INDEX.md`, `PACKAGE_MATURITY.md` |
| "panther check / panther run works" | ✅ | CI runs full regression; README showcase verified |
| "Compiler is self-hosted" | ❌ | `compiler/` is Python |
| "Zero Python runtime" | ❌ | Interpreter, Host ABI, async, I/O all Python |
| "All packages production-ready" | ❌ | See `PACKAGE_MATURITY.md` |
| "Native binaries available" | ❌ | Only Python wheel + VSIX |

---

## For Contributors

**When adding a stdlib function:**
1. Write it in `stdlib/panther/<package>/__init__.pan` as `fn panther_<pkg>_<name>()`
2. Register in Host ABI if it needs Python backing (`compiler/runtime/host_functions/`)
3. Add test in `tests/` exercising the Panther function
4. Update `PACKAGE_INDEX.md`

**When moving capability from Python to Panther:**
1. Implement Panther-native version (e.g., parser in PantherLang)
2. Keep Python version as fallback during transition
3. Switch registry to prefer Panther implementation
4. Remove Python version when tests pass

---

*Architecture status current as of PantherLang v1.1.8. Next review: v1.2 release.*