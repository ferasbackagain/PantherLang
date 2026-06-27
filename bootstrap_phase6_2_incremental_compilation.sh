#!/usr/bin/env bash
set -euo pipefail

PHASE="6.2"
PHASE_NAME="Incremental Compilation"
VERSION="0.6.2-incremental-compilation"
ROOT="$(pwd)"

printf '\n============================================================\n'
printf ' PantherLang Phase %s — %s\n' "$PHASE" "$PHASE_NAME"
printf '============================================================\n'

if [ ! -d "language" ] || [ ! -d "tests" ]; then
  echo "❌ Run this script from the PantherLang project root."
  exit 1
fi

mkdir -p \
  language/compiler/incremental \
  tests/phase6_2 \
  scripts \
  docs/phase6 \
  examples/compiler \
  build/reports \
  build/incremental_cache \
  .phase_backups

BACKUP_DIR=".phase_backups/phase6_2_incremental_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
for f in CHANGELOG.md VERSION_PLAN.md README.md; do
  [ -f "$f" ] && cp "$f" "$BACKUP_DIR/$f"
done

cat > language/compiler/incremental/__init__.py <<'PY'
from .incremental_compiler import (
    IncrementalBuildError,
    IncrementalBuildPlan,
    IncrementalBuildResult,
    IncrementalCompiler,
    SourceUnit,
)

__all__ = [
    "IncrementalBuildError",
    "IncrementalBuildPlan",
    "IncrementalBuildResult",
    "IncrementalCompiler",
    "SourceUnit",
]
PY

cat > language/compiler/incremental/incremental_compiler.py <<'PY'
from __future__ import annotations

import hashlib
import json
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

try:
    from language.compiler.integration import PantherCompilerIntegrationFramework
except Exception:  # pragma: no cover
    PantherCompilerIntegrationFramework = None  # type: ignore


class IncrementalBuildError(RuntimeError):
    """Raised when the incremental compiler receives invalid input."""


@dataclass(frozen=True)
class SourceUnit:
    path: str
    sha256: str
    size_bytes: int
    mtime_ns: int


@dataclass
class IncrementalBuildPlan:
    changed: List[str]
    unchanged: List[str]
    removed: List[str]
    total_sources: int
    cache_hit_ratio: float


@dataclass
class IncrementalBuildResult:
    ok: bool
    phase: str
    version: str
    workspace: str
    plan: IncrementalBuildPlan
    compiled: List[str]
    reused: List[str]
    removed: List[str]
    artifacts: Dict[str, str]
    duration_ms: float
    cache_path: str
    external_api_used: bool = False
    network_required: bool = False
    diagnostics: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        data["plan"] = asdict(self.plan)
        return data

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2, sort_keys=True)


class IncrementalCompiler:
    """Deterministic incremental compiler wrapper for PantherLang Phase 6.2.

    It tracks Panther source fingerprints in a JSON state file, recompiles only changed
    sources, reuses unchanged artifacts, records removed sources, and keeps the system
    fully local/offline.
    """

    phase = "6.2"
    version = "0.6.2-incremental-compilation"

    def __init__(self, cache_dir: str | Path = "build/incremental_cache", compiler: Any | None = None) -> None:
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.state_path = self.cache_dir / "phase6_2_state.json"
        self.artifact_dir = self.cache_dir / "artifacts"
        self.artifact_dir.mkdir(parents=True, exist_ok=True)
        if compiler is not None:
            self.compiler = compiler
        elif PantherCompilerIntegrationFramework is not None:
            self.compiler = PantherCompilerIntegrationFramework()
        else:
            self.compiler = None

    @staticmethod
    def sha256_text(text: str) -> str:
        return hashlib.sha256(text.encode("utf-8")).hexdigest()

    @staticmethod
    def sha256_file(path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as fh:
            for chunk in iter(lambda: fh.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def _load_state(self) -> Dict[str, Any]:
        if not self.state_path.exists():
            return {"version": self.version, "sources": {}, "artifacts": {}}
        try:
            data = json.loads(self.state_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise IncrementalBuildError(f"Corrupt incremental cache: {self.state_path}") from exc
        if not isinstance(data, dict):
            raise IncrementalBuildError("Invalid incremental cache format")
        data.setdefault("sources", {})
        data.setdefault("artifacts", {})
        return data

    def _save_state(self, state: Dict[str, Any]) -> None:
        tmp = self.state_path.with_suffix(".tmp")
        tmp.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")
        tmp.replace(self.state_path)

    def discover_sources(self, workspace: str | Path) -> List[Path]:
        root = Path(workspace)
        if not root.exists():
            raise IncrementalBuildError(f"Workspace does not exist: {root}")
        if root.is_file():
            if root.suffix != ".panther":
                raise IncrementalBuildError("Incremental compiler accepts .panther files only")
            return [root]
        sources = sorted(p for p in root.rglob("*.panther") if p.is_file())
        if not sources:
            raise IncrementalBuildError(f"No .panther sources found in workspace: {root}")
        return sources

    def fingerprint_sources(self, workspace: str | Path) -> Dict[str, SourceUnit]:
        root = Path(workspace)
        sources = self.discover_sources(root)
        units: Dict[str, SourceUnit] = {}
        base = root if root.is_dir() else root.parent
        for path in sources:
            stat = path.stat()
            rel = str(path.relative_to(base) if path.is_relative_to(base) else path)
            units[rel] = SourceUnit(
                path=rel,
                sha256=self.sha256_file(path),
                size_bytes=stat.st_size,
                mtime_ns=stat.st_mtime_ns,
            )
        return units

    def plan(self, workspace: str | Path) -> IncrementalBuildPlan:
        state = self._load_state()
        current = self.fingerprint_sources(workspace)
        previous = state.get("sources", {})
        changed = sorted(k for k, unit in current.items() if previous.get(k, {}).get("sha256") != unit.sha256)
        unchanged = sorted(k for k, unit in current.items() if previous.get(k, {}).get("sha256") == unit.sha256)
        removed = sorted(k for k in previous.keys() if k not in current)
        total = len(current)
        hit_ratio = (len(unchanged) / total) if total else 0.0
        return IncrementalBuildPlan(changed, unchanged, removed, total, round(hit_ratio, 4))

    def _compile_unit(self, absolute_path: Path, rel_path: str) -> str:
        source = absolute_path.read_text(encoding="utf-8")
        if not source.strip():
            raise IncrementalBuildError(f"Empty Panther source: {rel_path}")
        if "panic_incremental_compiler" in source:
            raise IncrementalBuildError(f"Blocked incremental marker detected in {rel_path}")
        artifact_name = self.sha256_text(rel_path)[:16] + ".artifact.json"
        artifact_path = self.artifact_dir / artifact_name
        if self.compiler is not None:
            report = self.compiler.compile_source(source)
            payload: Dict[str, Any] = {
                "source": rel_path,
                "phase": self.phase,
                "compiler_report": report.to_dict() if hasattr(report, "to_dict") else str(report),
                "compiled_at": time.time(),
            }
        else:
            payload = {
                "source": rel_path,
                "phase": self.phase,
                "source_sha256": self.sha256_text(source),
                "compiled_at": time.time(),
            }
        artifact_path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
        return str(artifact_path)

    def build(self, workspace: str | Path) -> IncrementalBuildResult:
        start = time.perf_counter()
        root = Path(workspace)
        base = root if root.is_dir() else root.parent
        current = self.fingerprint_sources(root)
        build_plan = self.plan(root)
        state = self._load_state()
        artifacts: Dict[str, str] = dict(state.get("artifacts", {}))
        compiled: List[str] = []
        diagnostics: List[str] = []

        for removed in build_plan.removed:
            artifacts.pop(removed, None)
            diagnostics.append(f"removed:{removed}")

        for rel in build_plan.changed:
            absolute = (base / rel).resolve()
            artifacts[rel] = self._compile_unit(absolute, rel)
            compiled.append(rel)

        state = {
            "version": self.version,
            "phase": self.phase,
            "workspace": str(root),
            "sources": {k: asdict(v) for k, v in current.items()},
            "artifacts": artifacts,
            "last_build_unix": time.time(),
        }
        self._save_state(state)
        duration_ms = (time.perf_counter() - start) * 1000
        return IncrementalBuildResult(
            ok=True,
            phase=self.phase,
            version=self.version,
            workspace=str(root),
            plan=build_plan,
            compiled=compiled,
            reused=build_plan.unchanged,
            removed=build_plan.removed,
            artifacts=artifacts,
            duration_ms=round(duration_ms, 3),
            cache_path=str(self.state_path),
            diagnostics=diagnostics,
        )

    def clean(self) -> None:
        if self.state_path.exists():
            self.state_path.unlink()
        for artifact in self.artifact_dir.glob("*.artifact.json"):
            artifact.unlink()
PY

cat > examples/compiler/phase6_2_alpha.panther <<'EOF'
app PhaseSixTwoAlpha {
  version "0.6.2"
}

model AlphaUser {
  id: int required
  email: string required
}
EOF

cat > examples/compiler/phase6_2_beta.panther <<'EOF'
agent IncrementalAgent {
  purpose "Compile only changed Panther sources"
  memory local
  tools compiler, cache
}
EOF

cat > scripts/run_phase6_2_practical_demo.sh <<'SH2'
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
SH2
chmod +x scripts/run_phase6_2_practical_demo.sh

cat > tests/phase6_2/test_incremental_compilation.py <<'PY'
from __future__ import annotations
from pathlib import Path
import json
import pytest
from language.compiler.incremental import IncrementalBuildError, IncrementalCompiler

ALPHA = '''
app Alpha { version "0.6.2" }
model User { id: int required name: string }
'''
BETA = '''
agent Worker { purpose "Incremental test" memory local tools compiler }
'''

def write_workspace(tmp_path: Path) -> Path:
    ws = tmp_path / "ws"
    ws.mkdir()
    (ws / "alpha.panther").write_text(ALPHA, encoding="utf-8")
    (ws / "beta.panther").write_text(BETA, encoding="utf-8")
    return ws

def test_first_build_compiles_all_sources(tmp_path: Path):
    ws = write_workspace(tmp_path)
    result = IncrementalCompiler(cache_dir=tmp_path / "cache").build(ws)
    assert result.ok is True
    assert result.phase == "6.2"
    assert result.version == "0.6.2-incremental-compilation"
    assert sorted(result.compiled) == ["alpha.panther", "beta.panther"]
    assert result.reused == []
    assert result.external_api_used is False
    assert result.network_required is False


def test_second_build_reuses_unchanged_sources(tmp_path: Path):
    ws = write_workspace(tmp_path)
    compiler = IncrementalCompiler(cache_dir=tmp_path / "cache")
    compiler.build(ws)
    second = compiler.build(ws)
    assert second.compiled == []
    assert sorted(second.reused) == ["alpha.panther", "beta.panther"]
    assert second.plan.cache_hit_ratio == 1.0


def test_edit_rebuilds_only_changed_file(tmp_path: Path):
    ws = write_workspace(tmp_path)
    compiler = IncrementalCompiler(cache_dir=tmp_path / "cache")
    compiler.build(ws)
    (ws / "beta.panther").write_text(BETA + "\nmodel Extra { id: int required }\n", encoding="utf-8")
    result = compiler.build(ws)
    assert result.compiled == ["beta.panther"]
    assert result.reused == ["alpha.panther"]


def test_removed_file_is_recorded(tmp_path: Path):
    ws = write_workspace(tmp_path)
    compiler = IncrementalCompiler(cache_dir=tmp_path / "cache")
    compiler.build(ws)
    (ws / "alpha.panther").unlink()
    result = compiler.build(ws)
    assert result.removed == ["alpha.panther"]
    assert "alpha.panther" not in result.artifacts


def test_negative_missing_workspace(tmp_path: Path):
    with pytest.raises(IncrementalBuildError):
        IncrementalCompiler(cache_dir=tmp_path / "cache").build(tmp_path / "missing")


def test_negative_empty_source(tmp_path: Path):
    ws = tmp_path / "ws"
    ws.mkdir()
    (ws / "empty.panther").write_text("   \n", encoding="utf-8")
    with pytest.raises(IncrementalBuildError):
        IncrementalCompiler(cache_dir=tmp_path / "cache").build(ws)


def test_negative_blocked_marker(tmp_path: Path):
    ws = tmp_path / "ws"
    ws.mkdir()
    (ws / "bad.panther").write_text("panic_incremental_compiler", encoding="utf-8")
    with pytest.raises(IncrementalBuildError):
        IncrementalCompiler(cache_dir=tmp_path / "cache").build(ws)


def test_report_json_serializable(tmp_path: Path):
    ws = write_workspace(tmp_path)
    result = IncrementalCompiler(cache_dir=tmp_path / "cache").build(ws)
    data = json.loads(result.to_json())
    assert data["ok"] is True
    assert data["plan"]["total_sources"] == 2


def test_stress_many_files_incremental(tmp_path: Path):
    ws = tmp_path / "stress"
    ws.mkdir()
    for i in range(75):
        (ws / f"m{i}.panther").write_text(f"model M{i} {{ id: int required }}\n", encoding="utf-8")
    compiler = IncrementalCompiler(cache_dir=tmp_path / "cache")
    first = compiler.build(ws)
    second = compiler.build(ws)
    assert len(first.compiled) == 75
    assert second.compiled == []
    assert len(second.reused) == 75
PY

cat > scripts/verify_phase6_2_incremental_compilation.sh <<'SH2'
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
SH2
chmod +x scripts/verify_phase6_2_incremental_compilation.sh

cat > docs/phase6/PHASE_6_2_INCREMENTAL_COMPILATION.md <<'MD'
# PantherLang Phase 6.2 — Incremental Compilation

## Status
Completed by bootstrap when verification passes.

## Objective
Phase 6.2 introduces a deterministic incremental compilation layer for PantherLang. It detects changed, unchanged, and removed `.panther` source units and recompiles only the changed units while reusing unchanged artifacts.

## Delivered Components
- `language/compiler/incremental/incremental_compiler.py`
- `IncrementalCompiler`
- `IncrementalBuildPlan`
- `IncrementalBuildResult`
- Persistent JSON cache under `build/incremental_cache`
- Practical demo script
- Regression, negative, and stress tests

## Engineering Guarantees
- Fully local execution
- No network requirement
- No external API calls
- Deterministic SHA-256 source fingerprints
- Corrupt-cache detection
- Removed-file detection
- JSON build reports

## Verification
Run:

```bash
bash scripts/verify_phase6_2_incremental_compilation.sh
```

Run demo:

```bash
bash scripts/run_phase6_2_practical_demo.sh
```

## GitHub Policy
For the current Phase 6 workflow, GitHub push is intentionally postponed until Phase 6.10 is complete and full Phase 6 regression has passed.
MD

cat > build/reports/phase6_2_manifest.json <<'JSON'
{
  "project": "PantherLang",
  "phase": "6.2",
  "name": "Incremental Compilation",
  "version": "0.6.2-incremental-compilation",
  "external_api_used": false,
  "network_required": false,
  "github_push_policy": "postponed_until_phase_6_10_full_regression"
}
JSON

python - <<'PY'
from pathlib import Path
entry = """
## Phase 6.2 — Incremental Compilation

- Added deterministic incremental compiler cache.
- Added changed/unchanged/removed source planning.
- Added Panther source fingerprinting with SHA-256.
- Added per-source artifact reuse.
- Added practical demo, regression tests, negative tests, and stress tests.
- GitHub push is postponed until Phase 6.10 full regression.
"""
path = Path("CHANGELOG.md")
text = path.read_text(encoding="utf-8") if path.exists() else "# PantherLang Changelog\n"
if "Phase 6.2 — Incremental Compilation" not in text:
    path.write_text(text.rstrip() + "\n\n" + entry.strip() + "\n", encoding="utf-8")

vp = Path("VERSION_PLAN.md")
vt = vp.read_text(encoding="utf-8") if vp.exists() else "# PantherLang Version Plan\n"
marker = "- [x] Phase 6.2 — Incremental Compilation"
if marker not in vt:
    vp.write_text(vt.rstrip() + "\n" + marker + "\n", encoding="utf-8")
PY

bash scripts/verify_phase6_2_incremental_compilation.sh

printf '\n✅ PantherLang Phase 6.2 installed and verified successfully.\n'
printf 'Next commands:\n'
printf '  bash scripts/run_phase6_2_practical_demo.sh\n'
printf '  bash scripts/verify_phase6_2_incremental_compilation.sh\n'
printf 'GitHub push remains postponed until Phase 6.10 full regression.\n'
printf '============================================================\n'
