#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 9.1 PRO - Production Build System"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase9_1_production_build_$STAMP"

mkdir -p "$BACKUP_DIR"
for t in cli/panther_cli_v2.py build_system examples/phase9_build scripts/verify_phase9_1_production_build.sh docs/phase9 tests/phase9_1 CHANGELOG.md; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

mkdir -p build_system examples/phase9_build scripts docs/phase9 tests/phase9_1
touch build_system/__init__.py

cat > build_system/build_manifest.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path


def write_build_manifest(project_root: Path, source: Path, artifact: Path, mode: str) -> Path:
    manifest = {
        "phase": "9.1",
        "mode": mode,
        "project_root": str(project_root),
        "source": str(source),
        "artifact": str(artifact),
        "production_build": True,
        "local_build_output": True
    }
    out = project_root / "build" / "build_manifest.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
    return out
PY

python3 - <<'PY'
from pathlib import Path

p = Path("cli/panther_cli_v2.py")
txt = p.read_text()

if "from build_system.build_manifest import write_build_manifest" not in txt:
    txt = txt.replace(
        "from typing import Any\n",
        "from typing import Any\n\nfrom build_system.build_manifest import write_build_manifest\n"
    )

start = txt.find("def build_panther_file(")
end = txt.find("\n\ndef check_panther_file", start)
if start == -1 or end == -1:
    raise SystemExit("build_panther_file boundary not found")

new_func = '''def build_panther_file(source: Path, out: Path | None = None, mode: str = "debug") -> int:
    source = source.expanduser().resolve()
    if not source.exists():
        raise PantherCLIError(f"Source file not found: {source}")
    if source.suffix != ".panther":
        raise PantherCLIError("panther build expects a .panther file")

    project_root = Path.cwd().resolve()
    if out is None:
        out = project_root / "build" / f"{source.stem}.sh"
    else:
        out = out.expanduser().resolve()

    out.parent.mkdir(parents=True, exist_ok=True)

    proc = subprocess.run(
        [sys.executable, str(COMPILER), "compile", str(source), "--out", str(out)],
        cwd=ROOT,
        text=True,
    )
    if proc.returncode == 0:
        write_build_manifest(project_root, source, out, mode)
        print(f"✅ build complete: {out}")
        print(f"mode: {mode}")
    return proc.returncode
'''
txt = txt[:start] + new_func + txt[end:]

txt = txt.replace(
'''    build_p = sub.add_parser("build")
    build_p.add_argument("source", nargs="?")
    build_p.add_argument("--out", default=None)
''',
'''    build_p = sub.add_parser("build")
    build_p.add_argument("source", nargs="?")
    build_p.add_argument("--out", default=None)
    build_p.add_argument("--release", action="store_true")
    build_p.add_argument("--debug", action="store_true")
'''
)

txt = txt.replace(
'''        if args.cmd == "build":
            source = Path(args.source) if args.source else Path("src/main.panther")
            out = Path(args.out) if args.out else None
            return build_panther_file(source, out)
''',
'''        if args.cmd == "build":
            source = Path(args.source) if args.source else Path("src/main.panther")
            out = Path(args.out) if args.out else None
            mode = "release" if args.release else "debug"
            return build_panther_file(source, out, mode)
'''
)

p.write_text(txt)
print("✅ patched Panther build for project-local output and build modes")
PY

cat > examples/phase9_build/production_build_demo.panther <<'EOF'
module panther.phase9.build

print "Phase 9.1 Production Build System"
EOF

cat > docs/phase9/PHASE_9_1_STATUS.md <<'EOF'
# Phase 9.1 — Production Build System

Completed:
- Project-local build output
- build/ artifact generation per project
- debug/release mode flag foundation
- build manifest generation
- real external project smoke test
- Panther CLI integration

Primary fix:
`Panther build` now writes into the current project's `build/` directory instead of the PantherLang source repository.
EOF

cat > tests/phase9_1/test_production_build.py <<'PY'
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_project_local_build(tmp_path: Path) -> None:
    project_name = "App"
    project = tmp_path / project_name
    subprocess.run([str(ROOT / "panther"), "new", "console", project_name], cwd=tmp_path, check=True)
    proc = subprocess.run([str(ROOT / "panther"), "build"], cwd=project, text=True, capture_output=True)
    assert proc.returncode == 0
    assert (project / "build" / "main.sh").exists()
    assert (project / "build" / "build_manifest.json").exists()
    manifest = json.loads((project / "build" / "build_manifest.json").read_text())
    assert manifest["phase"] == "9.1"
    assert manifest["local_build_output"] is True
PY

cat > scripts/verify_phase9_1_production_build.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.1 Production Build Verification"
echo "============================================================"

test -f build_system/build_manifest.py
test -f examples/phase9_build/production_build_demo.panther
test -f docs/phase9/PHASE_9_1_STATUS.md
echo "✅ structure tests passed"

python3 -m py_compile build_system/build_manifest.py cli/panther_cli_v2.py
echo "✅ python compile passed"

TMP="$(mktemp -d)"
(
  cd "$TMP"
  Panther new console BuildApp >/dev/null
  cd BuildApp
  Panther build >/tmp/p9_build.out
  grep -q "build complete" /tmp/p9_build.out
  grep -q "mode: debug" /tmp/p9_build.out
  test -f build/main.sh
  test -f build/build_manifest.json
  bash build/main.sh | grep -q "Hello from Panther Console Template"

  Panther build --release >/tmp/p9_release.out
  grep -q "mode: release" /tmp/p9_release.out
)
rm -rf "$TMP"
echo "✅ real external project build tests passed"

Panther run examples/phase9_build/production_build_demo.panther | grep -q "Phase 9.1 Production Build System"
echo "✅ runtime bridge passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase9_1 >/tmp/panther_phase9_1_pytest.log
  echo "✅ pytest suite passed"
fi

echo "✅ PantherLang Phase 9.1 Production Build System verification complete."
EOF
chmod +x scripts/verify_phase9_1_production_build.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 9.1 — Production Build System

Added production build system foundation:
- Project-local build output
- `Panther build` now writes to the current project's `build/`
- Debug/release mode foundation
- build manifest
- real external project smoke test

Next: Phase 9.2 Optimizing Compiler.
EOF

echo "[phase9.1] Running verification..."
bash scripts/verify_phase9_1_production_build.sh

echo "============================================================"
echo " Phase 9.1 COMPLETE"
echo " Next: Phase 9.2 Optimizing Compiler"
echo "============================================================"
