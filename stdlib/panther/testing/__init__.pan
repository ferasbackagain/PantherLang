panther main {
    // Testing framework
    fn panther_testing_test(name, test_fn) {
        let result = test_fn();
        if result == true {
            print("[PASS] " + name);
            return true;
        } else {
            print("[FAIL] " + name);
            return false;
        }
    }

    fn panther_testing_test_eq(name, actual, expected) {
        let pass = actual == expected;
        if pass {
            print("[PASS] " + name);
        } else {
            print("[FAIL] " + name + " - expected: " + to_string(expected) + " got: " + to_string(actual));
        }
        return pass;
    }

    fn panther_testing_test_ne(name, actual, expected) {
        let pass = actual != expected;
        if pass {
            print("[PASS] " + name);
        } else {
            print("[FAIL] " + name + " - expected not equal: " + to_string(expected));
        }
        return pass;
    }

    fn panther_testing_test_true(name, condition) {
        if condition {
            print("[PASS] " + name);
            return true;
        } else {
            print("[FAIL] " + name + " - expected true");
            return false;
        }
    }

    fn panther_testing_test_false(name, condition) {
        if !condition {
            print("[PASS] " + name);
            return true;
        } else {
            print("[FAIL] " + name + " - expected false");
            return false;
        }
    }

    fn panther_testing_test_null(name, value) {
        if value == null {
            print("[PASS] " + name);
            return true;
        } else {
            print("[FAIL] " + name + " - expected null, got: " + to_string(value));
            return false;
        }
    }

    fn panther_testing_test_not_null(name, value) {
        if value != null {
            print("[PASS] " + name);
            return true;
        } else {
            print("[FAIL] " + name + " - expected not null");
            return false;
        }
    }

    fn panther_testing_test_contains(name, haystack, needle) {
        let pass = contains(haystack, needle);
        if pass {
            print("[PASS] " + name);
        } else {
            print("[FAIL] " + name + " - expected to contain: " + needle);
        }
        return pass;
    }

    fn panther_testing_test_throws(name, test_fn) {
        // Simplified - just run and check if it errors
        // In practice would need try/catch
        let result = test_fn();
        return false; // Simplified
    }

    fn panther_testing_run_suite(name, tests) {
        print("Running test suite: " + name);
        let passed = 0;
        let failed = 0;
        let i = 0;
        while i < len(tests) {
            let t = tests[i];
            if t() {
                passed = passed + 1;
            } else {
                failed = failed + 1;
            }
            i = i + 1;
        }
        print("Results: " + to_string(passed) + " passed, " + to_string(failed) + " failed");
        return failed == 0;
    }
}