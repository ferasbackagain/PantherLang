import json
from pathlib import Path


class PantherExecutablePackager:
    def package(self, name, runtime_program, output_dir="language/runtime/artifacts"):
        out = Path(output_dir)
        out.mkdir(parents=True, exist_ok=True)
        manifest = {
            "name": name,
            "type": "panther-executable-package",
            "runtime": "PantherRuntime",
            "runtime_program": runtime_program,
        }
        path = out / f"{name}.pantherpkg.json"
        path.write_text(json.dumps(manifest, indent=2) + "\n")
        return path
