//! Database operations module
//! 
//! This module provides high-level database operations that can be used by both CLI and GUI interfaces.

use crate::models::{DatabaseInfo, TableInfo, ColumnInfo};
use crate::error::{DconError, Result};
use serde_json::Value;
use tokio_postgres::Row;

/// Database operations trait
pub trait DatabaseOperations {
    /// List all databases
    async fn list_databases(&self) -> Result<Vec<DatabaseInfo>>;
    
    /// Create a new database
    async fn create_database(&self, name: &str, owner: Option<&str>, encoding: &str) -> Result<()>;
    
    /// Drop a database
    async fn drop_database(&self, name: &str) -> Result<()>;
    
    /// Get database information
    async fn get_database_info(&self, name: Option<&str>) -> Result<DatabaseInfo>;
    
    /// List tables in the current database
    async fn list_tables(&self, include_system: bool) -> Result<Vec<TableInfo>>;
    
    /// Get table information
    async fn describe_table(&self, table_name: &str) -> Result<Vec<ColumnInfo>>;
    
    /// Execute a custom SQL query
    async fn execute_query(&self, sql: &str) -> Result<Vec<Row>>;
    
    /// Execute a query and return results as JSON
    async fn execute_query_json(&self, sql: &str) -> Result<Vec<Value>>;
}

/// Convert a PostgreSQL row to JSON value
pub fn row_to_json(row: &Row) -> Value {
    let mut map = serde_json::Map::new();
    
    for (i, column) in row.columns().iter().enumerate() {
        let column_name = column.name();
        let value = match column.type_().name() {
            "bool" => row.try_get::<_, Option<bool>>(i)
                .unwrap_or(None)
                .map(Value::Bool)
                .unwrap_or(Value::Null),
            "int2" | "int4" => row.try_get::<_, Option<i32>>(i)
                .unwrap_or(None)
                .map(|v| Value::Number(v.into()))
                .unwrap_or(Value::Null),
            "int8" => row.try_get::<_, Option<i64>>(i)
                .unwrap_or(None)
                .map(|v| Value::Number(v.into()))
                .unwrap_or(Value::Null),
            "float4" => row.try_get::<_, Option<f32>>(i)
                .unwrap_or(None)
                .and_then(|v| serde_json::Number::from_f64(v as f64))
                .map(Value::Number)
                .unwrap_or(Value::Null),
            "float8" => row.try_get::<_, Option<f64>>(i)
                .unwrap_or(None)
                .and_then(|v| serde_json::Number::from_f64(v))
                .map(Value::Number)
                .unwrap_or(Value::Null),
            "text" | "varchar" | "char" | "name" => row.try_get::<_, Option<String>>(i)
                .unwrap_or(None)
                .map(Value::String)
                .unwrap_or(Value::Null),
            "timestamp" | "timestamptz" => row.try_get::<_, Option<chrono::NaiveDateTime>>(i)
                .unwrap_or(None)
                .map(|dt| Value::String(dt.to_string()))
                .unwrap_or(Value::Null),
            "date" => row.try_get::<_, Option<chrono::NaiveDate>>(i)
                .unwrap_or(None)
                .map(|d| Value::String(d.to_string()))
                .unwrap_or(Value::Null),
            "uuid" => {
                // Handle UUID as string since we don't have the FromSql trait implemented
                row.try_get::<_, Option<String>>(i)
                    .unwrap_or(None)
                    .map(Value::String)
                    .unwrap_or(Value::Null)
            },
            _ => {
                // For unknown types, try to get as string
                row.try_get::<_, Option<String>>(i)
                    .unwrap_or(None)
                    .map(Value::String)
                    .unwrap_or(Value::Null)
            }
        };
        
        map.insert(column_name.to_string(), value);
    }
    
    Value::Object(map)
}
