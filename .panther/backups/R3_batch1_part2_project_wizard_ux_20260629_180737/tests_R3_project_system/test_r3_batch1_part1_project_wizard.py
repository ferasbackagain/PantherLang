from pathlib import Path
import json
import subprocess
import sys

from tools.project_wizard.wizard import available_templates, create_project


def test_available_templates():
    assert available_templates() == ["ai", "api", "console", "web"]


def test_create_console_project(tmp_path):
    result = create_project("hello-panther", "console", tmp_path)
    assert result.files_created >= 2
    project = tmp_path / "hello-panther"
    assert (project / "panther.toml").exists()
    assert (project / "src" / "main.panther").exists()
    assert "hello-panther" in (project / "panther.toml").read_text()
    assert "hello-panther" in (project / "src" / "main.panther").read_text()


def test_create_all_templates(tmp_path):
    for template in available_templates():
        result = create_project(f"demo-{template}", template, tmp_path)
        assert result.destination.exists()
        assert (result.destination / "panther.toml").exists()


def test_cli_json_output(tmp_path):
    proc = subprocess.run(
        [
            sys.executable,
            "tools/project_wizard/panther_new.py",
            "json-demo",
            "--template",
            "api",
            "--destination",
            str(tmp_path),
            "--json",
        ],
        text=True,
        capture_output=True,
        check=True,
    )
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["name"] == "json-demo"
    assert data["template"] == "api"
    assert Path(data["destination"]).exists()
