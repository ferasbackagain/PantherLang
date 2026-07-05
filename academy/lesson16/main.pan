panther main {
    print "=== Lesson 16: Contributing to PantherLang ===";
    print "";
    
    print "--- Development Setup ---";
    print "1. Fork the repository";
    print "2. Clone your fork: git clone https://github.com/YOUR_USERNAME/PantherLang.git";
    print "3. Install in development mode:";
    print "   pip install -e \".[dev]\"";
    print "4. Run tests: python -m pytest";
    print "";
    
    print "--- Code Style ---";
    print "- Follow existing patterns in the codebase";
    print "- Use type hints where appropriate";
    print "- Run formatter: panther fmt <file>";
    print "- Run linter: python -m ruff check .";
    print "- Run type checker: python -m mypy compiler/";
    print "";
    
    print "--- Testing ---";
    print "- Write tests for new features";
    print "- Ensure all tests pass: python -m pytest";
    print "- Test examples: bash scripts/run_examples.sh";
    print "- Run doctor: python -m cli.panther_cli doctor";
    print "";
    
    print "--- Pull Request Process ---";
    print "1. Create a feature branch";
    print "2. Make changes with clear commits";
    print "3. Update documentation if needed";
    print "4. Ensure tests pass";
    print "5. Submit PR with description";
    print "";
    
    print "--- Areas for Contribution ---";
    print "- Compiler: lexer, parser, semantic, types, runtime";
    print "- Stdlib: add new functions";
    print "- Security: new diagnostics, sandbox improvements";
    print "- Web: routing, middleware, server";
    print "- AI: providers, agents, RAG";
    print "- Database: ORM, migrations, query builder";
    print "- Tools: formatter, LSP, debugger, VS Code extension";
    print "- Documentation: Academy, Book, Cookbook, API docs";
    print "- Tests: unit, integration, conformance";
    print "- Examples: new runnable examples";
    print "";
    
    print "--- Reporting Issues ---";
    print "Use GitHub Issues for:";
    print "- Bug reports with reproduction steps";
    print "- Feature requests with use cases";
    print "- Security vulnerabilities (private disclosure preferred)";
    print "- Documentation improvements";
    print "";
    
    print "--- Community ---";
    print "- Discord: PantherLang community";
    print "- GitHub Discussions";
    print "- Study groups and mentoring";
    print "";
    
    print "=== Lesson 16 Complete ===";
}