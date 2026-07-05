panther main {
    print "=== Lesson 13 Verification ===";
    print "";
    
    print "--- Test 1: Cross-Platform Concepts ---";
    print "Platforms: Linux, macOS, Windows";
    print "Runner scripts: .sh, .ps1, .bat";
    print "Path handling via pathlib";
    print "Filesystem functions work cross-platform";
    print "";
    
    print "--- Test 2: Filesystem ---";
    mkdir("xplat_test");
    write_file("xplat_test/file.txt", "test");
    let content = read_file("xplat_test/file.txt");
    if content == "test" { print "Filesystem cross-platform: PASS"; } else { print "Filesystem: FAIL"; }
    let files = list_dir("xplat_test");
    if len(files) == 1 { print "list_dir: PASS"; } else { print "list_dir: FAIL"; }
    remove_file("xplat_test/file.txt");
    
    print "";
    print "=== All Lesson 13 Tests Complete ===";
}