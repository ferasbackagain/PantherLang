panther main {
    let matched = regex_match("[0-9]+", "hello123");
    print "match digits: " + string(matched);

    let no_match = regex_match("[a-z]+", "12345");
    print "no match: " + string(no_match);

    let replaced = regex_replace("[0-9]", "X", "a1b2c3");
    print "replaced: " + replaced;

    let split = regex_split(",", "apple,banana,cherry");
    print "split len: " + string(len(split));
    print "split[0]: " + split[0];
    print "split[1]: " + split[1];

    let email_match = regex_match(".+@.+\\..+", "user@example.com");
    print "email match: " + string(email_match);
}
