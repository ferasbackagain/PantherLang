from __future__ import annotations
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_final_runtime_integration() -> None:
    from runtime.final_integration.final_runtime import PantherFinalRuntime
    rt = PantherFinalRuntime()
    report = rt.run_full_integration()
    assert report.ok is True
    assert report.scheduler_tasks == 1
    assert report.messages == 1
    assert report.context_ok is True
    assert report.plugins == 2
    assert report.sandbox_ok is True
    assert report.distributed_nodes == 2


def test_final_panther_run() -> None:
    proc = subprocess.run(
        [str(ROOT / "panther"), "run", "examples/phase7_final/final_runtime_demo.panther"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    assert "Phase 7.10 Final Runtime Integration" in proc.stdout
    assert "Phase 7 complete" in proc.stdout
