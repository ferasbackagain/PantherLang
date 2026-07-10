# PantherLang Capability Completion Plan

**Date:** 2026-07-09
**Baseline:** v1.1.6 (commit a7f487e), 1084/1084 tests passing
**Derived from:** PANTHERLANG_CAPABILITY_GAP_AUDIT.md

## Dependency Graph

```
C0 (Release Correctness) — no deps
  └─> C1 (System Foundation) — no deps
       └─> C2 (Network Foundation) — depends on C1 naming conventions
            └─> C3 (Socket Foundation) — depends on C2 patterns
                 └─> C4 (Filesystem Completion) — depends on C1 (path utilities)
                      └─> C5 (Data/Serialization) — depends on C4 (binary I/O)
                           └─> C6 (Database Foundation) — depends on C5 (datetime)
                                └─> C7 (Storage Foundation) — depends on C5 + C6
                                     └─> C8 (Cloud Application Foundation) — depends on C7
                                          └─> C9 (Concurrency/Async) — independent architecture
                                               └─> C10 (Observability) — depends on C9 (timers)
                                                    └─> C11 (Security Hardening) — depends on all above
                                                         └─> C12 (Package Ecosystem) — depends on C8
                                                              └─> C13 (Final Regression) — depends on all
```

## Phase Plan

| Phase | Title | Focus | Dependencies | Proof Gate |
|-------|-------|-------|-------------|------------|
| C0 | Release Correctness | BOM handling, CRLF tests, Windows PATH, empty source | None | Tests pass, no regression |
| C1 | System Foundation | system_home(), system_temp(), system_ppid(), system_exit() | None | .pan program runs with real output |
| C2 | Network Foundation | net_local_ips(), net_is_private_ip(), net_reverse_resolve() | C1 (naming conventions) | .pan program reads real machine state |
| C3 | Socket Foundation | TCP client/server, UDP client/server | C2 (patterns) | loopback client/server test passes |
| C4 | Filesystem Completion | is_file, is_dir, stat, basename, dirname, join, extension, walk, binary I/O | C1 (path conventions) | .pan file manager works |
| C5 | Data/Serialization | CSV, datetime, timezone, URL encode/decode, schema validation | C4 (binary I/O) | data pipeline example works |
| C6 | Database Foundation | Transactions, rollback, PostgreSQL adapter if proven | C5 (datetime) | CRUD + rollback test |
| C7 | Storage Foundation | Storage contract, local + S3-compatible | C5 + C6 | local storage example + mocked protocol |
| C8 | Cloud Application | Config profiles, retry/backoff, health, shutdown, structured logs | C7 | cloud-ready service example |
| C9 | Concurrency/Async | Async/await, tasks, channels (if architecture permits) | Independent | Deterministic tests |
| C10 | Observability | Logging, metrics, tracing contracts | C9 | Telemetry output |
| C11 | Security Hardening | Threat model all APIs, injection tests | All above | Injection/traversal/secret tests |
| C12 | Package Ecosystem | `panther install/uninstall/publish` | C8 | Package lifecycle test |
| C13 | Final Regression | Full test suite, examples, installers | All | 1084+ baseline maintained |

## Current Phase: C0
