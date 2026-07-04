# PantherLang Lexical Specification

## Character Set

PantherLang source is UTF-8 encoded Unicode text.

## Tokens

### Whitespace and Comments

Whitespace (spaces, tabs, newlines) separates tokens but is otherwise ignored.

Line comments begin with `//` and extend to the end of the line.

### Keywords (reserved)

```
panther   main      web       api       ai        test
let       fn        return    if        elif      else
while     for       in        loop      break     continue
struct    enum      trait     import    print     route
get       post      put       delete    as        true
false     null
```

### Identifiers

Begin with a letter `a-z`, `A-Z` or underscore `_`, followed by zero or more
letters, digits, or underscores.

```
identifier ::= [a-zA-Z_][a-zA-Z0-9_]*
```

### Literals

**Integer:** `42`, `-7`, `0`, `2026`
**Float:** `3.14`, `-0.5`, `10.0`
**String:** `"hello"`, `"42"`, `"hello \"world\""` (double-quoted, backslash escapes)
**Boolean:** `true`, `false`
**Null:** `null`

### Operators and Delimiters

```
+    -    *    /    %    **
==   !=   >    >=   <    <=
&&   ||   !
=    +=   -=   *=   /=   %=
(    )    {    }    [    ]
,    :    ;    .
..   ->
```

### Token Categories

| Category | Tokens |
|----------|--------|
| Literals | NUMBER_LITERAL, STRING_LITERAL, TRUE, FALSE, NULL |
| Keywords | PANTHER, MAIN, WEB, API, AI, TEST, LET, FN, RETURN, IF, ELIF, ELSE, WHILE, FOR, IN, LOOP, BREAK, CONTINUE, STRUCT, ENUM, TRAIT, IMPORT, PRINT, ROUTE, GET, POST, PUT, DELETE, AS |
| Identifiers | IDENTIFIER |
| Operators | PLUS, MINUS, STAR, SLASH, PERCENT, STAR_STAR, EQUAL_EQUAL, BANG_EQUAL, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL, PIPE_PIPE, AMP_AMP, BANG, EQUAL, PLUS_EQUAL, MINUS_EQUAL, STAR_EQUAL, SLASH_EQUAL, PERCENT_EQUAL |
| Delimiters | LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE, LEFT_BRACKET, RIGHT_BRACKET, COMMA, COLON, SEMICOLON, DOT, DOT_DOT, ARROW |
| Special | EOF |
