# docs/academy/README.md

# PantherLang Academy

## Overview

PantherLang Academy is a structured learning platform for mastering PantherLang. It provides comprehensive lessons from beginner to advanced levels, with hands-on exercises, labs, and real-world examples.

## Academy Philosophy

- **Progressive Learning**: Lessons build on previous concepts
- **Practical Application**: Every concept has real-world usage
- **Visual Learning**: Clear explanations with code examples
- **Security-First**: All lessons emphasize security best practices
- **Interactive**: Examples work immediately with the Panther CLI

## Academy Structure

### Lesson Organization
**10 Lessons (Lessons 01-05 are complete)**

| Lesson | Title | Focus | Status |
|--------|-------|-------|--------|
| 01 | Expressions & Operators | Basic expressions, operators, precedence | ✅ Complete |
| 02 | Variables & Types | Variable declaration, type inference | ✅ Complete |
| 03 | Control Flow | If/elif/else, loops, branching | ✅ Complete |
| 04 | Functions | Function definitions, recursion, closures | ✅ Complete |
| 05 | Conversions & IO | Type conversion, input/output operations | ✅ Complete |
| 06 | Arrays & Collections | Arrays, objects, indexing, manipulation | 🔄 In Progress |
| 07 | Modules & Packages | Importing, module system, dependency management | 🔄 In Progress |
| 08 | Web Development | HTTP server, routing, middleware | 🔄 In Progress |
| 09 | AI & Machine Learning | AI providers, agents, RAG engine | 🔄 In Progress |
| 10 | Advanced Security | Security analysis, sandbox, defense | 🔄 In Progress |

### Learning Paths
1. **Beginner Track**: Lessons 01-05 (Foundation)
2. **Developer Track**: Lessons 01-08 (Development)
3. **Professional Track**: Lessons 01-10 (Expert)

## Lesson Details

### Lesson 01: Expressions & Operators ✅
**Duration**: 3 hours | **Difficulty**: Beginner

#### Learning Objectives
- Understand expression evaluation
- Master operator precedence
- Implement arithmetic and logical operations
- Apply unary and binary operators
- Use function calls and member access

#### Key Concepts
```panther
// Expression types
literal: 42, "hello", true, null
unary: -5, !true
binary: 5 + 3, a == b
function: fn_name(args)
member: obj.field, arr[0]
grouping: (expr)
```

#### Lesson Activities
1. **Practice**: Build expression evaluator
2. **Lab**: Operator precedence challenges
3. **Homework**: Expression optimization
4. **Quiz**: Expression syntax validation

### Lesson 02: Variables & Types ✅
**Duration**: 4 hours | **Difficulty**: Beginner

#### Learning Objectives
- Declare variables with type inference
- Use optional type annotations
- Reassign variables safely
- Apply compound assignment operators
- Understand variable scope

#### Key Concepts
```panther
// Variable declaration
let name = "Alice";              // Inferred as string
let age: int = 30;              // Explicit type
let balance = 100.50;            // Inferred as float
let active = true;              // Inferred as bool
let data = "mixed";             // Inferred as any

// Reassignment
let x = 10;
x = 20;                     // Simple reassignment
x += 5;                         // Compound assignment
```

#### Lesson Activities
1. **Practice**: Variable declaration exercises
2. **Lab**: Scope resolution challenges
3. **Homework**: Type inference debugging
4. **Quiz**: Variable rules validation

### Lesson 03: Control Flow ✅
**Duration**: 5 hours | **Difficulty**: Intermediate

#### Learning Objectives
- Implement conditional logic
- Master loop structures
- Apply branching and iteration
- Handle loop control flow
- Use range-based iteration

#### Key Concepts
```panther
// Conditional logic
if condition {
    // execute when true
} elif other {
    // alternative
} else {
    // fallback
}

// Loops
while condition {
    // repeat while condition true
}

for i in 1..10 {
    // i from 1 to 10
}

loop {
    // infinite with break/continue
}
```

#### Lesson Activities
1. **Practice**: Control flow exercises
2. **Lab**: Loop optimization challenges
3. **Homework**: Control flow pattern implementation
4. **Quiz**: Control flow logic validation

### Lesson 04: Functions ✅
**Duration**: 6 hours | **Difficulty**: Intermediate

#### Learning Objectives
- Define and call functions
- Implement recursion
- Create closures
- Apply parameter typing
- Handle return values

#### Key Concepts
```panther
// Function definition
fn name(params) {
    // implementation
    return value;
}

// Recursive function
fn factorial(n) {
    if n <= 1 {
        return 1;
    }
    return n * factorial(n - 1);
}

// Closures
fn outer() {
    let x = 10;
    fn inner() {
        return x + 5;  // captures x
    }
    return inner;
}

// Type annotations
fn add(a: int, b: int): int {
    return a + b;
}
```

#### Lesson Activities
1. **Practice**: Function definition exercises
2. **Lab**: Recursion and closure challenges
3. **Homework**: Function composition problems
4. **Quiz**: Function syntax validation

### Lesson 05: Conversions & IO ✅
**Duration**: 4 hours | **Difficulty**: Intermediate

#### Learning Objectives
- Perform type conversions
- Handle input and output operations
- Apply security rules for I/O
- Process user input safely
- Format output correctly

#### Key Concepts
```panther
// Type conversions
let a = "42";
let b = to_int(a);

let str_value = string(123);
let float_value = float("3.14");

// Input/output
let input = input("Enter value: ");
let line = readline();
println("Hello, World!");
print "Result: ";
print result;
```

#### Lesson Activities
1. **Practice**: Conversion exercises
2. **Lab**: I/O security challenges
3. **Homework**: Conversion debugging
4. **Quiz**: IO operations validation

## Advanced Lessons (In Progress)

### Lesson 06: Arrays & Collections 🔄
**Estimated Completion**: Q1 2026

#### Topics
- Array operations and manipulation
- Object/dictionary creation and access
- Indexing and nested access
- Collection iteration and filtering
- Performance considerations

### Lesson 07: Modules & Packages 🔄
**Estimated Completion**: Q1 2026

#### Topics
- Import system and syntax
- Module resolution and loading
- Package dependency management
- Standard library organization
- Advanced import patterns

### Lesson 08: Web Development 🔄
**Estimated Completion**: Q2 2026

#### Topics
- HTTP server implementation
- Routing and request handling
- Middleware and security
- WebSockets and real-time communication
- Web application architecture

### Lesson 09: AI & Machine Learning 🔄
**Estimated Completion:** Q2 2026

#### Topics
- AI provider integration
- Agent architecture
- RAG engine and vector stores
- Prompt engineering
- AI security considerations

### Lesson 10: Advanced Security 🔄
**Estimated Completion:** Q3 2026

#### Topics
- Advanced security analysis
- Runtime sandbox configuration
- Defense-in-depth strategies
- Security auditing and compliance
- Enterprise security patterns

## Learning Methods

### Interactive Examples
```bash
# Run academy examples from repository
panther run examples/academy/lesson*/main.pan

# Test academy functionality
python -m pytest tests/academy/ -v

# Verify academy progress
bash scripts/verify_academy_lessons_01_05.sh
```

### Laboratory Exercises
1. **Code completion**: Complete partially written functions
2. **Debugging**: Identify and fix bugs in example code
3. **Optimization**: Improve performance of existing code
4. **Extension**: Add new features to existing examples

### Homework Assignments
1. **Problem sets**: Complete coding problems for each lesson
2. **Code review**: Review and provide feedback on peer solutions
3. **Project implementation**: Build complete projects using learned concepts
4. **Documentation**: Document solutions and explain reasoning

### Assessment
1. **Quizzes**: Multiple-choice and coding questions
2. **Projects**: Real-world project implementation
3. **Lab exams**: Practical implementation under timed conditions
4. **Peer review**: Evaluation of colleague solutions

## Technology Stack Integration

### Compiler & Runtime
- **Source**: `compiler/parser/`, `compiler/semantic/`, `compiler/types/`, `compiler/runtime/`
- **Execution**: Tree-walking interpreter with scoped environment
- **Testing**: Full test suite with 1000+ tests

### Development Tools
- **IDE**: VS Code extension with Panther support
- **Editor**: Syntax highlighting and code snippets
- **CLI**: `panther` commands for all operations
- **Testing**: pytest with custom test frameworks

### Verification Commands
```bash
# Verify academy lessons 01-05
bash scripts/verify_academy_lessons_01_05.sh

# Run specific academy tests
python -m pytest tests/academy/test_lesson*/ -v

# Test academy examples
python -m pytest tests/academy/ -v

# Full academy verification
python -m pytest tests/academy/ -v --tb=short
```

## Resources & Support

### Documentation
- **Panther Academy Guide**: `docs/academy/LESSONS_01_05_FIX_REPORT.md`
- **Engineering Report**: `engineering/academy_lessons01_05_stdlib_runtime_fix.md`
- **Testing Framework**: `tests/academy/test_lesson*/`

### Community
- **Discord**: PantherLang community server
- **Discussions**: GitHub issues and pull requests
- **Study Groups**: Regular meeting sessions
- **Mentoring**: Experienced developer guidance

### Certification
- **Foundation Certificate**: Lessons 01-05 completion
- **Developer Certificate**: Lessons 01-08 completion
- **Professional Certificate**: Lessons 01-10 completion

## Academy Integration

### Curriculum Alignment
1. **Programming Fundamentals**: Lessons 01-03
2. **Language Mastery**: Lessons 04-05
3. **Platform Skills**: Lessons 06-08
4. **Enterprise Skills**: Lessons 09-10

### Assessment Integration
1. **Continuous Assessment**: Quizzes and homework
2. **Practical Testing**: Lab exercises and projects
3. **Final Project**: Complete application implementation
4. **Certification**: Structured certification tracks

### Technology Integration
1. **Code Quality**: Best practices and standards
2. **Security**: Security-first curriculum design
3. **Performance**: Optimization and efficiency
4. **Documentation**: Comprehensive documentation requirements

---

**Current Status**: Academy Lessons 01-05 are complete and ready for user verification
**Next Steps**: Continue development of Lessons 06-10
**Completion Goal**: All 10 lessons by Q3 2026

PantherLang Academy provides the foundation for becoming a proficient PantherLang developer, with structured learning paths and practical application at every level.
