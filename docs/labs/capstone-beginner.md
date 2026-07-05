# Capstone: Personal Diary CLI (Beginner)

## Objectives
- Build a complete CLI application from scratch
- Use filesystem operations: `write_file`, `read_file`, `file_exists`, `list_dir`
- Practice string manipulation: `replace`, `join`
- Work with arrays and `while` loops

## Theory
A CLI diary app demonstrates fundamental programming concepts: file I/O, string processing, and data organization. You'll create a diary directory, save entries as individual text files named by date, list all entries, and search by date.

## Exercises

### Exercise 1: Save entries to files
**Task**: Write a `save_entry(date, content)` function that creates a file named `{date}.txt` in a `diary_entries/` directory.
**Hint**: Use `mkdir(diary_dir)` first, then `write_file(filename, content)`.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/capstone-beginner.pan`

### Exercise 2: List all entries
**Task**: Write a `list_entries()` function that reads the diary directory and prints all entry dates, numbered.
**Hint**: Use `list_dir(diary_dir)` and iterate with `while`. Strip `.txt` with `replace()`.
**Verify**: The output shows three sample entries with their dates.

### Exercise 3: Search entries by date
**Task**: Write a `search_by_date(date)` function that reads and returns a specific entry file, or a "not found" message.
**Hint**: Check `file_exists(filename)` before attempting to `read_file()`.
**Verify**: Searching for "2026-01-15" shows the saved content for that date.

## Summary
You built a functional CLI diary application using PantherLang's filesystem and string APIs. This project demonstrates the core patterns used in all PantherLang CLI applications.

## Further Reading
- `examples/file_manager/main.pan`
- `compiler/stdlib/functions.py`: filesystem and string functions
