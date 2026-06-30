import os
import subprocess
from dataclasses import dataclass
from typing import Optional


@dataclass
class LaunchResult:
    command: list[str]
    cwd: Optional[str]
    pid: Optional[int]
    started: bool


class PantherProgramLauncher:
    """Production PantherLang program launcher.

    The modern launcher keeps process startup behind a dry_run gate so tests and
    IDE smoke checks can verify DAP launch behavior without spawning Panther.
    """

    def build_command(self, program, args=None):
        args = list(args or [])
        if not program:
            raise ValueError("launch requires a program path")
        return ["Panther", "run", program, *args]

    def launch(self, program, args=None, cwd=None, dry_run=True):
        command = self.build_command(program, args)
        if dry_run:
            return LaunchResult(command=command, cwd=cwd, pid=None, started=False)

        process = subprocess.Popen(
            command,
            cwd=cwd or os.getcwd(),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return LaunchResult(command=command, cwd=cwd, pid=process.pid, started=True)


class Launcher(PantherProgramLauncher):
    """Legacy compatibility alias for older DAP tests/imports.

    Historical modules import ``debug_adapter.launcher.Launcher`` while the
    current production implementation is named ``PantherProgramLauncher``.
    Keeping this subclass preserves both public contracts without duplicating
    behavior.
    """

    pass


# Lowercase alias kept for old scripts that treated launcher as a factory name.
launcher = Launcher

__all__ = ["LaunchResult", "PantherProgramLauncher", "Launcher", "launcher"]
