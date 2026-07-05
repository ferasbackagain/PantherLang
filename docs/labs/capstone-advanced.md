# Capstone: Secure AI Chat with PantherLang (Advanced)

## Objectives
- Integrate AI providers using `ai_supported_providers()` and `ai_mock_chat()`
- Use `SecureAgent` principles: input sanitization with `sanitize_html()`
- Store message history in SQLite
- Implement rate limiting concepts
- Build a secure web API for AI chat

## Theory
A secure AI chat application requires multiple layers:
- **AI Integration**: PantherLang provides `ai_supported_providers()` and `ai_mock_chat()` for interacting with AI models
- **Input Sanitization**: `sanitize_html()` escapes HTML entities (`<`, `>`, `&`, `"`, `'`) to prevent XSS attacks
- **Message Integrity**: `sha256()` creates message hashes for verification
- **Rate Limiting**: Track request counts to prevent abuse
- **Security-First Design**: Never hardcode API keys, always sanitize user input

## Exercises

### Exercise 1: AI provider integration
**Task**: Use `ai_supported_providers()` to list available AI providers and `ai_mock_chat(prompt)` to get a mock AI response. Display both in the console.
**Hint**: `ai_supported_providers()` returns an array of provider names. `ai_mock_chat()` returns a string.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/capstone-advanced.pan`

### Exercise 2: Message history with SQLite
**Task**: Create a `messages` table with `role`, `content`, and `timestamp`. Save AI responses and expose a `GET /history` endpoint.
**Hint**: Use `db_open("chat_history.db")` and `CREATE TABLE IF NOT EXISTS messages (...)`.
**Verify**: The `/history` endpoint returns stored messages as JSON.

### Exercise 3: HTML sanitization and security
**Task**: Sanitize all user input and AI output with `sanitize_html()` before storing or displaying. Generate message integrity hashes with `sha256()`. Implement a rate limit counter.
**Hint**: `sanitize_html("<script>alert('xss')</script>")` escapes to safe HTML entities.
**Verify**: The solution prints sanitized output and message integrity hashes.

## Summary
You built a secure AI chat application with provider integration, message history, HTML sanitization, and rate limiting — demonstrating PantherLang's AI, security, and web capabilities.

## Further Reading
- `examples/hello_ai/main.pan`
- `compiler/ai/` for AI provider implementations
- `compiler/security/` for security analyzers
- `compiler/stdlib/functions.py`: `_sanitize_html`, `_sha256`, `_ai_mock_chat`
