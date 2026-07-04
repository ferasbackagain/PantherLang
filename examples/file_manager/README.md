# PantherLang File Manager Example

Demonstrates PantherLang filesystem operations:
- `mkdir()` — create directories
- `write_file()` — write text files
- `read_file()` — read text files
- `list_dir()` — list directory contents
- `file_exists()` — check file existence
- `remove_file()` — delete files

## Run

```bash
panther run examples/file_manager/main.pan
```

## Expected Output

Creates a `demo_files/` directory with sample files, reads them back,
checks existence, deletes one, and lists remaining files.
