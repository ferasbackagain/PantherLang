panther main {
    print "=== Lesson 18: Capstone Project ===";
    print "";
    
    print "--- Capstone: PantherLang Task Manager ---";
    print "Build a complete CLI application demonstrating:";
    print "  - Variables, types, and conversions";
    print "  - Control flow (if, while, for)";
    print "  - Functions with parameters and returns";
    print "  - Data structures (arrays, objects, structs)";
    print "  - Standard library functions";
    print "  - File I/O for persistence";
    print "  - JSON for data storage";
    print "  - SQLite for database";
    print "  - Security (input validation, path safety)";
    print "  - Error handling";
    print "";
    
    print "--- Project Structure ---";
    print "task_manager/";
    print "  main.pan              # Entry point";
    print "  tasks.pan             # Task operations";
    print "  storage.pan           # JSON/SQLite storage";
    print "  ui.pan                # User interface";
    print "  panther.toml          # Project config";
    print "";
    
    print "--- Features to Implement ---";
    print "1. Add task: title, description, priority, due date";
    print "2. List tasks: all, by status, by priority";
    print "3. Complete task: mark done";
    print "4. Delete task: remove permanently";
    print "5. Search tasks: by keyword";
    print "6. Save/load: JSON file or SQLite";
    print "7. Input validation: sanitize all user input";
    print "8. Error handling: graceful failures";
    print "";
    
    print "--- Sample main.pan ---";
    print "panther main {";
    print "    print \"=== PantherLang Task Manager ===\";";
    print "    let storage = Storage(\"tasks.json\");";
    print "    let ui = UI(storage);";
    print "    ui.run();";
    print "}";
    print "";
    
    print "--- Skills Demonstrated ---";
    print "- Project structure and organization";
    print "- Module separation (storage, UI, logic)";
    print "- Data persistence with JSON and SQLite";
    print "- User interaction and menu system";
    print "- Security: input validation, path sanitization";
    print "- Error handling and recovery";
    print "- Code organization and best practices";
    print "";
    
    print "--- Assessment Criteria ---";
    print "1. Functionality: All features work correctly";
    print "2. Code Quality: Clean, organized, documented";
    print "3. Security: Input validation, no hardcoded secrets";
    print "4. Error Handling: Graceful degradation";
    print "5. Testing: Unit tests for core functions";
    print "6. Documentation: README with usage instructions";
    print "";
    
    print "=== Lesson 18 Complete ===";
    print "Congratulations! You've completed the PantherLang Academy.";
}