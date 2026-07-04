panther main {
    let name = "PantherLang";
    let year = 2026;
    let version = "1.0.0";
    let is_fun = true;

    print "Hello from " + name;
    print "Year: " + string(year);
    print "Version: " + version;
    print "Is programming fun? " + string(is_fun);

    fn greet(msg) {
        return "Greetings: " + msg;
    }

    print greet("welcome to the Panther ecosystem");
}
