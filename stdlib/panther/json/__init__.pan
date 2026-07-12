panther main {
    // Parse
    fn panther_json_parse(text) {
        return json_parse(text);
    }

    fn panther_json_decode(text) {
        return json_decode(text);
    }

    // Stringify
    fn panther_json_stringify(value) {
        return json_stringify(value);
    }

    fn panther_json_encode(value) {
        return json_encode(value);
    }

    // Pretty print
    fn panther_json_pretty(value) {
        return json_pretty(value);
    }

    // Validation
    fn panther_json_valid(text) {
        return json_valid(text);
    }

    // Query - simple path access
    fn panther_json_get(obj, path) {
        let parts = split(path, ".");
        let current = obj;
        let n = len(parts);
        for i in 0..n {
            let part = parts[i];
            // Handle array index: key[0]
            if contains(part, "[") {
                let idx_start = panther_json_index_of(part, "[");
                let key = substring(part, 0, idx_start);
                let idx_str = substring(part, idx_start + 1, len(part) - 1);
                let idx = to_int(idx_str);
                if key != "" {
                    current = current[key];
                }
                current = current[idx];
            } else {
                current = current[part];
            }
            if current == null {
                return null;
            }
        }
        return current;
    }

    // Type checking
    fn panther_json_is_object(value) {
        return type_of(value) == "object";
    }

    fn panther_json_is_array(value) {
        return type_of(value) == "array";
    }

    fn panther_json_is_string(value) {
        return type_of(value) == "string";
    }

    fn panther_json_is_number(value) {
        let t = type_of(value);
        return t == "int" || t == "float";
    }

    fn panther_json_is_bool(value) {
        return type_of(value) == "bool";
    }

    fn panther_json_is_null(value) {
        return type_of(value) == "null";
    }

    // Compact/Minify
    fn panther_json_compact(value) {
        return json_stringify(value);
    }

    // Escape/unescape for JSON strings
    fn panther_json_escape_string(s) {
        return json_stringify(s);
    }

    fn panther_json_unescape_string(s) {
        return json_parse("\"" + s + "\"");
    }

    // Helper functions
    fn panther_json_index_of(s, sub) {
        let max = len(s) - len(sub);
        let i = 0;
        while i <= max {
            if substring(s, i, i + len(sub)) == sub {
                return i;
            }
            i = i + 1;
        }
        return -1;
    }
}