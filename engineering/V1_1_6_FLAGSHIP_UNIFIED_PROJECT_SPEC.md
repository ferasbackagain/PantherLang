# PantherLang v1.1.6 — Flagship Unified Project Specification

**Project Name:** Panther One
**Suggested Path:** `examples/flagship/panther_one/`
**Status:** DESIGN ONLY — do not build until implementation plan is approved

---

## 1. Executive Summary

Panther One is a unified demonstration application that validates every major PantherLang capability in a single, runnable project. It serves as:
- **Proof of capability** for the v1.1.6 release
- **Integration test** across all platform features
- **Educational showcase** for Academy, Book, and Cookbook alignment
- **Release acceptance gate** — if Panther One runs, the platform is ready

### Design Principles

1. **One command to run**: `panther run --serve main.pan`
2. **One browser URL to use**: `http://localhost:8080`
3. **All platform features demonstrated**: web, API, SQLite, filesystem, security, AI
4. **Offline-first**: Mock AI mode by default; real AI requires opt-in
5. **Defensive security**: Every operation is bounded, authorized, and safe
6. **Self-documenting**: README, architecture diagram, expected output

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Panther One App                        │
│                    main.pan                              │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐    │
│  │  Web UI  │  │  API     │  │  Dashboard          │    │
│  │  routes  │  │  routes  │  │  (reports/logs)     │    │
│  └────┬─────┘  └────┬─────┘  └─────────┬──────────┘    │
│       │              │                  │               │
│       └──────────────┼──────────────────┘               │
│                      │                                  │
│              ┌───────┴────────┐                         │
│              │  Request       │                         │
│              │  Router        │                         │
│              │  (HttpServer)  │                         │
│              └───────┬────────┘                         │
│                      │                                  │
│         ┌────────────┼────────────┐                     │
│         │            │            │                     │
│    ┌────┴────┐ ┌─────┴─────┐ ┌───┴────┐               │
│    │ SQLite  │ │ Filesystem│ │ JSON   │               │
│    │ CRUD    │ │ Fixtures  │ │ Config │               │
│    └─────────┘ └───────────┘ └────────┘               │
│                                                          │
│  ┌──────────────────────────────┐                       │
│  │  Security Layer              │                       │
│  │  ├─ Hash verification        │                       │
│  │  ├─ Path sanitization        │                       │
│  │  ├─ Token validation         │                       │
│  │  └─ HTML sanitization        │                       │
│  └──────────────────────────────┘                       │
│                                                          │
│  ┌──────────────────────────────┐                       │
│  │  AI Provider Layer           │                       │
│  │  ├─ Mock mode (default)      │                       │
│  │  └─ Real provider (opt-in)   │                       │
│  └──────────────────────────────┘                       │
└─────────────────────────────────────────────────────────┘
```

---

## 3. Web Routes

| Method | Route | Description | Response Type |
|--------|-------|-------------|---------------|
| GET | `/` | Dashboard homepage with status cards | HTML |
| GET | `/health` | Health check endpoint | JSON |
| GET | `/api/items` | List all items from SQLite | JSON |
| POST | `/api/items` | Create new item | JSON |
| PUT | `/api/items/{id}` | Update item | JSON (NOTE: PUT not yet working) |
| DELETE | `/api/items/{id}` | Delete item | JSON (NOTE: DELETE not yet working) |
| GET | `/api/stats` | Database statistics | JSON |
| GET | `/files` | List files in fixtures directory | JSON |
| GET | `/files/{name}` | Read file content | JSON |
| GET | `/security/scan` | Run security scanner on fixtures | JSON |
| GET | `/security/hash/{algorithm}` | Hash a test string | JSON |
| GET | `/ai/chat` | AI chat page | HTML |
| POST | `/ai/chat` | Send message to AI | JSON |
| GET | `/ai/providers` | List available AI providers | JSON |
| GET | `/logs` | View application logs | HTML/JSON |
| GET | `/report` | Generate system report | JSON |

### Route Implementation Notes

For v1.1.6 constraints:
- **PUT and DELETE routes** — Design specified but implementation notes say "NOT YET WORKING" since parser only handles GET/POST. These should be implemented as POST routes with `/update` and `/delete` suffixes until PUT/DELETE are supported.
- **Path parameters `/api/items/{id}`** — NOT working in current implementation. Alternative: use query parameters (`/api/items?id=5`) or POST body.
- **All other routes** — `GET` only, which is fully supported.

---

## 4. SQLite Database Schema

### Table: `items`

```sql
CREATE TABLE IF NOT EXISTS items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    status TEXT DEFAULT 'active',
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);
```

### Table: `logs`

```sql
CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    level TEXT DEFAULT 'info',
    source TEXT DEFAULT 'app',
    message TEXT NOT NULL,
    timestamp TEXT DEFAULT (datetime('now'))
);
```

### Table: `audit_events`

```sql
CREATE TABLE IF NOT EXISTS audit_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    detail TEXT DEFAULT '',
    created_at TEXT DEFAULT (datetime('now'))
);
```

---

## 5. Filesystem Fixtures

```
fixtures/
├── sample.txt            # Plain text file for read test
├── config.json           # JSON config for config_loader test
├── log_input.txt         # Log input for log generation
├── integrity_test.txt    # File with known hash for integrity check
└── emails.csv            # CSV file for data processing demo
```

Each fixture is a small, deterministic file used by the security scanner and filesystem demo.

---

## 6. Security Tools

### All security operations are LOCAL, DEFENSIVE, BOUNDED, and AUTHORIZED.

### 6.1 File Integrity Scanner

- Reads files in `fixtures/`
- Computes SHA256 hash of each file
- Compares against stored known-good hash
- Reports: MATCH, MISMATCH, or NOT_FOUND

### 6.2 Secret Scanner (Local)

- Scans fixture files for:
  - Hardcoded API key patterns (sk-... for OpenAI, etc.)
  - Password-like strings
  - Token patterns
- Reports: CLEAN, FLAG, or WARNING

### 6.3 HTML Sanitization Demo

- Takes user input via form
- Runs through `sanitize_html()`
- Shows original vs sanitized output

### 6.4 Path Sanitization Demo

- Takes user-provided path
- Runs through `sanitize_path()`
- Shows resolved path or traversal error

### 6.5 Secure Comparison Demo

- Takes two strings
- Runs through `secure_compare()`
- Shows timing-safe comparison result

### What is EXCLUDED (no offensive security):

- ❌ No port scanning
- ❌ No network scanning
- ❌ No credential attacks
- ❌ No exploitation
- ❌ No persistence
- ❌ No destructive actions
- ❌ No stealth operations
- ❌ No unauthorized data access

---

## 7. AI Provider Layer

### Architecture

```
┌──────────────┐
│ AI Chat Page │  HTML form + JSON API
└──────┬───────┘
       │
┌──────┴───────┐
│ ai_mock_chat │  Default (offline, no API key)
└──────┬───────┘
       │ (if OPENAI_API_KEY set)
┌──────┴───────┐
│ OpenAI Agent │  Real AI (requires opt-in via env var)
└──────────────┘
```

### Provider Configuration

| Provider | Env Var | Status |
|----------|---------|--------|
| Mock (default) | None | ✅ Always works |
| OpenAI | `OPENAI_API_KEY` | ✅ Mock without key, real with key |
| Anthropic | `ANTHROPIC_API_KEY` | Available but not wired (v1.2) |
| Gemini | `GEMINI_API_KEY` | Available but not wired (v1.2) |
| Ollama | `OLLAMA_HOST` | Available but not wired (v1.2) |
| OpenRouter | `OPENROUTER_API_KEY` | Available but not wired (v1.2) |

### AI Features

1. **Chat page**: Simple HTML form → POST `/ai/chat` → Mock/real response displayed
2. **Provider list**: GET `/ai/providers` → JSON list of supported providers
3. **Status indicator**: Shows "Mock Mode" or "Real: OpenAI" based on env vars
4. **Safety**: All AI output sanitized through `sanitize_html()` to prevent XSS
5. **Bounded tools**: If real AI is used, tools are restricted to:
   - `calculate(expression)` — math evaluation only
   - `lookup_item(id)` — database query only
   - `get_time()` — system time only

---

## 8. Dashboard UI

### Single-page HTML dashboard with:

1. **Status Cards** (top row):
   - Server Status (🟢/🔴)
   - Database Records (count from SQLite)
   - AI Provider (Mock/Real)
   - Security Status (Clean/Flagged)

2. **Navigation** (side bar):
   - Dashboard
   - Database CRUD
   - Filesystem Browser
   - Security Tools
   - AI Chat
   - Logs
   - Reports

3. **Quick Actions** (action buttons):
   - Add test record (SQLite INSERT)
   - Run security scan
   - Clear logs
   - Generate report

4. **Recent Logs** (footer table):
   - Latest 5 log entries
   - Auto-refresh on page load

### HTML/CSS

- All HTML generated inline (no external dependencies)
- CSS embedded in `<style>` block
- Minimal, functional, not decorative
- Works without JavaScript (form submissions only)
- JavaScript enhancement optional (fetch for auto-refresh)

---

## 9. Data Flow

```
User Browser
    │
    ├── GET /  ────────────────────┐
    │                              │
    │    http_server.dispatch      │
    │         │                    │
    │    Route handler fn          │
    │         │                    │
    │    ├── SQLite query ──── db_query(conn, sql)
    │    ├── File read ─────── fs_read(path)
    │    ├── Security check ── sha256/hmac
    │    ├── JSON encode ───── json_encode(result)
    │    └── Return ────────── "result" (auto-HTML/JSON)
    │                              │
    └── Browser receives response ─┘
```

---

## 10. Test Plan

### F0 — Capability Proof (before scaffold)
- [ ] All stdlib functions used in app are verified working
- [ ] HTTP server starts with `panther run --serve`
- [ ] SQLite CRUD works in-memory
- [ ] Security functions return expected values
- [ ] AI mock functions return expected values

### F1-F12 — Implementation Tests
- [ ] Each route returns expected status code and content type
- [ ] Database CRUD cycle completes (INSERT → SELECT → UPDATE → DELETE)
- [ ] Filesystem fixture list returns 5 files
- [ ] Security scanner reports correct hash comparison
- [ ] AI chat returns mock response (non-empty string)
- [ ] Logging records entry for each API call
- [ ] Report generates valid JSON with all sections
- [ ] Dashboard page loads all status cards

### Release Acceptance
- [ ] `panther run --serve main.pan` starts without errors
- [ ] `http://localhost:8080/` loads in browser
- [ ] All status cards show green/valid data
- [ ] No Python exceptions in server output
- [ ] Clean exit on Ctrl+C

---

## 11. Files Layout

```
examples/flagship/panther_one/
├── main.pan                 # Entry point: routes + server start
├── README.md                # Project documentation
├── ARCHITECTURE.md          # Architecture overview
├── EXPECTED_OUTPUT.md       # Expected browser output
├── ACCEPTANCE_CHECKLIST.md  # Pre-release checklist
├── fixtures/
│   ├── sample.txt           # Plain text fixture
│   ├── config.json          # JSON config fixture
│   ├── log_input.txt        # Log input fixture
│   ├── integrity_test.txt   # Integrity test fixture
│   └── emails.csv           # CSV fixture
├── tests/
│   └── test_panther_one.pan # Integration tests
└── screenshots/             (empty — populated during testing)
    ├── dashboard.png
    ├── crud.png
    ├── security.png
    └── ai_chat.png
```

---

## 12. One-Command Run

```bash
cd examples/flagship/panther_one/
panther run --serve main.pan
# Output:
# Panther web server starting on http://0.0.0.0:8080
# Registered routes: 16
# Panther One is running. Open http://localhost:8080
```

Browser: `http://localhost:8080/` → Dashboard with status cards

---

## 13. Expected Output (Smoke Test)

### GET / → HTML Dashboard
```
Status: 🟢 Running | DB: 3 records | AI: Mock | Security: ✅ Clean
```

### GET /health → JSON
```json
{"status": "ok", "app": "panther-one", "version": "1.1.6"}
```

### GET /api/items → JSON
```json
[{"id": 1, "name": "Sample Item 1", "status": "active"},
 {"id": 2, "name": "Sample Item 2", "status": "active"}]
```

### POST /api/items (body: {"name": "New Item"}) → JSON
```json
{"ok": true, "id": 3}
```

### GET /security/scan → JSON
```json
{"files": 5, "matched": 5, "mismatched": 0, "not_found": 0, "status": "CLEAN"}
```

### POST /ai/chat (body: {"message": "Hello"}) → JSON
```json
{"response": "PantherAI mock response: Hello", "provider": "mock"}
```

---

## 14. Non-Goals

1. **Not a production application** — This is a capability demo, not a deployment target
2. **Not a benchmark** — No performance testing
3. **Not a security certification** — Demonstrates security features, not certified security
4. **Not a replacement for test suite** — Unit tests remain in `tests/`
5. **Not AI-native** — AI features are mock or Python API — explicitly labeled

---

## 15. Security Compliance

All operations in Panther One:
- Read-only by default (fixtures are pre-created)
- Database is in-memory (`:memory:`) or application-owned file
- File operations are confined to `fixtures/` directory
- Security tools scan only `fixtures/` (no system scanning)
- Network operations limited to localhost HTTP server
- AI operations are mock-only by default; real AI requires explicit env var
- No credential collection, no persistence, no stealth
