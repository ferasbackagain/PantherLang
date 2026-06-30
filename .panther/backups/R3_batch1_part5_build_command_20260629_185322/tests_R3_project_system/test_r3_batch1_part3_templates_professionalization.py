from pathlib import Path

from tools.project_wizard.wizard import available_templates, create_project


def test_all_templates_have_professional_files():
    mapping = {
        "console": "console_app",
        "web": "web_app",
        "api": "api_app",
        "ai": "ai_app",
    }
    for template_id, folder in mapping.items():
        root = Path("project_templates") / folder
        assert (root / "README.md").exists()
        assert (root / ".gitignore").exists()
        assert (root / ".vscode" / "settings.json").exists()
        assert (root / ".vscode" / "tasks.json").exists()
        assert (root / ".vscode" / "launch.json").exists()
        assert (root / "docs" / "PROJECT_GUIDE.md").exists()
        assert any((root / "tests").glob("*.panther"))
        assert "[tooling]" in (root / "panther.toml").read_text()


def test_generated_projects_include_professional_files(tmp_path):
    for template in available_templates():
        result = create_project(f"pro-{template}", template, tmp_path)
        project = result.destination
        assert (project / "README.md").exists()
        assert (project / ".gitignore").exists()
        assert (project / ".vscode" / "tasks.json").exists()
        assert (project / ".vscode" / "launch.json").exists()
        assert (project / "docs" / "PROJECT_GUIDE.md").exists()
        assert (project / "panther.toml").exists()
        assert f"pro-{template}" in (project / "README.md").read_text()
