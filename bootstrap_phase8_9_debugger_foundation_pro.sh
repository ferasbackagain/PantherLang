#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 8.9 PRO - Debugger Foundation"
echo "============================================================"

mkdir -p tools/debugger examples/phase8_debugger scripts docs/phase8 tests/phase8_9

cat > tools/debugger/panther_debugger.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


class PantherDebugger:
    def __init__(self, source: Path):
        self.source = source
        self.lines = source.read_text(encoding="utf-8").splitlines()
        self.breakpoints: set[int] = set()

    def add_breakpoint(self, line: int) -> None:
        if line < 1 or line > len(self.lines):
            raise ValueError(f"Invalid breakpoint line: {line}")
        self.breakpoints.add(line)

    def trace(self) -> list[dict]:
        events = []
        for index, line in enumerate(self.lines, start=1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            events.append({
                "line": index,
                "source": stripped,
                "breakpoint": index in self.breakpoints
            })
        return events


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-debugger")
    parser.add_argument("source")
    parser.add_argument("--breakpoint", type=int, action="append", default=[])
    args = parser.parse_args()

    dbg = PantherDebugger(Path(args.source))
    for bp in args.breakpoint:
        dbg.add_breakpoint(bp)

    print(json.dumps({
        "ok": True,
        "phase": "8.9",
        "source": args.source,
        "breakpoints": sorted(dbg.breakpoints),
        "trace": dbg.trace()
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x tools/debugger/panther_debugger.py

cat > examples/phase8_debugger/debug_demo.panther <<'EOF'
module panther.debugger

let name = "PantherLang"
print "Phase 8.9 Debugger Foundation"
print name
EOF

cat > docs/phase8/PHASE_8_9_STATUS.md <<'EOF'
# Phase 8.9 — Debugger Foundation

Completed:
- Debugger trace engine
- Breakpoint model
- Source line tracing
- JSON debug output
- Panther CLI bridge
- runtime demo
- verification script

Next: Phase 8.10 — Final Developer Experience Integration.
EOF

# Patch panther CLI with debug command.
if ! grep -q 'tools/debugger/panther_debugger.py' panther; then
python3 - <<'PY'
from pathlib import Path
p=Path("panther")
t=p.read_text()
needle='  lsp)\n'
ins='  debug)\n    shift\n    python3 "$ROOT/tools/debugger/panther_debugger.py" "$@"\n    ;;\n\n'
if ins not in t:
    t=t.replace(needle,ins+needle)
p.write_text(t)
PY
chmod +x panther
fi

cat > scripts/verify_phase8_9_debugger.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.9 Debugger Verification"
echo "============================================================"

test -f tools/debugger/panther_debugger.py
test -f examples/phase8_debugger/debug_demo.panther
echo "✅ structure tests passed"

python3 tools/debugger/panther_debugger.py examples/phase8_debugger/debug_demo.panther --breakpoint 4 | grep -q '"ok": true'
python3 tools/debugger/panther_debugger.py examples/phase8_debugger/debug_demo.panther --breakpoint 4 | grep -q '"breakpoint": true'
echo "✅ debugger trace/breakpoint tests passed"

./panther debug examples/phase8_debugger/debug_demo.panther --breakpoint 4 | grep -q '"phase": "8.9"'
echo "✅ Panther debug CLI bridge tests passed"

./panther run examples/phase8_debugger/debug_demo.panther | grep -q "Phase 8.9 Debugger Foundation"
echo "✅ runtime bridge tests passed"

python3 -m py_compile tools/debugger/panther_debugger.py
echo "✅ python compile passed"

echo "✅ PantherLang Phase 8.9 Debugger Foundation verification complete."
EOF
chmod +x scripts/verify_phase8_9_debugger.sh

echo "[phase8.9] Running verification..."
bash scripts/verify_phase8_9_debugger.sh

echo "============================================================"
echo " Phase 8.9 COMPLETE"
echo " Next: Phase 8.10 Final Developer Experience Integration"
echo "============================================================"
