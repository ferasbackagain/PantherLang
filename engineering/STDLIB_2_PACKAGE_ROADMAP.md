# PantherLang Standard Library 2.0 — Package Roadmap

## Overview

This roadmap defines the phased implementation plan for Standard Library 2.0,
converting the flat function registry into an organized, versioned, professional
package ecosystem under the `panther.*` namespace.

## Execution Order

| Phase | Packages | Prerequisites | Complexity |
|-------|----------|---------------|------------|
| 0 | Audit | None | Analysis |
| 1 | Package/Module Foundation | Phase 0 | High |
| 2 | core, collections, math, text, time, json | Phase 1 | Medium |
| 3 | files, system, process, logging, cli | Phase 2 | Medium |
| 4 | net, http | Phase 3 | High |
| 5 | web | Phase 4 | High |
| 6 | database, storage | Phase 5 | Medium |
| 7 | crypto, security | Phase 6 | Medium |
| 8 | testing, concurrent, async | Phase 7 | High |
| 9 | ai | Phase 8 | Medium |
| 10 | cloud, container | Phase 9 | Low |
| Final | Integration & Release | Phase 10 | Verification |

## Phase Details

### Phase 1 — Package/Module Foundation
**Goal**: Enable `import panther.core` to resolve and load a package.

**Required changes**:
- `compiler/stdlib/package_loader.py` — New module for package discovery
- `compiler/modules/` — Module resolution system
- Enhanced `ImportStatement` handling in semantic analyzer
- Module caching in runtime
- Package discovery path (stdlib/panther/*)
- Compatibility aliases for existing flat functions

**Files to create**:
- `compiler/stdlib/package_loader.py`
- `stdlib/panther/` directory structure
- `stdlib/panther/__init__.pan`
- `stdlib/panther/core/__init__.pan`

**Tests**: package discovery, module import, forward refs, duplicates, cyclic deps

### Phase 2 — Core Foundation Packages
**Goal**: Implement `panther.core`, `panther.collections`, `panther.math`, `panther.text`, `panther.time`, `panther.json`

**Strategy**: Move existing functions into namespaced wrappers with .pan logic.

**Backend**: Primarily PYTHON_BACKED and PANTHER_IMPLEMENTED.

### Phase 3 — System Foundation Packages
**Goal**: Implement `panther.files`, `panther.system`, `panther.process`, `panther.logging`, `panther.cli`

**Strategy**: Wrap existing filesystem/system/logging functions. New process and CLI packages.

### Phase 4 — Network and HTTP
**Goal**: Implement `panther.net`, `panther.http`

**Strategy**: Reorganize existing 22 network functions into namespaced packages. Add HTTP client with structured responses.

### Phase 5 — Web Foundation
**Goal**: Implement `panther.web` with HTTP server.

**Dependency**: Requires `panther.http` from Phase 4 and existing `compiler/web/` server.

### Phase 6 — Database and Storage
**Goal**: Implement `panther.database`, `panther.storage`

**Strategy**: Wrap existing SQLite functions. Storage already has foundation (`storage_*` functions).

### Phase 7 — Cryptography and Security
**Goal**: Implement `panther.crypto`, `panther.security`

**Strategy**: Reorganize existing 17 crypto/security functions. Add security policy framework.

### Phase 8 — Testing and Concurrency
**Goal**: Implement `panther.testing`, `panther.concurrent`, `panther.async`

**Strategy**: New packages — testing assertions, concurrency primitives.

### Phase 9 — AI Package
**Goal**: Implement `panther.ai`

**Strategy**: Wrap existing 5 AI functions, add structured provider abstraction.

### Phase 10 — Cloud and Containers
**Goal**: Implement `panther.cloud`, `panther.container`

**Strategy**: Configuration models, provider-neutral abstractions. Mark unsupported providers honestly.

## Compatibility Policy

1. All existing flat function names remain as compatibility aliases
2. No breaking changes during v1.x
3. Old names redirect to new implementations
4. New `panther.*` APIs are the canonical interface
5. Deprecation notices in documentation only (no runtime warnings)

## Architecture Decision: Functional API First

Based on Phase 0 findings, the current PantherLang compiler does not support:
- Class/method syntax
- Constructor syntax
- Generics
- Namespace/property access on imported modules

Therefore, Standard Library 2.0 will use **functional API** pattern:
```
panther_math_abs(-5)
panther_text_trim(" hello ")
```

Instead of unsupported patterns like:
```
import panther.math;
panther.math.abs(-5);
```

This will be updated to object-oriented APIs when the language supports them.

## Self-Hosted Implementation Priority

Move logic into `.pan` files in this priority order:
1. Validation and type checking (`panther.core`)
2. Collection operations (`panther.collections`)
3. Text operations (`panther.text`)
4. Math helpers (`panther.math`)
5. Time/date formatting (`panther.time`)
6. JSON utilities (`panther.json`)

Leave Python backing for:
- Filesystem (needs OS access)
- Network (needs socket access)
- Crypto (needs library access)
- HTTP (needs HTTP client)
- Database (needs SQLite)
- System (needs OS access)

## Test Strategy

Every package requires:
1. `tests/test_stdlib2_<package>.py` — Package-specific tests
2. `tests/test_stdlib2_capability_consistency.py` — Master consistency test
3. Example in `examples/stdlib2_<name>/`

Test pattern:
```python
def test_package_function():
    result = execute_source('''
    panther main {
        let val = panther_math_abs(-5);
        print(val);
    }
    ''')
    assert result.error is None
    assert "5" in " ".join(result.captured_output)
```

## Capability Manifest Enhancement

The existing `compiler/capability_manifest.py` must be enhanced with:

1. Classification field (PANTHER_IMPLEMENTED, HOST_BACKED, etc.)
2. Parameter types
3. Return type
4. Error contract
5. Legacy aliases
6. Documentation path
7. Test path
8. Platform support
9. Security classification
10. Stability level

## Documentation Structure

```
docs/stdlib2/README.md
docs/stdlib2/CORE.md
docs/stdlib2/COLLECTIONS.md
docs/stdlib2/MATH.md
docs/stdlib2/TEXT.md
docs/stdlib2/TIME.md
docs/stdlib2/JSON.md
docs/stdlib2/FILES.md
docs/stdlib2/SYSTEM.md
docs/stdlib2/PROCESS.md
docs/stdlib2/NETWORK.md
docs/stdlib2/HTTP.md
docs/stdlib2/WEB.md
docs/stdlib2/DATABASE.md
docs/stdlib2/STORAGE.md
docs/stdlib2/CRYPTO.md
docs/stdlib2/SECURITY.md
docs/stdlib2/LOGGING.md
docs/stdlib2/CLI.md
docs/stdlib2/TESTING.md
docs/stdlib2/CONCURRENCY.md
docs/stdlib2/AI.md
docs/stdlib2/CLOUD.md
docs/stdlib2/CONTAINER.md
```

## Example Projects

```
examples/stdlib2_cli_app/
examples/stdlib2_file_manager/
examples/stdlib2_network_intelligence/
examples/stdlib2_http_client/
examples/stdlib2_web_api/
examples/stdlib2_sqlite_crud/
examples/stdlib2_security_audit/
examples/stdlib2_async_worker/
examples/stdlib2_ai_assistant/
```

## Phase Gate Checklist

After every phase:
1. Run targeted package tests
2. Run semantic/runtime consistency
3. Run representative example
4. Run resource warning checks
5. Run full regression
6. Remove generated artifacts
7. Update engineering report
8. Continue only if green

## Current Status

Phase 0: COMPLETE (audit completed, 146 functions inventoried)
Phase 1: PENDING
Phase 2-10: PENDING
Final: PENDING
