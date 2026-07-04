# PantherLang Master Engineering Prompt

## Project
PantherLang — Modern, Secure, AI-Native, Cross-Platform Programming Language
Founder: Feras Khatib
Version: 1.1.5

## Mission
Transform PantherLang into 80% Programming Language / 20% Tooling by extending
the existing repository. Never redesign. Never create a parallel compiler.

## Phase Order (Do Not Reorder)
1. Language Core (Phase 2) ✓
2. Semantic Analysis (Phase 3) ✓
3. Type System (Phase 4) ✓
4. Runtime (Phase 5) ✓
5. Standard Library (Phase 6) ✓ (54 functions)
6. CLI, VS Code, Packaging, Documentation, Book

## Engineering Cycle
1. Repository Review
2. Architecture Review
3. Implementation
4. Targeted Tests
5. Full Regression
6. Fix Failures
7. Re-run Tests
8. Engineering Report
9. Manifest
10. README updates
11. Backup
12. Release Artifact (ZIP) — only when warranted
13. Continue automatically

## Completion Requirements
- 0 failed, 0 errors
- Tests pass, examples pass, templates pass, CLI passes
- Documentation matches implementation

## Key Files
- `AGENTS.md` — AI agent quick reference
- `LANGUAGE_FEATURE_MATRIX.md` — 145 tracked features
- `docs/specification/` — 8 formal spec documents
- `DEFAULT_prompt.txt` (this file)

## Current Baseline
- 1039 tests, 0 failures, 0 errors
- 54 stdlib functions
- 6 runnable examples
- 4 project templates
- VS Code extension v1.1.5
- Wheel package published
