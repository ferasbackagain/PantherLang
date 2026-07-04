# PantherLang Standard Library S1-S6 API Contract

Status: **Release Contract Candidate**

This document freezes the current callable API names for the PantherLang Standard Library S1-S6 foundation. The current language syntax uses global prefixed functions such as `fs_read()` and `net_local_ip()`. Future namespace syntax such as `std.fs.read()` may be added later, but these names must remain backward compatible unless a major version explicitly deprecates them.

## Release Requirements

Every library group must have:

- Stable API names.
- Documentation.
- Runnable examples.
- Automated tests.
- Linux/Kali support.
- Windows test commands.
- Regression coverage.

## S1 — Types and I/O Foundation

Stable functions:

- `type_of(value)`
- `to_string(value)`
- `to_int(value)`
- `to_float(value)`
- `to_number(value)`
- `to_bool(value)`
- `println(value, ...)`
- `printf(format, ...)`
- `input([prompt])`
- `readline([prompt])`

Policy:

- PantherLang does not perform implicit conversion between incompatible types.
- Conversion must be explicit.

## S2 — Filesystem

Stable functions:

- `fs_read(path)`
- `fs_write(path, content)`
- `fs_append(path, content)`
- `fs_exists(path)`
- `fs_mkdir(path)`
- `fs_copy(src, dst)`
- `fs_move(src, dst)`
- `fs_remove(path)`
- `fs_rename(src, dst)`
- `fs_listdir([path])`
- `fs_cwd()`
- `fs_absolute(path)`

Safety:

- Examples write only under `.panther_tmp/`.

## S3 — System / Time / Random

Stable functions:

- `system_hostname()`
- `system_os()`
- `system_arch()`
- `system_username()`
- `system_env(name[, default])`
- `system_cpu_count()`
- `system_memory()`
- `system_disk([path])`
- `system_uptime()`
- `system_cwd()`
- `system_pid()`
- `system_command_line()`
- `time_now()`
- `time_sleep(seconds)`
- `random_float()`
- `random_int(low, high)`

## S4 — Network / HTTP / JSON / SQLite

Stable functions:

- `net_local_ip()`
- `net_gateway()`
- `net_dns()`
- `net_interfaces()`
- `net_mac_address([interface])`
- `net_resolve(host)`
- `net_ping(host)`
- `net_port_check(host, port[, timeout])`
- `net_scan_lan()`
- `http_request(method, url[, data, timeout])`
- `http_get(url)`
- `http_post(url, data)`
- `http_put(url[, data])`
- `http_delete(url)`
- `json_parse(text)`
- `json_stringify(value)`
- `json_pretty(value)`
- `json_valid(text)`
- `sqlite_open(path)`
- `sqlite_close(conn)`
- `sqlite_execute(conn, sql[, params])`
- `sqlite_query(conn, sql[, params])`

Network security:

- `net_scan_lan()` is defensive and passive-only. It reads local ARP/cache information and must not perform unauthorized active scanning.

## S5 — Crypto

Stable functions:

- `crypto_sha256(text)`
- `crypto_sha512(text)`
- `crypto_md5(text)`
- `crypto_hmac_sha256(key, message)`
- `crypto_uuid()`
- `crypto_random_bytes([nbytes])`
- `crypto_secure_random_int(low, high)`
- `crypto_base64_encode(text)`
- `crypto_base64_decode(text)`
- `crypto_hex_encode(text)`
- `crypto_hex_decode(text)`

Security:

- Use safe primitives from the host runtime.
- Do not implement custom cryptography.

## S6 — AI Helpers

Stable functions:

- `ai_supported_providers()`
- `ai_provider_available(provider)`
- `ai_mock_chat(prompt)`

Security:

- No hardcoded API keys.
- Real provider integration must use environment variables.
- Mock mode must always work offline.
