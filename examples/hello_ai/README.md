# Hello AI Example

Demonstrates PantherLang AI-native direction.

**Security rules:**
- API keys from environment variables only (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.)
- No hardcoded secrets
- Prompt injection detection available via `SecureAgent`
- Mock mode active when API keys are absent

## Run

```bash
panther run examples/hello_ai/main.pan
```

## Provider Support

| Provider | SDK | Env Variable |
|----------|-----|-------------|
| OpenAI | `openai` | `OPENAI_API_KEY` |
| Anthropic | `anthropic` | `ANTHROPIC_API_KEY` |
| Gemini | `google-generativeai` | `GEMINI_API_KEY` |
| Ollama | `requests` (local) | None (local) |
| OpenRouter | `requests` | `OPENROUTER_API_KEY` |
