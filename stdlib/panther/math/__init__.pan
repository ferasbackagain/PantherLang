panther main {
    // Basic math
    fn panther_math_abs(x) {
        if x < 0 {
            return -x;
        }
        return x;
    }

    fn panther_math_min(a, b) {
        if a < b {
            return a;
        }
        return b;
    }

    fn panther_math_max(a, b) {
        if a > b {
            return a;
        }
        return b;
    }

    fn panther_math_add(a, b) {
        return a + b;
    }

    fn panther_math_diff(a, b) {
        return a - b;
    }

    fn panther_math_prod(a, b) {
        return a * b;
    }

    fn panther_math_quot(a, b) {
        if b == 0 {
            return null;
        }
        return a / b;
    }

    fn panther_math_rem(a, b) {
        return a % b;
    }

    fn panther_math_pow(base, exp) {
        return base ** exp;
    }

    fn panther_math_sqrt(x) {
        if x < 0 {
            return null;
        }
        return x ** 0.5;
    }

    fn panther_math_cbrt(x) {
        return x ** (1.0 / 3.0);
    }

    // Rounding
    fn panther_math_floor(x) {
        let i = to_int(x);
        if to_float(i) > x {
            return i - 1;
        }
        return i;
    }

    fn panther_math_ceil(x) {
        let i = to_int(x);
        if to_float(i) < x {
            return i + 1;
        }
        return i;
    }

    fn panther_math_round(x) {
        return round(x);
    }

    fn panther_math_trunc(x) {
        return to_int(x);
    }

    // Clamping and normalization
    fn panther_math_clamp(value, lo, hi) {
        if value < lo {
            return lo;
        }
        if value > hi {
            return hi;
        }
        return value;
    }

    fn panther_math_lerp(a, b, t) {
        return a + (b - a) * t;
    }

    fn panther_math_map(value, in_min, in_max, out_min, out_max) {
        return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
    }

    // Random
    fn panther_math_random() {
        return random();
    }

    fn panther_math_random_int(lo, hi) {
        return randint(lo, hi);
    }

    fn panther_math_random_float(lo, hi) {
        return lo + random() * (hi - lo);
    }

    // Sign and comparison
    fn panther_math_sign(x) {
        if x > 0 {
            return 1;
        }
        if x < 0 {
            return -1;
        }
        return 0;
    }

    fn panther_math_is_even(x) {
        return x % 2 == 0;
    }

    fn panther_math_is_odd(x) {
        return x % 2 != 0;
    }

    fn panther_math_is_prime(n) {
        if n < 2 {
            return false;
        }
        let limit = to_int(sqrt(n)) + 1;
        for i in 2..limit {
            if n % i == 0 {
                return false;
            }
        }
        return true;
    }

    // Statistics - using index-based loops
    fn panther_math_sum(arr) {
        let total = 0;
        let n = len(arr);
        for i in 0..n {
            total = total + arr[i];
        }
        return total;
    }

    fn panther_math_mean(arr) {
        let n = len(arr);
        if n == 0 {
            return 0;
        }
        return panther_math_sum(arr) / n;
    }

    fn panther_math_median(arr) {
        let n = len(arr);
        if n == 0 {
            return 0;
        }
        let sorted = array_sort(arr);
        let mid = n / 2;
        if n % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2.0;
        }
        return sorted[mid];
    }

    fn panther_math_variance(arr) {
        let m = panther_math_mean(arr);
        let sum = 0;
        let n = len(arr);
        for i in 0..n {
            let d = arr[i] - m;
            sum = sum + d * d;
        }
        return sum / n;
    }

    fn panther_math_stddev(arr) {
        return sqrt(panther_math_variance(arr));
    }

    // Constants
    fn panther_math_pi() {
        return 3.141592653589793;
    }

    fn panther_math_e() {
        return 2.718281828459045;
    }

    fn panther_math_tau() {
        return 6.283185307179586;
    }

    // Degree/radian conversion
    fn panther_math_deg_to_rad(deg) {
        return deg * panther_math_pi() / 180.0;
    }

    fn panther_math_rad_to_deg(rad) {
        return rad * 180.0 / panther_math_pi();
    }

    // Integer math
    fn panther_math_gcd(a, b) {
        while b != 0 {
            let temp = b;
            b = a % b;
            a = temp;
        }
        return panther_math_abs(a);
    }

    fn panther_math_lcm(a, b) {
        return abs(a * b) / panther_math_gcd(a, b);
    }
}