import re
from language.compiler.ast import ASTApp


class AppParser:

    def parse(self, source):

        m = re.search(
            r"app\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{([\s\S]*?)\}",
            source,
        )

        if not m:
            return None

        name = m.group(1)
        body = m.group(2)

        version = "0.5"

        vm = re.search(
            r'version\s+"([^"]+)"',
            body,
        )

        if vm:
            version = vm.group(1)

        return ASTApp(
            name=name,
            version=version,
        )
