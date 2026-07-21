panther main {

    import panther.json as json;
    import panther.web as web;
    import panther.storage as storage;
    import panther.text as text;
    import panther.logging as log;

// ============================================================
// CONSTANTS & CONFIGURATION
// ============================================================

let HOST = "127.0.0.1";
let PORT = 9090;
let APP_VERSION = "2.0.0";
let ARRAY_MAX = 100;
let PI = 3.14159265358979323846;
let E = 2.71828182845904523536;
let data_dir = "panther-calc-data";
let store = storage.open(data_dir);

// Calculator mode: "calculator" (percentage) or "programmer" (modulo)
let CALC_MODE = "calculator";

    // ============================================================
    // HELPERS
    // ============================================================

    fn coalesce(val, default) {
        if val == null { return default; }
        return val;
    }

    fn array_push_copy(arr, val) {
        let n = len(arr); let result = [];
        for i1 in 0..n { result = array_push(result, arr[i1]); }
        result = array_push(result, val);
        return result;
    }

    // ============================================================
    // MATH CONSTANTS & FUNCTIONS
    // ============================================================

    let MATH_PI = 3.14159265358979323846264338327950288419716939937510;
    let MATH_E = 2.71828182845904523536028747135266249775724709369995;
    let TAU = 6.28318530717958647692528676655900576839433879875020;
    let HALF_PI = 1.57079632679489661923132169163975144209858469968755;
    let QUARTER_PI = 0.78539816339744830961566084581987572104929234984378;
    let LN2 = 0.69314718055994530941723212145817656807550013436026;
    let LN10 = 2.3025850929940456840179914546843642076011014886288;
    let EPS = 0.000000000000001;
    let DEG_TO_RAD = 0.017453292519943295769236907684886127134428718885417;
    let RAD_TO_DEG = 57.295779513082320876798154814105170332405472466564;

    fn taylor_sin(x) {
        let result = x; let term = x; let n1 = 50;
        for i1 in 1..n1 {
            term = -term * x * x * pow(2 * i1, -1) * pow(2 * i1 + 1, -1);
            result = result + term;
            if abs(term) < EPS { break; }
        }
        return result;
    }

    fn taylor_cos(x) {
        let result = 1; let term = 1; let n1 = 50;
        for i1 in 1..n1 {
            term = -term * x * x * pow(2 * i1 - 1, -1) * pow(2 * i1, -1);
            result = result + term;
            if abs(term) < EPS { break; }
        }
        return result;
    }

    fn math_sin(x) {
        let a = x % TAU;
        if a < 0 { a = a + TAU; }
        if a > PI && a < TAU { return -taylor_sin(a - PI); }
        if a > HALF_PI && a < PI + HALF_PI { return taylor_cos(a - HALF_PI); }
        return taylor_sin(a);
    }

    fn math_cos(x) { return math_sin(HALF_PI - x); }
    fn math_tan(x) { return math_sin(x) * pow(math_cos(x), -1); }

    fn math_asin(x) {
        if x > 1 || x < -1 { return null; }
        if x == 0 { return 0; }
        if abs(x) == 1 { return x * HALF_PI; }
        let result = x; let term = x; let x2 = x * x; let n1 = 50;
        for i1 in 1..n1 {
            term = term * x2 * (2 * i1 - 1) * (2 * i1 - 1) * pow(2 * i1, -1) * pow(2 * i1 + 1, -1);
            result = result + term;
            if abs(term) < EPS { break; }
        }
        return result;
    }

    fn math_acos(x) { return HALF_PI - math_asin(x); }

    fn math_atan(x) {
        if x == 0 { return 0; }
        if abs(x) == 1 { return x * QUARTER_PI; }
        if abs(x) > 1 { return HALF_PI - math_atan(pow(x, -1)); }
        let x2 = x * x; let result = x; let term = x; let n1 = 50;
        for i1 in 1..n1 {
            term = -term * x2 * (2 * i1 - 1) * pow(2 * i1 + 1, -1);
            result = result + term;
            if abs(term) < EPS { break; }
        }
        return result;
    }

    fn math_atan2(y, x) {
        if x > 0 { return math_atan(y * pow(x, -1)); }
        if x < 0 && y >= 0 { return math_atan(y * pow(x, -1)) + PI; }
        if x < 0 && y < 0 { return math_atan(y * pow(x, -1)) - PI; }
        if x == 0 && y > 0 { return HALF_PI; }
        if x == 0 && y < 0 { return -HALF_PI; }
        return 0;
    }

    fn math_sinh(x) {
        let ex = math_pow(MATH_E, x);
        return (ex - pow(ex, -1)) * pow(2, -1);
    }

    fn math_cosh(x) {
        let ex = math_pow(MATH_E, x);
        return (ex + pow(ex, -1)) * pow(2, -1);
    }

    fn math_tanh(x) {
        let ex = math_pow(MATH_E, 2 * x);
        return (ex - 1) * pow(ex + 1, -1);
    }

    fn math_asinh(x) { return math_ln(x + math_sqrt(x * x + 1)); }

    fn math_acosh(x) {
        if x < 1 { return null; }
        return math_ln(x + math_sqrt(x * x - 1));
    }

    fn math_ln(x) {
        if x <= 0 { return null; }
        if x == 1 { return 0; }
        if x == MATH_E { return 1; }
        let y = (x - 1) * pow(x + 1, -1); let y2 = y * y;
        let result = y; let term = y; let n1 = 100;
        for i1 in 1..n1 {
            term = term * y2 * (2 * i1 - 1) * pow(2 * i1 + 1, -1);
            result = result + term;
            if abs(term) < EPS { break; }
        }
        return 2 * result;
    }

    fn math_log10(x) {
        let ln_x = math_ln(x);
        if ln_x == null { return null; }
        return ln_x * pow(LN10, -1);
    }

    fn math_log2(x) {
        let ln_x = math_ln(x);
        if ln_x == null { return null; }
        return ln_x * pow(LN2, -1);
    }

    fn math_pow(base, exp) {
        if exp == 0 { return 1; }
        if exp == 1 { return base; }
        if exp == -1 { return pow(base, -1); }
        if exp > 0 && exp == to_int(exp) {
            let r = 1; let b = base; let e = to_int(exp);
            while e > 0 {
                if e % 2 == 1 { r = r * b; }
                b = b * b;
                e = to_int(e * pow(2, -1));
            }
            return r;
        }
        if exp < 0 { return pow(math_pow(base, -exp), -1); }
        return math_exp(exp * math_ln(base));
    }

    fn math_exp(x) {
        let result = 1; let term = 1; let n1 = 60;
        for i1 in 1..n1 {
            term = term * x * pow(i1, -1);
            result = result + term;
            if abs(term) < EPS { break; }
        }
        return result;
    }

    fn math_sqrt(x) {
        if x < 0 { return null; }
        if x == 0 { return 0; }
        if x == 1 { return 1; }
        let guess = x * pow(2, -1); let n1 = 50;
        for i1 in 0..n1 {
            let next = (guess + x * pow(guess, -1)) * pow(2, -1);
            if abs(next - guess) < EPS { break; }
            guess = next;
        }
        return guess;
    }

    fn math_cbrt(x) {
        if x == 0 { return 0; }
        let sign = 1; let v = x;
        if v < 0 { sign = -1; v = -v; }
        let guess = v * pow(3, -1); let n1 = 50;
        for i1 in 0..n1 {
            let next = (2 * guess + v * pow(guess * guess, -1)) * pow(3, -1);
            if abs(next - guess) < EPS { break; }
            guess = next;
        }
        return sign * guess;
    }

    fn math_hypot(a, b) { return math_sqrt(a * a + b * b); }

    fn math_factorial(n) {
        let ni = to_int(n);
        if ni < 0 { return null; }
        if ni == 0 { return 1; }
        let r = 1;
        for i1 in 1..ni { r = r * i1; }
        return r;
    }

    fn math_nCr(n, r) {
        let n1 = to_int(n); let r1 = to_int(r);
        if r1 < 0 || r1 > n1 { return 0; }
        if r1 == 0 || r1 == n1 { return 1; }
        if r1 > n1 - r1 { r1 = n1 - r1; }
        let result = 1;
        for i1 in 0..(r1-1) { result = result * (n1 - i1) * pow(i1 + 1, -1); }
        return result;
    }

    fn math_nPr(n, r) {
        let n1 = to_int(n); let r1 = to_int(r);
        if r1 < 0 || r1 > n1 { return 0; }
        let result = 1;
        for i1 in 0..(r1-1) { result = result * (n1 - i1); }
        return result;
    }

    fn math_gcd(a, b) {
        let a1 = to_int(abs(a)); let b1 = to_int(abs(b));
        while b1 > 0 { let t = b1; b1 = a1 % b1; a1 = t; }
        return a1;
    }

    fn math_lcm(a, b) {
        let g = math_gcd(a, b);
        if g == 0 { return 0; }
        return to_int(abs(a)) / g * to_int(abs(b));
    }

    fn math_is_prime(n) {
        let ni = to_int(abs(n));
        if ni < 2 { return false; }
        if ni == 2 { return true; }
        if ni % 2 == 0 { return false; }
        let limit = to_int(math_sqrt(ni));
        for i1 in 3..limit {
            if ni % i1 == 0 { return false; }
        }
        return true;
    }

    fn math_random(min, max) {
        if min == null { min = 0; }
        if max == null { max = 1; }
        return min + random() * (max - min);
    }

    fn math_lerp(a, b, t) { return a + (b - a) * t; }
    fn math_clamp(val, min_v, max_v) {
        if val < min_v { return min_v; }
        if val > max_v { return max_v; }
        return val;
    }
    fn math_sign(x) {
        if x > 0 { return 1; }
        if x < 0 { return -1; }
        return 0;
    }
    fn math_deg_to_rad(d) { return d * DEG_TO_RAD; }
    fn math_rad_to_deg(r) { return r * RAD_TO_DEG; }

    // ============================================================
    // UNITS & CONVERSIONS
    // ============================================================

    let UNIT_CATEGORIES = {};
    let _lu = {}; _lu["m"] = 1; _lu["km"] = 1000; _lu["cm"] = 1; _lu["mm"] = 1; _lu["mi"] = 1; _lu["yd"] = 1; _lu["ft"] = 1; _lu["in"] = 1; _lu["nm"] = 1; _lu["ly"] = 1;
    UNIT_CATEGORIES["length"] = {label: "Length", units: _lu};
    let _mu = {}; _mu["kg"] = 1; _mu["g"] = 1; _mu["mg"] = 1; _mu["lb"] = 1; _mu["oz"] = 1; _mu["t"] = 1; _mu["st"] = 1;
    UNIT_CATEGORIES["mass"] = {label: "Mass", units: _mu};
    UNIT_CATEGORIES["temperature"] = {label: "Temperature", units: {c: 1, f: 1, k: 1}};
    let _au = {}; _au["m2"] = 1; _au["km2"] = 1; _au["ha"] = 1; _au["acre"] = 1; _au["ft2"] = 1; _au["in2"] = 1;
    UNIT_CATEGORIES["area"] = {label: "Area", units: _au};
    let _vu = {}; _vu["l"] = 1; _vu["ml"] = 1; _vu["gal"] = 1; _vu["qt"] = 1; _vu["pt"] = 1; _vu["cup"] = 1; _vu["floz"] = 1; _vu["m3"] = 1;
    UNIT_CATEGORIES["volume"] = {label: "Volume", units: _vu};
    let _tu = {}; _tu["s"] = 1; _tu["ms"] = 1; _tu["min"] = 1; _tu["hr"] = 1; _tu["day"] = 1; _tu["week"] = 1; _tu["month"] = 1; _tu["year"] = 1;
    UNIT_CATEGORIES["time"] = {label: "Time", units: _tu};
    let _su = {}; _su["ms"] = 1; _su["kmh"] = 1; _su["mph"] = 1; _su["knot"] = 1; _su["c"] = 1;
    UNIT_CATEGORIES["speed"] = {label: "Speed", units: _su};
    let _pu = {}; _pu["pa"] = 1; _pu["kpa"] = 1; _pu["mpa"] = 1; _pu["bar"] = 1; _pu["psi"] = 1; _pu["atm"] = 1; _pu["torr"] = 1;
    UNIT_CATEGORIES["pressure"] = {label: "Pressure", units: _pu};
    let _eu = {}; _eu["j"] = 1; _eu["kj"] = 1; _eu["cal"] = 1; _eu["kcal"] = 1; _eu["wh"] = 1; _eu["kwh"] = 1; _eu["ev"] = 1; _eu["btu"] = 1;
    UNIT_CATEGORIES["energy"] = {label: "Energy", units: _eu};
    let _fu = {}; _fu["hz"] = 1; _fu["khz"] = 1; _fu["mhz"] = 1; _fu["ghz"] = 1; _fu["thz"] = 1;
    UNIT_CATEGORIES["frequency"] = {label: "Frequency", units: _fu};

    fn convert_unit(category, value, from_unit, to_unit) {
        let cat = UNIT_CATEGORIES[category];
        if cat == null { return {error: "Unknown category"}; }
        let units = cat["units"];
        let from_val = units[from_unit];
        let to_val = units[to_unit];
        if from_val == null { return {error: "Unknown from_unit"}; }
        if to_val == null { return {error: "Unknown to_unit"}; }
        if category == "temperature" {
            let in_c = value;
            if from_unit == "f" { in_c = (value - 32) * 5 * pow(9, -1); }
            if from_unit == "k" { in_c = value - 273.15; }
            if to_unit == "f" { return in_c * 9 * pow(5, -1) + 32; }
            if to_unit == "k" { return in_c + 273.15; }
            return in_c;
        }
        return value * from_val * pow(to_val, -1);
    }

    // ============================================================
    // FINANCIAL FUNCTIONS
    // ============================================================

    fn fin_pmt(rate, nper, pv, fv) {
        if fv == null { fv = 0; }
        if rate == 0 { return -pv * pow(nper, -1); }
        let r = rate * pow(100, -1); let n = nper;
        let pvif = math_pow(1 + r, n);
        return -(r * pv * pvif + r * fv) * pow(pvif - 1, -1);
    }

    fn fin_fv(rate, nper, pmt, pv) {
        if pv == null { pv = 0; }
        if rate == 0 { return -pv - pmt * nper; }
        let r = rate * pow(100, -1); let n = nper;
        let pvif = math_pow(1 + r, n);
        return -pv * pvif - pmt * (pvif - 1) * pow(r, -1);
    }

    fn fin_pv(rate, nper, pmt, fv) {
        if fv == null { fv = 0; }
        if rate == 0 { return -fv - pmt * nper; }
        let r = rate * pow(100, -1); let n = nper;
        let pvif = math_pow(1 + r, n);
        return -(pmt * (pvif - 1) * pow(r, -1) + fv) * pow(pvif, -1);
    }

    fn fin_npv(rate, values) {
        let r = rate * pow(100, -1); let npv = 0;
        for i1 in 0..(len(values)-1) {
            npv = npv + values[i1] * pow(math_pow(1 + r, i1), -1);
        }
        return npv;
    }

    fn fin_roi(gain, cost) {
        if cost == 0 { return 0; }
        return (gain - cost) * pow(cost, -1) * 100;
    }

    // ============================================================
    // STATISTICS FUNCTIONS
    // ============================================================

    fn stats_arr(data_str) {
        let parts = split(data_str, ",");
        let result = [];
        for i1 in 0..(len(parts)-1) {
            let trimmed = text.trim(parts[i1]);
            if trimmed != "" { result = array_push(result, to_number(trimmed)); }
        }
        return result;
    }

    fn stats_mean(arr) {
        if len(arr) == 0 { return 0; }
        let sum = 0;
        for i1 in 0..(len(arr)-1) { sum = sum + arr[i1]; }
        return sum * pow(len(arr), -1);
    }

    fn stats_median(arr) {
        let n1 = len(arr);
        if n1 == 0 { return 0; }
        let sorted = array_sort(arr);
        let half = to_int(n1 * pow(2, -1));
        if n1 % 2 == 1 { return sorted[half]; }
        return (sorted[half - 1] + sorted[half]) * pow(2, -1);
    }

    fn stats_stddev(arr) {
        let n1 = len(arr);
        if n1 < 2 { return 0; }
        let mean = stats_mean(arr);
        let sum_sq = 0;
        for i1 in 0..(n1-1) { sum_sq = sum_sq + (arr[i1] - mean) * (arr[i1] - mean); }
        return math_sqrt(sum_sq * pow(n1, -1));
    }

    fn stats_variance(arr) {
        let n1 = len(arr);
        if n1 < 2 { return 0; }
        let mean = stats_mean(arr);
        let sum_sq = 0;
        for i1 in 0..(n1-1) { sum_sq = sum_sq + (arr[i1] - mean) * (arr[i1] - mean); }
        return sum_sq * pow(n1, -1);
    }

    fn stats_summary(arr) {
        if len(arr) == 0 { return {count: 0}; }
        return {
            count: len(arr), mean: stats_mean(arr), median: stats_median(arr),
            stddev: stats_stddev(arr), variance: stats_variance(arr),
            min: arr[0], max: arr[len(arr)-1]
        };
    }

    fn stats_correlation(arr1, arr2) {
        let n1 = min(len(arr1), len(arr2));
        if n1 < 2 { return 0; }
        let mean1 = stats_mean(arr1); let mean2 = stats_mean(arr2);
        let cov = 0; let var1 = 0; let var2 = 0;
        for i1 in 0..(n1-1) {
            let d1 = arr1[i1] - mean1; let d2 = arr2[i1] - mean2;
            cov = cov + d1 * d2; var1 = var1 + d1 * d1; var2 = var2 + d2 * d2;
        }
        let denom = math_sqrt(var1 * var2);
        if denom == 0 { return 0; }
        return cov * pow(denom, -1);
    }

    fn stats_linear_regression(arr1, arr2) {
        let n1 = min(len(arr1), len(arr2));
        if n1 < 2 { return {error: "Need >= 2 points"}; }
        let mean_x = stats_mean(arr1); let mean_y = stats_mean(arr2);
        let num = 0; let den = 0;
        for i1 in 0..(n1-1) {
            let dx = arr1[i1] - mean_x;
            num = num + dx * (arr2[i1] - mean_y);
            den = den + dx * dx;
        }
        let slope = num * pow(den, -1);
        let intercept = mean_y - slope * mean_x;
        let var_y = stats_variance(arr2) * n1;
        return {slope: slope, intercept: intercept, r2: num * num * pow(den * var_y, -1)};
    }

    fn stats_random_normal(count, mean, stddev) {
        let result = [];
        for i1 in 0..(count-1) {
            let u1 = random(); let u2 = random();
            let z = math_sqrt(-2 * math_ln(u1 + EPS)) * math_cos(TAU * u2);
            result = array_push(result, mean + z * stddev);
        }
        return result;
    }

    // ============================================================
    // MATRIX FUNCTIONS
    // ============================================================

    fn matrix_create(rows, cols, values) {
        let mat = [];
        for r in 0..(rows-1) {
            let row = [];
            for c in 0..(cols-1) {
                let idx = r * cols + c;
                if values != null && idx < len(values) { row = array_push(row, values[idx]); }
                else { row = array_push(row, 0); }
            }
            mat = array_push(mat, row);
        }
        return mat;
    }

    fn matrix_det(mat) {
        let n1 = len(mat);
        if n1 == 2 { return mat[0][0] * mat[1][1] - mat[0][1] * mat[1][0]; }
        if n1 == 3 {
            return mat[0][0] * (mat[1][1] * mat[2][2] - mat[1][2] * mat[2][1])
                 - mat[0][1] * (mat[1][0] * mat[2][2] - mat[1][2] * mat[2][0])
                 + mat[0][2] * (mat[1][0] * mat[2][1] - mat[1][1] * mat[2][0]);
        }
        return null;
    }

    fn matrix_transpose(mat) {
        let rows = len(mat); let cols = len(mat[0]);
        let result = [];
        for c in 0..(cols-1) { let row = []; for r in 0..(rows-1) { row = array_push(row, mat[r][c]); } result = array_push(result, row); }
        return result;
    }

    fn matrix_inverse(mat) {
        let n1 = len(mat);
        if n1 == 2 {
            let det = mat[0][0] * mat[1][1] - mat[0][1] * mat[1][0];
            if det == 0 { return null; }
            return [[mat[1][1]/det, -mat[0][1]/det], [-mat[1][0]/det, mat[0][0]/det]];
        }
        return null;
    }

// ============================================================
// TOKENIZER
// ============================================================

let OP_CHARS = "+-*/^%()[],";
let WS_CHARS = " \t\n\r";
let DIGIT_CHARS = "0123456789";
let HEX_CHARS = "0123456789abcdefABCDEF";
let BIN_CHARS = "01";
let OCT_CHARS = "01234567";

fn tokenize(expr) {
    let tokens = []; let i1 = 0; let n1 = len(expr);
    while i1 < n1 {
        let ch = substring(expr, i1, i1 + 1);
        if contains(WS_CHARS, ch) { i1 = i1 + 1; continue; }
        if ch == "0" && i1 + 1 < n1 {
            let next = substring(expr, i1 + 1, i1 + 2);
            if next == "x" || next == "X" {
                let start = i1 + 2; i1 = start;
                while i1 < n1 && contains(HEX_CHARS, substring(expr, i1, i1 + 1)) { i1 = i1 + 1; }
                tokens = array_push(tokens, {t: "num", v: "0x" + substring(expr, start, i1)});
                continue;
            }
            if next == "b" || next == "B" {
                let start = i1 + 2; i1 = start;
                while i1 < n1 && contains(BIN_CHARS, substring(expr, i1, i1 + 1)) { i1 = i1 + 1; }
                tokens = array_push(tokens, {t: "num", v: "0b" + substring(expr, start, i1)});
                continue;
            }
            if next == "o" || next == "O" {
                let start = i1 + 2; i1 = start;
                while i1 < n1 && contains(OCT_CHARS, substring(expr, i1, i1 + 1)) { i1 = i1 + 1; }
                tokens = array_push(tokens, {t: "num", v: "0o" + substring(expr, start, i1)});
                continue;
            }
        }
        if contains(DIGIT_CHARS, ch) || ch == "." {
            let start = i1; let is_float = false;
            if ch == "." { is_float = true; }
            i1 = i1 + 1;
            while i1 < n1 && contains(DIGIT_CHARS, substring(expr, i1, i1 + 1)) { i1 = i1 + 1; }
            if i1 < n1 && substring(expr, i1, i1 + 1) == "." && !is_float {
                is_float = true; i1 = i1 + 1;
                while i1 < n1 && contains(DIGIT_CHARS, substring(expr, i1, i1 + 1)) { i1 = i1 + 1; }
            }
            // Check for scientific notation (e/E)
            if i1 < n1 {
                let next = substring(expr, i1, i1 + 1);
                if next == "e" || next == "E" {
                    i1 = i1 + 1;
                    if i1 < n1 {
                        let exp_sign = substring(expr, i1, i1 + 1);
                        if exp_sign == "+" || exp_sign == "-" { i1 = i1 + 1; }
                    }
                    while i1 < n1 && contains(DIGIT_CHARS, substring(expr, i1, i1 + 1)) { i1 = i1 + 1; }
                }
            }
            tokens = array_push(tokens, {t: "num", v: substring(expr, start, i1)});
            // Check for postfix % in calculator mode
            if CALC_MODE == "calculator" && i1 < n1 && substring(expr, i1, i1 + 1) == "%" {
                tokens = array_push(tokens, {t: "op", v: "post%"});
                i1 = i1 + 1;
            }
            continue;
        }
        if contains(OP_CHARS, ch) {
            // Handle % as postfix in calculator mode
            if ch == "%" && CALC_MODE == "calculator" {
                tokens = array_push(tokens, {t: "op", v: "post%"});
            } else {
                tokens = array_push(tokens, {t: "op", v: ch});
            }
            i1 = i1 + 1; continue;
        }
        if (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z") || ch == "_" {
            let start = i1; i1 = i1 + 1;
            while i1 < n1 {
                let c2 = substring(expr, i1, i1 + 1);
                if (c2 >= "a" && c2 <= "z") || (c2 >= "A" && c2 <= "Z") || (c2 >= "0" && c2 <= "9") || c2 == "_" { i1 = i1 + 1; }
                else { break; }
            }
            let ident = substring(expr, start, i1);
            if ident == "and" { tokens = array_push(tokens, {t: "op", v: "&&"}); }
            elif ident == "or" { tokens = array_push(tokens, {t: "op", v: "||"}); }
            elif ident == "not" { tokens = array_push(tokens, {t: "op", v: "!"}); }
            elif ident == "mod" { 
                if CALC_MODE == "programmer" {
                    tokens = array_push(tokens, {t: "op", v: "%"}); 
                } else {
                    tokens = array_push(tokens, {t: "op", v: "mod"});
                }
            }
            else { tokens = array_push(tokens, {t: "ident", v: ident}); }
            continue;
        }
        return {error: "Unexpected character: " + ch, pos: i1};
    }
    return {tokens: tokens, error: null};
}

// ============================================================
// SHUNTING-YARD -> RPN PARSER
// ============================================================

let PREC = {
    "||": 1, "&&": 2, "!": 3,
    "<": 4, ">": 4, "<=": 4, ">=": 4, "==": 4, "!=": 4,
    "+": 5, "-": 5,
    "*": 6, "/": 6, "%": 6, "mod": 6,
    "^": 7,
    "u-": 8, "u+": 8,
    "post%": 9,
    "+%": 5, "-%": 5, "*%": 6, "/%": 6, "^%": 7
};

fn to_rpn(tokens) {
    let output = []; let op_stack = [];
    let i1 = 0; let n1 = len(tokens);
    while i1 < n1 {
        let tok = tokens[i1];
        if tok.t == "num" { output = array_push(output, tok); i1 = i1 + 1; continue; }
        if tok.t == "ident" { output = array_push(output, tok); i1 = i1 + 1; continue; }
        if tok.t == "op" && tok.v == "," {
            while len(op_stack) > 0 { let top = op_stack[len(op_stack) - 1]; if top.v == "(" { break; } output = array_push(output, array_pop(op_stack)); }
            i1 = i1 + 1; continue;
        }
        if tok.t == "op" && tok.v == "(" { op_stack = array_push(op_stack, tok); i1 = i1 + 1; continue; }
        if tok.t == "op" && tok.v == ")" {
            while len(op_stack) > 0 { let top = op_stack[len(op_stack) - 1]; if top.v == "(" { break; } output = array_push(output, array_pop(op_stack)); }
            if len(op_stack) > 0 { array_pop(op_stack); }
            i1 = i1 + 1; continue;
        }
        if tok.t == "op" {
            let is_unary = false;
            if tok.v == "-" || tok.v == "+" {
                if i1 == 0 { is_unary = true; }
                elif i1 > 0 { let prev = tokens[i1 - 1]; if prev.t == "op" && prev.v != ")" { is_unary = true; } }
            }
            let op = tok;
            if is_unary { op = {t: "op", v: "u" + tok.v}; }
            
            // Check for calculator percentage pattern: binary_op num post%
            // We need to look ahead in the token stream
            if CALC_MODE == "calculator" && !is_unary && (op.v == "+" || op.v == "-" || op.v == "*" || op.v == "/" || op.v == "^") {
                // Check if next tokens are: num post%
                if i1 + 2 < n1 {
                    let next1 = tokens[i1 + 1];
                    let next2 = tokens[i1 + 2];
                    if next1.t == "num" && next2.t == "op" && next2.v == "post%" {
                        // Transform: a + b post%  ->  a b +% (special combined operator)
                        // Push the number first
                        output = array_push(output, next1);
                        // Create combined operator
                        let combined_op = {t: "op", v: op.v + "%"};
                        op = combined_op;
                        // Skip the next two tokens (num and post%)
                        i1 = i1 + 3;
                    }
                }
            }
            
            while len(op_stack) > 0 {
                let top = op_stack[len(op_stack) - 1];
                if top.v == "(" { break; }
                let p1 = coalesce(PREC[op.v], 0);
                let p2 = coalesce(PREC[top.v], 0);
                // post% is right-associative (postfix), so don't pop on equal precedence
                // Combined percentage ops (+%, -%, *%, /%, ^%) have same precedence as base op
                if p2 > p1 || (p2 == p1 && op.v != "^" && op.v != "post%" && not_ends_with(op.v, "%")) { output = array_push(output, array_pop(op_stack)); }
                else { break; }
            }
            op_stack = array_push(op_stack, op);
            i1 = i1 + 1; continue;
        }
        if tok.t == "func" { op_stack = array_push(op_stack, tok); i1 = i1 + 1; continue; }
        return {error: "Unexpected token: " + tok.v};
    }
    while len(op_stack) > 0 { output = array_push(output, array_pop(op_stack)); }
    return {rpn: output, error: null};
}

fn not_ends_with(s, suffix) {
    let slen = len(s);
    let suflen = len(suffix);
    if slen < suflen { return true; }
    return substring(s, slen - suflen) != suffix;
}

// ============================================================
// RPN EVALUATOR
// ============================================================

fn eval_rpn(rpn) {
    let stack = [];
    let i1 = 0; let n1 = len(rpn);
    while i1 < n1 {
        let tok = rpn[i1];
        if tok.t == "num" {
            let v = tok.v;
            if starts_with(v, "0x") || starts_with(v, "0X") {
                let hex_str = substring(v, 2);
                let dec = 0;
                for j1 in 0..(len(hex_str)-1) {
                    let digit = substring(hex_str, j1, j1+1);
                    let val = 0;
                    if digit == "0" { val = 0; }
                    elif digit == "1" { val = 1; }
                    elif digit == "2" { val = 2; }
                    elif digit == "3" { val = 3; }
                    elif digit == "4" { val = 4; }
                    elif digit == "5" { val = 5; }
                    elif digit == "6" { val = 6; }
                    elif digit == "7" { val = 7; }
                    elif digit == "8" { val = 8; }
                    elif digit == "9" { val = 9; }
                    elif digit == "a" || digit == "A" { val = 10; }
                    elif digit == "b" || digit == "B" { val = 11; }
                    elif digit == "c" || digit == "C" { val = 12; }
                    elif digit == "d" || digit == "D" { val = 13; }
                    elif digit == "e" || digit == "E" { val = 14; }
                    elif digit == "f" || digit == "F" { val = 15; }
                    dec = dec * 16 + val;
                }
                stack = array_push(stack, dec);
            }
            elif starts_with(v, "0b") || starts_with(v, "0B") {
                let dec = 0;
                for j1 in 2..(len(v)-1) {
                    if substring(v, j1, j1+1) == "1" { dec = dec * 2 + 1; } else { dec = dec * 2; }
                }
                stack = array_push(stack, dec);
            }
            elif starts_with(v, "0o") || starts_with(v, "0O") {
                let dec = 0;
                for j1 in 2..(len(v)-1) { dec = dec * 8 + to_number(substring(v, j1, j1+1)); }
                stack = array_push(stack, dec);
            }
            else { stack = array_push(stack, to_number(v)); }
            i1 = i1 + 1; continue;
        }
        if tok.t == "ident" {
            let name = tok.v;
            if name == "pi" { stack = array_push(stack, MATH_PI); }
            elif name == "e" { stack = array_push(stack, MATH_E); }
            elif name == "tau" { stack = array_push(stack, TAU); }
            else { return {error: "Unknown identifier: " + name}; }
            i1 = i1 + 1; continue;
        }
        if tok.t == "op" {
            let op = tok.v;
            // Unary operators
            if op == "u-" || op == "u+" || op == "!" {
                if len(stack) < 1 { return {error: "Not enough args for unary " + op}; }
                let a = array_pop(stack);
                if op == "u-" { stack = array_push(stack, -a); }
                elif op == "u+" { stack = array_push(stack, a); }
                elif op == "!" { if a == 0 { stack = array_push(stack, 1); } else { stack = array_push(stack, 0); } }
                i1 = i1 + 1; continue;
            }
            // Postfix percentage (calculator mode)
            if op == "post%" {
                if len(stack) < 1 { return {error: "Percentage operator requires a value"}; }
                let a = array_pop(stack);
                // In calculator mode, post% alone means divide by 100
                stack = array_push(stack, a * 0.01);
                i1 = i1 + 1; continue;
            }
// Combined percentage operators (from parser transformation): +%, -%, *%, /%, ^%
            if op == "+%" || op == "-%" || op == "*%" || op == "/%" || op == "^%" {
                if len(stack) < 2 { return {error: "Not enough arguments for " + op}; }
                let b = array_pop(stack);
                let a = array_pop(stack);
                let r;
                let pct = b * 0.01;
                if op == "+%" { r = a + a * pct; }
                elif op == "-%" { r = a - a * pct; }
                elif op == "*%" { r = a * pct; }
                elif op == "/%" { if b == 0 { return {error: "Division by zero (percentage)"}; } r = a * pow(pct, -1); }
                elif op == "^%" { r = math_pow(a, pct); }
                stack = array_push(stack, r);
                i1 = i1 + 1; continue;
            }
            // Binary operators
            if op == "+" || op == "-" || op == "*" || op == "/" || op == "^" || op == "%" || op == "mod" || op == "&&" || op == "||" || op == "<" || op == ">" || op == "<=" || op == ">=" || op == "==" || op == "!=" {
                if len(stack) < 2 { return {error: "Not enough arguments for " + op}; }
                let b = array_pop(stack);
                let a = array_pop(stack);
                let r;
                if op == "+" { r = a + b; }
                elif op == "-" { r = a - b; }
                elif op == "*" { r = a * b; }
                elif op == "/" { if b == 0 { return {error: "Division by zero"}; } r = a * pow(b, -1); }
                elif op == "%" || op == "mod" { r = a % b; }
                elif op == "^" { r = math_pow(a, b); }
                elif op == "&&" { if a != 0 && b != 0 { r = 1; } else { r = 0; } }
                elif op == "||" { if a != 0 || b != 0 { r = 1; } else { r = 0; } }
                elif op == "<" { if a < b { r = 1; } else { r = 0; } }
                elif op == ">" { if a > b { r = 1; } else { r = 0; } }
                elif op == "<=" { if a <= b { r = 1; } else { r = 0; } }
                elif op == ">=" { if a >= b { r = 1; } else { r = 0; } }
                elif op == "==" { if a == b { r = 1; } else { r = 0; } }
                elif op == "!=" { if a != b { r = 1; } else { r = 0; } }
                else { return {error: "Unknown op: " + op}; }
                i1 = i1 + 1;
                stack = array_push(stack, r);
                continue;
            }
            return {error: "Unknown operator: " + op};
        }
        return {error: "Invalid token type: " + tok.t};
    }
    if len(stack) != 1 { return {error: "Unexpected stack size: " + to_string(len(stack))}; }
    return {result: stack[0], error: null};
}

    // ============================================================
    // MAIN CALCULATOR
    // ============================================================

    fn do_calc(expression) {
        let expr = text.trim(expression);
        if expr == "" { return {error: "Empty expression"}; }
        let tok_result = tokenize(expr);
        if tok_result.error != null { return {error: tok_result.error, pos: tok_result.pos}; }
        let tokens = tok_result.tokens;
        if len(tokens) == 0 { return {error: "No tokens"}; }
        let rpn_result = to_rpn(tokens);
        if rpn_result.error != null { return {error: rpn_result.error}; }
        let eval_result = eval_rpn(rpn_result.rpn);
        if eval_result.error != null { return {error: eval_result.error}; }
        return {
            expression: expr,
            result: eval_result.result,
            tokens: tokens,
            rpn: rpn_result.rpn,
            is_int: eval_result.result == to_int(eval_result.result),
            error: null
        };
    }

    fn validate_expression(expr) {
        let result = do_calc(expr);
        return {valid: result.error == null, error: result.error};
    }

    fn evaluate_batch(expressions) {
        let results = [];
        for i1 in 0..(len(expressions)-1) { results = array_push(results, do_calc(expressions[i1])); }
        return results;
    }

    // ============================================================
    // STORAGE FUNCTIONS
    // ============================================================

    fn save_hist(expr_val, result_val) {
        let entries = storage.get_json(store, "history_list");
        let list = [];
        if entries != null { list = entries; }
        let id_str = replace(to_string(time.now()), ".", "");
        let entry = {id: id_str, expr: expr_val, result: to_string(result_val), ts: to_string(time.now())};
        list = array_push_copy(list, entry);
        if len(list) > ARRAY_MAX {
            let nl = [];
            for ti in 1..(len(list)-1) { nl = array_push_copy(nl, list[ti]); }
            list = nl;
        }
        storage.put_json(store, "history_list", list);
        return list[0];
    }

    fn load_hist() {
        let entries = storage.get_json(store, "history_list");
        if entries == null { return []; }
        return entries;
    }

    fn clear_hist() { storage.put_json(store, "history_list", []); return true; }

    fn delete_hist_entry(entry_id) {
        let entries = load_hist(); let new_entries = [];
        for i1 in 0..(len(entries)-1) {
            if entries[i1]["id"] != entry_id { new_entries = array_push_copy(new_entries, entries[i1]); }
        }
        storage.put_json(store, "history_list", new_entries);
        return new_entries;
    }

    fn load_mem_val() {
        let val = storage.get_json(store, "panther_calc_mem");
        if val == null { return 0; }
        return val;
    }

    fn save_mem_val(val) { storage.put_json(store, "panther_calc_mem", val); }
    fn clear_mem_val() { storage.delete(store, "panther_calc_mem"); }

    fn load_prefs() {
        let prefs = storage.get_json(store, "preferences");
        if prefs == null { return {mode: "basic", angle: "deg", word_size: 64, theme: "dark", precision: 15}; }
        return prefs;
    }

    fn save_prefs(prefs) { storage.put_json(store, "preferences", prefs); return {ok: true}; }

    // ============================================================
    // SERVER SETUP
    // ============================================================

    log.info("PantherLang Calculator Pro starting...");
    let server = web.server_create(HOST, PORT);

    // ============================================================
    // API HANDLERS
    // ============================================================

    fn handle_calculate(req) {
        let body = json.parse(req["body"]);
        if body == null { return {error: "Invalid JSON"}; }
        let expr = body["expression"];
        if expr == null { return {error: "Missing expression"}; }
        return do_calc(expr);
    }

    fn handle_validate(req) {
        let body = json.parse(req["body"]);
        if body == null { return {error: "Invalid JSON"}; }
        return validate_expression(coalesce(body["expression"], ""));
    }

    fn handle_batch(req) {
        let body = json.parse(req["body"]);
        if body == null || body["expressions"] == null { return {error: "Missing expressions"}; }
        return {results: evaluate_batch(body["expressions"])};
    }

    fn handle_stats(req) {
        let body = json.parse(req["body"]);
        if body == null { return {error: "Invalid JSON"}; }
        let data_str = body["data"];
        if data_str == null { return {error: "Missing data"}; }
        let arr = stats_arr(data_str);
        let action = coalesce(body["action"], "summary");
        if action == "summary" { return stats_summary(arr); }
        if action == "regression" {
            let data2_str = body["data2"]; if data2_str == null { return {error: "Need data2 for regression"}; }
            return stats_linear_regression(arr, stats_arr(data2_str));
        }
        if action == "correlation" {
            let data2_str = body["data2"]; if data2_str == null { return {error: "Need data2"}; }
            return {r: stats_correlation(arr, stats_arr(data2_str))};
        }
        if action == "random_normal" {
            return stats_random_normal(coalesce(body["count"], 100), coalesce(body["mean"], 0), coalesce(body["stddev"], 1));
        }
        return {error: "Unknown action"};
    }

    fn handle_matrix(req) {
        let body = json.parse(req["body"]);
        if body == null { return {error: "Invalid JSON"}; }
        let action = body["action"];
        if action == "create" { return matrix_create(to_int(coalesce(body["rows"], 2)), to_int(coalesce(body["cols"], 2)), body["values"]); }
        if action == "det" { return {det: matrix_det(body["matrix"])}; }
        if action == "transpose" { return {matrix: matrix_transpose(body["matrix"])}; }
        if action == "inverse" { return {matrix: matrix_inverse(body["matrix"])}; }
        return {error: "Unknown action"};
    }

    fn handle_graph(req) {
        let body = json.parse(req["body"]);
        if body == null { return {error: "Invalid JSON"}; }
        let expr = coalesce(body["expr"], "x");
        let x_min = coalesce(body["x_min"], -10);
        let x_max = coalesce(body["x_max"], 10);
        let steps = to_int(coalesce(body["steps"], 200));
        let result = []; let step = (x_max - x_min) / steps;
        for i1 in 0..steps {
            let x = x_min + i1 * step;
            let compiled = do_calc(to_string(x));
            if compiled.error == null { result = array_push(result, {x: x, y: compiled.result}); }
        }
        return {points: result};
    }

    fn handle_financial(req) {
        let body = json.parse(req["body"]);
        if body == null { return {error: "Invalid JSON"}; }
        let action = body["action"];
        if action == "pmt" { return {result: fin_pmt(coalesce(body["rate"], 0), coalesce(body["nper"], 12), coalesce(body["pv"], 0), coalesce(body["fv"], 0))}; }
        if action == "fv" { return {result: fin_fv(coalesce(body["rate"], 0), coalesce(body["nper"], 12), coalesce(body["pmt"], 0), coalesce(body["pv"], 0))}; }
        if action == "pv" { return {result: fin_pv(coalesce(body["rate"], 0), coalesce(body["nper"], 12), coalesce(body["pmt"], 0), coalesce(body["fv"], 0))}; }
        if action == "npv" { return {result: fin_npv(coalesce(body["rate"], 0), coalesce(body["values"], [0]))}; }
        if action == "roi" { return {result: fin_roi(coalesce(body["gain"], 0), coalesce(body["cost"], 0))}; }
        return {error: "Unknown action"};
    }

    fn handle_engineering(req) {
        let body = json.parse(req["body"]);
        if body == null { return {error: "Invalid JSON"}; }
        return convert_unit(body["category"], coalesce(body["value"], 0), body["from"], body["to"]);
    }

    fn handle_debug(req) {
        let body = json.parse(req["body"]);
        if body == null { return {error: "Invalid JSON"}; }
        let expr = coalesce(body["expression"], "");
        let tok_result = tokenize(expr);
        if tok_result.error != null { return {error: tok_result.error}; }
        let rpn_result = to_rpn(tok_result.tokens);
        if rpn_result.error != null { return {error: rpn_result.error}; }
        let eval_result = eval_rpn(rpn_result.rpn);
        if eval_result.error != null { return {error: eval_result.error}; }
        return {tokens: tok_result.tokens, rpn: rpn_result.rpn, result: eval_result.result, error: eval_result.error};
    }

    fn handle_profile(req) {
        let body = json.parse(req["body"]);
        if body == null { return {error: "Invalid JSON"}; }
        let expr = coalesce(body["expression"], "");
        let start_t = time.now();
        let result = do_calc(expr);
        let elapsed = time.now() - start_t;
        return {result: result, time_ms: elapsed * 1000, time_ns: elapsed * 1000000000};
    }

    fn handle_export(req) {
        return {version: APP_VERSION, exported_at: to_string(time.now()), history: load_hist(), memory: load_mem_val(), preferences: load_prefs()};
    }

    fn handle_import(req) {
        let body = json.parse(req["body"]);
        if body == null || body["data"] == null { return {error: "Missing data"}; }
        let data = body["data"]; let count = 0;
        if data["history"] != null { storage.put_json(store, "history_list", data["history"]); count = count + len(data["history"]); }
        if data["memory"] != null { save_mem_val(data["memory"]); count = count + 1; }
        if data["preferences"] != null { save_prefs(data["preferences"]); count = count + 1; }
        return {ok: true, count: count};
    }

    fn handle_history(req) {
        let method = req["method"];
        if method == "POST" {
            let body = json.parse(req["body"]);
            if body == null { return {error: "Invalid JSON"}; }
            return save_hist(body["expr"], body["result"]);
        }
        if method == "DELETE" {
            let body = json.parse(req["body"]);
            if body != null && body["id"] != null { return delete_hist_entry(body["id"]); }
            clear_hist(); return {ok: true};
        }
        return load_hist();
    }

    fn handle_memory(req) {
        let method = req["method"];
        if method == "POST" {
            let body = json.parse(req["body"]);
            if body != null && body["value"] != null { save_mem_val(body["value"]); }
            return {ok: true};
        }
        if method == "DELETE" { clear_mem_val(); return {ok: true}; }
        return {value: load_mem_val()};
    }

    fn handle_preferences(req) {
        let method = req["method"];
        if method == "POST" {
            let body = json.parse(req["body"]);
            if body != null { save_prefs(body); }
            return {ok: true};
        }
        return load_prefs();
    }

    fn handle_health(req) {
        return {status: "ok", service: "panther-calculator-pro", version: APP_VERSION};
    }

    fn handle_root(req) {
        let p = [];
        p = array_push(p, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><title>PantherCalc v" + APP_VERSION + "</title><style>");
        p = array_push(p, "body{font-family:sans-serif;background:#0b0f1a;color:#f9fafb;margin:0;padding:20px;max-width:600px;margin:0 auto}");
        p = array_push(p, ".disp{background:#1f2937;padding:12px 16px;border-radius:8px;margin-bottom:12px;text-align:right}");
        p = array_push(p, ".expr{color:#9ca3af;font-size:12px;font-family:monospace;min-height:18px}");
        p = array_push(p, ".val{font-size:28px;font-weight:700;font-family:monospace;min-height:36px}");
        p = array_push(p, ".keypad{display:grid;grid-template-columns:repeat(4,1fr);gap:6px;margin-bottom:12px}");
        p = array_push(p, ".key{padding:12px;background:#1f2937;border:1px solid rgba(75,85,99,0.4);color:#f9fafb;border-radius:6px;font-size:15px;cursor:pointer;text-align:center;user-select:none}");
        p = array_push(p, ".key:hover{background:#3b82f6}.key.op{background:#111827;color:#3b82f6}.key.eq{background:#3b82f6;color:#fff}.key.clr{background:#ef4444;color:#fff}");
        p = array_push(p, ".hdr{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px}");
        p = array_push(p, ".brand{font-weight:700;color:#3b82f6;font-size:18px}");
        p = array_push(p, ".hist{background:#1f2937;border-radius:8px;overflow:hidden;margin-bottom:12px;max-height:200px;overflow-y:auto}");
        p = array_push(p, ".hist-i{padding:6px 12px;border-bottom:1px solid rgba(75,85,99,0.4);display:flex;justify-content:space-between;font-family:monospace;cursor:pointer}");
        p = array_push(p, ".hist-e{color:#9ca3af;font-size:11px}.hist-r{color:#f9fafb;font-weight:600}.ft{text-align:center;padding:12px;font-size:11px;color:#6b7280}");
        p = array_push(p, "</style></head><body>");
        p = array_push(p, "<div class=\"hdr\"><span class=\"brand\">PantherCalc v" + APP_VERSION + "</span><span style=\"color:#6b7280;font-size:11px\">" + HOST + ":" + to_string(PORT) + "</span></div>");
        p = array_push(p, "<div class=\"disp\"><div class=\"expr\" id=\"dispE\"></div><div class=\"val\" id=\"dispV\">0</div></div>");
        p = array_push(p, "<div class=\"keypad\">");
        p = array_push(p, "<button class=\"key clr\" onclick=\"k('C')\">AC</button><button class=\"key op\" onclick=\"k('%')\">%</button><button class=\"key op\" onclick=\"k('/')\">/</button><button class=\"key op\" onclick=\"k('*')\">*</button>");
        p = array_push(p, "<button class=\"key\" onclick=\"k('7')\">7</button><button class=\"key\" onclick=\"k('8')\">8</button><button class=\"key\" onclick=\"k('9')\">9</button><button class=\"key op\" onclick=\"k('-')\">-</button>");
        p = array_push(p, "<button class=\"key\" onclick=\"k('4')\">4</button><button class=\"key\" onclick=\"k('5')\">5</button><button class=\"key\" onclick=\"k('6')\">6</button><button class=\"key op\" onclick=\"k('+')\">+</button>");
        p = array_push(p, "<button class=\"key\" onclick=\"k('1')\">1</button><button class=\"key\" onclick=\"k('2')\">2</button><button class=\"key\" onclick=\"k('3')\">3</button><button class=\"key eq\" onclick=\"k('=')\">=</button>");
        p = array_push(p, "<button class=\"key\" onclick=\"k('0')\" style=\"grid-column:span 2\">0</button><button class=\"key\" onclick=\"k('.')\">.</button><button class=\"key fn\" onclick=\"k('neg')\">+/-</button>");
        p = array_push(p, "</div>");
        p = array_push(p, "<div id=\"histBox\"></div>");
        p = array_push(p, "<script>");
        p = array_push(p, "var S={expr:'',hist:[]};function k(c){if(c==='C'){S.expr='';upd();return}if(c==='B'){S.expr=S.expr.slice(0,-1);upd();return}if(c==='='){calc();return}if(c==='neg'){S.expr=S.expr.startsWith('-')?S.expr.slice(1):'-'+S.expr;upd();return}S.expr+=c;upd()}");
        p = array_push(p, "function upd(){document.getElementById('dispE').textContent=S.expr;document.getElementById('dispV').textContent=S.expr||'0'}");
        p = array_push(p, "function calc(){fetch('/api/calculate',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({expression:S.expr})}).then(function(r){return r.json()}).then(function(d){if(d.error){document.getElementById('dispV').textContent='Error: '+d.error;document.getElementById('dispV').className='val err'}else{document.getElementById('dispV').textContent=d.result;document.getElementById('dispV').className='val';S.expr=String(d.result);document.getElementById('dispE').textContent=d.expression;loadHist()}})}");
        p = array_push(p, "function loadHist(){fetch('/api/history').then(function(r){return r.json()}).then(function(d){var h=document.getElementById('histBox');if(!h)return;if(!d||d.length===0){h.innerHTML='<div style=\"padding:12px;color:#6b7280\">No history</div>';return}h.innerHTML='<div style=\"padding:6px 12px;color:#9ca3af;font-size:11px\">History <span onclick=\"clearHist()\" style=\"cursor:pointer;color:#ef4444;float:right\">Clear</span></div>'+d.map(function(e){return'<div class=\"hist-i\" onclick=\"S.expr='+JSON.stringify(e.expr)+';upd()\"><span class=\"hist-e\">'+e.expr+'</span><span class=\"hist-r\">='+e.result+'</span></div>'}).join('')})}");
        p = array_push(p, "function clearHist(){fetch('/api/history',{method:'DELETE'}).then(function(){loadHist()})}");
        p = array_push(p, "document.addEventListener('keydown',function(e){var kc=e.key;if(kc==='Enter'){calc()}else if(kc==='Backspace'){k('B')}else if(kc==='Escape'){k('C')}else if('0123456789.+-*/%'.indexOf(kc)>=0){k(kc)}});loadHist();");
        p = array_push(p, "</script></body></html>");
        return join("", p);
    }

    // ============================================================
    // ROUTES
    // ============================================================

    web.get(server, "/", handle_root);
    web.get(server, "/health", handle_health);
    web.post(server, "/api/calculate", handle_calculate);
    web.post(server, "/api/validate", handle_validate);
    web.post(server, "/api/batch", handle_batch);
    web.post(server, "/api/stats", handle_stats);
    web.post(server, "/api/matrix", handle_matrix);
    web.post(server, "/api/graph", handle_graph);
    web.post(server, "/api/financial", handle_financial);
    web.post(server, "/api/engineering", handle_engineering);
    web.post(server, "/api/debug", handle_debug);
    web.post(server, "/api/profile", handle_profile);
    web.get(server, "/api/export", handle_export);
    web.post(server, "/api/import", handle_import);
    web.get(server, "/api/history", handle_history);
    web.post(server, "/api/history", handle_history);
    web.delete(server, "/api/history", handle_history);
    web.get(server, "/api/memory", handle_memory);
    web.post(server, "/api/memory", handle_memory);
    web.delete(server, "/api/memory", handle_memory);
    web.get(server, "/api/preferences", handle_preferences);
    web.post(server, "/api/preferences", handle_preferences);

    // ============================================================
    // START
    // ============================================================

    log.info("Starting PantherLang Calculator Pro v" + APP_VERSION);
    print "========================================================";
    print "  PantherLang Calculator Pro v" + APP_VERSION;
    print "========================================================";
    print "  URL:       http://" + HOST + ":" + to_string(PORT) + "/";
    print "  API:       /api/calculate, /api/history, /api/memory,";
    print "             /api/stats, /api/matrix, /api/graph,";
    print "             /api/financial, /api/engineering,";
    print "             /api/debug, /api/profile, /api/export";
    print "  Modes:     Basic, Sci, Prog, Stats, Matrix, Graph, Fin, Eng, Dev";
    print "  Engine:    panther.math + Taylor series + Shunting-Yard parser";
    print "  Version:   " + APP_VERSION;
    print "========================================================";
    web.start(server);
}
