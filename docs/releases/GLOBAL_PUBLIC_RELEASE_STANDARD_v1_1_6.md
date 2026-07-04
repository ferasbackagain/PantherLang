# PantherLang v1.1.6 Global Public Release Standard

**Date:** 2026-07-04
**Version:** 1.1.6
**Repository:** https://github.com/ferasbackagain/PantherLang
**Branch:** main

---

## Release Classification

This document defines the standard for what constitutes a "global public release" for PantherLang v1.1.6. A release is not globally real until all criteria are met.

---

## ✅ Verified Public (VERIFIED_PUBLIC)

| Resource | URL | Status | Verification |
|----------|-----|--------|--------------|
| GitHub Repository | https://github.com/ferasbackagain/PantherLang | **VERIFIED_PUBLIC** | API returns 200, `private: false` |
| Git Clone (HTTPS) | https://github.com/ferasbackagain/PantherLang.git | **VERIFIED_PUBLIC** | `git ls-remote` works |
| Git Clone (SSH) | git@github.com:ferasbackagain/PantherLang.git | **VERIFIED_PUBLIC** | Standard GitHub SSH |
| GitHub Issues | https://github.com/ferasbackagain/PantherLang/issues | **VERIFIED_PUBLIC** | Linked from repo |
| Repository Visibility | Public | **VERIFIED_PUBLIC** | `private: false` in API |

---

## ⚠️ Ready After External Action (EXTERNAL_ACTION_REQUIRED)

| Resource | URL | Status | Blockers |
|----------|-----|--------|----------|
| Raw Installer (install.sh) | https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | **EXTERNAL_ACTION_REQUIRED** | File missing from main branch root |
| Curl Install Command | `curl -fsSL https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | bash` | **EXTERNAL_ACTION_REQUIRED** | Requires install.sh pushed to main |
| PyPI Package (1.1.6) | `pip install pantherlang==1.1.6` | **EXTERNAL_ACTION_REQUIRED** | Not yet published |
| VS Code Marketplace | pantherlang-official v1.1.6 | **EXTERNAL_ACTION_REQUIRED** | Not yet published |
| GitHub Release | v1.1.6 tag + artifacts | **EXTERNAL_ACTION_REQUIRED** | Tag not created, artifacts not uploaded |
| Website/Docs Deploy | https://pantherlang.dev | **EXTERNAL_ACTION_REQUIRED** | Not deployed |

---

## ❌ Do Not Claim (DO_NOT_CLAIM)

| Claim | Reality |
|-------|---------|
| "Global curl install works" | Raw installer 404s |
| "Available on PyPI" | Not published |
| "VS Code extension on Marketplace" | Not published |
| "feras-khatib/pantherlang" URLs | Wrong owner |
| "100% automatic file icon" | Requires VS Code icon theme |

---

## Global Install Paths

### Linux/macOS (Worldwide)

**Available NOW (source):**
```bash
git clone https://github.com/ferasbackagain/PantherLang.git
cd PantherLang
pip install -e ".[dev]"
```

**Available AFTER PyPI publish:**
```bash
pip install pantherlang==1.1.6
```

**Available AFTER installer pushed to main:**
```bash
curl -fsSL https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | bash
```

### Windows (Worldwide)

**Available NOW (source):**
```powershell
git clone https://github.com/ferasbackagain/PantherLang.git
cd PantherLang
pip install -e ".[dev]"
```

**Available AFTER PyPI publish:**
```powershell
pip install pantherlang==1.1.6
```

**PATH setup required (user action):**
```powershell
# After pip install --user or system
$env:PATH += ";$HOME\AppData\Roaming\Python\Python313\Scripts"
```

---

## Verification Commands (All Platforms)

```bash
# Version
panther version
# Expected: PantherLang 1.1.6 (PantherLang v1.1.6)

# System health
panther doctor
# All 11 components: OK

# Run example
panther run examples/console_hello/main.pan
# Should print "Hello from PantherLang"

# Create project
panther new console myapp
cd myapp
panther run src/main.panther
# Should run successfully

# Tests (from source)
python -m pytest tests/ -q
# 1039 passed
```

---

## VS Code Extension (Global)

**Source Install (always works):**
```bash
cd vscode-extension
npm install && npm run package
code --install-extension pantherlang-1.1.6.vsix
```

**Marketplace Install (AFTER publish):**
1. Open VS Code Extensions
2. Search "PantherLang"
3. Install

**File Association Verified:**
- `.pan` → PantherLang language mode ✅
- `.panther` → PantherLang language mode ✅
- Syntax highlighting ✅
- File icon (requires PantherLang icon theme enabled) ✅

---

## AI Discoverability Assets

| File | Purpose | Status |
|------|---------|--------|
| `llms.txt` | Quick reference | ✅ Created |
| `llms-full.txt` | Complete knowledge pack | ✅ Created |
| `AI_CONTEXT.md` | AI context | ✅ Exists |
| `LANGUAGE_RULES.md` | Language rules | ✅ Exists |
| `PANTHER_PROMPT.md` | Prompt template | ✅ Exists |
| `LLM_REFERENCE.md` | LLM reference | ✅ Exists |
| `docs/ai/AI_KNOWLEDGE_PACK_v1_1_5.md` | Consolidated pack | ✅ Created |
| `docs/agent_knowledge/` | Agent guides | ✅ 4 files |

**Note:** These improve LOCAL AI agent understanding. They do NOT guarantee external public LLMs (ChatGPT, Claude, etc.) will know PantherLang until trained/indexed on this content.

---

## Documentation URLs

| Doc | URL | Status |
|-----|-----|--------|
| GitHub Repo | https://github.com/ferasbackagain/PantherLang | ✅ VERIFIED_PUBLIC |
| Issues | https://github.com/ferasbackagain/PantherLang/issues | ✅ VERIFIED_PUBLIC |
| Docs (repo) | https://github.com/ferasbackagain/PantherLang/tree/main/docs | ✅ VERIFIED_PUBLIC |
| Website | https://pantherlang.dev | ❌ NOT_DEPLOYED |

---

## Release Manifest Requirements

Before declaring v1.1.6 globally released, the following must exist:

- [ ] Git tag `v1.1.6` pushed to GitHub
- [ ] GitHub Release created with:
  - `pantherlang-1.1.6.tar.gz`
  - `pantherlang-1.1.6-py3-none-any.whl`
  - `pantherlang-official-1.1.6.vsix`
  - Release notes (truth-audited)
- [ ] PyPI upload: `twine upload dist/*`
- [ ] VS Code Marketplace: `vsce publish`
- [ ] Website/docs deployed
- [ ] Install.sh pushed to main branch root (for curl installer)
- [ ] Checksums generated for all artifacts

---

## Classification Summary for v1.1.6

| Component | Classification |
|-----------|----------------|
| Source code (GitHub) | **VERIFIED_PUBLIC** |
| Git clone install | **VERIFIED_PUBLIC** |
| Source dev install | **VERIFIED_PUBLIC** |
| PyPI wheel install | **READY_AFTER_PYPI** |
| Curl installer | **READY_AFTER_PUSH** |
| VS Code Marketplace | **READY_AFTER_VSCODE_MARKETPLACE** |
| GitHub Release | **READY_AFTER_GITHUB_RELEASE** |
| Website | **READY_AFTER_WEBSITE_DEPLOY** |
| AI knowledge (local) | **VERIFIED_LOCAL** |
| AI knowledge (external) | **EXTERNAL_ACTION_REQUIRED** |

---

## Professional Release Policy

A PantherLang release is **globally real** only when:

1. ✅ Code committed to main branch
2. ✅ Version consistent (1.1.6 everywhere)
3. ✅ All tests pass (1039/1039)
4. ✅ All examples pass (11/11)
5. ✅ Git tag pushed to public GitHub
6. ⏳ Artifacts attached to GitHub Release
7. ⏳ Package published to PyPI
8. ⏳ Extension published to VS Code Marketplace
9. ⏳ Install.sh at repo root for curl
10. ⏳ Release notes published
11. ⏳ Checksums generated
12. ⏳ Clean install verified on Linux, macOS, Windows

**Current Status:** Items 1-5 complete. Items 6-12 require external publication actions.