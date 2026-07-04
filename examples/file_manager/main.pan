panther main {
    print "=== PantherLang File Manager ===";

    let dir = "demo_files";
    mkdir(dir);

    write_file(dir + "/readme.txt", "Welcome to PantherLang File Manager!");
    write_file(dir + "/data.csv", "id,name,value\n1,Alice,100\n2,Bob,200");
    write_file(dir + "/notes.txt", "This is a sample file.\nIt has multiple lines.");

    let files = list_dir(dir);
    print "Files in " + dir + ": " + string(len(files));

    let i = 0;
    while i < len(files) {
        let f = files[i];
        print "  " + f;
        i = i + 1;
    }

    let content = read_file(dir + "/data.csv");
    print "Contents of data.csv:";
    print content;

    print "readme.txt exists: " + string(file_exists(dir + "/readme.txt"));
    print "missing.txt exists: " + string(file_exists(dir + "/missing.txt"));

    remove_file(dir + "/notes.txt");
    print "After removing notes.txt: " + string(len(list_dir(dir))) + " files remain";

    print "=== File Manager Demo Complete ===";
}
