from dataclasses import dataclass
from typing import List

KEYWORDS = {
    "app", "version", "target", "targets", "description",
    "capabilities", "allow", "data", "api", "ui", "page", "workflow",
    "agent", "device", "security", "deploy", "task", "service",
    "package", "import", "config", "return", "public", "secure",
    "required", "unique", "default", "when", "notify", "admin",
    "type", "read", "tools", "purpose", "auth", "secrets", "protected",
    "permission", "network", "dangerous_commands", "explicit", "local",
    "port", "create", "from", "request", "body", "run", "print", "input",
    "action", "declared", "private", "deny", "filesystem", "device", "ai",
    "memory", "policy", "scoped", "optional", "web", "api_only", "app_storage"
}

SYMBOLS = {"{", "}", "(", ")", "[", "]", ",", ".", ":", "=", "<", ">", "/", "?", "_"}

@dataclass
class Token:
    type: str
    value: str
    line: int
    column: int

    def __repr__(self):
        return f"{self.type}({self.value!r})@{self.line}:{self.column}"

class TokenizerError(Exception):
    pass

def tokenize(source: str) -> List[Token]:
    tokens: List[Token] = []
    i = 0
    line = 1
    col = 1

    def add(tok_type: str, value: str, start_line: int, start_col: int):
        tokens.append(Token(tok_type, value, start_line, start_col))

    while i < len(source):
        ch = source[i]

        if ch in " \t\r":
            i += 1
            col += 1
            continue

        if ch == "\n":
            i += 1
            line += 1
            col = 1
            continue

        if ch == "#":
            while i < len(source) and source[i] != "\n":
                i += 1
                col += 1
            continue

        if ch == '"':
            start_line, start_col = line, col
            i += 1
            col += 1
            value = ""
            while i < len(source) and source[i] != '"':
                if source[i] == "\n":
                    raise TokenizerError(f"Unterminated string at {start_line}:{start_col}")
                value += source[i]
                i += 1
                col += 1
            if i >= len(source):
                raise TokenizerError(f"Unterminated string at {start_line}:{start_col}")
            i += 1
            col += 1
            add("STRING", value, start_line, start_col)
            continue

        if ch.isdigit():
            start_line, start_col = line, col
            value = ""
            while i < len(source) and (source[i].isdigit() or source[i] == "."):
                value += source[i]
                i += 1
                col += 1
            add("NUMBER", value, start_line, start_col)
            continue

        if ch.isalpha() or ch == "_":
            start_line, start_col = line, col
            value = ""
            while i < len(source) and (source[i].isalnum() or source[i] == "_"):
                value += source[i]
                i += 1
                col += 1
            tok_type = "KEYWORD" if value in KEYWORDS else "IDENTIFIER"
            add(tok_type, value, start_line, start_col)
            continue

        if ch in SYMBOLS:
            add("SYMBOL", ch, line, col)
            i += 1
            col += 1
            continue

        raise TokenizerError(f"Unexpected character {ch!r} at {line}:{col}")

    tokens.append(Token("EOF", "", line, col))
    return tokens
