# General-Purpose Independence Program — Phase 0: Full Repository Forensic Audit

**Date:** 2026-07-09
**Baseline:** 1268 tests passing, 0 failing
**Version:** PantherLang 1.1.6
**Python:** 3.13.12
**Platform:** Linux (kali)
**Repository:** `/home/panther/Downloads/PantherLang`

---

## 1. Registry Snapshot

### 1.1 File Counts

| Category | Count |
|----------|-------|
| Python files (`.py`) | 1,859 |
| Panther files (`.pan`) | 145 |
| Panther files (`.panther`) | 126 |
| Total Panther source files | 271 |
| Markdown files (`.md`) | ~400+ |
| JSON files | ~100+ |
| Shell scripts (`.sh`, `.ps1`, `.bat`) | ~160 |
| HTML files | 2 |
| **Compiled native binaries (`.so`, `.dll`, `.dylib`, `.pyd`)** | **0** |
| **C/C++/Rust source files (`.c`, `.cpp`, `.rs`, `.h`)** | **0** |

### 1.2 Test Suite

| Category | Count |
|----------|-------|
| Pytest suite | 1268 tests, 0 failed |
| Test subdirectories | 58 |
| Test files (`.py`) | 164 |
| `.pan` fixture files | 7 |
| Conftest files | 0 |

### 1.3 Key Directories

| Directory | Files | Role |
|-----------|-------|------|
| `compiler/` | 106 `.py` | Core compiler pipeline (lexer, parser, AST, semantic, types, runtime, stdlib, web, AI, database, security, host_abi) |
| `runtime/` | 27 `.py` | Higher-level AI/Agent/Sandbox scaffold (mostly stubs) |
| `stdlib/` | 4 `.py` + 6 `.pan` + 1 JSON | Stdlib foundation + self-host network layer |
| `cli/` | 4 `.py` | CLI entry point |
| `toolchain/` | 7 `.py` | Build toolchain |
| `package_manager/` | 4 `.py` | Package management |
| `debug_adapter/` | 39 `.py` | Production DAP implementation |
| `debug_adapter_rebuilt/` | 18 `.py` | Canonical DAP rebuild (unused target) |
| `language/` | 158 `.py` + 20 `.panther` | Second copy of compiler/tooling (separate suite) |
| `docs/` | 304 files (226 `.md`) | All documentation |
| `engineering/` | 76 files (75 `.md` + 1 JSON) | Engineering docs, prior audits |
| `tests/` | 164 `.py` | Primary test suite |
| `examples/` | 84 subdirs, 132 files | Runnable examples |
| `vscode-extension/` | ~800 lines JS/TS | VS Code extension (active) |
| `scripts/` | 143 scripts | Verification + demo runners |
| `tools/` | 12 subdirs | Mixed stubs and functional tools |
| `project_templates/` | 4 template dirs | Project scaffolding |
| `installers/` | 5 scripts | Multi-platform installers |
| `reports/` | 15 entries | Phase reports, compatibility matrices |

---

## 2. Complete Dependency Map

### 2.1 Python External (PyPI) Dependencies

**All are optional** (guarded by try/except with mock fallback):

| Package | Used In | Purpose | Required? |
|---------|---------|---------|-----------|
| `anthropic` | `compiler/ai/providers.py` | Anthropic Claude API | No (mock fallback) |
| `google-generativeai` | `compiler/ai/providers.py` | Google Gemini API | No (mock fallback) |
| `openai` | `compiler/ai/providers.py` | OpenAI GPT API | No (mock fallback) |
| `requests` | `compiler/ai/providers.py` | Ollama/OpenRouter API calls | No (mock fallback) |

**Runtime dependencies in `pyproject.toml`:** `[]` (empty)

### 2.2 External Native/Tool Dependencies

| Tool | Used In | Purpose |
|------|---------|---------|
| `ping` | `compiler/stdlib/functions.py:880` | `net_ping()` via `subprocess.run()` |
| `ip` | `compiler/stdlib/functions.py:901` | `net_local_ips()` via `subprocess.run()` |
| `ip`/`arp` | `compiler/stdlib/functions.py:1512` | `net_neighbors()` via `subprocess.run()` |
| `nmcli`/`resolvectl` | `compiler/stdlib/functions.py:1495` | `net_dns_servers()` via `subprocess.run()` |
| `libc.so` (ctypes) | `compiler/host_abi/backends/native_socket.py` | `native_tcp_connect()` via ctypes FFI (Linux only) |

### 2.3 Python Standard Library Modules Used Across the Codebase

**Heavy users:** `os`, `sys`, `pathlib`, `json`, `re`, `typing`, `dataclasses`, `enum`, `argparse`, `subprocess`, `hashlib`, `hmac`, `math`, `random`, `secrets`, `socket`, `sqlite3`, `time`, `urllib`, `shutil`, `tempfile`, `uuid`, `csv`, `datetime`, `base64`, `threading`, `struct`, `platform`, `itertools`, `functools`, `contextlib`

**Notable:** The entire compiler pipeline uses ONLY Python standard library (no PyPI dependencies). This means the compiler itself is **fully Python-Backed**.

---

## 3. Truthfulness Classification Matrix

### 3.1 Classification Summary

| Classification | Count | % of Stdlib | Definition |
|---------------|-------|-------------|------------|
| **Panther-Implemented** | 0 | 0.0% | Pure PantherLang (.pan files) |
| **Host-Backed** | 1 | 0.6% | Uses Host ABI (ctypes/libc native) |
| **Native-Backed** | 0 | 0.0% | Compiled C/Rust extension |
| **Python-Backed** | 168 | 96.0% | Pure Python stdlib implementation |
| **External-Tool-Backed** | 4 | 2.3% | Requires external binary via subprocess |
| **Stub** | 0 | 0.0% | Minimal/empty body, no real work |
| **Placeholder** | 2 | 1.1% | Returns hardcoded mock strings |
| **Fake** | 0 | 0.0% | Deterministic fake data |
| **Unsupported** | 0 | 0.0% | Errors on use |
| **Total unique `_register`-ed** | **175** | 100% | |
| **+ stdlib_engine legacy** | **5** | | Separate AST-based `std.*` functions |
| **Total stdlib functions** | **180** | | |

### 3.2 Detailed Function Matrix

#### STRING (11 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `len` | Python-Backed | `len()` |
| `substring` | Python-Backed | `s[start:end]` |
| `contains` | Python-Backed | `in` operator |
| `starts_with` | Python-Backed | `str.startswith()` |
| `ends_with` | Python-Backed | `str.endswith()` |
| `upper` | Python-Backed | `str.upper()` |
| `lower` | Python-Backed | `str.lower()` |
| `trim` | Python-Backed | `str.strip()` |
| `replace` | Python-Backed | `str.replace()` |
| `split` | Python-Backed | `str.split()` |
| `join` | Python-Backed | `str.join()` |

#### MATH (10 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `abs` | Python-Backed | `abs()` |
| `max` | Python-Backed | `max()` |
| `min` | Python-Backed | `min()` |
| `pow` | Python-Backed | `**` operator |
| `sqrt` | Python-Backed | `math.sqrt()` |
| `floor` | Python-Backed | `math.floor()` |
| `ceil` | Python-Backed | `math.ceil()` |
| `round` | Python-Backed | `round()` |
| `random` | Python-Backed | `random.random()` |
| `randint` | Python-Backed | `random.randint()` |

#### JSON (6 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `json_encode` | Python-Backed | `json.dumps()` |
| `json_decode` | Python-Backed | `json.loads()` |
| `json_parse` | Python-Backed | `json.loads()` |
| `json_stringify` | Python-Backed | `json.dumps()` |
| `json_pretty` | Python-Backed | `json.dumps(indent=2)` |
| `json_valid` | Python-Backed | try/except `json.loads()` |

#### TIME (4 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `time` | Python-Backed | `time.time()` |
| `sleep` | Python-Backed | `time.sleep()` |
| `time_now` | Python-Backed | `time.time()` |
| `time_sleep` | Python-Backed | `time.sleep()` |

#### TYPE CONVERSION / I/O (12 effective names) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `input` | Python-Backed | `builtins.input()` |
| `readline` | Python-Backed | `builtins.input()` (alias) |
| `println` | Python-Backed | `str()` join |
| `printf` | Python-Backed | `str.format()` / `%` |
| `int` | Python-Backed | `int()` |
| `float` | Python-Backed | `float()` |
| `string` | Python-Backed | `str()` with bool/null mapping |
| `to_int` | Python-Backed | `int()` |
| `to_float` | Python-Backed | `float()` |
| `to_number` | Python-Backed | `float()` |
| `to_bool` | Python-Backed | truthiness string parse |
| `to_string` | Python-Backed | `str()` with bool/null mapping |
| `type_of` | Python-Backed | `isinstance()` chain |

#### SECURITY / CRYPTO (17 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `sha256` | Python-Backed | `hashlib.sha256()` |
| `hmac_sha256` | Python-Backed | `hmac.new()` |
| `secure_token` | Python-Backed | `secrets.token_hex()` |
| `secure_compare` | Python-Backed | `hmac.compare_digest()` |
| `sanitize_path` | Python-Backed | `Path.resolve()` prefix check |
| `sanitize_html` | Python-Backed | HTML entity replacement |
| `crypto_sha256` | Python-Backed | `hashlib.sha256()` |
| `crypto_sha512` | Python-Backed | `hashlib.sha512()` |
| `crypto_md5` | Python-Backed | `hashlib.md5()` |
| `crypto_hmac_sha256` | Python-Backed | `hmac.new()` |
| `crypto_uuid` | Python-Backed | `uuid.uuid4()` |
| `crypto_random_bytes` | Python-Backed | `secrets.token_hex()` |
| `crypto_secure_random_int` | Python-Backed | `secrets.randbelow()` |
| `crypto_base64_encode` | Python-Backed | `base64.b64encode()` |
| `crypto_base64_decode` | Python-Backed | `base64.b64decode()` |
| `crypto_hex_encode` | Python-Backed | `bytes.hex()` |
| `crypto_hex_decode` | Python-Backed | `bytes.fromhex()` |

#### FILESYSTEM (28 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `read_file` | Python-Backed | `open().read()` |
| `write_file` | Python-Backed | `open().write()` |
| `file_exists` | Python-Backed | `Path.exists()` |
| `mkdir` | Python-Backed | `Path.mkdir()` |
| `list_dir` | Python-Backed | `Path.iterdir()` |
| `remove_file` | Python-Backed | `Path.unlink()` |
| `fs_read` | Python-Backed | `Path.read_text()` |
| `fs_write` | Python-Backed | `Path.write_text()` |
| `fs_append` | Python-Backed | open in append mode |
| `fs_exists` | Python-Backed | `Path.exists()` |
| `fs_mkdir` | Python-Backed | `Path.mkdir()` |
| `fs_copy` | Python-Backed | `shutil.copy2()` |
| `fs_move` | Python-Backed | `shutil.move()` |
| `fs_remove` | Python-Backed | `shutil.rmtree()`/`Path.unlink()` |
| `fs_rename` | Python-Backed | `Path.rename()` |
| `fs_listdir` | Python-Backed | `Path.iterdir()` sorted |
| `fs_cwd` | Python-Backed | `Path.cwd()` |
| `fs_absolute` | Python-Backed | `Path.resolve()` |
| `fs_is_file` | Python-Backed | `Path.is_file()` |
| `fs_is_dir` | Python-Backed | `Path.is_dir()` |
| `fs_basename` | Python-Backed | `Path.name` |
| `fs_dirname` | Python-Backed | `str(Path.parent)` |
| `fs_extension` | Python-Backed | `Path.suffix` |
| `fs_join` | Python-Backed | Path `/` operator |
| `fs_tempdir` | Python-Backed | `tempfile.mkdtemp()` |
| `fs_tempfile` | Python-Backed | `tempfile.mktemp()` |
| `fs_stat` | Python-Backed | `Path.stat()` |
| `fs_walk` | Python-Backed | `Path.rglob()` |

#### HTTP (6 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `http_get` | Python-Backed | `urllib.request.urlopen()` |
| `http_post` | Python-Backed | `urllib.request.Request()` POST |
| `http_request` | Python-Backed | `urllib.request.Request()` full |
| `http_put` | Python-Backed | wraps `http_request("PUT")` |
| `http_delete` | Python-Backed | wraps `http_request("DELETE")` |
| `sanitize_html` | Python-Backed | HTML entity replacement |

#### REGEX (3 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `regex_match` | Python-Backed | `re.search()` |
| `regex_replace` | Python-Backed | `re.sub()` |
| `regex_split` | Python-Backed | `re.split()` |

#### COLLECTIONS (4 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `array_push` | Python-Backed | `list.append()` |
| `array_pop` | Python-Backed | `list.pop()` |
| `array_sort` | Python-Backed | `sorted()` |
| `array_reverse` | Python-Backed | `reversed()` |

#### SQLITE (14 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `db_open`/`sqlite_open` | Python-Backed | `sqlite3.connect()` |
| `db_close`/`sqlite_close` | Python-Backed | `connection.close()` |
| `db_execute`/`sqlite_execute` | Python-Backed | `connection.execute()` |
| `db_query`/`sqlite_query` | Python-Backed | `fetchall()` returning dicts |
| `db_begin`/`sqlite_begin` | Python-Backed | `BEGIN` SQL |
| `db_commit`/`sqlite_commit` | Python-Backed | `connection.commit()` |
| `db_rollback`/`sqlite_rollback` | Python-Backed | `connection.rollback()` |

#### SYSTEM (17 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `system_hostname` | Python-Backed | `socket.gethostname()` |
| `system_os` | Python-Backed | `platform.system()` |
| `system_arch` | Python-Backed | `platform.machine()` |
| `system_username` | Python-Backed | `os.environ` |
| `system_env` | Python-Backed | `os.environ.get()` |
| `system_cpu_count` | Python-Backed | `os.cpu_count()` |
| `system_memory` | Python-Backed | `/proc/meminfo` (Linux-only) |
| `system_disk` | Python-Backed | `shutil.disk_usage()` |
| `system_uptime` | Python-Backed | `/proc/uptime` (Linux-only) |
| `system_cwd` | Python-Backed | `Path.cwd()` |
| `system_pid` | Python-Backed | `os.getpid()` |
| `system_command_line` | Python-Backed | `sys.argv` |
| `system_home` | Python-Backed | `Path.home()` |
| `system_temp` | Python-Backed | `tempfile.gettempdir()` |
| `system_ppid` | Python-Backed | `os.getppid()` |
| `system_exit` | Python-Backed | `sys.exit()` |
| `system_home` | Python-Backed | `Path.home()` |

#### NETWORK (18 functions) — MIXED

| Registered Name | Classification | Backend |
|----------------|----------------|---------|
| `net_local_ip` | Python-Backed | UDP socket to 8.8.8.8 |
| `net_gateway` | Python-Backed | `/proc/net/route` |
| `net_dns` | Python-Backed | `/etc/resolv.conf` |
| `net_interfaces` | Python-Backed | `socket.if_nameindex()` |
| `net_mac_address` | Python-Backed | `/sys/class/net/*/address` |
| `net_resolve` | Python-Backed | `socket.gethostbyname()` |
| `net_port_check` | Python-Backed | `socket.create_connection()` |
| `net_reverse_resolve` | Python-Backed | `socket.gethostbyaddr()` |
| `net_is_private_ip` | Python-Backed | RFC 1918 string parsing |
| `net_scan_lan` | Python-Backed | `/proc/net/arp` |
| `net_tcp_send` | Python-Backed | `socket.create_connection()` |
| `net_tcp_serve_start` | Python-Backed | `threading` + `socket` |
| `net_tcp_serve_stop` | Python-Backed | event flag + `thread.join()` |
| `net_tcp_serve_wait` | Python-Backed | `thread.join()` |
| `net_udp_send` | Python-Backed | `socket.SOCK_DGRAM` |
| **`net_ping`** | **External-Tool-Backed** | `subprocess.run(["ping", ...])` |
| **`net_local_ips`** | **External-Tool-Backed** | `subprocess.run(["ip", ...])` |
| **`net_dns_servers`** | **External-Tool-Backed** | `subprocess.run(["nmcli"] / ["resolvectl"])` |
| **`net_neighbors`** | **External-Tool-Backed** | `subprocess.run(["ip", "neigh"] / ["arp"])` |
| **`tcp_connect`** | **Host-Backed** | ctypes/libc native socket + Python socket fallback |
| `tcp_banner` | Python-Backed | Python socket module only |
| `net_primary_ip` | Python-Backed | UDP socket to 1.1.1.1 + fallback |
| `host_capability_available` | Python-Backed | Host ABI registry query |
| `host_list_capabilities` | Python-Backed | Host ABI registry query |
| `host_error_message` | Python-Backed | Host ABI error lookup |

#### AI (5 functions) — 3 Python-Backed + 2 Placeholder

| Registered Name | Classification | Justification |
|----------------|----------------|---------------|
| `ai_supported_providers` | Python-Backed | Returns hardcoded list of provider names |
| `ai_provider_available` | Python-Backed | Checks environment variables only |
| **`ai_mock_chat`** | **Placeholder** | Returns `"PantherAI mock response: " + prompt` — hardcoded mock, no real AI call |
| `ai_available_providers` | Python-Backed | Filters supported by env var check |
| **`ai_chat`** | **Placeholder** | Defaults to mock; even with "real" provider, returns `[PantherAI provider] response to: ...` — never calls HTTP API |

#### DATA / SERIALIZATION (8 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `datetime_now` | Python-Backed | `datetime.now().isoformat()` |
| `datetime_format` | Python-Backed | `strftime()` |
| `datetime_parse` | Python-Backed | `fromisoformat()` |
| `csv_parse` | Python-Backed | `csv.reader()` |
| `csv_stringify` | Python-Backed | manual delimiter join |
| `csv_parse_objects` | Python-Backed | `csv.reader()` with header zip |
| `url_encode` | Python-Backed | `urllib.parse.quote()` |
| `url_decode` | Python-Backed | `urllib.parse.unquote()` |

#### STORAGE (6 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `storage_open` | Python-Backed | `Path.mkdir()` |
| `storage_put` | Python-Backed | key-value file write |
| `storage_get` | Python-Backed | key-value file read |
| `storage_exists` | Python-Backed | key file existence |
| `storage_delete` | Python-Backed | key file unlink |
| `storage_list` | Python-Backed | directory walk with prefix |

#### OBSERVABILITY (5 functions) — ALL Python-Backed

| Registered Name | Classification | Python Source |
|----------------|----------------|---------------|
| `log_set_level` | Python-Backed | global level set + validation |
| `log_debug` | Python-Backed | message format + timestamp |
| `log_info` | Python-Backed | message format + timestamp |
| `log_warn` | Python-Backed | message format + timestamp |
| `log_error` | Python-Backed | message format + timestamp |

---

## 4. Stub / Placeholder / Fake Inventory

### 4.1 Compiler Pipeline

| Location | SeverITY | Description |
|----------|----------|-------------|
| `compiler/runtime/statement_executor.py:280-281` | **Minor** | `_execute_trait_declaration()` — `pass` body. Traits parsed but not executed at runtime. |
| `compiler/database/orm.py:10-17` | **Moderate** | `DatabaseEngine` abstract base — all methods raise `NotImplementedError`. Only `SqliteEngine` is concrete. |
| `compiler/ai/providers.py:23-27` | **Moderate** | `AIProvider` abstract base — `complete()` and `embed()` raise `NotImplementedError`. All 5 providers have mock fallbacks returning `"[mock]..."` strings. |
| `compiler/pipeline/panther_compiler.py:173-180` | **Minor** | `AgentDecl`, `MemoryDecl`, `PackageDecl`, `IntentDecl` — parsed but stored as raw source strings, no meaningful processing. |
| `compiler/parser/program_parser.py:93-101` | **Low** | `parse_placeholder_block()` — legacy name, fully delegates to `BlockParser`. |
| `compiler/incremental/incremental_compiler.py` | **Experimental** | 32-line minimal script — not integrated into any pipeline. |

### 4.2 Runtime Directory (Higher-Level Scaffolds)

| Location | SeverITY | Description |
|----------|----------|-------------|
| `runtime/panther_vm/vm.py:20-27` | **High** | `PantherVM.execute_source()` returns hardcoded `"PantherVM scaffold accepted source"` — complete scaffold/stub. |
| `runtime/sandbox/sandbox.py:16-22` | **High** | `SandboxRuntime.execute()` returns hardcoded dict — stub, no actual execution. |
| `runtime/agents/agent.py:39-50` | **High** | `PantherAgent.execute()` always returns `{"ok": True}` — deterministic stub. |
| `runtime/ai_runtime/ai_runtime.py:43-51` | **High** | `PantherAIRuntime.execute()` always returns `{"ok": True}` — deterministic stub. |

### 4.3 CLI / Toolchain

| Location | SeverITY | Description |
|----------|----------|-------------|
| `toolchain/cross_platform/cross_platform_toolchain.py` | **High** | Generates trivial `echo` scripts — no real cross-compilation. Self-describes as stub. |
| `toolchain/final/final_toolchain.py` | **High** | Integration check references 3 non-existent paths; always fails. |
| `native_executables/native_builder.py` | **High** | Self-described as "launcher wraps Panther CLI until H2 binary compiler packaging matures" — generates shell wrappers, not native executables. Directory name is misleading. |
| `production/production_manifest.json` | **Moderate** | References phase 6.20 (codebase at 1.1.6). Narrative-only capabilities. |
| `stable/stable_manifest.json` | **Moderate** | References version 1.0.0-rc1 (codebase at 1.1.6). References non-existent `release_engineering`. |
| `package_manager/package_manager.py` vs `package_cli.py` | **Medium** | Duplicate `PackageManager` class (52 lines identical) — refactoring artifact. |
| `package_manager/package_manager.py` / `package_cli.py` | **Medium** | `local_registry` directory referenced but never populated — dead code path. |

### 4.4 Tools Directory

| Location | SeverITY | Description |
|----------|----------|-------------|
| `tools/debugger/panther_debugger.py` | **High** | Line-based debugger with no DAP integration, no runtime connection. |
| `tools/docgen/panther_docgen.py` | **High** | 30-line stub wrapping source in MD template. |
| `tools/formatter/panther_fmt.py` | **High** | 19-line stub doing basic line stripping — no AST-based formatting. |
| `tools/panther-ide/` | **High** | Minimal VSCode extension with LSP restart command — stub-level. |
| `tools/panther-lsp/panther_lsp/` | **Medium** | Functional but minimal LSP — JSON-RPC framing, basic analyzer. Production-ready? No. |
| `tools/panther-toolchain/` | **Medium** | Functional but stub-level cross-platform build toolchain. |

### 4.5 Benchmarks / Fuzz / Stress

| Location | SeverITY | Description |
|----------|----------|-------------|
| `benchmarks/panther_benchmark.py` | **High** | 39-line stub measuring build time of a 1-line program. Not representative. |
| `fuzz_tests/panther_fuzzer.py` | **High** | 62-line stub — 5 token patterns, 25 seeds, no coverage guidance. |
| `stress_tests/stress_runner.py` | **High** | 41-line stub — generates 200 trivial print statements. No profiling. |
| `_conformance_test/` | **High** | Empty directory — conformance test placeholder. |

### 4.6 Debug Adapter

| Location | SeverITY | Description |
|----------|----------|-------------|
| `debug_adapter_rebuilt/` | **Moderate** | Canonical rebuild target — complete but unused. All imports route here via `debug_adapter_bridge/` but active runtime uses `debug_adapter/`. |
| `debug_adapter_bridge/` | **Moderate** | 18 single-line re-export stubs — pure compatibility shim. |

### 4.7 Stale / Duplicate Code

| Location | SeverITY | Description |
|----------|----------|-------------|
| `vscode_extension/` | **High** | Legacy VS Code extension (v1.0.0) — superseded by `vscode-extension/` v1.1.6. |
| `templates/` | **Moderate** | Legacy template sources — superseded by `project_templates/`. |
| `language/` | **Moderate** | Second complete copy of compiler/tooling (158 `.py`, 20 `.panther`, 24 tests). Duplicates `compiler/`, `runtime/`, `stdlib/`, etc. in Panther-type-definition form. |

---

## 5. Two-Compiler-Pipeline Problem

The codebase contains **two coexisting compiler pipelines**:

| Aspect | Formal Pipeline (Primary) | Phase 6 Pipeline (Legacy) |
|--------|--------------------------|---------------------------|
| Location | `compiler/lexer/`, `compiler/parser/`, `compiler/ast/`, `compiler/semantic/`, `compiler/types/`, `compiler/runtime/` | `compiler/pipeline/`, `compiler/expressions/`, `compiler/control_flow/`, `compiler/loops/`, `compiler/functions/`, `compiler/structs/`, `compiler/modules/`, `compiler/optimization/` |
| Lexer | Character-based `PantherLexer` | Regex-based `TOKEN_RE` |
| Parser | Pratt + recursive descent with full AST | Line-based, dict-based AST |
| Runtime | Tree-walking interpreter | Bash shell script output |
| CLI entry | `cli/panther_cli.py` | `cli/panther_cli_v2.py` |
| Output | Python objects / CLI execution | Shell scripts |
| Status | **Active, maintained** | **Legacy, Phase 6** |

Both pipelines pass tests. The legacy Phase 6 pipeline has a separate runtime bridge (`compiler/runtime_bridge/`) that shells out to execute generated bash scripts.

Additionally, the `language/` directory contains a **third representation** of the compiler pipeline in Panther type-definition form (`.panther` files).

---

## 6. Self-Host Stdlib Status

| File | Lines | Functions | Domain |
|------|-------|-----------|--------|
| `stdlib/selfhost/address.pan` | 42 | 3 | Network IP validation |
| `stdlib/selfhost/discovery.pan` | 62 | 5 | Network discovery utilities |
| `stdlib/selfhost/discovery_engine.pan` | 119 | 7 | Network discovery engine |
| `stdlib/selfhost/network.pan` | 138 | 7 | Network classification/security |
| `stdlib/selfhost/policy.pan` | 47 | 4 | Network policy/authorization |
| `stdlib/selfhost/services.pan` | 465 | 8 | Port-to-service mapping (200 ports) |
| **Total** | **873** | **~34** | **Network security domain only** |

**All 34 self-host functions call into Python-Backed host primitives** (`tcp_connect`, `split`, `len`, `to_int`, `array_push`, `time_now`, etc.). They represent the first layer of the self-hosting onion: Panther wrappers around Python stdlib primitives.

---

## 7. Architecture Decisions Still Pending

Based on stub/placeholder analysis, these architectural decisions remain:

1. **Trait Runtime Execution** — `_execute_trait_declaration` is `pass`. Traits are parsed and semantically validated but never executed. Decision needed: how do trait methods dispatch at runtime?

2. **AI Provider Integration** — All 5 AI providers have mock fallbacks. The AI system never actually calls OpenAI/Anthropic/Gemini APIs. Decision needed: real HTTP integration or remain Panther-level abstraction?

3. **Database Abstraction** — `DatabaseEngine` base class is pure abstract; only `SqliteEngine` exists. Decision needed: support additional databases (PostgreSQL, MySQL)?

4. **Cross-Platform Native Binaries** — `native_executables/` generates shell script launchers, not compiled binaries. `toolchain/cross_platform/` generates trivial `echo` scripts. Decision needed: true binary compilation or remain Python-interpreted?

5. **Debug Adapter Unification** — `debug_adapter/` (production) vs `debug_adapter_rebuilt/` (canonical target) coexist with a bridge layer. Decision needed: complete the atomic swap?

6. **Language Directory Duplication** — `language/` contains 158 `.py` files + 20 `.panther` files duplicating compiler/tooling. Decision needed: archive or integrate?

7. **Self-Host Expansion** — Only 6 `.pan` files exist covering the network domain. Decision needed: which stdlib domains to self-host next?

8. **Optimizer Integration** — `optimizer/` is a prototype not connected to the compiler pipeline. Decision needed: integrate or discard?

9. **LSP / Formatter / DocGen** — All three are stub-level. Decision needed: invest in production-quality tooling?

10. **Incremental Compilation** — 32-line experimental file, not integrated. Decision needed: invest or discard?

---

## 8. Summary

### What PantherLang IS:

- A **pure-Python tree-walking interpreter** for the Panther language
- **96% of stdlib (168/175 functions) is Python-Backed** — calls directly into Python standard library
- **4 functions require external tools** (ping, ip, nmcli, arp) via subprocess
- **1 function is Host-Backed** (tcp_connect via ctypes/libc)
- **2 functions are Placeholders** (AI mock chat functions)
- **6 self-host .pan files** exist (873 lines, network security domain only)
- **0 native compiled extensions** exist anywhere in the repository
- **0 C/C++/Rust source files** exist anywhere in the repository
- **45+ identifiable stubs/placeholders** across the codebase
- **Two compiler pipelines** coexist (formal + Phase 6 legacy)
- **10 pending architectural decisions** need resolution

### What PantherLang is NOT (yet):

- NOT a self-hosted language (0% of stdlib is Panther-Implemented in core domains)
- NOT a natively compiled language (no native executables, no compiler backend for machine code)
- NOT independent of Python (the entire runtime is a Python program calling Python stdlib)
- NOT production-ready for AI workloads (AI providers are all mock stubs)
- NOT production-ready for cross-platform distribution (native_executables generate shell wrappers)
- NOT a unified codebase (language/ duplicates compiler/, two debug adapter implementations, two CLIs)

The General-Purpose Independence Program must address all of these gaps systematically, phase by phase.

---

*End of Phase 0 Audit Report. Baseline: 1268 tests passing, 0 failing. Next: Phase planning.*
