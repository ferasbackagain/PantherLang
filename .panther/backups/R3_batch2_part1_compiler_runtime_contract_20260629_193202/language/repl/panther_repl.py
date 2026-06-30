class PantherREPL:
    def evaluate(self, command: str):
        command = command.strip()

        if command in ("help", "?"):
            return "Panther REPL commands: help, version, exit"

        if command == "version":
            return "PantherLang Developer Preview v0.5"

        if command == "exit":
            return "exit"

        return f"echo: {command}"
