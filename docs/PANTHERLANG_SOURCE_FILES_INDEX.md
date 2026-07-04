# PantherLang Source Files Index

All `.panther` and `.pan` files in the repository.

## Verified Examples (`.pan` — Run with `panther run`)

| # | File | Project | Purpose | Run Command | Status |
|---|------|---------|---------|-------------|--------|
| 1 | `examples/console_hello/main.pan` | console_hello | Variables, functions, print, string concat | `panther run examples/console_hello/main.pan` | ✅ Passes |
| 2 | `examples/calculator/calc.pan` | calculator | Arithmetic, operators, recursion, if | `panther run examples/calculator/calc.pan` | ✅ Passes |
| 3 | `examples/hello_api/main.pan` | hello_api | API template structure | `panther run examples/hello_api/main.pan` | ✅ Passes |
| 4 | `examples/hello_web/main.pan` | hello_web | Web template structure | `panther run examples/hello_web/main.pan` | ✅ Passes |
| 5 | `examples/hello_ai/main.pan` | hello_ai | AI provider info mock | `panther run examples/hello_ai/main.pan` | ✅ Passes |
| 6 | `examples/security_audit_demo/main.pan` | security_audit_demo | Defensive security audit | `panther run examples/security_audit_demo/main.pan` | ✅ Passes |
| 7 | `examples/file_manager/main.pan` | file_manager | Filesystem CRUD | `panther run examples/file_manager/main.pan` | ✅ Passes |
| 8 | `examples/sqlite_crud/main.pan` | sqlite_crud | SQLite database CRUD | `panther run examples/sqlite_crud/main.pan` | ✅ Passes |
| 9 | `examples/http_client/main.pan` | http_client | HTTP GET/POST | `panther run examples/http_client/main.pan` | ✅ Passes |
| 10 | `examples/json_parser/main.pan` | json_parser | JSON encode/decode | `panther run examples/json_parser/main.pan` | ✅ Passes |
| 11 | `examples/config_loader/main.pan` | config_loader | JSON config read/parse | `panther run examples/config_loader/main.pan` | ✅ Passes |
| 12 | `examples/hello.pan` | (standalone) | Basic hello, variables | `panther run examples/hello.pan` | ✅ Passes |

## Phase Demo Files (`.panther` — Language Feature Demos)

These files are in the `examples/` directory and demonstrate specific language features. They use the `.panther` extension and can be run with `panther run`.

| # | File | Feature Area |
|---|------|-------------|
| 1 | `examples/phase6_expressions/expressions_demo.panther` | Arithmetic, comparison, logical expressions |
| 2 | `examples/phase6_control_flow/if_else_demo.panther` | If/elif/else control flow |
| 3 | `examples/phase6_loops/for_loop_demo.panther` | For, while, loop, break, continue |
| 4 | `examples/phase6_functions/function_demo.panther` | Function definition, parameters, recursion |
| 5 | `examples/phase6_structs/struct_demo.panther` | Struct definition and construction |
| 6 | `examples/phase6_modules/module_demo.panther` | Import and module usage |
| 7 | `examples/phase6_stdlib/stdlib_demo.panther` | Standard library functions |
| 8 | `examples/phase6_runtime/runtime_demo.panther` | Runtime behavior and execution |
| 9 | `examples/phase6_fast_regression/fast_regression_demo.panther` | Fast regression test suite |
| 10 | `examples/phase6_final/hello_phase6_10.panther` | Final phase 6 integration |
| 11 | `examples/phase6_production/production_demo.panther` | Production readiness features |
| 12 | `examples/types/phase5_2_types.panther` | Type system and annotations |
| 13 | `examples/types/phase5_2_type_error.panther` | Type error detection |
| 14 | `examples/types/phase6_4_advanced_type_inference.panther` | Advanced type inference |
| 15 | `examples/compiler/phase5_6_unoptimized.panther` | Compiler optimization demo |
| 16 | `examples/compiler/phase6_1_integration.panther` | Compiler integration demo |
| 17 | `examples/compiler/phase6_2_alpha.panther` | Compiler alpha demo |
| 18 | `examples/compiler/phase6_2_beta.panther` | Compiler beta demo |
| 19 | `examples/memory/phase5_3_context.panther` | Memory and context management |
| 20 | `examples/agents/phase5_4_multi_agent.panther` | Multi-agent system |
| 21 | `examples/nlp/phase5_5_natural_language.panther` | Natural language processing |
| 22 | `examples/distributed/phase5_7_distributed.panther` | Distributed computing |
| 23 | `examples/packages/phase5_9_package.panther` | Package management |
| 24 | `examples/ai_native/hello_ai.panther` | AI-native features |
| 25 | `examples/H1/h1_enterprise_demo.panther` | Enterprise demo (Phase H1) |
| 26 | `examples/H2/h2_native_demo.panther` | Native demo (Phase H2) |
| 27 | `examples/H3/h3_vscode_demo.panther` | VS Code demo (Phase H3) |
| 28 | `examples/phase7_agents/agent_demo.panther` | Agent system (Phase 7) |
| 29 | `examples/phase7_cli/cli_run_demo.panther` | CLI run (Phase 7) |
| 30 | `examples/phase7_context/context_demo.panther` | Context (Phase 7) |
| 31 | `examples/phase7_distributed/distributed_demo.panther` | Distributed (Phase 7) |
| 32 | `examples/phase7_final/final_runtime_demo.panther` | Final runtime (Phase 7) |
| 33 | `examples/phase7_memory/memory_demo.panther` | Memory (Phase 7) |
| 34 | `examples/phase7_multi_agent/agents_demo.panther` | Multi-agent (Phase 7) |
| 35 | `examples/phase7_plugins/plugin_demo.panther` | Plugins (Phase 7) |
| 36 | `examples/phase7_runtime/runtime_demo.panther` | Runtime (Phase 7) |
| 37 | `examples/phase7_sandbox/sandbox_demo.panther` | Sandbox (Phase 7) |
| 38 | `examples/phase7_scheduler/task_demo.panther` | Task scheduler (Phase 7) |
| 39 | `examples/phase8_cli/install_demo.panther` | CLI install (Phase 8) |
| 40 | `examples/phase8_debugger/debug_demo.panther` | Debugger (Phase 8) |
| 41 | `examples/phase8_docgen/doc_demo.panther` | Doc generation (Phase 8) |
| 42 | `examples/phase8_formatter/format_demo.panther` | Formatter (Phase 8) |
| 43 | `examples/phase8_lsp/lsp_demo.panther` | LSP (Phase 8) |
| 44 | `examples/phase8_packages/package_demo.panther` | Packages (Phase 8) |
| 45 | `examples/phase8_stdlib/stdlib_demo.panther` | Stdlib (Phase 8) |
| 46 | `examples/phase8_templates/template_demo.panther` | Templates (Phase 8) |
| 47 | `examples/phase8_vscode/vscode_demo.panther` | VS Code (Phase 8) |
| 48 | `examples/phase9_advanced_optimizer/advanced_optimizer_demo.panther` | Advanced optimizer (Phase 9) |
| 49 | `examples/phase9_build/production_build_demo.panther` | Production build (Phase 9) |
| 50 | `examples/phase9_build_cache/build_cache_demo.panther` | Build cache (Phase 9) |
| 51 | `examples/phase9_cross_platform/cross_demo.panther` | Cross-platform (Phase 9) |
| 52 | `examples/phase9_final/final_demo.panther` | Final (Phase 9) |
| 53 | `examples/phase9_incremental/incremental_demo.panther` | Incremental (Phase 9) |
| 54 | `examples/phase9_optimizer/optimizer_demo.panther` | Optimizer (Phase 9) |
| 55 | `examples/phase9_packaging/packaging_demo.panther` | Packaging (Phase 9) |
| 56 | `examples/phase9_release/release_demo.panther` | Release (Phase 9) |
| 57 | `examples/phase9_toolchain/toolchain_demo.panther` | Toolchain (Phase 9) |
| 58 | `examples/phase10_distribution/distribution_demo.panther` | Distribution (Phase 10) |
| 59 | `examples/phase10_docs/documentation_demo.panther` | Documentation (Phase 10) |
| 60 | `examples/phase10_registry/registry_demo.panther` | Registry (Phase 10) |
| 61 | `examples/phase10_release/stable_release.panther` | Stable release (Phase 10) |
| 62 | `examples/phase10_stable/stable_demo.panther` | Stable demo (Phase 10) |
| 63 | `examples/phase_6_8_lsp/hello_lsp.panther` | LSP hello (Phase 6.8) |
| 64 | `examples/phase_6_9_toolchain/hello_cross.panther` | Cross-platform hello (Phase 6.9) |
| 65 | `examples/store.panther` | Store example |
| 66 | `examples/workspace/app/main.panther` | Workspace app |
| 67 | `examples/workspace/core/core.panther` | Workspace core |
| 68 | `examples/ai_native/hello_ai.panther` | AI native hello |

## Template Files

| File | For |
|------|-----|
| `project_templates/console_app/src/main.panther` | `panther new console` |
| `project_templates/web_app/src/main.panther` | `panther new web` |
| `project_templates/api_app/src/main.panther` | `panther new api` |
| `project_templates/ai_app/src/main.panther` | `panther new ai` |
| `vscode-extension/project_templates/console_app/src/main.panther` | VS Code new console |
| `vscode-extension/project_templates/web_app/src/main.panther` | VS Code new web |
| `vscode-extension/project_templates/api_app/src/main.panther` | VS Code new api |
| `vscode-extension/project_templates/ai_app/src/main.panther` | VS Code new ai |
| `docs/examples/console/main.panther` | Documentation example |
| `docs/examples/web/main.panther` | Documentation example |
| `docs/examples/api/main.panther` | Documentation example |
| `docs/examples/ai/main.panther` | Documentation example |

## Language Spec Files (`.panther` in `language/`)

Type definitions and specifications in `language/` directory (20 files) — used by the formal language specification, not directly runnable.

## Note

Only the 12 `.pan` files under `examples/` are tested as verified examples in `tests/test_examples.py`. The `.panther` files in `examples/` are phase demo files that may use a different execution pipeline.
