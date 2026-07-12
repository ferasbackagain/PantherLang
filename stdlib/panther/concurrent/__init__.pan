panther main {
    // Worker pool / task execution (PYTHON_BOOTSTRAP_BACKED)
    fn panther_concurrent_spawn(task) {
        return _concurrent_spawn(task);
    }

    fn panther_concurrent_join(task) {
        return _concurrent_join(task);
    }

    fn panther_concurrent_join_timeout(task, timeout_ms) {
        return _concurrent_join_timeout(task, timeout_ms);
    }

    fn panther_concurrent_task_status(task) {
        return _concurrent_task_status(task);
    }

    fn panther_concurrent_task_result(task) {
        return _concurrent_task_result(task);
    }

    fn panther_concurrent_task_error(task) {
        return _concurrent_task_error(task);
    }

    fn panther_concurrent_cancel(task) {
        return _concurrent_cancel(task);
    }

    fn panther_concurrent_worker_count() {
        return _concurrent_worker_count();
    }

    fn panther_concurrent_queue_create() {
        return _concurrent_queue_create();
    }

    fn panther_concurrent_queue_put(queue, value) {
        _concurrent_queue_put(queue, value);
    }

    fn panther_concurrent_queue_get(queue) {
        return _concurrent_queue_get(queue);
    }

    fn panther_concurrent_queue_get_timeout(queue, timeout_ms) {
        return _concurrent_queue_get_timeout(queue, timeout_ms);
    }

    fn panther_concurrent_map(mapper, items) {
        let results = [];
        let n = len(items);
        for i in 0..n {
            results = array_push(results, mapper(items[i]));
        }
        return results;
    }

    fn panther_concurrent_filter(predicate, items) {
        let results = [];
        let n = len(items);
        for i in 0..n {
            if predicate(items[i]) {
                results = array_push(results, items[i]);
            }
        }
        return results;
    }

    fn panther_concurrent_reduce(reducer, items, initial) {
        let acc = initial;
        let n = len(items);
        for i in 0..n {
            acc = reducer(acc, items[i]);
        }
        return acc;
    }

    fn panther_concurrent_for_each(action, items) {
        let n = len(items);
        for i in 0..n {
            action(items[i]);
        }
    }

    // Task group / wait group
    fn panther_concurrent_wait_group() {
        return {count: 0, tasks: []};
    }

    fn panther_concurrent_add(wg, task) {
        wg.tasks = array_push(wg.tasks, task);
        wg.count = wg.count + 1;
    }

    fn panther_concurrent_wait(wg) {
        let i = 0;
        while i < len(wg.tasks) {
            wg.tasks[i]();
            i = i + 1;
        }
        wg.count = 0;
        wg.tasks = [];
    }

    // Semaphore
    fn panther_concurrent_semaphore(permits) {
        return {permits: permits, waiting: 0};
    }

    fn panther_concurrent_acquire(sem) {
        if sem.permits > 0 {
            sem.permits = sem.permits - 1;
            return true;
        }
        sem.waiting = sem.waiting + 1;
        return false;
    }

    fn panther_concurrent_release(sem) {
        if sem.waiting > 0 {
            sem.waiting = sem.waiting - 1;
        } else {
            sem.permits = sem.permits + 1;
        }
    }

    // Mutex
    fn panther_concurrent_mutex() {
        return {locked: false, owner: null};
    }

    fn panther_concurrent_lock(mutex) {
        if !mutex.locked {
            mutex.locked = true;
            return true;
        }
        return false;
    }

    fn panther_concurrent_unlock(mutex) {
        mutex.locked = false;
    }

    // Channel
    fn panther_concurrent_channel(buffer_size) {
        return {buffer: [], size: buffer_size, closed: false};
    }

    fn panther_concurrent_send(ch, value) {
        if ch.closed {
            return false;
        }
        if len(ch.buffer) < ch.size {
            ch.buffer = array_push(ch.buffer, value);
            return true;
        }
        return false;
    }

    fn panther_concurrent_receive(ch) {
        if len(ch.buffer) > 0 {
            let val = ch.buffer[0];
            let new_buf = [];
            let i = 1;
            while i < len(ch.buffer) {
                new_buf = array_push(new_buf, ch.buffer[i]);
                i = i + 1;
            }
            ch.buffer = new_buf;
            return val;
        }
        if ch.closed {
            return null;
        }
        return null;
    }

    fn panther_concurrent_close(ch) {
        ch.closed = true;
    }

    // Promise/Future
    fn panther_concurrent_promise() {
        return {state: "pending", value: null, callbacks: []};
    }

    fn panther_concurrent_resolve(promise, value) {
        promise.state = "resolved";
        promise.value = value;
    }

    fn panther_concurrent_reject(promise, error) {
        promise.state = "rejected";
        promise.value = error;
    }

    fn panther_concurrent_then(promise, on_fulfilled, on_rejected) {
        if promise.state == "resolved" {
            on_fulfilled(promise.value);
        } elif promise.state == "rejected" {
            on_rejected(promise.value);
        } else {
            promise.callbacks = array_push(promise.callbacks, {on_fulfilled: on_fulfilled, on_rejected: on_rejected});
        }
    }

    fn panther_concurrent_all(promises) {
        let results = [];
        let i = 0;
        while i < len(promises) {
            results = array_push(results, "waiting");
            i = i + 1;
        }
        return results;
    }

    fn panther_concurrent_race(promises) {
        return "pending";
    }

    // Timeout
    fn panther_concurrent_timeout(promise, ms) {
        return promise;
    }
}
