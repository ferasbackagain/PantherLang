panther main {
    print "=== Lesson 15 Verification ===";
    print "";
    
    print "--- Test 1: Same-Type Comparisons ---";
    if 100 == 100 { print "100 == 100: PASS"; } else { print "FAIL"; }
    if 100 != 50 { print "100 != 50: PASS"; } else { print "FAIL"; }
    if 100 > 50 { print "100 > 50: PASS"; } else { print "FAIL"; }
    if 100 < 50 == false { print "100 < 50: PASS"; } else { print "FAIL"; }
    if 100 >= 100 { print "100 >= 100: PASS"; } else { print "FAIL"; }
    if 50 <= 100 { print "50 <= 100: PASS"; } else { print "FAIL"; }
    if "abc" == "abc" { print "string ==: PASS"; } else { print "FAIL"; }
    if "abc" != "xyz" { print "string !=: PASS"; } else { print "FAIL"; }
    if true == true { print "bool ==: PASS"; } else { print "FAIL"; }
    if true != false { print "bool !=: PASS"; } else { print "FAIL"; }
    if null == null { print "null ==: PASS"; } else { print "FAIL"; }
    if null != null == false { print "null !=: PASS"; } else { print "FAIL"; }
    
    print "";
    print "--- Test 2: Explicit Conversion ---";
    if to_int("100") == 100 { print "to_int: PASS"; } else { print "FAIL"; }
    if to_string(100) == "100" { print "to_string: PASS"; } else { print "FAIL"; }
    
    print "";
    print "--- Test 3: Null Comparisons ---";
    if null == "hello" == false { print "null == string: PASS"; } else { print "FAIL"; }
    if null != "hello" { print "null != string: PASS"; } else { print "FAIL"; }
    if null == 42 == false { print "null == int: PASS"; } else { print "FAIL"; }
    if null == true == false { print "null == bool: PASS"; } else { print "FAIL"; }
    
    print "";
    print "=== All Lesson 15 Tests Complete ===";
}