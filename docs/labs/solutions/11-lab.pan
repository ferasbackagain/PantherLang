panther main {
    print "=== Lab 11: AI Platform ===";

    print "--- Exercise 1: List Providers ---";
    let providers = ai_supported_providers();
    print "Supported providers: " + join(", ", providers);
    print "Provider count: " + string(len(providers));

    print "--- Exercise 2: Check Availability ---";
    let openai_avail = ai_provider_available("openai");
    let ollama_avail = ai_provider_available("ollama");
    print "OpenAI available: " + string(openai_avail);
    print "Ollama available: " + string(ollama_avail);

    print "--- Exercise 3: Mock Chat ---";
    let response = ai_mock_chat("What is PantherLang?");
    print "AI response: " + response;

    print "--- Security Note ---";
    print "Never hardcode API keys in source code.";
    print "Always read secrets from environment variables at runtime.";
}
