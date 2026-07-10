from __future__ import annotations

from .tokens import KEYWORDS, LexerError, SourceLocation, Token, TokenKind


class PantherLexer:
    def __init__(self, source: str):
        self.source = source
        self.tokens: list[Token] = []
        self.start = 0
        self.current = 0
        self.line = 1
        self.column = 1
        self.token_line = 1
        self.token_column = 1
        self.token_index = 0

    def scan_tokens(self) -> list[Token]:
        while not self._is_at_end():
            self.start = self.current
            self.token_line = self.line
            self.token_column = self.column
            self.token_index = self.current
            self._scan_token()
        self.tokens.append(Token(TokenKind.EOF, "", None, SourceLocation(self.line, self.column, self.current)))
        return self.tokens

    def _scan_token(self) -> None:
        ch = self._advance()
        if ch == "(":
            self._add_token(TokenKind.LEFT_PAREN)
        elif ch == ")":
            self._add_token(TokenKind.RIGHT_PAREN)
        elif ch == "{":
            self._add_token(TokenKind.LEFT_BRACE)
        elif ch == "}":
            self._add_token(TokenKind.RIGHT_BRACE)
        elif ch == "[":
            self._add_token(TokenKind.LEFT_BRACKET)
        elif ch == "]":
            self._add_token(TokenKind.RIGHT_BRACKET)
        elif ch == ",":
            self._add_token(TokenKind.COMMA)
        elif ch == ":":
            self._add_token(TokenKind.COLON)
        elif ch == ";":
            self._add_token(TokenKind.SEMICOLON)
        elif ch == ".":
            if self._match("."):
                self._add_token(TokenKind.DOT_DOT)
            else:
                self._add_token(TokenKind.DOT)
        elif ch == "+":
            if self._match("="):
                self._add_token(TokenKind.PLUS_EQUAL)
            elif self._match("+"):
                self._add_token(TokenKind.PLUS, "+")
            else:
                self._add_token(TokenKind.PLUS)
        elif ch == "-":
            if self._match("="):
                self._add_token(TokenKind.MINUS_EQUAL)
            elif self._match("-"):
                self._add_token(TokenKind.MINUS, "-")
            elif self._match(">"):
                self._add_token(TokenKind.ARROW)
            else:
                self._add_token(TokenKind.MINUS)
        elif ch == "*":
            if self._match("="):
                self._add_token(TokenKind.STAR_EQUAL)
            elif self._match("*"):
                self._add_token(TokenKind.STAR_STAR)
            else:
                self._add_token(TokenKind.STAR)
        elif ch == "/":
            if self._match("="):
                self._add_token(TokenKind.SLASH_EQUAL)
            elif self._match("/"):
                while self._peek() != "\n" and not self._is_at_end():
                    self._advance()
            else:
                self._add_token(TokenKind.SLASH)
        elif ch == "%":
            if self._match("="):
                self._add_token(TokenKind.PERCENT_EQUAL)
            else:
                self._add_token(TokenKind.PERCENT)
        elif ch == "!":
            self._add_token(TokenKind.BANG_EQUAL if self._match("=") else TokenKind.BANG)
        elif ch == "=":
            self._add_token(TokenKind.EQUAL_EQUAL if self._match("=") else TokenKind.EQUAL)
        elif ch == "<":
            self._add_token(TokenKind.LESS_EQUAL if self._match("=") else TokenKind.LESS)
        elif ch == ">":
            self._add_token(TokenKind.GREATER_EQUAL if self._match("=") else TokenKind.GREATER)
        elif ch == "&":
            if self._match("&"):
                self._add_token(TokenKind.AMP_AMP)
            else:
                self._add_token(TokenKind.AMPERSAND)
        elif ch == "|":
            if self._match("|"):
                self._add_token(TokenKind.PIPE_PIPE)
            else:
                self._add_token(TokenKind.PIPE)
        elif ch in (" ", "\r", "\t", "\ufeff"):
            return
        elif ch == "\n":
            return
        elif ch == '"':
            self._string()
        elif ch.isdigit():
            self._number()
        elif self._is_identifier_start(ch):
            self._identifier()
        else:
            raise LexerError(f"Unexpected character {ch!r}", self._location())

    def _identifier(self) -> None:
        while self._is_identifier_part(self._peek()):
            self._advance()
        text = self.source[self.start:self.current]
        self._add_token(KEYWORDS.get(text, TokenKind.IDENTIFIER))

    def _number(self) -> None:
        while self._peek().isdigit():
            self._advance()
        if self._peek() == "." and self._peek_next().isdigit():
            self._advance()
            while self._peek().isdigit():
                self._advance()
        text = self.source[self.start:self.current]
        self._add_token(TokenKind.NUMBER, float(text) if "." in text else int(text))

    def _string(self) -> None:
        chars: list[str] = []
        while not self._is_at_end() and self._peek() != '"':
            ch = self._advance()
            if ch == "\\":
                if self._is_at_end():
                    raise LexerError("Unterminated string escape", self._location())
                esc = self._advance()
                chars.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(esc, esc))
            else:
                chars.append(ch)
        if self._is_at_end():
            raise LexerError("Unterminated string", self._location())
        self._advance()
        self._add_token(TokenKind.STRING, "".join(chars))

    def _add_token(self, kind: TokenKind, literal: object | None = None) -> None:
        self.tokens.append(Token(
            kind=kind,
            lexeme=self.source[self.start:self.current],
            literal=literal,
            location=SourceLocation(self.token_line, self.token_column, self.token_index),
        ))

    def _advance(self) -> str:
        ch = self.source[self.current]
        self.current += 1
        if ch == "\n":
            self.line += 1
            self.column = 1
        else:
            self.column += 1
        return ch

    def _match(self, expected: str) -> bool:
        if self._is_at_end() or self.source[self.current] != expected:
            return False
        self._advance()
        return True

    def _peek(self) -> str:
        return "\0" if self._is_at_end() else self.source[self.current]

    def _peek_next(self) -> str:
        return "\0" if self.current + 1 >= len(self.source) else self.source[self.current + 1]

    def _is_at_end(self) -> bool:
        return self.current >= len(self.source)

    def _location(self) -> SourceLocation:
        return SourceLocation(self.line, self.column, self.current)

    @staticmethod
    def _is_identifier_start(ch: str) -> bool:
        return ch.isalpha() or ch == "_"

    @staticmethod
    def _is_identifier_part(ch: str) -> bool:
        return ch.isalnum() or ch == "_"


def lex_source(source: str) -> list[Token]:
    # Windows editors and PowerShell may create UTF-8 BOM-prefixed files.
    # Treat a leading BOM as metadata, not as PantherLang source text.
    if source.startswith("\ufeff"):
        source = source[1:]
    return PantherLexer(source).scan_tokens()
