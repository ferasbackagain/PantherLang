from __future__ import annotations

import builtins
import hashlib
import os
import platform
import hmac
import json
import math
import random
import re as _re
import secrets
import sqlite3 as _sqlite3
import time
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable


@dataclass(frozen=True)
class StdlibFunction:
    name: str
    arity: tuple[int, int | None]
    fn: Callable[..., Any]
    doc: str = ""


_STDLIB: dict[str, StdlibFunction] = {}


def _register(fn: StdlibFunction) -> None:
    _STDLIB[fn.name] = fn


def get_stdlib_functions() -> dict[str, StdlibFunction]:
    return dict(_STDLIB)


# --- String ---

def _len(*args: Any) -> int:
    return len(args[0])


def _substring(s: str, start: int, end: int | None = None) -> str:
    if end is None:
        return s[start:]
    return s[start:end]


def _contains(s: str, sub: str) -> bool:
    return sub in s


def _starts_with(s: str, prefix: str) -> bool:
    return s.startswith(prefix)


def _ends_with(s: str, suffix: str) -> bool:
    return s.endswith(suffix)


def _upper(s: str) -> str:
    return s.upper()


def _lower(s: str) -> str:
    return s.lower()


def _trim(s: str) -> str:
    return s.strip()


def _replace(s: str, old: str, new: str) -> str:
    return s.replace(old, new)


def _split(s: str, sep: str | None = None) -> list[str]:
    if sep is None:
        return s.split()
    return s.split(sep)


def _join(sep: str, items: tuple | list) -> str:
    return sep.join(str(i) for i in items)


_register(StdlibFunction("len", (1, 1), _len, "len(x) -> int"))
_register(StdlibFunction("substring", (2, 3), _substring, "substring(s, start[, end]) -> str"))
_register(StdlibFunction("contains", (2, 2), _contains, "contains(s, sub) -> bool"))
_register(StdlibFunction("starts_with", (2, 2), _starts_with, "starts_with(s, prefix) -> bool"))
_register(StdlibFunction("ends_with", (2, 2), _ends_with, "ends_with(s, suffix) -> bool"))
_register(StdlibFunction("upper", (1, 1), _upper, "upper(s) -> str"))
_register(StdlibFunction("lower", (1, 1), _lower, "lower(s) -> str"))
_register(StdlibFunction("trim", (1, 1), _trim, "trim(s) -> str"))
_register(StdlibFunction("replace", (3, 3), _replace, "replace(s, old, new) -> str"))
_register(StdlibFunction("split", (1, 2), _split, "split(s[, sep]) -> list"))
_register(StdlibFunction("join", (2, 2), _join, "join(sep, items) -> str"))


# --- Math ---

def _abs(x: float | int) -> float | int:
    return abs(x)


def _max_(*args: Any) -> Any:
    return max(args)


def _min_(*args: Any) -> Any:
    return min(args)


def _pow(x: float | int, y: float | int) -> float | int:
    return x ** y


def _sqrt(x: float) -> float:
    return math.sqrt(x)


def _floor(x: float) -> int:
    return math.floor(x)


def _ceil(x: float) -> int:
    return math.ceil(x)


def _round_(x: float, ndigits: int = 0) -> float:
    return round(x, ndigits)


def _random() -> float:
    return random.random()


def _randint(lo: int, hi: int) -> int:
    return random.randint(lo, hi)


_register(StdlibFunction("abs", (1, 1), _abs, "abs(x) -> number"))
_register(StdlibFunction("max", (2, None), _max_, "max(a, b, ...) -> number"))
_register(StdlibFunction("min", (2, None), _min_, "min(a, b, ...) -> number"))
_register(StdlibFunction("pow", (2, 2), _pow, "pow(x, y) -> number"))
_register(StdlibFunction("sqrt", (1, 1), _sqrt, "sqrt(x) -> float"))
_register(StdlibFunction("floor", (1, 1), _floor, "floor(x) -> int"))
_register(StdlibFunction("ceil", (1, 1), _ceil, "ceil(x) -> int"))
_register(StdlibFunction("round", (1, 2), _round_, "round(x[, ndigits]) -> float"))
_register(StdlibFunction("random", (0, 0), _random, "random() -> float"))
_register(StdlibFunction("randint", (2, 2), _randint, "randint(lo, hi) -> int"))


# --- JSON ---

def _json_encode(obj: Any) -> str:
    return json.dumps(_convert(obj))


def _convert(obj: Any) -> Any:
    if isinstance(obj, tuple):
        return list(obj)
    return obj


def _json_decode(s: str) -> Any:
    return json.loads(s)


_register(StdlibFunction("json_encode", (1, 1), _json_encode, "json_encode(obj) -> str"))
_register(StdlibFunction("json_decode", (1, 1), _json_decode, "json_decode(s) -> object"))


# --- Time ---

def _time_now() -> float:
    return time.time()


def _sleep(secs: float) -> None:
    time.sleep(secs)


_register(StdlibFunction("time", (0, 0), _time_now, "time() -> float"))
_register(StdlibFunction("sleep", (1, 1), _sleep, "sleep(secs) -> None"))


# --- IO / Type Conversion ---

def _input(prompt: str = "") -> str:
    return builtins.input(str(prompt))


def _readline(prompt: str = "") -> str:
    return builtins.input(str(prompt))


def _to_int(x: Any) -> int:
    return int(x)


def _to_float(x: Any) -> float:
    return float(x)


def _to_bool(x: Any) -> bool:
    if isinstance(x, bool):
        return x
    if isinstance(x, (int, float)):
        return x != 0
    if isinstance(x, str):
        normalized = x.strip().lower()
        if normalized in {"true", "yes", "y", "1", "on"}:
            return True
        if normalized in {"false", "no", "n", "0", "off", ""}:
            return False
    return bool(x)


def _to_string(x: Any) -> str:
    if x is True:
        return "true"
    if x is False:
        return "false"
    if x is None:
        return "null"
    return str(x)


def _type_of(x: Any) -> str:
    if x is None:
        return "null"
    if isinstance(x, bool):
        return "bool"
    if isinstance(x, int):
        return "int"
    if isinstance(x, float):
        return "float"
    if isinstance(x, str):
        return "string"
    if isinstance(x, list):
        return "array"
    if isinstance(x, dict):
        return "object"
    return type(x).__name__


def _println(*args: Any) -> str:
    return " ".join(_to_string(arg) for arg in args)


_register(StdlibFunction("input", (0, 1), _input, "input([prompt]) -> str"))
_register(StdlibFunction("readline", (0, 1), _readline, "readline([prompt]) -> str"))
_register(StdlibFunction("println", (0, None), _println, "println(value, ...) -> str"))
_register(StdlibFunction("int", (1, 1), _to_int, "int(x) -> int"))
_register(StdlibFunction("float", (1, 1), _to_float, "float(x) -> float"))
_register(StdlibFunction("string", (1, 1), _to_string, "string(x) -> str"))
_register(StdlibFunction("to_int", (1, 1), _to_int, "to_int(x) -> int"))
_register(StdlibFunction("to_float", (1, 1), _to_float, "to_float(x) -> float"))
_register(StdlibFunction("to_number", (1, 1), _to_float, "to_number(x) -> float"))
_register(StdlibFunction("to_bool", (1, 1), _to_bool, "to_bool(x) -> bool"))
_register(StdlibFunction("to_string", (1, 1), _to_string, "to_string(x) -> str"))
_register(StdlibFunction("type_of", (1, 1), _type_of, "type_of(x) -> str"))


# --- Security / Crypto ---

def _sha256(data: str) -> str:
    return hashlib.sha256(data.encode("utf-8")).hexdigest()


def _hmac_sha256(key: str, message: str) -> str:
    return hmac.new(
        key.encode("utf-8"),
        message.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def _secure_token(nbytes: int = 32) -> str:
    return secrets.token_hex(nbytes)


def _secure_compare(a: str, b: str) -> bool:
    return hmac.compare_digest(a.encode("utf-8"), b.encode("utf-8"))


def _sanitize_path(base_dir: str, user_path: str) -> str:
    base = Path(base_dir).resolve()
    target = (base / user_path).resolve()
    if not str(target).startswith(str(base)):
        raise ValueError(f"Path traversal detected: {user_path}")
    return str(target)


def _sanitize_html(text: str) -> str:
    replacements = {
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#x27;",
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text


_register(StdlibFunction("sha256", (1, 1), _sha256, "sha256(data) -> str"))
_register(StdlibFunction("hmac_sha256", (2, 2), _hmac_sha256, "hmac_sha256(key, message) -> str"))
_register(StdlibFunction("secure_token", (0, 1), _secure_token, "secure_token([nbytes]) -> str"))
_register(StdlibFunction("secure_compare", (2, 2), _secure_compare, "secure_compare(a, b) -> bool"))
_register(StdlibFunction("sanitize_path", (2, 2), _sanitize_path, "sanitize_path(base, path) -> str"))
_register(StdlibFunction("sanitize_html", (1, 1), _sanitize_html, "sanitize_html(text) -> str"))


# --- Filesystem ---

def _read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def _write_file(path: str, content: str) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def _file_exists(path: str) -> bool:
    return Path(path).exists()


def _mkdir(path: str) -> None:
    Path(path).mkdir(parents=True, exist_ok=True)


def _list_dir(path: str) -> list[str]:
    return [str(p.name) for p in Path(path).iterdir()]


def _remove_file(path: str) -> None:
    Path(path).unlink()


_register(StdlibFunction("read_file", (1, 1), _read_file, "read_file(path) -> str"))
_register(StdlibFunction("write_file", (2, 2), _write_file, "write_file(path, content) -> None"))
_register(StdlibFunction("file_exists", (1, 1), _file_exists, "file_exists(path) -> bool"))
_register(StdlibFunction("mkdir", (1, 1), _mkdir, "mkdir(path) -> None"))
_register(StdlibFunction("list_dir", (1, 1), _list_dir, "list_dir(path) -> list"))
_register(StdlibFunction("remove_file", (1, 1), _remove_file, "remove_file(path) -> None"))


# --- HTTP Client ---

def _http_get(url: str) -> str | None:
    try:
        with urllib.request.urlopen(url, timeout=10) as resp:
            return resp.read().decode("utf-8")
    except Exception:
        return None


def _http_post(url: str, data: str = "") -> str | None:
    try:
        body = data.encode("utf-8") if data else b""
        req = urllib.request.Request(url, data=body, method="POST")
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.read().decode("utf-8")
    except Exception:
        return None


_register(StdlibFunction("http_get", (1, 1), _http_get, "http_get(url) -> str | None"))
_register(StdlibFunction("http_post", (1, 2), _http_post, "http_post(url[, data]) -> str | None"))


# --- Regex ---

def _regex_match(pattern: str, text: str) -> bool:
    return bool(_re.search(pattern, text))


def _regex_replace(pattern: str, replacement: str, text: str) -> str:
    return _re.sub(pattern, replacement, text)


def _regex_split(pattern: str, text: str) -> list[str]:
    return _re.split(pattern, text)


_register(StdlibFunction("regex_match", (2, 2), _regex_match, "regex_match(pattern, text) -> bool"))
_register(StdlibFunction("regex_replace", (3, 3), _regex_replace, "regex_replace(pattern, replacement, text) -> str"))
_register(StdlibFunction("regex_split", (2, 2), _regex_split, "regex_split(pattern, text) -> list"))


# --- Collections ---

def _array_push(arr: list, item: Any) -> int:
    arr.append(item)
    return len(arr)


def _array_pop(arr: list) -> Any:
    return arr.pop() if arr else None


def _array_sort(arr: list) -> list:
    return sorted(arr)


def _array_reverse(arr: list) -> list:
    return list(reversed(arr))


_register(StdlibFunction("array_push", (2, 2), _array_push, "array_push(arr, item) -> int"))
_register(StdlibFunction("array_pop", (1, 1), _array_pop, "array_pop(arr) -> any"))
_register(StdlibFunction("array_sort", (1, 1), _array_sort, "array_sort(arr) -> list"))
_register(StdlibFunction("array_reverse", (1, 1), _array_reverse, "array_reverse(arr) -> list"))


# --- SQLite ---

def _db_open(path: str) -> dict:
    conn = _sqlite3.connect(path)
    conn.row_factory = _sqlite3.Row
    return {"__conn": conn, "__path": path}


def _db_close(conn_obj: dict) -> None:
    if isinstance(conn_obj, dict) and "__conn" in conn_obj:
        conn_obj["__conn"].close()


def _db_execute(conn_obj: dict, sql: str, params: Any = None) -> int:
    if isinstance(conn_obj, dict) and "__conn" in conn_obj:
        conn = conn_obj["__conn"]
        if params is not None:
            result = conn.execute(sql, params)
        else:
            result = conn.execute(sql)
        conn.commit()
        return result.rowcount if result.rowcount is not None else 0
    return 0


def _db_query(conn_obj: dict, sql: str, params: Any = None) -> list[dict]:
    if isinstance(conn_obj, dict) and "__conn" in conn_obj:
        conn = conn_obj["__conn"]
        if params is not None:
            cursor = conn.execute(sql, params)
        else:
            cursor = conn.execute(sql)
        return [dict(row) for row in cursor.fetchall()]
    return []


_register(StdlibFunction("db_open", (1, 1), _db_open, "db_open(path) -> connection"))
_register(StdlibFunction("db_close", (1, 1), _db_close, "db_close(conn) -> None"))
_register(StdlibFunction("db_execute", (2, 3), _db_execute, "db_execute(conn, sql[, params]) -> int"))
_register(StdlibFunction("db_query", (2, 3), _db_query, "db_query(conn, sql[, params]) -> list"))


# === PantherLang Stdlib S1-S6 Expansion ===
# Academy-driven standard library expansion.
# Design policy: explicit conversions, safe defaults, defensive-only network helpers.

import base64 as _base64
import os as _os
import platform as _platform
import shutil as _shutil
import socket as _socket
import subprocess as _subprocess
import uuid as _uuid
from pathlib import Path as _Path
from typing import Any as _Any


def _panther_bool_text(value: _Any) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return False
    if isinstance(value, (int, float)):
        return value != 0
    text = str(value).strip().lower()
    if text in {"true", "1", "yes", "y", "on"}:
        return True
    if text in {"false", "0", "no", "n", "off", "", "null", "none"}:
        return False
    return True


def _type_of(value: _Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "bool"
    if isinstance(value, int) and not isinstance(value, bool):
        return "int"
    if isinstance(value, float):
        return "float"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    return type(value).__name__


def _to_bool(value: _Any) -> bool:
    return _panther_bool_text(value)


def _to_number(value: _Any) -> float:
    return float(value)


def _println(*args: _Any) -> str:
    return " ".join(str(a) for a in args)


def _printf(fmt: str, *args: _Any) -> str:
    try:
        return fmt.format(*args)
    except Exception:
        try:
            return fmt % args
        except Exception:
            return fmt + (" " + " ".join(str(a) for a in args) if args else "")


def _input(prompt: str = "") -> str:
    return input(prompt)


def _readline(prompt: str = "") -> str:
    return input(prompt)


# S1: types + io aliases
_register(StdlibFunction("type_of", (1, 1), _type_of, "type_of(value) -> string"))
_register(StdlibFunction("to_string", (1, 1), _to_string, "to_string(value) -> string"))
_register(StdlibFunction("to_int", (1, 1), _to_int, "to_int(value) -> int"))
_register(StdlibFunction("to_float", (1, 1), _to_float, "to_float(value) -> float"))
_register(StdlibFunction("to_number", (1, 1), _to_number, "to_number(value) -> float"))
_register(StdlibFunction("to_bool", (1, 1), _to_bool, "to_bool(value) -> bool"))
_register(StdlibFunction("println", (0, None), _println, "println(value, ...) -> string"))
_register(StdlibFunction("printf", (1, None), _printf, "printf(format, ...) -> string"))
_register(StdlibFunction("input", (0, 1), _input, "input([prompt]) -> string"))
_register(StdlibFunction("readline", (0, 1), _readline, "readline([prompt]) -> string"))


# S2: filesystem

def _fs_read(path: str) -> str:
    return _Path(path).read_text(encoding="utf-8")


def _fs_write(path: str, content: str) -> bool:
    target = _Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(str(content), encoding="utf-8")
    return True


def _fs_append(path: str, content: str) -> bool:
    target = _Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("a", encoding="utf-8") as fh:
        fh.write(str(content))
    return True


def _fs_copy(src: str, dst: str) -> bool:
    _Path(dst).parent.mkdir(parents=True, exist_ok=True)
    _shutil.copy2(src, dst)
    return True


def _fs_move(src: str, dst: str) -> bool:
    _Path(dst).parent.mkdir(parents=True, exist_ok=True)
    _shutil.move(src, dst)
    return True


def _fs_remove(path: str) -> bool:
    target = _Path(path)
    if target.is_dir():
        _shutil.rmtree(target)
    elif target.exists():
        target.unlink()
    return True


def _fs_rename(src: str, dst: str) -> bool:
    _Path(src).rename(dst)
    return True


def _fs_listdir(path: str = ".") -> list[str]:
    return sorted(p.name for p in _Path(path).iterdir())


def _fs_cwd() -> str:
    return str(_Path.cwd())


def _fs_absolute(path: str) -> str:
    return str(_Path(path).resolve())


_register(StdlibFunction("fs_read", (1, 1), _fs_read, "fs_read(path) -> string"))
_register(StdlibFunction("fs_write", (2, 2), _fs_write, "fs_write(path, content) -> bool"))
_register(StdlibFunction("fs_append", (2, 2), _fs_append, "fs_append(path, content) -> bool"))
_register(StdlibFunction("fs_exists", (1, 1), _file_exists, "fs_exists(path) -> bool"))
_register(StdlibFunction("fs_mkdir", (1, 1), _mkdir, "fs_mkdir(path) -> bool"))
_register(StdlibFunction("fs_copy", (2, 2), _fs_copy, "fs_copy(src, dst) -> bool"))
_register(StdlibFunction("fs_move", (2, 2), _fs_move, "fs_move(src, dst) -> bool"))
_register(StdlibFunction("fs_remove", (1, 1), _fs_remove, "fs_remove(path) -> bool"))
_register(StdlibFunction("fs_rename", (2, 2), _fs_rename, "fs_rename(src, dst) -> bool"))
_register(StdlibFunction("fs_listdir", (0, 1), _fs_listdir, "fs_listdir([path]) -> array"))
_register(StdlibFunction("fs_cwd", (0, 0), _fs_cwd, "fs_cwd() -> string"))
_register(StdlibFunction("fs_absolute", (1, 1), _fs_absolute, "fs_absolute(path) -> string"))


# S3: system + time + random

def _system_hostname() -> str:
    return _socket.gethostname()


def _system_os() -> str:
    return _platform.system()


def _system_arch() -> str:
    return _platform.machine()


def _system_username() -> str:
    return _os.environ.get("USER") or _os.environ.get("USERNAME") or "unknown"


def _system_env(name: str, default: str = "") -> str:
    return _os.environ.get(name, default)


def _system_cpu_count() -> int:
    return _os.cpu_count() or 0


def _system_memory() -> str:
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as fh:
            first = fh.readline().strip()
        return first
    except Exception:
        return "unknown"


def _system_disk(path: str = ".") -> dict:
    usage = _shutil.disk_usage(path)
    return {"total": usage.total, "used": usage.used, "free": usage.free}


def _system_uptime() -> float:
    try:
        return float(_Path("/proc/uptime").read_text().split()[0])
    except Exception:
        return 0.0


def _system_cwd() -> str:
    return str(_Path.cwd())


def _system_pid() -> int:
    return _os.getpid()


def _system_command_line() -> str:
    import sys as _sys
    return " ".join(_sys.argv)


_register(StdlibFunction("system_hostname", (0, 0), _system_hostname, "system_hostname() -> string"))
_register(StdlibFunction("system_os", (0, 0), _system_os, "system_os() -> string"))
_register(StdlibFunction("system_arch", (0, 0), _system_arch, "system_arch() -> string"))
_register(StdlibFunction("system_username", (0, 0), _system_username, "system_username() -> string"))
_register(StdlibFunction("system_env", (1, 2), _system_env, "system_env(name[, default]) -> string"))
_register(StdlibFunction("system_cpu_count", (0, 0), _system_cpu_count, "system_cpu_count() -> int"))
_register(StdlibFunction("system_memory", (0, 0), _system_memory, "system_memory() -> string"))
_register(StdlibFunction("system_disk", (0, 1), _system_disk, "system_disk([path]) -> object"))
_register(StdlibFunction("system_uptime", (0, 0), _system_uptime, "system_uptime() -> float"))
_register(StdlibFunction("system_cwd", (0, 0), _system_cwd, "system_cwd() -> string"))
_register(StdlibFunction("system_pid", (0, 0), _system_pid, "system_pid() -> int"))
_register(StdlibFunction("system_command_line", (0, 0), _system_command_line, "system_command_line() -> string"))
_register(StdlibFunction("time_now", (0, 0), _time_now, "time_now() -> float"))
_register(StdlibFunction("time_sleep", (1, 1), _sleep, "time_sleep(seconds) -> null"))
_register(StdlibFunction("random_float", (0, 0), _random, "random_float() -> float"))
_register(StdlibFunction("random_int", (2, 2), _randint, "random_int(low, high) -> int"))


# S4: net + http + json + sqlite aliases

def _net_local_ip() -> str:
    try:
        s = _socket.socket(_socket.AF_INET, _socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def _net_interfaces() -> list[str]:
    try:
        return [name for _, name in _socket.if_nameindex()]
    except Exception:
        return []


def _net_dns() -> list[str]:
    servers: list[str] = []
    try:
        for line in _Path("/etc/resolv.conf").read_text(encoding="utf-8").splitlines():
            parts = line.strip().split()
            if len(parts) >= 2 and parts[0] == "nameserver":
                servers.append(parts[1])
    except Exception:
        pass
    return servers


def _net_gateway() -> str:
    try:
        with open("/proc/net/route", "r", encoding="utf-8") as fh:
            for line in fh.readlines()[1:]:
                fields = line.strip().split()
                if len(fields) >= 3 and fields[1] == "00000000":
                    gateway_hex = fields[2]
                    return ".".join(str(int(gateway_hex[i:i+2], 16)) for i in (6, 4, 2, 0))
    except Exception:
        pass
    return "unknown"


def _net_mac_address(interface: str = "") -> str:
    if interface:
        path = _Path("/sys/class/net") / interface / "address"
        if path.exists():
            return path.read_text(encoding="utf-8").strip()
    try:
        return ":".join(["%02x" % ((_uuid.getnode() >> ele) & 0xff) for ele in range(40, -1, -8)])
    except Exception:
        return "unknown"


def _net_resolve(host: str) -> str:
    try:
        return _socket.gethostbyname(host)
    except Exception:
        return ""


def _net_port_check(host: str, port: int, timeout: float = 2.0) -> bool:
    try:
        with _socket.create_connection((host, int(port)), timeout=float(timeout)):
            return True
    except Exception:
        return False


def _net_ping(host: str) -> bool:
    ping = _shutil.which("ping")
    if not ping:
        return False
    try:
        result = _subprocess.run([ping, "-c", "1", "-W", "1", host], stdout=_subprocess.DEVNULL, stderr=_subprocess.DEVNULL, timeout=3)
        return result.returncode == 0
    except Exception:
        return False


def _net_scan_lan() -> list[dict]:
    # Defensive, passive-only discovery from ARP cache. No active scanning.
    devices: list[dict] = []
    try:
        for line in _Path("/proc/net/arp").read_text(encoding="utf-8").splitlines()[1:]:
            parts = line.split()
            if len(parts) >= 6:
                devices.append({"ip": parts[0], "mac": parts[3], "interface": parts[5]})
    except Exception:
        pass
    return devices


def _http_request(method: str, url: str, data: str = "", timeout: float = 10.0) -> dict:
    try:
        body = data.encode("utf-8") if data else None
        req = urllib.request.Request(url, data=body, method=method.upper())
        with urllib.request.urlopen(req, timeout=float(timeout)) as resp:
            content = resp.read().decode("utf-8", errors="replace")
            return {"ok": True, "status": resp.status, "body": content}
    except Exception as exc:
        return {"ok": False, "status": 0, "body": "", "error": str(exc)}


def _http_put(url: str, data: str = "") -> str | None:
    r = _http_request("PUT", url, data)
    return r.get("body") if r.get("ok") else None


def _http_delete(url: str) -> str | None:
    r = _http_request("DELETE", url)
    return r.get("body") if r.get("ok") else None


def _json_parse(s: str) -> _Any:
    return json.loads(s)


def _json_stringify(obj: _Any) -> str:
    return json.dumps(obj)


def _json_pretty(obj: _Any) -> str:
    return json.dumps(obj, indent=2, sort_keys=True)


def _json_valid(s: str) -> bool:
    try:
        json.loads(s)
        return True
    except Exception:
        return False


_register(StdlibFunction("net_local_ip", (0, 0), _net_local_ip, "net_local_ip() -> string"))
_register(StdlibFunction("net_gateway", (0, 0), _net_gateway, "net_gateway() -> string"))
_register(StdlibFunction("net_dns", (0, 0), _net_dns, "net_dns() -> array"))
_register(StdlibFunction("net_interfaces", (0, 0), _net_interfaces, "net_interfaces() -> array"))
_register(StdlibFunction("net_mac_address", (0, 1), _net_mac_address, "net_mac_address([interface]) -> string"))
_register(StdlibFunction("net_resolve", (1, 1), _net_resolve, "net_resolve(host) -> string"))
_register(StdlibFunction("net_ping", (1, 1), _net_ping, "net_ping(host) -> bool"))
_register(StdlibFunction("net_port_check", (2, 3), _net_port_check, "net_port_check(host, port[, timeout]) -> bool"))
_register(StdlibFunction("net_scan_lan", (0, 0), _net_scan_lan, "net_scan_lan() -> array; passive ARP cache only"))
_register(StdlibFunction("http_request", (2, 4), _http_request, "http_request(method, url[, data, timeout]) -> object"))
_register(StdlibFunction("http_put", (1, 2), _http_put, "http_put(url[, data]) -> string|null"))
_register(StdlibFunction("http_delete", (1, 1), _http_delete, "http_delete(url) -> string|null"))
_register(StdlibFunction("json_parse", (1, 1), _json_parse, "json_parse(text) -> object"))
_register(StdlibFunction("json_stringify", (1, 1), _json_stringify, "json_stringify(value) -> string"))
_register(StdlibFunction("json_pretty", (1, 1), _json_pretty, "json_pretty(value) -> string"))
_register(StdlibFunction("json_valid", (1, 1), _json_valid, "json_valid(text) -> bool"))
_register(StdlibFunction("sqlite_open", (1, 1), _db_open, "sqlite_open(path) -> connection"))
_register(StdlibFunction("sqlite_close", (1, 1), _db_close, "sqlite_close(conn) -> null"))
_register(StdlibFunction("sqlite_execute", (2, 3), _db_execute, "sqlite_execute(conn, sql[, params]) -> int"))
_register(StdlibFunction("sqlite_query", (2, 3), _db_query, "sqlite_query(conn, sql[, params]) -> array"))


# S5: crypto/security aliases

def _crypto_sha512(data: str) -> str:
    return hashlib.sha512(str(data).encode("utf-8")).hexdigest()


def _crypto_md5(data: str) -> str:
    return hashlib.md5(str(data).encode("utf-8")).hexdigest()


def _crypto_uuid() -> str:
    return str(_uuid.uuid4())


def _crypto_random_bytes(nbytes: int = 16) -> str:
    return secrets.token_hex(int(nbytes))


def _crypto_secure_random_int(low: int, high: int) -> int:
    low = int(low); high = int(high)
    if high < low:
        low, high = high, low
    return low + secrets.randbelow(high - low + 1)


def _crypto_base64_encode(text: str) -> str:
    return _base64.b64encode(str(text).encode("utf-8")).decode("ascii")


def _crypto_base64_decode(text: str) -> str:
    return _base64.b64decode(str(text).encode("ascii")).decode("utf-8")


def _crypto_hex_encode(text: str) -> str:
    return str(text).encode("utf-8").hex()


def _crypto_hex_decode(text: str) -> str:
    return bytes.fromhex(str(text)).decode("utf-8")


_register(StdlibFunction("crypto_sha256", (1, 1), _sha256, "crypto_sha256(text) -> string"))
_register(StdlibFunction("crypto_sha512", (1, 1), _crypto_sha512, "crypto_sha512(text) -> string"))
_register(StdlibFunction("crypto_md5", (1, 1), _crypto_md5, "crypto_md5(text) -> string"))
_register(StdlibFunction("crypto_hmac_sha256", (2, 2), _hmac_sha256, "crypto_hmac_sha256(key, message) -> string"))
_register(StdlibFunction("crypto_uuid", (0, 0), _crypto_uuid, "crypto_uuid() -> string"))
_register(StdlibFunction("crypto_random_bytes", (0, 1), _crypto_random_bytes, "crypto_random_bytes([nbytes]) -> string"))
_register(StdlibFunction("crypto_secure_random_int", (2, 2), _crypto_secure_random_int, "crypto_secure_random_int(low, high) -> int"))
_register(StdlibFunction("crypto_base64_encode", (1, 1), _crypto_base64_encode, "crypto_base64_encode(text) -> string"))
_register(StdlibFunction("crypto_base64_decode", (1, 1), _crypto_base64_decode, "crypto_base64_decode(text) -> string"))
_register(StdlibFunction("crypto_hex_encode", (1, 1), _crypto_hex_encode, "crypto_hex_encode(text) -> string"))
_register(StdlibFunction("crypto_hex_decode", (1, 1), _crypto_hex_decode, "crypto_hex_decode(text) -> string"))


# S6: AI mock/safe provider helpers

def _ai_supported_providers() -> list[str]:
    return ["openai", "gemini", "anthropic", "ollama", "openrouter"]


def _ai_provider_available(provider: str) -> bool:
    env_map = {
        "openai": "OPENAI_API_KEY",
        "gemini": "GEMINI_API_KEY",
        "anthropic": "ANTHROPIC_API_KEY",
        "openrouter": "OPENROUTER_API_KEY",
        "ollama": "OLLAMA_HOST",
    }
    key = env_map.get(str(provider).lower())
    return bool(key and _os.environ.get(key))


def _ai_mock_chat(prompt: str) -> str:
    return "PantherAI mock response: " + str(prompt)


_register(StdlibFunction("ai_supported_providers", (0, 0), _ai_supported_providers, "ai_supported_providers() -> array"))
_register(StdlibFunction("ai_provider_available", (1, 1), _ai_provider_available, "ai_provider_available(provider) -> bool"))
_register(StdlibFunction("ai_mock_chat", (1, 1), _ai_mock_chat, "ai_mock_chat(prompt) -> string"))

# === End PantherLang Stdlib S1-S6 Expansion ===
