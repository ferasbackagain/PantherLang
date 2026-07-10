panther main {
    fn json_encode(value) {
        return json_stringify(value);
    }

    fn json_decode(text) {
        return json_parse(text);
    }

    fn json_pretty(value) {
        return json_stringify(value);
    }

    fn json_valid(text) {
        return json_parse(text) != null;
    }
}
