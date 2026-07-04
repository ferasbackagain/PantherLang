# PantherLang v1.1.5 Version Reconciliation Report

**Date:** 2026-07-04
**Author:** PantherLang Release Audit
**Status:** FINAL DECISION

---

## Executive Summary

This document records the decision to unify all PantherLang component versions to **v1.1.5** for the final public release.

---

## Version Audit Results

| Component | Current Version | Location | Action |
|-----------|----------------|----------|--------|
| Core Package (pyproject.toml) | 1.0.0 | `pyproject.toml` | **UPDATE to 1.1.5** |
| Core Version Module | 1.0.0 | `panther_core/version.py` | **UPDATE to 1.1.5** |
| CLI Version Module | 1.0.0 (delegates to core) | `cli/version.py` | No change needed |
| Compiler Version Module | 1.0.0 (delegates to core) | `compiler/version.py` | No change needed |
| VS Code Extension | 1.1.3 | `vscode-extension/package.json` | **UPDATE to 1.1.5** |
| Debug Adapter | 1.0.0 | `panther_core/version.py` | **UPDATE to 1.1.5** |
| Engineering Reports | 1.1.5 | Multiple `.md` files | Already consistent |
| CHANGELOG | 1.0.0 | `CHANGELOG.md` | **UPDATE to 1.1.5** |

---

## Decision Rationale

### Why v1.1.5 (not 1.0.0, not 1.1.3, not 1.1.4)

1. **Release target is v1.1.5** — All engineering evidence packages, RC patches (RC1, RC1a, RC1b, RC1c), and the autonomous execution checkpoint explicitly target v1.1.5.

2. **VS Code extension already at 1.1.3** — The extension version has been incremented independently. Moving to 1.1.5 aligns it with the core release.

3. **1.0.0 represents Developer Edition milestone** — The 1.0.0 version was tagged as "PantherLang Developer Edition v1.0.0" for internal development. The public release deserves a distinct version.

4. **Semantic versioning** — 1.1.5 indicates:
   - Major: 1 (stable language foundation)
   - Minor: 1 (feature-complete public release with stdlib, web, AI, database)
   - Patch: 5 (five rounds of RC stabilization: RC1 → RC1a → RC1b → RC1c → Final)

---

## Files to Update

### Core Package (MUST UPDATE)
- `pyproject.toml` — version = "1.1.5"
- `panther_core/version.py` — PANTHERLANG_VERSION = "1.1.5", PANTHERLANG_RELEASE_NAME = "PantherLang v1.1.5", PANTHERLANG_DEBUG_ADAPTER_VERSION = "1.1.5"

### VS Code Extension (MUST UPDATE)
- `vscode-extension/package.json` — "version": "1.1.5"

### Documentation (MUST UPDATE)
- `CHANGELOG.md` — Add v1.1.5 entry at top
- `docs/book/chapters/12-cli-and-tooling.md` — Update extension install command
- `docs/book/THE_PANTHER_PROGRAMMING_LANGUAGE.md` — Update extension version reference
- `PROJECT_OVERVIEW.md` — Update extension version
- `MASTER_PROMPT.md` — Update extension version

### Generated Files (DO NOT UPDATE — will be regenerated)
- `dist/`, `build/`, `*.egg-info` — Will be rebuilt with `python -m build`

---

## Version Reconciliation Decision

**DECISION: Unify all versions to v1.1.5**

This is the single source of truth for the v1.1.5 public release. All components MUST report v1.1.5 after this reconciliation.

---

## Verification Commands

After updates, verify with:

```bash
panther version
panther doctor
python -m pytest tests/ -q
bash scripts/run_examples.sh
python -m build
```

Expected output:
- `panther version` → "PantherLang 1.1.5 (PantherLang v1.1.5)"
- All tests pass (1039+)
- All examples pass (11/11)
- Build produces `pantherlang-1.1.5.tar.gz` and `pantherlang-1.1.5-py3-none-any.whl`