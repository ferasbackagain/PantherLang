# PantherLang v1.1.6 — Flagship Implementation Plan

**Project:** Panther One (`examples/flagship/panther_one/`)
**Status:** DESIGN COMPLETE — implementation deferred until reports are approved

---

## Implementation Phases

### F0 — Capability Proof (before any code)

**Purpose:** Verify that all required stdlib functions and platform features work before building the app.

**Tasks:**
1. [ ] Verify `json_encode`/`json_decode` round-trip works with objects containing strings, numbers, booleans, null
2. [ ] Verify `db_open(":memory:")` + `db_execute` + `db_query` cycle
3. [ ] Verify `fs_read` with existing file and non-existing file (document behavior)
4. [ ] Verify `sha256` produces expected hex string
5. [ ] Verify `sanitize_path` with valid and traversal paths
6. [ ] Verify `sanitize_html` escapes all 5 HTML entities
7. [ ] Verify `ai_mock_chat` returns non-empty string
8. [ ] Verify `ai_supported_providers` returns array of 5 strings
9. [ ] Verify `panther run --serve` starts and serves GET routes
10. [ ] Verify POST routes receive body data

**Gate:** All 10 items working. Document any deviations in `F0_NOTES.md`.

**Duration:** 1 session (2-4 hours)

---

### F1 — Project Scaffold

**Purpose:** Create directory structure and entry point.

**Tasks:**
1. [ ] Create `examples/flagship/panther_one/` directory
2. [ ] Create `main.pan` with `panther main { }` block
3. [ ] Create `fixtures/` directory with 5 test files
4. [ ] Create `tests/` directory
5. [ ] Create `README.md` with architecture and run instructions
6. [ ] Create `EXPECTED_OUTPUT.md` with sample outputs
7. [ ] Verify `panther run --serve main.pan` starts without error

**Gate:** Server starts with "Panther One" banner and 0 registered routes.

**Duration:** 1 session (1-2 hours)

---

### F2 — Web Server / Browser

**Purpose:** Implement basic web routes and the HTML dashboard.

**Tasks:**
1. [ ] Add `web { }` block with `GET /` route returning HTML dashboard
2. [ ] Build HTML dashboard page with status cards (CSS embedded)
3. [ ] Add `GET /health` route returning JSON
4. [ ] Style dashboard with minimal embedded CSS
5. [ ] Verify `http://localhost:8080/` loads the dashboard
6. [ ] Verify `http://localhost:8080/health` returns JSON

**Gate:** Dashboard visible in browser with structure (cards can show placeholder data).

**Duration:** 1 session (2-3 hours)

---

### F3 — API Routes

**Purpose:** Implement JSON API endpoints for CRUD.

**Tasks:**
1. [ ] Add `GET /api/items` route returning hardcoded JSON array
2. [ ] Add `POST /api/items` route returning `{"ok": true}`
3. [ ] Add `GET /api/stats` route returning `{"items": 0}`
4. [ ] Add `GET /api/items/{id}` — NOTE: NOT YET WORKING (path params broken). Alternative: use `GET /api/item?id=5` with query parameters (implement via POST body parsing)
5. [ ] Add `PUT /api/items/{id}` — NOT YET WORKING. Alternative: POST /api/items/update with body
6. [ ] Add `DELETE /api/items/{id}` — NOT YET WORKING. Alternative: POST /api/items/delete with body
7. [ ] Verify JSON responses with `curl`

**Gate:** All reachable API routes return correct JSON. Broken routes documented.

**Duration:** 1 session (2-3 hours)

---

### F4 — SQLite Persistence

**Purpose:** Wire SQLite into all CRUD routes.

**Tasks:**
1. [ ] Initialize in-memory SQLite database on server start
2. [ ] Create `items` table with schema
3. [ ] Create `logs` table with schema
4. [ ] Create seed data (3 sample items)
5. [ ] Wire `GET /api/items` → `db_query(conn, "SELECT * FROM items")`
6. [ ] Wire `POST /api/items` → `db_execute(conn, "INSERT INTO items ...")`
7. [ ] Wire `GET /api/stats` → `db_query(conn, "SELECT COUNT(*) as cnt FROM items")`
8. [ ] Wire log table: insert log entry on each API call
9. [ ] Verify CRUD cycle end-to-end

**Known limitation:** UPDATE and DELETE require POST fallback routes since PUT/DELETE not implemented in parser.

**Gate:** API calls persist to in-memory SQLite and return database-backed data.

**Duration:** 1 session (3-4 hours)

---

### F5 — Security Tools

**Purpose:** Implement local, defensive security tools.

**Tasks:**
1. [ ] Add `GET /security/scan` route
2. [ ] Read all files in `fixtures/` directory
3. [ ] Compute SHA256 hash of each file
4. [ ] Compare against hardcoded expected hashes
5. [ ] Return JSON: `{"files": N, "matched": N, "mismatched": N}`
6. [ ] Add `GET /security/hash/{text}` — compute SHA256 of user-provided text
7. [ ] Add HTML hash calculator form on dashboard
8. [ ] Add `sanitize_html` demo form (input → sanitized output)
9. [ ] Add `sanitize_path` demo form (path → resolved result or error)

**Security rules:**
- All scanning is LOCAL (only `fixtures/` directory)
- No network scanning
- No exploitation
- All operations read-only

**Gate:** Security form works in browser. Hash comparison returns correct results.

**Duration:** 1 session (2-3 hours)

---

### F6 — AI Provider Layer

**Purpose:** Implement AI chat with mock mode.

**Tasks:**
1. [ ] Add `GET /ai/chat` route returning HTML chat form
2. [ ] Add `POST /ai/chat` route calling `ai_mock_chat(message)`
3. [ ] Add `GET /ai/providers` route returning provider list
4. [ ] Add provider status to dashboard (Mock/Real indicator)
5. [ ] Sanitize AI output with `sanitize_html()` before display
6. [ ] Document mock/real mode in README

**Explicit limitations:**
- Default mode: MOCK (no API key needed, works offline)
- Real AI: Requires `OPENAI_API_KEY` env var
- Always label AI responses "Mock" or "Real"
- No agent tools in v1.1 (Python API only)

**Gate:** Chat form submits, mock response displayed. Provider list shows 5 providers.

**Duration:** 1 session (2-3 hours)

---

### F7 — Safe Agent (Deferred to v1.2)

**NOTE:** PantherLang cannot create agents from language syntax in v1.1.6. The `Agent` and `SecureAgent` classes are Python-only. This phase is **DEFERRED** to v1.2.

**What would be done in v1.2:**
1. [ ] Create PantherLang-native `agent { }` syntax
2. [ ] Implement agent creation from `.pan` files
3. [ ] Wire `SecureAgent` with prompt injection detection
4. [ ] Register bounded tools (calculate, lookup_item, get_time)
5. [ ] Add agent dashboard page

**For v1.1.6:** Document that agent features are Python API only, with a note about v1.2 plans.

---

### F8 — Dashboard UI

**Purpose:** Polish the dashboard with live data.

**Tasks:**
1. [ ] Wire "Server Status" card → `GET /health` check
2. [ ] Wire "Database Records" card → `db_query("SELECT COUNT(*)")`
3. [ ] Wire "AI Provider" card → `ai_supported_providers()` output
4. [ ] Wire "Security Status" card → security scan summary
5. [ ] Add navigation sidebar with links to all tools
6. [ ] Add "Quick Actions" buttons (Add test record, Run scan, Clear logs)
7. [ ] Add "Recent Logs" table showing last 5 log entries
8. [ ] Style with clean, minimal CSS

**Gate:** All dashboard cards show live data. Navigation works.

**Duration:** 1 session (3-4 hours)

---

### F9 — Reports and Logs

**Purpose:** Implement log viewing and system report generation.

**Tasks:**
1. [ ] Implement logging helper: each API call logs to SQLite `logs` table
2. [ ] Add `GET /logs` route returning log entries
3. [ ] Add `GET /logs?level=error` filter
4. [ ] Add `GET /report` route returning comprehensive JSON report
5. [ ] Report includes: server uptime, route count, DB record count, security status, AI provider
6. [ ] Add log viewer page on dashboard
7. [ ] Add report download button

**Gate:** Logs are recorded and viewable. Report returns valid JSON with all sections.

**Duration:** 1 session (2-3 hours)

---

### F10 — Tests

**Purpose:** Create integration tests for Panther One.

**Tasks:**
1. [ ] Create `tests/test_panther_one.pan` with executable assertions
2. [ ] Test each route returns expected status code
3. [ ] Test CRUD cycle: INSERT → SELECT → UPDATE → DELETE (via POST fallbacks)
4. [ ] Test security scan returns correct hash comparisons
5. [ ] Test AI mock chat returns non-empty string
6. [ ] Test log entries are created
7. [ ] Create `tests/run_tests.sh` for CI automation

**Gate:** All tests pass. Test script can be run in CI.

**Duration:** 1 session (3-4 hours)

---

### F11 — Academy/Book Integration

**Purpose:** Cross-reference Panther One with educational content.

**Tasks:**
1. [ ] Map each Panther One feature to Academy lesson, Book chapter, Cookbook recipe
2. [ ] Add cross-reference comments in `main.pan` (`// See: Academy Lesson 07`)
3. [ ] Create `CURRICULUM_MAP.md` showing how Panther One connects all materials
4. [ ] Add "Try It Yourself" sections in README pointing to relevant lessons
5. [ ] Verify that all referenced Academy lessons currently work (run verify.pan)

**Gate:** Curriculum map documents the connections. All referenced educational content is verified working.

**Duration:** 1 session (2-3 hours)

---

### F12 — Release Acceptance

**Purpose:** Final validation before marking Panther One complete.

**Tasks:**
1. [ ] Run `panther run --serve main.pan` in fresh terminal
2. [ ] Visit `http://localhost:8080/` — dashboard loads
3. [ ] All status cards show valid data
4. [ ] API calls return correct JSON
5. [ ] SQLite CRUD cycle works
6. [ ] Security scan runs and returns results
7. [ ] AI chat mock mode works
8. [ ] Logs are recorded and viewable
9. [ ] Report generates valid JSON
10. [ ] All tests pass
11. [ ] README reviewed for accuracy
12. [ ] Known limitations documented

**Gate:** Acceptance checklist complete. All items pass.

**Duration:** 1 session (1-2 hours)

---

## Estimated Total Effort

| Phase | Sessions | Hours |
|-------|----------|-------|
| F0 — Capability Proof | 1 | 2-4 |
| F1 — Project Scaffold | 1 | 1-2 |
| F2 — Web Server | 1 | 2-3 |
| F3 — API Routes | 1 | 2-3 |
| F4 — SQLite Persistence | 1 | 3-4 |
| F5 — Security Tools | 1 | 2-3 |
| F6 — AI Provider Layer | 1 | 2-3 |
| F7 — Safe Agent | *Deferred* | *v1.2* |
| F8 — Dashboard UI | 1 | 3-4 |
| F9 — Reports/Logs | 1 | 2-3 |
| F10 — Tests | 1 | 3-4 |
| F11 — Academy/Book Integration | 1 | 2-3 |
| F12 — Release Acceptance | 1 | 1-2 |
| **Total** | **12** | **27-38 hours** |

## Implementation Constraints

1. **All code in ONE file** (`main.pan`) — no module imports (PantherLang import system is minimal)
2. **No Python helper files** — all logic must execute in the PantherLang runtime
3. **No JavaScript** — forms use HTML-only submission (no JS required, JS optional for enhancements)
4. **No external CSS** — styles embedded in `<style>` blocks
5. **Offline-first** — all features work without internet (AI mock mode, local SQLite, local files)
6. **No hardcoded secrets** — API keys read from environment via `system_env()`
7. **Defensive by default** — all inputs sanitized, all paths validated

## Known v1.1.6 Limitations to Document

1. PUT/DELETE routes not supported → use POST fallbacks
2. Path parameters `/items/{id}` not working → use query params or POST body
3. `ai { }` block is no-op → use Python API or `ai_mock_chat()` stdlib function
4. Agent is Python API only → not available in PantherLang syntax
5. Some system functions Linux-only → document alternatives or fallbacks
6. No module imports → all code in a single file

## Build Authorization

**This plan is DESIGN ONLY.** Implementation may begin when:
- [ ] All 6 research reports are reviewed by the team
- [ ] F0 capability proof confirms all required features work
- [ ] This implementation plan is approved
- [ ] A decision is made on which v1.1.6 release blockers to fix before building
