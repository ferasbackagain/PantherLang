from dataclasses import dataclass, field

@dataclass
class SandboxPolicy:
    allow_network: bool=False
    allow_filesystem: bool=False
    allow_plugins: bool=True

@dataclass
class SandboxRuntime:
    policy: SandboxPolicy = field(default_factory=SandboxPolicy)

    def execute(self, command:str):
        if not command.strip():
            raise ValueError("empty command")
        return {
            "ok": True,
            "command": command,
            "network": self.policy.allow_network,
            "filesystem": self.policy.allow_filesystem,
            "plugins": self.policy.allow_plugins,
            "sandbox": "secure"
        }
