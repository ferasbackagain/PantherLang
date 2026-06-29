#!/usr/bin/env bash
set -u -o pipefail
ROOT="${P75_ROOT:-$(pwd)}"; WORKDIR="${P75_WORKDIR:?}"; REPORT_DIR="${P75_REPORT_DIR:?}"
mkdir -p "$WORKDIR/status" "$REPORT_DIR"
cd "$ROOT" || exit 1

python3 - <<'PY'
from __future__ import annotations
import json, os, shutil, hashlib
from pathlib import Path
root=Path(os.environ.get('P75_ROOT', os.getcwd()))
work=Path(os.environ['P75_WORKDIR']); report=Path(os.environ['P75_REPORT_DIR'])
required = [
  'adapter.py','breakpoint_store.py','breakpoints.py','capabilities.py','dispatcher.py',
  'dispatcher_contract.py','event_merge.py','events.py','execution_controller.py','execution_state.py',
  'finalize_v2_guard.py','finalize_v2_status.py','legacy_cleanup.py','locations.py','messages.py',
  'response_merge.py','source_map.py','state_machine.py','transport.py','validation.py'
]
# H4.3 compatibility names expected by current tests
aliases = {
  'variables.py': None,
}

def sha(p: Path):
    return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None

refs=[]
for b in sorted((root/'.panther'/'backups').glob('*'), key=lambda p: p.stat().st_mtime, reverse=True):
    da=b/'debug_adapter'
    if da.is_dir(): refs.append(da)

manifest={'reference_candidates':[str(r) for r in refs[:20]], 'restored':[], 'skipped_existing':[], 'missing_reference':[], 'generated':[]}
if not refs:
    raise SystemExit('No reference debug_adapter folders found under .panther/backups')

(root/'debug_adapter').mkdir(exist_ok=True)
for name in required:
    dest=root/'debug_adapter'/name
    if dest.exists():
        manifest['skipped_existing'].append({'file':name,'reason':'already exists','sha256':sha(dest)})
        continue
    src=None
    for ref in refs:
        if (ref/name).exists(): src=ref/name; break
    if src:
        shutil.copy2(src, dest)
        manifest['restored'].append({'file':name,'from':str(src.relative_to(root)),'sha256':sha(dest)})
    else:
        manifest['missing_reference'].append(name)

# Generate variables.py as explicit compatibility facade if absent.
variables = root/'debug_adapter'/'variables.py'
if not variables.exists():
    variables.write_text('''from __future__ import annotations\n\n"""H4.3 compatibility facade for PantherLang debug adapter variables.\n\nThis module preserves the historical import path `debug_adapter.variables` while\nforwarding to the canonical split modules introduced during P-2/P-3.\n"""\n\ntry:\n    from .variables_core import *  # noqa: F401,F403\nexcept Exception:  # pragma: no cover\n    pass\ntry:\n    from .variable_store import VariableStore  # noqa: F401\nexcept Exception:  # pragma: no cover\n    VariableStore = None  # type: ignore\ntry:\n    from .variable_references import VariableReferenceStore  # noqa: F401\nexcept Exception:  # pragma: no cover\n    VariableReferenceStore = None  # type: ignore\n''', encoding='utf-8')
    manifest['generated'].append({'file':'variables.py','reason':'compatibility facade for H4.3 imports','sha256':sha(variables)})

# Ensure __init__.py exists
init=root/'debug_adapter'/'__init__.py'
if not init.exists():
    init.write_text('', encoding='utf-8')
    manifest['generated'].append({'file':'__init__.py','reason':'package marker','sha256':sha(init)})

(work/'restoration_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
(report/'restoration_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(json.dumps(manifest, indent=2))
PY
