# PantherLang v1.1.6 Real Release URLs Audit

**Date:** 2026-07-04
**Audit:** Verified against GitHub API and repository evidence
**Repository:** https://github.com/ferasbackagain/PantherLang

---

## URL Classification Legend

| Status | Meaning |
|--------|---------|
| **VERIFIED_PUBLIC** | Confirmed reachable via GitHub API / HTTP |
| **VERIFIED_LOCAL_ONLY** | Exists in local repo, not confirmed public |
| **OWNER_PROVIDED_NOT_PUBLICLY_VERIFIED** | Owner claims it works, but not independently verified |
| **PRIVATE_REPOSITORY** | Repository is private |
| **PLACEHOLDER** | Template/invented URL |
| **BROKEN** | Returns 404 or error |
| **EXTERNAL_ACTION_REQUIRED** | Needs external action (push, publish, etc.) |

---

## Repository URLs

| URL | Status | Evidence |
|-----|--------|----------|
| `https://github.com/ferasbackagain/PantherLang` | **VERIFIED_PUBLIC** | GitHub API returns 200, `private: false` |
| `https://github.com/ferasbackagain/PantherLang.git` | **VERIFIED_PUBLIC** | `git remote -v` matches, `git ls-remote` works |
| `https://github.com/feras-khatib/pantherlang` | **BROKEN** | Not the actual repo (owner says this is wrong) |
| `https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh` | **BROKEN (404)** | File does not exist at root of main branch |
| `https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh` | **EXTERNAL_ACTION_REQUIRED** | Must push install.sh to root of main branch |

---

## Installer Files in Repository (Local)

| File | Local Path | Status |
|------|------------|--------|
| `install.sh` | Root | **VERIFIED_LOCAL_ONLY** - exists locally |
| `install.ps1` | Root | **VERIFIED_LOCAL_ONLY** - exists locally |
| `install.bat` | Root | **VERIFIED_LOCAL_ONLY** - exists locally |
| `installer/install.sh` | `installer/` | **VERIFIED_LOCAL_ONLY** |
| `installers/linux/install_panther.sh` | `installers/linux/` | **VERIFIED_LOCAL_ONLY** |
| `installers/windows/install_panther.ps1` | `installers/windows/` | **VERIFIED_LOCAL_ONLY** |
| `installers/macos/install_panther.command` | `installers/macos/` | **VERIFIED_LOCAL_ONLY** |

---

## GitHub Repository Contents (Main Branch Root)

| Path | Type | Notes |
|------|------|-------|
| `installer/` | Directory | Contains install.sh |
| `installers/` | Directory | Contains linux/, windows/, macos/ |
| `install.sh` | **MISSING** | NOT at root of main branch |
| `install.ps1` | **MISSING** | NOT at root of main branch |
| `install.bat` | **MISSING** | NOT at root of main branch |

---

## Corrected URLs for Active v1.1.6 Release Documentation

### Repository (VERIFIED)
- **Repository:** https://github.com/ferasbackagain/PantherLang
- **Issues:** https://github.com/ferasbackagain/PantherLang/issues
- **Clone (HTTPS):** https://github.com/ferasbackagain/PantherLang.git
- **Clone (SSH):** git@github.com:ferasbackagain/PantherLang.git

### Installer (NOT YET WORKING — EXTERNAL_ACTION_REQUIRED)
The following URLs will **NOT work** until `install.sh` is pushed to the root of the `main` branch on GitHub:

- ❌ `https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh` — Returns 404
- ❌ `curl -fsSL https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | bash` — Will fail

### Working Alternative (Local Source Install)
```bash
git clone https://github.com/ferasbackagain/PantherLang.git
cd PantherLang
pip install -e .
```

Or from PyPI (after publish):
```bash
pip install pantherlang==1.1.6
```

---

## Files Requiring URL Updates (Stale feras-khatib references)

### High Priority (Active Release Docs)
| File | Lines to Fix |
|------|--------------|
| `INSTALLATION_GUIDE_LINUX_WINDOWS.md` | 5 `git clone` lines, 1 `curl` line |
| `install.sh` | Comment line with curl command |
| `README.md` | 2 GitHub URLs |
| `cli/panther_cli.py` | 2 print statements |
| `pyproject.toml` | 3 URL fields |
| `docs/DEVELOPER_GUIDE.md` | 1 git clone |
| `docs/PANTHERLANG_PRACTICAL_LANGUAGE_GUIDE.md` | 1 GitHub URL |
| `vscode-extension/package.json` | 3 URLs (repository, issues, homepage) |

### Bootstrap/Backup Files (Historical - Do Not Change)
- `.panther_backups/...` — Historical records
- `bootstrap_R2_part2_publisher_identity_package_finalization.sh` — Historical

---

## Action Required for Working curl Installer

**To make the curl installer work, the owner must:**

1. Push `install.sh`, `install.ps1`, `install.bat` to the root of `main` branch:
   ```bash
   git add install.sh install.ps1 install.bat
   git commit -m "Add root installer scripts for public curl install"
   git push origin main
   ```

2. Verify:
   ```bash
   curl -I https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh
   # Should return 200 OK
   ```

3. Then the install command will work:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | bash
   ```

---

## Classification Summary for v1.1.6 Release

| Resource | Classification |
|----------|----------------|
| Repository homepage | **VERIFIED_PUBLIC** |
| Git clone URL | **VERIFIED_PUBLIC** |
| GitHub Issues | **VERIFIED_PUBLIC** |
| Raw install.sh (root) | **BROKEN (404)** — **EXTERNAL_ACTION_REQUIRED** |
| curl install command | **NOT_FUNCTIONAL** — **EXTERNAL_ACTION_REQUIRED** |
| PyPI package (1.1.6) | **NOT_PUBLISHED** — **EXTERNAL_ACTION_REQUIRED** |
| VS Code Marketplace (1.1.6) | **NOT_PUBLISHED** — **EXTERNAL_ACTION_REQUIRED** |

---

## Recommendation

**Do not claim public curl installer works in v1.1.6 release notes.**

State honestly:
> "Public curl installer requires owner to push install.sh to main branch root. Currently available via `git clone` + `pip install -e .` or PyPI after publish."

Update all active release documentation accordingly.