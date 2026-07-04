panther main {
    print "=== PantherLang Console Demo ===";
    print "Welcome to the Panther ecosystem!";
    let name = "PantherLang";
    let version = "1.0.0";
    print "Language: " + name + " v" + version;
    fn greet(user) {
        return "Hello, " + user + "!";
    }
    print greet("Developer");
    print "=== Demo Complete ===";
}
