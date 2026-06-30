class PantherFormatter:
    def format(self, source: str) -> str:
        lines = source.splitlines()
        output = []
        indent = 0

        for raw in lines:
            stripped = raw.strip()

            if not stripped:
                if output and output[-1] != "":
                    output.append("")
                continue

            if stripped.startswith("}"):
                indent = max(indent - 1, 0)

            output.append(("    " * indent) + stripped)

            if stripped.endswith("{"):
                indent += 1

        while output and output[-1] == "":
            output.pop()

        return "\n".join(output) + "\n"


def format_panther(source: str) -> str:
    return PantherFormatter().format(source)
