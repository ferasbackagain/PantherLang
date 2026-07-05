panther main {
    fn factorial(n) {
        if n <= 1 {
            return 1;
        }
        return n * factorial(n - 1);
    }

    fn add(a, b) {
        return a + b;
    }

    fn greet(name) {
        return "Hello, " + name;
    }

    print greet("Panther");
    print "5! = " + string(factorial(5));
    print "add(10, 20) = " + string(add(10, 20));

    // recursion
    fn fib(n) {
        if n <= 1 {
            return n;
        }
        return fib(n - 1) + fib(n - 2);
    }
    print "fib(10) = " + string(fib(10));

    // fn with multiple params
    fn sum_range(start, end) {
        let s = 0;
        for i in start..end {
            s = s + i;
        }
        return s;
    }
    print "sum 1..10 = " + string(sum_range(1, 10));
}
