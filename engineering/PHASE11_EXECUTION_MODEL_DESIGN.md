# PHASE 11 — Execution Model Design

## Architecture

```
PantherLang program (user code)
    │
    ├── import panther.concurrent as conc
    │       │
    │       └── conc.spawn(fn) → self-hosted panther_concurrent_spawn
    │               │
    │               └── calls Python flat builtin _concurrent_spawn(fn)
    │                       │
    │                       └── threading.Thread(target=fn, daemon=True)
    │                           └── returns task dict {task_id, state, value, error}
    │
    └── import panther.async as async_pkg
            │
            └── async_pkg.task(fn) → self-hosted panther_async_task
                    │
                    └── calls Python flat builtin _async_task(fn)
                            │
                            └── ThreadPoolExecutor with dedicated thread
                                └── returns task dict {task_id, state, value, error}
```

## Task States

CREATED → RUNNING → COMPLETED
                 → FAILED
                 → CANCELLED
                 → TIMED_OUT

## Task Representation

Panther dict with fields:
- task_id: string (UUID)
- state: string (CREATED|RUNNING|COMPLETED|FAILED|CANCELLED|TIMED_OUT)
- value: any (return value on COMPLETED)
- error: string (error message on FAILED)

## Python-Backed Primitives

### Concurrent (threading)
| Function | Implementation |
|---|---|
| _concurrent_spawn(fn) | threading.Thread(target=fn, daemon=True), returns task dict |
| _concurrent_join(task) | thread.join(), returns task dict with final state |
| _concurrent_join_timeout(task, ms) | thread.join(timeout=ms/1000), checks state |
| _concurrent_task_status(task) | reads state from registry |
| _concurrent_task_result(task) | reads value from registry |
| _concurrent_task_error(task) | reads error from registry |
| _concurrent_cancel(task) | sets CANCELLED flag, thread checks cooperatively |
| _concurrent_worker_count() | len(active_threads) |
| _concurrent_queue_create() | queue.Queue wrapped in dict |
| _concurrent_queue_put(q, v) | q.put(v) |
| _concurrent_queue_get(q) | q.get() (blocking) |
| _concurrent_queue_get_timeout(q, ms) | q.get(timeout=ms/1000) |

### Async (ThreadPoolExecutor + synchronization)
| Function | Implementation |
|---|---|
| _async_task(fn) | ThreadPoolExecutor.submit(fn), returns task dict |
| _async_run(task) | starts the task (already started on submit) |
| _async_await_task(task) | future.result() (blocking) |
| _async_await_timeout(task, ms) | future.result(timeout=ms/1000) |
| _async_sleep(ms) | time.sleep(ms/1000) |
| _async_gather(tasks) | concurrent.futures.wait(ALL_COMPLETED), collect results |
| _async_race(tasks) | concurrent.futures.wait(FIRST_COMPLETED) |
| _async_retry(fn, attempts) | loop with retry, blocking sleep |
| _async_retry_with_backoff(fn, attempts, delay) | loop with exponential backoff |
| _async_cancel(task) | future.cancel() |
| _async_status(task) | reads state from future |

## Classification

All implemented: PYTHON_BOOTSTRAP_BACKED

## Thread Safety

- Task registry uses threading.Lock for concurrent access
- Each spawned task runs in its own thread with its own environment child scope
- Queue operations delegate to thread-safe queue.Queue
- Worker threads are daemon threads (don't prevent interpreter exit)
- Active workers are tracked; all are joined during clean shutdown

## Migration Path to Native

1. Replace threading.Thread with native pthreads via ctypes
2. Replace queue.Queue with native mpsc queue
3. Replace ThreadPoolExecutor with native thread pool
4. Replace concurrent.futures with native synchronization primitives

## Platform Support

Linux: full (via Python threading which uses pthreads)
macOS: full (same)
Windows: full (via Python threading which uses Win32 threads)
