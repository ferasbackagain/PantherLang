panther main {
    let s = "  Hello, PantherLang!  ";
    print "len: " + string(len(s));
    print "upper: " + upper(s);
    print "lower: " + lower(s);
    print "trim: '" + trim(s) + "'";
    print "contains 'Panther': " + string(contains(s, "Panther"));
    print "starts_with '  He': " + string(starts_with(s, "  He"));
    print "ends_with '!  ': " + string(ends_with(s, "!  "));
    print "replace: " + replace(s, "Panther", "Python");
    print "substring(2, 9): " + substring(s, 2, 9);
    let parts = split("a,b,c", ",");
    print "split[0]: " + parts[0] + " [1]: " + parts[1] + " [2]: " + parts[2];
    print "join: " + join(", ", ["apple", "banana", "cherry"]);
}
