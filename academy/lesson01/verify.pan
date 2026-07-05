panther main {
    print "=== Lesson 01 Verification ===";
    print "";
    
    // Test arithmetic
    if 10 + 5 * 2 == 20 { print "Precedence: PASS"; } else { print "Precedence: FAIL"; }
    if (10 + 5) * 2 == 30 { print "Parentheses: PASS"; } else { print "Parentheses: FAIL"; }
    
    // Test comparison
    if (10 > 5) == true { print "Greater than: PASS"; } else { print "Greater than: FAIL"; }
    if (10 == 10) == true { print "Equal: PASS"; } else { print "Equal: FAIL"; }
    
    // Test string concat
    if "Hello " + "World" == "Hello World" { print "String concat: PASS"; } else { print "String concat: FAIL"; }
    
    // Test logical
    if (true && false) == false { print "Logical AND: PASS"; } else { print "Logical AND: FAIL"; }
    if (true || false) == true { print "Logical OR: PASS"; } else { print "Logical OR: FAIL"; }
    
    print "";
    print "=== All Lesson 01 Tests Complete ===";
}
