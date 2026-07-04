# PantherLang AI Knowledge Pack

**Version:** 1.1.5
**Date:** 2026-07-04

This directory provides structured knowledge for AI agents working with PantherLang. The authoritative source files are in `docs/agent_knowledge/`.

## Quick Navigation

| Document | Purpose | Location |
|----------|---------|----------|
| **Agent Guide** | How AI agents should work in PantherLang projects | `../agent_knowledge/PANTHERLANG_AGENT_GUIDE.md` |
| **Agent Prompts** | Prompt templates for creating projects | `../agent_knowledge/PANTHERLANG_AGENT_PROMPTS.md` |
| **Grammar Quick Reference** | Syntax reference for code generation | `../agent_knowledge/PANTHERLANG_GRAMMAR_QUICK_REFERENCE.md` |
| **Project Conventions** | Standard project layout and manifest | `../agent_knowledge/PANTHERLANG_PROJECT_CONVENTIONS.md` |

## Key Facts for AI Agents

- **Language:** PantherLang (`.panther`, `.pan`)
- **Version:** 1.1.5 (stable release)
- **Entry point:** `panther main { }` block
- **Project manifest:** `panther.toml`
- **Source location:** `src/main.panther`
- **CLI commands:** `panther run/build/check/new/doctor/version`
- **Security rule:** Never hardcode API keys — use environment variables
- **Type system:** Explicit conversion only (no implicit comparison conversion)

## Verification Commands

```bash
# Verify PantherLang installation
panther doctor

# Run a PantherLang file
panther run src/main.panther

# Check syntax without executing
panther check src/main.panther

# Create new project
panther new console my-app
```

## Project Types

| Type | Description | Template Command |
|------|-------------|------------------|
| `console` | Command-line application | `panther new console <name>` |
| `web` | Web application with HTTP server | `panther new web <name>` |
| `api` | REST API structure | `panther new api <name>` |
| `ai` | AI-integrated application | `panther new ai <name>` |

## Standard Library Highlights

43 built-in functions across 11 categories:
- **String** (11): len, upper, lower, trim, contains, replace, split, join, substring, starts_with, ends_with
- **Math** (10): abs, max, min, pow, sqrt, floor, ceil, round, random, randint
- **JSON** (2): json_encode, json_decode
- **Time** (2): time, sleep
- **Type Conversion** (3): int, float, string
- **Crypto** (4): sha256, hmac_sha256, secure_token, secure_compare
- **Security** (2): sanitize_path, sanitize_html
- **Filesystem** (6): read_file, write_file, file_exists, mkdir, list_dir, remove_file
- **HTTP** (2): http_get, http_post
- **Regex** (3): regex_match, regex_replace, regex_split
- **Collections** (4): array_push, array_pop, array_sort, array_reverse
- **SQLite** (4): db_open, db_close, db_execute, db_query

## AI Platform (Python API)

```python
from compiler.ai.providers import OpenAIProvider, AnthropicProvider, GeminiProvider, OllamaProvider, OpenRouterProvider
from compiler.ai.agents import Agent
from compiler.ai.secure_agent import SecureAgent
from compiler.ai.rag import RAGEngine
```

All providers support mock mode (no API keys required for testing).

## VS Code Extension

- **Version:** 1.1.5
- **Location:** `vscode-extension/`
- **Features:** Syntax highlighting, snippets, debug adapter, LSP server, project wizard

## Important Links

- **Full Language Reference:** `docs/book/chapters/14-language-reference.md`
- **Standard Library Reference:** `docs/book/chapters/07-standard-library.md`
- **Security Guide:** `docs/SECURITY_GUIDE.md`
- **CLI Guide:** `docs/CLI_GUIDE.md`
- **Developer Guide:** `docs/DEVELOPER_GUIDE.md`
- **Academy Lessons:** `docs/academy/`
- **Examples:** `examples/`

---

*This is a summary document. For complete details, see the authoritative files in `docs/agent_knowledge/` and the full documentation in `docs/`.*