# Chapter 7: Standard Library

PantherLang includes 43 built-in functions. All are available without imports.

## String (11)

```panther
len("hello")            // 5
upper("hello")          // "HELLO"
lower("HELLO")          // "hello"
trim("  hi  ")          // "hi"
contains("Panther", "th")  // true
starts_with("Panther", "Pan")  // true
ends_with("Panther", "er")    // true
replace("a-b-c", "-", "/")    // "a/b/c"
split("a,b,c", ",")           // ["a", "b", "c"]
join(["a", "b"], ",")         // "a,b"
substring("Panther", 2, 5)   // "nth"
```

## Math (10)

```panther
abs(-5)                 // 5
max(10, 20)             // 20
min(10, 20)             // 10
pow(2, 3)               // 8
sqrt(16)                // 4.0
floor(3.7)              // 3
ceil(3.2)               // 4
round(3.5)              // 4
random()                // 0.0–1.0 float
randint(1, 10)          // random int 1–10
```

## JSON (2)

```panther
let json = json_encode({name: "Panther", year: 2026});
let obj = json_decode(json);
let arr = json_decode("[10, 20, 30]");
```

## Time (2)

```panther
let now = time();       // Unix timestamp
sleep(1);               // pause 1 second
```

## Type Conversion (3)

```panther
int("42")               // 42
float("3.14")           // 3.14
string(42)              // "42"
```

## Crypto / Security (6)

```panther
sha256("hello")         // hex hash
hmac_sha256("key", "msg")
secure_token(32)        // random hex token
secure_compare("a", "b")  // constant-time compare
sanitize_path("/unsafe/../path")
sanitize_html("<script>alert('xss')</script>")
```

## Filesystem (6)

```panther
mkdir("dir")
write_file("dir/file.txt", "content")
let content = read_file("dir/file.txt")
file_exists("dir/file.txt")    // true
let files = list_dir("dir")
remove_file("dir/file.txt")
```

## HTTP Client (2)

```panther
let resp = http_get("https://httpbin.org/get")
let post = http_post("https://httpbin.org/post", "{\"key\": \"val\"}")
```

## Regex (3)

```panther
regex_match("hello123", "\\d+")        // true
regex_replace("a1b2", "\\d", "X")      // "aXbX"
regex_split("a,b,c", ",")              // ["a", "b", "c"]
```

## Collections (4)

```panther
let arr = [1, 2, 3];
array_push(arr, 4);       // arr = [1, 2, 3, 4]
let last = array_pop(arr);  // last = 4
array_sort(arr);           // ascending
array_reverse(arr);        // reversed
```

## SQLite (4)

```panther
let conn = db_open(":memory:");
db_execute(conn, "CREATE TABLE t (id INTEGER, name TEXT)");
let rows = db_query(conn, "SELECT * FROM t");
db_close(conn);
```
