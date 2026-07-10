panther main {
    fn now() {
        return time_now();
    }

    fn wait(secs) {
        time_sleep(secs);
    }

    fn timestamp() {
        return time_now();
    }
}
