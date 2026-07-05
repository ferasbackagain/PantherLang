# PantherLang v1.1.6 — Duplicate Resolution Plan

**Date:** 2026-07-04
**Phase:** 2

---

## Items Requiring Action

| # | Path | Classification | Action | When |
|---|------|---------------|--------|------|
| 1 | `.panther/` (817 tracked files) | GENERATED_ARTIFACT | Remove from tracking, add to .gitignore | Phase 19 |
| 2 | `debug_adapter_bridge/` (27 tracked) | STALE_DUPLICATE | Remove from tracking | Phase 19 |
| 3 | `debug_adapter_rebuilt/` (36 tracked) | STALE_DUPLICATE | Remove from tracking | Phase 19 |
| 4 | `debug_adapter_legacy_P3_20260629_111133/` (39 tracked) | LOCAL_ARCHIVE | Remove from tracking, archive off-tree | Phase 19 |
| 5 | `vscode_extension/` (underscore, 9 tracked) | STALE_DUPLICATE | Remove from tracking | Phase 19 |
| 6 | `stdlib/` (top-level, 9 tracked) | HISTORICAL | Remove from tracking, preserve as archive | Phase 19 |
| 7 | `toolchain/` (18 tracked) | HISTORICAL | Remove from tracking | Phase 19 |
| 8 | `bootstrap_*.sh` (100 files) | HISTORICAL_ARTIFACT | Move to archive directory | Phase 19 |
| 9 | `README_*` docs (25 files) | HISTORICAL_ARTIFACT | Move to archive directory | Phase 19 |
| 10 | `BATCH_*_MANIFEST.json` (8 files) | HISTORICAL_ARTIFACT | Move to archive directory | Phase 19 |
| 11 | `.aider.*` files | LOCAL_AI_STATE | Add to .gitignore | Phase 19 |
| 12 | `build_system/` | HISTORICAL | Archive off-tree | Phase 19 |
| 13 | `distribution/` | HISTORICAL | Archive off-tree | Phase 19 |
| 14 | `hardening/` | HISTORICAL | Archive off-tree | Phase 19 |
| 15 | `installer/` / `installers/` | HISTORICAL | Archive off-tree | Phase 19 |
| 16 | `manifests/` (18 tracked) | HISTORICAL | Remove from tracking, archive | Phase 19 |
| 17 | `native_executables/` | GENERATED | Add to .gitignore | Phase 19 |
| 18 | `official_registry/` | EMPTY | Remove | Phase 19 |
| 19 | `optimizer/` | HISTORICAL | Archive | Phase 19 |
| 20 | `packages/` | EMPTY | Remove | Phase 19 |
| 21 | `payload/` | GENERATED | Already gitignored | ✅ |
| 22 | `production/` / `production_toolchain/` | HISTORICAL | Archive | Phase 19 |
| 23 | `qa/` | HISTORICAL | Archive | Phase 19 |
| 24 | `registry/` | HISTORICAL | Remove from tracking, archive | Phase 19 |
| 25 | `release/` / `release_engineering/` | HISTORICAL | Archive | Phase 19 |
| 26 | `releases/` (212 tracked) | HISTORICAL | Keep (release history archive) | No action |
| 27 | `reports/` (95 tracked) | HISTORICAL | Keep (engineering reports) | No action |
| 28 | `architecture/` (48 tracked) | HISTORICAL | Keep (architecture docs) | No action |
| 29 | `stable/` | HISTORICAL | Archive | Phase 19 |
| 30 | `website/` | HISTORICAL | Archive | Phase 19 |
| 31 | `playground/` (13 tracked) | HISTORICAL | Keep (may be active) | No action |
| 32 | `projects/` (8 tracked) | HISTORICAL | Keep (may be active) | No action |
| 33 | `reference_bundle/` dirs (3 dirs, tracked) | HISTORICAL | Remove from tracking, archive | Phase 19 |
| 34 | `p3_batch7_5_scripts/` (7 tracked) | HISTORICAL | Remove from tracking, archive | Phase 19 |
| 35 | `_conformance_test/` | AMBIGUOUS | Investigate | Phase 3 |
| 36 | `TestApp/` (9 tracked) | GENERATED | Remove from tracking, gitignore | Phase 19 |
| 37 | `hello-api/` (9 tracked) | GENERATED | Remove from tracking, gitignore | Phase 19 |
| 38 | `demo_files/` | GENERATED | Already gitignored | ✅ |

## Items to KEEP (not duplicates)

| Path | Reason |
|------|--------|
| `language/` | **INTEGRATED** — `compiler/core/compiler.py` imports `language.compiler.core` |
| `runtime/` | **TEST_DEPENDENCY** — Phase 7 tests import from it |
| `cli/panther_cli_v2.py` | Alternative CLI implementation |
| `dist/` | Already gitignored |
| `build/` | Already gitignored |

## Archive Procedure (Phase 19)

1. Create `/home/panther/pantherlang/PantherLang_Developer_Edition_v0_5/.archive/` directory
2. Copy all HISTORICAL/LOCAL_ARCHIVE items into `.archive/` with timestamped subdirs
3. Remove HISTORICAL items from git tracking (`git rm --cached`)
4. Update `.gitignore` for GENERATED/LOCAL patterns
5. Verify nothing breaks (tests pass, CLI works)
6. Optionally move `.archive/` off-tree when ready

## Items NOT to touch

- `releases/` — Contains release history
- `reports/` — Contains engineering reports  
- `architecture/` — Contains architecture documentation
- `playground/` — May be active
- `projects/` — May be active
- `language/` — CANNOT remove; compiler depends on it
- `runtime/` — CANNOT remove; tests depend on it
