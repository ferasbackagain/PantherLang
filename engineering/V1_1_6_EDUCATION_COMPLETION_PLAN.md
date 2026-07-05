# PantherLang v1.1.6 Education Completion Plan

**Date:** 2026-07-04  
**Based on:** Forensic audits of Academy, Book, and Cookbook  
**Goal:** Publication-grade education system aligned with implemented language

---

## Current State Summary

| Component | Status | Completion | Verdict |
|-----------|--------|------------|---------|
| Academy | 6/10 lessons, 2 misaligned | ~27% | PARTIAL |
| Book | 14/18 chapters, 1 minimal | ~65% | PARTIAL |
| Cookbook | 5 documented, 11 actual examples | ~2% (vs 500 claimed) | ASPIRATIONAL |
| Labs | 0 | 0% | MISSING |
| Capstones | 0 | 0% | MISSING |
| Certification | 7 tracks planned, 0 defined | 0% | PLANNED |

---

## Phase 1: Fix Existing Academy Lessons (Week 1)

### 1.1 Fix Lesson 02: Variables & Types
- **Current:** 4 lines, only `print 100`
- **Required:** Type inference, annotations, reassignment, compound assignment, scope
- **Source:** Book Ch 02 + implementation
- **Add:** exercises, lab, quiz, assessment

### 1.2 Fix Lesson 03: Control Flow
- **Current:** Variable declarations only
- **Required:** if/elif/else, while, for range, loop, break/continue
- **Source:** Book Ch 04 + implementation
- **Add:** exercises, lab, quiz, assessment

### 1.3 Fix Lesson 04: Functions
- **Current:** Single arithmetic line
- **Required:** fn declaration, parameters, return, recursion, typed params, closures
- **Source:** Book Ch 05 + implementation
- **Add:** exercises, lab, quiz, assessment

### 1.4 Fix Lesson 06: Rename to "Comparisons" + Create Lesson 06 "Arrays & Collections"
- **Current Lesson 06:** Comparison policy (keep as "Lesson 06: Comparisons")
- **New Lesson 06:** Arrays, objects, indexing, iteration, methods
- **Source:** Book Ch 06 + Ch 07 (Collections) + implementation
- **Add:** exercises, lab, quiz, assessment

### 1.5 Create Lesson 01 (if missing from academy/)
- **Status:** Created during audit, needs full treatment
- **Add:** exercises, lab, quiz, assessment

---

## Phase 2: Create Missing Academy Lessons 07-15+ (Week 2-3)

Based on Book chapters and implementation scope:

| Lesson | Title | Book Chapter Source | Implementation Source |
|--------|-------|---------------------|----------------------|
| 07 | Modules & Packages | Ch 14 (partial) | `compiler/modules/`, `package_manager/` |
| 08 | Structs, Enums & Traits | Ch 14 | `compiler/structs/`, `compiler/parser/` |
| 09 | Standard Library Deep Dive | Ch 07 | `compiler/stdlib/` |
| 10 | Security Fundamentals | Ch 08 | `compiler/security/` |
| 11 | Web Development | Ch 09 | `compiler/web/` |
| 12 | Database Programming | Ch 10 | `compiler/database/`, `compiler/stdlib/` (db_*) |
| 13 | AI Integration | Ch 11 | `compiler/ai/` |
| 14 | CLI & Tooling Mastery | Ch 12 | `cli/`, `vscode-extension/`, `tools/` |
| 15 | Advanced Topics | Ch 13, 14 | `compiler/optimization/`, `compiler/native_backend/` |
| 16 | Contributing to PantherLang | Ch 16 (planned) | Repository structure, tests |
| 17 | Ecosystem & Platform | Ch 17 (planned) | `project_templates/`, `registry/` |
| 18 | Capstone Preparation | Ch 18 (planned) | All above |

**Total: 18 lessons** matching 18 Book chapters

---

## Phase 3: Complete Book Chapters 15-18 (Week 2)

### 3.1 Chapter 15: Comparison Semantics
- **Current:** 7 lines
- **Required:** Full comparison policy, examples, PT002 details, null semantics
- **Merge option:** Move to Ch 14 Language Reference as appendix

### 3.2 Chapter 16: Contributing
- **Required:** Development setup, test workflow, PR process, code style, architecture overview
- **Source:** `AGENTS.md`, `CONTRIBUTING.md` (if exists), repo structure

### 3.3 Chapter 17: The Panther Ecosystem
- **Required:** Project templates, package registry, VS Code extension, CI/CD, community
- **Source:** `project_templates/`, `registry/`, `vscode-extension/`, `.github/`

### 3.4 Chapter 18: Appendix/Index
- **Required:** Glossary, keyword index, stdlib index, error code index, spec cross-ref

---

## Phase 4: Build Verified Cookbook (Week 3)

### 4.1 Structure by Category (matching implementation)
```
cookbook/
├── basics/
│   ├── hello-world.pan
│   ├── variables-types.pan
│   ├── expressions.pan
│   └── control-flow.pan
├── strings/
├── numbers/
├── collections/
│   ├── arrays.pan
│   ├── objects.pan
│   └── structs.pan
├── functions/
├── modules/
├── files/
├── json/
├── http/
├── web/
├── api/
├── database/
├── security/
├── ai/
├── testing/
└── tooling/
```

### 4.2 Recipe Format (Machine-Readable)
```json
{
  "id": "basics/hello-world",
  "title": "Hello World",
  "category": "basics",
  "difficulty": "beginner",
  "problem": "Print hello world",
  "solution": "panther main { print \"Hello, PantherLang!\"; }",
  "code_file": "basics/hello-world.pan",
  "expected_output": "Hello, PantherLang!",
  "verified": true,
  "test_file": "tests/cookbook/test_hello_world.py",
  "concepts": ["panther_main", "print", "string_literal"],
  "prerequisites": []
}
```

### 4.3 Target: 50 Verified Recipes (not 500)
- 10 basics
- 5 strings
- 5 numbers
- 5 collections
- 5 functions
- 5 files
- 5 json
- 3 http
- 3 web
- 3 api
- 3 database
- 3 security
- 3 ai
- 2 testing
- 2 tooling

---

## Phase 5: Create Labs (Week 3-4)

### 5.1 Lab Structure
```
labs/
├── lab-01-expressions/
│   ├── scenario.md
│   ├── objectives.md
│   ├── starter/
│   ├── tasks.md
│   ├── verification.py
│   ├── solution/
│   └── troubleshooting.md
├── lab-02-variables/
├── lab-03-control-flow/
...
├── lab-18-capstone/
```

### 5.2 Lab Types
- **Guided Labs** (Lessons 01-10): Step-by-step with verification
- **Challenge Labs** (Lessons 11-15): Open-ended with criteria
- **Capstone Labs** (16-18): Full project builds

---

## Phase 6: Create Capstone Projects (Week 4)

| Capstone | Track | Requirements | Source |
|----------|-------|--------------|--------|
| CLI Calculator | Foundations | Functions, arithmetic, IO | Lesson 01-05 |
| File Organizer | Developer | Files, JSON, collections | Lesson 06, 09 |
| Task Manager | Developer | SQLite, CLI, structs | Lesson 10, 12 |
| REST API | Web Dev | Web, routing, security | Lesson 11, 10 |
| AI Chatbot | AI-Native | AI providers, SecureAgent | Lesson 13 |
| Secure Notes | Security | Security, sandbox, crypto | Lesson 10, 15 |
| Compiler Plugin | Compiler Eng | AST, semantic, types | Lesson 15 |

---

## Phase 7: Certification Alignment (Week 4)

### 7.1 Track Definitions (Evidence-Based)

| Track | Status | Academy Lessons | Book Chapters | Labs | Capstone | Assessment |
|-------|--------|-----------------|---------------|------|----------|------------|
| Foundations | READY | 01-05 | 01-05 | 1-5 | Calculator | Quiz + Project |
| Developer | PARTIAL | 01-10 | 01-10 | 1-10 | File Organizer | Quiz + Project |
| Professional | PLANNED | 01-15 | 01-15 | 1-15 | Task Manager | Exam + Project |
| Web Developer | PLANNED | 01-11, 14 | 01-12 | 1-12 | REST API | Exam + Project |
| AI-Native Developer | PLANNED | 01-13 | 01-11, 13 | 1-13 | AI Chatbot | Exam + Project |
| Compiler Engineer | PLANNED | 01-15, 18 | 01-14, 18 | 1-15 | Compiler Plugin | Exam + Project |
| Platform Engineer | PLANNED | All | All | All | Multi-capstone | Portfolio |

**Key:** Only claim tracks where ALL components exist

---

## Phase 8: Automated Validation (Week 4)

### 8.1 Validation Pipeline
```bash
# Validate all academy examples
python -m pytest tests/academy/ -v

# Validate all book examples
python -m pytest tests/conformance/test_book_truthfulness.py -v

# Validate all cookbook recipes
python -m pytest tests/cookbook/ -v

# Validate all labs
python -m pytest tests/labs/ -v

# Validate all capstones
python -m pytest tests/capstones/ -v

# Full education validation
bash scripts/validate_education.sh
```

### 8.2 Extract-Test Pattern
For every `.md` file with PantherLang code blocks:
1. Extract code blocks marked ```panther
2. Write to temp file
3. Run `panther check` (syntax)
4. Run `panther run` (execution)
5. Compare output to expected

---

## Phase 9: Machine-Readable Metadata (Week 4)

### 9.1 Files to Create
```
knowledge/
├── academy.json          # All lessons with metadata
├── book.json             # All chapters with metadata
├── cookbook.json         # All recipes with metadata
├── labs.json             # All labs with metadata
├── capstones.json        # All capstones with metadata
├── curriculum.json       # Unified curriculum graph
├── learning_paths.json   # Beginner/Developer/Professional paths
├── certification_tracks.json # 7 tracks with requirements
└── concept_map.json      # Concept → lessons/chapters/recipes
```

### 9.2 Status Enum
Each item must have:
```json
{
  "status": "IMPLEMENTED | VERIFIED | PARTIAL | PLANNED",
  "evidence": "file_path_or_test_reference",
  "last_verified": "2026-07-04"
}
```

---

## Phase 10: README Integration (Week 4)

### 10.1 README Sections to Add/Update
- Panther Academy badge + link
- Official Book badge + link
- Cookbook badge + link
- Learning Paths diagram
- Certification roadmap (honest status)
- Founder identity (Feras Khatib, LinkedIn, GitHub)
- Verified example count (not aspirational)

---

## Resource Requirements

| Resource | Needed | Available |
|----------|--------|-----------|
| Developer time | 4 weeks | 1 agent |
| Test infrastructure | Extended | pytest exists |
| CI integration | GitHub Actions | Not configured |
| Review cycles | 2 per phase | Human needed |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Scope creep | High | High | Strict phase gates, no new features |
| Inconsistent syntax | Medium | High | Single source of truth (Book) |
| Unverified examples | Medium | High | Automated validation pipeline |
| Human review bottleneck | High | Medium | Async review, clear criteria |
| Implementation gaps | Medium | High | Only teach what's implemented |

---

## Success Criteria (Publication Gates)

### Academy: PUBLICATION_READY
- [ ] 18 lessons complete with correct content
- [ ] Every lesson: objectives, explanation, examples, exercises, lab, quiz, assessment, solution
- [ ] All examples run and pass tests
- [ ] Machine-readable metadata complete
- [ ] Cross-references to Book chapters

### Book: PUBLICATION_READY
- [ ] 18 chapters complete (15 expanded, 3 new)
- [ ] Consistent terminology with Academy
- [ ] All examples verified
- [ ] Glossary, index, appendices
- [ ] Academy cross-references
- [ ] Specification references (PDL-XXX)

### Cookbook: PUBLICATION_READY
- [ ] 50 verified recipes (not 500)
- [ ] Each recipe: problem, solution, code, output, explanation, test
- [ ] Organized by category
- [ ] Machine-readable metadata
- [ ] No false claims

### Labs: PUBLICATION_READY
- [ ] 18 guided labs + 3 capstone labs
- [ ] Each lab: scenario, objectives, starter, tasks, verification, solution
- [ ] Automated verification
- [ ] Troubleshooting guides

### Certification: READY
- [ ] 3 tracks fully defined (Foundations, Developer, Web)
- [ ] 4 tracks planned with roadmap (Professional, AI, Compiler, Platform)
- [ ] Competency matrices
- [ ] Assessment blueprints
- [ ] No accreditation claims

---

## Timeline

```
Week 1: Phase 1 (Fix existing lessons) + Phase 3.1 (Ch 15)
Week 2: Phase 2 (Create lessons 07-18) + Phase 3.2-3.4 (Ch 16-18)
Week 3: Phase 4 (Cookbook) + Phase 5 (Labs)
Week 4: Phase 6 (Capstones) + Phase 7 (Certification) + Phase 8 (Validation) + Phase 9 (Metadata) + Phase 10 (README)
```

---

## Immediate Next Actions

1. **Fix Lesson 02** - Replace content with proper variables/types lesson
2. **Fix Lesson 03** - Replace with control flow lesson
3. **Fix Lesson 04** - Replace with functions lesson
4. **Rename Lesson 06** to "Comparisons", create new Lesson 06 "Arrays & Collections"
5. **Expand Chapter 15** or merge into Chapter 14
6. **Create Chapter 16, 17, 18** from scratch
7. **Build validation tooling** for code extraction/testing
8. **Create knowledge/*.json** metadata structure

---

## Notes

- **Do not** create content for unimplemented features (async, concurrency, etc.)
- **Do** use Book as authoritative content, Academy as practice layer
- **Do** verify every code example against `compiler/runtime/`
- **Do** maintain strict truth in all claims
- **Do** coordinate with v1.1.6 release cleanup mission