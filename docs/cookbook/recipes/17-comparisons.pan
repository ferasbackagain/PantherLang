panther main {
    // same-type comparisons
    if 5 == 5 { print "int ==: PASS"; }
    if 5 != 3 { print "int !=: PASS"; }
    if 5 > 3 { print "int >: PASS"; }
    if 3 < 5 { print "int <: PASS"; }
    if 5 >= 5 { print "int >=: PASS"; }
    if 5 <= 5 { print "int <=: PASS"; }

    if "abc" == "abc" { print "str ==: PASS"; }
    if "abc" != "xyz" { print "str !=: PASS"; }

    if true == true { print "bool ==: PASS"; }
    if false != true { print "bool !=: PASS"; }

    if 3.14 == 3.14 { print "float ==: PASS"; }
    if 3.14 < 4.0 { print "float <: PASS"; }

    let x = 10;
    let y = 20;
    let max_val = x;
    if y > x {
        max_val = y;
    }
    print "max: " + string(max_val);
    print "comparisons: all pass";
}
