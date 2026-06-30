from pathlib import Path


class PantherDocGenerator:
    def __init__(self, root="."):
        self.root = Path(root)

    def read_if_exists(self, path):
        p = self.root / path
        if p.exists():
            return p.read_text()
        return ""

    def generate_summary(self):
        spec = self.read_if_exists("architecture/specification/PANTHER_LANGUAGE_SPECIFICATION_v1_8.md")
        stdlib = self.read_if_exists("docs/STANDARD_LIBRARY.md")
        cli = self.read_if_exists("docs/CLI.md")
        formatter = self.read_if_exists("docs/FORMATTER.md")

        sections = [
            "# PantherLang Generated Documentation",
            "",
            "## Source Documents",
            "- Language Specification",
            "- Standard Library",
            "- CLI",
            "- Formatter",
            "",
            "## Language Specification Snapshot",
            self._first_lines(spec, 30),
            "",
            "## Standard Library Snapshot",
            self._first_lines(stdlib, 20),
            "",
            "## CLI Snapshot",
            self._first_lines(cli, 20),
            "",
            "## Formatter Snapshot",
            self._first_lines(formatter, 20),
            "",
        ]

        return "\\n".join(sections)

    def _first_lines(self, text, count):
        lines = text.splitlines()
        return "\\n".join(lines[:count]) if lines else "_Not available yet._"

    def write_generated_docs(self):
        output_dir = self.root / "docs" / "generated"
        output_dir.mkdir(parents=True, exist_ok=True)
        output_file = output_dir / "PANTHERLANG_GENERATED_DOCS.md"
        output_file.write_text(self.generate_summary() + "\\n")
        return output_file
