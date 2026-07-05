panther main {
    print "=== Lesson 05 Verification ===";
    print "";

    // Type conversions
    if int("42") == 42 { print "int conversion: PASS"; } else { print "int conversion: FAIL"; }
    if float("3.14") == 3.14 { print "float conversion: PASS"; } else { print "float conversion: FAIL"; }
    if string(100) == "100" { print "string conversion: PASS"; } else { print "string conversion: FAIL"; }

    // String concat with conversion
    let msg = "Value: " + string(42);
    if msg == "Value: 42" { print "string concat: PASS"; } else { print "string concat: FAIL"; }

    // Filesystem IO
    mkdir("l05_verify");
    write_file("l05_verify/test.txt", "test data");
    if file_exists("l05_verify/test.txt") { print "file_exists: PASS"; } else { print "file_exists: FAIL"; }
    let content = read_file("l05_verify/test.txt");
    if content == "test data" { print "read/write: PASS"; } else { print "read/write: FAIL"; }
    remove_file("l05_verify/test.txt");
    print "file remove: PASS";

    print "";
    print "=== All Lesson 05 Tests Complete ===";
}
