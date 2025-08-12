//! Query execution and result handling module

use crate::error::{DconError, Result};
use serde_json::Value;
use tokio_postgres::Row;

/// Query execution result
#[derive(Debug, Clone)]
pub struct QueryResult {
    pub rows: Vec<Row>,
    pub affected_rows: Option<u64>,
    pub columns: Vec<String>,
}

impl QueryResult {
    pub fn new(rows: Vec<Row>, affected_rows: Option<u64>) -> Self {
        let columns = if let Some(first_row) = rows.first() {
            first_row.columns().iter().map(|col| col.name().to_string()).collect()
        } else {
            Vec::new()
        };

        Self {
            rows,
            affected_rows,
            columns,
        }
    }

    /// Convert results to JSON
    pub fn to_json(&self) -> Result<Vec<Value>> {
        Ok(self.rows.iter().map(crate::database::row_to_json).collect())
    }

    /// Check if the result is empty
    pub fn is_empty(&self) -> bool {
        self.rows.is_empty()
    }

    /// Get the number of rows
    pub fn row_count(&self) -> usize {
        self.rows.len()
    }
}

/// Query builder for common database operations
pub struct QueryBuilder;

impl QueryBuilder {
    /// Build a SELECT query for listing databases
    pub fn list_databases() -> &'static str {
        r#"
            SELECT
                d.datname as name,
                pg_catalog.pg_get_userbyid(d.datdba) as owner,
                pg_catalog.pg_encoding_to_char(d.encoding) as encoding,
                pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname)) as size,
                COALESCE(shobj.description, 'No description') as description
            FROM pg_catalog.pg_database d
            LEFT JOIN pg_catalog.pg_shdescription shobj ON d.oid = shobj.objoid
            WHERE d.datallowconn = true
            ORDER BY d.datname;
        "#
    }

    /// Build a SELECT query for listing tables
    pub fn list_tables(include_system: bool) -> String {
        let system_filter = if include_system {
            ""
        } else {
            "AND schemaname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')"
        };

        format!(
            r#"
                SELECT
                    schemaname as schema,
                    tablename as table_name,
                    tableowner as table_type,
                    COALESCE(
                        (SELECT reltuples::bigint
                         FROM pg_class
                         WHERE relname = tablename
                         AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = schemaname)
                        ), 0
                    )::text as row_count
                FROM pg_tables
                WHERE 1=1 {system_filter}
                ORDER BY schemaname, tablename;
            "#
        )
    }

    /// Build a query to describe table structure
    pub fn describe_table(table_name: &str) -> String {
        format!(
            r#"
                SELECT
                    column_name,
                    data_type,
                    is_nullable,
                    COALESCE(column_default, '') as default_value,
                    CASE
                        WHEN column_name IN (
                            SELECT a.attname
                            FROM pg_index i
                            JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
                            WHERE i.indrelid = '{table_name}'::regclass AND i.indisprimary
                        ) THEN 'YES'
                        ELSE 'NO'
                    END as is_primary
                FROM information_schema.columns
                WHERE table_name = '{table_name}'
                ORDER BY ordinal_position;
            "#,
            table_name = table_name.replace("'", "''")
        )
    }

    /// Build a CREATE DATABASE query
    pub fn create_database(name: &str, owner: Option<&str>, encoding: &str) -> String {
        let mut query = format!("CREATE DATABASE \"{}\"", name.replace("\"", "\"\""));

        if let Some(owner) = owner {
            query.push_str(&format!(" OWNER \"{}\"", owner.replace("\"", "\"\"")));
        }

        query.push_str(&format!(" ENCODING '{}'", encoding.replace("'", "''")));
        query
    }

    /// Build a DROP DATABASE query
    pub fn drop_database(name: &str) -> String {
        format!("DROP DATABASE \"{}\"", name.replace("\"", "\"\""))
    }
}
