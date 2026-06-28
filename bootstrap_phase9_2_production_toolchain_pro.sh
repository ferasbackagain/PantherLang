#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase9_2_production_toolchain_$STAMP"

echo "============================================================"
echo " PantherLang Phase 9.2 PRO - Production Toolchain"
echo "============================================================"
echo "[phase9.2] Project root: $ROOT"

fail(){ echo "[phase9.2][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "panther"
require_file "cli/panther_cli_v2.py"
require_file "compiler/pipeline/panther_compiler.py"

mkdir -p "$BACKUP_DIR"
for t in toolchain production_toolchain examples/phase9_toolchain scripts/verify_phase9_2_production_toolchain.sh docs/phase9 tests/phase9_2 CHANGELOG.md cli/panther_cli_v2.py panther; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

mkdir -p toolchain production_toolchain examples/phase9_toolchain scripts docs/phase9 tests/phase9_2

cat > toolchain/production_toolchain.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
COMPILER = PROJECT_ROOT / "compiler" / "pipeline" / "panther_compiler.py"


class PantherToolchainError(Exception):
    pass


@dataclass
class BuildProfile:
    name: str
    optimize: bool
    debug_symbols: bool
    output_dir: str


PROFILES = {
    "debug": BuildProfile("debug", optimize=False, debug_symbols=True, output_dir="build/debug"),
    "release": BuildProfile("release", optimize=True, debug_symbols=False, output_dir="build/release"),
}


def project_entry(cwd: Path) -> Path:
    manifest = cwd / "panther.toml"
    if manifest.exists():
        for line in manifest.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith("entry") and "=" in line:
                entry = line.split("=", 1)[1].strip().strip('"')
                candidate = cwd / entry
                if candidate.exists():
                    return candidate

    default = cwd / "src" / "main.panther"
    if default.exists():
        return default

    raise PantherToolchainError("No Panther entry found. Expected src/main.panther or panther.toml entry.")


def build(source: Path | None = None, profile: str = "debug", cwd: Path | None = None) -> dict[str, Any]:
    cwd = (cwd or Path.cwd()).resolve()
    if profile not in PROFILES:
        raise PantherToolchainError(f"Unknown build profile: {profile}")

    src = (source.expanduser().resolve() if source else project_entry(cwd))
    if not src.exists():
        raise PantherToolchainError(f"Source file not found: {src}")

    config = PROFILES[profile]
    out_dir = cwd / config.output_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    artifact = out_dir / f"{src.stem}.sh"

    proc = subprocess.run(
        [sys.executable, str(COMPILER), "compile", str(src), "--out", str(artifact)],
        cwd=PROJECT_ROOT,
        text=True,
        capture_output=True,
    )

    if proc.returncode != 0:
        return {
            "ok": False,
            "phase": "9.2",
            "profile": profile,
            "source": str(src),
            "artifact": str(artifact),
            "compiler_stdout": proc.stdout,
            "compiler_stderr": proc.stderr,
        }

    report = json.loads(proc.stdout)
    metadata = {
        "ok": True,
        "phase": "9.2",
        "profile": profile,
        "source": str(src),
        "artifact": str(artifact),
        "toolchain": asdict(config),
        "compiler_report": report,
        "project_local_build": str(artifact).startswith(str(cwd / "build")),
    }

    meta_path = artifact.with_suffix(".build.json")
    meta_path.write_text(json.dumps(metadata, indent=2, sort_keys=True), encoding="utf-8")
    return metadata


def clean(cwd: Path | None = None) -> dict[str, Any]:
    cwd = (cwd or Path.cwd()).resolve()
    build_dir = cwd / "build"
    if build_dir.exists():
        shutil.rmtree(build_dir)
    return {"ok": True, "phase": "9.2", "cleaned": str(build_dir)}


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(prog="panther-toolchain")
    sub = parser.add_subparsers(dest="cmd", required=True)

    build_p = sub.add_parser("build")
    build_p.add_argument("source", nargs="?")
    build_p.add_argument("--profile", choices=sorted(PROFILES), default="debug")
    build_p.add_argument("--release", action="store_true")

    sub.add_parser("clean")

    args = parser.parse_args()

    try:
        if args.cmd == "build":
            profile = "release" if args.release else args.profile
            result = build(Path(args.source) if args.source else None, profile=profile)
            print(json.dumps(result, indent=2, sort_keys=True))
            return 0 if result["ok"] else 2

        if args.cmd == "clean":
            print(json.dumps(clean(), indent=2, sort_keys=True))
            return 0

    except PantherToolchainError as exc:
        print(json.dumps({"ok": False, "phase": "9.2", "error": str(exc)}, indent=2))
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x toolchain/production_toolchain.py

cat > examples/phase9_toolchain/toolchain_demo.panther <<'EOF'
module panther.phase9.toolchain

print "Phase 9.2 Production Toolchain"
print "Debug and release builds"
EOF

cat > docs/phase9/PHASE_9_2_STATUS.md <<'EOF'
# Phase 9.2 — Production Toolchain

Completed:
- Production toolchain module
- Debug profile
- Release profile
- Project-local artifact metadata
- Toolchain clean command
- Panther CLI bridge
- Real external-project build tests
- Verification script

Next: Phase 9.3 — Compiler Optimization.
EOF

python3 - <<'PY'
from pathlib import Path
p = Path("panther")
txt = p.read_text()

if 'toolchain/production_toolchain.py' not in txt:
    needle = 'case "${1:-}" in\n'
    insert = '  toolchain)\n    shift\n    python3 "$ROOT/toolchain/production_toolchain.py" "$@"\n    ;;\n\n'
    if needle not in txt:
        raise SystemExit("panther case block not found")
    txt = txt.replace(needle, needle + insert)

old = '  new|run|build|check)\n    python3 "$ROOT/cli/panther_cli_v2.py" "$@"\n    ;;\n'
new = '  build)\n    shift\n    python3 "$ROOT/toolchain/production_toolchain.py" build "$@"\n    ;;\n\n  new|run|check)\n    python3 "$ROOT/cli/panther_cli_v2.py" "$@"\n    ;;\n'
if old in txt:
    txt = txt.replace(old, new)

p.write_text(txt)
PY
chmod +x panther

cat > scripts/verify_phase9_2_production_toolchain.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.2 Production Toolchain Verification"
echo "============================================================"

test -f toolchain/production_toolchain.py
test -f examples/phase9_toolchain/toolchain_demo.panther
test -f docs/phase9/PHASE_9_2_STATUS.md
echo "✅ structure tests passed"

python3 -m py_compile toolchain/production_toolchain.py
echo "✅ python compile passed"

TMP="$(mktemp -d)"
PROJECT_ROOT="$(pwd)"
(
  cd "$TMP"
  "$PROJECT_ROOT/panther" new console ToolchainApp >/dev/null
  cd ToolchainApp

  "$PROJECT_ROOT/panther" build >/tmp/p9_2_debug.json
  grep -q '"ok": true' /tmp/p9_2_debug.json
  grep -q '"profile": "debug"' /tmp/p9_2_debug.json
  test -f build/debug/main.sh
  test -f build/debug/main.build.json
  bash build/debug/main.sh | grep -q "Hello from Panther Console Template"

  "$PROJECT_ROOT/panther" build --release >/tmp/p9_2_release.json
  grep -q '"ok": true' /tmp/p9_2_release.json
  grep -q '"profile": "release"' /tmp/p9_2_release.json
  test -f build/release/main.sh
  test -f build/release/main.build.json
  bash build/release/main.sh | grep -q "Hello from Panther Console Template"

  "$PROJECT_ROOT/panther" toolchain clean >/tmp/p9_2_clean.json
  grep -q '"ok": true' /tmp/p9_2_clean.json
  test ! -d build
)
rm -rf "$TMP"
echo "✅ real external project toolchain tests passed"

./panther build examples/phase9_toolchain/toolchain_demo.panther --release >/tmp/p9_2_repo_release.json
grep -q '"ok": true' /tmp/p9_2_repo_release.json
grep -q '"profile": "release"' /tmp/p9_2_repo_release.json
test -f build/release/toolchain_demo.sh
bash build/release/toolchain_demo.sh | grep -q "Phase 9.2 Production Toolchain"
echo "✅ repository release build test passed"

echo "✅ PantherLang Phase 9.2 Production Toolchain verification complete."
EOF
chmod +x scripts/verify_phase9_2_production_toolchain.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 9.2 — Production Toolchain

Added production toolchain foundation:
- debug and release profiles
- project-local build output
- build metadata files
- toolchain clean command
- Panther build integration through production toolchain
- real external-project verification

Next: Phase 9.3 Compiler Optimization.
EOF

echo "[phase9.2] Running verification..."
bash scripts/verify_phase9_2_production_toolchain.sh

echo "============================================================"
echo " Phase 9.2 COMPLETE"
echo " Next: Phase 9.3 Compiler Optimization"
echo "============================================================"
