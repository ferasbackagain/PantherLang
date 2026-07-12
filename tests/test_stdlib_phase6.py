"""Tests for Phase 6 stdlib additions: filesystem, HTTP, regex, collections, SQLite."""

import tempfile
from pathlib import Path

from compiler.runtime import execute_source


# --- Filesystem ---

def test_read_write_file():
    with tempfile.TemporaryDirectory() as tmp:
        result = execute_source(f'''
panther main {{
    write_file("{tmp}/test.txt", "hello world");
    let content = read_file("{tmp}/test.txt");
    print(content);
}}
''')
        assert result.error is None
        assert "hello world" in " ".join(result.captured_output)


def test_file_exists():
    with tempfile.TemporaryDirectory() as tmp:
        result = execute_source(f'''
panther main {{
    write_file("{tmp}/ex.txt", "data");
    print(file_exists("{tmp}/ex.txt"));
    print(file_exists("{tmp}/nonexistent.txt"));
}}
''')
        assert result.error is None
        output = " ".join(result.captured_output)
        assert "true" in output
        assert "false" in output


def test_mkdir_and_list_dir():
    with tempfile.TemporaryDirectory() as tmp:
        result = execute_source(f'''
panther main {{
    mkdir("{tmp}/subdir");
    write_file("{tmp}/subdir/a.txt", "a");
    write_file("{tmp}/subdir/b.txt", "b");
    let files = list_dir("{tmp}/subdir");
    print(len(files));
}}
''')
        assert result.error is None
        assert "2" in " ".join(result.captured_output)


def test_remove_file():
    with tempfile.TemporaryDirectory() as tmp:
        p = Path(tmp) / "del.txt"
        p.write_text("delete me")
        result = execute_source(f'''
panther main {{
    print(file_exists("{tmp}/del.txt"));
    remove_file("{tmp}/del.txt");
    print(file_exists("{tmp}/del.txt"));
}}
''')
        assert result.error is None
        output = " ".join(result.captured_output)
        assert output.count("true") == 1
        assert output.count("false") == 1


# --- Regex ---

def test_regex_match():
    result = execute_source('''
panther main {
    print(regex_match("hello", "hello world"));
    print(regex_match("^foo", "bar foo"));
}
''')
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "true" in output
    assert "false" in output


def test_regex_replace():
    result = execute_source('''
panther main {
    let s = regex_replace("world", "Panther", "hello world");
    print(s);
}
''')
    assert result.error is None
    assert "hello Panther" in " ".join(result.captured_output)


def test_regex_split():
    result = execute_source('''
panther main {
    let parts = regex_split("[,\\s]+", "a, b, c");
    print(len(parts));
}
''')
    assert result.error is None
    assert "3" in " ".join(result.captured_output)


# --- Collections ---

def test_array_push():
    result = execute_source('''
panther main {
    let a = [1, 2];
    let n = array_push(a, 3);
    print(n);
    print(a);
}
''')
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "[1, 2, 3]" in output


def test_array_push_returns_array():
    """Verify array_push returns the array, not the length (regression)."""
    result = execute_source('''
panther main {
    let a = [];
    a = array_push(a, 1);
    a = array_push(a, 2);
    a = array_push(a, 3);
    print(a);
}
''')
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "[1, 2, 3]" in output


def test_array_pop():
    result = execute_source('''
panther main {
    let a = [10, 20, 30];
    let last = array_pop(a);
    print(last);
    print(a);
}
''')
    assert result.error is None
    output = " ".join(result.captured_output)
    assert "30" in output
    assert "[10, 20]" in output


def test_array_sort():
    result = execute_source('''
panther main {
    let a = [3, 1, 2];
    let s = array_sort(a);
    print(s);
}
''')
    assert result.error is None
    assert "[1, 2, 3]" in " ".join(result.captured_output)


def test_array_reverse():
    result = execute_source('''
panther main {
    let a = [1, 2, 3];
    let r = array_reverse(a);
    print(r);
}
''')
    assert result.error is None
    assert "[3, 2, 1]" in " ".join(result.captured_output)


# --- SQLite ---

def test_db_open_and_query():
    import tempfile, os
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as f:
        db_path = f.name
    try:
        result = execute_source(f'''
panther main {{
    let conn = db_open("{db_path}");
    db_execute(conn, "CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, name TEXT)");
    db_execute(conn, "INSERT INTO test (name) VALUES ('Alice')");
    db_execute(conn, "INSERT INTO test (name) VALUES ('Bob')");
    let rows = db_query(conn, "SELECT name FROM test ORDER BY id");
    print(len(rows));
    db_close(conn);
}}
''')
        assert result.error is None, result.error
        assert "2" in " ".join(result.captured_output)
    finally:
        os.unlink(db_path)


def test_db_query_with_params():
    import tempfile, os
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as f:
        db_path = f.name
    try:
        result = execute_source(f'''
panther main {{
    let conn = db_open("{db_path}");
    db_execute(conn, "CREATE TABLE items (id INTEGER PRIMARY KEY, val TEXT)");
    db_execute(conn, "INSERT INTO items (val) VALUES ('x')");
    db_execute(conn, "INSERT INTO items (val) VALUES ('y')");
    let rows = db_query(conn, "SELECT val FROM items WHERE id = ?", [1]);
    print(len(rows));
    db_close(conn);
}}
''')
        assert result.error is None, result.error
        assert "1" in " ".join(result.captured_output)
    finally:
        os.unlink(db_path)


def test_db_execute_returns_rowcount():
    import tempfile, os
    with tempfile.NamedTemporaryFile(suffix=".sqlite", delete=False) as f:
        db_path = f.name
    try:
        result = execute_source(f'''
panther main {{
    let conn = db_open("{db_path}");
    db_execute(conn, "CREATE TABLE t (id INTEGER PRIMARY KEY)");
    db_execute(conn, "INSERT INTO t VALUES (1)");
    db_execute(conn, "INSERT INTO t VALUES (2)");
    let n = db_execute(conn, "DELETE FROM t WHERE id = 1");
    print(n);
    db_close(conn);
}}
''')
        assert result.error is None, result.error
        assert "1" in " ".join(result.captured_output)
    finally:
        os.unlink(db_path)
