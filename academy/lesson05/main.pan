panther main {
    print "===== Type Conversions & IO =====";

    // String to int
    let a = int("42");
    print string(a);

    // String to float
    let b = float("3.14");
    print string(b);

    // Num to string
    let c = string(100);
    print c;

    // String concat with conversions
    print "The answer is " + string(42);

    // Safe division check
    let dividend = 10;
    let divisor = 0;
    if divisor != 0 {
        print string(dividend / divisor);
    } else {
        print "Cannot divide by zero";
    }

    // Filesystem IO
    mkdir("lesson05_test");
    write_file("lesson05_test/hello.txt", "Hello from Lesson 05!");
    let content = read_file("lesson05_test/hello.txt");
    print content;
    if file_exists("lesson05_test/hello.txt") {
        print "File exists";
    }
    remove_file("lesson05_test/hello.txt");
    print "IO operations complete";
}
