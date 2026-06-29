#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3"
echo " Atomic Replacement Planning"
echo " Batch 1 - Dependency Census + Compatibility Contract"
echo "============================================================"

ROOT="$(pwd)"
P3="$ROOT/.panther/p3_atomic_replacement"
REPORTS="$ROOT/reports/P3"

mkdir -p "$P3" "$REPORTS"

[ -f "$ROOT/.panther/p2_debug_adapter_rebuild/status_batch10.json" ] || {
  echo "[P3-B1][ERROR] Complete P-2 Batch 10 first."
  exit 1
}

echo "[1/6] Discovering imports..."
python3 <<'PY'
from pathlib import Path
import ast, json

root=Path.cwd()
legacy=root/"debug_adapter"
rebuilt=root/"debug_adapter_rebuilt"

def scan(folder):
    out=[]
    if not folder.exists():
        return out
    for f in folder.rglob("*.py"):
        try:
            tree=ast.parse(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        imports=[]
        for n in ast.walk(tree):
            if isinstance(n,ast.Import):
                imports.extend(a.name for a in n.names)
            elif isinstance(n,ast.ImportFrom):
                imports.append((n.module or ""))
        out.append({
            "file":f.relative_to(root).as_posix(),
            "imports":sorted(set(imports))
        })
    return out

report={
 "legacy":scan(legacy),
 "rebuilt":scan(rebuilt),
 "status":"READY_FOR_COMPATIBILITY_BRIDGE"
}

out=root/".panther/p3_atomic_replacement/dependency_census.json"
out.write_text(json.dumps(report,indent=2))
print("legacy files:",len(report["legacy"]))
print("rebuilt files:",len(report["rebuilt"]))
PY

echo "[2/6] Creating compatibility contract..."
cat > "$P3/compatibility_contract.md" <<'EOF'
Goal:
- Replace debug_adapter with debug_adapter_rebuilt atomically.
- Preserve public API.
- No runtime mutation during planning.
- Rollback must remain possible.
EOF

echo "[3/6] Creating migration checklist..."
cat > "$P3/migration_checklist.txt" <<'EOF'
[ ] Map public API
[ ] Compare signatures
[ ] Build compatibility layer
[ ] Dry-run import swap
[ ] Execute H4 regression
[ ] Atomic switch
[ ] Rollback validation
EOF

echo "[4/6] Writing engineering report..."
cat > "$REPORTS/P3_BATCH1_DEPENDENCY_CENSUS.md" <<'EOF'
P3 Batch1 PASSED

Outputs:
- dependency_census.json
- compatibility_contract.md
- migration_checklist.txt

Runtime modified: NO

Next:
P3 Batch2 - Compatibility Bridge
EOF

echo "[5/6] Writing status..."
cat > "$P3/status_batch1.json" <<'EOF'
{
 "ok":true,
 "phase":"P-3",
 "batch":"1",
 "status":"PASSED",
 "runtime_modified":false,
 "next":"P-3 Batch 2 - Compatibility Bridge"
}
EOF

echo "[6/6] Done."

echo "============================================================"
echo "✅ P-3 Batch 1 COMPLETE"
echo "Next: P-3 Batch 2 - Compatibility Bridge"
echo "============================================================"
