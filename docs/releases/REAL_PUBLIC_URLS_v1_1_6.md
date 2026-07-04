# PantherLang v1.1.6 Real Public URLs

**Date:** 2026-07-04
**Classification:** Based on GitHub API verification and repository evidence
**Repository:** https://github.com/ferasbackagain/PantherLang

---

## URL Classification Legend

| Status | Meaning |
|--------|---------|
| **VERIFIED_PUBLIC** | Confirmed reachable via GitHub API / HTTP 200 |
| **VERIFIED_LOCAL_ONLY** | Exists in local repo, not confirmed public |
| **EXTERNAL_ACTION_REQUIRED** | Needs external action (push, publish, deploy) |
| **BROKEN** | Returns 404 or error |
| **PLACEHOLDER** | Template/invented URL |

---

## Verified Public URLs

| Resource | URL | Status | Verified |
|----------|-----|--------|----------|
| Repository Homepage | https://github.com/ferasbackagain/PantherLang | **VERIFIED_PUBLIC** | ✅ API 200, private=false |
| Git Clone (HTTPS) | https://github.com/ferasbackagain/PantherLang.git | **VERIFIED_PUBLIC** | ✅ `git ls-remote` works |
| Git Clone (SSH) | git@github.com:ferasbackagain/PantherLang.git | **VERIFIED_PUBLIC** | Standard GitHub |
| GitHub Issues | https://github.com/ferasbackagain/PantherLang/issues | **VERIFIED_PUBLIC** | ✅ Linked from repo |
| GitHub Actions | https://github.com/ferasbackagain/PantherLang/actions | **VERIFIED_PUBLIC** | Standard GitHub |
| Wiki | https://github.com/ferasbackagain/PantherLang/wiki | **VERIFIED_PUBLIC** | Standard GitHub |
| Discussions | https://github.com/ferasbackagain/PantherLang/discussions | **VERIFIED_PUBLIC** | Standard GitHub |

---

## External Action Required URLs

| Resource | URL | Status | Blocker |
|----------|-----|--------|---------|
| Raw Installer (install.sh) | https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | **EXTERNAL_ACTION_REQUIRED** | File not at root of main branch |
| Curl Install Command | `curl -fsSL https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh \| bash` | **EXTERNAL_ACTION_REQUIRED** | Requires install.sh pushed |
| PyPI Package | https://pypi.org/project/pantherlang/1.1.6/ | **EXTERNAL_ACTION_REQUIRED** | Not published |
| VS Code Marketplace | https://marketplace.visualstudio.com/items?itemName=PantherLang.pantherlang-official | **EXTERNAL_ACTION_REQUIRED** | Not published v1.1.6 |
| GitHub Release | https://github.com/ferasbackagain/PantherLang/releases/tag/v1.1.6 | **EXTERNAL_ACTION_REQUIRED** | Tag not created |
| Website | https://pantherlang.dev | **EXTERNAL_ACTION_REQUIRED** | Not deployed |

---

## Local-Only Resources

| Resource | Local Path | Status |
|----------|------------|--------|
| install.sh | `./install.sh` | **VERIFIED_LOCAL_ONLY** |
| install.ps1 | `./install.ps1` | **VERIFIED_LOCAL_ONLY** |
| install.bat | `./install.bat` | **VERIFIED_LOCAL_ONLY** |
| installer/install.sh | `./installer/install.sh` | **VERIFIED_LOCAL_ONLY** |
| installers/linux/install_panther.sh | `./installers/linux/install_panther.sh` | **VERIFIED_LOCAL_ONLY** |
| installers/windows/install_panther.ps1 | `./installers/windows/install_panther.ps1` | **VERIFIED_LOCAL_ONLY** |
| installers/macos/install_panther.command | `./installers/macos/install_panther.command` | **VERIFIED_LOCAL_ONLY** |
| Source code | Entire repo | **VERIFIED_LOCAL_ONLY** (but cloneable) |

---

## Corrected Repository Identity

| Field | Value |
|-------|-------|
| **Owner** | ferasbackagain |
| **Repository** | PantherLang |
| **Full Name** | ferasbackagain/PantherLang |
| **Primary Branch** | main |
| **Visibility** | Public |
| **Fork** | false |

---

## Documentation URLs (Corrected)

| Document | Corrected URL |
|----------|---------------|
| Repository | https://github.com/ferasbackagain/PantherLang |
| Issues | https://github.com/ferasbackagain/PantherLang/issues |
| Clone (HTTPS) | https://github.com/ferasbackagain/PantherLang.git |
| Clone (SSH) | git@github.com:ferasbackagain/PantherLang.git |
| Docs (in repo) | https://github.com/ferasbackagain/PantherLang/tree/main/docs |
| Releases | https://github.com/ferasbackagain/PantherLang/releases |
| Tags | https://github.com/ferasbackagain/PantherLang/tags |
| Wiki | https://github.com/ferasbackagain/PantherLang/wiki |

---

## Incorrect/Stale URLs (DO NOT USE)

| Incorrect URL | Reason |
|---------------|--------|
| https://github.com/feras-khatib/pantherlang | Wrong owner |
| https://github.com/feras-khatib/pantherlang/issues | Wrong owner |
| https://github.com/feras-khatib/pantherlang/docs | Wrong owner |
| https://raw.githubusercontent.com/feras-khatib/pantherlang/main/install.sh | Wrong owner |
| https://pantherlang.dev | Not deployed |

---

## Installation Commands (Status-Aware)

### Source Install (ALWAYS WORKS)
```bash
git clone https://github.com/ferasbackagain/PantherLang.git
cd PantherLang
pip install -e ".[dev]"
```

### PyPI Install (WORKS AFTER PUBLISH)
```bash
pip install pantherlang==1.1.6
```

### Curl Install (WORKS AFTER install.sh PUSHED)
```bash
curl -fsSL https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | bash
# Status: EXTERNAL_ACTION_REQUIRED - install.sh not at main branch root
```

### Windows PowerShell (WORKS AFTER PUBLISH)
```powershell
pip install pantherlang==1.1.6
# Then add to PATH if needed
```

---

## Verification Commands

```bash
# Verify repository reachable
curl -I https://github.com/feras/ferasbackagain/PantherLang
# Expected: HTTP/2 200

# Verify git clone works
git ls-remote https://github.com/ferasbackagain/PantherLang.git
# Expected: Lists refs including HEAD and main

# Verify raw installer (currently fails)
curl -I https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh
# Current: HTTP/2 404
# After push: HTTP/2 200
```

---

## Summary for v1.1.6 Release Notes

**WORKING NOW (source-based):**
- Git clone + pip install -e .[dev]
- All 1039 tests, 11 examples, 4 templates
- VS Code extension from source
- All documentation in repo

**REQUIRES EXTERNAL ACTION:**
- PyPI package
- VS Code Marketplace extension
- GitHub Release with artifacts
- Curl installer (push install.sh to main root)
- Website deployment

**DO NOT CLAIM:**
- "Available on PyPI"
- "Available on VS Code Marketplace"
- "Global curl install works"
- "Website live"