# Panther Academy Launch Plan v1.1.5

**Date:** 2026-07-04
**Status:** Foundation Launch (Lessons 01-05) — Advanced Track In Development

---

## Current State (v1.1.5 Release)

### ✅ LAUNCHING NOW: Foundation Track (Lessons 01-05)

| Lesson | Title | Status | Location | Verification |
|--------|-------|--------|----------|--------------|
| 01 | Expressions & Operators | ⚠️ MISSING DIR | Claimed in docs, no `academy/lesson01/` | **Do not claim** |
| 02 | Variables & Types | ✅ COMPLETE | `academy/lesson02/` + `academy/lesson02/academy/main.pan` | Verified runnable |
| 03 | Control Flow | ✅ COMPLETE | `academy/lesson03/main.pan` | Verified runnable |
| 04 | Functions | ✅ COMPLETE | `academy/lesson04/main.pan` | Verified runnable |
| 05 | Conversions & IO | ✅ COMPLETE | `academy/lesson05/` + `verify_fixes.pan` | Verified runnable |

**Foundation Track Reality:** 4/5 lessons have working code. Lesson 01 directory missing.

### 🔄 IN DEVELOPMENT: Advanced Track (Lessons 06-10)

| Lesson | Planned Title | Current Reality | Target |
|--------|---------------|-----------------|--------|
| 06 | Arrays & Collections | **PARTIAL** — Only comparisons (`comparison_policy.pan`) | Q3 2026 |
| 07 | Modules & Packages | **MISSING** — No directory | Q3 2026 |
| 08 | Web Development | **MISSING** — No directory | Q3 2026 |
| 09 | AI & Machine Learning | **MISSING** — No directory | Q3 2026 |
| 10 | Advanced Security | **MISSING** — No directory | Q3 2026 |

---

## Launch Strategy

### Phase 1: Foundation Launch (v1.1.5 — NOW)
**Message:** "Panther Academy Foundation (Lessons 01-05) is live. Start learning PantherLang today."

**Assets Ready:**
- `docs/academy/README.md` — Updated with accurate status table
- `docs/academy/ACADEMY_RELEASE_STATUS_v1_1_5.md` — Truth audit
- `academy/lesson02-05/` — Runnable verification scripts
- `scripts/verify_academy_lessons_01_05.sh` — Verification script

**Action Items:**
1. Fix Lesson 01: Create `academy/lesson01/main.pan` with expressions demo
2. Update `docs/academy/README.md` to mark Lesson 01 as "Complete" (not missing)
3. Rename Lesson 06 in docs from "Arrays & Collections" to "Comparison Policy" (accurate)
4. Add "🚧 IN DEVELOPMENT" badges to Lessons 07-10 in README

### Phase 2: Advanced Track Development (v1.2 — Q3 2026)

**Lesson 06 — Arrays & Collections (Real)**
- Array creation, indexing, iteration
- Object/dict manipulation
- Nested access patterns
- Collection stdlib functions (push, pop, sort, reverse)

**Lesson 07 — Modules & Packages**
- `import` syntax (parsed but not fully resolved)
- `panther.toml` dependency management
- Package manager CLI
- Standard library organization

**Lesson 08 — Web Development**
- `HttpServer` Python API
- Route registration patterns
- Security middleware
- Template rendering (if implemented)

**Lesson 09 — AI & Machine Learning**
- Provider abstraction (5 providers)
- Agent & SecureAgent patterns
- RAG engine with vector store
- Prompt engineering basics

**Lesson 10 — Advanced Security**
- Security analyzer diagnostics (S001-S005)
- Runtime sandbox configuration
- Prompt injection detection patterns
- Audit logging and compliance

### Phase 3: Professional Certification (v1.3 — Q4 2026)
- Automated lesson verification
- Progress tracking
- Certificate generation (Foundation/Developer/Professional)
- Integration with PantherHub (future)

---

## Documentation Updates Required for v1.1.5 Launch

### 1. Fix Lesson 01 (URGENT — Before Announcement)
```bash
# Create missing lesson
mkdir -p academy/lesson01
cat > academy/lesson01/main.pan << 'EOF'
panther main {
    print "=== Lesson 01: Expressions & Operators ===";
    
    // Arithmetic
    print 10 + 5 * 2;      // 20 (precedence)
    print (10 + 5) * 2;    // 30
    print 2 ** 10;         // 1024
    
    // Comparison
    print 10 > 5;          // true
    print 10 == 10;        // true
    print "a" < "b";       // true
    
    // Logical
    print true && false;   // false
    print true || false;   // true
    print !true;           // false
    
    // String concat
    print "Hello " + "World";
}
EOF
```

### 2. Update docs/academy/README.md Status Table
Change Lesson 01 from ✅ to ✅ (after creating directory)
Change Lesson 06 from "Arrays & Collections" to "Comparison Policy (Preview)"

### 3. Add Transparency Notice to Academy Landing
> "Lessons 01-05 form the Foundation Track and are complete. Lessons 06-10 (Advanced Track) are in active development. Lesson 06 (Comparison Policy) is available as a preview. Full curriculum targeted for Q3 2026."

---

## Verification Commands for Launch

```bash
# Verify all foundation lessons run
for i in 02 03 04 05; do
    panther run academy/lesson$i/main.pan
done

# Verify lesson 02 academy verification script
panther run academy/lesson02/academy/main.pan

# Verify lesson 05 comparison fixes
panther run academy/lesson05/verify_fixes.pan

# Run academy test suite (if exists)
python -m pytest tests/academy/ -v
```

---

## Communication Plan

### Launch Announcement (v1.1.5)
- **Headline:** "Panther Academy Foundation Launches: 5 Lessons, Runnable Code"
- **Key Message:** "Learn PantherLang with verified, executable examples"
- **CTA:** `panther run academy/lesson02/main.pan`

### Ongoing (Monthly)
- Progress updates on Lessons 06-10
- Community contributions welcome
- GitHub Issues for lesson requests

---

## Success Metrics

| Metric | v1.1.5 Target | v1.2 Target | v1.3 Target |
|--------|---------------|-------------|-------------|
| Lessons Complete | 5/10 (Foundation) | 8/10 (Developer) | 10/10 (Professional) |
| Verified Runnable | 5 | 8 | 10 |
| Verification Script | 1 (script) | 1 per lesson | Automated CI |
| Learner Completion | N/A | Trackable | Certificates |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Lesson 01 missing at launch | Create before announcement (30 min task) |
| Overclaiming in marketing | Use truth audit doc as source of truth |
| Community expects full 10 lessons | Clear "In Development" badges + timeline |
| Verification breaks on update | CI runs `verify_academy_lessons_01_05.sh` |

---

## Approval

**Academy Launch Go/No-Go:** ________________
**Date:** ________________
**Condition:** Lesson 01 directory created before announcement