#!/usr/bin/env bash
set -u -o pipefail
ROOT="${P75_ROOT:-$(pwd)}"; WORKDIR="${P75_WORKDIR:?}"; REPORT_DIR="${P75_REPORT_DIR:?}"
mkdir -p "$WORKDIR/logs" "$WORKDIR/status" "$REPORT_DIR"
cd "$ROOT" || exit 1

PYTHON_BIN="${PYTHON_BIN:-python3}"
if [[ -x "/home/panther/test_build/.venv/bin/python3" ]]; then
  PYTHON_BIN="/home/panther/test_build/.venv/bin/python3"
elif [[ -x ".venv/bin/python3" ]]; then
  PYTHON_BIN=".venv/bin/python3"
fi
export P75_PYTHON_BIN="$PYTHON_BIN"

python3 - <<'PY'
from __future__ import annotations
import json, os, subprocess, time
from pathlib import Path
root=Path(os.environ.get('P75_ROOT', os.getcwd()))
work=Path(os.environ['P75_WORKDIR']); report=Path(os.environ['P75_REPORT_DIR'])
py=os.environ.get('P75_PYTHON_BIN','python3')
patterns=[
 'tests/H4_1/test_debug_adapter_core.py',
 'tests/test_h4_2_f5_event_dispatcher_compatibility.py',
 'tests/test_h4_2_finalize_v2_f7_full_regression_manifest.py',
 'tests/test_h4_3_d9_full_regression_manifest.py',
 'tests/test_h4_3_d9_integrated_data_model_regression.py',
 'tests/test_h4_4_d2_debug_adapter_registration.py',
 'tests/test_h4_4_d5_vscode_extension_package_verification.py',
 'tests/test_h4_4_d6_vscode_end_to_end_verification.py',
]
results=[]
for idx, rel in enumerate(patterns,1):
    p=root/rel
    if not p.exists():
        results.append({'path':rel,'status':'MISSING','exit_code':None,'duration_seconds':0,'log_file':None})
        continue
    log=work/'logs'/f'targeted_{idx:02d}_{p.stem}.log'
    cmd=[py,'-m','pytest',str(p),'-q','--tb=short','--disable-warnings']
    start=time.time()
    proc=subprocess.run(cmd,cwd=root,text=True,capture_output=True,timeout=120)
    duration=round(time.time()-start,3)
    log.write_text(proc.stdout+proc.stderr,encoding='utf-8')
    results.append({'path':rel,'status':'PASS' if proc.returncode==0 else 'FAIL','exit_code':proc.returncode,'duration_seconds':duration,'log_file':str(log.relative_to(root)),'command':' '.join(cmd)})
summary={'total':len(results),'pass':sum(r['status']=='PASS' for r in results),'fail':sum(r['status']=='FAIL' for r in results),'missing':sum(r['status']=='MISSING' for r in results)}
out={'summary':summary,'results':results}
(work/'targeted_validation.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
(report/'targeted_validation.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
raise SystemExit(0 if summary['fail']==0 and summary['missing']==0 else 2)
PY
