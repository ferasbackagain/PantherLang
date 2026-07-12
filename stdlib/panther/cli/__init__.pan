panther main {
    // CLI argument parsing
    // Returns flat object: flags as top-level keys, "_positional" for positional args
    fn panther_cli_parse(args) {
        let parsed = {_positional: []};
        
        let i = 0;
        while i < len(args) {
            let arg = args[i];
            if starts_with(arg, "--") {
                let flag = substring(arg, 2);
                if i + 1 < len(args) && !starts_with(args[i + 1], "-") {
                    parsed[flag] = args[i + 1];
                    i = i + 2;
                } else {
                    parsed[flag] = true;
                    i = i + 1;
                }
            } elif starts_with(arg, "-") && len(arg) > 1 {
                let flag = substring(arg, 1);
                parsed[flag] = true;
                i = i + 1;
            } else {
                parsed._positional = array_push(parsed._positional, arg);
                i = i + 1;
            }
        }
        
        return parsed;
    }

    fn panther_cli_get_flag(parsed, name, default) {
        let flag_val = parsed[name];
        if flag_val != null {
            return flag_val;
        }
        return default;
    }

    fn panther_cli_get_option(parsed, name, default) {
        let opt_val = parsed[name];
        if opt_val != null {
            return opt_val;
        }
        return default;
    }

    fn panther_cli_get_positional(parsed, index, default) {
        if index < len(parsed._positional) {
            return parsed._positional[index];
        }
        return default;
    }

    fn panther_cli_positional_count(parsed) {
        return len(parsed._positional);
    }

    // Help generation
    fn panther_cli_usage(name, description, options) {
        let usage = "Usage: " + name + " [options]\n\n";
        if description != "" {
            usage = usage + description + "\n\n";
        }
        usage = usage + "Options:\n";
        
        let opts = options;
        let n = len(opts);
        for i in 0..n {
            let opt = opts[i];
            usage = usage + "  " + opt.flag + "  " + opt.description + "\n";
        }
        
        return usage;
    }

    fn panther_cli_help(name, description, options) {
        return panther_cli_usage(name, description, options);
    }

    // Version
    fn panther_cli_version(version) {
        return version;
    }

    // Exit codes
    fn panther_cli_EXIT_SUCCESS() {
        return 0;
    }

    fn panther_cli_EXIT_FAILURE() {
        return 1;
    }

    fn panther_cli_EXIT_USAGE() {
        return 2;
    }

    // Progress bar (simple)
    fn panther_cli_progress_bar(current, total, width) {
        let percent = (current * 100) / total;
        let filled = (width * current) / total;
        let bar = "[";
        let i = 0;
        while i < width {
            if i < filled {
                bar = bar + "=";
            } else {
                bar = bar + " ";
            }
            i = i + 1;
        }
        bar = bar + "]";
        return bar + " " + to_string(percent) + "%";
    }

    // Color output (ANSI)
    fn panther_cli_color_red(text) {
        return "\033[31m" + text + "\033[0m";
    }

    fn panther_cli_color_green(text) {
        return "\033[32m" + text + "\033[0m";
    }

    fn panther_cli_color_yellow(text) {
        return "\033[33m" + text + "\033[0m";
    }

    fn panther_cli_color_blue(text) {
        return "\033[34m" + text + "\033[0m";
    }

    fn panther_cli_color_cyan(text) {
        return "\033[36m" + text + "\033[0m";
    }

    fn panther_cli_color_bold(text) {
        return "\033[1m" + text + "\033[0m";
    }

    fn panther_cli_color_reset(text) {
        return "\033[0m" + text;
    }
}