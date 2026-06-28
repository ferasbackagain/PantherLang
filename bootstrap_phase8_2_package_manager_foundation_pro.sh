#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 8.2 PRO - Package Manager Foundation"
echo "============================================================"

mkdir -p package_manager/local_registry examples/phase8_packages scripts tests/phase8_2 docs/phase8

cat > package_manager/package_manager.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path


class PantherPackageError(Exception):
    pass


class PackageManager:
    def __init__(self, root: Path | None = None):
        self.root = root or Path.cwd()
        self.registry = self.root / "package_manager" / "local_registry"
        self.registry.mkdir(parents=True, exist_ok=True)

    def init_project(self, name: str, version: str = "0.1.0") -> Path:
        if not name.strip():
            raise PantherPackageError("Package name cannot be empty")
        manifest = self.root / "panther.toml"
        manifest.write_text(
            f'[project]\nname = "{name}"\nversion = "{version}"\n\n[dependencies]\n',
            encoding="utf-8",
        )
        return manifest

    def add(self, name: str, version: str = "latest") -> Path:
        if not name.strip():
            raise PantherPackageError("Dependency name cannot be empty")
        lock = self.root / "panther.lock"
        data = {"dependencies": {}}
        if lock.exists():
            data = json.loads(lock.read_text(encoding="utf-8"))
        data.setdefault("dependencies", {})[name] = version
        lock.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
        return lock

    def remove(self, name: str) -> Path:
        lock = self.root / "panther.lock"
        if not lock.exists():
            raise PantherPackageError("panther.lock not found")
        data = json.loads(lock.read_text(encoding="utf-8"))
        data.setdefault("dependencies", {}).pop(name, None)
        lock.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
        return lock

    def list_packages(self) -> dict:
        lock = self.root / "panther.lock"
        if not lock.exists():
            return {"dependencies": {}}
        return json.loads(lock.read_text(encoding="utf-8"))
PY

cat > package_manager/package_cli.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from package_manager.package_manager import PackageManager, PantherPackageError


def main() -> int:
    parser = argparse.ArgumentParser(prog="Panther package")
    sub = parser.add_subparsers(dest="cmd", required=True)

    init_p = sub.add_parser("init")
    init_p.add_argument("name")

    add_p = sub.add_parser("add")
    add_p.add_argument("name")
    add_p.add_argument("--version", default="latest")

    remove_p = sub.add_parser("remove")
    remove_p.add_argument("name")

    sub.add_parser("list")

    args = parser.parse_args()
    pm = PackageManager(Path.cwd())

    try:
        if args.cmd == "init":
            path = pm.init_project(args.name)
            print(f"✅ package initialized: {path}")
            return 0
        if args.cmd == "add":
            path = pm.add(args.name, args.version)
            print(f"✅ dependency added: {args.name}@{args.version}")
            print(path)
            return 0
        if args.cmd == "remove":
            path = pm.remove(args.name)
            print(f"✅ dependency removed: {args.name}")
            print(path)
            return 0
        if args.cmd == "list":
            print(json.dumps(pm.list_packages(), indent=2, sort_keys=True))
            return 0
    except PantherPackageError as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, indent=2))
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x package_manager/package_cli.py

cat > examples/phase8_packages/package_demo.panther <<'EOF'
module panther.package.demo

print "Phase 8.2 Package Manager Foundation"
EOF

cat > docs/phase8/PHASE_8_2_STATUS.md <<'EOF'
# Phase 8.2 — Package Manager Foundation

Completed:
- package manager core
- local registry folder
- panther.toml initialization
- panther.lock dependency lock file
- package add/remove/list
- CLI package bridge foundation
- practical demo
- verification script
EOF

if ! grep -q 'package_manager/package_cli.py' panther; then
  cp panther "panther.before_phase8_2"
  python3 - <<'PY'
from pathlib import Path
p = Path("panther")
txt = p.read_text()
needle = 'case "${1:-}" in\n'
insert = '  package)\n    shift\n    python3 "$ROOT/package_manager/package_cli.py" "$@"\n    ;;\n\n'
if needle not in txt:
    raise SystemExit("panther CLI case block not found")
txt = txt.replace(needle, needle + insert)
p.write_text(txt)
PY
  chmod +x panther
fi

cat > scripts/verify_phase8_2_package_manager.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.2 Package Manager Verification"
echo "============================================================"

test -f package_manager/package_manager.py
test -f package_manager/package_cli.py
test -d package_manager/local_registry
echo "✅ structure tests passed"

TMPDIR="$(mktemp -d)"
PROJECT_ROOT="$(pwd)"
(
  cd "$TMPDIR"
  PYTHONPATH="$PROJECT_ROOT" python3 "$PROJECT_ROOT/package_manager/package_cli.py" init demo_pkg | grep -q "package initialized"
  test -f panther.toml
  PYTHONPATH="$PROJECT_ROOT" python3 "$PROJECT_ROOT/package_manager/package_cli.py" add panther.ai --version 0.1.0 | grep -q "dependency added"
  test -f panther.lock
  PYTHONPATH="$PROJECT_ROOT" python3 "$PROJECT_ROOT/package_manager/package_cli.py" list | grep -q "panther.ai"
  PYTHONPATH="$PROJECT_ROOT" python3 "$PROJECT_ROOT/package_manager/package_cli.py" remove panther.ai | grep -q "dependency removed"
)
rm -rf "$TMPDIR"
echo "✅ package manager CLI tests passed"

./panther package list | grep -q "dependencies"
echo "✅ Panther package bridge tests passed"

./panther run examples/phase8_packages/package_demo.panther | grep -q "Phase 8.2 Package Manager Foundation"
echo "✅ compiler/runtime bridge tests passed"

python3 -m py_compile package_manager/package_manager.py package_manager/package_cli.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 8.2 Package Manager Foundation verification complete."
EOF
chmod +x scripts/verify_phase8_2_package_manager.sh

echo "[phase8.2] Running verification..."
bash scripts/verify_phase8_2_package_manager.sh

echo "============================================================"
echo " Phase 8.2 COMPLETE"
echo " Next: Phase 8.3 Project Templates"
echo "============================================================"
