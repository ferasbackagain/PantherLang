panther main {
    print "PantherLang AI Template";
    print "AI Providers: OpenAI, Anthropic, Gemini, Ollama, OpenRouter";
    print "Security: Prompt injection detection enabled";
    print "Mock mode: Active (no API keys required for demo)";

    fn get_provider_info(name) {
        if name == "openai" {
            return "OpenAI: gpt-4o, gpt-4-turbo, text-embedding-3-small";
        }
        if name == "anthropic" {
            return "Anthropic: claude-sonnet-4, claude-3-haiku";
        }
        if name == "ollama" {
            return "Ollama: llama3, mistral (local, no API key needed)";
        }
        return "Unknown provider: " + name;
    }

    print get_provider_info("openai");
    print get_provider_info("anthropic");
    print get_provider_info("ollama");

    print "API keys are read from environment variables only.";
    print "Never hardcode secrets in source code.";
}
