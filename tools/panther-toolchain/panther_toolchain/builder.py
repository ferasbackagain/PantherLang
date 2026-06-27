from dataclasses import dataclass, asdict
from pathlib import Path
from .resolver import ToolchainResolver

@dataclass
class BuildArtifact:
    source: str
    target: str
    object_file: str
    executable: str
    linker: str
    status: str

class CrossPlatformBuilder:
    def __init__(self, build_dir: str = "build/cross"):
        self.build_dir = Path(build_dir)
        self.resolver = ToolchainResolver()

    def plan(self, source: str, target_name: str) -> BuildArtifact:
        plan = self.resolver.resolve(target_name)
        stem = Path(source).stem
        target_dir = self.build_dir / plan.target.triple
        obj = target_dir / f"{stem}{plan.target.object_suffix}"
        exe = target_dir / self.resolver.artifact_name(stem, target_name)
        return BuildArtifact(source, plan.target.triple, str(obj), str(exe), plan.linker, "planned")

    def emit_manifest(self, source: str, targets: list[str]) -> dict:
        artifacts = [asdict(self.plan(source, target)) for target in targets]
        return {"phase": "6.9", "source": source, "artifacts": artifacts, "status": "ok"}
