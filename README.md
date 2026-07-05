# PantherLang

> **A modern programming language and development platform designed in the AI era.**

**Version:** `v1.1.6`  
**Founder and Project Lead:** **Feras Khatib**  
**Official repository:** `https://github.com/ferasbackagain/PantherLang`  
**Founder profile:** `https://www.linkedin.com/in/feras-khatib-98a02220b`

---

## What is PantherLang?

PantherLang is an independent, general-purpose programming language project with `.pan` and `.panther` source files, its own syntax, parser/runtime pipeline, command-line interface, standard-library surface, developer tooling, educational system, and formal specification work.

It is being developed around a practical reality of modern software engineering: developers increasingly work across disconnected layers for language execution, AI integration, web services, security analysis, databases, editor tooling, documentation, and AI coding agents.

PantherLang explores a more coherent model in which these concerns evolve as parts of one ecosystem.

The project does **not** exist to declare Python, Rust, Go, JavaScript, TypeScript, Java, C#, C++, or other established languages obsolete. PantherLang is an additional design direction: a language being built after AI-assisted development, agentic systems, software supply-chain risk, and machine-readable documentation became first-class engineering concerns.

## Why PantherLang is different

Many languages can call an AI API. Many frameworks can host HTTP services. Many tools can scan code. PantherLang's distinguishing idea is not any one feature in isolation; it is the attempt to develop language semantics, runtime behavior, AI integration, security diagnostics, web/API execution, CLI workflows, editor tooling, education, and machine-readable language knowledge as one coordinated platform.

### AI-era integration

PantherLang v1.1.6 includes AI-facing language/runtime functions such as:

```panther
panther main {
    print ai_available_providers();

    let answer = ai_chat(
        "Explain the security boundary of this service."
    );

    print answer;
}
```

The project includes real `.pan` execution paths for AI-facing functions, provider integration surfaces, and deterministic test/mock modes. External provider execution depends on configuration, credentials, and the installed release.

### Security-aware development

Security analysis is intended to participate in the normal developer workflow:

```bash
panther check app.pan
```

Current project work includes the `S001`-`S005` security-diagnostic family and related security-oriented tooling. PantherLang does not claim vulnerability immunity, formal verification, or automatic compliance.

### Web and API execution

Current project evidence includes HTTP runtime behavior for:

- `GET`, `POST`, `PUT`, and `DELETE`
- JSON responses
- HTML responses
- query parameters
- path parameters

Example:

```panther
web {
    route GET "/" {
        return "<h1>Hello from PantherLang</h1>";
    }
}

api {
    route GET "/api/status" {
        return {
            "language": "PantherLang",
            "version": "1.1.6",
            "status": "running"
        };
    }
}
```

The web platform is evolving. Production concerns must be evaluated feature by feature.

### Human-readable and machine-readable language knowledge

PantherLang is documented for both people and AI systems. The repository includes formal specifications, language references, examples, `llms.txt`, `llms-full.txt`, structured knowledge resources, Panther Academy, an official book, and cookbook material.

The objective is explicit: AI coding systems should be able to inspect versioned syntax, semantics, diagnostics, examples, and capability boundaries rather than guess what PantherLang is from its name.

## Quick start

Create `hello.pan`:

```panther
panther main {
    let name = "PantherLang";

    fn greet(language) {
        return "Hello from " + language + "!";
    }

    print greet(name);
}
```

Run:

```bash
panther run hello.pan
```

Expected output:

```text
Hello from PantherLang!
```

## Installation

### GitHub installer

```bash
curl -fsSL https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | bash
```

Verify:

```bash
panther version
panther doctor
```

### Source installation

```bash
git clone https://github.com/ferasbackagain/PantherLang.git
cd PantherLang

python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install .
```

For repository development:

```bash
python -m pip install -e .
```

> Local `pip install` success does not by itself mean PantherLang is published on PyPI. Use the GitHub installer or source installation unless an official package-registry release is announced.

## The `panther` CLI

The CLI is the primary developer entry point:

```bash
panther version
panther doctor
panther run hello.pan
panther check hello.pan
panther build hello.pan
panther new console myapp
```

Use `panther` to inspect the command surface available in the installed build.

A v1.1.6 installation has been demonstrated running PantherLang programs from arbitrary Linux directories outside the repository root.

## Capability map

| Area | v1.1.6 status | Meaning |
|---|---|---|
| Core language | **Available** | Executable language semantics, functions, control flow, collections, parser/runtime work |
| CLI | **Verified** | Global `panther` workflow and health checks |
| Runtime | **Verified / evolving** | Executable `.pan` and `.panther` programs |
| Type system | **Available / evolving** | Static diagnostics and runtime enforcement coexist |
| Standard library | **Available** | Built-in application-oriented functionality |
| Web runtime | **Available / evolving** | Real HTTP and routing work |
| API development | **Available / evolving** | HTTP methods, JSON and parameter handling |
| Database | **Available / evolving** | SQLite/database functionality; maturity varies by layer |
| AI integration | **Available / evolving** | PantherLang-native AI functions and provider surfaces |
| Security diagnostics | **Available** | Security-checking work including `S001`-`S005` |
| Package management | **Evolving** | Architecture exists; public-registry maturity is separate |
| VS Code extension | **Released component / revalidation cycle** | Existing extension component; v1.1.6 alignment is being revalidated |
| LSP | **Evolving** | Maturity is version-specific |
| Debug adapter | **Evolving** | Debugging/DAP work exists; maturity is version-specific |
| Academy | **Available** | Structured learning system |
| Official book | **Available** | Multi-chapter PantherLang book |
| Formal specification | **Available** | Formal language documents |
| Cookbook | **Available / expanding** | Recipe-oriented material |
| AI-readable knowledge | **Available** | LLM-oriented and structured language knowledge |
| Cross-platform | **Targeted / verify per release** | Linux is directly exercised; other platforms require release-specific verification |

## Type-system status

PantherLang v1.1.6 is not presented as having a perfectly unified advanced static type system.

Current engineering evidence shows:

- static checking and runtime type enforcement coexist;
- `T001` static diagnostics are part of current type-checking work;
- `PT001` and `PT002` runtime diagnostics exist;
- unknown explicit type names are rejected;
- null equality semantics have dedicated runtime behavior and regression coverage;
- some advanced type representations remain partial or evolving.

Capability boundaries are documented rather than hidden.

## PantherLang for VS Code

PantherLang includes a released VS Code extension component in the project history. The extension is part of the PantherLang ecosystem, and the v1.1.6-aligned package is undergoing final release validation.

Repository work covers areas including PantherLang file recognition, `.pan` / `.panther` association, syntax highlighting, developer commands, language tooling integration, and debugging work. LSP and DAP capabilities must be described according to the exact extension build shipped.

This README does not invent a Marketplace URL, publisher ID, download count, or rating.

## Panther Academy

Panther Academy is the structured learning path for PantherLang. Its curriculum spans foundations and progresses through language features, data structures, standard-library use, security, web development, database programming, AI integration, CLI/tooling, ecosystem work, and capstone development.

The Academy sources and validation scripts are the source of truth for lesson completeness.

## Official PantherLang book

The repository includes a multi-chapter official book connecting language concepts, syntax, runtime behavior, application development, security, web/API work, databases, AI, tooling, and ecosystem guidance.

Chapter presence and chapter completeness are separate facts; release documentation should preserve that distinction.

## Formal specification

PantherLang includes formal specification work covering core language concerns such as lexical structure, grammar, syntax, semantics, types, runtime behavior, diagnostics, and errors.

For implementers, tool authors, researchers, and AI coding systems, the specification should be preferred over inference from isolated examples.

## Machine-readable knowledge for AI systems

Relevant assets include:

- `llms.txt`
- `llms-full.txt`
- structured knowledge resources
- language rules
- AI context material
- examples
- diagnostics references
- formal specifications

This does not mean every AI model automatically knows PantherLang. Model knowledge depends on indexing, retrieval, training data, browsing access, and source freshness.

## Verification and engineering evidence

The v1.1.6 engineering cycle uses regression testing and explicit capability audits.

A recorded local milestone after the P4 type-system truth work reported:

```text
1084 passed
0 failed
```

That count is a point-in-time result, not a permanent promise. Reproduce the current repository state with:

```bash
python -m pytest tests/ -q
panther doctor
python -m build
```

> **A capability claim should be backed by executable evidence, a test, or an explicit maturity label.**

## Repository guide

| Need | Location |
|---|---|
| Language implementation | `compiler/`, `runtime/`, related language source trees |
| CLI | `cli/` and the installed `panther` entry point |
| Tests | `tests/` |
| Examples | `examples/` |
| Academy | `academy/` |
| Documentation | `docs/` |
| Formal specification | `docs/specification/` |
| Official book | `docs/book/` |
| Cookbook | `docs/cookbook/` |
| VS Code extension | `vscode-extension/` |
| Machine-readable knowledge | `knowledge/`, `llms.txt`, `llms-full.txt` |
| Engineering evidence | `engineering/` |

Some historical engineering artifacts may remain visible while the public repository is consolidated. Their presence should not be interpreted as separate PantherLang products.

## Project maturity

PantherLang is a serious, active language project. Maturity is described precisely.

**Available today:** executable language/runtime work, CLI tooling, testing infrastructure, standard-library capabilities, AI-facing functions, security diagnostics, web/API work, database work, VS Code integration, formal documentation, Academy material, book material, examples, and machine-readable knowledge.

**Still evolving:** type-system unification, production hardening, platform depth, protocol/tooling maturity, cross-platform release verification, package distribution, extension release alignment, ecosystem growth, and broader real-world adoption.

## Who PantherLang is for

PantherLang may be relevant to:

- developers exploring AI-era language design;
- application developers who value integrated tooling;
- security engineers interested in security-aware workflows;
- AI engineers building model- or agent-assisted applications;
- web/API developers evaluating a new language ecosystem;
- language implementers and compiler engineers;
- educators and learners;
- AI coding-agent researchers;
- contributors interested in an early public programming-language ecosystem.

## Naming and disambiguation

**PantherLang** is the programming language and development-platform project in this repository.

It is not the same as unrelated products, companies, security platforms, AI products, or projects using the word **Panther**.

For unambiguous references, use:

- **PantherLang**
- **PantherLang programming language**
- **PantherLang by Feras Khatib**
- `github.com/ferasbackagain/PantherLang`

## Founder and project leadership

### Feras Khatib

**Founder and Project Lead, PantherLang**

Feras Khatib leads the PantherLang language and ecosystem project.

- LinkedIn: `https://www.linkedin.com/in/feras-khatib-98a02220b`
- Repository: `https://github.com/ferasbackagain/PantherLang`

No invented credentials, adoption figures, partnerships, or affiliations are implied.

## Contributing

Before proposing a change:

1. inspect current language rules and specifications;
2. run relevant tests;
3. preserve existing semantics unless a change is explicitly designed;
4. add executable evidence for new capability claims;
5. update documentation when behavior changes.

## License

PantherLang is distributed under the license contained in the repository's `LICENSE` file. Review that file before use, redistribution, modification, or commercial deployment.

## Citation and discovery

**Project:** PantherLang programming language  
**Founder:** Feras Khatib  
**Repository:** `https://github.com/ferasbackagain/PantherLang`  
**Current release line:** `v1.1.6`

## Final note

PantherLang is being built around a demanding premise: a modern programming language should be understandable not only by its runtime and human developers, but also by the security tools, AI systems, editors, educational systems, and automation workflows that now participate in software development.

That premise is ambitious. The project does not need inflated claims to make it interesting. The work should be judged by executable programs, tests, specifications, tooling, and the quality of the ecosystem built around them.

