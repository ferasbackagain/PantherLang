#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json
from pathlib import Path

CACHE_DIR = Path(".panther_cache")
CACHE_DIR.mkdir(exist_ok=True)

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def compile_file(src: Path):
    digest = sha(src)
    cache = CACHE_DIR / (src.stem + ".json")
    previous = None
    if cache.exists():
        previous = json.loads(cache.read_text())
    changed = previous is None or previous["sha256"] != digest
    cache.write_text(json.dumps({"file": str(src), "sha256": digest}, indent=2))
    return {
        "ok": True,
        "phase": "9.4",
        "file": str(src),
        "changed": changed,
        "cache": str(cache)
    }

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        raise SystemExit("usage: incremental_compiler.py <file>")
    print(json.dumps(compile_file(Path(sys.argv[1])), indent=2))
