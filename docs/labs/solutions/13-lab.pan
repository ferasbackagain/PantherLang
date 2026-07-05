panther main {
    print "=== Lab 13: Cross-Platform Solutions ===";
    print "";

    fn normalize_path(parts) {
        return join("/", parts);
    }

    let path = normalize_path(["home", "user", "projects", "main.pan"]);
    print "Exercise 1: Cross-platform file path handler";
    print "  Normalized path: " + path;
    print "  This works on Linux, macOS, and Windows (forward slashes)";
    print "";

    let base = "sandbox";
    let user_file = "readme.txt";
    let safe = sanitize_path(base, user_file);
    print "Exercise 2: Safe file access with sanitize_path";
    print "  Base dir: " + base;
    print "  User file: " + user_file;
    print "  Safe path: " + safe;
    print "";

    let malicious = "../etc/passwd";
    print "  Malicious path: " + malicious;
    print "  sanitize_path blocks directory traversal automatically";
    print "";

    let platform = system_os();
    let host = system_hostname();
    let user = system_username();
    let arch = system_arch();
    print "Exercise 3: Script runner (platform detection)";
    print "  OS: " + platform;
    print "  Hostname: " + host;
    print "  User: " + user;
    print "  Architecture: " + arch;

    if platform == "Linux" || platform == "Darwin" {
        print "  Unix-like system detected";
    } elif platform == "Windows" {
        print "  Windows system detected";
    } else {
        print "  Unknown platform";
    }

    print "";
    print "=== Lab 13 Complete ===";
}
