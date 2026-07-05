# Lab 06: Data Structures

## Objectives
- Create and access arrays using `[ ]` syntax
- Create and access objects using `{key: value}` syntax
- Nest data structures and traverse them

## Theory

**Arrays**: Ordered collections using square brackets: `let arr = [10, 20, 30]`. Access by index: `arr[0]` → `10`. Get length with `len(arr)`. Iterate with `for i in 0..len(arr)-1`.

**Objects**: Key-value dictionaries using curly braces: `let obj = {name: "Panther", year: 2026}`. Access with bracket notation: `obj["name"]` → `"Panther"`.

**Nesting**: Arrays can contain objects, objects can contain arrays.

## Exercises

### Exercise 1: Gradebook Object
**Task**: Create an object called `gradebook` where each key is a student name and each value is an array of their scores. Include at least three students with at least three scores each. Print each student's name and scores.

**Hint**: 
```panther
let gradebook = {
    Alice: [85, 92, 78],
    Bob: [90, 88, 95],
    Carol: [70, 85, 89]
};
```
Access with `gradebook["Alice"]` and iterate over keys.

**Verify**: Running the solution should print each student's name and their list of scores.

### Exercise 2: Compute Class Average
**Task**: Iterate over the `gradebook` object, compute the average score for each student, and print it. Then compute and print the overall class average.

**Hint**: Use `for i in 0..len(scores)` inside a loop. Sum all scores for a student, divide by `len(scores)`. Track a `class_total` and `class_count` across all students.

**Verify**: Alice (avg 85.0), Bob (avg 91.0), Carol (avg 81.3), class average ~85.8.

### Exercise 3: Nested Object Access
**Task**: Create a nested structure representing a library catalog:
```panther
let library = {
    fiction: {count: 5, books: ["Dune", "1984", "Neuromancer", "Ender's Game", "Snow Crash"]},
    non_fiction: {count: 3, books: ["Sapiens", "Homo Deus", "21 Lessons"]}
};
```
Print the title of the first fiction book, the total number of non-fiction books, and list all book titles across both sections.

**Hint**: Access the first fiction book via `library["fiction"]["books"][0]`. Count non-fiction via `library["non_fiction"]["count"]`.

**Verify**: First fiction book is `Dune`, non-fiction count is `3`, and all 8 titles print correctly.

## Summary
You learned to create and work with arrays, objects, and nested data structures — the foundation for organizing data in PantherLang.

## Further Reading
- Academy Lesson 06: Arrays and Objects
- Academy Lesson 07: Nested Data
- Book Chapter 07: Collections
