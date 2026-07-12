// PantherLang Phase 11 — Real Concurrency & Async Example
// Uses threading.Thread (concurrent) and ThreadPoolExecutor (async)

panther main {
    import panther.concurrent as conc;
    import panther.async as async_pkg;

    print("=== PantherLang Phase 11: Concurrency & Async ===");
    print("");

    // =====================================================================
    // 1. Concurrent: Spawn a thread, join for result
    // =====================================================================
    print("--- 1. Basic concurrent spawn/join ---");
    let t1 = conc.spawn(fn() { return 10 + 20; });
    let r1 = conc.join(t1);
    print("t1 result: " + to_string(r1["value"]));

    // Multiple concurrent tasks
    let ta = conc.spawn(fn() { return "A"; });
    let tb = conc.spawn(fn() { return "B"; });
    let tc = conc.spawn(fn() { return "C"; });
    print("ta: " + conc.join(ta)["value"]);
    print("tb: " + conc.join(tb)["value"]);
    print("tc: " + conc.join(tc)["value"]);

    // =====================================================================
    // 2. Task lifecycle: status, task_result, task_error
    // =====================================================================
    print("");
    print("--- 2. Task lifecycle ---");
    let t2 = conc.spawn(fn() { return 42; });
    print("status before join: " + conc.task_status(t2));
    conc.join(t2);
    print("status after join: " + conc.task_status(t2));
    let res2 = conc.task_result(t2);
    print("task_result: " + to_string(res2["value"]));

    // =====================================================================
    // 3. Error handling in concurrent tasks
    // =====================================================================
    print("");
    print("--- 3. Error handling ---");
    let t3 = conc.spawn(fn() { let x = 1 / 0; });
    let r3 = conc.join(t3);
    print("error result: " + r3["error"]);

    // =====================================================================
    // 4. Async: thread pool tasks
    // =====================================================================
    print("");
    print("--- 4. Async tasks ---");
    let a1 = async_pkg.task(fn() { return 100; });
    let ar1 = async_pkg.await_task(a1);
    print("async result: " + to_string(ar1["value"]));

    // =====================================================================
    // 5. Async gather — run many tasks concurrently
    // =====================================================================
    print("");
    print("--- 5. Async gather ---");
    let many = [];
    many = array_push(many, async_pkg.task(fn() { return 1; }));
    many = array_push(many, async_pkg.task(fn() { return 2; }));
    many = array_push(many, async_pkg.task(fn() { return 3; }));
    many = array_push(many, async_pkg.task(fn() { return 4; }));
    many = array_push(many, async_pkg.task(fn() { return 5; }));
    let gathered = async_pkg.gather(many);
    let sum = 0;
    let g = 0;
    while g < len(gathered) {
        sum = sum + gathered[g]["value"];
        g = g + 1;
    }
    print("gather sum: " + to_string(sum));

    // =====================================================================
    // 6. Async race — first-to-finish wins
    // =====================================================================
    print("");
    print("--- 6. Async race ---");
    let fast = async_pkg.task(fn() { return "winner"; });
    let slow = async_pkg.task(fn() { async_pkg.sleep(50); return "loser"; });
    let raced = async_pkg.race([fast, slow]);
    print("race winner: " + raced["value"]);

    // =====================================================================
    // 7. Async retry with backoff
    // =====================================================================
    print("");
    print("--- 7. Async retry ---");
    let retried = async_pkg.retry_with_backoff(fn() { return 77; }, 3, 10);
    print("retry result: " + to_string(retried["value"]));

    // =====================================================================
    // 8. Concurrent queues
    // =====================================================================
    print("");
    print("--- 8. Concurrent queue ---");
    let q = conc.queue_create();
    conc.queue_put(q, "first");
    conc.queue_put(q, "second");
    conc.queue_put(q, "third");
    print("queue get: " + conc.queue_get(q));
    print("queue get: " + conc.queue_get(q));
    print("queue get: " + conc.queue_get(q));

    // =====================================================================
    // 9. Queue shared between threads (producer-consumer)
    // =====================================================================
    print("");
    print("--- 9. Queue producer-consumer ---");
    let sq = conc.queue_create();
    let producer = conc.spawn(fn() {
        conc.queue_put(sq, "produced");
        return "ok";
    });
    conc.join(producer);
    print("consumed: " + conc.queue_get(sq));

    // =====================================================================
    // 10. Join timeout
    // =====================================================================
    print("");
    print("--- 10. Join timeout ---");
    let tt = conc.spawn(fn() { return 999; });
    let tr = conc.join_timeout(tt, 3000);
    print("timed join: " + to_string(tr["value"]));

    // =====================================================================
    // 11. Worker count
    // =====================================================================
    print("");
    print("--- 11. Worker count ---");
    print("active workers: " + to_string(conc.worker_count()));

    // =====================================================================
    // 12. Cancel
    // =====================================================================
    print("");
    print("--- 12. Cancel ---");
    let tcancel = conc.spawn(fn() { return 0; });
    let cancelled = conc.cancel(tcancel);
    print("cancelled: " + to_string(cancelled));

    // =====================================================================
    // Summary
    // =====================================================================
    print("");
    print("=== All Phase 11 examples completed ===");
}
