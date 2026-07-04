panther main {
    let dir = "_conformance_test";
    mkdir(dir);
    write_file(dir + "/test.txt", "Hello, Panther!");
    print file_exists(dir + "/test.txt");
    let content = read_file(dir + "/test.txt");
    print content;
    let files = list_dir(dir);
    print len(files);
    remove_file(dir + "/test.txt");
}
