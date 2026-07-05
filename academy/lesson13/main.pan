panther main {
    print "=== Lesson 13: Cross-Platform Development ===";
    print "";
    
    print "--- Supported Platforms ---";
    print "PantherLang runs on any system with Python 3.10+:";
    print "  - Linux (Ubuntu, Debian, Fedora, Arch, etc.)";
    print "  - macOS (10.15+)";
    print "  - Windows (10/11 via PowerShell or Command Prompt)";
    print "";
    
    print "--- Cross-Platform Scripts ---";
    print "Repository includes runner scripts for all platforms:";
    print "";
    print "# Linux / macOS";
    print "bash scripts/run_examples.sh";
    print "";
    print "# Windows PowerShell";
    print ".\\scripts\\run_examples.ps1";
    print "";
    print "# Windows Command Prompt";
    print "scripts\\run_examples.bat";
    print "";
    
    print "--- Path Handling ---";
    print "Filesystem functions use Python's pathlib.Path, ensuring correct path separators on all platforms.";
    print "";
    print "let path = \"data/users/alice.txt\";";
    print "// Works correctly on Linux, macOS, and Windows";
    print "";
    
    print "--- CI/CD ---";
    print "Standard CI/CD commands work on all platforms:";
    print "";
    print "pip install -e \".[dev]\"";
    print "python -m pytest";
    print "python -m build";
    print "";
    
    print "--- File Operations ---";
    print "All filesystem operations work cross-platform:";
    print "  mkdir(\"dir\")           # Creates directory";
    print "  write_file(\"f.txt\", \"x\") # Writes file";
    print "  read_file(\"f.txt\")       # Reads file";
    print "  list_dir(\"dir\")         # Lists directory";
    print "  file_exists(\"f.txt\")    # Checks existence";
    print "  remove_file(\"f.txt\")    # Removes file";
    print "";
    
    print "--- Line Endings ---";
    print "PantherLang source files use LF line endings (Unix style).";
    print "The compiler handles both LF and CRLF correctly.";
    print "";
    
    print "=== Lesson 13 Complete ===";
}