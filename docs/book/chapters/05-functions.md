# Chapter 5: Functions

## Function Declaration

```panther
fn greet(msg) {
    return "Greetings: " + msg;
}

print greet("PantherLang");
```

## Parameters and Return

```panther
fn add(a, b) {
    return a + b;
}

fn no_return() {
    print "no value returned";
}

fn empty_return() {
    return;
}
```

## Recursion

```panther
fn factorial(n) {
    if n <= 1 {
        return 1;
    }
    return n * factorial(n - 1);
}

print factorial(5);    // 120
```

## Typed Parameters and Return

```panther
fn add(a: int, b: int): int {
    return a + b;
}

fn greet(name: string): string {
    return "Hello " + name;
}
```

Type annotations are verified by the type checker — passing a string where an int is expected produces a diagnostic.

## Functions in Scope

Functions can access outer scope variables (closures):

```panther
let prefix = "Value: ";
fn show(x) {
    return prefix + string(x);
}
print show(42);    // "Value: 42"
```
