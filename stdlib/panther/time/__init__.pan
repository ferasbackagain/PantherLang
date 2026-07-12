panther main {
    // Current time
    fn panther_time_now() {
        return time();
    }

    fn panther_time_timestamp() {
        return time();
    }

    fn panther_time_monotonic() {
        return time();
    }

    // Sleep
    fn panther_time_sleep(secs) {
        sleep(secs);
    }

    fn panther_time_sleep_ms(ms) {
        sleep(ms / 1000.0);
    }

    fn panther_time_sleep_us(us) {
        sleep(us / 1000000.0);
    }

    // Formatting
    fn panther_time_format(timestamp, fmt) {
        return datetime_format(timestamp, fmt);
    }

    fn panther_time_format_iso(timestamp) {
        return datetime_format(timestamp, "%Y-%m-%dT%H:%M:%S");
    }

    fn panther_time_format_date(timestamp) {
        return datetime_format(timestamp, "%Y-%m-%d");
    }

    fn panther_time_format_time(timestamp) {
        return datetime_format(timestamp, "%H:%M:%S");
    }

    fn panther_time_parse(s) {
        return datetime_parse(s);
    }

    fn panther_time_parse_iso(s) {
        return datetime_parse(s);
    }

    // Duration helpers
    fn panther_time_duration(seconds) {
        return seconds;
    }

    fn panther_time_seconds(seconds) {
        return seconds;
    }

    fn panther_time_minutes(minutes) {
        return minutes * 60;
    }

    fn panther_time_hours(hours) {
        return hours * 3600;
    }

    fn panther_time_days(days) {
        return days * 86400;
    }

    // Time components
    fn panther_time_year(timestamp) {
        let dt = datetime_format(timestamp, "%Y");
        return to_int(dt);
    }

    fn panther_time_month(timestamp) {
        let dt = datetime_format(timestamp, "%m");
        return to_int(dt);
    }

    fn panther_time_day(timestamp) {
        let dt = datetime_format(timestamp, "%d");
        return to_int(dt);
    }

    fn panther_time_hour(timestamp) {
        let dt = datetime_format(timestamp, "%H");
        return to_int(dt);
    }

    fn panther_time_minute(timestamp) {
        let dt = datetime_format(timestamp, "%M");
        return to_int(dt);
    }

    fn panther_time_second(timestamp) {
        let dt = datetime_format(timestamp, "%S");
        return to_int(dt);
    }

    fn panther_time_weekday(timestamp) {
        let dt = datetime_format(timestamp, "%w");
        return to_int(dt);
    }

    fn panther_time_yearday(timestamp) {
        let dt = datetime_format(timestamp, "%j");
        return to_int(dt);
    }

    // Comparison
    fn panther_time_is_before(a, b) {
        return a < b;
    }

    fn panther_time_is_after(a, b) {
        return a > b;
    }

    fn panther_time_diff(a, b) {
        if a > b {
            return a - b;
        }
        return b - a;
    }

    // Formatting durations
    fn panther_time_format_duration(seconds) {
        let s = to_int(seconds);
        if s < 60 {
            return to_string(s) + "s";
        }
        let m = s / 60;
        if m < 60 {
            return to_string(m) + "m " + to_string(s % 60) + "s";
        }
        let h = m / 60;
        if h < 24 {
            return to_string(h) + "h " + to_string(m % 60) + "m";
        }
        let d = h / 24;
        return to_string(d) + "d " + to_string(h % 24) + "h";
    }

    // Timezone (UTC offset)
    fn panther_time_utc_offset() {
        return 0;
    }
}