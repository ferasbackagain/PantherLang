#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase7_2_cli_run_$STAMP"

echo "============================================================"
echo " PantherLang Phase 7.2 PRO - Panther CLI Run Foundation"
echo "============================================================"
echo "[phase7.2] Project root: $ROOT"

fail(){ echo "[phase7.2][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "README.md"
require_file "CHANGELOG.md"
require_file "panther"
require_file "compiler/pipeline/panther_compiler.py"
require_file "scripts/verify_phase7_1_ai_runtime.sh"

mkdir -p "$BACKUP_DIR"
for t in cli docs/phase7 examples/phase7_cli tests/phase7_2 scripts/verify_phase7_2_cli_run.sh scripts/run_phase7_2_practical_demo.sh scripts/verify_phase7_all.sh CHANGELOG.md panther; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

echo "[phase7.2] Verifying Phase 7.1 baseline..."
bash scripts/verify_phase7_1_ai_runtime.sh >/tmp/panther_phase7_2_phase71.log

mkdir -p cli docs/phase7 examples/phase7_cli tests/phase7_2 scripts build
touch cli/__init__.py

cat > cli/panther_cli_v2.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"


class PantherCLIError(Exception):
    pass


def print_json(data: Any) -> None:
    print(json.dumps(data, indent=2, sort_keys=True))


def run_panther_file(source: Path) -> int:
    if not source.exists():
        raise PantherCLIError(f"Source file not found: {source}")
    if source.suffix != ".panther":
        raise PantherCLIError("panther run expects a .panther file")

    build_dir = ROOT / "build" / "panther-run"
    build_dir.mkdir(parents=True, exist_ok=True)
    artifact = build_dir / f"{source.stem}.sh"

    compile_proc = subprocess.run(
        [sys.executable, str(COMPILER), "compile", str(source), "--out", str(artifact)],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if compile_proc.returncode != 0:
        sys.stdout.write(compile_proc.stdout)
        sys.stderr.write(compile_proc.stderr)
        return compile_proc.returncode

    run_proc = subprocess.run([str(artifact)], cwd=ROOT, text=True)
    return run_proc.returncode


def build_panther_file(source: Path, out: Path | None = None) -> int:
    if not source.exists():
        raise PantherCLIError(f"Source file not found: {source}")
    if source.suffix != ".panther":
        raise PantherCLIError("panther build expects a .panther file")

    out = out or (ROOT / "build" / f"{source.stem}.sh")
    out.parent.mkdir(parents=True, exist_ok=True)

    proc = subprocess.run(
        [sys.executable, str(COMPILER), "compile", str(source), "--out", str(out)],
        cwd=ROOT,
        text=True,
    )
    if proc.returncode == 0:
        print(f"✅ build complete: {out}")
    return proc.returncode


def check_panther_file(source: Path) -> int:
    if not source.exists():
        raise PantherCLIError(f"Source file not found: {source}")
    with tempfile.NamedTemporaryFile(prefix="panther_check_", suffix=".sh") as tmp:
        proc = subprocess.run(
            [sys.executable, str(COMPILER), "compile", str(source), "--out", tmp.name],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
    if proc.returncode == 0:
        print("✅ check passed")
    else:
        sys.stdout.write(proc.stdout)
        sys.stderr.write(proc.stderr)
    return proc.returncode


def new_project(name: str) -> int:
    if not name or "/" in name or "\\" in name:
        raise PantherCLIError("Invalid project name")
    project = Path.cwd() / name
    if project.exists():
        raise PantherCLIError(f"Project already exists: {project}")

    (project / "src").mkdir(parents=True)
    (project / "tests").mkdir()
    (project / "docs").mkdir()
    (project / "build").mkdir()

    (project / "panther.toml").write_text(
        f'[project]\nname = "{name}"\nversion = "0.1.0"\nphase = "7.2"\n',
        encoding="utf-8",
    )
    (project / "src" / "main.panther").write_text(
        f'module {name}.main\n\nprint "Hello from {name}"\n',
        encoding="utf-8",
    )
    print(f"✅ Panther project created: {project}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther")
    sub = parser.add_subparsers(dest="cmd", required=True)

    run_p = sub.add_parser("run")
    run_p.add_argument("source")

    build_p = sub.add_parser("build")
    build_p.add_argument("source")
    build_p.add_argument("--out", default=None)

    check_p = sub.add_parser("check")
    check_p.add_argument("source")

    new_p = sub.add_parser("new")
    new_p.add_argument("name")

    sub.add_parser("doctor")

    args = parser.parse_args(argv)

    try:
        if args.cmd == "run":
            return run_panther_file(Path(args.source))
        if args.cmd == "build":
            out = Path(args.out) if args.out else None
            return build_panther_file(Path(args.source), out)
        if args.cmd == "check":
            return check_panther_file(Path(args.source))
        if args.cmd == "new":
            return new_project(args.name)
        if args.cmd == "doctor":
            print("Panther CLI v2: OK")
            print("phase: 7.2")
            print("commands: new, run, build, check")
            return 0
    except PantherCLIError as exc:
        print_json({"ok": False, "phase": "7.2", "error": str(exc)})
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x cli/panther_cli_v2.py

cat > docs/phase7/PHASE_7_2_STATUS.md <<'EOF'
# Phase 7.2 Status — Panther CLI Run Foundation PRO

Completed:
- Panther CLI v2 foundation
- `panther run file.panther`
- `panther build file.panther`
- `panther check file.panther`
- `panther new project`
- CLI doctor
- practical CLI demo
- negative tests
- pytest suite

Next: Phase 7.3 — Agent Execution Engine.
EOF

cat > examples/phase7_cli/cli_run_demo.panther <<'EOF'
module panther.cli.demo

fn announce(name) {
    print "Panther CLI run works"
    print name
}

let project = "PantherLang"
announce(project)

print "Phase 7.2 CLI run foundation"
EOF

cat > scripts/run_phase7_2_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

RUN_OUT="$(./panther run examples/phase7_cli/cli_run_demo.panther)"
echo "$RUN_OUT" | grep -q 'Panther CLI run works'
echo "$RUN_OUT" | grep -q 'PantherLang'
echo "$RUN_OUT" | grep -q 'Phase 7.2 CLI run foundation'

./panther check examples/phase7_cli/cli_run_demo.panther | grep -q 'check passed'

./panther build examples/phase7_cli/cli_run_demo.panther --out /tmp/panther_phase7_2_build.sh | grep -q 'build complete'
bash /tmp/panther_phase7_2_build.sh | grep -q 'Phase 7.2 CLI run foundation'
rm -f /tmp/panther_phase7_2_build.sh

echo "demo=phase7.2-cli-run"
echo "ok=true"
echo "panther_run=true"
echo "panther_build=true"
echo "panther_check=true"
echo "artifact_runs=true"
EOF
chmod +x scripts/run_phase7_2_practical_demo.sh

cat > tests/phase7_2/test_cli_run.py <<'EOF'
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_panther_run() -> None:
    proc = subprocess.run(
        [str(ROOT / "panther"), "run", "examples/phase7_cli/cli_run_demo.panther"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    assert "Panther CLI run works" in proc.stdout
    assert "Phase 7.2 CLI run foundation" in proc.stdout


def test_panther_check() -> None:
    proc = subprocess.run(
        [str(ROOT / "panther"), "check", "examples/phase7_cli/cli_run_demo.panther"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    assert "check passed" in proc.stdout


def test_panther_run_missing_fails() -> None:
    proc = subprocess.run(
        [str(ROOT / "panther"), "run", "missing.panther"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 2
    assert "Source file not found" in proc.stdout
EOF

# Patch panther CLI so run/build/check/new are first-class commands.
cp panther "$BACKUP_DIR/panther.before_phase7_2"

cat > panther <<'SH'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  new|run|build|check)
    python3 "$ROOT/cli/panther_cli_v2.py" "$@"
    ;;

  runtime)
    shift
    python3 "$ROOT/runtime/ai_runtime/runtime_api.py" "$@"
    ;;

  compile)
    shift
    python3 "$ROOT/compiler/pipeline/panther_compiler.py" compile "$@"
    ;;

  compiler-demo)
    shift || true
    python3 "$ROOT/compiler/pipeline/panther_compiler.py" demo "$@"
    ;;

  doctor)
    echo "PantherLang doctor: OK"
    python3 "$ROOT/cli/panther_cli_v2.py" doctor
    ;;

  phase5-verify)
    bash "$ROOT/scripts/verify_phase5_all.sh"
    ;;

  phase6-verify)
    bash "$ROOT/scripts/verify_phase6_all.sh"
    ;;

  phase7-verify)
    bash "$ROOT/scripts/verify_phase7_all.sh"
    ;;

  *)
    echo "PantherLang CLI"
    echo "Usage:"
    echo "  ./panther doctor"
    echo "  ./panther new <project>"
    echo "  ./panther run <file.panther>"
    echo "  ./panther build <file.panther> [--out artifact.sh]"
    echo "  ./panther check <file.panther>"
    echo "  ./panther compile <source.panther> --out <artifact.sh>"
    echo "  ./panther runtime demo"
    ;;
esac
SH
chmod +x panther

cat > scripts/verify_phase7_2_cli_run.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.2 PRO CLI Run Verification"
echo "============================================================"

test -f cli/panther_cli_v2.py
test -f examples/phase7_cli/cli_run_demo.panther
test -x scripts/run_phase7_2_practical_demo.sh
test -f tests/phase7_2/test_cli_run.py
echo "✅ structure tests passed"

./panther doctor | grep -q 'Panther CLI v2: OK'
echo "✅ CLI doctor tests passed"

RUN_OUT="$(./panther run examples/phase7_cli/cli_run_demo.panther)"
echo "$RUN_OUT" | grep -q 'Panther CLI run works'
echo "$RUN_OUT" | grep -q 'PantherLang'
echo "$RUN_OUT" | grep -q 'Phase 7.2 CLI run foundation'
echo "✅ panther run tests passed"

./panther check examples/phase7_cli/cli_run_demo.panther | grep -q 'check passed'
echo "✅ panther check tests passed"

./panther build examples/phase7_cli/cli_run_demo.panther --out /tmp/panther_phase7_2_verify_build.sh | grep -q 'build complete'
bash /tmp/panther_phase7_2_verify_build.sh | grep -q 'Phase 7.2 CLI run foundation'
rm -f /tmp/panther_phase7_2_verify_build.sh
echo "✅ panther build tests passed"

set +e
BAD_OUT="$(./panther run missing.panther)"
BAD_CODE=$?
set -e
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase7.2][ERROR] missing source should fail"
  exit 1
fi
echo "$BAD_OUT" | grep -q 'Source file not found'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase7_2_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase7.2-cli-run'
echo "$PRACTICAL_OUT" | grep -q 'panther_run=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical CLI demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase7_2 >/tmp/panther_phase7_2_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile cli/panther_cli_v2.py
  echo "✅ python compile tests passed"
fi

echo "✅ PantherLang Phase 7.2 CLI Run Foundation verification complete."
EOF
chmod +x scripts/verify_phase7_2_cli_run.sh

cat > scripts/verify_phase7_all.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase7_1_ai_runtime.sh
bash scripts/verify_phase7_2_cli_run.sh
echo "✅ ALL PHASE 7 TESTS PASSED THROUGH 7.2"
EOF
chmod +x scripts/verify_phase7_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 7.2 — Panther CLI Run Foundation PRO

Added first-class Panther CLI commands:
- panther new
- panther run
- panther build
- panther check
- CLI doctor
- practical CLI workflow
- pytest suite

This changes the developer workflow from manual compile/bash execution to first-class Panther commands.

Next: Phase 7.3 Agent Execution Engine.
EOF

echo "[phase7.2] Running professional verification..."
bash scripts/verify_phase7_2_cli_run.sh

echo "============================================================"
echo " Phase 7.2 COMPLETE"
echo " Next: Phase 7.3 Agent Execution Engine"
echo "============================================================"
