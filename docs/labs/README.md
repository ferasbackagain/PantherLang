# PantherLang Labs

21 hands-on labs (18 guided + 3 capstones) for learning PantherLang by doing.

## Guided Labs (18)

| Lab | Topic | Exercises | Academy Ref |
|-----|-------|-----------|-------------|
| 01 | Getting Started | print, expressions, Hello World | Lesson 01 |
| 02 | Variables & Types | let, type conversion, null | Lesson 02 |
| 03 | Control Flow | if/elif/else, while, for, loop, break/continue | Lesson 03 |
| 04 | Functions | fn, params, return, recursion | Lesson 04 |
| 05 | Type Conversions & IO | int(), float(), string() | Lesson 05 |
| 06 | Data Structures | arrays, objects, nested access | Lesson 06 |
| 07 | Standard Library | string, math, JSON functions | Lesson 07 |
| 08 | Security | SHA-256, HMAC, tokens, sanitization | Lesson 08 |
| 09 | Web Platform | routes, params, POST handlers | Lesson 09 |
| 10 | Database Platform | SQLite CRUD, parameterized queries | Lesson 10 |
| 11 | AI Platform | providers, Agent, SecureAgent | Lesson 11 |
| 12 | CLI & Tooling | doctor, scaffold, check | Lesson 12 |
| 13 | Cross-Platform | path handling, scripts, platform compat | Lesson 13 |
| 14 | Language Reference | keywords, operators, error codes | Lesson 14 |
| 15 | Comparison Semantics | same-type, cross-type, null | Lesson 15 |
| 16 | Contributing | dev setup, testing, PR process | Lesson 16 |
| 17 | Advanced Data Processing | JSON, file I/O, pipelines | Lesson 17 |
| 18 | Integration Project | web + database + security | Lesson 18 |

## Capstone Labs (3)

| Capstone | Level | Description | Uses |
|----------|-------|-------------|------|
| Beginner | Personal Diary CLI | File-based diary app | Filesystem, strings, arrays |
| Intermediate | Library Management API | Web API with SQLite | Web, SQLite, JSON, security |
| Advanced | AI Chat with Security | Secure AI chat app | AI, SQLite, security, web |

## Running Labs

```bash
# Read lab instructions
cat docs/labs/03-lab.md

# Run solution
python -m cli.panther_cli run docs/labs/solutions/03-lab.pan

# Check your answer
python -m cli.panther_cli check your_solution.pan
```

## Structure

```
docs/labs/
├── 01-lab.md ... 18-lab.md   # Lab instructions
├── capstone-*.md              # Capstone project specs
├── solutions/
│   ├── 01-lab.pan ... 18-lab.pan  # Verified solutions
│   └── capstone-*.pan             # Capstone solutions
└── README.md                   # This file
```
