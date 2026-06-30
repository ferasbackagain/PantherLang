from pathlib import Path
import json
def test_version():
    pkg=json.loads(Path("vscode-extension/package.json").read_text())
    assert pkg["version"]>="1.0.4"
def test_run_module():
    t=Path("vscode-extension/src/run_command.js").read_text()
    assert "panther run" in t
