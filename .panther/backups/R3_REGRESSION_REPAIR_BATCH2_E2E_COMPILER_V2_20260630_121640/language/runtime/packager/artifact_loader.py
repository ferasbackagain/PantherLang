import json
from pathlib import Path


class PantherArtifactLoader:
    def load(self, path):
        return json.loads(Path(path).read_text())
