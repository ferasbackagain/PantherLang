panther main {
    // SQLite connection management
    fn panther_database_open(path) {
        return db_open(path);
    }

    fn panther_database_close(conn) {
        return db_close(conn);
    }

    // Query execution
    fn panther_database_execute(conn, sql, params) {
        if params == null {
            return db_execute(conn, sql);
        }
        return db_execute(conn, sql, params);
    }

    fn panther_database_query(conn, sql, params) {
        if params == null {
            return db_query(conn, sql);
        }
        return db_query(conn, sql, params);
    }

    fn panther_database_query_one(conn, sql, params) {
        let rows = panther_database_query(conn, sql, params);
        if len(rows) > 0 {
            return rows[0];
        }
        return null;
    }

    fn panther_database_query_scalar(conn, sql, params) {
        let row = panther_database_query_one(conn, sql, params);
        if row != null {
            // Return first column value - simplified
            return panther_database_row_first_value(row);
        }
        return null;
    }

    // Transaction management
    fn panther_database_begin(conn) {
        return db_begin(conn);
    }

    fn panther_database_commit(conn) {
        return db_commit(conn);
    }

    fn panther_database_rollback(conn) {
        return db_rollback(conn);
    }

    fn panther_database_transaction(conn, callback) {
        let ok = panther_database_begin(conn);
        if !ok {
            return {ok: false, error: "Failed to begin transaction"};
        }
        let result = callback(conn);
        if result.ok == false {
            panther_database_rollback(conn);
            return result;
        }
        ok = panther_database_commit(conn);
        if !ok {
            return {ok: false, error: "Failed to commit transaction"};
        }
        return {ok: true, value: result.value};
    }

    // Prepared statements (using parameterized queries)
    fn panther_database_prepare(conn, sql) {
        return {conn: conn, sql: sql};
    }

    fn panther_database_stmt_execute(stmt, params) {
        return db_execute(stmt.conn, stmt.sql, params);
    }

    fn panther_database_stmt_query(stmt, params) {
        return db_query(stmt.conn, stmt.sql, params);
    }

    fn panther_database_stmt_query_one(stmt, params) {
        let rows = panther_database_stmt_query(stmt, params);
        if len(rows) > 0 {
            return rows[0];
        }
        return null;
    }

    // Schema operations
    fn panther_database_table_exists(conn, table) {
        let rows = db_query(conn, "SELECT name FROM sqlite_master WHERE type='table' AND name=?", [table]);
        return len(rows) > 0;
    }

    fn panther_database_get_columns(conn, table) {
        return db_query(conn, "PRAGMA table_info(" + table + ")");
    }

    fn panther_database_get_indexes(conn, table) {
        return db_query(conn, "PRAGMA index_list(" + table + ")");
    }

    fn panther_database_get_foreign_keys(conn, table) {
        return db_query(conn, "PRAGMA foreign_key_list(" + table + ")");
    }

    // Backup
    fn panther_database_backup(conn, dest_path) {
        // SQLite backup API not directly exposed
        // This would require native backend
        return false;
    }

    // Vacuum and maintenance
    fn panther_database_vacuum(conn) {
        return db_execute(conn, "VACUUM");
    }

    fn panther_database_analyze(conn) {
        return db_execute(conn, "ANALYZE");
    }

    // Row helpers
    fn panther_database_row_first_value(row) {
        // Get first key from row object
        let keys = panther_database_row_keys(row);
        if len(keys) > 0 {
            return row[keys[0]];
        }
        return null;
    }

    fn panther_database_row_keys(row) {
        // Note: object iteration not supported in for-loops
        // Return empty array as placeholder
        // In practice, use known column names
        return [];
    }

    fn panther_database_rows_to_array(rows) {
        return rows;
    }
}