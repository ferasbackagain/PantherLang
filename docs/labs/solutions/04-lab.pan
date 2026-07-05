panther main {
    fn is_even(n) {
        if n % 2 == 0 {
            return true;
        }
        return false;
    }
    print is_even(4);
    print is_even(7);

    fn sum_to(n) {
        if n <= 1 {
            return n;
        }
        return n + sum_to(n - 1);
    }
    print sum_to(5);
    print sum_to(100);

    fn celsius_to_fahrenheit(c) {
        return c * 9.0 / 5 + 32;
    }
    print celsius_to_fahrenheit(0);
    print celsius_to_fahrenheit(100);
    print celsius_to_fahrenheit(37);
}
