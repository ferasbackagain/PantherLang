#!/usr/bin/env bash
set -u -o pipefail
ROOT="${P75_ROOT:-$(pwd)}"; WORKDIR="${P75_WORKDIR:?}"; REPORT_DIR="${P75_REPORT_DIR:?}"
mkdir -p "$WORKDIR/logs" "$WORKDIR/status" "$REPORT_DIR"
cd "$ROOT" || exit 1

PYTHON_BIN="${P75_PYTHON_BIN:-python3}"
if [[ -x "/home/panther/test_build/.venv/bin/python3" ]]; then
  PYTHON_BIN="/home/panther/test_build/.venv/bin/python3"
elif [[ -x ".venv/bin/python3" ]]; then
  PYTHON_BIN=".venv/bin/python3"
fi

python3 - <<'PY'
from __future__ import annotations
import hashlib, json, os, re, subprocess, time
from pathlib import Path
root=Path(os.environ.get('P75_ROOT', os.getcwd()))
work=Path(os.environ['P75_WORKDIR']); report=Path(os.environ['P75_REPORT_DIR'])
py=os.environ.get('P75_PYTHON_BIN') or ('/home/panther/test_build/.venv/bin/python3' if Path('/home/panther/test_build/.venv/bin/python3').exists() else 'python3')

def module_for(path: Path):
    s=path.as_posix().lower()
    m=re.search(r'h4[_\.-](\d+)', s)
    return f'H4.{m.group(1)}' if m else 'H4.general'

def sha(p: Path): return hashlib.sha256(p.read_bytes()).hexdigest()

def discover():
    candidates=[]
    roots=[root/'tests']
    # Include H4 debug-adapter historical tests only; exclude compiler/runtime backup suites not directly under debug_adapter compatibility.
    for r in roots:
        if r.exists():
            candidates.extend([p for p in r.rglob('test*.py') if 'h4' in p.as_posix().lower() and '_retired' not in p.parts and '__pycache__' not in p.parts])
    # Include backup H4 tests that directly mention debug_adapter/imports to avoid re-running unrelated old compiler suites as blocking RC gates.
    broot=root/'.panther'/'backups'
    if broot.exists():
        for p in broot.rglob('test*.py'):
            s=p.as_posix().lower()
            if '_retired' in p.parts or '__pycache__' in p.parts: continue
            if 'h4' in s:
                txt=''
                try: txt=p.read_text(encoding='utf-8', errors='ignore')[:12000]
                except Exception: pass
                if 'debug_adapter' in txt or 'dap' in txt.lower(): candidates.append(p)
    seen={}; out=[]
    for p in sorted(candidates):
        h=sha(p)
        if h in seen: continue
        seen[h]=p; out.append(p)
    return out

suites=discover()
results=[]
print(f'Discovered {len(suites)} focused H4 compatibility suites/files')
for i,p in enumerate(suites,1):
    rel=p.relative_to(root).as_posix(); mod=module_for(p)
    print(f'[{i}/{len(suites)}] {mod} :: {rel}', flush=True)
    log=work/'logs'/f'full_{i:04d}_{mod.replace(".","_")}_{p.stem}.log'
    cmd=[py,'-m','pytest',str(p),'-q','--tb=short','--disable-warnings']
    start=time.time()
    try:
        proc=subprocess.run(cmd,cwd=root,text=True,capture_output=True,timeout=180)
        status='PASS' if proc.returncode==0 else 'FAIL'; code=proc.returncode; text=proc.stdout+proc.stderr
    except subprocess.TimeoutExpired as exc:
        status='TIMEOUT'; code=124; text=(exc.stdout or '')+(exc.stderr or '')+'\nTIMEOUT\n'
    dur=round(time.time()-start,3)
    log.write_text(text,encoding='utf-8')
    evidence=[]
    for line in text.splitlines():
        if any(k in line for k in ['E   ','FAILED','ModuleNotFoundError','AttributeError','AssertionError','TypeError','FileNotFoundError']):
            evidence.append(line.strip())
        if len(evidence)>=5: break
    origin='historical_backup' if '.panther/backups' in rel else 'current_tests'
    results.append({'suite_id':f'{i:04d}_{mod.replace(".","_")}_{p.stem}','module':mod,'path':rel,'origin':origin,'status':status,'exit_code':code,'duration_seconds':dur,'sha256':sha(p),'log_file':str(log.relative_to(root)),'command':' '.join(cmd),'evidence':evidence})
summary={}
for r in results:
    m=summary.setdefault(r['module'], {'total':0,'pass':0,'fail':0,'timeout':0})
    m['total']+=1; m[r['status'].lower()]+=1
out={'summary_by_module':summary,'total':len(results),'results':results}
(work/'full_h4_regression.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
(report/'full_h4_regression.json').write_text(json.dumps(out,indent=2),encoding='utf-8')

# Markdown matrix
lines=['# Full H4 Compatibility Matrix — P-3 Batch 7.5','', '| Module | Total | Pass | Fail | Timeout |','|---|---:|---:|---:|---:|']
for mod in sorted(summary):
    s=summary[mod]; lines.append(f"| {mod} | {s['total']} | {s['pass']} | {s['fail']} | {s['timeout']} |")
lines += ['', '## Suite Results', '', '| Suite | Module | Status | Origin | Path |', '|---|---|---|---|---|']
for r in results:
    lines.append(f"| {r['suite_id']} | {r['module']} | {r['status']} | {r['origin']} | `{r['path']}` |")
(report/'full_h4_compatibility_matrix.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')

fail_count=sum(1 for r in results if r['status']!='PASS')
raise SystemExit(0 if fail_count==0 else 2)
PY
