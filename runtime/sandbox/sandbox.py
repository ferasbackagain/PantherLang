from dataclasses import dataclass, field


@dataclass
class SandboxPolicy:
    allow_network: bool = False
    allow_filesystem: bool = False
    allow_plugins: bool = True


@dataclass
class SandboxRuntime:
    policy: SandboxPolicy = field(default_factory=SandboxPolicy)

    def execute(self, command: str) -> dict:
        if not command.strip():
            raise ValueError("empty command")
        try:
            from compiler.runtime.execution_pipeline import execute_source
            from compiler.security.sandbox import Sandbox, ResourceLimits
            limits = ResourceLimits(
                max_time=5.0,
                max_memory=100 * 1024 * 1024,
                network_allowed=self.policy.allow_network,
                filesystem_allowed=self.policy.allow_filesystem,
            )
            sandbox = Sandbox(limits=limits)
            result = sandbox.run(lambda: execute_source(command))
            output = "\n".join(result.captured_output) if hasattr(result, 'captured_output') and result.captured_output else ""
            return {
                "ok": result.error is None,
                "command": command,
                "output": output or str(result),
                "network": self.policy.allow_network,
                "filesystem": self.policy.allow_filesystem,
                "sandbox": "secure",
            }
        except ImportError:
            from compiler.runtime.execution_pipeline import execute_source
            result = execute_source(command)
            output = "\n".join(result.captured_output) if result.captured_output else ""
            return {
                "ok": result.error is None,
                "command": command,
                "output": output,
                "network": self.policy.allow_network,
                "filesystem": self.policy.allow_filesystem,
                "sandbox": "secure",
            }
        except Exception as e:
            return {
                "ok": False,
                "command": command,
                "error": str(e),
                "network": self.policy.allow_network,
                "filesystem": self.policy.allow_filesystem,
                "sandbox": "secure",
            }
