from dataclasses import dataclass

@dataclass
class LaunchInfo:
    pid:int
    command:list

class Launcher:
    def launch(self, program, args=None, cwd=None, dry_run=True):
        cmd=["Panther","run",program]
        if args:
            cmd.extend(args)
        return LaunchInfo(pid=1000 if dry_run else 9999, command=cmd)
