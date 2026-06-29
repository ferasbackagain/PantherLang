#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def run(cmd: list[str], cwd: Path | None = None) -> tuple[int, str, str]:
    proc = subprocess.run(cmd, cwd=cwd or ROOT, text=True, capture_output=True)
    return proc.returncode, proc.stdout, proc.stderr


def assert_ok(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def test_cli_core() -> dict:
    code, out, err = run([str(ROOT / "panther"), "doctor"])
    assert_ok(code == 0, "Panther doctor failed")
    assert_ok("PantherLang doctor: OK" in out, "doctor output missing")
    return {"name": "cli_core", "ok": True}


def test_project_workflow() -> dict:
    with tempfile.TemporaryDirectory() as tmp:
        tmpdir = Path(tmp)
        code, out, err = run([str(ROOT / "panther"), "new", "console", "EnterpriseApp"], cwd=tmpdir)
        assert_ok(code == 0, "Panther new failed")
        app = tmpdir / "EnterpriseApp"
        assert_ok((app / "src" / "main.panther").exists(), "main.panther missing")

        for cmd in [
            [str(ROOT / "panther"), "check"],
            [str(ROOT / "panther"), "run"],
            [str(ROOT / "panther"), "build", "--release"],
        ]:
            code, out, err = run(cmd, cwd=app)
            assert_ok(code == 0, f"{cmd} failed: {out} {err}")

        assert_ok((app / "build" / "release" / "main.sh").exists(), "release artifact missing")
    return {"name": "project_workflow", "ok": True}


def test_registry_cycle() -> dict:
    with tempfile.TemporaryDirectory() as tmp:
        pkg = Path(tmp) / "pkg"
        pkg.mkdir()
        (pkg / "package.panther").write_text('print "registry package"\n', encoding="utf-8")

        code, out, err = run([str(ROOT / "panther"), "registry", "init"])
        assert_ok(code == 0, "registry init failed")

        code, out, err = run([
            str(ROOT / "panther"), "registry", "publish", str(pkg),
            "--name", "enterprise.test",
            "--version", "1.0.0",
            "--description", "enterprise validation package",
        ])
        assert_ok(code == 0, "registry publish failed")

        code, out, err = run([str(ROOT / "panther"), "registry", "search", "enterprise"])
        assert_ok(code == 0 and "enterprise.test@1.0.0" in out, "registry search failed")
    return {"name": "registry_cycle", "ok": True}


def test_release_cycle() -> dict:
    with tempfile.TemporaryDirectory() as tmp:
        out_dir = Path(tmp) / "release"
        code, out, err = run([
            str(ROOT / "panther"), "release", "create",
            "--version", "1.0.0-H1",
            "--channel", "hardening",
            "--out-dir", str(out_dir),
        ])
        assert_ok(code == 0, "release create failed")
        assert_ok((Path(tmp) / "release.tar.gz").exists(), "release archive missing")
    return {"name": "release_cycle", "ok": True}


def main() -> int:
    tests = [
        test_cli_core,
        test_project_workflow,
        test_registry_cycle,
        test_release_cycle,
    ]
    results = []
    for test in tests:
        results.append(test())

    report = {
        "ok": all(item["ok"] for item in results),
        "stage": "H1",
        "suite": "enterprise",
        "tests": results,
        "total": len(results),
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
