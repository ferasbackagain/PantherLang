from dataclasses import dataclass

@dataclass
class LaunchResult:
    started: bool
    pid: int | None
    command: list[str]

class PantherProgramLauncher:
    def launch(self, program, args=None, dry_run=False):
        return LaunchResult(not dry_run, None, ["Panther", "run", program] + list(args or []))
