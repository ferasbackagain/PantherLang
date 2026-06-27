from dataclasses import dataclass
from .targets import TargetTriple, parse_target

@dataclass(frozen=True)
class ToolchainPlan:
    target: TargetTriple
    linker: str
    archiver: str
    runner: str
    sysroot_required: bool

class ToolchainResolver:
    def resolve(self, target_name: str) -> ToolchainPlan:
        target = parse_target(target_name)
        if target.os == "windows":
            return ToolchainPlan(target, "lld-link", "llvm-lib", "wine", True)
        if target.os == "darwin":
            return ToolchainPlan(target, "ld64.lld", "llvm-ar", "native-or-cross-runner", True)
        return ToolchainPlan(target, "ld.lld", "llvm-ar", "native", False)

    def artifact_name(self, basename: str, target_name: str) -> str:
        target = parse_target(target_name)
        return f"{basename}-{target.triple}{target.executable_suffix}"
