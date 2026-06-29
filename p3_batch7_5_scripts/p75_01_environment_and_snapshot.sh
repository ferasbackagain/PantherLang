#!/usr/bin/env bash
set -u -o pipefail
ROOT="${P75_ROOT:-$(pwd)}"; WORKDIR="${P75_WORKDIR:?}"; REPORT_DIR="${P75_REPORT_DIR:?}"
mkdir -p "$WORKDIR/status" "$WORKDIR/snapshots" "$REPORT_DIR"
cd "$ROOT" || exit 1

python3 - <<'PY'
from __future__ import annotations
import json, hashlib, os, shutil, subprocess, sys
from pathlib import Path
root=Path(os.environ.get('P75_ROOT', os.getcwd()))
work=Path(os.environ['P75_WORKDIR']); report=Path(os.environ['P75_REPORT_DIR'])
errors=[]; warnings=[]

def htree(path: Path):
    if not path.exists(): return None
    h=hashlib.sha256()
    for p in sorted(path.rglob('*')):
        if p.is_file() and '__pycache__' not in p.parts:
            rel=p.relative_to(path).as_posix().encode(); h.update(rel); h.update(b'\0'); h.update(p.read_bytes()); h.update(b'\0')
    return h.hexdigest()

if not (root/'debug_adapter').is_dir(): errors.append('debug_adapter directory is missing')
if not (root/'.panther'/'backups').is_dir(): errors.append('.panther/backups directory is missing')
legacy=list(root.glob('debug_adapter_legacy_P3_*'))
rollback=list((root/'.panther').rglob('*rollback*')) if (root/'.panther').exists() else []
if not legacy: warnings.append('No debug_adapter_legacy_P3_* directory found')
if not rollback: warnings.append('No rollback candidate found under .panther')

snapshot=work/'snapshots'/'debug_adapter_before'
if snapshot.exists(): shutil.rmtree(snapshot)
if (root/'debug_adapter').exists(): shutil.copytree(root/'debug_adapter', snapshot, ignore=shutil.ignore_patterns('__pycache__','*.pyc'))

# Backup git diff status if git exists
try:
    proc=subprocess.run(['git','status','--short'], cwd=root, text=True, capture_output=True, timeout=10)
    (work/'git_status_before.txt').write_text(proc.stdout+proc.stderr, encoding='utf-8')
except Exception as exc:
    warnings.append(f'git status unavailable: {exc}')

manifest={
  'batch':'P-3 Batch 7.5',
  'purpose':'Debug Adapter Compatibility Restoration',
  'project_root':str(root),
  'production_debug_adapter_hash_before': htree(root/'debug_adapter'),
  'legacy_adapter_count':len(legacy),
  'rollback_candidate_count':len(rollback),
  'snapshot':str(snapshot),
  'errors':errors,
  'warnings':warnings,
  'controls':{
    'monkey_patches':'not introduced',
    'quick_fixes':'not performed',
    'strategy':'restore missing compatibility modules from historical references and add explicit compatibility contracts'
  }
}
(work/'environment_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
(report/'environment_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
if errors:
    print('\n'.join(errors), file=sys.stderr); sys.exit(1)
print(json.dumps(manifest, indent=2))
PY
