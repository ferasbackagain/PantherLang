# PantherLang v1.1.5 Release Git Cleanup Plan

**Date:** 2026-07-04
**Status:** PLANNING PHASE - Review before execution

---

## Current State Analysis

### Files Currently Tracked (but shouldn't be)
The git index contains **12,000+ deleted files** from `.panther/backups/`, `.phase_backups/`, and `.panther/p3_atomic_replacement/` - these are `.pyc` cache files from historical backups that were accidentally committed.

### Untracked Files (should be committed)
There are **200+ untracked files** that are legitimate source code, documentation, tests, examples, and configuration:
- Source: `compiler/`, `cli/`, `panther_core/`, `package_manager/`, `tools/`
- Tests: `tests/` (48 subdirectories, 1039+ tests)
- Docs: `docs/` (academy, book, cookbook, specification, etc.)
- Examples: `examples/` (11 verified examples)
- Scripts: `scripts/` (cross-platform runners)
- Templates: `project_templates/` (4 templates)
- Config: `pyproject.toml`, `MANIFEST.in`, `LICENSE`, `README.md`
- CI/Engineering: `engineering/`, `manifests/`, `reports/`
- VS Code: `vscode-extension/` (source, not .vsix)

### Temporary/Generated Files (should be ignored)
- `.panther_tmp/` - temp test artifacts
- `dist/`, `build/`, `*.egg-info/` - build artifacts
- `__pycache__/`, `*.pyc` - Python cache
- `.pytest_cache/` - pytest cache
- `.vsix` files - VS Code extension packages
- `.panther/backups/`, `.phase_backups/` - historical backup directories
- `*.tar.gz`, `*.zip` - distribution archives

---

## Cleanup Plan

### KEEP (Commit these - source of truth)
| Category | Paths | Action |
|----------|-------|--------|
| Core Source | `compiler/`, `cli/`, `panther_core/`, `package_manager/`, `tools/` | `git add` |
| Tests | `tests/` (all 48 subdirs) | `git add` |
| Documentation | `docs/` (all subdirs) | `git add` |
| Examples | `examples/` (all 11) | `git add` |
| Scripts | `scripts/` | `git add` |
| Templates | `project_templates/` | `git add` |
| VS Code Ext Source | `vscode-extension/` (source only) | `git add` |
| Config/Manifests | `pyproject.toml`, `MANIFEST.in`, `LICENSE`, `README.md` | `git add` |
| Engineering | `engineering/`, `manifests/`, `reports/` | `git add` |
| Root Docs | `AGENTS.md`, `CHANGELOG.md`, `LANGUAGE_FEATURE_MATRIX.md`, `LANGUAGE_RULES.md`, `MASTER_PROMPT.md`, `PANTHERLANG_REPOSITORY_AUDIT.md`, `PANTHER_PROMPT.md`, `PROJECT_OVERVIEW.md`, `LLM_REFERENCE.md` | `git add` |
| Academy Source | `academy/` | `git add` |

### IGNORE (Add to .gitignore - DO NOT COMMIT)
| Pattern | Reason |
|---------|--------|
| `__pycache__/` | Python bytecode cache |
| `*.py[cod]` | Compiled Python files |
| `*.egg-info/` | Package metadata |
| `dist/` | Build output |
| `build/` | Build output |
| `*.egg` | Legacy egg format |
| `.panther/` | All internal backup/cache |
| `.panther_backups/` | Backup directories |
| `.phase_backups/` | Phase backup directories |
| `.panther_tmp/` | Temporary test artifacts |
| `*.tar.gz` | Distribution archives |
| `*.zip` | Zip archives |
| `*.vsix` | VS Code extension packages |
| `.pytest_cache/` | Pytest cache |
| `.coverage` | Coverage data |
| `.DS_Store` | macOS metadata |
| `Thumbs.db` | Windows metadata |
| `.vscode/` | IDE config (user-specific) |
| `.idea/` | IDE config (user-specific) |
| `TestApp/`, `hello-api/`, `config.json`, `demo_files/`, `test_console/`, `test_web/`, `test_api/`, `test_ai/` | Test project artifacts |
| `payload/` | Payload directory |
| `backups/` | Backup directory |
| `.aider*` | Aider AI tool files |
| `BATCH_*_MANIFEST.json` | Batch manifest files (generated) |
| `bootstrap_*.sh` | Bootstrap scripts (generated) |

### DELETE FROM GIT INDEX (but keep on disk)
These are currently tracked but should be removed from git tracking:
```bash
git rm -r --cached .panther/backups/
git rm -r --cached .phase_backups/
git rm -r --cached .panther/p3_atomic_replacement/
git rm -r --cached dist/
git rm -r --cached build/
git rm -r --cached *.egg-info/
```
Note: Use `--cached` to keep files on disk but remove from git index.

### COMMIT (After cleanup)
1. Updated `.gitignore`
2. All source files (KEEP list)
3. Version reconciliation changes (BATCH 1)
4. Updated docs (CHANGELOG, VERSION_RECONCILIATION, etc.)

---

## Execution Steps

### Step 1: Update .gitignore
Apply the IGNORE patterns above to `.gitignore`

### Step 2: Remove cached backup files
```bash
git rm -r --cached .panther/backups/
git rm -r --cached .phase_backups/
git rm -r --cached .panther/p3_atomic_replacement/
git rm -r --cached dist/
git rm -r --cached build/
git rm -r --cached *.egg-info/
```

### Step 3: Add all legitimate source files
```bash
git add .
```

### Step 4: Verify clean status
```bash
git status --short
```
Should show only modified files (version updates) and new files (docs/releases).

### Step 5: Commit
```bash
git commit -m "chore: v1.1.5 release cleanup - version reconciliation, gitignore update, remove backup artifacts from index"
```

---

## Post-Cleanup Verification

After commit, verify:
- [ ] `git status --short` shows only version-related modifications
- [ ] `git ls-files | wc -l` shows reasonable file count (~200-500 source files)
- [ ] `python -m pytest tests/ -q` still passes (1039 tests)
- [ ] `panther doctor` still passes
- [ ] `bash scripts/run_examples.sh` still passes (11/11)
- [ ] `python -m build` produces `pantherlang-1.1.5.tar.gz` and wheel

---

## Files to Preserve (DO NOT DELETE FROM DISK)
- All source code in `compiler/`, `cli/`, `panther_core/`, `package_manager/`, `tools/`
- All tests in `tests/`
- All docs in `docs/`, `academy/`
- All examples in `examples/`
- All scripts in `scripts/`
- All templates in `project_templates/`
- VS Code extension source in `vscode-extension/`
- Configuration: `pyproject.toml`, `MANIFEST.in`, `LICENSE`, `README.md`
- Engineering evidence: `engineering/`, `manifests/`, `reports/`
- Root documentation: `AGENTS.md`, `CHANGELOG.md`, `LANGUAGE_FEATURE_MATRIX.md`, `LANGUAGE_RULES.md`, `MASTER_PROMPT.md`, `PANTHERLANG_REPOSITORY_AUDIT.md`, `PANTHER_PROMPT.md`, `PROJECT_OVERVIEW.md`, `LLM_REFERENCE.md`