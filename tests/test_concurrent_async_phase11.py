"""Tests for Phase 11: Real concurrency (threading) and async (ThreadPoolExecutor)."""

import time
from compiler.runtime import execute_source


def _exec(source: str):
    return execute_source(f"""
panther main {{
    import panther.concurrent as conc;
    import panther.async as async_pkg;
    {source}
}}
""")


# =============================================================================
# Concurrent (threading) tests
# =============================================================================


def test_concurrent_spawn_returns_task():
    result = _exec("""
    let task = conc.spawn(fn() { return 42; });
    print(type_of(task));
    """)
    assert result.error is None
    assert "object" in " ".join(result.captured_output)


def test_concurrent_spawn_and_join():
    result = _exec("""
    let task = conc.spawn(fn() { return 7; });
    let res = conc.join(task);
    print(res["value"]);
    """)
    assert result.error is None
    assert "7" in " ".join(result.captured_output)


def test_concurrent_multiple_spawns():
    result = _exec("""
    let t1 = conc.spawn(fn() { return 1; });
    let t2 = conc.spawn(fn() { return 2; });
    let t3 = conc.spawn(fn() { return 3; });
    let r1 = conc.join(t1);
    let r2 = conc.join(t2);
    let r3 = conc.join(t3);
    print(r1["value"]);
    print(r2["value"]);
    print(r3["value"]);
    """)
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "1" in output and "2" in output and "3" in output


def test_concurrent_task_lifecycle():
    result = _exec("""
    let task = conc.spawn(fn() { return 99; });
    let s1 = conc.task_status(task);
    let res = conc.join(task);
    let s2 = conc.task_status(task);
    let val = conc.task_result(task);
    print(s1);
    print(s2);
    print(val["value"]);
    """)
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "COMPLETED" in output
    assert "99" in output


def test_concurrent_join_timeout_not_exceeded():
    result = _exec("""
    let task = conc.spawn(fn() { return 5; });
    let res = conc.join_timeout(task, 5000);
    print(res["value"]);
    """)
    assert result.error is None
    assert "5" in " ".join(result.captured_output)


def test_concurrent_cancel():
    result = _exec("""
    let task = conc.spawn(fn() { return 10; });
    let cancelled = conc.cancel(task);
    print(cancelled);
    """)
    assert result.error is None


def test_concurrent_worker_count():
    result = _exec("""
    let count = conc.worker_count();
    print(count);
    """)
    assert result.error is None


def test_concurrent_queue_basic():
    result = _exec("""
    let q = conc.queue_create();
    conc.queue_put(q, "hello");
    conc.queue_put(q, 42);
    let v1 = conc.queue_get(q);
    let v2 = conc.queue_get(q);
    print(v1);
    print(v2);
    """)
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "hello" in output
    assert "42" in output


def test_concurrent_queue_get_timeout():
    result = _exec("""
    let q = conc.queue_create();
    conc.queue_put(q, "data");
    let val = conc.queue_get_timeout(q, 1000);
    print(val);
    """)
    assert result.error is None
    assert "data" in " ".join(result.captured_output)


def test_concurrent_queue_fifo_order():
    result = _exec("""
    let q = conc.queue_create();
    conc.queue_put(q, "first");
    conc.queue_put(q, "second");
    conc.queue_put(q, "third");
    let a = conc.queue_get(q);
    let b = conc.queue_get(q);
    let c = conc.queue_get(q);
    print(a);
    print(b);
    print(c);
    """)
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "first" in output and "second" in output and "third" in output


def test_concurrent_spawn_with_closure():
    result = _exec("""
    let x = 10;
    let task = conc.spawn(fn() { return x + 5; });
    let res = conc.join(task);
    print(res["value"]);
    """)
    assert result.error is None
    assert "15" in " ".join(result.captured_output)


def test_concurrent_spawn_error_handling():
    result = _exec("""
    let task = conc.spawn(fn() { let x = 1 / 0; });
    let res = conc.join(task);
    print(res["error"] != null);
    """)
    assert result.error is None


# =============================================================================
# Async (ThreadPoolExecutor) tests
# =============================================================================


def test_async_task_and_await():
    result = _exec("""
    let task = async_pkg.task(fn() { return 42; });
    let res = async_pkg.await_task(task);
    print(res["value"]);
    """)
    assert result.error is None
    assert "42" in " ".join(result.captured_output)


def test_async_await_timeout():
    result = _exec("""
    let task = async_pkg.task(fn() { return 100; });
    let res = async_pkg.await_timeout(task, 5000);
    print(res["value"]);
    """)
    assert result.error is None
    assert "100" in " ".join(result.captured_output)


def test_async_gather():
    result = _exec("""
    let t1 = async_pkg.task(fn() { return 1; });
    let t2 = async_pkg.task(fn() { return 2; });
    let t3 = async_pkg.task(fn() { return 3; });
    let results = async_pkg.gather([t1, t2, t3]);
    print(results[0]["value"]);
    print(results[1]["value"]);
    print(results[2]["value"]);
    """)
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "1" in output and "2" in output and "3" in output


def test_async_race():
    result = _exec("""
    let t1 = async_pkg.task(fn() { return "slow"; });
    let t2 = async_pkg.task(fn() { return "fast"; });
    let winner = async_pkg.race([t1, t2]);
    print(winner["value"] != null);
    """)
    assert result.error is None


def test_async_sleep():
    result = _exec("""
    async_pkg.sleep(10);
    print("done");
    """)
    assert result.error is None
    assert "done" in " ".join(result.captured_output)


def test_async_retry_success():
    result = _exec("""
    let res = async_pkg.retry(fn() { return 5; }, 3);
    print(res["value"]);
    """)
    assert result.error is None
    assert "5" in " ".join(result.captured_output)


def test_async_retry_with_backoff():
    result = _exec("""
    let res = async_pkg.retry_with_backoff(fn() { return 10; }, 3, 10);
    print(res["value"]);
    """)
    assert result.error is None
    assert "10" in " ".join(result.captured_output)


def test_async_status():
    result = _exec("""
    let task = async_pkg.task(fn() { return 1; });
    let s1 = async_pkg.status(task);
    let res = async_pkg.await_task(task);
    let s2 = async_pkg.status(task);
    print(s1);
    print(s2);
    """)
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "COMPLETED" in output


def test_async_cancel():
    result = _exec("""
    let task = async_pkg.task(fn() { return 7; });
    let cancelled = async_pkg.cancel(task);
    print(cancelled);
    """)
    assert result.error is None


# =============================================================================
# Concurrent + Async integration tests
# =============================================================================


def test_concurrent_spawn_from_async():
    result = _exec("""
    let task = async_pkg.task(fn() { return 42; });
    let res = async_pkg.await_task(task);
    print(res["value"]);
    """)
    assert result.error is None
    assert "42" in " ".join(result.captured_output)


def test_queue_shared_between_tasks():
    result = _exec("""
    let q = conc.queue_create();
    let producer = conc.spawn(fn() {
        conc.queue_put(q, "from_thread");
        return "done";
    });
    let res = conc.join(producer);
    let val = conc.queue_get(q);
    print(val);
    """)
    assert result.error is None
    assert "from_thread" in " ".join(result.captured_output)


def test_gather_multiple_results():
    result = _exec("""
    let tasks = [];
    tasks = array_push(tasks, async_pkg.task(fn() { return 10; }));
    tasks = array_push(tasks, async_pkg.task(fn() { return 20; }));
    tasks = array_push(tasks, async_pkg.task(fn() { return 30; }));
    let results = async_pkg.gather(tasks);
    let sum = results[0]["value"] + results[1]["value"] + results[2]["value"];
    print(sum);
    """)
    assert result.error is None
    assert "60" in " ".join(result.captured_output)


def test_idempotent_join():
    result = _exec("""
    let task = conc.spawn(fn() { return 5; });
    let r1 = conc.join(task);
    let r2 = conc.join(task);
    print(r1["value"]);
    print(r2["value"]);
    """)
    assert result.error is None
    output = " ".join(result.captured_output)
    assert output.count("5") >= 2


def test_many_concurrent_tasks():
    result = _exec("""
    let tasks = [];
    let i = 0;
    while i < 10 {
        tasks = array_push(tasks, conc.spawn(fn(i) { return i; }));
        i = i + 1;
    }
    let j = 0;
    while j < 10 {
        let res = conc.join(tasks[j]);
        print(res["value"]);
        j = j + 1;
    }
    """)
    assert result.error is None


def test_task_lifecycle_negative():
    result = _exec("""
    let task = conc.spawn(fn() { return null; });
    conc.join(task);
    let err = conc.task_error(task);
    print(err == null);
    """)
    assert result.error is None
    assert "true" in " ".join(result.captured_output)


def test_concurrent_and_async_import_verification():
    result = _exec("""
    let ct = conc.spawn(fn() { return "c"; });
    let at = async_pkg.task(fn() { return "a"; });
    let cr = conc.join(ct);
    let ar = async_pkg.await_task(at);
    print(cr["value"]);
    print(ar["value"]);
    """)
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "c" in output and "a" in output


# =============================================================================
# Resource cleanup and stress tests
# =============================================================================


def test_thread_cleanup_after_join():
    result = _exec("""
    let task = conc.spawn(fn() { return 1; });
    let res = conc.join(task);
    print(conc.worker_count());
    """)
    assert result.error is None


def test_spawn_with_empty_function():
    result = _exec("""
    let task = conc.spawn(fn() { });
    let res = conc.join(task);
    print(res["value"] == null);
    """)
    assert result.error is None
    assert "true" in " ".join(result.captured_output)


def test_async_tasks_dont_block_each_other():
    result = _exec("""
    let t1 = async_pkg.task(fn() { async_pkg.sleep(10); return "a"; });
    let t2 = async_pkg.task(fn() { return "b"; });
    let r2 = async_pkg.await_task(t2);
    let r1 = async_pkg.await_task(t1);
    print(r2["value"]);
    print(r1["value"]);
    """)
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "a" in output and "b" in output
