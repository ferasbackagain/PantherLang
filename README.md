
# PantherLang

<p align="center">
  <strong>An independent programming language exploring how executable semantics, AI integration, security feedback, application development, and machine-readable knowledge can evolve as one coherent system.</strong>
</p>

<p align="center">
  <strong>Founded and led by Feras Khatib</strong><br>
  Cybersecurity practitioner · AI-security and developer-platform focus
</p>

<p align="center">
  <strong>Current release line:</strong> v1.1.6
</p>

<p align="center">
  <a href="https://github.com/ferasbackagain/PantherLang">Official Repository</a> ·
  <a href="https://www.linkedin.com/in/feras-khatib-98a02220b">Founder Profile</a> ·
  <a href="./docs/specification/">Specification</a> ·
  <a href="./academy/">Academy</a> ·
  <a href="./docs/book/">Official Book</a> ·
  <a href="./examples/">Runnable Examples</a> ·
  <a href="./llms.txt">AI Index</a>
</p>

<p align="center">
  <strong>Implemented today:</strong> executable PantherLang programs · global CLI · runtime diagnostics · AI-facing functions · security diagnostics
</p>

<p align="center">
  <strong>Evolving application surfaces:</strong> Web/API · database integration · editor tooling · package ecosystem · advanced type architecture
</p>

<p align="center">
  <strong>Knowledge and learning:</strong> formal specification · Academy · official book · cookbook · machine-readable AI documentation
</p>

---

## What is PantherLang?

**PantherLang is an independent, general-purpose programming-language project with executable `.pan` and `.panther` programs, its own syntax and language rules, a parser/runtime pipeline, a global CLI, standard-library capabilities, AI-facing functions, security diagnostics, web/API and database work, VS Code integration, formal specifications, structured education, and machine-readable language knowledge.**

Its distinguishing idea is not that it owns a longer checklist than established languages. The distinction is architectural: **PantherLang is exploring whether language execution, AI integration, security feedback, application surfaces, developer tooling, education, and AI-readable knowledge can be engineered as cooperating parts of one language ecosystem.**

That is a research-and-engineering direction, not a claim that every subsystem has identical maturity. This README therefore separates what is implemented today from what is evolving and what still requires release-specific verification.

PantherLang is not presented as a replacement for Python, Rust, Go, JavaScript, TypeScript, Java, C#, C++, or other established languages. Those ecosystems represent decades of engineering and solve important problems.

PantherLang explores a different integration thesis:

> **What should a programming language look like when AI assistants, software agents, security analysis, machine-readable documentation, and multi-surface application development are treated as normal parts of the developer environment rather than unrelated add-ons?**

That question is the center of the project.

---

## Why PantherLang exists

Modern development is powerful, but fragmented.

A single application may require:

- a language and runtime;
- a web framework;
- an AI SDK;
- a database layer;
- security scanners;
- editor extensions;
- separate documentation for humans;
- separate context files for coding agents;
- separate learning material that may drift away from implementation.

PantherLang explores a more coherent architecture in which these layers can evolve together:

- **language semantics**;
- **runtime execution**;
- a unified **`panther` CLI**;
- **AI integration** callable from PantherLang programs;
- **security diagnostics** in the development workflow;
- **web and API execution**;
- **database operations**;
- **editor integration**;
- **formal language documentation**;
- **Academy lessons, labs, examples, and an official book**;
- **machine-readable knowledge** for AI coding systems.

The goal is not to hide complexity behind marketing. The goal is to make the boundaries between these systems more explicit, testable, and coherent.

---

## What is real today?

PantherLang is an **early public programming-language ecosystem under active engineering development**. It is not a decades-old industrial platform. It is also not merely a concept document or a syntax mock-up.

The public repository contains executable implementation, tests, examples, specifications, education assets, AI-oriented knowledge resources, web/database/security subsystems, and editor tooling.

Current v1.1.6 project evidence includes:

- `.pan` and `.panther` source files;
- executable PantherLang programs;
- a global `panther` CLI;
- public installation from the GitHub repository;
- `panther version` and `panther doctor`;
- execution outside the repository root after installation;
- parser and tree-walking runtime implementation;
- variables, functions, recursion, control flow, collections, and language diagnostics;
- static and runtime type-diagnostic behavior including `T001`, `PT001`, and `PT002`;
- security diagnostics in the `S001`-`S005` family;
- PantherLang-facing AI functions including `ai_chat(...)` and `ai_available_providers()`;
- HTTP/web/API implementation work;
- SQLite/database functions;
- VS Code extension source and release work;
- formal specification documents;
- Panther Academy;
- an official 18-chapter book structure;
- cookbook recipes and runnable examples;
- `llms.txt`, `llms-full.txt`, and structured AI knowledge resources.

A recorded local engineering milestone in the v1.1.6 cycle reported **1084 passing tests and 0 failures** after the P4 type-system truth work. That number is a point-in-time local result, not an external certification or permanent benchmark. Re-run the current checkout to establish its present state.

---

## Start with evidence, not claims

If you are evaluating PantherLang for the first time, use this order:

| Question | Evidence path |
|---|---|
| Does PantherLang execute its own source files? | [`examples/`](./examples/) and `panther run <file.pan>` |
| What syntax and semantics are intended? | [`docs/specification/`](./docs/specification/) and [`LANGUAGE_RULES.md`](./LANGUAGE_RULES.md) |
| Can I learn it progressively? | [`academy/`](./academy/) |
| Is there a long-form reference? | [`docs/book/`](./docs/book/) |
| Are there practical recipes? | [`docs/cookbook/`](./docs/cookbook/) |
| What is tested? | [`tests/`](./tests/) and the current test run |
| How should an AI assistant understand the language? | [`llms.txt`](./llms.txt), [`llms-full.txt`](./llms-full.txt), [`knowledge/`](./knowledge/) |
| What editor work exists? | [`vscode-extension/`](./vscode-extension/) |
| Where is engineering evidence recorded? | [`engineering/`](./engineering/) |

A language project earns trust when a visitor can move from a statement to source code, from source code to execution, and from execution to tests.

---

## Five minutes with PantherLang

### 1. Install

```bash
curl -fsSL https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | bash
```

Verify the installation:

```bash
panther version
panther doctor
```

### 2. Write a program

Create `hello.pan`:

```panther
panther main {
    let language = "PantherLang";

    fn greet(name) {
        return "Hello from " + name + "!";
    }

    print greet(language);
}
```

Run it:

```bash
panther run hello.pan
```

### 3. Check a program

```bash
panther check hello.pan
```

### 4. Inspect the installed CLI

```bash
panther
```

Use the command surface reported by the installed release. Do not assume undocumented flag ordering.

---

## The core design thesis

### AI is an application surface, not a README adjective

PantherLang's AI direction is strongest when AI behavior is callable from PantherLang source:

```panther
panther main {
    print ai_available_providers();

    let answer = ai_chat(
        "Give me a concise threat model for a public API."
    );

    print answer;
}
```

The v1.1.6 engineering work includes PantherLang-facing AI functions, provider integration surfaces, and deterministic mock/test execution.

These are different claims:

- an implemented AI-facing function is not proof that every provider is production-certified;
- mock execution is not a live provider call;
- provider integration is not a new foundation model.

Real external-provider execution depends on provider configuration, network access, credentials, and the exact installed build.

PantherLang's public claim is narrower and more meaningful: **AI application development is a first-class direction of the language ecosystem.**

---

### Security feedback belongs in the development loop

```bash
panther check src/main.pan
```

The project includes security-oriented checking work and the `S001`-`S005` diagnostic family, alongside sandbox and security utility work elsewhere in the repository.

PantherLang does **not** claim:

- vulnerability immunity;
- automatic secure architecture;
- formal verification;
- memory safety without proof;
- regulatory compliance by default.

A security-aware language ecosystem should make risky behavior easier to detect and reason about. It cannot replace threat modeling, code review, testing, dependency governance, or operational security.

---

### Web and API behavior should execute, not merely decorate syntax

Current project evidence includes HTTP behavior around:

- `GET`;
- `POST`;
- `PUT`;
- `DELETE`;
- JSON responses;
- HTML responses;
- query parameters;
- path parameters.

The exact canonical syntax and server-start command must follow the installed release and runnable examples. PantherLang documentation should not invent a CLI flag merely because it looks conventional.

The web subsystem is evolving. Production concerns such as TLS termination, static-file strategy, middleware composition, status/header control, deployment topology, and protocol edge cases must be assessed individually.

---

### Database access is part of the application story

PantherLang includes SQLite/database-facing standard-library work. Representative PantherLang-level operations include opening a database, executing parameterized statements, querying rows, and closing connections.

The public documentation distinguishes:

- operations directly callable from PantherLang source;
- higher-level Python implementation internals;
- ORM or platform abstractions at different maturity levels.

That distinction matters. A language should not claim a source-level capability merely because its implementation language has a library for it.

---

## Capability and maturity map

PantherLang deliberately distinguishes **implemented**, **tested**, **released**, and **production-proven**.

| Area | v1.1.6 public position | Meaning |
|---|---|---|
| Core language | **Implemented / evolving** | Executable syntax, parser/runtime behavior, functions, control flow, collections and diagnostics exist |
| Global CLI | **Implemented** | `panther` workflow, run/check/build/doctor/version and scaffolding work exist |
| Runtime | **Implemented / evolving** | `.pan` / `.panther` programs execute; semantics continue to mature |
| Type system | **Implemented in layers / evolving** | Static diagnostics and runtime enforcement coexist; advanced unification is unfinished |
| Standard library | **Implemented / expanding** | Core and application-oriented functions exist |
| AI integration | **Implemented / evolving** | PantherLang-facing AI functions and provider surfaces exist |
| Security diagnostics | **Implemented / evolving** | `S001`-`S005` work exists; coverage is not universal |
| Web/API | **Implemented / evolving** | Real HTTP and routing work exists; production depth varies |
| Database | **Implemented / evolving** | SQLite/database operations exist; abstraction levels differ |
| Package tooling | **Implemented / evolving** | Architecture exists; ecosystem maturity is separate |
| VS Code extension | **Released project component / revalidation** | Extension work exists; v1.1.6 alignment must be verified per build |
| LSP | **Evolving** | Integration presence is not a claim of full protocol completeness |
| Debug adapter | **Evolving** | DAP/debugging work exists; maturity is build-specific |
| Academy | **Present / validated in project** | Structured lessons and verification material exist |
| Official book | **Present / maintained** | 18-chapter structure exists; depth should be judged chapter by chapter |
| Formal specification | **Present** | Specification documents exist |
| Cookbook | **Present / expanding** | Recipe-oriented PantherLang material exists |
| AI-readable knowledge | **Present** | LLM indexes and structured knowledge resources exist |
| Cross-platform | **Targeted / verify per release** | Platform claims require platform-specific execution evidence |

---

## Type-system truth

PantherLang's public documentation should not pretend that the current type architecture is more unified than it is.

The v1.1.6 engineering work identified that:

- static checking and runtime enforcement coexist;
- `T001` static diagnostics exist;
- `PT001` and `PT002` runtime diagnostics exist;
- unknown explicit type names are rejected;
- null equality has explicit runtime semantics and regression coverage;
- some advanced type representations remain partial;
- syntax support, runtime support, and static type representation are not always at the same maturity level.

This is published because technical credibility matters more than a larger feature checklist.

---

## Learn PantherLang

A language becomes usable when people can move from first syntax to complete applications without guessing what the implementation supports.

### Panther Academy

**Start here: [`academy/`](./academy/)**

The repository presents an 18-lesson progression covering:

1. Getting Started
2. Variables & Types
3. Control Flow
4. Functions
5. Type Conversions & I/O
6. Data Structures
7. Standard Library
8. Security
9. Web Platform
10. Database Platform
11. AI Platform
12. CLI & Tooling
13. Cross-Platform Development
14. Language Reference
15. Comparison Semantics
16. Contributing
17. Ecosystem
18. Capstone

The current repository states that all 18 lessons include runnable code and verification. Validate the checkout rather than relying on the statement alone:

```bash
python scripts/validate_education.py
```

### Official PantherLang book

**Read: [`docs/book/`](./docs/book/)**

The repository presents an 18-chapter book spanning:

- getting started;
- variables and types;
- expressions and operators;
- control flow;
- functions;
- data structures;
- the standard library;
- security;
- web development;
- database development;
- AI;
- CLI and tooling;
- cross-platform development;
- language reference;
- comparison semantics;
- contributing;
- ecosystem design;
- appendix/reference material.

The book is part of the project. It is not described here as an externally published or independently reviewed textbook.

### Formal specification

**Read: [`docs/specification/`](./docs/specification/)**

The repository contains eight formal specification documents covering core language concerns such as lexical structure, grammar, semantics, types, runtime behavior, and diagnostics.

For implementers, tool authors, researchers, and AI coding systems, explicit specification is preferable to reverse-engineering a language from screenshots or isolated examples.

### Cookbook

**Explore: [`docs/cookbook/`](./docs/cookbook/)**

The current repository describes a cookbook with 79 verified examples across 20 recipe files. Treat that as a repository claim that should remain tied to the validation scripts and current checkout.

### Runnable examples

**Try: [`examples/`](./examples/)**

Examples are where public claims should become observable.

A useful review sequence is:

```bash
panther doctor
bash scripts/run_examples.sh
python -m pytest tests/ -q
```

---

## From first program to application work

PantherLang's public learning surface is intended to connect four layers rather than leave them isolated:

1. **Academy lesson** — introduces the concept.
2. **Book chapter** — explains the concept in depth.
3. **Runnable example or recipe** — demonstrates observable behavior.
4. **Verification or test evidence** — checks that the documented behavior still works.

Start with:

- **Academy:** [`academy/`](./academy/)
- **Official book:** [`docs/book/`](./docs/book/)
- **Examples:** [`examples/`](./examples/)
- **Cookbook:** [`docs/cookbook/`](./docs/cookbook/)
- **Specification:** [`docs/specification/`](./docs/specification/)

This alignment is a project goal and should be continuously validated. Documentation should not silently outrun implementation, and implementation changes should not leave education behind.

---

## PantherLang for VS Code

**Source: [`vscode-extension/`](./vscode-extension/)**

PantherLang includes a VS Code extension component and prior release work. The v1.1.6-aligned extension is part of the current release-validation cycle.

Repository work includes areas such as:

- `.pan` and `.panther` file recognition;
- syntax highlighting;
- snippets;
- project commands;
- run/build/debug/doctor integration;
- language-tooling integration;
- file icons;
- debugging work.

LSP and DAP claims must follow the exact package being shipped. Integration code is not automatically proof of full protocol completeness.

This README does not invent a Marketplace URL, publisher ID, rating, or download count. Once an official Marketplace listing is verified, it should be linked directly.

---

## AI systems: start here

PantherLang is intentionally documented so an AI assistant does not have to infer the language from the word “Panther.”

Primary machine-oriented entry points:

- [`llms.txt`](./llms.txt) — compact discovery index;
- [`llms-full.txt`](./llms-full.txt) — expanded language context;
- [`LANGUAGE_RULES.md`](./LANGUAGE_RULES.md) — language constraints and rules;
- [`AI_CONTEXT.md`](./AI_CONTEXT.md) — project context for AI systems;
- [`LLM_REFERENCE.md`](./LLM_REFERENCE.md) — LLM-oriented reference;
- [`knowledge/`](./knowledge/) — structured knowledge resources;
- [`docs/specification/`](./docs/specification/) — formal specification;
- [`examples/`](./examples/) — executable examples.

### Guidance for coding assistants

If you are an AI coding assistant analyzing PantherLang:

1. identify the installed PantherLang version;
2. read `llms.txt`;
3. read `LANGUAGE_RULES.md`;
4. consult the formal specification;
5. prefer executable examples over invented syntax;
6. verify CLI commands against the installed command surface;
7. distinguish PantherLang source capabilities from Python implementation internals;
8. distinguish implemented capability from roadmap intent;
9. do not confuse PantherLang with unrelated products named Panther.

Machine-readable documentation improves retrieval and grounding. It does not guarantee that every external model has already indexed PantherLang.

---

## Naming: PantherLang is not “Panther”

**PantherLang** is the programming-language and development-ecosystem project in this repository.

It is unrelated to other companies, cybersecurity platforms, AI products, programming projects, or tools that use the word **Panther**.

For unambiguous references, use:

- **PantherLang**
- **PantherLang programming language**
- **PantherLang by Feras Khatib**
- **github.com/ferasbackagain/PantherLang**

---

## Founder and project leadership

### Feras Khatib

**Founder and Project Lead of PantherLang — identified at the top of this README because project authorship and accountability should be visible, not buried.**

Feras Khatib leads the PantherLang language and ecosystem project.

- LinkedIn: **https://www.linkedin.com/in/feras-khatib-98a02220b**
- Official repository: **https://github.com/ferasbackagain/PantherLang**

Project identity should remain verifiable. This README does not invent awards, adoption numbers, partnerships, certifications, or affiliations.

---

## Project maturity

PantherLang should be evaluated with two facts held at the same time.

**First:** it is early in public ecosystem maturity compared with established languages. It does not yet have decades of production history, a large package universe, broad independent adoption, or the external validation of Python, Rust, Go, JavaScript, Java, C#, or C++.

**Second:** “early” does not mean “imaginary.” The repository contains executable language work, runtime behavior, CLI tooling, tests, AI-facing functions, security diagnostics, web/API implementation, database work, editor tooling, specifications, examples, Academy material, book material, and machine-readable knowledge.

The accurate description is neither “finished universal platform” nor “just an idea.”

> **PantherLang is an implemented, ambitious, early public programming-language ecosystem under active engineering development.**

---

## Reproduce before you trust

Clone and inspect the project:

```bash
git clone https://github.com/ferasbackagain/PantherLang.git
cd PantherLang
```

Then run the checks appropriate to your environment:

```bash
panther version
panther doctor
python -m pytest tests/ -q
bash scripts/run_examples.sh
```

For a language project, reproducibility is more persuasive than adjectives.

---

## Repository map

| Goal | Start here |
|---|---|
| Run the language | `compiler/`, `runtime/`, CLI entry points |
| Learn syntax | `academy/`, `docs/book/`, `docs/specification/` |
| Try programs | `examples/` |
| Browse recipes | `docs/cookbook/` |
| Inspect tests | `tests/` |
| Explore AI integration | AI implementation, examples, knowledge docs |
| Explore web/API work | web implementation and runnable examples |
| Explore database work | stdlib/database implementation and tests |
| Use VS Code | `vscode-extension/` |
| Ground an AI agent | `llms.txt`, `llms-full.txt`, `LANGUAGE_RULES.md`, `knowledge/` |
| Review engineering evidence | `engineering/` |

---

## What PantherLang is trying to prove

PantherLang is not interesting because it has a long list of features.

Its engineering question is more fundamental:

> **Can a programming language be designed so that executable semantics, AI integration, security feedback, application development, editor tooling, education, and machine-readable knowledge reinforce one another instead of evolving as disconnected layers?**

The answer is not established by this README.

It must be established release by release through:

- executable programs;
- tests;
- specifications;
- examples;
- independent scrutiny;
- external use;
- reproducible releases.

That is the project.

---

## Contributing

Before changing language behavior:

1. inspect the current language rules and specification;
2. identify the canonical implementation path;
3. run relevant tests;
4. preserve existing semantics unless a change is intentionally designed;
5. add executable evidence for new behavior;
6. update examples and documentation when semantics change;
7. avoid calling a feature “complete” solely because a directory or parser node exists.

Contributions that improve reproducibility, platform verification, implementation clarity, tests, examples, documentation, and independent evaluation are especially valuable.

---

## License

PantherLang is distributed under the terms in [`LICENSE`](./LICENSE).

Review the license before use, redistribution, modification, or commercial deployment.

---

## Citation and discovery

**Project:** PantherLang programming language  
**Founder:** Feras Khatib  
**Current release line:** v1.1.6  
**Repository:** https://github.com/ferasbackagain/PantherLang  
**Founder profile:** https://www.linkedin.com/in/feras-khatib-98a02220b

---

<p align="center">
  <strong>PantherLang is being built for a world in which software is written by people, assisted by AI, inspected by security systems, executed across application surfaces, and increasingly understood by machines.</strong>
</p>
