panther main {
    print "=== Lesson 11: AI Platform ===";
    print "";
    
    print "--- AI Providers ---";
    print "Five providers with mock fallback (no API keys required for testing):";
    print "";
    let all = ai_supported_providers();
    for i in 0..len(all)-1 {
        let p = all[i];
        let avail = ai_provider_available(p);
        if avail {
            print p + ": READY (env var set)";
        } else {
            print p + ": MOCK (set env var for real calls)";
        }
    }
    print "";
    
    print "--- AI Chat ---";
    print "ai_chat() uses mock provider by default (no API key needed):";
    let response = ai_chat("What is the capital of France?");
    print "AI says: " + response;
    print "";
    
    print "--- Provider Selection ---";
    print "Pass provider name to ai_chat for explicit selection:";
    let resp = ai_chat("Hello!", "mock");
    print resp;
    print "";
    
    print "--- Available Providers ---";
    let ready = ai_available_providers();
    if len(ready) == 0 {
        print "No providers available (no env vars set). Mock mode active.";
    } else {
        for i in 0..len(ready)-1 {
            print "Available: " + ready[i];
        }
    }
    print "";
    
    print "--- Security Rule ---";
    print "// API keys must come from environment variables, never source code";
    print "// Bad:  let key = \"sk-...\"";
    print "// Good: key = env(\"OPENAI_API_KEY\")  // read at runtime";
    print "";
    
    print "=== Lesson 11 Complete ===";
}