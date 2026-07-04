from compiler.database import (
    Column,
    DatabaseEngine,
    Migration,
    Model,
    QueryBuilder,
    SqliteEngine,
    Table,
    migrate,
)


def test_sqlite_engine_connect():
    engine = SqliteEngine(":memory:")
    conn = engine.connect()
    assert conn is not None
    engine.close()


def test_sqlite_engine_execute():
    engine = SqliteEngine(":memory:")
    engine.execute("CREATE TABLE test (id INTEGER, name TEXT)")
    engine.execute("INSERT INTO test VALUES (?, ?)", (1, "hello"))
    rows = engine.execute("SELECT * FROM test").fetchall()
    assert len(rows) == 1
    assert rows[0]["name"] == "hello"
    engine.close()


def test_sqlite_engine_context_manager():
    with SqliteEngine(":memory:") as engine:
        engine.execute("CREATE TABLE t (x INTEGER)")
        engine.execute("INSERT INTO t VALUES (42)")
        rows = engine.execute("SELECT * FROM t").fetchall()
        assert rows[0]["x"] == 42


def test_column_defaults():
    c = Column(name="id", type="INTEGER")
    assert c.name == "id"
    assert c.type == "INTEGER"
    assert not c.primary_key


def test_column_sql_primary_key():
    c = Column(name="id", type="INTEGER", primary_key=True, nullable=False)
    sql = c.sql()
    assert "id" in sql
    assert "INTEGER" in sql
    assert "PRIMARY KEY" in sql
    assert "NOT NULL" in sql


def test_column_sql_unique():
    c = Column(name="email", type="TEXT", unique=True)
    sql = c.sql()
    assert "UNIQUE" in sql


def test_table_creation():
    table = Table(
        name="users",
        columns=[
            Column(name="id", type="INTEGER", primary_key=True, nullable=False),
            Column(name="name", type="TEXT", nullable=False),
        ],
    )
    assert table.name == "users"
    assert len(table.columns) == 2


def test_model_create_table():
    engine = SqliteEngine(":memory:")
    table = Table(
        name="items",
        columns=[Column(name="id", type="INTEGER", primary_key=True), Column(name="value", type="TEXT")],
    )
    model = Model(table, engine)
    sql = model.create_table()
    assert "CREATE TABLE" in sql
    assert "items" in sql
    engine.execute("INSERT INTO items (value) VALUES ('test')")
    rows = engine.execute("SELECT * FROM items").fetchall()
    assert len(rows) == 1
    engine.close()


def test_model_drop_table():
    engine = SqliteEngine(":memory:")
    table = Table(name="temp", columns=[Column(name="x", type="INTEGER")])
    model = Model(table, engine)
    model.create_table()
    sql = model.drop_table()
    assert "DROP TABLE" in sql


def test_query_builder_select_all():
    engine = SqliteEngine(":memory:")
    engine.execute("CREATE TABLE products (id INTEGER, name TEXT)")
    engine.execute("INSERT INTO products VALUES (1, 'A')")
    engine.execute("INSERT INTO products VALUES (2, 'B')")
    qb = QueryBuilder("products", engine)
    rows = qb.select()
    assert len(rows) == 2
    engine.close()


def test_query_builder_where():
    engine = SqliteEngine(":memory:")
    engine.execute("CREATE TABLE products (id INTEGER, name TEXT)")
    engine.execute("INSERT INTO products VALUES (1, 'A')")
    engine.execute("INSERT INTO products VALUES (2, 'B')")
    qb = QueryBuilder("products", engine)
    rows = qb.where("id = ?", 1).select()
    assert len(rows) == 1
    assert rows[0]["name"] == "A"
    engine.close()


def test_query_builder_insert():
    engine = SqliteEngine(":memory:")
    engine.execute("CREATE TABLE t (id INTEGER PRIMARY KEY, val TEXT)")
    qb = QueryBuilder("t", engine)
    row_id = qb.insert({"val": "hello"})
    assert row_id == 1
    rows = qb.select()
    assert len(rows) == 1
    engine.close()


def test_query_builder_update():
    engine = SqliteEngine(":memory:")
    engine.execute("CREATE TABLE t (id INTEGER, val TEXT)")
    engine.execute("INSERT INTO t VALUES (1, 'old')")
    qb = QueryBuilder("t", engine)
    count = qb.where("id = ?", 1).update({"val": "new"})
    assert count == 1
    rows = qb.where("id = ?", 1).select()
    assert rows[0]["val"] == "new"
    engine.close()


def test_query_builder_delete():
    engine = SqliteEngine(":memory:")
    engine.execute("CREATE TABLE t (id INTEGER)")
    engine.execute("INSERT INTO t VALUES (1)")
    engine.execute("INSERT INTO t VALUES (2)")
    count = QueryBuilder("t", engine).where("id = ?", 1).delete()
    assert count == 1
    rows = QueryBuilder("t", engine).select()
    assert len(rows) == 1
    engine.close()


def test_query_builder_order():
    engine = SqliteEngine(":memory:")
    engine.execute("CREATE TABLE t (id INTEGER)")
    engine.execute("INSERT INTO t VALUES (2)")
    engine.execute("INSERT INTO t VALUES (1)")
    qb = QueryBuilder("t", engine)
    rows = qb.order("id", "DESC").select()
    assert rows[0]["id"] == 2
    assert rows[1]["id"] == 1
    engine.close()


def test_query_builder_limit():
    engine = SqliteEngine(":memory:")
    engine.execute("CREATE TABLE t (id INTEGER)")
    engine.execute("INSERT INTO t VALUES (1)")
    engine.execute("INSERT INTO t VALUES (2)")
    engine.execute("INSERT INTO t VALUES (3)")
    qb = QueryBuilder("t", engine)
    rows = qb.limit(2).select()
    assert len(rows) == 2
    engine.close()


def test_migration():
    engine = SqliteEngine(":memory:")
    migrations = [
        Migration(version="001", sql="CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)", description="create users"),
        Migration(version="002", sql="ALTER TABLE users ADD COLUMN email TEXT", description="add email"),
    ]
    applied = migrate(engine, migrations)
    assert applied == ["001", "002"]
    rows = engine.execute("SELECT * FROM users").fetchall()
    assert len(rows) == 0
    # Re-run should be no-op
    applied2 = migrate(engine, migrations)
    assert applied2 == []
    engine.close()


def test_migration_tracking():
    engine = SqliteEngine(":memory:")
    m1 = Migration(version="001", sql="CREATE TABLE t (x INTEGER)")
    migrate(engine, [m1])
    rows = engine.execute("SELECT version FROM _migrations").fetchall()
    assert len(rows) == 1
    assert rows[0]["version"] == "001"
    engine.close()


def test_database_engine_interface():
    engine = DatabaseEngine()
    try:
        engine.connect()
        assert False, "should raise"
    except NotImplementedError:
        pass
    try:
        engine.execute("")
        assert False, "should raise"
    except NotImplementedError:
        pass
    try:
        engine.close()
        assert False, "should raise"
    except NotImplementedError:
        pass
