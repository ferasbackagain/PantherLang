from language.runtime.vm import PantherRuntimePipeline


class PantherRuntimeCLI:
    def run_source(self, source):
        result = PantherRuntimePipeline().execute_source(source)
        return f"Executed {result['app']} with models: {', '.join(result['models'])}"

    def doctor(self):
        return "Panther Runtime CLI OK"
