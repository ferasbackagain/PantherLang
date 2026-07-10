panther main {
    print("=== PantherLang File Manager ===");

    // Create a working directory
    let work_dir = fs_join(fs_tempdir(), "panther_file_test");
    fs_mkdir(work_dir);
    print("Work dir: " + work_dir);

    // Create files
    let file1 = fs_join(work_dir, "hello.txt");
    let file2 = fs_join(work_dir, "data.json");
    fs_write(file1, "Hello, PantherLang!");
    fs_write(file2, "{\"name\": \"Panther\", \"version\": 1.16}");
    print("Created: " + fs_basename(file1));
    print("Created: " + fs_basename(file2));

    // Verify with stat
    let s1 = fs_stat(file1);
    print("File1 size: " + to_string(s1["size"]) + " bytes");
    print("File1 ext:  " + fs_extension(file1));

    // Read back
    let content = fs_read(file1);
    print("Read: " + content);

    // Append
    fs_append(file1, " Appended line.");
    let content2 = fs_read(file1);
    print("After append: " + content2);

    // List directory
    print("");
    print("Directory listing:");
    let entries = fs_listdir(work_dir);
    for i in 0..len(entries)-1 {
        let entry_path = fs_join(work_dir, entries[i]);
        let is_file = fs_is_file(entry_path);
        let label = "FILE";
        if !is_file {
            label = "DIR ";
        };
        print("  [" + label + "] " + entries[i]);
    };

    // Walk directory
    print("");
    print("Walk (1 level):");
    let walked = fs_walk(work_dir);
    for i in 0..len(walked)-1 {
        let w = walked[i];
        let type_label = "FILE";
        if w["is_dir"] {
            type_label = "DIR ";
        };
        print("  [" + type_label + "] " + fs_basename(w["path"]));
    };

    // Copy and rename
    let copy_path = fs_join(work_dir, "hello_copy.txt");
    fs_copy(file1, copy_path);
    print("");
    print("Copied: " + fs_basename(copy_path));

    let renamed = fs_join(work_dir, "renamed.txt");
    fs_rename(copy_path, renamed);
    print("Renamed to: " + fs_basename(renamed));
    print("Exists renamed: " + to_string(fs_exists(renamed)));

    // Cleanup
    print("");
    print("Cleaning up...");
    fs_remove(work_dir);
    print("Dir removed: " + to_string(!fs_exists(work_dir)));

    print("");
    print("=== File Manager Complete ===");
}
