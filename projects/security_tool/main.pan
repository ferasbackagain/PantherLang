panther main {
    print "=== PantherLang Security Tool ===";
    let audit_items = ["/etc/passwd", "/tmp/test.txt", "/home/user/.ssh/id_rsa"];
    let blocked = 0;
    let i = 0;
    while i < len(audit_items) {
        let path = audit_items[i];
        if path == "/etc/passwd" {
            print "BLOCKED: " + path;
            blocked = blocked + 1;
        } elif path == "/home/user/.ssh/id_rsa" {
            print "BLOCKED: " + path;
            blocked = blocked + 1;
        } else {
            print "ALLOWED: " + path;
        }
        i = i + 1;
    }
    print "Summary: " + string(len(audit_items)) + " paths, " + string(blocked) + " blocked";
    print "=== Security Tool Complete ===";
}
