# Phase 0 — Forensic Architecture Audit

**PantherLang Native Network Intelligence Engine**

**Date**: 2026-07-09  
**Version**: 1.1.6  
**Repository**: `/home/panther/Downloads/PantherLang`  
**Founder**: Feras Khatib

---

## 1. Baseline Test Results

| Metric | Value |
|--------|-------|
| Total tests | 1195 |
| Passed | 1195 |
| Failed | 0 |
| Test duration | 91.66s |
| Python | 3.13.12 |
| panther doctor | All OK |

**Baseline recorded**: 1195 passing, 0 failing.

_Note: Prior to the Phase 0 selfhost.py regex fix, 5 self-hosting tests failed. These are now resolved._

---

## 2. Execution Pipeline

```
.pan source text
    │
    ▼
apply_selfhosted_stdlib()           [compiler/stdlib/selfhost.py]
    │  Injects stdlib/selfhost/*.pan function definitions
    │  into top-level block bodies (panther main { ... })
    ▼
lex_source()                        [compiler/lexer/lexer.py]
    │  Tokenizes source into Token list
    ▼
ProgramParser(stream).parse()       [compiler/parser/program_parser.py]
    │  Pratt expression + recursive descent → ProgramNode AST
    ▼
SemanticAnalyzer (check path only)  [compiler/semantic/analyzer.py]
    │  Validates symbols, declares stdlib function names
    ▼
StatementExecutor(env)              [compiler/runtime/statement_executor.py]
    │  Executes AST nodes against VariableEnvironment
    ▼
ExecutionResult
```

**Entry points**: `cli/panther_cli.py` — `_run()` → `execute_source()`, `_check()` → applies selfhost then lex+parse+semantic.

---

## 3. Semantic Registry

**File**: `compiler/stdlib/functions.py`  
**Data structure**: `_STDLIB: dict[str, StdlibFunction]` (module-level, line 30)  
**Registration**: `_register(StdlibFunction(name, arity, fn, doc))`  
**Consumption (semantic)**: `SemanticAnalyzer._register_stdlib_symbols()` (analyzer.py:48-57) iterates `get_stdlib_functions()` keys, declares each in `SymbolTable` as `SymbolKind.FUNCTION`.  
**Consumption (runtime)**: `VariableEnvironment._register_stdlib()` (variable_environment.py:105-111) stores `fn.fn` callables in `env._functions[name]`.

**Total registered functions**: 174

---

## 4. Self-Host Stdlib Loader

**File**: `compiler/stdlib/selfhost.py`  
**Location**: `stdlib/selfhost/*.pan`  
**Files**: 1 — `stdlib/selfhost/network.pan` (138 lines)  
**Functions defined in .pan**: 7

| .pan function | Logic | Host dependency |
|---|---|---|
| `net_is_loopback_ip(ip)` | `starts_with(ip, "127.")` | `starts_with` (Python stdlib) |
| `net_is_link_local_ip(ip)` | `starts_with(ip, "169.254.")` | `starts_with` |
| `net_is_private_ip(ip)` | RFC 1918 prefix checks | none beyond starts_with |
| `net_network_class(ip)` | Classification combining above 3 | none |
| `net_risk_score(ip, open_ports, unknown_nodes, vpn)` | Heuristic scoring | none |
| `net_security_label(score)` | HIGH/MEDIUM/LOW threshold | none |
| `net_release_summary(ip, score)` | Formatting | none |

**Injection mechanism**: Regex-based. Matches `panther main {`, `web {`, `api {`, `ai {`, `test {` at line start. Injects self-host source after the opening `{`.

**Bug found and fixed** (Phase 0): `_TOP_LEVEL_PATTERN` regex had doubled backslashes `\\t` instead of `\t` and `\\{` instead of `\{` inside raw string, causing complete silent failure of all injection.

---

## 5. API Classification Table

Legend:
- **SEM_REG**: Registered in `_STDLIB` for semantic analysis
- **RNT_REG**: Registered in `env._functions` for runtime dispatch
- **ORPHAN**: Defined as module globals but NOT in `_STDLIB` (inaccessible from PantherLang)
- **PYTHON**: Implementation language for substantive logic
- **SUBPROCESS**: Uses subprocess
- **SHELL**: Uses shell=True
- **NATIVE**: Direct OS API access
- **NETREQ**: Requires network connectivity

### 5.1 System APIs

| PUBLIC_NAME | SEM_REG | RNT_REG | IMPL_LANG | HOST_DEP | PLATFORM | TEST_COV | STATUS |
|---|---|---|---|---|---|---|---|
| `system_hostname()` | YES | YES | Python | socket.gethostname() | All | partial | REAL |
| `system_os()` | YES | YES | Python | platform.system() | All | partial | REAL |
| `system_arch()` | YES | YES | Python | platform.machine() | All | partial | REAL |
| `system_username()` | YES | YES | Python | os.environ | All | partial | REAL |
| `system_env(name, default)` | YES | YES | Python | os.environ.get | All | partial | REAL |
| `system_cpu_count()` | YES | YES | Python | os.cpu_count() | All | partial | REAL |
| `system_memory()` | YES | YES | Python | /proc/meminfo | Linux | none | REAL/LINUX |
| `system_disk(path)` | YES | YES | Python | shutil.disk_usage | All | none | REAL |
| `system_uptime()` | YES | YES | Python | /proc/uptime | Linux | none | REAL/LINUX |
| `system_cwd()` | YES | YES | Python | Path.cwd() | All | none | REAL |
| `system_pid()` | YES | YES | Python | os.getpid() | All | none | REAL |
| `system_command_line()` | YES | YES | Python | sys.argv | All | none | REAL |
| `system_home()` | YES | YES | Python | Path.home() | All | none | REAL |
| `system_temp()` | YES | YES | Python | tempfile | All | none | REAL |
| `system_ppid()` | YES | YES | Python | os.getppid() | All | none | REAL |
| `system_exit(code)` | YES | YES | Python | sys.exit() | All | none | REAL |
| `system_platform()` | **NO** | **NO** | Python | platform.system() | All | none | **ORPHAN** |

### 5.2 Network APIs — Properly Registered

| PUBLIC_NAME | SEM_REG | RNT_REG | IMPL_LANG | HOST_DEP | PLATFORM | TEST_COV | STATUS |
|---|---|---|---|---|---|---|---|
| `net_local_ip()` | YES | YES | Python | UDP to 8.8.8.8:80 | All (netreq) | none | REAL/NETREQ |
| `net_gateway()` | YES | YES | Python | /proc/net/route | Linux | none | REAL/LINUX |
| `net_dns()` | YES | YES | Python | /etc/resolv.conf | Linux | none | REAL/LINUX |
| `net_interfaces()` | YES | YES | Python | socket.if_nameindex() | All | none | REAL |
| `net_mac_address([if])` | YES | YES | Python | /sys/class/net or uuid | Linux/All | none | REAL |
| `net_resolve(host)` | YES | YES | Python | socket.gethostbyname | All | none | REAL |
| `net_ping(host)` | YES | YES | Python | **subprocess** ping -c 1 | All | none | REAL/SUBPROC |
| `net_port_check(host, port, timeout)` | YES | YES | Python | socket.create_connection | All | none | REAL/SOCKET |
| `net_scan_lan()` | YES | YES | Python | /proc/net/arp | Linux | none | REAL/LINUX/PASSIVE |
| `net_local_ips()` | YES | YES | Python | **subprocess** ip -o -4 addr | Linux | none | REAL/SUBPROC |
| `net_is_private_ip(ip)` | YES | YES | Python | Pure Python RFC 1918 | All | none | REAL |
| `net_reverse_resolve(ip)` | YES | YES | Python | socket.gethostbyaddr | All | none | REAL |
| `net_tcp_send(host, port, data, timeout)` | YES | YES | Python | socket | All | none | REAL/SOCKET |
| `net_tcp_serve_start(port, ...)` | YES | YES | Python | socket + threading | All | none | REAL/SOCKET |
| `net_tcp_serve_stop(port)` | YES | YES | Python | threading.Event | All | none | REAL |
| `net_tcp_serve_wait(port, timeout)` | YES | YES | Python | threading.join | All | none | REAL |
| `net_udp_send(host, port, data, timeout)` | YES | YES | Python | socket | All | none | REAL/SOCKET |

### 5.3 Network APIs — ORPHANED (not accessible from PantherLang)

These 12 functions are defined at `functions.py:1456-1752` via `globals().update()` but are **NOT** registered through `_register()`. The registration probe searches for `FUNCTIONS`, `BUILTINS`, `BUILTIN_FUNCTIONS`, `STDLIB_FUNCTIONS`, `FUNCTION_REGISTRY`, `REGISTRY` dicts — none exist in the module. They are invisible to semantic analyzer and runtime.

| PUBLIC_NAME | SEM_REG | RNT_REG | IMPL_LANG | HOST_DEP | STATUS |
|---|---|---|---|---|---|
| `system_platform()` | **NO** | **NO** | Python | platform.system() | ORPHAN/DUPLICATE of system_os |
| `net_primary_ip()` | **NO** | **NO** | Python | UDP to 1.1.1.1:80 | ORPHAN/DUPLICATE of net_local_ip |
| `net_dns_servers()` | **NO** | **NO** | Python | /etc/resolv.conf + **subprocess** nmcli/resolvectl | ORPHAN |
| `net_neighbors()` | **NO** | **NO** | Python | **subprocess** ip neigh / arp -an | ORPHAN |
| `net_resolve(host)` | **NO** | **NO** | Python | socket.gethostbyname | ORPHAN/DUPLICATE |
| `net_network_class(ip)` | **NO** | **NO** | Python | ipaddress module | ORPHAN/DUPLICATE of .pan version |
| `net_is_private_ip(ip)` | **NO** | **NO** | Python | ipaddress module | ORPHAN/DUPLICATE |
| `net_risk_score(ip, ...)` | **NO** | **NO** | Python | Pure Python | ORPHAN/DUPLICATE of .pan version |
| `net_security_label(score)` | **NO** | **NO** | Python | Pure Python | ORPHAN/DUPLICATE of .pan version |
| `net_release_summary(ip, score)` | **NO** | **NO** | Python | Pure Python | ORPHAN/DUPLICATE of .pan version |
| `tcp_connect(host, port, timeout)` | **NO** | **NO** | Python | socket.connect_ex | ORPHAN/LOST |
| `tcp_banner(host, port, timeout)` | **NO** | **NO** | Python | socket.sendall + recv | ORPHAN/LOST |

### 5.4 Self-Host .pan Functions

These exist only as injected PantherLang source via `selfhost.py`. They are not registered in `_STDLIB`.

| PUBLIC_NAME | DEFINED IN | HOST_DEP | STATUS |
|---|---|---|---|
| `net_is_loopback_ip(ip)` | network.pan | starts_with() | PANTHER-IMPLEMENTED |
| `net_is_link_local_ip(ip)` | network.pan | starts_with() | PANTHER-IMPLEMENTED |
| `net_is_private_ip(ip)` | network.pan | starts_with() | PANTHER-IMPLEMENTED |
| `net_network_class(ip)` | network.pan | none | PANTHER-IMPLEMENTED |
| `net_risk_score(ip, open_ports, unknown_nodes, vpn)` | network.pan | none | PANTHER-IMPLEMENTED |
| `net_security_label(score)` | network.pan | none | PANTHER-IMPLEMENTED |
| `net_release_summary(ip, score)` | network.pan | none | PANTHER-IMPLEMENTED |

---

## 6. Critical Issues Found

### Issue A: Orphaned Network Functions (CRITICAL)

**Location**: `compiler/stdlib/functions.py:1716-1751`  

The `_panther_register_network_mapper_foundation()` function attempts to register 12 network functions (`tcp_connect`, `tcp_banner`, `net_primary_ip`, `net_dns_servers`, `net_neighbors`, `net_network_class`, `net_is_private_ip`, `net_risk_score`, `net_security_label`, `net_release_summary`, `system_platform`, `net_resolve`) by searching for dict names that don't exist. It falls through to `globals().update()`, making these module-level globals inaccessible from PantherLang.

**Impact**:
- `tcp_connect` and `tcp_banner` — essential TCP primitives — are **completely unusable** from PantherLang
- Semantic checker produces "Undefined symbol" errors when any orphaned function is called
- Runtime produces "Undefined function" errors

### Issue B: Subprocess Dependencies

Three registered network APIs use subprocess:
- `net_ping()` — runs `ping -c 1 -W 1 <host>` via subprocess
- `net_local_ips()` — runs `ip -o -4 addr show` via subprocess

The orphaned `net_neighbors()` also uses subprocess for `ip neigh` and `arp -an`.

### Issue C: Linux-only Dependencies

| Function | Linux-specific file |
|---|---|
| `net_gateway()` | `/proc/net/route` |
| `net_dns()` | `/etc/resolv.conf` |
| `system_memory()` | `/proc/meminfo` |
| `system_uptime()` | `/proc/uptime` |
| `net_scan_lan()` | `/proc/net/arp` |
| `net_mac_address(if)` | `/sys/class/net/<if>/address` |

### Issue D: Internet Dependency for Local IP

Both `net_local_ip()` (registered) and the orphaned `net_primary_ip()` use UDP connect to external DNS servers (8.8.8.8, 1.1.1.1) to determine local primary IP. No offline fallback.

### Issue E: No Structured Error Model

All network functions use silent failure with empty values:
- Empty string on failure
- Empty list on failure
- "unknown" string
- "127.0.0.1" fallback

No structured result types, no error codes, no deterministic error classification.

### Issue F: Overlapping Definitions

Multiple conflicting implementations exist for the same logical function:

| Concept | Registered stdlib | Orphaned Python | Self-host .pan |
|---|---|---|---|
| ip classification | — | `net_network_class` | `net_network_class` |
| private ip check | `net_is_private_ip` | `net_is_private_ip` | `net_is_private_ip` |
| risk scoring | — | `net_risk_score` | `net_risk_score` |
| security label | — | `net_security_label` | `net_security_label` |
| hostname lookup | `net_resolve` | `net_resolve` | — |
| local IP | `net_local_ip` | `net_primary_ip` | — |

### Issue G: No Test Coverage for Network APIs

A grep for `net_` and `tcp_` and `system_` in `tests/` shows:
- `net_local_ip` — no dedicated tests
- `net_gateway` — no dedicated tests
- `net_dns` — no dedicated tests
- `net_interfaces` — no dedicated tests
- `net_port_check` — no dedicated tests
- `net_resolve` — no dedicated tests
- `tcp_connect` — no dedicated tests (entirely inaccessible)
- `tcp_banner` — no dedicated tests (entirely inaccessible)
- `system_hostname` — no dedicated tests

---

## 7. Architecture Findings Summary

| Component | File | Status |
|---|---|---|
| Semantic registration | `compiler/stdlib/functions.py:30-34` | Working, 174 functions |
| Semantic consumption | `compiler/semantic/analyzer.py:48-57` | Working |
| Runtime registration | `compiler/runtime/variable_environment.py:105-111` | Working |
| Runtime dispatch | `compiler/runtime/expression_evaluator.py:223-238` | Working |
| Self-host injection | `compiler/stdlib/selfhost.py` | **Fixed** in Phase 0 |
| Orphaned functions | `compiler/stdlib/functions.py:1716-1751` | **Broken** — not accessible |
| Type checker | `compiler/types/checker.py` | No stdlib type signatures; all return Any |
| Security analyzer | `compiler/security/` | Present, not relevant to network features |

---

## 8. Phase 0 Pass Checklist

- [x] Exact architecture identified (Section 2)
- [x] Exact semantic registry identified (Section 3)
- [x] Exact runtime registry identified (Section 3)
- [x] Exact execution pipeline identified (Section 2)
- [x] Self-host mechanism identified and fixed (Section 4)
- [x] All fake/stub/empty-result behavior identified (Sections 5, 6)
- [x] Baseline tests recorded (Section 1 — 1195 pass, 0 fail)
- [x] Orphaned functions identified (Section 5.3)
- [x] No structured error model identified (Section 6E)

**Phase 0 PASS**: Ready for Phase 1.
