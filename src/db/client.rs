use crate::models::connection::{ConnectionConfig, ConnectionInfo};
use crate::models::database::DatabaseInfo;
use crate::models::table::{ColumnInfo, TableInfo};
use chrono::{NaiveDate, NaiveDateTime};
use colored::*;
use serde_json::Value;
use tokio_postgres::{Client, NoTls, Row};

pub struct PostgresClient {
    client: Client,
    config: ConnectionConfig,
}

impl PostgresClient {
    pub async fn new(config: &ConnectionConfig) -> Result<Self, Box<dyn std::error::Error>> {
        let connection_string = config.to_connection_string();

        println!("{}", "🔌 Connecting to PostgreSQL...".cyan());

        let (client, connection) = tokio_postgres::connect(&connection_string, NoTls)
            .await
            .map_err(|e| format!("Failed to connect to PostgreSQL: {e}"))
            .unwrap();

        tokio::spawn(async move {
            if let Err(e) = connection.await {
                eprintln!("Connection Error: {e}");
            }
        });

        println!("{}", "✅ Connected successfully!".green());

        Ok(PostgresClient {
            client,
            config: config.clone(),
        })
    }

    pub async fn get_connection_info(
        &self,
    ) -> Result<Vec<ConnectionInfo>, Box<dyn std::error::Error>> {
        println!("{}", "ℹ️  Fetching connection information...".cyan());
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
                    info.push(ConnectionInfo {
                        property: property.to_string(),
                        value,
                    });
                }
                Err(_) => {
                    info.push(ConnectionInfo {
                        property: property.to_string(),
                        value: "N/A".to_string(),
                    });
                }
            }
        }

        Ok(info)
    }

    pub async fn list_databases(&self) -> Result<Vec<DatabaseInfo>, Box<dyn std::error::Error>> {
        println!("{}", "📊 Fetching database information...".cyan());

        let query = r#"
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
        "#;

        let rows = self.client.query(query, &[]).await.unwrap();
        let databases: Vec<DatabaseInfo> = rows
            .into_iter()
            .map(|row| DatabaseInfo {
                name: row.get("name"),
                owner: row.get("owner"),
                encoding: row.get("encoding"),
                size: row.get("size"),
                description: row.get("description"),
            })
            .collect();

        Ok(databases)
    }

    pub async fn list_tables(
        &self,
        include_system: bool,
    ) -> Result<Vec<TableInfo>, Box<dyn std::error::Error>> {
        println!(
            "{}",
            format!(
                "📋 Fetching tables for database '{}'...",
                self.config.database
            )
            .cyan()
        );

        let table_query = format!(
            r#"
            SELECT
                t.schemaname as schema,
                t.tablename as table_name,
                'table' as table_type
            FROM pg_tables t
            {}
            UNION ALL
            SELECT
                v.schemaname as schema,
                v.viewname as table_name,
                'view' as table_type
            FROM pg_views v
            {}
            ORDER BY schema, table_name;
            "#,
            if include_system {
                ""
            } else {
                "WHERE t.schemaname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')"
            },
            if include_system {
                ""
            } else {
                "WHERE v.schemaname NOT IN ('information_schema', 'pg_catalog')"
            }
        );

        let rows = self.client.query(&table_query, &[]).await.unwrap();

        let mut tables = Vec::new();
        for row in rows {
            let schema: String = row.get("schema");
            let table_name: String = row.get("table_name");
            let table_type: String = row.get("table_type");

            let row_count = if table_type == "table" {
                match self.get_table_row_count(&table_name, Some(&schema)).await {
                    Ok(count) => count.to_string(),
                    Err(_) => "Error".to_string(),
                }
            } else {
                "N/A".to_string()
            };

            tables.push(TableInfo {
                schema,
                table_name,
                table_type,
                row_count,
            });
        }
        Ok(tables)
    }

    pub async fn describe_table(
        &self,
        table_name: &str,
        schema: Option<&str>,
    ) -> Result<Vec<ColumnInfo>, Box<dyn std::error::Error>> {
        let schema = schema.unwrap_or("public");

        println!(
            "{}",
            format!("🔍 Describing table '{schema}.{table_name}'...").cyan()
        );

        let query = r#"
            SELECT
                c.column_name,
                c.data_type,
                c.is_nullable,
                COALESCE(c.column_default, 'NULL') as default_value,
                CASE
                    WHEN pk.column_name IS NOT NULL THEN 'YES'
                    ELSE 'NO'
                END as is_primary
            FROM information_schema.columns c
            LEFT JOIN (
                SELECT ku.column_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage ku
                    ON tc.constraint_name = ku.constraint_name
                    AND tc.table_schema = ku.table_schema
                    AND tc.table_name = ku.table_name
                WHERE tc.constraint_type = 'PRIMARY KEY'
                    AND tc.table_name = $1
                    AND tc.table_schema = $2
            ) pk ON c.column_name = pk.column_name
            WHERE c.table_name = $1
                AND c.table_schema = $2
            ORDER BY c.ordinal_position;
        "#;

        let rows = self.client.query(query, &[&table_name, &schema]).await?;

        let columns: Vec<ColumnInfo> = rows
            .into_iter()
            .map(|row| ColumnInfo {
                column_name: row.get("column_name"),
                data_type: row.get("data_type"),
                is_nullable: row.get("is_nullable"),
                default_value: row.get("default_value"),
                is_primary: row.get("is_primary"),
            })
            .collect();

        Ok(columns)
    }

    pub async fn execute_query(&self, query: &str) -> Result<Vec<Row>, Box<dyn std::error::Error>> {
        println!("{}", "🔧 Executing query...".cyan());
        let rows = self
            .client
            .query(query, &[])
            .await
            .map_err(|e| format!("Query execution failed: {e}"))
            .unwrap();

        Ok(rows)
    }

    pub async fn insert_data(
        &self,
        table_name: &str,
        data: &Value,
    ) -> Result<u64, Box<dyn std::error::Error>> {
        if !data.is_object() {
            return Err("Data must be a JSON object".into());
        }

        let obj = data.as_object().unwrap();
        let columns: Vec<&String> = obj.keys().collect();
        let values: Vec<&Value> = obj.values().collect();

        if columns.is_empty() {
            return Err("No data provided".into());
        }

        let column_list = columns
            .iter()
            .map(|c| format!("\"{}\"", c.replace("\"", "\"\"")))
            .collect::<Vec<_>>()
            .join(", ");

        let placeholders = (1..=values.len())
            .map(|i| format!("${i}"))
            .collect::<Vec<_>>()
            .join(", ");

        let query = format!(
            "INSERT INTO \"{}\" ({}) VALUES ({})",
            table_name.replace("\"", "\"\""),
            column_list,
            placeholders
        );

        // Convert JSON values to strings for postgres compatibility
        let string_values: Vec<String> = values
            .iter()
            .map(|v| match v {
                Value::String(s) => s.clone(),
                Value::Number(n) => n.to_string(),
                Value::Bool(b) => b.to_string(),
                Value::Null => "NULL".to_string(),
                _ => v.to_string().trim_matches('"').to_string(),
            })
            .collect();

        let params: Vec<&(dyn tokio_postgres::types::ToSql + Sync)> = string_values
            .iter()
            .map(|s| s as &(dyn tokio_postgres::types::ToSql + Sync))
            .collect();

        println!("{}", format!("📝 Executing: {query}").dimmed());

        let result = self
            .client
            .execute(&query, &params)
            .await
            .map_err(|e| format!("Insert failed: {e}"))?;

        Ok(result)
    }

    pub async fn update_data(
        &self,
        table_name: &str,
        set_data: &Value,
        where_clause: &str,
    ) -> Result<u64, Box<dyn std::error::Error>> {
        if !set_data.is_object() {
            return Err("Set data must be a JSON object".into());
        }

        let obj = set_data.as_object().unwrap();
        if obj.is_empty() {
            return Err("No update data provided".into());
        }

        let mut set_clauses = Vec::new();
        let mut string_values = Vec::new();
        let mut param_index = 1;

        for (key, value) in obj.iter() {
            set_clauses.push(format!(
                "\"{}\" = ${}",
                key.replace("\"", "\"\""),
                param_index
            ));

            let string_value = match value {
                Value::String(s) => s.clone(),
                Value::Number(n) => n.to_string(),
                Value::Bool(b) => b.to_string(),
                Value::Null => "NULL".to_string(),
                _ => value.to_string().trim_matches('"').to_string(),
            };

            string_values.push(string_value);
            param_index += 1;
        }

        let params: Vec<&(dyn tokio_postgres::types::ToSql + Sync)> = string_values
            .iter()
            .map(|s| s as &(dyn tokio_postgres::types::ToSql + Sync))
            .collect();

        let query = format!(
            "UPDATE \"{}\" SET {} WHERE {}",
            table_name.replace("\"", "\"\""),
            set_clauses.join(", "),
            where_clause
        );

        println!("{}", format!("📝 Executing: {query}").dimmed());

        let result = self
            .client
            .execute(&query, &params)
            .await
            .map_err(|e| format!("Update failed: {e}"))?;

        Ok(result)
    }

    pub async fn delete_data(
        &self,
        table_name: &str,
        where_clause: &str,
    ) -> Result<u64, Box<dyn std::error::Error>> {
        let query = format!(
            "DELETE FROM \"{}\" WHERE {}",
            table_name.replace("\"", "\"\""),
            where_clause
        );

        println!("{}", format!("📝 Executing: {query}").dimmed());

        let result = self
            .client
            .execute(&query, &[])
            .await
            .map_err(|e| format!("Delete failed: {e}"))?;

        Ok(result)
    }

    pub async fn create_database(
        &self,
        name: &str,
        owner: Option<&str>,
        encoding: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let mut query = format!("CREATE DATABASE \"{}\"", name.replace("\"", "\"\""));

        if let Some(owner) = owner {
            query.push_str(&format!(" OWNER \"{}\"", owner.replace("\"", "\"\"")));
        }

        query.push_str(&format!(" ENCODING '{}'", encoding.replace("'", "''")));

        println!("{}", format!("📝 Executing: {query}").dimmed());

        self.client
            .execute(&query, &[])
            .await
            .map_err(|e| format!("Create database failed: {e}"))?;

        Ok(())
    }

    pub async fn drop_database(&self, name: &str) -> Result<(), Box<dyn std::error::Error>> {
        let query = format!("DROP DATABASE \"{}\"", name.replace("\"", "\"\""));

        println!("{}", format!("📝 Executing: {query}").dimmed());

        self.client
            .execute(&query, &[])
            .await
            .map_err(|e| format!("Drop database failed: {e}"))?;

        Ok(())
    }

    pub async fn drop_table(&self, name: &str) -> Result<(), Box<dyn std::error::Error>> {
        let query = format!("DROP TABLE \"{}\"", name.replace("\"", "\"\""));

        println!("{}", format!("📝 Executing: {query}").dimmed());

        self.client
            .execute(&query, &[])
            .await
            .map_err(|e| format!("Drop table failed: {e}"))?;

        Ok(())
    }

    pub async fn select_data(
        &self,
        table_name: &str,
        columns: Option<&str>,
        where_clause: Option<&str>,
        order_by: Option<&str>,
        limit: Option<i64>,
        offset: Option<i64>,
    ) -> Result<Vec<Row>, Box<dyn std::error::Error>> {
        let column_list = columns.unwrap_or("*");
        let mut query = format!(
            "SELECT {} FROM \"{}\"",
            column_list,
            table_name.replace("\"", "\"\"")
        );

        if let Some(where_clause) = where_clause {
            query.push_str(&format!(" WHERE {where_clause}"));
        }

        if let Some(order_by) = order_by {
            query.push_str(&format!(" ORDER BY {order_by}"));
        }

        if let Some(limit) = limit {
            query.push_str(&format!(" LIMIT {limit}"));
        }

        if let Some(offset) = offset {
            query.push_str(&format!(" OFFSET {offset}"));
        }

        println!("{}", format!("📝 Executing: {query}").dimmed());

        let rows = self
            .client
            .query(&query, &[])
            .await
            .map_err(|e| format!("Select failed: {e}"))?;

        Ok(rows)
    }

    pub async fn get_table_row_count(
        &self,
        table_name: &str,
        schema: Option<&str>,
    ) -> Result<i64, Box<dyn std::error::Error>> {
        let schema = schema.unwrap_or("public");
        let query = format!(
            "SELECT COUNT(*) FROM \"{}\".\"{}\"",
            schema.replace("\"", "\"\""),
            table_name.replace("\"", "\"\"")
        );

        let row = self
            .client
            .query_one(&query, &[])
            .await
            .map_err(|e| format!("Failed to get row count: {e}"))?;

        let count: i64 = row.get(0);
        Ok(count)
    }

    pub fn get_column_value(row: &Row, index: usize) -> String {
        // Try to get the value as different types and convert to string
        if let Ok(val) = row.try_get::<_, Option<String>>(index) {
            val.unwrap_or_else(|| "NULL".to_string())
        } else if let Ok(val) = row.try_get::<_, Option<i64>>(index) {
            val.map(|v| v.to_string())
                .unwrap_or_else(|| "NULL".to_string())
        } else if let Ok(val) = row.try_get::<_, Option<i32>>(index) {
            val.map(|v| v.to_string())
                .unwrap_or_else(|| "NULL".to_string())
        } else if let Ok(val) = row.try_get::<_, Option<f64>>(index) {
            val.map(|v| v.to_string())
                .unwrap_or_else(|| "NULL".to_string())
        } else if let Ok(val) = row.try_get::<_, Option<f32>>(index) {
            val.map(|v| v.to_string())
                .unwrap_or_else(|| "NULL".to_string())
        } else if let Ok(val) = row.try_get::<_, Option<bool>>(index) {
            val.map(|v| v.to_string())
                .unwrap_or_else(|| "NULL".to_string())
        } else if let Ok(val) = row.try_get::<_, Option<NaiveDateTime>>(index) {
            val.map(|v| v.format("%Y-%m-%d %H:%M:%S").to_string())
                .unwrap_or_else(|| "NULL".to_string())
        } else if let Ok(val) = row.try_get::<_, Option<NaiveDate>>(index) {
            val.map(|v| v.format("%Y-%m-%d").to_string())
                .unwrap_or_else(|| "NULL".to_string())
        } else {
            "Unknown Type".to_string()
        }
    }
}
