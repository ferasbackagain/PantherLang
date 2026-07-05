panther main {
    print "PantherLang AI Template";
    print "AI Providers: OpenAI, Anthropic, Gemini, Ollama, OpenRouter";
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

    print "";
    print "--- AI Chat Demo (mock mode) ---";
    let response = ai_chat("What is PantherLang?");
    print "AI: " + response;

    print "";
    print "--- AI Block Demo ---";
    print "ai {} is a top-level block. ai_chat() works from any block.";

    print "";
    print "--- Available Providers ---";
    let ready = ai_available_providers();
    if len(ready) == 0 {
        print "No API keys configured. Using mock mode.";
    } else {
        for i in 0..len(ready)-1 {
            print "Ready: " + ready[i];
        }
    }

    print "";
    print "API keys are read from environment variables only.";
    print "Never hardcode secrets in source code.";
}
