# PantherLang Stdlib Self-Hosting — Phase 1 Evidence

## Classification

**PHASE 1 STATUS: PASS_WITH_TARGETED_PROOF**

This package implements the first self-hosted PantherLang standard-library layer.

The work does **not** claim full runtime self-hosting. The runtime/compiler are still
Python-backed. The new model is:

```text
User .pan program
→ self-hosted stdlib logic in stdlib/selfhost/*.pan
→ Python host primitives for OS/system access
→ operating system
```

## What changed

### New self-hosted PantherLang stdlib source

- `stdlib/selfhost/network.pan`

This file contains real PantherLang functions:

- `net_is_loopback_ip(ip)`
- `net_is_link_local_ip(ip)`
- `net_is_private_ip(ip)`
- `net_network_class(ip)`
- `net_risk_score(ip, open_ports, unknown_nodes, vpn_enabled)`
- `net_security_label(score)`
- `net_release_summary(ip, score)`

These are pure logic functions implemented in `.pan`, not Python.

### New loader

- `compiler/stdlib/selfhost.py`

The loader reads `stdlib/selfhost/*.pan`, extracts PantherLang stdlib function
declarations, and injects them into top-level PantherLang blocks before user
statements execute.

### Runtime integration

- `compiler/runtime/execution_pipeline.py`

`execute_source()` and `serve_source()` now apply the self-hosted stdlib prelude
before parsing/execution.

### CLI check integration

- `cli/panther_cli.py`

`panther check` now validates user programs after applying the self-hosted stdlib
prelude. Source loading uses `utf-8-sig` to tolerate Windows UTF-8 BOM files.

### Example

- `examples/selfhost_network_policy/main.pan`

This example obtains the real local IP from the host-backed primitive
`net_local_ip()` and then evaluates network class/risk/summary through logic
implemented in `stdlib/selfhost/network.pan`.

## Proof commands executed

```bash
python -m pytest tests/test_stdlib_self_hosting_phase1.py -q
```

Result:

```text
6 passed
```

```bash
python -m pytest   tests/test_release_correctness_c0.py   tests/test_system_foundation_c1.py   tests/test_network_foundation_c2.py   tests/test_socket_foundation_c3.py   tests/test_filesystem_foundation_c4.py   tests/test_data_serialization_c5.py   tests/test_database_foundation_c6.py   tests/test_storage_foundation_c7.py   tests/test_observability_c10.py   tests/test_security_hardening_c11.py   tests/test_stdlib_self_hosting_phase1.py   -q
```

Result:

```text
109 passed
```

```bash
python -m cli.panther_cli check examples/selfhost_network_policy/main.pan
python -m cli.panther_cli run examples/selfhost_network_policy/main.pan
```

Observed output included:

```text
PantherLang Self-Hosted Network Policy
Primary IP      : <actual host IP>
Network class   : private
Risk score      : 10
Risk label      : LOW
Policy summary  : network=private;risk=LOW
Logic source    : stdlib/selfhost/network.pan
Host primitive  : net_local_ip()
```

## Verification note

A full `python -m pytest tests/ -q` was attempted in this environment but did not
complete within the available execution window. The targeted capability suite
passed. Run the full suite on Kali before commit/push.

## What is still host-backed

The following remain host/runtime primitives:

- real local IP discovery
- real interfaces
- DNS/gateway/routes
- filesystem metadata
- sockets
- SQLite
- crypto primitives
- process/system APIs

## Phase 2 readiness

Phase 2 may start only after full regression passes on Kali. Phase 2 should
formalize a Host ABI so self-hosted stdlib code calls controlled host
capabilities instead of relying on ad-hoc builtin registration.
