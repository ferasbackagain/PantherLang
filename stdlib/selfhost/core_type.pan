panther main {
    fn to_int(value) {
        return int(value);
    }

    fn to_float(value) {
        return float(value);
    }

    fn to_string(value) {
        return string(value);
    }

    fn is_string(value) {
        return type_of(value) == "string";
    }

    fn is_int(value) {
        return type_of(value) == "int";
    }

    fn is_float(value) {
        return type_of(value) == "float";
    }

    fn is_bool(value) {
        return type_of(value) == "bool";
    }

    fn is_array(value) {
        return type_of(value) == "array";
    }

    fn is_object(value) {
        return type_of(value) == "object";
    }

    fn is_null(value) {
        return type_of(value) == "null";
    }

    fn is_number(value) {
        let t = type_of(value);
        return t == "int" || t == "float";
    }
}
