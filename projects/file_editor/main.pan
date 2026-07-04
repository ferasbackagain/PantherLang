panther main {
    print "=== PantherLang File Editor ===";
    mkdir("_editor_test");
    write_file("_editor_test/note.txt", "Hello, PantherLang!");
    let content = read_file("_editor_test/note.txt");
    print "Content: " + content;
    write_file("_editor_test/log.txt", "Line 1\nLine 2\nLine 3");
    let lines = read_file("_editor_test/log.txt");
    print "Log:";
    print lines;
    print "Files created: " + string(len(list_dir("_editor_test")));
    remove_file("_editor_test/note.txt");
    remove_file("_editor_test/log.txt");
    remove_file("_editor_test");
    print "=== File Editor Complete ===";
}
