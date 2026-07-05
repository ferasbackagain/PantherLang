panther main {
    print "=== Lesson 14: Language Reference ===";
    print "";
    
    print "--- Lexical Structure ---";
    print "Comments: // single-line only";
    print "Identifiers: letters, digits, underscores; start with letter or underscore";
    print "String escapes: \\n, \\t, \\\", \\\\";
    print "Numbers: integer (42) and float (3.14) decimal literals";
    print "";
    
    print "--- Keywords (16) ---";
    print "panther main web api ai test";
    print "print return route get post";
    print "true false null assert prompt";
    print "";
    
    print "--- Operators ---";
    print "Arithmetic: +, -, *, /, %, **";
    print "Compound: +=, -=, *=, /=, %=";
    print "Comparison: ==, !=, >, >=, <, <=";
    print "Logical: &&, ||, !";
    print "Index: [, ]";
    print "Member: ., ->";
    print "Separators: {, }, (, ), ,, :, ;";
    print "";
    
    print "--- Top-Level Blocks ---";
    print "panther main { ... }    // Entry point - executable";
    print "web { ... }             // Web block";
    print "api { ... }             // API block";
    print "ai { ... }              // AI block";
    print "test \"name\" { ... }    // Test block";
    print "";
    
    print "--- Statements ---";
    print "let x = expr;                    // variable declaration";
    print "let x: type = expr;              // typed declaration";
    print "x = expr;                        // assignment";
    print "x += expr;                       // compound assignment";
    print "print expr;                      // output";
    print "return expr;                     // return with value";
    print "return;                          // return without value";
    print "if cond { ... } elif cond { ... } else { ... }";
    print "while cond { ... }";
    print "for id in start..end { ... }";
    print "loop { ... }";
    print "break;";
    print "continue;";
    print "fn id(params) { ... }";
    print "fn id(params): type { ... }";
    print "route GET \"/path\" { ... }";
    print "route POST \"/path\" { ... }";
    print "struct Name { fields }";
    print "enum Name { VARIANTS }";
    print "trait Name { fn sig(params); }";
    print "import module;";
    print "import module as alias;";
    print "{ ... }                          // nested block";
    print "";
    
    print "--- Standard Library Categories (43 functions) ---";
    print "String (11): len, substring, contains, starts_with, ends_with, upper, lower, trim, replace, split, join";
    print "Math (10): abs, max, min, pow, sqrt, floor, ceil, round, random, randint";
    print "JSON (2): json_encode, json_decode";
    print "Time (2): time, sleep";
    print "Type Conversion (3): int, float, string";
    print "Crypto (4): sha256, hmac_sha256, secure_token, secure_compare";
    print "Security (2): sanitize_path, sanitize_html";
    print "Filesystem (6): read_file, write_file, file_exists, mkdir, list_dir, remove_file";
    print "HTTP (2): http_get, http_post";
    print "Regex (3): regex_match, regex_replace, regex_split";
    print "Collections (4): array_push, array_pop, array_sort, array_reverse";
    print "SQLite (4): db_open, db_close, db_execute, db_query";
    print "";
    
    print "--- Error Codes ---";
    print "E001: Break outside loop";
    print "E002: Continue outside loop";
    print "E003: Duplicate function declaration";
    print "E005: Duplicate variable declaration";
    print "E006: Duplicate import";
    print "E007: Undefined variable referenced";
    print "E008: Undefined function/symbol";
    print "T001: Type mismatch / incompatibility";
    print "S001: Hardcoded secret in string literal";
    print "S002: Dangerous function name";
    print "S003: Dangerous function call";
    print "S004: Dangerous shell pattern";
    print "S005: Secret pattern in string value";
    print "";
    
    print "=== Lesson 14 Complete ===";
}