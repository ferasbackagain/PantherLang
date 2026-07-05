# Chapter 11: AI Platform

## AI Providers

Five providers, all with mock fallback (no API keys required for testing):

| Provider | Model | Env Variable |
|----------|-------|-------------|
| OpenAI | GPT-4o, text-embedding-3-small | `OPENAI_API_KEY` |
| Anthropic | Claude Sonnet 4 | `ANTHROPIC_API_KEY` |
| Gemini | Gemini 2.0 Flash | `GEMINI_API_KEY` |
| Ollama | Llama 3, Mistral (local) | None |
| OpenRouter | Various models | `OPENROUTER_API_KEY` |

## AI Chat

`ai_chat(prompt, provider)` sends a prompt to an AI provider and returns the response.

```panther
panther main {
    let response = ai_chat("What is PantheLang?");
    print "AI: " + response;
}
```

By default, `ai_chat` uses the mock provider (offline, no API key required). Pass a
provider name for explicit selection:

```panther
panther main {
    let resp = ai_chat("Hello", "mock");
    print resp;
}
```

## AI Top-Level Block

The `ai {}` block is a top-level block that executes its body during program
execution, alongside `panther main {}`:

```panther
panther main {
    print "This runs in the main block.";
}

ai {
    print "This runs in the AI block.";
}
```

## AI Functions

| Function | Description |
|----------|-------------|
| `ai_chat(prompt[, provider])` | Chat with an AI provider (default: mock) |
| `ai_mock_chat(prompt)` | Quick mock chat (always offline) |
| `ai_supported_providers()` | List all supported provider names |
| `ai_provider_available(name)` | Check if a provider's env var is set |
| `ai_available_providers()` | List providers with env vars configured |

## Agent (Python API)

For advanced agent workflows, use the Python API:

```python
from compiler.ai.agents import Agent

agent = Agent("assistant")
agent.register_tool("get_weather", get_weather_fn)
response = agent.complete("What is the weather in Paris?")
```

## SecureAgent (Python API)

```python
from compiler.ai.secure_agent import SecureAgent

agent = SecureAgent("assistant")
agent.complete(user_input)  # injection detection + output sanitization + audit
```

## RAG Engine (Python API)

```python
from compiler.ai.rag import RAGEngine

engine = RAGEngine(provider=embedding_provider)
engine.add_document("PantherLang is a programming language.")
results = engine.query("What is PantherLang?", top_k=3)
```

## Security Rule

```panther
// API keys must come from environment variables, never source code
// Bad:  let key = "sk-..."
// Good: key = env("OPENAI_API_KEY")  // read at runtime
```
