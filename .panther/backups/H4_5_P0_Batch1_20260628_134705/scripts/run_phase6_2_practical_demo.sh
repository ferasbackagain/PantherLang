#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="$(pwd):${PYTHONPATH:-}"
DEMO_DIR="build/phase6_2_demo_workspace"
CACHE_DIR="build/phase6_2_demo_cache"
rm -rf "$DEMO_DIR" "$CACHE_DIR"
mkdir -p "$DEMO_DIR"
cp examples/compiler/phase6_2_alpha.panther "$DEMO_DIR/alpha.panther"
cp examples/compiler/phase6_2_beta.panther "$DEMO_DIR/beta.panther"
python - <<'PY'
from pathlib import Path
from language.compiler.incremental import IncrementalCompiler
workspace = Path("build/phase6_2_demo_workspace")
compiler = IncrementalCompiler(cache_dir="build/phase6_2_demo_cache")
first = compiler.build(workspace)
second = compiler.build(workspace)
alpha = workspace / "alpha.panther"
alpha.write_text(alpha.read_text() + "\nmodel AlphaAudit { id: int required }\n", encoding="utf-8")
third = compiler.build(workspace)
assert first.plan.total_sources == 2 and len(first.compiled) == 2
assert second.plan.cache_hit_ratio == 1.0 and len(second.compiled) == 0
assert third.compiled == ["alpha.panther"]
Path("build/reports/phase6_2_practical_demo_report.json").write_text(third.to_json(), encoding="utf-8")
print("✅ PantherLang Phase 6.2 practical demo passed")
print(f"   first compiled: {first.compiled}")
print(f"   second reused: {second.reused}")
print(f"   third compiled after edit: {third.compiled}")
PY
