# Capstone: CLI Task Manager

## Level
Beginner

## Track
CLI

## Prerequisites
- Academy Lessons 1-7
- Book Chapters 1-5

## Objective
Build a CLI task manager that demonstrates filesystem persistence, JSON serialization, and array manipulation.

## Requirements
1. Use `panther main` as the entry point
2. Simulate commands via variables: `mode = "add"`, `task_text = "Buy groceries"`, etc.
3. Persist tasks to a JSON file using `mkdir`, `write_file`, `read_file`, `file_exists`
4. Use `json_encode`/`json_decode` for storage format
5. Manage tasks with `array_push`, `array_pop`, `array_sort`
6. Print status messages for each operation
7. Support operations: add, list, complete, delete

## Rubric
| Criteria | Points |
|----------|--------|
| Functionality | 40 |
| Code quality | 20 |
| File persistence | 20 |
| Documentation | 20 |

## Solution
Run: `python -m cli.panther_cli run docs/capstones/solutions/cli-task-manager.pan`

## Verification
Expected output:
```
=== Panther Task Manager ===
Mode: add
[ADD] Task added: Buy groceries
[ADD] Task added: Write documentation
[ADD] Task added: Review PR
Mode: list
  [ ] 1: Buy groceries
  [ ] 2: Write documentation
  [ ] 3: Review PR
Mode: complete
[DONE] Task 1 completed
Mode: delete
[DEL] Removed task: Review PR
Mode: list
  [X] 1: Buy groceries
  [ ] 2: Write documentation
```
