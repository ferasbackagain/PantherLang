from dataclasses import dataclass

@dataclass(frozen=True)
class TargetTriple:
    arch: str
    vendor: str
    os: str
    abi: str = "gnu"

    @property
    def triple(self) -> str:
        return f"{self.arch}-{self.vendor}-{self.os}-{self.abi}"

    @property
    def executable_suffix(self) -> str:
        return ".exe" if self.os == "windows" else ""

    @property
    def object_suffix(self) -> str:
        return ".obj" if self.os == "windows" else ".o"

    @property
    def library_prefix(self) -> str:
        return "" if self.os == "windows" else "lib"

    @property
    def shared_library_suffix(self) -> str:
        return {"linux": ".so", "darwin": ".dylib", "windows": ".dll"}.get(self.os, ".so")

TARGETS = {
    "linux-x86_64": TargetTriple("x86_64", "unknown", "linux", "gnu"),
    "linux-aarch64": TargetTriple("aarch64", "unknown", "linux", "gnu"),
    "macos-x86_64": TargetTriple("x86_64", "apple", "darwin", "none"),
    "macos-aarch64": TargetTriple("aarch64", "apple", "darwin", "none"),
    "windows-x86_64": TargetTriple("x86_64", "pc", "windows", "msvc"),
}

def parse_target(name: str) -> TargetTriple:
    if name in TARGETS:
        return TARGETS[name]
    for target in TARGETS.values():
        if name == target.triple:
            return target
    raise ValueError(f"Unsupported target: {name}")
