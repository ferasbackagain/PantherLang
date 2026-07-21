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
import threading
import uuid as _uuid
import queue as _queue
import concurrent.futures as _futures
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


def _cos(x: float) -> float:
    return math.cos(x)


def _sin(x: float) -> float:
    return math.sin(x)


def _atan2(y: float, x: float) -> float:
    return math.atan2(y, x)


def _sign(x: float | int) -> int:
    if x > 0:
        return 1
    if x < 0:
        return -1
    return 0


def _tan(x: float) -> float:
    return math.tan(x)


def _clamp(v: float | int, lo: float | int, hi: float | int) -> float | int:
    return max(lo, min(hi, v))


_register(StdlibFunction("abs", (1, 1), _abs, "abs(x) -> number"))
_register(StdlibFunction("max", (2, None), _max_, "max(a, b, ...) -> number"))
_register(StdlibFunction("min", (2, None), _min_, "min(a, b, ...) -> number"))
_register(StdlibFunction("pow", (2, 2), _pow, "pow(x, y) -> number"))
_register(StdlibFunction("sqrt", (1, 1), _sqrt, "sqrt(x) -> float"))
_register(StdlibFunction("floor", (1, 1), _floor, "floor(x) -> int"))
_register(StdlibFunction("ceil", (1, 1), _ceil, "ceil(x) -> int"))
_register(StdlibFunction("round", (1, 2), _round_, "round(x[, ndigits]) -> float"))
_register(StdlibFunction("cos", (1, 1), _cos, "cos(x) -> float"))
_register(StdlibFunction("sin", (1, 1), _sin, "sin(x) -> float"))
_register(StdlibFunction("atan2", (2, 2), _atan2, "atan2(y, x) -> float"))
_register(StdlibFunction("sign", (1, 1), _sign, "sign(x) -> int"))
_register(StdlibFunction("tan", (1, 1), _tan, "tan(x) -> float"))
_register(StdlibFunction("clamp", (3, 3), _clamp, "clamp(v, lo, hi) -> number"))
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
    try:
        from compiler.host_abi.backends.native_time import native_time
        result, error = native_time()
        if result is not None:
            return result
    except Exception:
        pass
    return time.time()


def _sleep(secs: float) -> None:
    try:
        from compiler.host_abi.backends.native_time import native_sleep
        success, error = native_sleep(secs)
        if success:
            return
    except Exception:
        pass
    time.sleep(secs)


_register(StdlibFunction("time", (0, 0), _time_now, "time() -> float"))
_register(StdlibFunction("time_now", (0, 0), _time_now, "time_now() -> float"))
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
    try:
        from compiler.host_abi.backends.native_crypto import native_sha256
        result, error = native_sha256(data)
        if result is not None:
            return result
    except Exception:
        pass
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
    try:
        from compiler.host_abi.backends.native_filesystem import native_read_file
        result, error = native_read_file(path)
        if result is not None:
            return result
    except Exception:
        pass
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def _write_file(path: str, content: str) -> None:
    try:
        from compiler.host_abi.backends.native_filesystem import native_write_file
        success, error = native_write_file(path, content)
        if success:
            return
    except Exception:
        pass
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def _file_exists(path: str) -> bool:
    try:
        from compiler.host_abi.backends.native_filesystem import native_file_exists
        return native_file_exists(path)
    except Exception:
        pass
    return Path(path).exists()


def _mkdir(path: str) -> None:
    try:
        from compiler.host_abi.backends.native_filesystem import native_mkdir
        success, error = native_mkdir(path)
        if success:
            return
    except Exception:
        pass
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

def _regex_findall(pattern: str, text: str) -> list[str]:
    return _re.findall(pattern, text)


def _regex_match(pattern: str, text: str) -> bool:
    return bool(_re.search(pattern, text))


def _regex_replace(pattern: str, replacement: str, text: str) -> str:
    return _re.sub(pattern, replacement, text)


def _regex_split(pattern: str, text: str) -> list[str]:
    return _re.split(pattern, text)


_register(StdlibFunction("regex_match", (2, 2), _regex_match, "regex_match(pattern, text) -> bool"))
_register(StdlibFunction("regex_findall", (2, 2), _regex_findall, "regex_findall(pattern, text) -> list"))
_register(StdlibFunction("regex_replace", (3, 3), _regex_replace, "regex_replace(pattern, replacement, text) -> str"))
_register(StdlibFunction("regex_split", (2, 2), _regex_split, "regex_split(pattern, text) -> list"))


# --- Collections ---

def _array_push(arr: list, item: Any) -> list:
    arr.append(item)
    return arr


def _array_pop(arr: list) -> Any:
    return arr.pop() if arr else None


def _array_sort(arr: list) -> list:
    return sorted(arr)


def _array_reverse(arr: list) -> list:
    return list(reversed(arr))


_register(StdlibFunction("array_push", (2, 2), _array_push, "array_push(arr, item) -> arr"))
_register(StdlibFunction("array_pop", (1, 1), _array_pop, "array_pop(arr) -> any"))
_register(StdlibFunction("array_sort", (1, 1), _array_sort, "array_sort(arr) -> list"))
_register(StdlibFunction("array_reverse", (1, 1), _array_reverse, "array_reverse(arr) -> list"))


# --- SQLite ---

def _db_open(path: str) -> dict:
    conn = _sqlite3.connect(path)
    conn.row_factory = _sqlite3.Row
    return {"__conn": conn, "__path": path, "__in_txn": False}


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
        if not conn_obj.get("__in_txn"):
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


def _db_begin(conn_obj: dict) -> bool:
    if isinstance(conn_obj, dict) and "__conn" in conn_obj:
        conn_obj["__conn"].execute("BEGIN")
        conn_obj["__in_txn"] = True
        return True
    return False


def _db_commit(conn_obj: dict) -> bool:
    if isinstance(conn_obj, dict) and "__conn" in conn_obj:
        conn_obj["__conn"].commit()
        conn_obj["__in_txn"] = False
        return True
    return False


def _db_rollback(conn_obj: dict) -> bool:
    if isinstance(conn_obj, dict) and "__conn" in conn_obj:
        conn_obj["__conn"].rollback()
        conn_obj["__in_txn"] = False
        return True
    return False


_register(StdlibFunction("db_open", (1, 1), _db_open, "db_open(path) -> connection"))
_register(StdlibFunction("db_close", (1, 1), _db_close, "db_close(conn) -> None"))
_register(StdlibFunction("db_execute", (2, 3), _db_execute, "db_execute(conn, sql[, params]) -> int"))
_register(StdlibFunction("db_query", (2, 3), _db_query, "db_query(conn, sql[, params]) -> list"))
_register(StdlibFunction("db_begin", (1, 1), _db_begin, "db_begin(conn) -> bool"))
_register(StdlibFunction("db_commit", (1, 1), _db_commit, "db_commit(conn) -> bool"))
_register(StdlibFunction("db_rollback", (1, 1), _db_rollback, "db_rollback(conn) -> bool"))


# === PantherLang Stdlib S1-S6 Expansion ===
# Academy-driven standard library expansion.
# Design policy: explicit conversions, safe defaults, defensive-only network helpers.

import base64 as _base64
import os as _os
import platform as _platform
import shutil as _shutil
import socket as _socket
import subprocess as _subprocess
import tempfile as _tempfile
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
_register(StdlibFunction("fs_is_file", (1, 1), lambda p: _Path(p).is_file(), "fs_is_file(path) -> bool"))
_register(StdlibFunction("fs_is_dir", (1, 1), lambda p: _Path(p).is_dir(), "fs_is_dir(path) -> bool"))
_register(StdlibFunction("fs_basename", (1, 1), lambda p: _Path(p).name, "fs_basename(path) -> string"))
_register(StdlibFunction("fs_dirname", (1, 1), lambda p: str(_Path(p).parent), "fs_dirname(path) -> string"))
_register(StdlibFunction("fs_extension", (1, 1), lambda p: _Path(p).suffix, "fs_extension(path) -> string"))
_register(StdlibFunction("fs_join", (2, 2), lambda a, b: str(_Path(a) / b), "fs_join(a, b) -> string"))
_register(StdlibFunction("fs_tempdir", (0, 0), lambda: _tempfile.mkdtemp(), "fs_tempdir() -> string"))
_register(StdlibFunction("fs_tempfile", (0, 1), lambda s="": _tempfile.mktemp(suffix=str(s)), "fs_tempfile([suffix]) -> string"))


def _fs_stat(path: str) -> dict:
    try:
        p = _Path(path)
        s = p.stat()
        return {
            "size": s.st_size,
            "modified": s.st_mtime,
            "created": s.st_ctime,
            "is_file": p.is_file(),
            "is_dir": p.is_dir(),
            "name": p.name,
            "parent": str(p.parent),
        }
    except Exception:
        return {"size": 0, "modified": 0, "created": 0, "is_file": False, "is_dir": False, "name": "", "parent": ""}


def _fs_walk(path: str) -> list[dict]:
    try:
        entries: list[dict] = []
        root = _Path(path)
        if not root.is_dir():
            return entries
        for p in root.rglob("*"):
            entries.append({"path": str(p), "is_file": p.is_file(), "is_dir": p.is_dir()})
        return entries
    except Exception:
        return []


_register(StdlibFunction("fs_stat", (1, 1), _fs_stat, "fs_stat(path) -> object"))
_register(StdlibFunction("fs_walk", (1, 1), _fs_walk, "fs_walk(path) -> array"))


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


def _system_home() -> str:
    return str(_Path.home())


def _system_temp() -> str:
    return _tempfile.gettempdir()


def _system_ppid() -> int:
    return _os.getppid()



def _system_exit(code: int = 0) -> None:
    import sys as _sys_mod
    _sys_mod.exit(int(code))


_register(StdlibFunction("system_home", (0, 0), _system_home, "system_home() -> string"))
_register(StdlibFunction("system_temp", (0, 0), _system_temp, "system_temp() -> string"))
_register(StdlibFunction("system_ppid", (0, 0), _system_ppid, "system_ppid() -> int"))
_register(StdlibFunction("system_exit", (0, 1), _system_exit, "system_exit([code]) -> null"))

# S4: net + http + json + sqlite aliases + Host ABI

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


def _net_local_ips() -> list[str]:
    try:
        result = _subprocess.run(
            ["ip", "-o", "-4", "addr", "show"],
            capture_output=True, text=True, timeout=3,
        )
        ips: list[str] = []
        for line in result.stdout.strip().splitlines():
            parts = line.split()
            for i, p in enumerate(parts):
                if p == "inet" and i + 1 < len(parts):
                    ips.append(parts[i + 1].split("/")[0])
        return ips
    except Exception:
        return []


def _net_is_private_ip(ip: str) -> bool:
    try:
        parts = str(ip).strip().split(".")
        if len(parts) != 4:
            return False
        first = int(parts[0])
        second = int(parts[1])
        if first == 10:
            return True
        if first == 172 and 16 <= second <= 31:
            return True
        if first == 192 and second == 168:
            return True
        if first == 127:
            return True
        return False
    except (ValueError, IndexError):
        return False


def _net_reverse_resolve(ip: str) -> str:
    try:
        return _socket.gethostbyaddr(str(ip))[0]
    except Exception:
        return ""


# Module-level TCP server registry
_TCP_SERVERS: dict[int, tuple] = {}


def _net_tcp_send(host: str, port: int, data: str, timeout: float = 5.0) -> str:
    try:
        s = _socket.create_connection((str(host), int(port)), timeout=float(timeout))
    except Exception:
        return ""
    try:
        s.sendall(data.encode("utf-8"))
        s.shutdown(_socket.SHUT_WR)
        response = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            response += chunk
        return response.decode("utf-8", errors="replace")
    except Exception:
        return ""
    finally:
        try:
            s.close()
        except Exception:
            pass


def _net_tcp_serve_start(port: int, response: str = "ok", oneshot: bool = True) -> bool:
    try:
        import threading as _threading
        stop_ev = _threading.Event()
        ready_ev = _threading.Event()
        failed_ev = _threading.Event()

        def _serve() -> None:
            server = None
            try:
                server = _socket.socket(_socket.AF_INET, _socket.SOCK_STREAM)
                server.setsockopt(_socket.SOL_SOCKET, _socket.SO_REUSEADDR, 1)
                server.bind(("127.0.0.1", int(port)))
                server.listen(1)
                server.settimeout(1.0)
                ready_ev.set()
                while not stop_ev.is_set():
                    try:
                        conn, _addr = server.accept()
                        try:
                            _data = conn.recv(4096)
                            if _data:
                                conn.sendall(str(response).encode("utf-8"))
                        finally:
                            conn.close()
                        if oneshot:
                            stop_ev.set()
                    except _socket.timeout:
                        continue
                    except Exception:
                        break
            except Exception:
                failed_ev.set()
                ready_ev.set()
            finally:
                if server is not None:
                    try:
                        server.close()
                    except Exception:
                        pass

        t = _threading.Thread(target=_serve, daemon=True)
        _TCP_SERVERS[int(port)] = (t, stop_ev)
        t.start()
        ready_ev.wait(timeout=2.0)
        if failed_ev.is_set() or not t.is_alive():
            _TCP_SERVERS.pop(int(port), None)
            return False
        return True
    except Exception:
        return False


def _net_tcp_serve_stop(port: int) -> bool:
    try:
        p = int(port)
        if p in _TCP_SERVERS:
            t, stop_ev = _TCP_SERVERS.pop(p)
            stop_ev.set()
            t.join(timeout=2.0)
            return True
        return False
    except Exception:
        return False


def _net_tcp_serve_wait(port: int, timeout: float = 5.0) -> bool:
    try:
        p = int(port)
        if p in _TCP_SERVERS:
            t, _stop_ev = _TCP_SERVERS[p]
            t.join(timeout=float(timeout))
            return not t.is_alive()
        return False
    except Exception:
        return False


def _net_udp_send(host: str, port: int, data: str, timeout: float = 2.0) -> str:
    s = _socket.socket(_socket.AF_INET, _socket.SOCK_DGRAM)
    try:
        s.settimeout(float(timeout))
        s.sendto(data.encode("utf-8"), (str(host), int(port)))
        response, _addr = s.recvfrom(4096)
        return response.decode("utf-8", errors="replace")
    except Exception:
        return ""
    finally:
        s.close()


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
_register(StdlibFunction("net_local_ips", (0, 0), _net_local_ips, "net_local_ips() -> array; all local IPv4 addresses"))
_register(StdlibFunction("net_is_private_ip", (1, 1), _net_is_private_ip, "net_is_private_ip(ip) -> bool; RFC 1918 check"))
_register(StdlibFunction("net_reverse_resolve", (1, 1), _net_reverse_resolve, "net_reverse_resolve(ip) -> string; reverse DNS lookup"))
_register(StdlibFunction("net_tcp_send", (3, 4), _net_tcp_send, "net_tcp_send(host, port, data[, timeout]) -> string"))
_register(StdlibFunction("net_tcp_serve_start", (1, 3), _net_tcp_serve_start, "net_tcp_serve_start(port[, response, oneshot]) -> bool"))
_register(StdlibFunction("net_tcp_serve_stop", (1, 1), _net_tcp_serve_stop, "net_tcp_serve_stop(port) -> bool"))
_register(StdlibFunction("net_tcp_serve_wait", (1, 2), _net_tcp_serve_wait, "net_tcp_serve_wait(port[, timeout]) -> bool"))
_register(StdlibFunction("net_udp_send", (3, 4), _net_udp_send, "net_udp_send(host, port, data[, timeout]) -> string"))
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
_register(StdlibFunction("sqlite_begin", (1, 1), _db_begin, "sqlite_begin(conn) -> bool"))
_register(StdlibFunction("sqlite_commit", (1, 1), _db_commit, "sqlite_commit(conn) -> bool"))
_register(StdlibFunction("sqlite_rollback", (1, 1), _db_rollback, "sqlite_rollback(conn) -> bool"))


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


def _ai_available_providers() -> list[str]:
    """Return only providers whose environment variables are set."""
    all_providers = _ai_supported_providers()
    return [p for p in all_providers if _ai_provider_available(p)]


def _ai_chat(prompt: str, provider: str = "mock") -> str:
    """Chat with an AI provider. Defaults to mock (offline)."""
    provider = str(provider).lower()
    if provider == "mock":
        return _ai_mock_chat(prompt)
    try:
        from compiler.ai.providers import (
            AnthropicProvider,
            GeminiProvider,
            OllamaProvider,
            OpenAIProvider,
            OpenRouterProvider,
            Message,
        )
        provider_map = {
            "openai": OpenAIProvider,
            "anthropic": AnthropicProvider,
            "gemini": GeminiProvider,
            "ollama": OllamaProvider,
            "openrouter": OpenRouterProvider,
        }
        cls = provider_map.get(provider)
        if cls is None:
            return f"[PantherAI] Unknown provider '{provider}'. Falling back to mock: " + str(prompt)
        inst = cls()
        messages = [Message(role="user", content=str(prompt))]
        result = inst.complete(messages)
        if result.content and not result.content.startswith("[mock]"):
            return result.content
        return f"[PantherAI {provider}] response to: " + str(prompt)
    except ImportError:
        return f"[PantherAI] Provider '{provider}' unavailable (import failed). Falling back to mock: " + str(prompt)


_register(StdlibFunction("ai_supported_providers", (0, 0), _ai_supported_providers, "ai_supported_providers() -> array"))
_register(StdlibFunction("ai_provider_available", (1, 1), _ai_provider_available, "ai_provider_available(provider) -> bool"))
_register(StdlibFunction("ai_mock_chat", (1, 1), _ai_mock_chat, "ai_mock_chat(prompt) -> string"))
_register(StdlibFunction("ai_available_providers", (0, 0), _ai_available_providers, "ai_available_providers() -> array"))
_register(StdlibFunction("ai_chat", (1, 2), _ai_chat, "ai_chat(prompt[, provider]) -> string"))

# C5: Data / Serialization

import csv as _csv
import datetime as _datetime


def _datetime_now() -> str:
    return _datetime.datetime.now().isoformat()


def _datetime_format(timestamp: float, fmt: str = "%Y-%m-%d %H:%M:%S") -> str:
    try:
        return _datetime.datetime.fromtimestamp(float(timestamp)).strftime(str(fmt))
    except Exception:
        return ""


def _datetime_parse(s: str) -> float:
    try:
        dt = _datetime.datetime.fromisoformat(str(s))
        return dt.timestamp()
    except Exception:
        return 0.0


def _csv_parse(text: str) -> list[list[str]]:
    try:
        return list(_csv.reader(str(text).splitlines()))
    except Exception:
        return []


def _csv_stringify(rows: list, delimiter: str = ",") -> str:
    try:
        output = []
        for row in rows:
            if isinstance(row, list):
                output.append(delimiter.join(str(c) for c in row))
            else:
                output.append(str(row))
        return "\n".join(output)
    except Exception:
        return ""


def _csv_parse_objects(text: str) -> list[dict]:
    try:
        lines = str(text).strip().splitlines()
        if not lines:
            return []
        reader = _csv.reader(lines)
        headers = [h.strip() for h in next(reader)]
        return [dict(zip(headers, [c.strip() for c in row])) for row in reader]
    except Exception:
        return []


def _url_encode(text: str) -> str:
    return urllib.parse.quote(str(text), safe="")


def _url_decode(text: str) -> str:
    return urllib.parse.unquote(str(text))


_register(StdlibFunction("datetime_now", (0, 0), _datetime_now, "datetime_now() -> string; ISO 8601 timestamp"))
_register(StdlibFunction("datetime_format", (1, 2), _datetime_format, "datetime_format(timestamp[, format]) -> string"))
_register(StdlibFunction("datetime_parse", (1, 1), _datetime_parse, "datetime_parse(s) -> float; Unix timestamp"))
_register(StdlibFunction("csv_parse", (1, 1), _csv_parse, "csv_parse(text) -> array; rows of strings"))
_register(StdlibFunction("csv_stringify", (1, 2), _csv_stringify, "csv_stringify(rows[, delimiter]) -> string"))
_register(StdlibFunction("csv_parse_objects", (1, 1), _csv_parse_objects, "csv_parse_objects(text) -> array; rows of objects"))
_register(StdlibFunction("url_encode", (1, 1), _url_encode, "url_encode(text) -> string"))
_register(StdlibFunction("url_decode", (1, 1), _url_decode, "url_decode(text) -> string"))

# C7: Storage Foundation (local filesystem-backed object storage)


def _storage_open(path: str) -> dict:
    p = _Path(path)
    p.mkdir(parents=True, exist_ok=True)
    return {"__path": str(p.resolve())}


def _storage_put(store: dict, key: str, data: str) -> bool:
    try:
        base = _Path(store["__path"]).resolve()
        sanitized = _sanitize_key(key)
        if sanitized == "_invalid_path":
            return False
        target = (base / sanitized).resolve()
        if not str(target).startswith(str(base)):
            return False
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(str(data), encoding="utf-8")
        return True
    except Exception:
        return False


def _storage_get(store: dict, key: str) -> str:
    try:
        base = _Path(store["__path"]).resolve()
        sanitized = _sanitize_key(key)
        if sanitized == "_invalid_path":
            return ""
        target = (base / sanitized).resolve()
        if not str(target).startswith(str(base)):
            return ""
        if target.is_file():
            return target.read_text(encoding="utf-8")
        return ""
    except Exception:
        return ""


def _storage_exists(store: dict, key: str) -> bool:
    try:
        base = _Path(store["__path"]).resolve()
        sanitized = _sanitize_key(key)
        if sanitized == "_invalid_path":
            return False
        target = (base / sanitized).resolve()
        if not str(target).startswith(str(base)):
            return False
        return target.exists()
    except Exception:
        return False


def _storage_delete(store: dict, key: str) -> bool:
    try:
        base = _Path(store["__path"]).resolve()
        sanitized = _sanitize_key(key)
        if sanitized == "_invalid_path":
            return False
        target = (base / sanitized).resolve()
        if not str(target).startswith(str(base)):
            return False
        if target.exists():
            target.unlink()
            return True
        return False
    except Exception:
        return False


def _storage_list(store: dict, prefix: str = "") -> list[str]:
    try:
        base = _Path(store["__path"]).resolve()
        search_dir = base
        if prefix:
            sanitized = _sanitize_key(prefix)
            if sanitized == "_invalid_path":
                return []
            search_dir = (base / sanitized).resolve()
            if not str(search_dir).startswith(str(base)):
                return []
        if not search_dir.is_dir():
            return []
        return sorted(
            str(p.relative_to(base))
            for p in search_dir.rglob("*")
            if p.is_file() and str(p.resolve()).startswith(str(base))
        )
    except Exception:
        return []


def _sanitize_key(key: str) -> str:
    # Prevent path traversal: collapse to relative path, strip leading slash
    clean = _Path(key.lstrip("/")).as_posix()
    if ".." in clean.split("/"):
        return "_invalid_path"
    return clean


_register(StdlibFunction("storage_open", (1, 1), _storage_open, "storage_open(path) -> store"))
_register(StdlibFunction("storage_put", (3, 3), _storage_put, "storage_put(store, key, data) -> bool"))
_register(StdlibFunction("storage_get", (2, 2), _storage_get, "storage_get(store, key) -> string"))
_register(StdlibFunction("storage_exists", (2, 2), _storage_exists, "storage_exists(store, key) -> bool"))
_register(StdlibFunction("storage_delete", (2, 2), _storage_delete, "storage_delete(store, key) -> bool"))
_register(StdlibFunction("storage_list", (1, 2), _storage_list, "storage_list(store[, prefix]) -> array"))

# C10: Observability / Logging

_LOG_LEVEL = "info"


def _log_set_level(level: str) -> bool:
    global _LOG_LEVEL
    level = str(level).lower()
    if level in ("debug", "info", "warn", "error"):
        _LOG_LEVEL = level
        return True
    return False


def _log(level: str, message: str) -> str:
    levels = {"debug": 0, "info": 1, "warn": 2, "error": 3}
    if levels.get(level, 1) < levels.get(_LOG_LEVEL, 1):
        return ""
    ts = _datetime.datetime.now().isoformat()
    return f"[{ts}] [{level.upper()}] {message}"


def _log_debug(msg: str) -> str:
    return _log("debug", str(msg))


def _log_info(msg: str) -> str:
    return _log("info", str(msg))


def _log_warn(msg: str) -> str:
    return _log("warn", str(msg))


def _log_error(msg: str) -> str:
    return _log("error", str(msg))


_register(StdlibFunction("log_set_level", (1, 1), _log_set_level, "log_set_level(level) -> bool"))
_register(StdlibFunction("log_debug", (1, 1), _log_debug, "log_debug(msg) -> null"))
_register(StdlibFunction("log_info", (1, 1), _log_info, "log_info(msg) -> null"))
_register(StdlibFunction("log_warn", (1, 1), _log_warn, "log_warn(msg) -> null"))
_register(StdlibFunction("log_error", (1, 1), _log_error, "log_error(msg) -> null"))
# === End PantherLang Stdlib S1-S6 Expansion ===


# Host ABI: Network primitives (properly registered)
import ipaddress as _ipaddress


def _net_primary_ip() -> str:
    try:
        s = _socket.socket(_socket.AF_INET, _socket.SOCK_DGRAM)
        try:
            s.connect(("1.1.1.1", 80))
            return s.getsockname()[0]
        except Exception:
            try:
                return _socket.gethostbyname(_socket.gethostname())
            except Exception:
                return "127.0.0.1"
        finally:
            try:
                s.close()
            except Exception:
                pass
    except Exception:
        return "127.0.0.1"


def _net_dns_servers() -> str:
    servers: list[str] = []
    p = _Path("/etc/resolv.conf")
    try:
        if p.exists():
            for line in p.read_text(encoding="utf-8", errors="ignore").splitlines():
                line = line.strip()
                if line.startswith("nameserver"):
                    parts = line.split()
                    if len(parts) >= 2 and parts[1] not in servers:
                        servers.append(parts[1])
    except Exception:
        pass
    if not servers:
        for cmd in (["nmcli", "dev", "show"], ["resolvectl", "dns"]):
            try:
                proc = _subprocess.run(cmd, text=True, capture_output=True, timeout=2, shell=False)
                for token in proc.stdout.replace(",", " ").split():
                    try:
                        _ipaddress.ip_address(token)
                        if token not in servers:
                            servers.append(token)
                    except Exception:
                        pass
            except Exception:
                pass
    return ",".join(servers)


def _net_neighbors() -> list[str]:
    rows: list[str] = []
    for cmd in (["ip", "neigh"], ["arp", "-an"]):
        try:
            proc = _subprocess.run(cmd, text=True, capture_output=True, timeout=3, shell=False)
            for line in proc.stdout.strip().splitlines():
                line = line.strip()
                if line and line not in rows:
                    rows.append(line)
        except Exception:
            pass
    return rows


def _tcp_connect(host: str, port: int, timeout_ms: float = 800) -> str:
    # Native backend (libc via ctypes) preferred when available
    try:
        from compiler.host_abi.backends.native_socket import native_tcp_connect, native_available
        if native_available():
            return native_tcp_connect(str(host), int(port), int(timeout_ms))
    except Exception:
        pass
    # Fallback to Python socket
    try:
        port = int(port)
    except Exception:
        return "INVALID_ARGUMENT"
    try:
        timeout = float(timeout_ms) / 1000.0
    except Exception:
        timeout = 0.8
    s = _socket.socket(_socket.AF_INET, _socket.SOCK_STREAM)
    s.settimeout(timeout)
    try:
        code = s.connect_ex((str(host), port))
        if code == 0:
            return "open"
        if code == 111:
            return "connection_refused"
        if code == 113:
            return "host_unreachable"
        if code == 110:
            return "timeout"
        if code == 101:
            return "network_unreachable"
        return "closed"
    except _socket.timeout:
        return "timeout"
    except _socket.gaierror:
        return "dns_error"
    except OSError as e:
        if "refused" in str(e).lower():
            return "connection_refused"
        if "unreachable" in str(e).lower():
            return "host_unreachable"
        return "io_error"
    except Exception:
        return "internal_error"
    finally:
        try:
            s.close()
        except Exception:
            pass


def _tcp_banner(host: str, port: int, timeout_ms: float = 1000) -> str:
    # tcp_banner uses Python socket for robust banner collection.
    # The native backend is used for tcp_connect (connectivity check).
    try:
        port = int(port)
    except Exception:
        return ""
    try:
        timeout = float(timeout_ms) / 1000.0
    except Exception:
        timeout = 1.0
    s = _socket.socket(_socket.AF_INET, _socket.SOCK_STREAM)
    s.settimeout(timeout)
    try:
        code = s.connect_ex((str(host), port))
        if code != 0:
            return ""
        try:
            s.sendall(b"\r\n")
        except Exception:
            pass
        data = s.recv(256)
        return data.decode("utf-8", errors="replace").strip()
    except Exception:
        return ""
    finally:
        try:
            s.close()
        except Exception:
            pass


# Host ABI: capability registry
from compiler.host_abi import HostCapability, register_capability


register_capability(HostCapability("net_local_ip", "Get local primary IP", requires_network=True))
register_capability(HostCapability("net_primary_ip", "Get local primary IP (alt method)", requires_network=True))
register_capability(HostCapability("net_gateway", "Get default gateway", supported_platforms=("linux",)))
register_capability(HostCapability("net_dns", "Get DNS servers", supported_platforms=("linux",)))
register_capability(HostCapability("net_dns_servers", "Get DNS servers with fallback", supported_platforms=("linux",)))
register_capability(HostCapability("net_interfaces", "List network interfaces"))
register_capability(HostCapability("net_mac_address", "Get MAC address"))
register_capability(HostCapability("net_resolve", "DNS resolve hostname"))
register_capability(HostCapability("net_reverse_resolve", "Reverse DNS lookup"))
register_capability(HostCapability("net_neighbors", "List ARP/neighbor table entries", supported_platforms=("linux",)))
register_capability(HostCapability("tcp_connect", "TCP connect check"))
register_capability(HostCapability("tcp_banner", "Read TCP banner"))
register_capability(HostCapability("net_port_check", "Check if TCP port is open"))
register_capability(HostCapability("net_scan_lan", "Passive LAN scan from ARP cache", supported_platforms=("linux",)))
register_capability(HostCapability("net_ping", "Ping host", requires_subprocess=True))
register_capability(HostCapability("system_hostname", "Get system hostname"))
register_capability(HostCapability("system_os", "Get OS name"))
register_capability(HostCapability("native_socket_backend", "Native libc socket backend (ctypes)", supported_platforms=("linux",)))
register_capability(HostCapability("native_filesystem_backend", "Native libc filesystem backend (ctypes)", supported_platforms=("linux",)))
register_capability(HostCapability("native_crypto_backend", "Native libcrypto backend (ctypes)", supported_platforms=("linux",)))
register_capability(HostCapability("native_time_backend", "Native libc time backend (ctypes)", supported_platforms=("linux",)))


def _host_capability_available(name: str) -> bool:
    from compiler.host_abi import is_capability_available
    return is_capability_available(str(name))


def _host_list_capabilities() -> list:
    from compiler.host_abi import list_capabilities
    return list_capabilities()


def _host_error_message(code: str) -> str:
    from compiler.host_abi.errors import error_message as _err_msg
    return _err_msg(str(code))


# S7: Host ABI registrations
_register(StdlibFunction("net_primary_ip", (0, 0), _net_primary_ip, "net_primary_ip() -> string; local primary IP"))
_register(StdlibFunction("net_dns_servers", (0, 0), _net_dns_servers, "net_dns_servers() -> string; CSV DNS servers"))
_register(StdlibFunction("net_neighbors", (0, 0), _net_neighbors, "net_neighbors() -> array; ARP/neighbor table"))
_register(StdlibFunction("tcp_connect", (2, 3), _tcp_connect, "tcp_connect(host, port[, timeout_ms]) -> string; port state"))
_register(StdlibFunction("tcp_banner", (2, 3), _tcp_banner, "tcp_banner(host, port[, timeout_ms]) -> string; banner text"))
_register(StdlibFunction("host_capability_available", (1, 1), _host_capability_available, "host_capability_available(name) -> bool"))
_register(StdlibFunction("host_list_capabilities", (0, 0), _host_list_capabilities, "host_list_capabilities() -> array"))
_register(StdlibFunction("host_error_message", (1, 1), _host_error_message, "host_error_message(code) -> string"))


# S8: AI Package functions
# Legacy flat API compatibility (S6)
def _ai_chat_legacy(prompt: str, provider: str = "mock") -> str:
    if provider == "mock":
        return "[PantherAI mock] Response to: " + prompt
    return "[PantherAI] Provider '" + provider + "' not implemented"

def _ai_chat_legacy_wrapped(*args: Any) -> str:
    """Wrapper to handle optional provider argument."""
    prompt = args[0] if len(args) > 0 else ""
    provider = args[1] if len(args) > 1 else "mock"
    return _ai_chat_legacy(prompt, provider)

def _ai_mock_chat_legacy(prompt: str) -> str:
    return "[PantherAI mock] Response to: " + prompt

def _ai_available_providers_legacy() -> list:
    import os
    providers = []
    if os.environ.get("OLLAMA_HOST"):
        providers.append("ollama")
    if os.environ.get("OPENAI_API_KEY"):
        providers.append("openai")
    if os.environ.get("ANTHROPIC_API_KEY"):
        providers.append("anthropic")
    if os.environ.get("GOOGLE_API_KEY"):
        providers.append("google")
    if not providers:
        providers = ["mock"]
    return providers

def _ai_supported_providers_legacy() -> list:
    return ["ollama", "openai", "anthropic", "google", "mock"]

def _ai_provider_available_legacy(provider: str) -> bool:
    import os
    if provider == "ollama":
        return bool(os.environ.get("OLLAMA_HOST"))
    if provider == "openai":
        return bool(os.environ.get("OPENAI_API_KEY"))
    if provider == "anthropic":
        return bool(os.environ.get("ANTHROPIC_API_KEY"))
    if provider == "google":
        return bool(os.environ.get("GOOGLE_API_KEY"))
    if provider == "mock":
        return True
    return False

# New structured AI API
def _ai_provider(name: str) -> dict:
    return {"name": name, "models": []}

def _ai_model(provider: dict, name: str) -> dict:
    return {"provider": provider, "name": name}

def _ai_list_models(provider: dict) -> list:
    models = []
    name = provider.get("name", "")
    if name == "ollama":
        models.extend(["llama3", "mistral", "codellama"])
    elif name == "openai":
        models.extend(["gpt-4", "gpt-3.5-turbo"])
    elif name == "anthropic":
        models.extend(["claude-3-opus", "claude-3-sonnet"])
    elif name == "google":
        models.append("gemini-pro")
    return models

def _ai_message(role: str, content: str) -> dict:
    return {"role": role, "content": content}

def _ai_system_message(content: str) -> dict:
    return {"role": "system", "content": content}

def _ai_user_message(content: str) -> dict:
    return {"role": "user", "content": content}

def _ai_assistant_message(content: str) -> dict:
    return {"role": "assistant", "content": content}

def _ai_chat(model: dict, messages: list, options: dict | None = None) -> dict:
    provider = model.get("provider", {})
    name = provider.get("name", "")
    if name == "ollama":
        return {"ok": False, "error": "Ollama integration not implemented"}
    elif name == "openai":
        return {"ok": False, "error": "OpenAI integration not implemented"}
    elif name == "anthropic":
        return {"ok": False, "error": "Anthropic integration not implemented"}
    else:
        return {"ok": False, "error": "Unsupported provider: " + name}

def _ai_chat_stream(model: dict, messages: list, options: dict | None = None) -> list:
    result = _ai_chat(model, messages, options or {})
    return [result]

def _ai_structured_output(model: dict, messages: list, schema: dict, options: dict | None = None) -> dict:
    result = _ai_chat(model, messages, options or {})
    if result.get("ok"):
        import json
        try:
            parsed = json.loads(result.get("content", "{}"))
            return {"ok": True, "data": parsed}
        except Exception:
            return {"ok": False, "error": "Failed to parse structured output"}
        return result

def _ai_tool(name: str, description: str, parameters: dict) -> dict:
    return {"type": "function", "function": {"name": name, "description": description, "parameters": parameters}}

def _ai_chat_with_tools(model: dict, messages: list, tools: list, options: dict | None = None) -> dict:
    return _ai_chat(model, messages, options or {})

def _ai_with_timeout(ai_fn: callable, timeout_ms: int) -> dict:
    try:
        import signal
        def handler(signum, frame):
            raise TimeoutError("AI call timed out")
        signal.signal(signal.SIGALRM, handler)
        signal.alarm(timeout_ms // 1000)
        try:
            result = ai_fn()
            signal.alarm(0)
            return result
        except TimeoutError:
            return {"ok": False, "error": "AI call timed out"}
        except Exception as e:
            return {"ok": False, "error": str(e)}
        finally:
            signal.alarm(0)
    except Exception:
        return {"ok": False, "error": "Timeout not supported"}

def _ai_retry(ai_fn: callable, retries: int, delay: int) -> dict:
    attempt = 0
    while attempt < retries:
        result = ai_fn()
        if result.get("ok"):
            return result
        attempt += 1
        if attempt < retries:
            import time
            time.sleep(delay / 1000.0)
    return {"ok": False, "error": "Max retries exceeded"}

def _ai_usage(result: dict) -> dict:
    return result.get("usage", {})

def _ai_detect_injection(prompt_text: str) -> dict:
    patterns = [
        "ignore previous instructions",
        "system prompt",
        "you are now",
        "forget everything",
        "new instructions"
    ]
    detected = []
    for pattern in patterns:
        if pattern in prompt_text.lower():
            detected.append(pattern)
    return {"detected": len(detected) > 0, "patterns": detected}

def _ai_audit_log(event_type: str, details: dict) -> dict:
    return {"timestamp": __import__("time").time(), "type": "ai_" + event_type, "details": details}

def _ai_require_approval(operation: str, context: dict) -> dict:
    return {"required": False, "reason": ""}

def _ai_available_providers() -> list:
    import os
    providers = []
    if os.environ.get("OLLAMA_HOST"):
        providers.append("ollama")
    if os.environ.get("OPENAI_API_KEY"):
        providers.append("openai")
    if os.environ.get("ANTHROPIC_API_KEY"):
        providers.append("anthropic")
    if os.environ.get("GOOGLE_API_KEY"):
        providers.append("google")
    return providers

def _ai_package_mock_chat(model: dict, messages: list, options: dict | None = None) -> dict:
    last_msg = messages[-1] if messages else {}
    return {
        "ok": True,
        "content": "[MOCK] Response to: " + last_msg.get("content", ""),
        "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15}
    }

def _ai_ollama_chat(model: dict, messages: list, options: dict | None = None) -> dict:
    return {"ok": False, "error": "Ollama integration not implemented"}

def _ai_openai_chat(model: dict, messages: list, options: dict | None = None) -> dict:
    return {"ok": False, "error": "OpenAI integration not implemented"}

def _ai_anthropic_chat(model: dict, messages: list, options: dict | None = None) -> dict:
    return {"ok": False, "error": "Anthropic integration not implemented"}

_register(StdlibFunction("ai_provider", (1, 1), _ai_provider, "ai_provider(name) -> provider"))
_register(StdlibFunction("ai_model", (2, 2), _ai_model, "ai_model(provider, name) -> model"))
_register(StdlibFunction("ai_list_models", (1, 1), _ai_list_models, "ai_list_models(provider) -> list"))
_register(StdlibFunction("ai_message", (2, 2), _ai_message, "ai_message(role, content) -> message"))
_register(StdlibFunction("ai_system_message", (1, 1), _ai_system_message, "ai_system_message(content) -> message"))
_register(StdlibFunction("ai_user_message", (1, 1), _ai_user_message, "ai_user_message(content) -> message"))
_register(StdlibFunction("ai_assistant_message", (1, 1), _ai_assistant_message, "ai_assistant_message(content) -> message"))
_register(StdlibFunction("ai_chat_stream", (2, 3), _ai_chat_stream, "ai_chat_stream(model, messages[, options]) -> stream"))
_register(StdlibFunction("ai_structured_output", (3, 4), _ai_structured_output, "ai_structured_output(model, messages, schema[, options]) -> result"))
_register(StdlibFunction("ai_tool", (3, 3), _ai_tool, "ai_tool(name, description, parameters) -> tool"))
_register(StdlibFunction("ai_chat_with_tools", (3, 4), _ai_chat_with_tools, "ai_chat_with_tools(model, messages, tools[, options]) -> result"))
_register(StdlibFunction("ai_with_timeout", (2, 2), _ai_with_timeout, "ai_with_timeout(ai_fn, timeout_ms) -> result"))
_register(StdlibFunction("ai_retry", (2, 3), _ai_retry, "ai_retry(ai_fn, retries, delay) -> result"))
_register(StdlibFunction("ai_usage", (1, 1), _ai_usage, "ai_usage(result) -> usage"))
_register(StdlibFunction("ai_detect_injection", (1, 1), _ai_detect_injection, "ai_detect_injection(prompt_text) -> result"))
_register(StdlibFunction("ai_audit_log", (2, 2), _ai_audit_log, "ai_audit_log(event_type, details) -> log"))
_register(StdlibFunction("ai_require_approval", (2, 2), _ai_require_approval, "ai_require_approval(operation, context) -> result"))

# Add async retry function for AI package
def _async_retry(callback: callable, retries: int, delay: int) -> any:
    attempt = 0
    while attempt < retries:
        result = callback()
        if result is not None and result.get("ok", True):
            return result
        attempt += 1
        if attempt < retries:
            import time
            time.sleep(delay / 1000.0)
    return None

# Serialization Package Implementation Functions
def _serialization_encode(value: Any, format: str) -> str:
    """Encode value to specified format."""
    format = format.lower()
    if format == "json":
        return json.dumps(value)
    elif format == "yaml":
        return json.dumps(value)  # fallback
    elif format == "toml":
        return json.dumps(value)  # fallback
    elif format == "msgpack":
        return json.dumps(value)  # fallback
    elif format == "cbor":
        return json.dumps(value)  # fallback
    elif format == "base64":
        return _crypto_base64_encode(json.dumps(value))
    elif format == "hex":
        return _crypto_hex_encode(json.dumps(value))
    else:
        raise ValueError(f"Unsupported format: {format}")

def _serialization_decode(data: str, format: str) -> Any:
    """Decode data from specified format."""
    format = format.lower()
    if format == "json":
        return json.loads(data)
    elif format == "yaml":
        return json.loads(data)  # fallback
    elif format == "toml":
        return json.loads(data)  # fallback
    elif format == "msgpack":
        return json.loads(data)  # fallback
    elif format == "cbor":
        return json.loads(data)  # fallback
    elif format == "base64":
        return json.loads(_crypto_base64_decode(data))
    elif format == "hex":
        return json.loads(_crypto_hex_decode(data))
    else:
        raise ValueError(f"Unsupported format: {format}")

def _serialization_encode_with_options(value: Any, format: str, options: dict) -> str:
    """Encode with options (pretty, indent, etc.)."""
    # For now, just use basic encode
    return _serialization_encode(value, format)


_register(StdlibFunction("async_retry", (3, 3), _async_retry, "async_retry(callback, retries, delay) -> result"))

# Serialization Package Functions (PANTHER_IMPLEMENTED)
_register(StdlibFunction("panther_serialization_json_encode", (1, 1), _json_encode, "panther_serialization_json_encode(value) -> string"))
_register(StdlibFunction("panther_serialization_json_decode", (1, 1), _json_decode, "panther_serialization_json_decode(text) -> object"))
_register(StdlibFunction("panther_serialization_json_pretty", (1, 1), _json_pretty, "panther_serialization_json_pretty(value) -> string"))
_register(StdlibFunction("panther_serialization_json_valid", (1, 1), _json_valid, "panther_serialization_json_valid(text) -> bool"))

# YAML (fallback to JSON)
_register(StdlibFunction("panther_serialization_yaml_encode", (1, 1), _json_encode, "panther_serialization_yaml_encode(value) -> string"))
_register(StdlibFunction("panther_serialization_yaml_decode", (1, 1), _json_decode, "panther_serialization_yaml_decode(text) -> object"))

# TOML (fallback to JSON)
_register(StdlibFunction("panther_serialization_toml_encode", (1, 1), _json_encode, "panther_serialization_toml_encode(value) -> string"))
_register(StdlibFunction("panther_serialization_toml_decode", (1, 1), _json_decode, "panther_serialization_toml_decode(text) -> object"))

# MessagePack (fallback to JSON)
_register(StdlibFunction("panther_serialization_msgpack_encode", (1, 1), _json_encode, "panther_serialization_msgpack_encode(value) -> string"))
_register(StdlibFunction("panther_serialization_msgpack_decode", (1, 1), _json_decode, "panther_serialization_msgpack_decode(text) -> object"))

# CBOR (fallback to JSON)
_register(StdlibFunction("panther_serialization_cbor_encode", (1, 1), _json_encode, "panther_serialization_cbor_encode(value) -> string"))
_register(StdlibFunction("panther_serialization_cbor_decode", (1, 1), _json_decode, "panther_serialization_cbor_decode(text) -> object"))

# Base64
_register(StdlibFunction("panther_serialization_base64_encode", (1, 1), _crypto_base64_encode, "panther_serialization_base64_encode(data) -> string"))
_register(StdlibFunction("panther_serialization_base64_decode", (1, 1), _crypto_base64_decode, "panther_serialization_base64_decode(text) -> string"))

# Hex
_register(StdlibFunction("panther_serialization_hex_encode", (1, 1), _crypto_hex_encode, "panther_serialization_hex_encode(data) -> string"))
_register(StdlibFunction("panther_serialization_hex_decode", (1, 1), _crypto_hex_decode, "panther_serialization_hex_decode(text) -> string"))

# Universal encode/decode
_register(StdlibFunction("panther_serialization_encode", (2, 2), _serialization_encode, "panther_serialization_encode(value, format) -> string"))
_register(StdlibFunction("panther_serialization_decode", (2, 2), _serialization_decode, "panther_serialization_decode(data, format) -> object"))
_register(StdlibFunction("panther_serialization_encode_with_options", (3, 3), _serialization_encode_with_options, "panther_serialization_encode_with_options(value, format, options) -> string"))

# ========================================================================
# PHASE 11 — Concurrency & Async Runtime (PYTHON_BOOTSTRAP_BACKED)
# ========================================================================

# --- Thread-safe task registry ---
_concurrent_tasks: dict[str, dict] = {}
_concurrent_tasks_lock = threading.Lock()
_concurrent_executor = _futures.ThreadPoolExecutor(
    max_workers=32,
    thread_name_prefix="panther-concurrent",
)
_concurrent_next_id = 0
_concurrent_next_id_lock = threading.Lock()


def _concurrent_next_task_id() -> str:
    global _concurrent_next_id
    with _concurrent_next_id_lock:
        _concurrent_next_id += 1
        return f"task-{_concurrent_next_id}"


def _concurrent_spawn(fn: Callable) -> dict:
    task_id = _concurrent_next_task_id()
    entry = {
        "task_id": task_id,
        "state": "RUNNING",
        "value": None,
        "error": None,
        "thread": None,
        "cancelled": False,
    }

    def worker():
        try:
            entry["state"] = "RUNNING"
            result = fn()
            with _concurrent_tasks_lock:
                if entry.get("cancelled"):
                    entry["state"] = "CANCELLED"
                else:
                    entry["value"] = result
                    entry["state"] = "COMPLETED"
        except Exception as exc:
            with _concurrent_tasks_lock:
                entry["error"] = str(exc)
                entry["state"] = "FAILED"

    thread = threading.Thread(target=worker, daemon=True, name=f"panther-worker-{task_id}")
    entry["thread"] = thread
    with _concurrent_tasks_lock:
        _concurrent_tasks[task_id] = entry

    thread.start()
    return {"task_id": task_id, "state": "RUNNING", "value": None, "error": None}


def _concurrent_join(task_dict: dict) -> dict:
    task_id = task_dict.get("task_id", "")
    with _concurrent_tasks_lock:
        entry = _concurrent_tasks.get(task_id)
    if entry is None:
        raise RuntimeError(f"Unknown task: {task_id}")
    thread = entry.get("thread")
    if thread is not None and thread.is_alive():
        thread.join()
    with _concurrent_tasks_lock:
        return {
            "task_id": entry["task_id"],
            "state": entry["state"],
            "value": entry["value"],
            "error": entry["error"],
        }


def _concurrent_join_timeout(task_dict: dict, timeout_ms: int) -> dict:
    task_id = task_dict.get("task_id", "")
    timeout_sec = max(0.001, timeout_ms / 1000.0)
    with _concurrent_tasks_lock:
        entry = _concurrent_tasks.get(task_id)
    if entry is None:
        raise RuntimeError(f"Unknown task: {task_id}")
    thread = entry.get("thread")
    if thread is not None and thread.is_alive():
        thread.join(timeout=timeout_sec)
    with _concurrent_tasks_lock:
        state = entry["state"]
        if thread is not None and thread.is_alive():
            state = "RUNNING"
        return {
            "task_id": entry["task_id"],
            "state": state,
            "value": entry["value"],
            "error": entry["error"],
        }


def _concurrent_task_status(task_dict: dict) -> str:
    task_id = task_dict.get("task_id", "")
    with _concurrent_tasks_lock:
        entry = _concurrent_tasks.get(task_id)
    if entry is None:
        return "UNKNOWN"
    thread = entry.get("thread")
    if thread is not None and thread.is_alive() and entry["state"] == "RUNNING":
        return "RUNNING"
    return entry["state"]


def _concurrent_task_result(task_dict: dict) -> dict:
    task_id = task_dict.get("task_id", "")
    with _concurrent_tasks_lock:
        entry = _concurrent_tasks.get(task_id)
    if entry is None:
        return {"value": None, "error": "Task not found"}
    if entry["state"] == "COMPLETED":
        return {"value": entry["value"], "error": None}
    if entry["state"] == "FAILED":
        return {"value": None, "error": entry["error"]}
    return {"value": None, "error": f"Task not completed (state={entry['state']})"}


def _concurrent_task_error(task_dict: dict) -> str | None:
    task_id = task_dict.get("task_id", "")
    with _concurrent_tasks_lock:
        entry = _concurrent_tasks.get(task_id)
    if entry is None:
        raise RuntimeError(f"Unknown task: {task_id}")
    return entry.get("error")


def _concurrent_cancel(task_dict: dict) -> bool:
    task_id = task_dict.get("task_id", "")
    with _concurrent_tasks_lock:
        entry = _concurrent_tasks.get(task_id)
    if entry is None:
        return False
    if entry["state"] in ("COMPLETED", "FAILED", "CANCELLED"):
        return False
    entry["cancelled"] = True
    entry["state"] = "CANCELLED"
    return True


def _concurrent_worker_count() -> int:
    count = 0
    with _concurrent_tasks_lock:
        for entry in _concurrent_tasks.values():
            thread = entry.get("thread")
            if thread is not None and thread.is_alive():
                count += 1
    return count


def _concurrent_queue_create() -> dict:
    q = _queue.Queue()
    return {"_queue": q}


def _concurrent_queue_put(queue_dict: dict, value: Any) -> None:
    q = queue_dict.get("_queue")
    if q is None:
        raise RuntimeError("Invalid queue object")
    q.put(value)


def _concurrent_queue_get(queue_dict: dict) -> Any:
    q = queue_dict.get("_queue")
    if q is None:
        raise RuntimeError("Invalid queue object")
    return q.get()


def _concurrent_queue_get_timeout(queue_dict: dict, timeout_ms: int) -> Any:
    q = queue_dict.get("_queue")
    if q is None:
        raise RuntimeError("Invalid queue object")
    timeout_sec = max(0.001, timeout_ms / 1000.0)
    try:
        return q.get(timeout=timeout_sec)
    except _queue.Empty:
        return None


# --- Async backend ---
_async_executor = _futures.ThreadPoolExecutor(
    max_workers=32,
    thread_name_prefix="panther-async",
)
_async_futures: dict[str, _futures.Future] = {}
_async_tasks: dict[str, dict] = {}
_async_next_id = 0
_async_lock = threading.Lock()


def _async_next_task_id() -> str:
    global _async_next_id
    with _async_lock:
        _async_next_id += 1
        return f"async-{_async_next_id}"


def _async_task(fn: Callable) -> dict:
    task_id = _async_next_task_id()
    fut = _async_executor.submit(fn)
    with _async_lock:
        _async_futures[task_id] = fut
        _async_tasks[task_id] = {
            "task_id": task_id,
            "state": "RUNNING",
            "value": None,
            "error": None,
        }

    def on_done(f):
        with _async_lock:
            entry = _async_tasks.get(task_id)
            if entry is None:
                return
            try:
                exc = f.exception()
                if exc is not None:
                    entry["state"] = "FAILED"
                    entry["error"] = str(exc)
                else:
                    if entry.get("cancelled"):
                        entry["state"] = "CANCELLED"
                    else:
                        entry["value"] = f.result()
                        entry["state"] = "COMPLETED"
            except _futures.CancelledError:
                entry["state"] = "CANCELLED"

    fut.add_done_callback(on_done)
    return {"task_id": task_id, "state": "RUNNING", "value": None, "error": None}


def _async_run(task_dict: dict) -> dict:
    return _async_await_task(task_dict)


def _async_await_task(task_dict: dict) -> dict:
    task_id = task_dict.get("task_id", "")
    with _async_lock:
        fut = _async_futures.get(task_id)
        entry = _async_tasks.get(task_id)
    if fut is None or entry is None:
        raise RuntimeError(f"Unknown async task: {task_id}")
    try:
        fut.result()
    except Exception:
        pass
    with _async_lock:
        return {
            "task_id": entry["task_id"],
            "state": entry["state"],
            "value": entry["value"],
            "error": entry["error"],
        }


def _async_await_timeout(task_dict: dict, timeout_ms: int) -> dict:
    task_id = task_dict.get("task_id", "")
    timeout_sec = max(0.001, timeout_ms / 1000.0)
    with _async_lock:
        fut = _async_futures.get(task_id)
        entry = _async_tasks.get(task_id)
    if fut is None or entry is None:
        raise RuntimeError(f"Unknown async task: {task_id}")
    try:
        fut.result(timeout=timeout_sec)
    except _futures.TimeoutError:
        with _async_lock:
            return {
                "task_id": entry["task_id"],
                "state": "TIMED_OUT",
                "value": entry["value"],
                "error": "timeout",
            }
    except Exception:
        pass
    with _async_lock:
        return {
            "task_id": entry["task_id"],
            "state": entry["state"],
            "value": entry["value"],
            "error": entry["error"],
        }


def _async_sleep(milliseconds: int) -> None:
    time.sleep(max(0.001, milliseconds / 1000.0))


def _async_gather(task_dicts: list[dict]) -> list[dict]:
    results = []
    for td in task_dicts:
        r = _async_await_task(td)
        results.append(r)
    return results


def _async_race(task_dicts: list[dict]) -> dict:
    task_ids = []
    futures = []
    for td in task_dicts:
        tid = td.get("task_id", "")
        with _async_lock:
            fut = _async_futures.get(tid)
        if fut is not None:
            task_ids.append(tid)
            futures.append(fut)
    if not futures:
        return {"task_id": "", "state": "FAILED", "value": None, "error": "no tasks"}
    done, _ = _futures.wait(futures, return_when=_futures.FIRST_COMPLETED)
    for i, fut in enumerate(futures):
        if fut in done:
            tid = task_ids[i]
            with _async_lock:
                entry = _async_tasks.get(tid)
            if entry:
                return {
                    "task_id": entry["task_id"],
                    "state": entry["state"],
                    "value": entry["value"],
                    "error": entry["error"],
                }
    return {"task_id": "", "state": "FAILED", "value": None, "error": "race failed"}


def _async_retry(callable_fn: Callable, attempts: int) -> dict:
    last_error = None
    for attempt in range(attempts):
        try:
            result = callable_fn()
            if result is not None:
                return {"value": result, "error": None}
        except Exception as exc:
            last_error = str(exc)
        if attempt < attempts - 1:
            time.sleep(0.1)
    return {"value": None, "error": last_error or "all attempts failed"}


def _async_retry_with_backoff(callable_fn: Callable, attempts: int, initial_delay_ms: int) -> dict:
    delay = max(1, initial_delay_ms) / 1000.0
    last_error = None
    for attempt in range(attempts):
        try:
            result = callable_fn()
            if result is not None:
                return {"value": result, "error": None}
        except Exception as exc:
            last_error = str(exc)
        if attempt < attempts - 1:
            time.sleep(delay)
            delay *= 2
    return {"value": None, "error": last_error or "all attempts failed"}


def _async_cancel(task_dict: dict) -> bool:
    task_id = task_dict.get("task_id", "")
    with _async_lock:
        fut = _async_futures.get(task_id)
        entry = _async_tasks.get(task_id)
    if fut is None or entry is None:
        return False
    if entry["state"] in ("COMPLETED", "FAILED", "CANCELLED"):
        return False
    cancelled = fut.cancel()
    if cancelled:
        with _async_lock:
            entry["state"] = "CANCELLED"
    return cancelled


def _async_status(task_dict: dict) -> str:
    task_id = task_dict.get("task_id", "")
    with _async_lock:
        entry = _async_tasks.get(task_id)
    if entry is None:
        return "UNKNOWN"
    return entry["state"]


# --- Register concurrent backend functions ---
_register(StdlibFunction("_concurrent_spawn", (1, 1), _concurrent_spawn, "_concurrent_spawn(fn) -> task"))
_register(StdlibFunction("_concurrent_join", (1, 1), _concurrent_join, "_concurrent_join(task) -> task"))
_register(StdlibFunction("_concurrent_join_timeout", (2, 2), _concurrent_join_timeout, "_concurrent_join_timeout(task, ms) -> task"))
_register(StdlibFunction("_concurrent_task_status", (1, 1), _concurrent_task_status, "_concurrent_task_status(task) -> str"))
_register(StdlibFunction("_concurrent_task_result", (1, 1), _concurrent_task_result, "_concurrent_task_result(task) -> any"))
_register(StdlibFunction("_concurrent_task_error", (1, 1), _concurrent_task_error, "_concurrent_task_error(task) -> str"))
_register(StdlibFunction("_concurrent_cancel", (1, 1), _concurrent_cancel, "_concurrent_cancel(task) -> bool"))
_register(StdlibFunction("_concurrent_worker_count", (0, 0), _concurrent_worker_count, "_concurrent_worker_count() -> int"))
_register(StdlibFunction("_concurrent_queue_create", (0, 0), _concurrent_queue_create, "_concurrent_queue_create() -> queue"))
_register(StdlibFunction("_concurrent_queue_put", (2, 2), _concurrent_queue_put, "_concurrent_queue_put(queue, value) -> null"))
_register(StdlibFunction("_concurrent_queue_get", (1, 1), _concurrent_queue_get, "_concurrent_queue_get(queue) -> any"))
_register(StdlibFunction("_concurrent_queue_get_timeout", (2, 2), _concurrent_queue_get_timeout, "_concurrent_queue_get_timeout(queue, ms) -> any"))

# --- Register async backend functions ---
_register(StdlibFunction("_async_task", (1, 1), _async_task, "_async_task(fn) -> task"))
_register(StdlibFunction("_async_run", (1, 1), _async_run, "_async_run(task) -> task"))
_register(StdlibFunction("_async_await_task", (1, 1), _async_await_task, "_async_await_task(task) -> task"))
_register(StdlibFunction("_async_await_timeout", (2, 2), _async_await_timeout, "_async_await_timeout(task, ms) -> task"))
_register(StdlibFunction("_async_sleep", (1, 1), _async_sleep, "_async_sleep(ms) -> null"))
_register(StdlibFunction("_async_gather", (1, 1), _async_gather, "_async_gather(tasks) -> array"))
_register(StdlibFunction("_async_race", (1, 1), _async_race, "_async_race(tasks) -> task"))
_register(StdlibFunction("_async_retry", (2, 2), _async_retry, "_async_retry(fn, attempts) -> result"))
_register(StdlibFunction("_async_retry_with_backoff", (3, 3), _async_retry_with_backoff, "_async_retry_with_backoff(fn, attempts, delay_ms) -> result"))
_register(StdlibFunction("_async_cancel", (1, 1), _async_cancel, "_async_cancel(task) -> bool"))
_register(StdlibFunction("_async_status", (1, 1), _async_status, "_async_status(task) -> str"))

# ========================================================================
# PHASE 11b — Web Engine Backend (panther.web) — REAL HTTP SERVER
# ========================================================================

_web_servers: dict[str, Any] = {}
_web_server_lock = threading.Lock()


def _web_server_create(host: str, port: int) -> dict:
    from compiler.web import HttpServer
    server_id = f"web-{id(_web_servers)}-{len(_web_servers)}"
    server = HttpServer(host=str(host), port=int(port))
    handle = {"_server_id": server_id, "_server": server, "_host": str(host), "_port": int(port)}
    with _web_server_lock:
        _web_servers[server_id] = handle
    return handle


def _web_server_start(server_dict: dict) -> bool:
    sid = server_dict.get("_server_id", "")
    with _web_server_lock:
        handle = _web_servers.get(sid)
    if handle is None:
        return False
    server = handle["_server"]
    thread = threading.Thread(target=server.start, daemon=True, name=f"panther-web-{sid}")
    thread.start()
    handle["_thread"] = thread
    server._started.wait(timeout=5.0)
    return True


def _web_server_stop(server_dict: dict) -> bool:
    sid = server_dict.get("_server_id", "")
    with _web_server_lock:
        handle = _web_servers.get(sid)
    if handle is None:
        return False
    server = handle["_server"]
    try:
        server.stop()
        return True
    except Exception:
        return False


def _web_server_running(server_dict: dict) -> bool:
    sid = server_dict.get("_server_id", "")
    with _web_server_lock:
        handle = _web_servers.get(sid)
    if handle is None:
        return False
    server = handle["_server"]
    return server._server is not None


def _web_server_port(server_dict: dict) -> int:
    sid = server_dict.get("_server_id", "")
    with _web_server_lock:
        handle = _web_servers.get(sid)
    if handle is None:
        return 0
    return handle["_server"].port


def _web_route_add(server_dict: dict, method: str, path: str, handler_fn: Callable) -> bool:
    sid = server_dict.get("_server_id", "")
    with _web_server_lock:
        handle = _web_servers.get(sid)
    if handle is None:
        return False
    server = handle["_server"]

    def wrapper(**kwargs: Any) -> Any:
        from compiler.web.server import _request_context
        ctx = _request_context
        route_param_names: tuple[str, ...] = getattr(ctx, "_route_param_names", ())
        query_params: dict[str, Any] = {}
        route_params: dict[str, str] = {}
        raw_body: Any = None
        for k, v in kwargs.items():
            if k == "body":
                raw_body = v
            elif k in route_param_names:
                route_params[k] = str(v)
            else:
                query_params[k] = v
        req_method = getattr(ctx, "method", method)
        req_path = getattr(ctx, "path", path)
        req_headers = getattr(ctx, "headers", {})
        body_str = ""
        if raw_body is not None:
            if isinstance(raw_body, bytes):
                body_str = raw_body.decode("utf-8", errors="replace")
            else:
                body_str = str(raw_body)
        req: dict[str, Any] = {
            "_method": req_method,
            "_path": req_path,
            "_headers": req_headers,
            "method": req_method,
            "path": req_path,
            "headers": req_headers,
            "query": query_params,
            "body": body_str,
            "params": route_params,
        }
        # Backward compat: expose route and query params at top level too
        for k, v in route_params.items():
            req[k] = v
        for k, v in query_params.items():
            req[k] = v
        return handler_fn(req)

    server.router.add_route(str(method).upper(), str(path), wrapper)
    return True


def _web_route_get(server_dict: dict, path: str, handler_fn: Callable) -> bool:
    return _web_route_add(server_dict, "GET", path, handler_fn)


def _web_route_post(server_dict: dict, path: str, handler_fn: Callable) -> bool:
    return _web_route_add(server_dict, "POST", path, handler_fn)


def _web_route_put(server_dict: dict, path: str, handler_fn: Callable) -> bool:
    return _web_route_add(server_dict, "PUT", path, handler_fn)


def _web_route_delete(server_dict: dict, path: str, handler_fn: Callable) -> bool:
    return _web_route_add(server_dict, "DELETE", path, handler_fn)


def _web_error_handler(server_dict: dict, status: int, handler_fn: Callable) -> bool:
    sid = server_dict.get("_server_id", "")
    with _web_server_lock:
        handle = _web_servers.get(sid)
    if handle is None:
        return False
    server = handle["_server"]
    server.set_error_handler(int(status), handler_fn)
    return True


def _web_response_text(text: str) -> str:
    return str(text)


def _web_response_json(data: Any) -> str:
    return json.dumps(_convert(data))


def _web_response_html(html: str) -> str:
    return str(html)


def _web_response(data: Any, status: int = 200) -> dict:
    body = data
    if not isinstance(data, str):
        body = json.dumps(_convert(data))
    return {
        "_type": "Response",
        "status": int(status),
        "headers": {"Content-Type": "text/plain; charset=utf-8"},
        "body": body,
    }


def _web_response_status(data: Any, status: int, content_type: str = "application/json; charset=utf-8") -> dict:
    body = data
    if not isinstance(data, str):
        body = json.dumps(_convert(data))
    return {
        "_type": "Response",
        "status": int(status),
        "headers": {"Content-Type": content_type},
        "body": body,
    }


def _web_response_redirect(url: str, status: int = 302) -> dict:
    return {
        "_type": "Response",
        "status": int(status),
        "headers": {"Location": str(url)},
        "body": "",
    }


def _web_request_method(req: dict) -> str:
    return str(req.get("_method", req.get("method", "GET")))


def _web_request_path(req: dict) -> str:
    return str(req.get("_path", req.get("path", "")))


def _web_request_query(req: dict, name: str, default: str = "") -> str:
    qp = req.get("query", {})
    val = qp.get(name)
    if val is None:
        val = req.get(name)
    return str(val) if val is not None else default


def _web_request_header(req: dict, name: str) -> str:
    headers = req.get("_headers", req.get("headers", {}))
    if isinstance(headers, dict):
        return str(headers.get(name, ""))
    return ""


def _web_request_body(req: dict) -> str:
    body = req.get("body", req.get("body_obj", ""))
    if body is not None:
        if isinstance(body, bytes):
            return body.decode("utf-8", errors="replace")
        return str(body)
    return ""


_register(StdlibFunction("_web_server_create", (2, 2), _web_server_create, "_web_server_create(host, port) -> server"))
_register(StdlibFunction("_web_server_start", (1, 1), _web_server_start, "_web_server_start(server) -> bool"))
_register(StdlibFunction("_web_server_stop", (1, 1), _web_server_stop, "_web_server_stop(server) -> bool"))
_register(StdlibFunction("_web_server_running", (1, 1), _web_server_running, "_web_server_running(server) -> bool"))
_register(StdlibFunction("_web_server_port", (1, 1), _web_server_port, "_web_server_port(server) -> int"))
_register(StdlibFunction("_web_route_add", (4, 4), _web_route_add, "_web_route_add(server, method, path, handler) -> bool"))
_register(StdlibFunction("_web_route_get", (3, 3), _web_route_get, "_web_route_get(server, path, handler) -> bool"))
_register(StdlibFunction("_web_route_post", (3, 3), _web_route_post, "_web_route_post(server, path, handler) -> bool"))
_register(StdlibFunction("_web_route_put", (3, 3), _web_route_put, "_web_route_put(server, path, handler) -> bool"))
_register(StdlibFunction("_web_route_delete", (3, 3), _web_route_delete, "_web_route_delete(server, path, handler) -> bool"))
_register(StdlibFunction("_web_error_handler", (3, 3), _web_error_handler, "_web_error_handler(server, status, handler) -> bool"))
_register(StdlibFunction("_web_response_text", (1, 1), _web_response_text, "_web_response_text(text) -> string"))
_register(StdlibFunction("_web_response_json", (1, 1), _web_response_json, "_web_response_json(data) -> string"))
_register(StdlibFunction("_web_response_html", (1, 1), _web_response_html, "_web_response_html(html) -> string"))
_register(StdlibFunction("_web_response", (1, 2), _web_response, "_web_response(data[, status]) -> Response"))
_register(StdlibFunction("_web_response_status", (2, 3), _web_response_status, "_web_response_status(data, status[, content_type]) -> Response"))
_register(StdlibFunction("_web_response_redirect", (1, 2), _web_response_redirect, "_web_response_redirect(url[, status]) -> Response"))
_register(StdlibFunction("_web_request_query", (2, 3), _web_request_query, "_web_request_query(req, name[, default]) -> string"))
_register(StdlibFunction("_web_request_body", (1, 1), _web_request_body, "_web_request_body(req) -> string"))


# ========================================================================
# Phase 4 — Browser Launch (system.open_url)
# ========================================================================

def _system_open_url(url: str) -> bool:
    """Open a URL in the default browser."""
    import webbrowser
    try:
        webbrowser.open(str(url))
        return True
    except Exception:
        return False


_register(StdlibFunction("_system_open_url", (1, 1), _system_open_url, "_system_open_url(url) -> bool; open URL in default browser"))

# End of stdlib function registrations

