#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

TARGETS={
 "linux-x64":{"ext":".sh"},
 "windows-x64":{"ext":".bat"},
 "macos-arm64":{"ext":".command"},
}

def generate(src:Path,target:str,outdir:Path):
    if target not in TARGETS:
        raise SystemExit("Unknown target")
    outdir.mkdir(parents=True,exist_ok=True)
    ext=TARGETS[target]["ext"]
    out=outdir/(src.stem+ext)
    if ext==".bat":
        out.write_text("@echo off\necho Panther artifact\n")
    else:
        out.write_text("#!/usr/bin/env bash\necho Panther artifact\n")
    return {"ok":True,"phase":"9.8","target":target,"artifact":str(out)}

if __name__=="__main__":
    import argparse
    p=argparse.ArgumentParser()
    p.add_argument("source")
    p.add_argument("--target",required=True)
    p.add_argument("--out-dir",default="dist")
    a=p.parse_args()
    print(json.dumps(generate(Path(a.source),a.target,Path(a.out_dir)),indent=2))
