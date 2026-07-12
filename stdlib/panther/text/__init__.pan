panther main {
    // Basic operations
    fn panther_text_len(s) {
        return len(s);
    }

    fn panther_text_trim(s) {
        return trim(s);
    }

    fn panther_text_trim_start(s) {
        let i = 0;
        let max = len(s);
        while i < max && substring(s, i, i + 1) == " " {
            i = i + 1;
        }
        return substring(s, i);
    }

    fn panther_text_trim_end(s) {
        let i = len(s) - 1;
        while i >= 0 && substring(s, i, i + 1) == " " {
            i = i - 1;
        }
        return substring(s, 0, i + 1);
    }

    fn panther_text_split(s, sep) {
        return split(s, sep);
    }

    fn panther_text_join(sep, items) {
        return join(sep, items);
    }

    fn panther_text_contains(s, sub) {
        return contains(s, sub);
    }

    fn panther_text_starts_with(s, prefix) {
        return starts_with(s, prefix);
    }

    fn panther_text_ends_with(s, suffix) {
        return ends_with(s, suffix);
    }

    fn panther_text_replace(s, old, new) {
        return replace(s, old, new);
    }

    fn panther_text_replace_all(s, old, new) {
        return replace(s, old, new);
    }

    fn panther_text_upper(s) {
        return upper(s);
    }

    fn panther_text_lower(s) {
        return lower(s);
    }

    fn panther_text_capitalize(s) {
        if len(s) == 0 {
            return s;
        }
        return upper(substring(s, 0, 1)) + lower(substring(s, 1));
    }

    fn panther_text_substring(s, start, end) {
        return substring(s, start, end);
    }

    fn panther_text_char_at(s, index) {
        if index < 0 || index >= len(s) {
            return "";
        }
        return substring(s, index, index + 1);
    }

    fn panther_text_repeat(s, n) {
        let result = "";
        let i = 0;
        while i < n {
            result = result + s;
            i = i + 1;
        }
        return result;
    }

    fn panther_text_pad_start(s, length, pad_char) {
        if len(pad_char) == 0 {
            pad_char = " ";
        }
        while len(s) < length {
            s = pad_char + s;
        }
        return s;
    }

    fn panther_text_pad_end(s, length, pad_char) {
        if len(pad_char) == 0 {
            pad_char = " ";
        }
        while len(s) < length {
            s = s + pad_char;
        }
        return s;
    }

    fn panther_text_reverse(s) {
        let result = "";
        let i = len(s) - 1;
        while i >= 0 {
            result = result + substring(s, i, i + 1);
            i = i - 1;
        }
        return result;
    }

    fn panther_text_to_lines(s) {
        return split(s, "\n");
    }

    fn panther_text_to_words(s) {
        return split(s, " ");
    }

    // Case conversion
    fn panther_text_camel_case(s) {
        let words = split(s, " ");
        let result = "";
        let i = 0;
        while i < len(words) {
            let w = words[i];
            if i == 0 {
                result = result + lower(w);
            } else {
                result = result + panther_text_capitalize(w);
            }
            i = i + 1;
        }
        return result;
    }

    fn panther_text_snake_case(s) {
        return lower(replace(s, " ", "_"));
    }

    fn panther_text_kebab_case(s) {
        return lower(replace(s, " ", "-"));
    }

    // Search
    fn panther_text_index_of(s, sub) {
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

    fn panther_text_last_index_of(s, sub) {
        let i = len(s) - len(sub);
        while i >= 0 {
            if substring(s, i, i + len(sub)) == sub {
                return i;
            }
            i = i - 1;
        }
        return -1;
    }

    // Validation
    fn panther_text_is_empty(s) {
        return len(s) == 0;
    }

    fn panther_text_is_blank(s) {
        return trim(s) == "";
    }

    fn panther_text_matches(s, pattern) {
        return regex_match(pattern, s);
    }

    // Formatting
    fn panther_text_format(template, values) {
        let result = template;
        let i = 0;
        while i < len(values) {
            result = replace(result, "{" + to_string(i) + "}", to_string(values[i]));
            i = i + 1;
        }
        return result;
    }

    // Encoding helpers
    fn panther_text_base64_encode(s) {
        return crypto_base64_encode(s);
    }

    fn panther_text_base64_decode(s) {
        return crypto_base64_decode(s);
    }

    fn panther_text_url_encode(s) {
        return url_encode(s);
    }

    fn panther_text_url_decode(s) {
        return url_decode(s);
    }
}