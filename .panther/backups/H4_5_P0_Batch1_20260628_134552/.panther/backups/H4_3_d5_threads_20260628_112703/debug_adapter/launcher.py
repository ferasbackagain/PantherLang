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
