"""Phase C6 — Database Foundation Tests

Tests for SQLite database with transaction support:
- db_begin, db_commit, db_rollback
- CRUD operations with transactions
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.runtime import execute_source


class TestDBTransactions:
    def test_commit_persists_data(self):
        """Data inserted in a committed transaction should persist."""
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            db = f.name
        try:
            src = f"""panther main {{
    let conn = db_open("{db}");
    db_execute(conn, "CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)");
    db_begin(conn);
    db_execute(conn, "INSERT INTO t VALUES (1, 'persist')");
    db_commit(conn);
    let r = db_query(conn, "SELECT v FROM t WHERE id = 1");
    print(r[0]["v"]);
    db_close(conn);
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "persist"
        finally:
            Path(db).unlink(missing_ok=True)

    def test_rollback_undoes_data(self):
        """Data inserted in a rolled-back transaction should not persist."""
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            db = f.name
        try:
            src = f"""panther main {{
    let conn = db_open("{db}");
    db_execute(conn, "CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)");
    db_begin(conn);
    db_execute(conn, "INSERT INTO t VALUES (1, 'rollback_me')");
    db_rollback(conn);
    let r = db_query(conn, "SELECT COUNT(*) as cnt FROM t");
    print(to_string(r[0]["cnt"]));
    db_close(conn);
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "0"
        finally:
            Path(db).unlink(missing_ok=True)

    def test_multiple_operations_in_txn(self):
        """Multiple operations in a single transaction should work."""
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            db = f.name
        try:
            src = f"""panther main {{
    let conn = db_open("{db}");
    db_execute(conn, "CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)");
    db_begin(conn);
    db_execute(conn, "INSERT INTO t VALUES (1, 'a')");
    db_execute(conn, "INSERT INTO t VALUES (2, 'b')");
    db_execute(conn, "INSERT INTO t VALUES (3, 'c')");
    db_commit(conn);
    let r = db_query(conn, "SELECT COUNT(*) as cnt FROM t");
    print(to_string(r[0]["cnt"]));
    db_close(conn);
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "3"
        finally:
            Path(db).unlink(missing_ok=True)

    def test_rollback_then_commit(self):
        """Rollback then commit should work in sequence."""
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            db = f.name
        try:
            src = f"""panther main {{
    let conn = db_open("{db}");
    db_execute(conn, "CREATE TABLE t (id INTEGER PRIMARY KEY)");
    db_begin(conn);
    db_execute(conn, "INSERT INTO t VALUES (1)");
    db_rollback(conn);
    db_begin(conn);
    db_execute(conn, "INSERT INTO t VALUES (2)");
    db_commit(conn);
    let r = db_query(conn, "SELECT COUNT(*) as cnt FROM t");
    print(to_string(r[0]["cnt"]));
    db_close(conn);
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "1"
        finally:
            Path(db).unlink(missing_ok=True)


class TestDBSQLiteAliases:
    def test_sqlite_aliases_work(self):
        """sqlite_begin/commit/rollback aliases should work."""
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            db = f.name
        try:
            src = f"""panther main {{
    let conn = sqlite_open("{db}");
    sqlite_execute(conn, "CREATE TABLE t (x INTEGER)");
    sqlite_begin(conn);
    sqlite_execute(conn, "INSERT INTO t VALUES (99)");
    sqlite_rollback(conn);
    let r = sqlite_query(conn, "SELECT COUNT(*) as c FROM t");
    print(to_string(r[0]["c"]));
    sqlite_commit(conn);
    sqlite_close(conn);
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "0"
        finally:
            Path(db).unlink(missing_ok=True)


class TestDBCRUD:
    def test_full_crud(self):
        """Full CRUD lifecycle should work."""
        src = """panther main {
    let conn = db_open(":memory:");
    db_execute(conn, "CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT)");
    db_execute(conn, "INSERT INTO items VALUES (1, 'create')");
    let r1 = db_query(conn, "SELECT name FROM items WHERE id = 1");
    print(r1[0]["name"]);
    db_execute(conn, "UPDATE items SET name = 'update' WHERE id = 1");
    let r2 = db_query(conn, "SELECT name FROM items WHERE id = 1");
    print(r2[0]["name"]);
    db_execute(conn, "DELETE FROM items WHERE id = 1");
    let r3 = db_query(conn, "SELECT COUNT(*) as cnt FROM items");
    print(to_string(r3[0]["cnt"]));
    db_close(conn);
}"""
        result = execute_source(src)
        assert result.error is None
        out = result.captured_output
        assert out[0].strip() == "create"
        assert out[1].strip() == "update"
        assert out[2].strip() == "0"
