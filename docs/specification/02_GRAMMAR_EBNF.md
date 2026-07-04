# PantherLang Grammar (EBNF)

## Notation

```
|   alternation
()  grouping
[]  optional (0 or 1)
{}  repetition (0 or more)
""  terminal string
```

## Program

```
program          = { top_level_block } EOF ;

top_level_block  = panther_main_block
                 | web_block
                 | api_block
                 | ai_block
                 | test_block ;

panther_main_block = "panther" "main" block ;
web_block        = "web" block ;
api_block        = "api" block ;
ai_block         = "ai" block ;
test_block       = "test" [ string_literal | identifier ] block ;
```

## Statements

```
block            = "{" { statement } "}" ;

statement        = variable_declaration
                 | function_declaration
                 | struct_declaration
                 | enum_declaration
                 | trait_declaration
                 | import_statement
                 | assignment_statement
                 | if_statement
                 | while_statement
                 | for_statement
                 | loop_statement
                 | route_statement
                 | print_statement
                 | return_statement
                 | break_statement
                 | continue_statement
                 | expression_statement ;

variable_declaration = "let" identifier [ ":" type_name ] [ "=" expression ] ";" ;

function_declaration = "fn" identifier "(" [ parameter_list ] ")" [ ":" type_name ] block ;

parameter_list   = parameter { "," parameter } ;
parameter        = identifier [ ":" type_name ] ;

struct_declaration  = "struct" identifier "{" { identifier } "}" ;
enum_declaration    = "enum" identifier "{" { identifier } "}" ;
trait_declaration   = "trait" identifier "{" { trait_method } "}" ;
trait_method        = [ "fn" ] identifier "(" [ identifier { "," identifier } ] ")" ";" ;

import_statement = "import" identifier { "." identifier } [ "as" identifier ] ";" ;

assignment_statement = expression ("=" | "+=" | "-=" | "*=" | "/=" | "%=") expression ";" ;

if_statement     = "if" expression block
                   { "elif" expression block }
                   [ "else" block ] ;

while_statement  = "while" expression block ;

for_statement    = "for" identifier "in" expression ".." expression block ;

loop_statement   = "loop" block ;

route_statement  = "route" ("GET" | "POST" | identifier) string_literal block ;

print_statement  = "print" [ "(" expression ")" | expression ] ";" ;

return_statement = "return" [ expression ] ";" ;

break_statement    = "break" ";" ;
continue_statement = "continue" ";" ;

expression_statement = expression ";" ;
```

## Expressions (Pratt Grammar)

```
expression       = binary_expression ;

binary_expression = unary_expression { binary_op unary_expression } ;

binary_op        = "||" | "&&"
                 | "==" | "!="
                 | ">" | ">=" | "<" | "<="
                 | "+" | "-"
                 | "*" | "/" | "%"
                 | "**" ;

unary_expression = primary_expression
                 | unary_op unary_expression ;

unary_op         = "!" | "-" | "+" ;

primary_expression = literal
                   | identifier
                   | grouping
                   | array_literal
                   | object_literal
                   | call_expression
                   | member_expression
                   | index_expression ;

literal          = number_literal | string_literal | "true" | "false" | "null" ;
number_literal   = integer | float ;
string_literal   = '"' { character } '"' ;

grouping         = "(" expression ")" ;

array_literal    = "[" [ expression { "," expression } [ "," ] ] "]" ;
object_literal   = "{" [ object_entry { "," object_entry } [ "," ] ] "}" ;
object_entry     = (identifier | string_literal) ":" expression ;

call_expression  = primary_expression "(" [ argument_list ] ")" ;
argument_list    = expression { "," expression } ;

member_expression = primary_expression "." identifier ;

index_expression = primary_expression "[" expression "]" ;
```

## Precedence (lowest to highest)

| Level | Operators | Associativity |
|-------|-----------|---------------|
| 10 | `=` `+=` `-=` `*=` `/=` `%=` | Right |
| 20 | `\|\|` | Left |
| 30 | `&&` | Left |
| 40 | `==` `!=` | Left |
| 50 | `>` `>=` `<` `<=` | Left |
| 60 | `+` `-` | Left |
| 70 | `*` `/` `%` | Left |
| 80 | `**` | Right |
| 90 | unary `!` `-` `+` | Right |
| 100 | `.` `()` `[]` | Left |
