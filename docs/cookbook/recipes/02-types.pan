panther main {
    let i = int("42");
    let f = float("3.14");
    let s = string(100);
    if i == 42 { print "int: PASS"; }
    if f == 3.14 { print "float: PASS"; }
    if s == "100" { print "string: PASS"; }
    let null_val = null;
    print "null: " + string(null_val);
    let flag = true;
    print "bool: " + string(flag);
}
