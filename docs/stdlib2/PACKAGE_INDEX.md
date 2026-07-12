# PantherLang Standard Library 2.0 — Package Index

Complete public API reference for all 25 `panther.*` packages. Each package is defined in `stdlib/panther/<name>/__init__.pan`.

---

## panther.core
**File:** `stdlib/panther/core/__init__.pan`

### Type Conversion
- `panther_core_type_of(value)` → string
- `panther_core_to_int(value)` → int
- `panther_core_to_float(value)` → float
- `panther_core_to_number(value)` → int|float
- `panther_core_to_string(value)` → string
- `panther_core_to_bool(value)` → bool

### Type Predicates
- `panther_core_is_string(value)` → bool
- `panther_core_is_int(value)` → bool
- `panther_core_is_float(value)` → bool
- `panther_core_is_bool(value)` → bool
- `panther_core_is_array(value)` → bool
- `panther_core_is_object(value)` → bool
- `panther_core_is_null(value)` → bool
- `panther_core_is_number(value)` → bool

### Equality & Comparison
- `panther_core_eq(a, b)` → bool
- `panther_core_ne(a, b)` → bool
- `panther_core_lt(a, b)` → bool
- `panther_core_le(a, b)` → bool
- `panther_core_gt(a, b)` → bool
- `panther_core_ge(a, b)` → bool

### Validation
- `panther_core_validate_type(value, expected_type)` → {ok: bool, value|error}
- `panther_core_validate_range(value, min, max)` → {ok: bool, value|error}
- `panther_core_assert(condition, message)` → {ok: bool, error?}

### Inspection & I/O
- `panther_core_inspect(value)` → string
- `panther_core_pretty_print(value)` → string
- `panther_core_println(value)` → void
- `panther_core_input(prompt_text)` → string
- `panther_core_readline(prompt_text)` → string

### Option / Result
- `panther_core_some(value)` → {some: true, value}
- `panther_core_none()` → {some: false, value: null}
- `panther_core_is_some(opt)` → bool
- `panther_core_is_none(opt)` → bool
- `panther_core_unwrap(opt, default)` → value
- `panther_core_ok(value)` → {ok: true, value}
- `panther_core_err(error)` → {ok: false, error}
- `panther_core_is_ok(result)` → bool
- `panther_core_is_err(result)` → bool
- `panther_core_unwrap_ok(result)` → value|null
- `panther_core_unwrap_err(result)` → error|null

---

## panther.math
**File:** `stdlib/panther/math/__init__.pan`

### Basic Arithmetic
- `panther_math_abs(x)` → number
- `panther_math_min(a, b)` → number
- `panther_math_max(a, b)` → number
- `panther_math_add(a, b)` → number
- `panther_math_diff(a, b)` → number
- `panther_math_prod(a, b)` → number
- `panther_math_quot(a, b)` → number|null
- `panther_math_rem(a, b)` → number
- `panther_math_pow(base, exp)` → number
- `panther_math_sqrt(x)` → number|null
- `panther_math_cbrt(x)` → number

### Rounding
- `panther_math_floor(x)` → int
- `panther_math_ceil(x)` → int
- `panther_math_round(x)` → int
- `panther_math_trunc(x)` → int

### Clamping & Interpolation
- `panther_math_clamp(value, lo, hi)` → number
- `panther_math_lerp(a, b, t)` → number
- `panther_math_map(value, in_min, in_max, out_min, out_max)` → number

### Random
- `panther_math_random()` → float [0,1)
- `panther_math_random_int(lo, hi)` → int
- `panther_math_random_float(lo, hi)` → float

### Sign & Properties
- `panther_math_sign(x)` → -1|0|1
- `panther_math_is_even(x)` → bool
- `panther_math_is_odd(x)` → bool
- `panther_math_is_prime(n)` → bool

### Statistics
- `panther_math_sum(arr)` → number
- `panther_math_mean(arr)` → number
- `panther_math_median(arr)` → number
- `panther_math_variance(arr)` → number
- `panther_math_stddev(arr)` → number

### Constants
- `panther_math_pi()` → float
- `panther_math_e()` → float
- `panther_math_tau()` → float

### Degree/Radian
- `panther_math_deg_to_rad(deg)` → float
- `panther_math_rad_to_deg(rad)` → float

### Integer Math
- `panther_math_gcd(a, b)` → int
- `panther_math_lcm(a, b)` → int

---

## panther.text
**File:** `stdlib/panther/text/__init__.pan`

### Basic Operations
- `panther_text_len(s)` → int
- `panther_text_trim(s)` → string
- `panther_text_trim_start(s)` → string
- `panther_text_trim_end(s)` → string
- `panther_text_split(s, sep)` → array
- `panther_text_join(sep, items)` → string
- `panther_text_contains(s, sub)` → bool
- `panther_text_starts_with(s, prefix)` → bool
- `panther_text_ends_with(s, suffix)` → bool
- `panther_text_replace(s, old, new)` → string
- `panther_text_replace_all(s, old, new)` → string
- `panther_text_upper(s)` → string
- `panther_text_lower(s)` → string
- `panther_text_capitalize(s)` → string
- `panther_text_substring(s, start, end)` → string
- `panther_text_char_at(s, index)` → string
- `panther_text_repeat(s, n)` → string
- `panther_text_pad_start(s, length, pad_char)` → string
- `panther_text_pad_end(s, length, pad_char)` → string
- `panther_text_reverse(s)` → string
- `panther_text_to_lines(s)` → array
- `panther_text_to_words(s)` → array

### Case Conversion
- `panther_text_camel_case(s)` → string
- `panther_text_snake_case(s)` → string
- `panther_text_kebab_case(s)` → string

### Search
- `panther_text_index_of(s, sub)` → int
- `panther_text_last_index_of(s, sub)` → int

### Validation
- `panther_text_is_empty(s)` → bool
- `panther_text_is_blank(s)` → bool
- `panther_text_matches(s, pattern)` → bool

### Formatting & Encoding
- `panther_text_format(template, values)` → string
- `panther_text_base64_encode(s)` → string
- `panther_text_base64_decode(s)` → string
- `panther_text_url_encode(s)` → string
- `panther_text_url_decode(s)` → string

---

## panther.net
**File:** `stdlib/panther/net/__init__.pan`

### Network Configuration
- `panther_net_local_ip()` → string
- `panther_net_primary_ip()` → string
- `panther_net_gateway()` → string
- `panther_net_dns()` → string
- `panther_net_dns_servers()` → array
- `panther_net_interfaces()` → array
- `panther_net_mac_address(interface)` → string
- `panther_net_resolve(host)` → string
- `panther_net_reverse_resolve(ip)` → string
- `panther_net_is_private_ip(ip)` → bool
- `panther_net_local_ips()` → array
- `panther_net_neighbors()` → array

### Port Checking
- `panther_net_port_check(host, port, timeout)` → string
- `panther_net_port_open(host, port)` → bool
- `panther_net_ping(host)` → string
- `panther_net_scan_lan()` → array

### TCP Operations
- `panther_net_tcp_connect(host, port, timeout_ms)` → string
- `panther_net_tcp_banner(host, port, timeout_ms)` → string
- `panther_net_tcp_send(host, port, data, timeout)` → string
- `panther_net_tcp_serve_start(port, response, oneshot)` → string
- `panther_net_tcp_serve_stop(port)` → string
- `panther_net_tcp_serve_wait(port, timeout)` → string

### UDP Operations
- `panther_net_udp_send(host, port, data, timeout)` → string

### IP Classification (Self-Hosted)
- `panther_net_is_loopback_ip(ip)` → bool
- `panther_net_is_link_local_ip(ip)` → bool
- `panther_net_network_class(ip)` → string
- `panther_net_risk_score(ip, open_ports, unknown_nodes, vpn_enabled)` → int
- `panther_net_security_label(score)` → string
- `panther_net_release_summary(ip, score)` → string

---

## panther.database
**File:** `stdlib/panther/database/__init__.pan`

### Connection
- `panther_database_open(path)` → connection
- `panther_database_close(conn)` → bool

### Query Execution
- `panther_database_execute(conn, sql, params?)` → int (rowcount)
- `panther_database_query(conn, sql, params?)` → array of rows
- `panther_database_query_one(conn, sql, params?)` → row|null
- `panther_database_query_scalar(conn, sql, params?)` → value|null

### Transactions
- `panther_database_begin(conn)` → bool
- `panther_database_commit(conn)` → bool
- `panther_database_rollback(conn)` → bool
- `panther_database_transaction(conn, callback)` → {ok: bool, value|error}

### Prepared Statements
- `panther_database_prepare(conn, sql)` → statement
- `panther_database_stmt_execute(stmt, params)` → int
- `panther_database_stmt_query(stmt, params)` → array
- `panther_database_stmt_query_one(stmt, params)` → row|null

### Schema
- `panther_database_table_exists(conn, table)` → bool
- `panther_database_get_columns(conn, table)` → array
- `panther_database_get_indexes(conn, table)` → array
- `panther_database_get_foreign_keys(conn, table)` → array

### Maintenance
- `panther_database_backup(conn, dest_path)` → bool (not implemented)
- `panther_database_vacuum(conn)` → bool
- `panther_database_analyze(conn)` → bool

### Row Helpers
- `panther_database_row_first_value(row)` → value
- `panther_database_row_keys(row)` → array
- `panther_database_rows_to_array(rows)` → array

---

## panther.crypto
**File:** `stdlib/panther/crypto/__init__.pan`

### Hashing
- `panther_crypto_sha256(data)` → string
- `panther_crypto_sha512(data)` → string
- `panther_crypto_md5(data)` → string
- `panther_crypto_hmac_sha256(key, message)` → string
- `panther_crypto_hmac_sha512(key, message)` → string

### Secure Random
- `panther_crypto_secure_token(nbytes)` → string (hex)
- `panther_crypto_random_bytes(nbytes)` → string
- `panther_crypto_secure_random_int(lo, hi)` → int

### UUID
- `panther_crypto_uuid()` → string

### Constant-Time Compare
- `panther_crypto_secure_compare(a, b)` → bool

### Encoding
- `panther_crypto_base64_encode(data)` → string
- `panther_crypto_base64_decode(data)` → string
- `panther_crypto_hex_encode(data)` → string
- `panther_crypto_hex_decode(data)` → string

### Path Sanitization
- `panther_crypto_sanitize_path(base, user_path)` → string

### Password Hashing
- `panther_crypto_hash_password(password, salt?)` → "salt:hash"
- `panther_crypto_verify_password(password, stored)` → bool
- `panther_crypto_pbkdf2(password, salt, iterations)` → "salt:iterations:hash"
- `panther_crypto_verify_pbkdf2(password, stored)` → bool

---

## panther.json
**File:** `stdlib/panther/json/__init__.pan`

### Parse / Stringify
- `panther_json_parse(text)` → value
- `panther_json_decode(text)` → value
- `panther_json_stringify(value)` → string
- `panther_json_encode(value)` → string

### Pretty / Validate
- `panther_json_pretty(value)` → string
- `panther_json_valid(text)` → bool

### Query
- `panther_json_get(obj, path)` → value (dot notation, supports `array[0]`)

### Type Checks
- `panther_json_is_object(value)` → bool
- `panther_json_is_array(value)` → bool
- `panther_json_is_string(value)` → bool
- `panther_json_is_number(value)` → bool
- `panther_json_is_bool(value)` → bool
- `panther_json_is_null(value)` → bool

### Utilities
- `panther_json_compact(value)` → string
- `panther_json_escape_string(s)` → string
- `panther_json_unescape_string(s)` → string

---

## panther.time
**File:** `stdlib/panther/time/__init__.pan`

### Current Time
- `panther_time_now()` → float (unix timestamp)
- `panther_time_timestamp()` → float
- `panther_time_monotonic()` → float

### Sleep
- `panther_time_sleep(secs)` → void
- `panther_time_sleep_ms(ms)` → void
- `panther_time_sleep_us(us)` → void

### Formatting
- `panther_time_format(timestamp, fmt)` → string (strftime)
- `panther_time_format_iso(timestamp)` → string
- `panther_time_format_date(timestamp)` → string
- `panther_time_format_time(timestamp)` → string
- `panther_time_parse(s)` → float
- `panther_time_parse_iso(s)` → float

### Duration Helpers
- `panther_time_duration(seconds)` → float
- `panther_time_seconds(seconds)` → float
- `panther_time_minutes(minutes)` → float
- `panther_time_hours(hours)` → float
- `panther_time_days(days)` → float

### Components
- `panther_time_year(timestamp)` → int
- `panther_time_month(timestamp)` → int
- `panther_time_day(timestamp)` → int
- `panther_time_hour(timestamp)` → int
- `panther_time_minute(timestamp)` → int
- `panther_time_second(timestamp)` → int
- `panther_time_weekday(timestamp)` → int (0=Sun)
- `panther_time_yearday(timestamp)` → int

### Comparison
- `panther_time_is_before(a, b)` → bool
- `panther_time_is_after(a, b)` → bool
- `panther_time_diff(a, b)` → float

### Duration Formatting
- `panther_time_format_duration(seconds)` → string

### Timezone
- `panther_time_utc_offset()` → int (0)

---

## panther.collections
**File:** `stdlib/panther/collections/__init__.pan`

### Array Operations
- `panther_collections_array_len(arr)` → int
- `panther_collections_array_push(arr, item)` → int (new length)
- `panther_collections_array_pop(arr)` → value
- `panther_collections_array_get(arr, index)` → value
- `panther_collections_array_set(arr, index, value)` → array
- `panther_collections_array_contains(arr, item)` → bool
- `panther_collections_array_index_of(arr, item)` → int
- `panther_collections_array_reverse(arr)` → array
- `panther_collections_array_sort(arr)` → array
- `panther_collections_array_map(arr, callback)` → array
- `panther_collections_array_filter(arr, predicate)` → array
- `panther_collections_array_reduce(arr, reducer, initial)` → value
- `panther_collections_array_join(arr, sep)` → string
- `panther_collections_array_concat(arr1, arr2)` → array
- `panther_collections_array_flatten(arr)` → array

### Range
- `panther_collections_range(start, end, step?)` → array

---

## panther.files
**File:** `stdlib/panther/files/__init__.pan`

- `panther_files_read(path)` → string
- `panther_files_write(path, content)` → bool
- `panther_files_append(path, content)` → bool
- `panther_files_exists(path)` → bool
- `panther_files_mkdir(path)` → bool
- `panther_files_copy(src, dst)` → bool
- `panther_files_move(src, dst)` → bool
- `panther_files_remove(path)` → bool
- `panther_files_rename(src, dst)` → bool
- `panther_files_listdir(path)` → array
- `panther_files_cwd()` → string
- `panther_files_absolute(path)` → string
- `panther_files_is_file(path)` → bool
- `panther_files_is_dir(path)` → bool
- `panther_files_basename(path)` → string
- `panther_files_dirname(path)` → string
- `panther_files_extension(path)` → string
- `panther_files_join(a, b)` → string
- `panther_files_tempdir()` → string
- `panther_files_tempfile(suffix?)` → string
- `panther_files_stat(path)` → object
- `panther_files_walk(path)` → array

---

## panther.http
**File:** `stdlib/panther/http/__init__.pan`

### Basic Requests
- `panther_http_get(url, timeout?)` → response
- `panther_http_post(url, data, timeout?)` → response
- `panther_http_put(url, data, timeout?)` → response
- `panther_http_delete(url, timeout?)` → response
- `panther_http_request(method, url, data, timeout?)` → response

### Structured Response
- `panther_http_fetch(url, method, data, timeout?)` → {ok: bool, status: int, body: string, error?}

### JSON Helpers
- `panther_http_get_json(url, timeout?)` → value|null
- `panther_http_post_json(url, data, timeout?)` → value|null
- `panther_http_put_json(url, data, timeout?)` → value|null
- `panther_http_delete_json(url, timeout?)` → value|null

### Status Classification
- `panther_http_status_ok(status)` → bool
- `panther_http_status_error(status)` → bool
- `panther_http_status_redirect(status)` → bool

---

## panther.ai
**File:** `stdlib/panther/ai/__init__.pan`

### Provider & Model
- `panther_ai_provider(name)` → provider
- `panther_ai_model(provider, name)` → model
- `panther_ai_list_models(provider)` → array

### Messages
- `panther_ai_message(role, content)` → message
- `panther_ai_system_message(content)` → message
- `panther_ai_user_message(content)` → message
- `panther_ai_assistant_message(content)` → message

### Chat
- `panther_ai_chat(model, messages, options?)` → {ok: bool, content: string, usage?}
- `panther_ai_chat_stream(model, messages, options?)` → array
- `panther_ai_structured_output(model, messages, schema, options?)` → {ok: bool, data|error}

### Tools
- `panther_ai_tool(name, description, parameters)` → tool
- `panther_ai_chat_with_tools(model, messages, tools, options?)` → result

### Resilience
- `panther_ai_with_timeout(ai_fn, timeout_ms)` → result
- `panther_ai_retry(ai_fn, retries, delay)` → result

### Metadata
- `panther_ai_usage(result)` → usage
- `panther_ai_detect_injection(prompt_text)` → {detected: bool, patterns: array}
- `panther_ai_audit_log(event_type, details)` → log entry
- `panther_ai_require_approval(operation, context)` → {required: bool, reason: string}
- `panther_ai_available_providers()` → array of strings

### Providers (Stubs)
- `panther_ai_ollama_chat(model, messages, options?)` → {ok: false, error}
- `panther_ai_openai_chat(model, messages, options?)` → {ok: false, error}
- `panther_ai_anthropic_chat(model, messages, options?)` → {ok: false, error}

### Testing
- `panther_ai_mock_chat(model, messages, options?)` → {ok: true, content, usage}

---

## panther.security
**File:** `stdlib/panther/security/__init__.pan`

### Secret Detection & Redaction
- `panther_security_audit_secrets(text)` → array of "type=...;pattern=...;match=..."
- `panther_security_redact(text, patterns)` → string
- `panther_security_redact_secrets(text)` → string

### Input Validation
- `panther_security_validate_email(email)` → bool
- `panther_security_validate_url(url)` → bool
- `panther_security_validate_ip(ip)` → bool
- `panther_security_validate_ipv6(ip)` → bool
- `panther_security_validate_hostname(host)` → bool

### Sanitization
- `panther_security_sanitize_sql(input)` → string
- `panther_security_sanitize_html(input)` → string
- `panther_security_sanitize_path(base, user_path)` → string
- `panther_security_sanitize_shell(input)` → string

### Policy Engine
- `panther_security_policy_create(name, rules)` → policy string
- `panther_security_policy_check(policy, input)` → "allowed=true" | "allowed=false;reason=..."

### Audit Logging
- `panther_security_audit_log(event_type, details)` → log string
- `panther_security_audit_write(log)` → log string

### Rate Limiting (Simulated)
- `panther_security_rate_limit_check(key, limit, window)` → "allowed=true;remaining=N"

### CORS & Headers
- `panther_security_cors_policy(origins, methods, headers)` → policy string
- `panther_security_headers()` → headers string

---

## panther.logging
**File:** `stdlib/panther/logging/__init__.pan`

### Leveled
- `panther_logging_debug(message)` → string
- `panther_logging_info(message)` → string
- `panther_logging_warn(message)` → string
- `panther_logging_error(message)` → string
- `panther_logging_set_level(level)` → string

### Structured & Formatted
- `panther_logging_log(level, message, fields)` → string
- `panther_logging_debugf(template, args)` → string
- `panther_logging_infof(template, args)` → string
- `panther_logging_warnf(template, args)` → string
- `panther_logging_errorf(template, args)` → string

### Level Constants
- `panther_logging_LEVEL_DEBUG()` → "debug"
- `panther_logging_LEVEL_INFO()` → "info"
- `panther_logging_LEVEL_WARN()` → "warn"
- `panther_logging_LEVEL_ERROR()` → "error"

---

## panther.system
**File:** `stdlib/panther/system/__init__.pan`

- `panther_system_hostname()` → string
- `panther_system_os()` → string
- `panther_system_arch()` → string
- `panther_system_username()` → string
- `panther_system_env(name, default?)` → string
- `panther_system_cpu_count()` → int
- `panther_system_memory()` → object
- `panther_system_disk(path)` → object
- `panther_system_uptime()` → float
- `panther_system_cwd()` → string
- `panther_system_pid()` → int
- `panther_system_ppid()` → int
- `panther_system_command_line()` → string
- `panther_system_home()` → string
- `panther_system_temp()` → string
- `panther_system_exit(code)` → void

---

## panther.testing
**File:** `stdlib/panther/testing/__init__.pan`

- `panther_testing_test(name, test_fn)` → bool
- `panther_testing_test_eq(name, actual, expected)` → bool
- `panther_testing_test_ne(name, actual, expected)` → bool
- `panther_testing_test_true(name, condition)` → bool
- `panther_testing_test_false(name, condition)` → bool
- `panther_testing_test_null(name, value)` → bool
- `panther_testing_test_not_null(name, value)` → bool
- `panther_testing_test_contains(name, haystack, needle)` → bool
- `panther_testing_test_throws(name, test_fn)` → bool
- `panther_testing_run_suite(name, tests)` → bool

---

## panther.storage
**File:** `stdlib/panther/storage/__init__.pan`

### Basic Operations
- `panther_storage_open(path)` → store
- `panther_storage_put(store, key, data)` → bool
- `panther_storage_get(store, key)` → string
- `panther_storage_exists(store, key)` → bool
- `panther_storage_delete(store, key)` → bool
- `panther_storage_list(store, prefix?)` → array

### JSON Helpers
- `panther_storage_put_json(store, key, value)` → bool
- `panther_storage_get_json(store, key)` → value|null

### Batch Operations
- `panther_storage_put_batch(store, items)` → bool
- `panther_storage_get_batch(store, keys)` → object
- `panther_storage_delete_batch(store, keys)` → bool

### Prefix Operations
- `panther_storage_get_prefix(store, prefix)` → object
- `panther_storage_delete_prefix(store, prefix)` → int

### Metadata
- `panther_storage_count(store)` → int
- `panther_storage_keys(store, prefix?)` → array
- `panther_storage_size(store)` → int

### Collections
- `panther_storage_collection(store, collection_name)` → collection
- `panther_storage_coll_put(coll, key, data)` → bool
- `panther_storage_coll_get(coll, key)` → string
- `panther_storage_coll_exists(coll, key)` → bool
- `panther_storage_coll_delete(coll, key)` → bool
- `panther_storage_coll_list(coll)` → array
- `panther_storage_coll_count(coll)` → int

### TTL Support
- `panther_storage_put_ttl(store, key, data, ttl_seconds)` → bool
- `panther_storage_get_ttl(store, key)` → string|null
- `panther_storage_cleanup_expired(store)` → int

---

## panther.serialization
**File:** `stdlib/panther/serialization/__init__.pan`

### JSON
- `panther_serialization_json_encode(value)` → string
- `panther_serialization_json_decode(text)` → value
- `panther_serialization_json_pretty(value)` → string
- `panther_serialization_json_valid(text)` → bool

### YAML (Fallback to JSON)
- `panther_serialization_yaml_encode(value)` → string
- `panther_serialization_yaml_decode(text)` → value

### TOML (Fallback to JSON)
- `panther_serialization_toml_encode(value)` → string
- `panther_serialization_toml_decode(text)` → value

### MessagePack (Fallback to JSON)
- `panther_serialization_msgpack_encode(value)` → string
- `panther_serialization_msgpack_decode(data)` → value

### CBOR (Fallback to JSON)
- `panther_serialization_cbor_encode(value)` → string
- `panther_serialization_cbor_decode(data)` → value

### Base64 / Hex
- `panther_serialization_base64_encode(data)` → string
- `panther_serialization_base64_decode(data)` → string
- `panther_serialization_hex_encode(data)` → string
- `panther_serialization_hex_decode(data)` → string

### CSV (Placeholder)
- `panther_serialization_csv_encode(rows)` → string
- `panther_serialization_csv_decode(text)` → array

### Universal Interface
- `panther_serialization_encode(value, format)` → string
- `panther_serialization_decode(data, format)` → value
- `panther_serialization_encode_with_options(value, format, options)` → string
- `panther_serialization_stream_encode(value, format, writer)` → {ok: bool, bytes_written: int}

**Supported formats:** "json", "yaml", "toml", "msgpack", "cbor", "base64", "hex"

---

## panther.cli
**File:** `stdlib/panther/cli/__init__.pan`

### Parsing
- `panther_cli_parse(args)` → {_positional: array, ...flags}
- `panther_cli_get_flag(parsed, name, default)` → value
- `panther_cli_get_option(parsed, name, default)` → value
- `panther_cli_get_positional(parsed, index, default)` → value
- `panther_cli_positional_count(parsed)` → int

### Help & Usage
- `panther_cli_usage(name, description, options)` → string
- `panther_cli_help(name, description, options)` → string

### Version & Exit Codes
- `panther_cli_version(version)` → string
- `panther_cli_EXIT_SUCCESS()` → 0
- `panther_cli_EXIT_FAILURE()` → 1
- `panther_cli_EXIT_USAGE()` → 2

### Progress & Colors
- `panther_cli_progress_bar(current, total, width)` → string
- `panther_cli_color_red(text)` → string
- `panther_cli_color_green(text)` → string
- `panther_cli_color_yellow(text)` → string
- `panther_cli_color_blue(text)` → string
- `panther_cli_color_cyan(text)` → string
- `panther_cli_color_bold(text)` → string
- `panther_cli_color_reset(text)` → string

---

## panther.web
**File:** `stdlib/panther/web/__init__.pan`

### Server
- `panther_web_server_create(host, port)` → server

### Routes
- `panther_web_get(server, path, handler)` → server
- `panther_web_post(server, path, handler)` → server
- `panther_web_put(server, path, handler)` → server
- `panther_web_delete(server, path, handler)` → server
- `panther_web_route(server, method, path, handler)` → server

### Middleware & Static
- `panther_web_use(server, middleware)` → server
- `panther_web_static(server, path, root)` → server

### Lifecycle
- `panther_web_start(server)` → bool
- `panther_web_stop(server)` → bool

### Responses
- `panther_web_response_json(data)` → string
- `panther_web_response_html(html)` → string
- `panther_web_response_text(text)` → string
- `panther_web_response_error(status, message)` → object
- `panther_web_response_redirect(url)` → object

### Request Accessors
- `panther_web_request_param(req, name, default)` → value
- `panther_web_request_query(req, name, default)` → value
- `panther_web_request_body(req)` → value
- `panther_web_request_header(req, name)` → value
- `panther_web_request_method(req)` → string
- `panther_web_request_path(req)` → string

### Error Handling & CORS
- `panther_web_error_handler(server, status, handler)` → server
- `panther_web_cors(server, options)` → server

### Health & Info
- `panther_web_health_check()` → {status: "ok", timestamp: float}
- `panther_web_server_info(server)` → object

---

## panther.cloud
**File:** `stdlib/panther/cloud/__init__.pan`

### Abstraction
- `panther_cloud_provider(name)` → provider
- `panther_cloud_service(provider, name, config)` → service

### AWS
- `panther_cloud_aws_s3_bucket(provider, bucket_name, region)` → service
- `panther_cloud_aws_lambda(provider, function_name, runtime, handler)` → service
- `panther_cloud_aws_dynamodb(provider, table_name, region)` → service
- `panther_cloud_aws_sqs(provider, queue_name, region)` → service
- `panther_cloud_aws_sns(provider, topic_name, region)` → service

### GCP
- `panther_cloud_gcp_storage(provider, bucket_name, location)` → service
- `panther_cloud_gcp_functions(provider, function_name, region)` → service
- `panther_cloud_gcp_firestore(provider, project_id)` → service
- `panther_cloud_gcp_pubsub(provider, topic_name, project_id)` → service

### Azure
- `panther_cloud_azure_blob(provider, container_name, account_name)` → service
- `panther_cloud_azure_functions(provider, function_name, resource_group)` → service
- `panther_cloud_azure_cosmosdb(provider, database_name, account_name)` → service
- `panther_cloud_azure_servicebus(provider, queue_name, namespace)` → service

### Operations
- `panther_cloud_deploy(service, config)` → {status: "deployed", service, config}
- `panther_cloud_scale(service, replicas)` → {status: "scaled", service, replicas}
- `panther_cloud_logs(service, filter)` → {service, logs: array}
- `panther_cloud_metrics(service, metric_names)` → {service, metrics: object}

### Multi-Cloud
- `panther_cloud_available_providers()` → array
- `panther_cloud_estimate_cost(services, hours)` → {estimated_cost: float, services, hours}

---

## panther.container
**File:** `stdlib/panther/container/__init__.pan`

### Images
- `panther_container_image(name, tag)` → image
- `panther_container_build(dockerfile_path, image_name, tag, build_args)` → {status: "built", image, path}
- `panther_container_pull(image_name, tag)` → {status: "pulled", image}
- `panther_container_push(image_name, tag, registry)` → {status: "pushed", image, registry}
- `panther_container_tag(image_name, source_tag, target_tag)` → {status: "tagged", image, source, target}
- `panther_container_inspect(image_name, tag)` → {image, layers, size}
- `panther_container_history(image_name, tag)` → {image, history}

### Lifecycle
- `panther_container_run(image_name, tag, options)` → {status: "running", container_id, image}
- `panther_container_start(container_id)` → {status: "started", container_id}
- `panther_container_stop(container_id, timeout)` → {status: "stopped", container_id}
- `panther_container_restart(container_id, timeout)` → {status: "restarted", container_id}
- `panther_container_pause(container_id)` → {status: "paused", container_id}
- `panther_container_unpause(container_id)` → {status: "running", container_id}
- `panther_container_remove(container_id, force)` → {status: "removed", container_id}
- `panther_container_kill(container_id, signal)` → {status: "killed", container_id}

### Inspection
- `panther_container_ps(all, filter)` → array
- `panther_container_logs(container_id, follow, tail)` → {container_id, logs: string}
- `panther_container_exec(container_id, command, options)` → {status: "executed", container_id, exit_code}
- `panther_container_stats(container_id, no_stream)` → {container_id, cpu, memory}
- `panther_container_top(container_id, ps_args)` → {container_id, processes}
- `panther_container_port(container_id, private_port)` → {container_id, public_port}

### Volumes
- `panther_container_volume_create(name, driver, options)` → {status: "created", volume}
- `panther_container_volume_remove(name)` → {status: "removed", volume}
- `panther_container_volume_inspect(name)` → {volume, mountpoint}
- `panther_container_volume_ls(filter)` → array
- `panther_container_volume_prune()` → {volumes_deleted: array}

### Networks
- `panther_container_network_create(name, driver, options)` → {status: "created", network}
- `panther_container_network_remove(name)` → {status: "removed", network}
- `panther_container_network_inspect(name)` → {network, containers}
- `panther_container_network_ls(filter)` → array
- `panther_container_network_connect(network, container_id)` → {status: "connected", network, container}
- `panther_container_network_disconnect(network, container_id)` → {status: "disconnected", network, container}

### Compose
- `panther_container_compose_up(compose_file, project_name, detach)` → {status: "up", project, services}
- `panther_container_compose_down(compose_file, project_name, volumes)` → {status: "down", project}
- `panther_container_compose_ps(compose_file, project_name)` → {project, services}
- `panther_container_compose_logs(compose_file, project_name, services)` → {project, logs}

### Registry
- `panther_container_registry_login(registry, username, password)` → {status: "logged_in", registry}
- `panther_container_registry_logout(registry)` → {status: "logged_out", registry}
- `panther_container_registry_search(term, limit)` → array

### Health & Resources
- `panther_container_health_check(container_id)` → {status: "healthy", container_id}
- `panther_container_wait(container_id, condition)` → {status: "completed", container_id}
- `panther_container_update(container_id, resources)` → {status: "updated", container_id}

---

## panther.process
**File:** `stdlib/panther/process/__init__.pan`

### Execution (Not Implemented)
- `panther_process_run(command, args, env, timeout, cwd)` → {ok: false, error}
- `panther_process_spawn(command, args, env, cwd)` → {ok: false, error}
- `panther_process_kill(pid, signal)` → bool
- `panther_process_wait(pid, timeout)` → {ok: false, error}

### Current Process
- `panther_process_self_pid()` → int
- `panther_process_self_ppid()` → int
- `panther_process_self_env()` → object
- `panther_process_self_cwd()` → string
- `panther_process_self_argv()` → array
- `panther_process_self_exe()` → string

---

## panther.concurrent
**File:** `stdlib/panther/concurrent/__init__.pan`

### Worker Pool (Python Bootstrap)
- `panther_concurrent_spawn(task)` → task
- `panther_concurrent_join(task)` → result
- `panther_concurrent_join_timeout(task, timeout_ms)` → result
- `panther_concurrent_task_status(task)` → status
- `panther_concurrent_task_result(task)` → result
- `panther_concurrent_task_error(task)` → error
- `panther_concurrent_cancel(task)` → bool
- `panther_concurrent_worker_count()` → int

### Queues (Python Bootstrap)
- `panther_concurrent_queue_create()` → queue
- `panther_concurrent_queue_put(queue, value)` → void
- `panther_concurrent_queue_get(queue)` → value
- `panther_concurrent_queue_get_timeout(queue, timeout_ms)` → value

### Parallel Algorithms (Panther Impl)
- `panther_concurrent_map(mapper, items)` → array
- `panther_concurrent_filter(predicate, items)` → array
- `panther_concurrent_reduce(reducer, items, initial)` → value
- `panther_concurrent_for_each(action, items)` → void

### Synchronization (Panther Data Structures)
- `panther_concurrent_wait_group()` → {count: 0, tasks: []}
- `panther_concurrent_add(wg, task)` → void
- `panther_concurrent_wait(wg)` → void
- `panther_concurrent_semaphore(permits)` → {permits, waiting}
- `panther_concurrent_acquire(sem)` → bool
- `panther_concurrent_release(sem)` → void
- `panther_concurrent_mutex()` → {locked: false, owner: null}
- `panther_concurrent_lock(mutex)` → bool
- `panther_concurrent_unlock(mutex)` → void
- `panther_concurrent_channel(buffer_size)` → {buffer: [], size, closed: false}
- `panther_concurrent_send(ch, value)` → bool
- `panther_concurrent_receive(ch)` → value
- `panther_concurrent_close(ch)` → void

### Promises (Panther Data Structures)
- `panther_concurrent_promise()` → {state: "pending", value: null, callbacks: []}
- `panther_concurrent_resolve(promise, value)` → void
- `panther_concurrent_reject(promise, error)` → void
- `panther_concurrent_then(promise, on_fulfilled, on_rejected)` → void
- `panther_concurrent_all(promises)` → array
- `panther_concurrent_race(promises)` → string
- `panther_concurrent_timeout(promise, ms)` → promise

---

## panther.async
**File:** `stdlib/panther/async/__init__.pan`

### Task Execution (Python Bootstrap)
- `panther_async_task(callable_fn)` → task
- `panther_async_run(task)` → result
- `panther_async_await_task(task)` → result
- `panther_async_await_timeout(task, timeout_ms)` → result
- `panther_async_sleep(milliseconds)` → void
- `panther_async_gather(tasks)` → array
- `panther_async_race(tasks)` → result
- `panther_async_retry(callable_fn, attempts)` → result
- `panther_async_retry_with_backoff(callable_fn, attempts, initial_delay_ms)` → result
- `panther_async_cancel(task)` → bool
- `panther_async_status(task)` → status

### Async Iterators (Panther Impl)
- `panther_async_range(start, end, step)` → array
- `panther_async_map(callback, items)` → array
- `panther_async_filter(predicate, items)` → array
- `panther_async_reduce(reducer, items, initial)` → value
- `panther_async_for_each(callback, items)` → void

### Utilities (Panther Data Structures)
- `panther_async_with_timeout(callback, timeout_ms)` → result
- `panther_async_debounce(callback, delay)` → callback
- `panther_async_throttle(callback, interval)` → callback
- `panther_async_memoize(callback)` → callback
- `panther_async_circuit_breaker(callback, failure_threshold, reset_timeout)` → callback

---

*This index reflects the exact public APIs exposed in each package's `__init__.pan` as of PantherLang v1.1.8.*