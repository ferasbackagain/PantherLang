panther main {
    print "=== Lesson 17: The Panther Ecosystem ===";
    print "";
    
    print "--- Project Templates ---";
    print "Ready-to-use project scaffolding:";
    print "  panther new console my_app    # Console application";
    print "  panther new web my_web_app    # Web application";
    print "  panther new api my_api        # REST API";
    print "  panther new ai my_ai_app      # AI-powered application";
    print "";
    print "Each template includes:";
    print "  - main.pan with proper structure";
    print "  - panther.toml configuration";
    print "  - .vscode/ for IDE integration";
    print "  - tests/ for testing";
    print "  - README.md with guidance";
    print "";
    
    print "--- Package Registry ---";
    print "PantherLang package system for dependency management:";
    print "  - Local packages with panther.toml";
    print "  - Registry at registry/ for published packages";
    print "  - Lock files for reproducible builds";
    print "  - Security scanning for dependencies";
    print "";
    
    print "--- VS Code Extension ---";
    print "Full IDE support:";
    print "  - Syntax highlighting";
    print "  - Code snippets (pn-main, pn-fn, pn-let, pn-if, etc.)";
    print "  - Debug adapter (breakpoints, variables, call stack)";
    print "  - LSP integration (hover, completion, diagnostics)";
    print "  - Project wizard for new projects";
    print "";
    
    print "--- CI/CD Integration ---";
    print "Cross-platform CI scripts:";
    print "  - Linux/macOS: bash scripts/";
    print "  - Windows: PowerShell (.ps1) and Batch (.bat)";
    print "  - GitHub Actions compatible";
    print "";
    
    print "--- Documentation ---";
    print "Comprehensive documentation at docs/:";
    print "  - Academy: structured lessons";
    print "  - Book: language reference";
    print "  - Cookbook: practical recipes";
    print "  - Specification: formal language spec";
    print "";
    
    print "--- Distribution ---";
    print "PyPI package: pip install pantherlang";
    print "Source: pip install -e \".[dev]\"";
    print "VS Code extension: .vsix package";
    print "";
    
    print "=== Lesson 17 Complete ===";
}