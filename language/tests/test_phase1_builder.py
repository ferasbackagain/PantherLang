from pathlib import Path
import shutil
from language.tools.builder import PantherProjectBuilder

tmp = Path("tmp_panther_builder_test")
if tmp.exists():
    shutil.rmtree(tmp)
tmp.mkdir()

builder = PantherProjectBuilder(tmp)
project = builder.create_basic_app("PantherDemo")

assert project.exists()
assert (project / "README.md").exists()
assert (project / "panther.project.json").exists()
assert (project / "src" / "app.panther").exists()

content = (project / "src" / "app.panther").read_text()
assert "app PantherDemo" in content
assert "model Product" in content

shutil.rmtree(tmp)

print("✅ Phase 1.15 project builder tests passed.")
