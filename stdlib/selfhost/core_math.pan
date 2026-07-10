panther main {
    fn abs(x) {
        if x < 0 {
            return -x;
        }
        return x;
    }

    fn pow(base, exp) {
        return base ** exp;
    }

    fn sqrt(x) {
        return x ** 0.5;
    }

    fn floor(x) {
        let i = to_int(x);
        if to_float(i) > x {
            return i - 1;
        }
        return i;
    }

    fn ceil(x) {
        let i = to_int(x);
        if to_float(i) < x {
            return i + 1;
        }
        return i;
    }
}
