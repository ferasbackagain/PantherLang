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

## Agent

```python
from compiler.ai.agents import Agent

agent = Agent("assistant")
agent.register_tool("get_weather", get_weather_fn)
response = agent.complete("What is the weather in Paris?")
```

## SecureAgent

```python
from compiler.ai.secure_agent import SecureAgent

agent = SecureAgent("assistant")
agent.complete(user_input)  # injection detection + output sanitization + audit
```

## RAG Engine

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
