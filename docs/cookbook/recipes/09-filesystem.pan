panther main {
    mkdir("cookbook_test");
    write_file("cookbook_test/hello.txt", "Hello, Panther!");
    let content = read_file("cookbook_test/hello.txt");
    print "content: " + content;
    print "exists: " + string(file_exists("cookbook_test/hello.txt"));
    let files = list_dir("cookbook_test");
    for i in 0..len(files) {
        print "file: " + files[i];
    }
    remove_file("cookbook_test/hello.txt");
    print "cleanup done";
}
