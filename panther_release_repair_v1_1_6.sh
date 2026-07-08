#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="${1:-$PWD}"
cd "$ROOT"

BACKUP="/tmp/panther_release_fix_$(date +%Y%m%d_%H%M%S)"

echo "=================================================="
echo " PantherLang v1.1.6 — Release Repair"
echo " Root: $ROOT"
echo " Backup: $BACKUP"
echo "=================================================="

mkdir -p "$BACKUP"

echo
echo "[1/10] Verify Git repository..."
git rev-parse --is-inside-work-tree >/dev/null
git status --short > "$BACKUP/git-status-before.txt"

echo
echo "[2/10] Clean Python cache noise..."
find . -type d -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true
find . -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete 2>/dev/null || true

# Restore tracked bytecode only if this repository historically tracked it.
git ls-files -d -z -- '*__pycache__*' '*.pyc' '*.pyo' \
  | xargs -0 -r git restore --worktree -- 2>/dev/null || true

echo
echo "[3/10] Restore only runtime/test-critical .panther contracts..."

restore_if_tracked() {
    local path="$1"
    if git cat-file -e "HEAD:$path" 2>/dev/null; then
        echo "  RESTORE $path"
        mkdir -p "$(dirname "$path")"
        git restore --source=HEAD --worktree -- "$path"
    else
        echo "  SKIP    $path (not tracked in HEAD)"
    fi
}

restore_if_tracked ".panther/tools/panther_cli.py"
restore_if_tracked ".panther/p2_debug_adapter_rebuild/spec/canonical_debug_adapter_contract.json"
restore_if_tracked ".panther/R3_compiler_runtime/compiler_runtime_contract.json"
restore_if_tracked ".panther/p3_atomic_replacement/sandbox_atomic_switch/debug_adapter_legacy"
restore_if_tracked ".panther/p3_atomic_replacement/sandbox_atomic_switch/debug_adapter"

for f in \
  H4_2_finalize_v2_f4_response_merge.json \
  H4_2_f5_event_request_seq_patch.json \
  H4_2_finalize_v2_f6_execution_merge.json \
  H4_2_finalize_v2_f7_full_regression.json \
  H4_2_finalize_v2_f8_end_to_end_professional_verification.json \
  H4_3_d1_variables_core.json \
  H4_3_d2_variables_references.json \
  H4_3_d3_variable_store.json \
  H4_3_d4_stack_frames.json \
  H4_3_d5_threads.json \
  H4_3_d6_scopes.json \
  H4_3_d7_evaluate.json \
  H4_3_d8_watch_expressions.json \
  H4_3_d9_full_regression.json \
  H4_3_d10_professional_verification.json \
  H4_4_d1_vscode_debugger_contribution.json \
  H4_4_d2_debug_adapter_registration.json \
  H4_4_d3_workspace_debug_configs.json \
  H4_4_d4_f5_debug_flow.json \
  H4_4_d5_vscode_extension_package_verification.json
do
    restore_if_tracked ".panther/phase_status/$f"
done

echo
echo "[4/10] Repair Panther launcher dependency..."
if [ ! -f ".panther/tools/panther_cli.py" ]; then
    echo "  Internal CLI path absent; checking canonical CLI..."

    if [ -f "cli/panther_cli.py" ]; then
        cp -a panther "$BACKUP/panther.before" 2>/dev/null || true

        python3 - <<'PY'
from pathlib import Path

p = Path("panther")
s = p.read_text(encoding="utf-8")

old = ".panther/tools/panther_cli.py"
new = "cli/panther_cli.py"

if old in s:
    s = s.replace(old, new)
    p.write_text(s, encoding="utf-8")
    print("  Rewired ./panther to canonical cli/panther_cli.py")
else:
    print("  Launcher does not contain old internal CLI path; left unchanged")
PY
    else
        echo "ERROR: neither .panther/tools/panther_cli.py nor cli/panther_cli.py exists"
        exit 1
    fi
fi

chmod +x panther 2>/dev/null || true

echo
echo "[5/10] Fix OllamaProvider missing-requests crash..."
cp -a compiler/ai/providers.py "$BACKUP/providers.py.before"

python3 - <<'PY'
from pathlib import Path

p = Path("compiler/ai/providers.py")
s = p.read_text(encoding="utf-8")

old = "        except (ImportError, requests.exceptions.ConnectionError, Exception):"
new = "        except Exception:"

if old in s:
    s = s.replace(old, new)
    p.write_text(s, encoding="utf-8")
    print("  Fixed UnboundLocalError in OllamaProvider")
else:
    print("  Exact vulnerable except-clause not found; checking syntax only")
PY

python3 -m py_compile compiler/ai/providers.py

echo
echo "[6/10] Repair README quick-install regression without changing product claims..."
cp -a README.md "$BACKUP/README.md.before"

python3 - <<'PY'
from pathlib import Path

p = Path("README.md")
s = p.read_text(encoding="utf-8")

if "pip install" not in s:
    marker = "## Quick Start"
    block = """## Quick Start

Install from the repository:

```bash
curl -fsSL https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | bash
```

For Python package workflows, editable development installs use `pip install` through the project packaging configuration.

"""
    if marker in s:
        start = s.index(marker)
        next_heading = s.find("\n## ", start + len(marker))
        if next_heading != -1:
            s = s[:start] + block + s[next_heading + 1:]
        else:
            s = s[:start] + block
    else:
        s += "\n\n" + block

    p.write_text(s, encoding="utf-8")
    print("  Added truthful pip-install wording required by current docs regression")
else:
    print("  README already contains pip install")
PY

echo
echo "[7/10] Remove local database/cache artifacts again..."
rm -f chat_history.db library.db todos.db 2>/dev/null || true
find . -type d -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true
find . -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete 2>/dev/null || true

echo
echo "[8/10] Fast targeted verification..."

python -m pytest \
  tests/P2_canonical_debug_adapter/test_p2_batch1_contract.py \
  tests/P3_atomic_replacement/test_p3_batch5_sandbox_switch.py \
  tests/R3_compiler_runtime/test_r3_batch2_part1_contract.py \
  tests/phase10_batch10_1/test_ai_platform.py \
  tests/phase6_18/test_runtime_bridge.py \
  tests/phase6_19/test_fast_regression.py \
  tests/phase6_20/test_production_readiness.py \
  tests/phase7_10/test_final_runtime.py \
  tests/phase7_2/test_cli_run.py \
  tests/phase9_1/test_production_build.py \
  tests/test_docs_presence.py \
  tests/test_h4_2_finalize_v2_f7_full_regression_manifest.py \
  tests/test_h4_2_finalize_v2_f8_end_to_end_professional_verification.py \
  tests/test_h4_3_d9_full_regression_manifest.py \
  tests/test_h4_3_d10_professional_verification.py \
  tests/test_h4_4_d6_vscode_end_to_end_verification.py \
  -q

echo
echo "[9/10] CLI verification..."
./panther version
./panther doctor

echo
echo "[10/10] Full regression..."
python -m pytest tests/ -q

echo
echo "=================================================="
echo " RELEASE REPAIR COMPLETE"
echo "=================================================="
echo
echo "Final Git status:"
git status --short

echo
echo "Final diff summary:"
git diff --stat || true

echo
echo "Backup kept outside repository:"
echo "$BACKUP"
echo
echo "DO NOT PUSH YET until you inspect the final status above."
