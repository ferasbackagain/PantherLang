#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 9.4 PRO - Incremental Compilation"
echo "============================================================"

mkdir -p compiler/incremental examples/phase9_incremental scripts docs/phase9

cat > compiler/incremental/incremental_compiler.py <<'PY'
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
PY
chmod +x compiler/incremental/incremental_compiler.py

cat > examples/phase9_incremental/incremental_demo.panther <<'EOF'
print "Phase 9.4 Incremental Compilation"
EOF

cat > docs/phase9/PHASE_9_4_STATUS.md <<'EOF'
Phase 9.4
- Incremental compilation cache
- File hashing
- Change detection
- Build cache foundation
EOF

cat > scripts/verify_phase9_4_incremental.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.4 Incremental Compilation Verification"
echo "============================================================"

test -f compiler/incremental/incremental_compiler.py
echo "✅ structure tests passed"

python3 -m py_compile compiler/incremental/incremental_compiler.py
echo "✅ python compile passed"

python3 compiler/incremental/incremental_compiler.py examples/phase9_incremental/incremental_demo.panther > /tmp/inc1.json
grep -q '"changed": true' /tmp/inc1.json
echo "✅ first compile detected"

python3 compiler/incremental/incremental_compiler.py examples/phase9_incremental/incremental_demo.panther > /tmp/inc2.json
grep -q '"changed": false' /tmp/inc2.json
echo "✅ cache hit detected"

./panther build examples/phase9_incremental/incremental_demo.panther --release >/tmp/incbuild.json
grep -q '"ok": true' /tmp/incbuild.json
test -f build/release/incremental_demo.sh
bash build/release/incremental_demo.sh | grep -q "Phase 9.4 Incremental Compilation"
echo "✅ release build passed"

echo "✅ PantherLang Phase 9.4 Incremental Compilation verification complete."
EOF
chmod +x scripts/verify_phase9_4_incremental.sh

echo "[phase9.4] Running verification..."
bash scripts/verify_phase9_4_incremental.sh

echo "============================================================"
echo " Phase 9.4 COMPLETE"
echo " Next: Phase 9.5 Advanced Optimization Pipeline"
echo "============================================================"
