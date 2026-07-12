panther main {
    // Type conversion
    fn panther_core_type_of(value) {
        return type_of(value);
    }

    fn panther_core_to_int(value) {
        return to_int(value);
    }

    fn panther_core_to_float(value) {
        return to_float(value);
    }

    fn panther_core_to_number(value) {
        return to_number(value);
    }

    fn panther_core_to_string(value) {
        return to_string(value);
    }

    fn panther_core_to_bool(value) {
        return to_bool(value);
    }

    // Type predicates
    fn panther_core_is_string(value) {
        return type_of(value) == "string";
    }

    fn panther_core_is_int(value) {
        return type_of(value) == "int";
    }

    fn panther_core_is_float(value) {
        return type_of(value) == "float";
    }

    fn panther_core_is_bool(value) {
        return type_of(value) == "bool";
    }

    fn panther_core_is_array(value) {
        return type_of(value) == "array";
    }

    fn panther_core_is_object(value) {
        return type_of(value) == "object";
    }

    fn panther_core_is_null(value) {
        return type_of(value) == "null";
    }

    fn panther_core_is_number(value) {
        let t = type_of(value);
        return t == "int" || t == "float";
    }

    // Equality and comparison
    fn panther_core_eq(a, b) {
        return a == b;
    }

    fn panther_core_ne(a, b) {
        return a != b;
    }

    fn panther_core_lt(a, b) {
        return a < b;
    }

    fn panther_core_le(a, b) {
        return a <= b;
    }

    fn panther_core_gt(a, b) {
        return a > b;
    }

    fn panther_core_ge(a, b) {
        return a >= b;
    }

    // Validation
    fn panther_core_validate_type(value, expected_type) {
        let actual = type_of(value);
        if actual == expected_type {
            return {ok: true, value: value};
        }
        return {ok: false, error: "Type mismatch: expected " + expected_type + " got " + actual};
    }

    fn panther_core_validate_range(value, min, max) {
        if !panther_core_is_number(value) {
            return {ok: false, error: "Value is not a number"};
        }
        if value < min {
            return {ok: false, error: "Value " + to_string(value) + " below minimum " + to_string(min)};
        }
        if value > max {
            return {ok: false, error: "Value " + to_string(value) + " above maximum " + to_string(max)};
        }
        return {ok: true, value: value};
    }

    fn panther_core_assert(condition, message) {
        if !condition {
            return {ok: false, error: message};
        }
        return {ok: true};
    }

    // Safe value inspection
    fn panther_core_inspect(value) {
        return to_string(value);
    }

    fn panther_core_pretty_print(value) {
        if type_of(value) == "object" {
            return json_pretty(value);
        }
        if type_of(value) == "array" {
            return json_pretty(value);
        }
        return to_string(value);
    }

    // I/O
    fn panther_core_println(value) {
        return println(value);
    }

    fn panther_core_input(prompt_text) {
        return input(prompt_text);
    }

    fn panther_core_readline(prompt_text) {
        return readline(prompt_text);
    }

    // Option/Result helpers
    fn panther_core_some(value) {
        return {some: true, value: value};
    }

    fn panther_core_none() {
        return {some: false, value: null};
    }

    fn panther_core_is_some(opt) {
        return opt.some == true;
    }

    fn panther_core_is_none(opt) {
        return opt.some == false;
    }

    fn panther_core_unwrap(opt, default) {
        if opt.some == true {
            return opt.value;
        }
        return default;
    }

    fn panther_core_ok(value) {
        return {ok: true, value: value};
    }

    fn panther_core_err(error) {
        return {ok: false, error: error};
    }

    fn panther_core_is_ok(result) {
        return result.ok == true;
    }

    fn panther_core_is_err(result) {
        return result.ok == false;
    }

    fn panther_core_unwrap_ok(result) {
        if result.ok == true {
            return result.value;
        }
        return null;
    }

    fn panther_core_unwrap_err(result) {
        if result.ok == false {
            return result.error;
        }
        return null;
    }
}