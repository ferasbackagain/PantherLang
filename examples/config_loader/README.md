# PantherLang Configuration Loader Example

Demonstrates reading and parsing JSON configuration files:
- `write_file()` — create a config file
- `read_file()` — read a config file
- `json_decode()` — parse JSON configuration
- `remove_file()` — clean up

## Run

```bash
panther run examples/config_loader/main.pan
```

## Expected Output

Creates config.json with nested settings, reads and parses it,
accesses configuration values including nested objects and arrays,
then cleans up.
