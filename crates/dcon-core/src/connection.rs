//! PostgreSQL connection and client implementation

use crate::models::{ConnectionConfig, ConnectionInfo, DatabaseInfo, TableInfo, ColumnInfo};
use crate::error::{DconError, Result};
use crate::database::DatabaseOperations;
use crate::query::{QueryBuilder, QueryResult};
use serde_json::Value;
use tokio_postgres::{Client, NoTls, Row};

/// PostgreSQL client for database operations
pub struct PostgresClient {
    client: Client,
    config: ConnectionConfig,
}

impl PostgresClient {
    /// Create a new PostgreSQL client connection
    pub async fn new(config: &ConnectionConfig) -> Result<Self> {
        // Validate configuration first
        config.validate()?;

        let connection_string = config.to_connection_string();

        let (client, connection) = tokio_postgres::connect(&connection_string, NoTls)
            .await
            .map_err(|e| DconError::connection_failed(format!("Failed to connect to PostgreSQL: {e}")))?;

        // Spawn the connection task
        tokio::spawn(async move {
            if let Err(e) = connection.await {
                eprintln!("Connection Error: {e}");
            }
        });

        Ok(PostgresClient {
            client,
            config: config.clone(),
        })
    }

    /// Get the connection configuration
    pub fn config(&self) -> &ConnectionConfig {
        &self.config
    }

    /// Test the connection
    pub async fn test_connection(&self) -> Result<()> {
        self.client.query_one("SELECT 1", &[]).await
            .map_err(|e| DconError::connection_failed(format!("Connection test failed: {e}")))?;
        Ok(())
    }

    /// Get connection information
    pub async fn get_connection_info(&self) -> Result<Vec<ConnectionInfo>> {
        let port = format!("SELECT '{}'", self.config.port);
        let host = format!("SELECT '{}'", self.config.host);

        let queries = vec![
            ("Database", "SELECT current_database()"),
            ("User", "SELECT current_user"),
            ("Version", "SELECT version()"),
            ("Current Schema", "SELECT current_schema()"),
            ("Session User", "SELECT session_user"),
            ("Backend PID", "SELECT pg_backend_pid()::text"),
            ("Connection Host", &host),
            ("Connection Port", &port),
        ];

        let mut info = Vec::new();

        for (property, query) in queries {
            match self.client.query_one(query, &[]).await {
                Ok(row) => {
                    let value: String = row.get(0);
                    info.push(ConnectionInfo::new(property.to_string(), value));
                }
                Err(_) => {
                    info.push(ConnectionInfo::new(property.to_string(), "N/A".to_string()));
                }
            }
        }

        Ok(info)
    }
}

impl DatabaseOperations for PostgresClient {
    /// List all databases
    async fn list_databases(&self) -> Result<Vec<DatabaseInfo>> {
        let query = QueryBuilder::list_databases();
        let rows = self.client.query(query, &[]).await
            .map_err(|e| DconError::query_failed(format!("Failed to list databases: {e}")))?;

        let databases: Vec<DatabaseInfo> = rows
            .into_iter()
            .map(|row| DatabaseInfo::new(
                row.get("name"),
                row.get("owner"),
                row.get("encoding"),
                row.get("size"),
                row.get("description"),
            ))
            .collect();

        Ok(databases)
    }

    /// Create a new database
    async fn create_database(&self, name: &str, owner: Option<&str>, encoding: &str) -> Result<()> {
        let query = QueryBuilder::create_database(name, owner, encoding);
        self.client.execute(&query, &[]).await
            .map_err(|e| DconError::database_operation_failed(format!("Failed to create database: {e}")))?;
        Ok(())
    }

    /// Drop a database
    async fn drop_database(&self, name: &str) -> Result<()> {
        let query = QueryBuilder::drop_database(name);
        self.client.execute(&query, &[]).await
            .map_err(|e| DconError::database_operation_failed(format!("Failed to drop database: {e}")))?;
        Ok(())
    }

    /// Get database information
    async fn get_database_info(&self, name: Option<&str>) -> Result<DatabaseInfo> {
        let db_name = name.unwrap_or(&self.config.database);
        let databases = self.list_databases().await?;

        databases.into_iter()
            .find(|db| db.name == db_name)
            .ok_or_else(|| DconError::database_operation_failed(format!("Database '{}' not found", db_name)))
    }

    /// List tables in the current database
    async fn list_tables(&self, include_system: bool) -> Result<Vec<TableInfo>> {
        let query = QueryBuilder::list_tables(include_system);
        let rows = self.client.query(&query, &[]).await
            .map_err(|e| DconError::query_failed(format!("Failed to list tables: {e}")))?;

        let tables: Vec<TableInfo> = rows
            .into_iter()
            .map(|row| TableInfo::new(
                row.get("schema"),
                row.get("table_name"),
                row.get("table_type"),
                row.get("row_count"),
            ))
            .collect();

        Ok(tables)
    }

    /// Get table information
    async fn describe_table(&self, table_name: &str) -> Result<Vec<ColumnInfo>> {
        let query = QueryBuilder::describe_table(table_name);
        let rows = self.client.query(&query, &[]).await
            .map_err(|e| DconError::table_operation_failed(format!("Failed to describe table: {e}")))?;

        let columns: Vec<ColumnInfo> = rows
            .into_iter()
            .map(|row| ColumnInfo::new(
                row.get("column_name"),
                row.get("data_type"),
                row.get("is_nullable"),
                row.get("default_value"),
                row.get("is_primary"),
            ))
            .collect();

        Ok(columns)
    }

    /// Execute a custom SQL query
    async fn execute_query(&self, sql: &str) -> Result<Vec<Row>> {
        self.client.query(sql, &[]).await
            .map_err(|e| DconError::query_failed(format!("Query execution failed: {e}")))
    }

    /// Execute a query and return results as JSON
    async fn execute_query_json(&self, sql: &str) -> Result<Vec<Value>> {
        let rows = self.execute_query(sql).await?;
        Ok(rows.iter().map(crate::database::row_to_json).collect())
    }
}