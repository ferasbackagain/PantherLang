# PantherLang Calculator Roadmap

## Goal

Build the first real PantherLang application: **Panther Calculator**.

## Phase 1 --- R3 Batch 2 Part 3.3: Expression Parser

-   Integer literals
-   Parentheses
-   Unary operators
-   Binary operators
-   Operator precedence
-   AST generation

``` panther
10 + 5
10 * (8 + 2)
100 / 4
```

## Phase 2 --- Variables

``` panther
let a = 10
let b = 5
let result = a + b
```

## Phase 3 --- Input

``` panther
let value = input("Enter number:")
```

## Phase 4 --- Conditions

``` panther
if op == "+" {
    print(a + b)
}
```

## Phase 5 --- Functions

``` panther
function calculate(a, op, b) {
    return a + b
}
```

## Phase 6 --- Panther Calculator v1

``` bash
panther run calculator.pan
```

Workflow: 1. Read first number. 2. Read operator. 3. Read second number.
4. Evaluate. 5. Print result. 6. Continue or exit.
