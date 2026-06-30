from pathlib import Path
import json


def test_agent_knowledge_pack_exists():
    base = Path("docs/agent_knowledge")
    assert (base / "PANTHERLANG_AGENT_GUIDE.md").exists()
    assert (base / "PANTHERLANG_GRAMMAR_QUICK_REFERENCE.md").exists()
    assert (base / "PANTHERLANG_PROJECT_CONVENTIONS.md").exists()
    assert (base / "PANTHERLANG_AGENT_PROMPTS.md").exists()


def test_copilot_instructions_exist():
    text = Path(".github/copilot/instructions.md").read_text()
    assert "PantherLang" in text
    assert "panther.toml" in text


def test_examples_exist():
    for kind in ["console", "web", "api", "ai"]:
        p = Path("docs/examples") / kind / "main.panther"
        assert p.exists()
        assert "panther" in p.read_text()


def test_vscode_agent_command_registered():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}
    assert "pantherlang.openAgentGuide" in commands
    assert pkg["version"] >= "1.0.7"
    assert "ai-agent" in pkg.get("keywords", [])


def test_agent_command_implementation():
    text = Path("vscode-extension/src/agent_command.js").read_text()
    assert "PANTHERLANG_AGENT_GUIDE.md" in text
    assert "showTextDocument" in text
