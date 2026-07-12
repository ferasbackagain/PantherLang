panther main {
    fn core_time_now() {
        return time_now();
    }

    fn core_time_wait(secs) {
        time_sleep(secs);
    }

    fn core_time_timestamp() {
        return time_now();
    }
}
