# PantherLang Standard Library S1-S6 Reference

This batch adds practical, callable PantherLang stdlib functions using the current identifier-call syntax. Dot namespaces such as `std.fs.read()` remain a future syntax goal; today the stable names use prefixes.

## S1 — Types and I/O
`type_of`, `to_string`, `to_int`, `to_float`, `to_number`, `to_bool`, `println`, `printf`, `input`, `readline`.

## S2 — Filesystem
`fs_read`, `fs_write`, `fs_append`, `fs_exists`, `fs_mkdir`, `fs_copy`, `fs_move`, `fs_remove`, `fs_rename`, `fs_listdir`, `fs_cwd`, `fs_absolute`.

## S3 — System, Time, Random
`system_hostname`, `system_os`, `system_arch`, `system_username`, `system_env`, `system_cpu_count`, `system_memory`, `system_disk`, `system_uptime`, `system_cwd`, `system_pid`, `system_command_line`, `time_now`, `time_sleep`, `random_float`, `random_int`.

## S4 — Network, HTTP, JSON, SQLite
`net_local_ip`, `net_gateway`, `net_dns`, `net_interfaces`, `net_mac_address`, `net_resolve`, `net_ping`, `net_port_check`, `net_scan_lan`, `http_request`, `http_get`, `http_post`, `http_put`, `http_delete`, `json_parse`, `json_stringify`, `json_pretty`, `json_valid`, `sqlite_open`, `sqlite_close`, `sqlite_execute`, `sqlite_query`.

`net_scan_lan()` is passive and reads the ARP cache only. It does not perform active scanning.

## S5 — Crypto
`crypto_sha256`, `crypto_sha512`, `crypto_md5`, `crypto_hmac_sha256`, `crypto_uuid`, `crypto_random_bytes`, `crypto_secure_random_int`, `crypto_base64_encode`, `crypto_base64_decode`, `crypto_hex_encode`, `crypto_hex_decode`.

## S6 — AI Helpers
`ai_supported_providers`, `ai_provider_available`, `ai_mock_chat`.

No API keys are hardcoded. Real provider calls remain controlled by environment variables and future provider abstractions.
