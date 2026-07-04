from __future__ import annotations

import sqlite3
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


class DatabaseEngine:
    def connect(self) -> Any:
        raise NotImplementedError

    def execute(self, sql: str, params: tuple = ()) -> Any:
        raise NotImplementedError

    def close(self) -> None:
        raise NotImplementedError


class SqliteEngine(DatabaseEngine):
    def __init__(self, path: str = ":memory:") -> None:
        self.path = str(Path(path).expanduser().resolve()) if path != ":memory:" else path
        self._conn: sqlite3.Connection | None = None

    def connect(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(self.path)
            self._conn.row_factory = sqlite3.Row
        return self._conn

    def execute(self, sql: str, params: tuple = ()) -> Any:
        conn = self.connect()
        return conn.execute(sql, params)

    def close(self) -> None:
        if self._conn:
            self._conn.close()
            self._conn = None

    def __enter__(self) -> SqliteEngine:
        self.connect()
        return self

    def __exit__(self, *args: Any) -> None:
        self.close()


@dataclass
class Column:
    name: str
    type: str = "TEXT"
    primary_key: bool = False
    nullable: bool = True
    default: Any = None
    unique: bool = False

    def sql(self) -> str:
        parts = [self.name, self.type]
        if self.primary_key:
            parts.append("PRIMARY KEY")
        if not self.nullable:
            parts.append("NOT NULL")
        if self.default is not None:
            parts.append(f"DEFAULT {self.default!r}")
        if self.unique:
            parts.append("UNIQUE")
        return " ".join(parts)


@dataclass
class Table:
    name: str
    columns: list[Column] = field(default_factory=list)


class Model:
    def __init__(self, table: Table, engine: DatabaseEngine) -> None:
        self._table = table
        self._engine = engine

    @property
    def table(self) -> Table:
        return self._table

    def create_table(self) -> str:
        cols = ", ".join(c.sql() for c in self._table.columns)
        sql = f"CREATE TABLE IF NOT EXISTS {self._table.name} ({cols})"
        self._engine.execute(sql)
        return sql

    def drop_table(self) -> str:
        sql = f"DROP TABLE IF EXISTS {self._table.name}"
        self._engine.execute(sql)
        return sql


class QueryBuilder:
    def __init__(self, table: str, engine: DatabaseEngine) -> None:
        self._table = table
        self._engine = engine
        self._where_clauses: list[str] = []
        self._params: list[Any] = []
        self._order_by: str | None = None
        self._limit: int | None = None

    def where(self, condition: str, *params: Any) -> QueryBuilder:
        self._where_clauses.append(condition)
        self._params.extend(params)
        return self

    def order(self, column: str, direction: str = "ASC") -> QueryBuilder:
        self._order_by = f"{column} {direction}"
        return self

    def limit(self, count: int) -> QueryBuilder:
        self._limit = count
        return self

    def select(self, columns: str = "*") -> list[dict[str, Any]]:
        sql = f"SELECT {columns} FROM {self._table}"
        if self._where_clauses:
            sql += " WHERE " + " AND ".join(self._where_clauses)
        if self._order_by:
            sql += " ORDER BY " + self._order_by
        if self._limit is not None:
            sql += f" LIMIT {self._limit}"
        cursor = self._engine.execute(sql, tuple(self._params))
        return [dict(row) for row in cursor.fetchall()]

    def insert(self, data: dict[str, Any]) -> int:
        cols = ", ".join(data.keys())
        placeholders = ", ".join("?" for _ in data)
        sql = f"INSERT INTO {self._table} ({cols}) VALUES ({placeholders})"
        cursor = self._engine.execute(sql, tuple(data.values()))
        self._engine.connect().commit()
        return cursor.lastrowid

    def update(self, data: dict[str, Any]) -> int:
        sets = ", ".join(f"{k} = ?" for k in data)
        sql = f"UPDATE {self._table} SET {sets}"
        params = list(data.values())
        if self._where_clauses:
            sql += " WHERE " + " AND ".join(self._where_clauses)
        params.extend(self._params)
        cursor = self._engine.execute(sql, tuple(params))
        self._engine.connect().commit()
        return cursor.rowcount

    def delete(self) -> int:
        sql = f"DELETE FROM {self._table}"
        if self._where_clauses:
            sql += " WHERE " + " AND ".join(self._where_clauses)
        cursor = self._engine.execute(sql, tuple(self._params))
        self._engine.connect().commit()
        return cursor.rowcount


@dataclass
class Migration:
    version: str
    sql: str
    description: str = ""


def migrate(engine: DatabaseEngine, migrations: list[Migration]) -> list[str]:
    engine.execute(
        "CREATE TABLE IF NOT EXISTS _migrations (version TEXT PRIMARY KEY, applied_at TEXT)"
    )
    applied = set()
    for row in engine.execute("SELECT version FROM _migrations").fetchall():
        applied.add(row["version"])
    results: list[str] = []
    for m in migrations:
        if m.version not in applied:
            engine.execute(m.sql)
            engine.execute(
                "INSERT INTO _migrations (version, applied_at) VALUES (?, datetime('now'))",
                (m.version,),
            )
            engine.connect().commit()
            results.append(m.version)
    return results
