from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
COMPILER=ROOT/'compiler'/'pipeline'/'panther_compiler.py'
def run_cmd(*args: str):
    p=subprocess.run([sys.executable,str(COMPILER),*args],cwd=ROOT,text=True,capture_output=True)
    return p.returncode,json.loads(p.stdout)
def test_expression_demo_compile_and_run(tmp_path: Path):
    out=tmp_path/'expr.sh'; code,data=run_cmd('compile','examples/phase6_expressions/expressions_demo.panther','--out',str(out))
    assert code==0 and data['ok']; p=subprocess.run([str(out)],text=True,capture_output=True); assert '15' in p.stdout and '30' in p.stdout and 'true' in p.stdout
def test_division_by_zero_fails(tmp_path: Path):
    src=tmp_path/'bad.panther'; src.write_text('let x = 10 / 0\nprint x\n')
    code,data=run_cmd('compile',str(src),'--out',str(tmp_path/'bad.sh')); assert code==2 and 'Division by zero' in data['error']
def test_undefined_symbol_fails(tmp_path: Path):
    src=tmp_path/'bad_symbol.panther'; src.write_text('print missing_value\n')
    code,data=run_cmd('compile',str(src),'--out',str(tmp_path/'bad_symbol.sh')); assert code==2 and 'Undefined symbol' in data['error']
