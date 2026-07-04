panther main {
    print "Panther Academy Lesson 05 - Explicit Conversion";

    let age = 45;
    let name = "Feras";

    print "No implicit conversion:";
    print "age is stored as:";
    print type_of(age);
    print "name is stored as:";
    print type_of(name);

    print "Explicit conversion result:";
    print println("Founder", name, "age", age);
    print to_string(age);
    print to_int("45") + 5;
}
