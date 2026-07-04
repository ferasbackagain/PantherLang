panther main {
    print "AI Providers: OpenAI, Anthropic, Gemini, Ollama, OpenRouter";
    print "Mock mode: Active (no API keys required for demo)";
    fn get_provider_info(name) {
        if name == "openai" {
            return "OpenAI: gpt-4o";
        }
        if name == "ollama" {
            return "Ollama: llama3";
        }
        return "Unknown: " + name;
    }
    print get_provider_info("openai");
    print get_provider_info("ollama");
}
