# PantherLang Standard Library 2.0 — Package Maturity

This document defines the maturity classification system used in `PACKAGE_INDEX.md` and explains what each label means for production readiness.

---

## Maturity Levels

### VERIFIED_EXECUTABLE
**Definition:** The package imports successfully, all public functions execute via `panther run`, and return semantically correct results. Tests exist and pass.

**What this means for you:**
- Safe to use in production PantherLang programs
- Functions behave as documented
- Covered by regression tests

**Packages:** `core`, `math`, `text`, `net`, `database`, `crypto`, `json`, `time`, `collections`, `files`, `http`, `security`, `logging`, `system`, `testing`, `storage`, `cli`

---

### PANTHER_IMPLEMENTED
**Definition:** The package imports and exposes PantherLang functions. Core APIs are implemented as Panther functions calling Host ABI. External provider integrations (AI, web server) return structured errors or simulated responses — they do not perform live I/O without credentials/configuration.

**What this means for you:**
- PantherLang API surface is stable
- Live backend calls require provider setup and are not guaranteed to work without credentials
- Mock/test modes work for development

**Packages:** `ai`, `web`

---

### PYTHON_BOOTSTRAP_BACKED
**Definition:** The package imports and exposes PantherLang functions, but the core primitives delegate to Python runtime functions (`_async_*`, `_concurrent_*`). True preemptive multitasking, async/await semantics, and concurrent execution are not implemented in the Panther runtime.

**What this means for you:**
- APIs are available for code structure and testing
- Actual concurrency/async behavior runs on Python event loop
- Not suitable for production workloads requiring true parallelism
- May block the Panther interpreter during long operations

**Packages:** `concurrent`, `async`

---

### API_SHAPE_ONLY
**Definition:** The package imports and returns data structures (objects with expected fields). No live backend integration exists. Functions return mock/default values.

**What this means for you:**
- Useful for designing interfaces and type-safe code
- Cannot be used for actual cloud/container/process operations
- Intended for future implementation

**Packages:** `cloud`, `container`, `process`

---

### PARTIAL
**Definition:** Some functions work (typically introspection of the current process), but core capability (subprocess execution) is not implemented.

**What this means for you:**
- Current-process inspection (`self_pid`, `self_cwd`, etc.) works
- Process spawning/execution returns "not supported" errors

**Packages:** `process`

---

## Decision Matrix

| Question | VERIFIED_EXECUTABLE | PANTHER_IMPLEMENTED | PYTHON_BOOTSTRAP_BACKED | API_SHAPE_ONLY | PARTIAL |
|----------|---------------------|---------------------|-------------------------|----------------|---------|
| Import works? | ✅ | ✅ | ✅ | ✅ | ✅ |
| Functions return real results? | ✅ | ✅ (core) | ⚠️ (delegates to Python) | ❌ (mocks) | ⚠️ (some) |
| Safe for production logic? | ✅ | ✅ (with caveats) | ⚠️ (blocking) | ❌ | ⚠️ |
| Live I/O without setup? | ✅ | ❌ | N/A | ❌ | ❌ |
| Covered by tests? | ✅ | ✅ | ⚠️ (limited) | ❌ | ❌ |

---

## How Maturity Is Determined

1. **Import verification:** `import panther.<name>` succeeds
2. **Function enumeration:** All `panther_<name>_<function>` exports are callable
3. **Execution test:** Each function invoked via `panther run` with valid inputs
4. **Result validation:** Outputs match expected types and semantics
5. **Test coverage:** Existing test suite exercises the package
6. **Backend inspection:** Implementation reviewed for Host ABI vs. Python bootstrap vs. stubs

---

## Upgrading Maturity

A package can move to a higher maturity level when:
- **API_SHAPE_ONLY → PANTHER_IMPLEMENTED:** Live backend integration implemented and tested
- **PANTHER_IMPLEMENTED → VERIFIED_EXECUTABLE:** All provider integrations work without external dependencies (or mock mode is production-ready)
- **PYTHON_BOOTSTRAP_BACKED → VERIFIED_EXECUTABLE:** Native Panther runtime implementation of concurrency/async primitives

Maturity changes are documented in CHANGELOG.md per release.

---

## Current Maturity Snapshot (v1.1.8)

| Package | Maturity |
|---------|----------|
| panther.core | VERIFIED_EXECUTABLE |
| panther.math | VERIFIED_EXECUTABLE |
| panther.text | VERIFIED_EXECUTABLE |
| panther.net | VERIFIED_EXECUTABLE |
| panther.database | VERIFIED_EXECUTABLE |
| panther.crypto | VERIFIED_EXECUTABLE |
| panther.json | VERIFIED_EXECUTABLE |
| panther.time | VERIFIED_EXECUTABLE |
| panther.collections | VERIFIED_EXECUTABLE |
| panther.files | VERIFIED_EXECUTABLE |
| panther.http | VERIFIED_EXECUTABLE |
| panther.ai | PANTHER_IMPLEMENTED |
| panther.security | VERIFIED_EXECUTABLE |
| panther.logging | VERIFIED_EXECUTABLE |
| panther.system | VERIFIED_EXECUTABLE |
| panther.testing | VERIFIED_EXECUTABLE |
| panther.storage | VERIFIED_EXECUTABLE |
| panther.serialization | PARTIAL |
| panther.cli | VERIFIED_EXECUTABLE |
| panther.web | PANTHER_IMPLEMENTED |
| panther.cloud | API_SHAPE_ONLY |
| panther.container | API_SHAPE_ONLY |
| panther.process | PARTIAL |
| panther.concurrent | PYTHON_BOOTSTRAP_BACKED |
| panther.async | PYTHON_BOOTSTRAP_BACKED |

**Summary:**
- **17** VERIFIED_EXECUTABLE
- **2** PANTHER_IMPLEMENTED
- **2** PYTHON_BOOTSTRAP_BACKED
- **3** API_SHAPE_ONLY
- **1** PARTIAL

---

## Recommendations

**For production applications today:**
- Use VERIFIED_EXECUTABLE packages freely
- Use PANTHER_IMPLEMENTED packages (`ai`, `web`) with mock/test modes; plan for provider setup
- Avoid PYTHON_BOOTSTRAP_BACKED packages for latency-sensitive or parallel workloads
- Do not use API_SHAPE_ONLY or PARTIAL packages for live operations

**For library authors:**
- Target VERIFIED_EXECUTABLE APIs for stability
- Declare required maturity in package metadata when ecosystem exists
- Test against mock modes for PANTHER_IMPLEMENTED packages