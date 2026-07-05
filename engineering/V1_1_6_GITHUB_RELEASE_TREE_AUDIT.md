# PantherLang v1.1.6 GitHub Release Tree Audit

**Generated:** 2026-07-04  
**Repo Size:** 370M (Git: 57M)  
**Goal:** Clean GitHub release tree for `git clone https://github.com/ferasbackagain/PantherLang.git`

---

## Classification Legend

| Classification | Meaning | Action |
|---|---|---|
| **KEEP_FOR_GITHUB** | Required for build/run/test/docs/learn/contribute | Keep in Git, ship to GitHub |
| **KEEP_LOCAL_ONLY** | Required for local dev/CI but not for GitHub users | Keep in Git, add to .gitignore |
| **MOVE_TO_LOCAL_ARCHIVE** | Historical/backup/archival, not needed for GitHub | Move to `../PantherLang_local_archive_v1_1_6/` |
| **IGNORE_FUTURE** | Generated/temp files that should be gitignored | Add to .gitignore, remove from tracking if tracked |
| **REMOVE_FROM_GIT_TRACKING** | Tracked files that are generated/cache | `git rm --cached` |
| **REQUIRES_HUMAN_REVIEW** | Uncertain classification, needs human decision | Flag for human review |

---

## 1. Source Code - KEEP_FOR_GITHUB

```
pantherlang/                    # Core package (pip install pantherlang)
├── compiler/                   # Full compiler pipeline
│   ├── lexer/                  # Tokenizer
│   ├── parser/                 # Pratt parser + recursive descent
│   ├── ast/                    # Frozen dataclass AST nodes
│   ├── semantic/               # Symbol table, scope, diagnostics
│   ├── types/                  # Type system, checker, inference
│   ├── runtime/                # Tree-walking interpreter
│   ├── stdlib/                 # 54 stdlib functions (12 categories)
│   ├── security/               # Security analyzer, sandbox, web/AI security
│   ├── web/                    # HTTP server, routing, security middleware
│   ├── ai/                     # AI providers, agents, RAG, secure agent
│   └── database/               # SQLite engine, ORM, migrations
├── cli/                        # panther CLI entry point
├── panther_core/               # Version info
├── package_manager/            # Dependency resolution, lock files
├── project_templates/          # Scaffolds: console, web, api, ai
└── tests/                      # 1006+ tests (48 subdirs)

cli/                            # CLI entry point (panther_cli.py)
compiler/                       # Formal compiler pipeline (alternative structure)
runtime/                        # Runtime system
stdlib/                         # Standard library
tools/                          # Toolchain: formatter, LSP, debugger, toolchain
tools/panther-lsp/              # LSP server
tools/panther-toolchain/        # Cross-platform toolchain
tools/panther-regression/       # Regression testing
tools/project_runner-toolchain/                # Legacy?
```

**Verdict:** **KEEP_FOR_GITHUB** - Core product, required for build/run/test/learn/contribute

---

## 2. Documentation - KEEP_FOR_GITHUB

```
docs/                           # Full documentation tree
├── specification/              # 8-spec formal language reference
├── architecture/               # Architecture docs
├── cli/                        # CLI docs
├── security/                   # Security docs
├── dev_guides/                 # Developer guides
├── language_ref/               # Language reference
└── specification/              # Formal spec

README.md                       # Main README
PROJECT_OVERVIEW.md             # Project overview
AGENTS.md                       # AI agent guide
PUBLIC_LAUNCH_CHECKLIST.md      # Launch checklist
PANTHERLANG_REPOSITORY_AUDIT.md # Repo audit
RELEASE_LOCAL_CHECKLIST.md      # Release checklist
RELEASE_GIT_CLEANUP_PLAN.md     # This cleanup plan
PANTHERLANG_MASTER_PROMPT_AIDER_OLLAMA_V1.md
PANTHERLANG_ZBORA_ZB_PLAN.md
README_*.md                     # Various feature READMEs
```

**Verdict:** **KEEP_FOR_GITHUB** - Required for docs/learn/contribute

---

## 3. Examples & Learning - KEEP_FOR_GITHUB

```
examples/                       # 6 runnable examples + 68 phase demo files
├── console_hello/
├── web_hello/
├── api_hello/
├── ai_hello/
├── console_app/
└── web_app/

playground/                     # Learning playground
├── language_tests/             # Basic language tests
└── advanced_language_tests/    # Advanced features

projects/                       # Example projects
├── console_demo/
├── file_editor/
├── security_tool/
└── sqlite_app/

academy/                        # Academy lessons (tests/academy/)
```

**Verdict:** **KEEP_FOR_GITHUB** - Required for learn/examples

---

## 4. VS Code Extension Source - KEEP_FOR_GITHUB

```
vscode-extension/               # VS Code extension v1.1.5 source
├── src/                        # Extension source
├── package.json                # Extension manifest
├── tsconfig.json
├── webpack.config.js
├── .vscodeignore               # VS Code package ignore
├── CHANGELOG.md
├── LICENSE
└── README.md

vscode_extension/               # Duplicate/legacy? (REVIEW)
```

**Verdict:** **KEEP_FOR_GITHUB** (vscode-extension/) - Required for VS Code extension source  
**REQUIRES_HUMAN_REVIEW** (vscode_extension/) - Likely duplicate/legacy

---

## 5. Tests - KEEP_FOR_GITHUB

```
tests/                          # Main test suite (1006+ tests)
├── phase*/                     # Phase-based tests
├── phase*/                     # Phase-based tests (legacy naming)
├── R3_*/                       # R3 regression tests
├── P2_*/                       # P2 debug adapter tests
├── P3_*/                       # P3 atomic replacement tests
├── security/                   # Security tests
├── academy/                    # Academy lesson tests
├── conformance/                # Conformance tests
├── stress_tests/               # Stress tests
├── benchmarks/                 # Benchmarks
├── test_*.py                   # Top-level test files
└── conftest.py                 # Pytest config

qa/                             # QA enterprise tests
```

**Verdict:** **KEEP_FOR_GITHUB** - Required for test/contribute

---

## 6. Release Artifacts (Historical) - MOVE_TO_LOCAL_ARCHIVE

```
releases/                       # All historical releases
├── 0.9.10.tar.gz
├── 0.9.10/
├── P2_debug_adapter_rebuilt_rc/
├── P3_OFFICIAL/
├── P3_RC/
├── P3_OFFICIAL/
├── R1_product_unification/
├── R3_developer_experience/
├── panther_debug_adapter_rebuilt_P2_RC_20260629_105102.tar.gz
└── vscode_marketplace/         # 12+ VSIX files
    ├── pantherlang-0.8.8.vsix
    ├── pantherlang-1.0.0.vsix
    ├── pantherlang-1.0.1.vsix
    ├── pantherlang-1.0.2.vsix
    ├── pantherlang-1.0.3.vsix
    ├── pantherlang-1.0.4.vsix
    ├── pantherlang-1.0.5.vsix
    ├── pantherlang-1.0.6.vsix
    ├── pantherlang-1.0.7.vsix
    ├── pantherlang-1.1.0.vsix
    ├── pantherlang-1.1.1.vsix
    └── *.sha256

pantherlang_R3_batch*.zip       # 20+ batch zip files (root)
pantherlang_all_in_one_reference_bundle.zip
pantherlang_all_in_one_reference_bundle/
pantherlang_batch4_v4/
pantherlang_reference_bundle/
r3_regression_repair_batches.zip
r3_regression_repair_batches_v2.zip
p3_batch7_5_debug_adapter_compatibility_restoration_scripts.zip
bootstrap_R3_batch2_part3_1_AST_Definitions.zip
```

**Verdict:** **MOVE_TO_LOCAL_ARCHIVE** - Historical releases, not needed for GitHub clone
**Destination:** `../PantherLang_local_archive_v1_1_6/releases/`

---

## 6. Reports (Engineering/Historical) - MOVE_TO_LOCAL_ARCHIVE

```
reports/                        # 100+ engineering reports
├── H1/, H2/, H3/, H4_5/
├── P2/, P3/
├── R1_product_unification/
├── R2_marketplace/
├── R3_*/
├── p3_batch*/
├── recovery/
└── vscode_marketplace/

engineering/                    # This audit file location
```

**Verdict:** **MOVE_TO_LOCAL_ARCHIVE** - Historical engineering reports
**Destination:** `../PantherLang_local_archive_v1_1_6/reports/`

---

## 7. Backup Directories - MOVE_TO_LOCAL_ARCHIVE

```
.panther_backups/               # 40+ backup tarballs
.phase_backups/                 # Phase backup directories
.panther/backups/               # Nested backup directories (deeply nested)
.panther_tmp/                   # Temp directory
.payload/                       # Payload directory
backups/                        # Referenced in .gitignore
```

**Verdict:** **MOVE_TO_LOCAL_ARCHIVE** - Local backups only
**Destination:** `../PantherLang_local_archive_v1_1_6/backups/`

---

## 8. Build/Dist Artifacts (Tracked) - REMOVE_FROM_GIT_TRACKING

```
dist/                           # Python build artifacts (TRACKED!)
├── pantherlang-1.0.0-py3-none-any.whl
├── pantherlang-1.0.0.tar.gz
├── pantherlang-1.1.6-py3-none-any.whl
├── pantherlang-1.1.6.tar.gz

pantherlang.egg-info/           # Egg info (TRACKED!)
build/                          # Build directory (TRACKED!)
.vscode-extension/dist/         # VSIX build output (TRACKED!)
vscode-extension/dist/          # VSIX build output (TRACKED!)
```

**Verdict:** **REMOVE_FROM_GIT_TRACKING** - Generated build artifacts
**Action:** `git rm -r --cached dist/ build/ pantherlang.egg-info/ vscode-extension/dist/ .vscode-extension/dist/`

---

## 9. Python Cache Directories (Tracked) - REMOVE_FROM_GIT_TRACKING

```
**/__pycache__/                 # Hundreds of __pycache__ directories (TRACKED!)
**/*.pyc                        # Hundreds of .pyc files (TRACKED!)
.pytest_cache/                  # Pytest cache (TRACKED!)
.mypy_cache/                    # MyPy cache
.ruff_cache/                    # Ruff cache
.coverage                       # Coverage data
htmlcov/                        # HTML coverage
```

**Verdict:** **REMOVE_FROM_GIT_TRACKING** + **IGNORE_FUTURE**
**Action:** `git rm -r --cached **/__pycache__/ **/*.pyc .pytest_cache/ .mypy_cache/ .ruff_cache/ .coverage htmlcov/`

---

## 10. Local Test Projects - IGNORE_FUTURE (already in .gitignore)

```
TestApp/                        # Local test app
hello-api/                      # Local test
config.json                     # Local config
demo_files/                     # Demo files
test_console/                   # Test project
test_web/                       # Test project
test_api/                       # Test project
test_ai/                        # Test project
```

**Verdict:** **IGNORE_FUTURE** - Already in .gitignore, ensure not tracked

---

## 11. Bootstrap Scripts (Root) - KEEP_LOCAL_ONLY / MOVE_TO_LOCAL_ARCHIVE

```
bootstrap_*.sh                  # 50+ bootstrap scripts in root
bootstrap_*.zip                 # Bootstrap zips
scripts/run_*.sh                # Runner scripts (KEEP_FOR_GITHUB)
scripts/run_*.bat               # Windows runners (KEEP_FOR_GITHUB)
scripts/run_*.ps1               # PowerShell runners (KEEP_FOR_GITHUB)
scripts/verify_*.sh             # Verification scripts (KEEP_FOR_GITHUB)
scripts/test.sh                 # Test runner (KEEP_FOR_GITHUB)
scripts/run_conformance.sh      # Conformance runner (KEEP_FOR_GITHUB)
scripts/run_examples.sh         # Examples runner (KEEP_FOR_GITHUB)
scripts/run_store.sh            # Store runner (KEEP_FOR_GITHUB)
```

**Verdict:** 
- `scripts/` → **KEEP_FOR_GITHUB** (official runners)
- Root `bootstrap_*.sh` → **MOVE_TO_LOCAL_ARCHIVE** (historical bootstrap scripts)
- Root `bootstrap_*.zip` → **MOVE_TO_LOCAL_ARCHIVE**

---

## 12. Manifest/Manifest Files - KEEP_LOCAL_ONLY / MOVE_TO_LOCAL_ARCHIVE

```
manifests/                      # Manifest JSON files
├── academy_lessons01_05_stdlib_runtime_fix.json
├── phase2_batch2_*.json
├── stdlib_s1_s6_*.json
├── v1_1_5_rc1_*.json
├── web_runtime_fix*.json
BATCH_*_MANIFEST.json           # Root manifest files
```

**Verdict:** **MOVE_TO_LOCAL_ARCHIVE** - Build-time manifests
**Destination:** `../PantherLang_local_archive_v1_1_6/manifests/`

---

## 13. Registry & Package Artifacts - KEEP_FOR_GITHUB / MOVE_TO_LOCAL_ARCHIVE

```
registry/                       # Package registry
├── index.json
├── published/                  # Published packages
├── registry_cli.py
└── registry_manifest.json

package_manager/                # Package manager (source)
```

**Verdict:** 
- `registry/` source → **KEEP_FOR_GITHUB**
- `registry/published/` → **MOVE_TO_LOCAL_ARCHIVE** (published packages cache)

---

## 14. Language/ Runtime Duplicate Structures - REQUIRES_HUMAN_REVIEW

```
language/                       # Alternative language implementation?
├── compiler/
├── runtime/
├── stdlib/
├── models/
├── registry/
├── repl/
├── packages/
├── distributed/
├── memory/
├── nlp/
├── testing/
├── tools/
├── types/
├── examples/
├── tests/
└── panther.py

runtime/                        # Another runtime?
├── agents/
├── ai_runtime/
├── context_state/
├── distributed/
├── final_integration/
├── memory/
├── multi_agent/
├── panther_vm/
├── plugins/
├── sandbox/
├── task_scheduler/
├── version.py
└── runtime_manifest.json

compiler/                       # Yet another compiler?
├── ast/
├── parser/
├── types/
├── expressions/
├── stdlib/
├── modules/
├── optimization/
├── ai/
├── web/
├── control_flow/
├── structs/
├── runtime_contract/
├── lexer/
├── semantic/
├── functions/
├── runtime/
├── security/
├── database/
├── loops/
└── parser/

toolchain/                      # Toolchain?
tools/                          # Tools?
stdlib/                         # Stdlib?
```

**Verdict:** **REQUIRES_HUMAN_REVIEW** - Multiple duplicate/parallel implementations
**Action:** Determine canonical structure, archive duplicates

---

## 15. Debug Adapter & Related - MOVE_TO_LOCAL_ARCHIVE / KEEP_FOR_GITHUB

```
debug_adapter/                  # Debug adapter source
debug_adapter_rebuilt/          # Rebuilt debug adapter
debug_adapter_bridge/           # Bridge
releases/P3_RC/.../debug_adapter/  # In releases
releases/P3_RC/.../debug_adapter_rebuilt/
releases/P3_RC/.../debug_adapter_bridge/
.panther/backups/.../debug_adapter/  # In backups
```

**Verdict:** 
- Source in `vscode-extension/src/` or `tools/debugger/` → **KEEP_FOR_GITHUB**
- Duplicate builds in `releases/`, `.panther/backups/`, `debug_adapter_rebuilt/` → **MOVE_TO_LOCAL_ARCHIVE**

---

## 16. Misc Root Files - CLASSIFY INDIVIDUALLY

| File | Classification | Reason |
|------|---------------|--------|
| `panther` (executable) | REMOVE_FROM_GIT_TRACKING | Generated binary |
| `pantherlang-icon.png` | KEEP_FOR_GITHUB | Official icon |
| `llms.txt`, `llms-full.txt` | KEEP_FOR_GITHUB | LLM context files |
| `main` (executable) | REMOVE_FROM_GIT_TRACKING | Generated binary |
| `pyproject.toml` | KEEP_FOR_GITHUB | Build config |
| `.aider.chat.history.md` | IGNORE_FUTURE | AI chat history |
| `.aider.input.history` | IGNORE_FUTURE | AI input history |
| `.aider.tags.cache.v4/` | IGNORE_FUTURE | AI cache |
| `PANTHER_PROMPT.md` | KEEP_LOCAL_ONLY | Internal prompt |
| `RELEASE_GIT_CLEANUP_PLAN.md` | KEEP_LOCAL_ONLY | This plan |

---

## 17. IDE/OS Files - IGNORE_FUTURE (mostly in .gitignore)

```
.vscode/                        # VS Code settings (in .gitignore)
.idea/                          # IntelliJ (in .gitignore)
.DS_Store                       # macOS (in .gitignore)
Thumbs.db                       # Windows (in .gitignore)
```

---

## Summary Statistics

| Classification | Count (Est.) | Size Est. |
|---|---|---|
| KEEP_FOR_GITHUB | ~50 dirs, 2000+ files | ~50 MB |
| KEEP_LOCAL_ONLY | ~5 dirs | ~5 MB |
| MOVE_TO_LOCAL_ARCHIVE | ~30 dirs, 100+ files | ~200 MB |
| IGNORE_FUTURE | ~50 dirs | ~50 MB (cache) |
| REMOVE_FROM_GIT_TRACKING | ~500 dirs, 5000+ files | ~100 MB |
| REQUIRES_HUMAN_REVIEW | ~10 dirs | ~50 MB |

---

## Action Plan

### Phase 1: Update .gitignore (Professional)
- Add comprehensive patterns for all cache/build/temp files
- Ensure `.panther/`, `.phase_backups/`, `.panther_backups/`, `.panther_tmp/`, `payload/`, `backups/` are ignored
- Ensure `dist/`, `build/`, `*.egg-info/`, `*.vsix`, `*.zip`, `*.tar.gz`, `*.whl` are ignored
- Ensure `__pycache__/`, `*.pyc`, `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `.coverage`, `htmlcov/` are ignored
- Ensure `TestApp/`, `hello-api/`, `test_*/`, `demo_files/`, `config.json` are ignored
- Ensure `.aider*`, `BATCH_*_MANIFEST.json`, `bootstrap_*.sh` are ignored

### Phase 2: Remove Tracked Generated Files
```bash
git rm -r --cached dist/ build/ pantherlang.egg-info/
git rm -r --cached vscode-extension/dist/ .vscode-extension/dist/
git rm -r --cached **/__pycache__/ **/*.pyc .pytest_cache/ .mypy_cache/ .ruff_cache/ .coverage htmlcov/
git rm --cached panther main pantherlang-icon.png  # if generated
```

### Phase 3: Move Local Archives
```bash
mkdir -p ../PantherLang_local_archive_v1_1_6/{releases,reports,backups,manifests,bootstrap}
mv releases/ ../PantherLang_local_archive_v1_1_6/releases/
mv reports/ ../PantherLang_local_archive_v1_1_6/reports/
mv .panther_backups/ .phase_backups/ .panther/backups/ ../PantherLang_local_archive_v1_1_6/backups/
mv manifests/ ../PantherLang_local_archive_v1_1_6/manifests/
mv bootstrap_*.sh bootstrap_*.zip ../PantherLang_local_archive_v1_1_6/bootstrap/
mv pantherlang_R3_batch*.zip pantherlang_all_in_one_reference_bundle* pantherlang_batch4_v4/ pantherlang_reference_bundle/ ../PantherLang_local_archive_v1_1_6/
mv r3_regression_repair_batches*.zip p3_batch7_5_debug_adapter*.zip bootstrap_R3_batch2_part3_1_AST_Definitions.zip ../PantherLang_local_archive_v1_1_6/
```

### Phase 4: Human Review Required
- `language/`, `runtime/`, `compiler/`, `toolchain/`, `tools/`, `stdlib/` - Determine canonical structure
- `vscode_extension/` vs `vscode-extension/` - Remove duplicate
- `debug_adapter/`, `debug_adapter_rebuilt/`, `debug_adapter_bridge/` - Determine canonical location
- `registry/published/` - Archive published packages
- Root `panther`, `main` executables - Confirm generated

### Phase 5: Verify
```bash
git status --short
python -m pytest tests/ -q
bash scripts/run_examples.sh
python -m cli.panther_cli doctor
python -m build
```

---

## GitHub Release Tree (Expected After Cleanup)

```
PantherLang/
├── .github/                      # GitHub workflows (if any)
├── .gitignore                    # Professional ignore rules
├── AGENTS.md                     # AI agent guide
├── README.md                     # Main README
├── pyproject.toml                # Build config
├── pantherlang-icon.png          # Official icon
├── llms.txt                      # LLM context
├── llms-full.txt                 # Full LLM context
├── pantherlang/                  # Core package (pip installable)
│   ├── compiler/
│   ├── cli/
│   ├── panther_core/
│   ├── package_manager/
│   ├── project_templates/
│   └── tests/
├── cli/                          # CLI entry
├── compiler/                     # Formal compiler
├── runtime/                      # Runtime
├── stdlib/                       # Stdlib
├── tools/                        # Toolchain
├── tests/                        # Test suite
├── examples/                     # Runnable examples
├── playground/                   # Learning playground
├── projects/                     # Example projects
├── academy/                      # Academy lessons
├── docs/                         # Documentation
├── vscode-extension/             # VS Code extension source
├── scripts/                      # Official runners
├── project_templates/            # Project scaffolds
├── registry/                     # Package registry source
├── engineering/                  # Engineering docs (this audit)
├── architecture/                 # Architecture docs
├── benchmarks/                   # Benchmarks
├── qa/                           # QA tests
├── stable/                       # Stable releases
├── production/                   # Production configs
├── production_toolchain/         # Production toolchain
├── templates/                    # Templates
├── website/                      # Website source
└── registry/                     # Package registry
```

---

## Sign-Off

- [ ] .gitignore updated professionally
- [ ] Tracked generated files removed from Git tracking
- [ ] Local archives moved to `../PantherLang_local_archive_v1_1_6/`
- [ ] Human review completed for ambiguous directories
- [ ] `git status --short` shows only expected changes
- [ ] `python -m pytest tests/ -q` passes (0 failed)
- [ ] `bash scripts/run_examples.sh` passes
- [ ] `python -m cli.panther_cli doctor` passes
- [ ] `python -m build` succeeds
- [ ] **GIT PUSH APPROVED**

**Prepared by:** AI Agent  
**Reviewed by:** [Human]  
**Date:** 2026-07-04