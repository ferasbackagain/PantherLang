#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="$(pwd):${PYTHONPATH:-}"
printf '\n============================================================\n'
printf ' PantherLang Phase 6.2 PRO Verification\n'
printf '============================================================\n'

required=(
  "language/compiler/incremental/__init__.py"
  "language/compiler/incremental/incremental_compiler.py"
  "tests/phase6_2/test_incremental_compilation.py"
  "scripts/run_phase6_2_practical_demo.sh"
  "docs/phase6/PHASE_6_2_INCREMENTAL_COMPILATION.md"
  "examples/compiler/phase6_2_alpha.panther"
  "examples/compiler/phase6_2_beta.panther"
)
for f in "${required[@]}"; do
  [ -f "$f" ] || { echo "❌ missing required file: $f"; exit 1; }
done
echo "✅ structure tests passed"

python - <<'PY'
from pathlib import Path
from language.compiler.incremental import IncrementalCompiler
assert IncrementalCompiler.phase == "6.2"
assert IncrementalCompiler.version == "0.6.2-incremental-compilation"
print("✅ manifest tests passed")
PY

python -m pytest tests/phase6_2/test_incremental_compilation.py -q

echo "✅ pytest regression suite passed"
bash scripts/run_phase6_2_practical_demo.sh

echo "✅ practical demo passed"
python - <<'PY'
from pathlib import Path
from language.compiler.incremental import IncrementalCompiler, IncrementalBuildError
ws = Path("build/phase6_2_negative_workspace")
cache = Path("build/phase6_2_negative_cache")
import shutil
shutil.rmtree(ws, ignore_errors=True)
shutil.rmtree(cache, ignore_errors=True)
ws.mkdir(parents=True)
(ws / "bad.panther").write_text("panic_incremental_compiler", encoding="utf-8")
try:
    IncrementalCompiler(cache_dir=cache).build(ws)
except IncrementalBuildError:
    print("✅ negative tests passed")
else:
    raise SystemExit("negative test failed")
PY

python - <<'PY'
from pathlib import Path
from language.compiler.incremental import IncrementalCompiler
import shutil
ws = Path("build/phase6_2_stress_workspace")
cache = Path("build/phase6_2_stress_cache")
shutil.rmtree(ws, ignore_errors=True)
shutil.rmtree(cache, ignore_errors=True)
ws.mkdir(parents=True)
for i in range(120):
    (ws / f"stress_{i}.panther").write_text(f"model Stress{i} {{ id: int required }}\n", encoding="utf-8")
compiler = IncrementalCompiler(cache_dir=cache)
first = compiler.build(ws)
second = compiler.build(ws)
assert len(first.compiled) == 120
assert second.compiled == []
assert len(second.reused) == 120
Path("build/reports/phase6_2_incremental_report.json").write_text(second.to_json(), encoding="utf-8")
print("✅ stress tests passed")
PY

echo "✅ PantherLang Phase 6.2 Incremental Compilation verification complete."
printf '============================================================\n'
