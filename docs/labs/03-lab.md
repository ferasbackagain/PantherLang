# Lab 03: Control Flow

## Objectives
- Use `if`/`elif`/`else` for conditional branching
- Iterate with `while` loops
- Use `for` range loops
- Control loop flow with `loop`, `break`, and `continue`

## Theory

Conditionals use `if condition { } elif condition { } else { }` — no parentheses needed around the condition, but braces are required.

Loop constructs:
- `while condition { }` — repeats while a condition is true
- `for i in start..end { }` — iterates from `start` to `end` (inclusive on both ends)
- `loop { }` — infinite loop, use `break` to exit, `continue` to skip to next iteration

## Exercises

### Exercise 1: FizzBuzz
**Task**: Print numbers from 1 to 15. For multiples of 3, print `"Fizz"` instead of the number. For multiples of 5, print `"Buzz"`. For multiples of both 3 and 5, print `"FizzBuzz"`.

**Hint**: Use `for i in 1..15 { }`. Use `%` (modulo) to check divisibility: `i % 3 == 0`. Check the `&&` (both 3 and 5) condition first!

**Verify**: The output should be: 1, 2, Fizz, 4, Buzz, Fizz, 7, 8, Fizz, Buzz, 11, Fizz, 13, 14, FizzBuzz.

### Exercise 2: Sum 1 to 100 Using While
**Task**: Use a `while` loop to sum all integers from 1 to 100. Print the total.

**Hint**: Initialize `let i = 1; let sum = 0;` then loop `while i <= 100 { sum = sum + i; i = i + 1; }`.

**Verify**: The result should be `5050`.

### Exercise 3: Find First Divisible by 7 and 13
**Task**: Use `loop` and `break` to find the first number in the range 1..200 that is divisible by both 7 and 13. Print it.

**Hint**: Start `let i = 1; loop { if i > 200 { break; } if i % 7 == 0 && i % 13 == 0 { print i; break; } i = i + 1; }`.

**Verify**: The smallest number divisible by both 7 and 13 (LCM of 7 and 13) is 91. Confirm the output is `91`.

## Summary
You mastered PantherLang control flow: conditionals, while loops, for ranges, and the loop/break/continue pattern.

## Further Reading
- Academy Lesson 03: Control Flow
- Academy Lesson 04: Loops
- Book Chapter 03: Making Decisions
- Book Chapter 04: Repeating Code
