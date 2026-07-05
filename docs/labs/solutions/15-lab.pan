panther main {
    print "=== Lab 15: Comparison Semantics Solutions ===";
    print "";

    print "Exercise 1: Comparison expressions for each type";
    print "";

    let a = 10;
    let b = 20;
    let c = 10;
    print "  int: " + string(a) + " == " + string(b) + " -> " + string(a == b);
    print "  int: " + string(a) + " != " + string(b) + " -> " + string(a != b);
    print "  int: " + string(a) + " < " + string(b) + " -> " + string(a < b);
    print "  int: " + string(a) + " <= " + string(c) + " -> " + string(a <= c);
    print "  int: " + string(b) + " > " + string(a) + " -> " + string(b > a);
    print "  int: " + string(b) + " >= " + string(c) + " -> " + string(b >= c);
    print "";

    let x = 3.14;
    let y = 2.71;
    print "  float: " + string(x) + " > " + string(y) + " -> " + string(x > y);
    print "  float: " + string(x) + " == " + string(x) + " -> " + string(x == x);
    print "";

    let s1 = "hello";
    let s2 = "world";
    let s3 = "hello";
    print "  string: " + s1 + " == " + s2 + " -> " + string(s1 == s2);
    print "  string: " + s1 + " == " + s3 + " -> " + string(s1 == s3);
    print "  string: " + s1 + " != " + s2 + " -> " + string(s1 != s2);
    print "";

    let flag1 = true;
    let flag2 = false;
    print "  bool: " + string(flag1) + " == " + string(flag2) + " -> " + string(flag1 == flag2);
    print "  bool: " + string(flag1) + " != " + string(flag2) + " -> " + string(flag1 != flag2);
    print "";

    print "Exercise 2: Convert and compare (int to float)";
    print "";

    let int_val = 42;
    let float_val = 42.0;
    let diff_float = 3.14;
    print "  int " + string(int_val) + " vs float " + string(float_val);
    print "  float(int_val) == float_val: " + string(float(int_val) == float_val);
    print "  float(int_val) == diff_float: " + string(float(int_val) == diff_float);
    print "  int(diff_float) == int_val: " + string(int(diff_float) == int_val);
    print "";

    print "Exercise 3: Null semantics";
    print "";

    let n = null;
    print "  null == null: " + string(n == null);
    print "  null == 0: " + string(n == 0);
    print "  null == false: " + string(n == false);
    print "  null == \"\": " + string(n == "");
    print "  null != 0: " + string(n != 0);
    print "";

    print "  null compared to different types only equals null";

    print "=== Lab 15 Complete ===";
}
