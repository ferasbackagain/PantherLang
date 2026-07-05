panther main {
    print "=== Lesson 12: CLI & Tooling ===";
    print "";
    
    print "--- CLI Reference ---";
    print "";
    print "Command                 | Description";
    print "------------------------|-------------";
    print "panther run <file>      | Execute a .panther/.pan file";
    print "panther run --serve <file>| Execute with HTTP server";
    print "panther build <file>    | Build to shell artifact script";
    print "panther check <file>    | Syntax validation (no execution)";
    print "panther fmt <file>      | Validate and print source";
    print "panther new console <name>| Scaffold console project";
    print "panther new web <name>  | Scaffold web project";
    print "panther new api <name>  | Scaffold API project";
    print "panther new ai <name>   | Scaffold AI project";
    print "panther doctor          | Verify all system components";
    print "panther version         | Show version information";
    print "";
    
    print "--- VS Code Extension ---";
    print "The extension at vscode-extension/ provides:";
    print "  - Syntax highlighting for .panther and .pan files";
    print "  - Code snippets (pn-main, pn-fn, pn-let, etc.)";
    print "  - Debug adapter protocol support";
    print "  - LSP server integration";
    print "";
    print "Install from repository:";
    print "  cd vscode-extension";
    print "  npm install && npm run package";
    print "  code --install-extension pantherlang-1.1.5.vsix";
    print "";
    
    print "--- Project Templates ---";
    print "panther new console my_app    # Creates main.pan with panther main { }";
    print "panther new web my_web_app    # Creates web project structure";
    print "panther new api my_api        # Creates API project structure";
    print "panther new ai my_ai_app      # Creates AI project structure";
    print "";
    
    print "--- Formatter ---";
    print "panther fmt formats and validates code:";
    print "  panther fmt main.pan";
    print "";
    
    print "--- LSP Server ---";
    print "Language Server Protocol server for IDE integration:";
    print "  tools/panther-lsp/";
    print "";
    
    print "--- Debugger ---";
    print "Debug Adapter Protocol support for VS Code:";
    print "  tools/debugger/";
    print "";
    
    print "--- Cross-Platform Scripts ---";
    print "Repository includes runner scripts:";
    print "  scripts/run_examples.sh      # Linux/macOS";
    print "  scripts/run_examples.ps1     # Windows PowerShell";
    print "  scripts/run_examples.bat     # Windows Command Prompt";
    print "";
    
    print "=== Lesson 12 Complete ===";
}