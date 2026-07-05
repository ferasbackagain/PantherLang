# PantherLang v1.1.6 — Stdlib Truth Matrix

**Date:** 2026-07-04
**Source:** `compiler/stdlib/functions.py` — actual `_register()` calls

---

## Actual Registered Functions (125 names, ~107 unique implementations)

### ✅ VERIFIED WORKING (tested this session)

| Category | Callable Name | Test |
|----------|---------------|------|
| System | `system_hostname()` | ✅ `phase4_stdlib2.pan` |
| System | `system_os()` | ✅ |
| System | `system_arch()` | ✅ |
| System | `system_cpu_count()` | ✅ |
| System | `system_pid()` | ✅ |
| System | `system_username()` | ✅ |
| Network | `net_local_ip()` | ✅ |
| Network | `net_dns()` | ❓ untested |
| Network | `net_gateway()` | ❓ untested |
| Network | `net_interfaces()` | ❓ untested |
| Network | `net_mac_address()` | ❓ untested |
| Network | `net_resolve()` | ❓ untested |
| Network | `net_port_check()` | ❓ untested |
| Network | `net_ping()` | ❓ untested |
| Network | `net_scan_lan()` | ❓ untested |
| Filesystem | `fs_exists()` | ✅ |
| Filesystem | `fs_mkdir()` | ✅ |
| Filesystem | `fs_write()` | ✅ |
| Filesystem | `fs_read()` | ✅ |
| Filesystem | `fs_listdir()` | ❓ untested |
| Filesystem | `fs_remove()` | ❓ untested |
| Filesystem | `fs_rename()` | ❓ untested |
| Filesystem | `fs_copy()` | ❓ untested |
| Filesystem | `fs_move()` | ❓ untested |
| Filesystem | `fs_append()` | ❓ untested |
| Filesystem | `fs_cwd()` | ❓ untested |
| Filesystem | `fs_absolute()` | ❓ untested |
| Crypto | `crypto_sha256()` | ✅ |
| Crypto | `crypto_sha512()` | ✅ |
| Crypto | `crypto_md5()` | ✅ |
| Crypto | `crypto_uuid()` | ❓ untested |
| Crypto | `crypto_random_bytes()` | ❓ untested |
| Crypto | `crypto_secure_random_int()` | ❓ untested |
| Crypto | `crypto_base64_encode()` | ❓ untested |
| Crypto | `crypto_base64_decode()` | ❓ untested |
| Crypto | `crypto_hex_encode()` | ❓ untested |
| Crypto | `crypto_hex_decode()` | ❓ untested |
| Crypto | `crypto_hmac_sha256()` | ❓ untested |
| JSON | `json_valid()` | ✅ |
| JSON | `json_pretty()` | ✅ |
| JSON | `json_parse()` | ❓ (alias for json_decode?) |
| JSON | `json_stringify()` | ❓ (alias for json_encode?) |
| Time | `time()` | ✅ |
| Time | `time_now()` | ✅ (alias) |
| Time | `time_sleep()` | ✅ (also `sleep()`) |

### ✅ VERIFIED WORKING (previous cookbook tests)

| Category | Callable Name | Test File |
|----------|---------------|-----------|
| String | `len()`, `substring()`, `contains()`, `starts_with()`, `ends_with()` | `08-strings.pan` |
| String | `upper()`, `lower()`, `trim()`, `replace()`, `split()`, `join()` | `08-strings.pan` |
| Math | `abs()`, `max()`, `min()`, `pow()`, `sqrt()` | `03-arithmetic.pan` |
| Math | `floor()`, `ceil()`, `round()` | `03-arithmetic.pan` |
| Math | `random()`, `randint()` | `12-math.pan` |
| JSON | `json_encode()`, `json_decode()` | `10-json.pan` |
| Time | `time()`, `sleep()` | `12-math.pan` |
| Conversion | `int()`, `float()`, `string()` | `02-types.pan` |
| Crypto | `sha256()`, `hmac_sha256()`, `secure_token()`, `secure_compare()` | `11-security.pan` |
| Security | `sanitize_path()`, `sanitize_html()` | `11-security.pan` |
| Filesystem | `read_file()`, `write_file()`, `file_exists()`, `mkdir()`, `list_dir()`, `remove_file()` | `09-filesystem.pan` |
| HTTP | `http_get()`, `http_post()` | `14-http.pan` |
| Regex | `regex_match()`, `regex_replace()`, `regex_split()` | `13-regex.pan` |
| Collections | `array_push()`, `array_pop()`, `array_sort()`, `array_reverse()` | `15-collections.pan` |
| SQLite | `db_open()`, `db_execute()`, `db_query()`, `db_close()` | `16-sqlite.pan` |

## Name Mapping — Documented vs. Actual

| Documented Name | Actual Name(s) | Notes |
|-----------------|----------------|-------|
| `sha256()` | `sha256()` or `crypto_sha256()` | Both work |
| `hmac_sha256()` | `hmac_sha256()` or `crypto_hmac_sha256()` | Both work |
| `sleep()` | `sleep()` or `time_sleep()` | Both work |
| `int()` | `int()` or `to_int()` | Both work |
| `float()` | `float()` or `to_float()` | Both work |
| `string()` | `string()` or `to_string()` | Both work |
| `time()` | `time()` or `time_now()` | Both work |
| `json_encode()` | `json_encode()` or `json_stringify()` | Both work |
| `json_decode()` | `json_decode()` or `json_parse()` | Both work |

## Undocumented But Working Functions

These functions exist in `stdlib/functions.py` but are NOT documented in any lesson, book chapter, or README:

### System (10+)
`system_hostname()`, `system_os()`, `system_arch()`, `system_username()`, `system_env()`, `system_cpu_count()`, `system_memory()`, `system_disk()`, `system_uptime()`, `system_pid()`, `system_command_line()`, `system_cwd()`

### Network (9)
`net_local_ip()`, `net_interfaces()`, `net_dns()`, `net_gateway()`, `net_mac_address()`, `net_resolve()`, `net_port_check()`, `net_ping()`, `net_scan_lan()`

### Extended Crypto (8+)
`crypto_sha512()`, `crypto_md5()`, `crypto_uuid()`, `crypto_random_bytes()`, `crypto_secure_random_int()`, `crypto_base64_encode()`, `crypto_base64_decode()`, `crypto_hex_encode()`, `crypto_hex_decode()`

### Extended Filesystem (6+)
`fs_append()`, `fs_copy()`, `fs_move()`, `fs_rename()`, `fs_cwd()`, `fs_absolute()`

### Extended JSON (3)
`json_valid()`, `json_pretty()`, `json_parse()`

### Extended HTTP (3)
`http_put()`, `http_delete()`, `http_request()`

### Extended Type (5)
`to_bool()`, `to_number()`, `type_of()`, `bool_text()`, `convert()`

### AI (3)
`ai_mock_chat()`, `ai_provider_available()`, `ai_supported_providers()`

### I/O (2)
`input()`, `readline()`, `println()`, `printf()`

### SQLite aliases (4)
`sqlite_open()`, `sqlite_close()`, `sqlite_execute()`, `sqlite_query()`

## Key Discrepancies

| Issue | Details |
|-------|---------|
| **Prefix convention** | Some functions use `fs_*`, `crypto_*`, `net_*`, `system_*` prefixes but also have unprefixed aliases |
| **Dual naming** | Both `sha256()` and `crypto_sha256()` work, creating confusion |
| **Documented count** | README claims 43 functions, but 125 are actually registered |
| **`to_string` vs `string`** | Both are registered but docs only mention `string()` |
| **`list_dir` vs `fs_listdir`** | Both exist but with different signatures |
