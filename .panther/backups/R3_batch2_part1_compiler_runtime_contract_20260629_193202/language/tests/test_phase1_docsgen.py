from pathlib import Path
from language.tools.docsgen import PantherDocGenerator

gen = PantherDocGenerator(".")
output = gen.write_generated_docs()

assert output.exists()
text = output.read_text()
assert "PantherLang Generated Documentation" in text
assert "Language Specification" in text

print("✅ Phase 1.13 documentation generator tests passed.")
