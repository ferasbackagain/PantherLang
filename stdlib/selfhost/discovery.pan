panther main {
    fn net_dedup_strings(items) {
        let result = [];
        let n = len(items);
        for i in 0..(n - 1) {
            let current = items[i];
            let found = false;
            let m = len(result);
            if m > 0 {
                for j in 0..(m - 1) {
                    if result[j] == current {
                        found = true;
                    }
                }
            }
            if found == false {
                array_push(result, current);
            }
        }
        return result;
    }

    fn net_count_open(results) {
        let count = 0;
        let n = len(results);
        if n > 0 {
            for i in 0..(n - 1) {
                if results[i] == "open" {
                    count = count + 1;
                }
            }
        }
        return count;
    }

    fn net_count_closed(results) {
        let count = 0;
        let n = len(results);
        if n > 0 {
            for i in 0..(n - 1) {
                if results[i] == "closed" {
                    count = count + 1;
                }
            }
        }
        return count;
    }

    fn net_result_summary(results) {
        let open_count = net_count_open(results);
        let closed_count = net_count_closed(results);
        let total = len(results);
        return "open=" + to_string(open_count) + ";closed=" + to_string(closed_count) + ";total=" + to_string(total);
    }

    fn net_format_duration(start_ms, end_ms) {
        let diff = end_ms - start_ms;
        let seconds = to_int(diff / 1000);
        let millis = diff - (seconds * 1000);
        return to_string(seconds) + "." + to_string(millis) + "s";
    }
}
