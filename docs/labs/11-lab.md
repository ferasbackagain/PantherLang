# Lab 11: AI Platform

## Objectives
- List supported AI providers with `ai_supported_providers`
- Check provider availability with `ai_provider_available`
- Simulate AI chat with `ai_mock_chat`
- Understand SecureAgent and prompt injection

## Theory

PantherLang's AI platform integrates with five providers: OpenAI, Anthropic, Gemini, Ollama, OpenRouter. All have **mock fallback** — no API keys needed for testing.

Available stdlib functions:
- **ai_supported_providers()**: Returns an array of provider names
- **ai_provider_available(provider)**: Returns `true` if the provider's API key is set
- **ai_mock_chat(prompt)**: Returns a mock chat response (no API key required)

**Security Rule**: API keys must come from environment variables, never hardcoded in source.

## Exercises

### Exercise 1: List Providers
**Task**: Call `ai_supported_providers()`, print the list of providers, and print the total count.
**Hint**: Use `len()` on the returned array.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/11-lab.pan`

### Exercise 2: Check Provider Availability
**Task**: Check if `"openai"` and `"ollama"` providers are available using `ai_provider_available()`. Print the results.
**Hint**: `ai_provider_available("ollama")` returns `true` if `OLLAMA_HOST` is set, otherwise `false`.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/11-lab.pan`

### Exercise 3: Mock Chat and Security
**Task**: Use `ai_mock_chat()` to send `"What is PantherLang?"` and print the response. Then explain why you should never hardcode API keys.
**Hint**: The mock function works without any API key. Always use environment variables for secrets.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/11-lab.pan`

## Summary
You explored PantherLang's AI platform, listed providers, checked availability, and used mock chat. You also learned the critical security rule of never hardcoding API keys.

## Further Reading
- Book Chapter 11: AI Platform
- examples/hello_ai/main.pan
