from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_production_manifest() -> None:
    manifest = json.loads((ROOT / "production" / "production_manifest.json").read_text())
    assert manifest["phase"] == "6.20"
    assert manifest["status"] == "phase-6-production-ready"
    assert "runtime_bridge" in manifest["capabilities"]
    assert manifest["external_api_required"] is False


def test_production_demo_compile_and_run(tmp_path: Path) -> None:
    out = tmp_path / "production.sh"
    proc = subprocess.run(
        [str(ROOT / "panther"), "compile", "examples/phase6_production/production_demo.panther", "--out", str(out)],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    data = json.loads(proc.stdout)
    assert data["ok"] is True

    run = subprocess.run([str(out)], text=True, capture_output=True)
    assert run.returncode == 0
    assert "Production readiness demo" in run.stdout
    assert "Phase 6.20 production readiness" in run.stdout
