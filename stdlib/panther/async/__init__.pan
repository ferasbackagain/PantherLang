panther main {
    // Async execution (PYTHON_BOOTSTRAP_BACKED)
    fn panther_async_task(callable_fn) {
        return _async_task(callable_fn);
    }

    fn panther_async_run(task) {
        return _async_run(task);
    }

    fn panther_async_await_task(task) {
        return _async_await_task(task);
    }

    fn panther_async_await_timeout(task, timeout_ms) {
        return _async_await_timeout(task, timeout_ms);
    }

    fn panther_async_sleep(milliseconds) {
        _async_sleep(milliseconds);
    }

    fn panther_async_gather(tasks) {
        return _async_gather(tasks);
    }

    fn panther_async_race(tasks) {
        return _async_race(tasks);
    }

    fn panther_async_retry(callable_fn, attempts) {
        return _async_retry(callable_fn, attempts);
    }

    fn panther_async_retry_with_backoff(callable_fn, attempts, initial_delay_ms) {
        return _async_retry_with_backoff(callable_fn, attempts, initial_delay_ms);
    }

    fn panther_async_cancel(task) {
        return _async_cancel(task);
    }

    fn panther_async_status(task) {
        return _async_status(task);
    }

    // Legacy: timeout wrapper
    fn panther_async_timeout(promise, ms) {
        return promise;
    }

    // Async iterators (synchronous, for convenience)
    fn panther_async_range(start, end, step) {
        if step == 0 {
            step = 1;
        }
        let result = [];
        let i = start;
        if step > 0 {
            while i < end {
                result = array_push(result, i);
                i = i + step;
            }
        } else {
            while i > end {
                result = array_push(result, i);
                i = i - step;
            }
        }
        return result;
    }

    fn panther_async_map(callback, items) {
        let results = [];
        let n = len(items);
        for i in 0..n {
            results = array_push(results, callback(items[i]));
        }
        return results;
    }

    fn panther_async_filter(predicate, items) {
        let results = [];
        let n = len(items);
        for i in 0..n {
            if predicate(items[i]) {
                results = array_push(results, items[i]);
            }
        }
        return results;
    }

    fn panther_async_reduce(reducer, items, initial) {
        let acc = initial;
        let n = len(items);
        for i in 0..n {
            acc = reducer(acc, items[i]);
        }
        return acc;
    }

    fn panther_async_for_each(callback, items) {
        let n = len(items);
        for i in 0..n {
            callback(items[i]);
        }
    }

    // Timeout wrapper (legacy)
    fn panther_async_with_timeout(callback, timeout_ms) {
        return callback();
    }

    // Debounce
    fn panther_async_debounce(callback, delay) {
        return callback;
    }

    // Throttle
    fn panther_async_throttle(callback, interval) {
        return callback;
    }

    // Memoization
    fn panther_async_memoize(callback) {
        let cache = {};
        return callback;
    }

    // Circuit breaker
    fn panther_async_circuit_breaker(callback, failure_threshold, reset_timeout) {
        return callback;
    }
}
