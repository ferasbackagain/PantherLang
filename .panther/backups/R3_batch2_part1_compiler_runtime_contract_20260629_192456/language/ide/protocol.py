class PantherIDEProtocol:
    def diagnostics(self, source: str):
        if "???" in source:
            return [{"level": "error", "message": "Unknown syntax marker"}]
        return []

    def completions(self, prefix: str):
        keywords = ["app", "model", "api", "page", "agent", "workflow", "capabilities"]
        return [k for k in keywords if k.startswith(prefix)]

    def symbols(self, source: str):
        found = []
        for line in source.splitlines():
            clean = line.strip()
            if clean.startswith("model "):
                found.append({"kind": "model", "name": clean.split()[1]})
            if clean.startswith("app "):
                found.append({"kind": "app", "name": clean.split()[1]})
        return found
