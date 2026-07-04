# Chapter 6: Data Structures

## Arrays

Ordered, mutable collections:

```panther
let arr = [10, 20, 30];
print arr[0];           // 10
print len(arr);         // 3

// Iteration
let i = 0;
while i < len(arr) {
    print arr[i];
    i = i + 1;
}

// Nested arrays
let matrix = [[1, 2], [3, 4]];
print matrix[0][1];     // 2
```

## Objects / Dictionaries

Unordered key-value collections:

```panther
let obj = {name: "Panther", version: "1.0.0", year: 2026};
print obj["name"];      // "Panther"
print obj["year"];      // 2026

// Nested access
let config = json_decode("{\"db\": {\"host\": \"localhost\"}}");
print config["db"]["host"];  // "localhost"
```

## Structs

Named data structures with typed fields:

```panther
struct Point {
    x y
}

let p = Point(10, 20);
print p.x;              // 10
```
