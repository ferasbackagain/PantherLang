panther main {
    let a = 42;
    let b = 7;

    print "PantherLang Calculator";
    print "a = " + string(a) + ", b = " + string(b);

    print "a + b = " + string(a + b);
    print "a - b = " + string(a - b);
    print "a * b = " + string(a * b);
    print "a / b = " + string(a / b);
    print "a % b = " + string(a % b);
    print "a ** 2 = " + string(a ** 2);

    let x = 10;
    let y = 3;
    print "x = " + string(x) + ", y = " + string(y);
    print "x > y: " + string(x > y);
    print "x == y: " + string(x == y);
    print "x < y: " + string(x < y);

    fn factorial(n) {
        if n <= 1 {
            return 1;
        }
        return n * factorial(n - 1);
    }

    print "factorial(5) = " + string(factorial(5));
    print "factorial(7) = " + string(factorial(7));
}
