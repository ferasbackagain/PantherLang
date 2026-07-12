panther main {
    // Logging levels
    fn panther_logging_debug(message) {
        return log_debug(message);
    }

    fn panther_logging_info(message) {
        return log_info(message);
    }

    fn panther_logging_warn(message) {
        return log_warn(message);
    }

    fn panther_logging_error(message) {
        return log_error(message);
    }

    fn panther_logging_set_level(level) {
        return log_set_level(level);
    }

    // Structured logging with key-value pairs
    fn panther_logging_log(level, message, fields) {
        let msg = message;
        // Note: structured fields not fully supported yet
        if level == "debug" {
            return log_debug(msg);
        } elif level == "info" {
            return log_info(msg);
        } elif level == "warn" {
            return log_warn(msg);
        } elif level == "error" {
            return log_error(msg);
        }
        return "";
    }

    // Convenience functions
    fn panther_logging_debugf(template, args) {
        // Simple template formatting
        let msg = template;
        let i = 0;
        while i < len(args) {
            msg = replace(msg, "{" + to_string(i) + "}", to_string(args[i]));
            i = i + 1;
        }
        return log_debug(msg);
    }

    fn panther_logging_infof(template, args) {
        let msg = template;
        let i = 0;
        while i < len(args) {
            msg = replace(msg, "{" + to_string(i) + "}", to_string(args[i]));
            i = i + 1;
        }
        return log_info(msg);
    }

    fn panther_logging_warnf(template, args) {
        let msg = template;
        let i = 0;
        while i < len(args) {
            msg = replace(msg, "{" + to_string(i) + "}", to_string(args[i]));
            i = i + 1;
        }
        return log_warn(msg);
    }

    fn panther_logging_errorf(template, args) {
        let msg = template;
        let i = 0;
        while i < len(args) {
            msg = replace(msg, "{" + to_string(i) + "}", to_string(args[i]));
            i = i + 1;
        }
        return log_error(msg);
    }

    // Log level constants
    fn panther_logging_LEVEL_DEBUG() {
        return "debug";
    }

    fn panther_logging_LEVEL_INFO() {
        return "info";
    }

    fn panther_logging_LEVEL_WARN() {
        return "warn";
    }

    fn panther_logging_LEVEL_ERROR() {
        return "error";
    }
}