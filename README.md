# PantherLang

An independent, general-purpose programming-language project for secure, AI-aware, multi-domain software engineering.

PantherLang combines its own language syntax, parser, semantic analysis, runtime architecture, package system, standard library, CLI, VS Code tooling, security diagnostics, and machine-readable developer knowledge in one evolving ecosystem.

**Current release:** v1.1.8
**Founder:** Feras Khatib

**Build Anything. In Panther.**

---

## What PantherLang Is

PantherLang is an independent, general-purpose programming-language project with executable `.pan` and `.panther` programs, its own syntax and language rules, a parser/runtime pipeline, a global CLI, standard-library capabilities, AI-facing functions, security diagnostics, web/API and database work, VS Code integration, formal specifications, structured education, and machine-readable language knowledge.

Its distinguishing idea is not that it owns a longer checklist than established languages. The distinction is architectural: **PantherLang is exploring whether language execution, AI integration, security feedback, application surfaces, developer tooling, education, and AI-readable knowledge can be engineered as cooperating parts of one language ecosystem.**

That is a research-and-engineering direction, not a claim that every subsystem has identical maturity. This README therefore separates what is implemented today from what is evolving and what still requires release-specific verification.

PantherLang is not presented as a replacement for Python, Rust, Go, JavaScript, TypeScript, Java, C#, C++, or other established languages. Those ecosystems represent decades of engineering and solve important problems.

PantherLang explores a different integration thesis:

> **What should a programming language look like when AI assistants, software agents, security analysis, machine-readable documentation, and multi-surface application development are treated as normal parts of the developer environment rather than unrelated add-ons?**

That question is the center of the project.

---

## Why PantherLang Exists

Modern development is powerful, but fragmented.

A single application may require:
- a language and runtime;
- a web framework;
- an AI SDK;
- a database layer;
- security scanners;
- editor extensions;
- separate documentation for humans;
- separate context files for coding agents;
- separate learning material that may drift away from implementation.

PantherLang explores a more coherent architecture in which these layers can evolve together:
- **language semantics**;
- **runtime execution**;
- a unified **`panther` CLI**;
- **AI integration** callable from PantherLang programs;
- **security diagnostics** in the development workflow;
- **web and API execution**;
- **database operations**;
- **editor integration**;
- **formal language documentation**;
- **Academy lessons, labs, examples, and an official book**;
- **machine-readable knowledge** for AI coding systems.

The goal is not to hide complexity behind marketing. The goal is to make the boundaries between these systems more explicit, testable, and coherent.

---

## What Changed in v1.1.8

**Version alignment:** All components (core, CLI, compiler, VS Code extension, debug adapter) now report 1.1.8 consistently.

**Standard Library 2.0 package architecture:** 25 organized `panther.*` packages with verified imports, each exposing public PantherLang functions. Packages include: `panther.core`, `panther.math`, `panther.text`, `panther.net`, `panther.database`, `panther.crypto`, `panther.json`, `panther.time`, `panther.collections`, `panther.files`, `panther.http`, `panther.ai`, `panther.security`, `panther.logging`, `panther.system`, `panther.testing`, `panther.storage`, `panther.serialization`, `panther.cli`, `panther.web`, `panther.net`, `panther.cloud`, `panther.container`, `panther.process`, `panther.concurrent`, `panther.async`.

**Multi-package import example verified:** The README showcase program imports 6 packages and executes successfully through `panther check` and `panther run`.

**New package:** `panther.serialization` with JSON, YAML, TOML, MessagePack, CBOR, Base64, Hex, and CSV encode/decode APIs.

**Improved:** import parsing, namespace resolution, package member-call evaluation, semantic package registration, function-literal parameter handling, return propagation, array/dictionary index assignment, short-circuit Boolean evaluation, runtime error propagation, package naming consistency, standard-library loading.

**Fixed:** duplicate flat built-in registrations, `array_push` return contract, CLI parsing structure, time naming conflicts, package alias semantic collisions, runtime errors swallowed inside control-flow bodies.

**Verification:** README showcase passes `panther check` and `panther run`; VSIX builds successfully; package metadata aligned to 1.1.8; zero production secrets; generated artifacts excluded.

---

## Language Architecture

### Core Language (v1.1.8)
- **Variables:** `let` with type inference, optional type annotations (`let x: int = 42`)
- **Functions:** `fn` with recursion, closures, parameters, return types
- **Control flow:** `if/elif/else`, `while`, `for i in 1..10`, `loop`, `break/continue`
- **Data types:** int, float, string, bool, null, any; struct, enum, trait
- **Collections:** Arrays (`[1, 2, 3]`), objects/dicts (`{x: 1, y: 2}`), indexing (`arr[0]`, `obj["key"]`)
- **Type system:** Primitive types, inference, annotations, compatibility checks (T001)
- **Semantic analysis:** Symbol tables, scope resolution, duplicate detection (E001-E008)
- **Security diagnostics:** S001-S005 run during linting

### Compiler Pipeline
```
Source → Lexer → Token Stream → Parser → AST
      → Semantic Analysis → Type Check → Runtime → Output
```
- **Parser:** Pratt expression parser + recursive descent statement parser, error recovery
- **AST:** Frozen dataclass nodes
- **Runtime:** Tree-walking interpreter with Host ABI for stdlib

---

## Package System

PantherLang now supports organized package imports:

```panther
panther main {
    import panther.core as core;
    import panther.math as math;
    import panther.text as text;
    import panther.net as net;
    import panther.database as db;
    import panther.crypto as crypto;

    let absolute_value = math.abs(-42);
    let message = text.trim("  PantherLang  ");
    let local_address = net.local_ip();
    let connection = db.open(":memory:");
    let digest = crypto.sha256("PantherLang");

    print message;
    print core.to_string(absolute_value);
    print local_address;
    print digest;

    db.close(connection);
}
```

**Verified:** This exact program passes `panther check` and `panther run` in v1.1.8.

**Package discovery:** Packages live in `stdlib/panther/<name>/__init__.pan`. Each `__init__.pan` contains public `fn panther_<package>_<function>` exports that are registered at load time.

**Namespace resolution:** Imports create aliases (`import panther.math as math`). Calls use the alias (`math.abs(-42)`). The runtime resolves package members through the Host ABI.

---

## Standard Library 2.0

| Package | Purpose | Maturity | Primary Implementation | Example API |
|---------|---------|----------|----------------------|-------------|
| `panther.core` | Type conversion, predicates, validation, I/O, Option/Result helpers | VERIFIED_EXECUTABLE | Panther (Host ABI) | `to_string`, `is_int`, `validate_type`, `println`, `some`, `ok` |
| `panther.math` | Arithmetic, rounding, random, statistics, constants, integer math | VERIFIED_EXECUTABLE | Panther (Host ABI) | `abs`, `min`, `max`, `pow`, `sqrt`, `random`, `sum`, `mean`, `stddev` |
| `panther.text` | String manipulation, search, case, formatting, encoding | VERIFIED_EXECUTABLE | Panther (Host ABI) | `trim`, `split`, `join`, `contains`, `replace`, `upper`, `format`, `base64_encode` |
| `panther.net` | Network config, DNS, port check, TCP/UDP, IP classification, risk scoring | VERIFIED_EXECUTABLE | Panther (Host ABI) | `local_ip`, `resolve`, `port_check`, `tcp_connect`, `ping`, `risk_score` |
| `panther.database` | SQLite open/close, execute, query, transactions, prepared statements, schema | VERIFIED_EXECUTABLE | Panther (Host ABI) | `open`, `close`, `execute`, `query`, `query_one`, `transaction` |
| `panther.crypto` | Hashing (SHA256/512, MD5), HMAC, secure random, UUID, constant-time compare, encoding, password hashing | VERIFIED_EXECUTABLE | Panther (Host ABI) | `sha256`, `hmac_sha256`, `secure_token`, `uuid`, `secure_compare`, `base64_encode`, `hash_password` |
| `panther.json` | Parse, stringify, pretty, validate, path query, type checks | VERIFIED_EXECUTABLE | Panther (Host ABI) | `parse`, `stringify`, `pretty`, `valid`, `get`, `is_object` |
| `panther.time` | Current time, sleep, formatting, parsing, components, durations, comparison | VERIFIED_EXECUTABLE | Panther (Host ABI) | `now`, `sleep`, `format`, `parse`, `year`, `month`, `diff`, `format_duration` |
| `panther.collections` | Array operations: len, push, pop, get, set, contains, index_of, reverse, sort, map, filter, reduce, join, concat, flatten, range | VERIFIED_EXECUTABLE | Panther (Host ABI) | `array_len`, `array_push`, `array_pop`, `array_map`, `array_filter`, `array_reduce`, `range` |
| `panther.files` | Read/write/append, exists, mkdir, copy/move/remove, list, cwd, path utils, stat, walk | VERIFIED_EXECUTABLE | Panther (Host ABI) | `read`, `write`, `exists`, `mkdir`, `listdir`, `cwd`, `join`, `walk` |
| `panther.http` | GET/POST/PUT/DELETE, structured fetch, JSON helpers, status classification | VERIFIED_EXECUTABLE | Panther (Host ABI) | `get`, `post`, `put`, `delete`, `fetch`, `get_json`, `post_json`, `status_ok` |
| `panther.ai` | Provider abstraction, message building, chat completion, streaming, structured output, tool calling, timeout/retry, usage, injection detection, audit, approval, provider availability, mock provider | PANTHER_IMPLEMENTED | Panther (Host ABI + Python bootstrap) | `provider`, `model`, `chat`, `chat_stream`, `structured_output`, `tool`, `detect_injection`, `available_providers`, `mock_chat` |
| `panther.security` | Secret detection, redaction, input validation, SQL/HTML/path/shell sanitization, policy engine, audit logging, rate limiting, CORS, security headers | VERIFIED_EXECUTABLE | Panther (Host ABI) | `audit_secrets`, `redact_secrets`, `validate_email`, `sanitize_sql`, `sanitize_path`, `audit_log`, `rate_limit_check` |
| `panther.logging` | Debug/info/warn/error, structured logging, formatted logging, level constants | VERIFIED_EXECUTABLE | Panther (Host ABI) | `debug`, `info`, `warn`, `error`, `log`, `debugf`, `infof`, `LEVEL_INFO` |
| `panther.system` | Hostname, OS, arch, username, env, CPU, memory, disk, uptime, cwd, PID, command line, home, temp, exit | VERIFIED_EXECUTABLE | Panther (Host ABI) | `hostname`, `os`, `arch`, `env`, `cpu_count`, `memory`, `uptime`, `pid`, `home` |
| `panther.testing` | Test framework: test, test_eq, test_ne, test_true, test_false, test_null, test_not_null, test_contains, test_throws, run_suite | VERIFIED_EXECUTABLE | Panther | `test`, `test_eq`, `test_true`, `run_suite` |
| `panther.storage` | Key-value store: open, put/get/exists/delete, list, JSON helpers, batch ops, prefix ops, collections, TTL | VERIFIED_EXECUTABLE | Panther (Host ABI) | `open`, `put`, `get`, `exists`, `delete`, `list`, `put_json`, `get_json`, `collection` |
| `panther.serialization` | JSON, YAML, TOML, MessagePack, CBOR, Base64, Hex, CSV encode/decode, universal interface, streaming | VERIFIED_EXECUTABLE | Panther (Host ABI + Python bootstrap for non-JSON) | `encode`, `decode`, `encode_with_options`, `stream_encode`, `json_encode`, `yaml_encode` |
| `panther.cli` | Argument parsing, flag/option/positional access, help generation, version, exit codes, progress bar, ANSI colors | VERIFIED_EXECUTABLE | Panther | `parse`, `get_flag`, `get_option`, `get_positional`, `usage`, `progress_bar`, `color_red` |
| `panther.web` | Server creation, route registration (GET/POST/PUT/DELETE), middleware, static files, start/stop, response helpers, request accessors, error handlers, CORS, health check | PANTHER_IMPLEMENTED | Panther (Host ABI + Python bootstrap) | `server_create`, `get`, `post`, `use`, `static`, `start`, `stop`, `response_json`, `request_param` |
| `panther.cloud` | Provider abstraction (AWS/GCP/Azure), service descriptors (S3, Lambda, DynamoDB, etc.), deploy, scale, logs, metrics, multi-cloud utilities | API_SHAPE_ONLY | Panther (data structures only) | `provider`, `service`, `aws_s3_bucket`, `gcp_storage`, `deploy`, `available_providers` |
| `panther.container` | Image management (build, pull, push, tag, inspect, history), lifecycle (run, start, stop, restart, pause, remove, kill), inspection (ps, logs, exec, stats, top, port), volumes, networks, compose, registry, health, resources | API_SHAPE_ONLY | Panther (data structures only) | `image`, `build`, `run`, `start`, `stop`, `ps`, `logs`, `exec`, `volume_create`, `network_create`, `compose_up` |
| `panther.process` | Process execution (run, spawn, kill, wait), current process info (PID, PPID, env, cwd, argv, exe) | PARTIAL | Panther (Host ABI for current process only) | `run`, `spawn`, `self_pid`, `self_cwd`, `self_env` |
| `panther.concurrent` | Worker pool (spawn, join, cancel, status, result, error), queues, map/filter/reduce/for_each, wait groups, semaphores, mutex, channels, promises, all/race, timeout | PYTHON_BOOTSTRAP_BACKED | Python bootstrap (`_concurrent_*`) | `spawn`, `join`, `worker_count`, `queue_create`, `map`, `wait_group`, `semaphore`, `mutex`, `channel`, `promise` |
| `panther.async` | Task execution (task, run, await, await_timeout, sleep, gather, race, retry, cancel, status), iterators (range, map, filter, reduce, for_each), timeout, debounce, throttle, memoize, circuit breaker | PYTHON_BOOTSTRAP_BACKED | Python bootstrap (`_async_*`) | `task`, `run`, `await_task`, `sleep`, `gather`, `retry`, `map`, `filter`, `debounce`, `circuit_breaker` |
| `panther.testing` | See above | | | |

**Maturity labels:**
- **VERIFIED_EXECUTABLE** — Package imports, all public functions execute and return expected results via `panther run`
- **PANTHER_IMPLEMENTED** — Package imports, core APIs are Panther functions calling Host ABI; some provider integrations are simulated
- **PYTHON_BOOTSTRAP_BACKED** — Package imports, but core async/concurrent primitives delegate to Python runtime (`_async_*`, `_concurrent_*`)
- **API_SHAPE_ONLY** — Package imports and returns data structures; no live backend integration
- **PARTIAL** — Current-process introspection works; subprocess execution not implemented

---

## Multi-Package Example (Verified)

The following program imports 6 packages and is the official README showcase. It passes `panther check` and `panther run`:

```panther
panther main {
    import panther.core as core;
    import panther.math as math;
    import panther.text as text;
    import panther.net as net;
    import panther.database as db;
    import panther.crypto as crypto;

    let absolute_value = math.abs(-42);
    let message = text.trim("  PantherLang  ");
    let local_address = net.local_ip();
    let connection = db.open(":memory:");
    let digest = crypto.sha256("PantherLang");

    print message;
    print core.to_string(absolute_value);
    print local_address;
    print digest;

    db.close(connection);
}
```

**Output:**
```
PantherLang
42
10.0.2.15
39988d19b311c1fc348ce81980356a96941990e8aea89a6564464846b1feab0a
```

**Location:** `examples/stdlib2_readme_showcase/main.pan`

---

## Network Example

```panther
panther main {
    import panther.net as net;
    import panther.http as http;
    import panther.json as json;

    // Local network info
    let ip = net.local_ip();
    let interfaces = net.interfaces();
    let dns = net.dns();

    // HTTP request
    let response = http.get("https://api.github.com/users/octocat");
    let data = json.parse(response.body);

    print "Local IP: " + ip;
    print "GitHub user: " + data["login"];
}
```

---

## Web/API Status

**Implemented:** HTTP server creation, route registration (GET/POST/PUT/DELETE), middleware, static file serving, start/stop, response helpers (JSON, HTML, text, error, redirect), request accessors (params, query, body, headers, method, path), error handlers, CORS, health check endpoint.

**Maturity:** `panther.web` is `PANTHER_IMPLEMENTED` — the server runs via `panther run --serve`, routes register, requests are handled. Production concerns (TLS termination, static-file strategy, middleware composition, status/header control, deployment topology, protocol edge cases) require individual assessment.

**Example (runnable):**
```panther
panther main {
    import panther.web as web;

    let server = web.server_create("127.0.0.1", 8080);
    server = web.get(server, "/", fn(req) { return web.response_text("Hello PantherLang"); });
    server = web.get(server, "/health", fn(req) { return web.response_json({status: "ok"}); });
    web.start(server);
}
```

Run with: `panther run --serve examples/hello_web/main.pan`

---

## AI Status

**Implemented:** Provider abstraction, message building, chat completion (mock and provider stubs), streaming simulation, structured output simulation, tool/function calling structure, timeout/retry wrappers, usage metadata, prompt injection detection, audit logging, approval gates, provider availability detection via environment variables.

**Maturity:** `panther.ai` is `PANTHER_IMPLEMENTED`. Core APIs are Panther functions. Provider integrations (Ollama, OpenAI, Anthropic, Google) are stubbed — they return structured errors unless mocked. Deterministic mock provider (`panther_ai_mock_chat`) works for testing without credentials.

**Example (runs with mock):**
```panther
panther main {
    import panther.ai as ai;

    let providers = ai.available_providers();
    print "Available: " + core.to_string(providers);

    let model = ai.model(ai.provider("mock"), "mock-model");
    let messages = [ai.user_message("Say hello in 5 words")];
    let result = ai.chat(model, messages, {});
    print "AI: " + result.content;
}
```

---

## Installation

### Linux/macOS
```bash
git clone https://github.com/ferasbackagain/PantherLang.git
cd PantherLang
python -m venv .venv
source .venv/bin/activate
python -m pip install -e .
panther version
panther doctor
```

### Windows PowerShell
```powershell
git clone https://github.com/ferasbackagain/PantherLang.git
cd PantherLang
py -m venv .venv
.\.venv\Scripts\Activate.ps1
py -m pip install -e .
panther version
panther doctor
```

**Note:** PyPI installation is not advertised until the package is published and verified there.

---

## Quick Start

```bash
# Verify installation
panther version
panther doctor

# Write a program (hello.pan)
panther main {
    let language = "PantherLang";
    fn greet(name) { return "Hello from " + name + "!"; }
    print greet(language);
}

# Run it
panther run hello.pan

# Check it
panther check hello.pan

# Create a new project
panther new console myapp
cd myapp
panther run src/main.panther
```

---

## VS Code Extension

**Official extension identity (do not change):**
- **Publisher:** `PantherLang`
- **Extension:** `pantherlang-official`
- **Extension ID:** `PantherLang.pantherlang-official`
- **Target version:** `1.1.8`

**Features:**
- Syntax highlighting for `.pan` and `.panther`
- Run/check commands via command palette
- Project creation wizard (console, web, api, ai)
- Debugger integration (verified to DAP dry-run maturity)
- File icons

**Install from VSIX:**
```bash
cd vscode-extension
npx @vscode/vsce package
# Produces: pantherlang-official-1.1.8.vsix
code --install-extension pantherlang-official-1.1.8.vsix
```

---

## Verification and Test Evidence

**Test suite:** 1,330 tests collected. Run:
```bash
python -m pytest tests/ -q
```

**Expected baseline (v1.1.8):** 1,330 passed, 0 failed, 0 errors.

**CLI verification:**
```bash
panther version
# PantherLang 1.1.8 (PantherLang v1.1.8)
# Channel: stable
# Debug Adapter: 1.1.8

panther doctor
# All components OK

panther check examples/stdlib2_readme_showcase/main.pan
# check passed

panther run examples/stdlib2_readme_showcase/main.pan
# PantherLang
# 42
# 10.0.2.15
# 39988d19b311c1fc348ce81980356a96941990e8aea89a6564464846b1feab0a
```

**Example test run:**
```bash
bash scripts/run_examples.sh
```

---

## Package Maturity

| Package | Maturity | Notes |
|---------|----------|-------|
| core, math, text, net, database, crypto, json, time, collections, files, http, security, logging, system, testing, storage, serialization, cli | VERIFIED_EXECUTABLE | All public functions execute via `panther run` |
| ai, web | PANTHER_IMPLEMENTED | Core APIs work; provider/server backends are stubbed or simulated |
| cloud, container | API_SHAPE_ONLY | Data structures only; no live backend |
| process | PARTIAL | Current-process introspection works; subprocess execution not implemented |
| concurrent, async | PYTHON_BOOTSTRAP_BACKED | Delegates to Python runtime for concurrency primitives |

**Do not assume** every package is production-ready merely because imports succeed. Maturity labels above are based on implementation inspection and test verification.

---

## Architecture Honesty

**PantherLang is an independent programming-language project.**
**Application source is written in PantherLang.**
**Standard Library 2.0 exposes PantherLang package APIs.**
**A significant portion of package orchestration is implemented in `.pan`.**
**Host access is provided through runtime/Host ABI capabilities.**
**Some current backends still use Python as bootstrap/runtime infrastructure.**
**The compiler is not yet fully self-hosted.**
**Current distributable artifacts are not all Python-free native binaries.**

Implementation independence is increasing release by release.

**Avoid these claims unless proven:**
- zero Python dependency
- fully native compiler
- fully self-hosted compiler
- every package is production-ready
- every type of application can already be built without limitations

---

## Current Limitations

- **Web server:** No TLS, limited middleware composition, no production deployment tooling
- **Async/Concurrency:** Primitives delegate to Python; no true preemptive multitasking in Panther runtime
- **AI providers:** All external providers return structured errors; only mock provider works without credentials
- **Cloud/Container:** Data-structure APIs only; no actual AWS/GCP/Azure/Docker daemon calls
- **Process execution:** Subprocess spawning not implemented
- **Self-hosting:** Compiler and parts of runtime remain in Python
- **Type system:** Static and runtime diagnostics coexist; advanced unification incomplete
- **Package ecosystem:** No public package registry; all packages are built-in

---

## Roadmap

- **v1.2:** Self-hosted parser in PantherLang, expanded type system, native codegen exploration
- **v1.3:** True async runtime in Panther, HTTP server production hardening, SQLite ORM completion
- **v2.0:** Package registry, incremental compilation, language server protocol completion

Roadmap items are engineering directions, not commitments.

---

## Documentation and Academy

- **Academy (18 lessons):** `academy/` — start here for progressive learning
- **Official Book (18 chapters):** `docs/book/` — deep reference
- **Formal Specification (8 docs):** `docs/specification/` — lexical, grammar, semantics, types, runtime, diagnostics
- **Cookbook:** `docs/cookbook/` — recipe-oriented examples
- **Runnable Examples:** `examples/` — 6 runnable apps + 68 phase demo files
- **AI Knowledge Pack:** `llms.txt`, `llms-full.txt`, `LANGUAGE_RULES.md`, `AI_CONTEXT.md`, `LLM_REFERENCE.md`, `knowledge/`
- **Package Index:** `docs/stdlib2/PACKAGE_INDEX.md` — every package and its public API index
- **Package Maturity:** `docs/stdlib2/PACKAGE_MATURITY.md` — maturity level definitions
- **Architecture Status:** `docs/stdlib2/ARCHITECTURE_STATUS.md` — Panther, Host ABI, native, Python bootstrap responsibilities
- **Quick Start:** `docs/stdlib2/QUICK_START.md` — working package examples

---

## Contributing

Before changing language behavior:
1. Inspect current language rules and specification
2. Identify the canonical implementation path
3. Run relevant tests
4. Preserve existing semantics unless a change is intentionally designed
5. Add executable evidence for new behavior
6. Update examples and documentation when semantics change
7. Avoid calling a feature "complete" solely because a directory or parser node exists

Contributions that improve reproducibility, platform verification, implementation clarity, tests, examples, documentation, and independent evaluation are especially valuable.

---

## Founder and Links

**Feras Khatib**
Founder and Project Lead of PantherLang — identified at the top of this README because project authorship and accountability should be visible, not buried.

- **LinkedIn:** https://www.linkedin.com/in/feras-khatib-98a02220b
- **Repository:** https://github.com/ferasbackagain/PantherLang

Project identity remains verifiable. This README does not invent awards, adoption numbers, partnerships, certifications, or affiliations.

---

## License

PantherLang is distributed under the terms in [LICENSE](./LICENSE).

Review the license before use, redistribution, modification, or commercial deployment.

---

## Citation and Discovery

**Project:** PantherLang programming language
**Founder:** Feras Khatib
**Current release line:** v1.1.8
**Repository:** https://github.com/ferasbackagain/PantherLang
**Founder profile:** https://www.linkedin.com/in/feras-khatib-98a02220b

---

*PantherLang is being built for a world in which software is written by people, assisted by AI, inspected by security systems, executed across application surfaces, and increasingly understood by machines.*