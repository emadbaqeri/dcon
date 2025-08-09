use crate::db::client::PostgresClient;
use crate::cli::{OutputFormat, DatabaseCommands, TableCommands, CrudCommands};
use colored::*;
use serde_json::Value;
use std::error::Error;
use std::io::{self, Write};
use tabled::Table;

pub async fn execute_connect(
    client: &PostgresClient,
    format: &OutputFormat,
) -> Result<(), Box<dyn Error>> {
    println!("{}", "📡 Connection Information:".bright_green().bold());

    let conn_info = client.get_connection_info().await?;

    match format {
        OutputFormat::Table => {
            let table = Table::new(&conn_info);
            println!("{}", table);
        }
        OutputFormat::Json => {
            let json = serde_json::to_string_pretty(&conn_info)?;
            println!("{}", json);
        }
        OutputFormat::Csv => {
            println!("Property,Value");
            for info in conn_info {
                println!("{},{}", info.property, info.value);
            }
        }
    }

    Ok(())
}

pub async fn execute_database_command(
    client: &PostgresClient,
    command: &DatabaseCommands,
    format: &OutputFormat,
) -> Result<(), Box<dyn Error>> {
    match command {
        DatabaseCommands::List => {
            println!("{}", "🗄️ Available Databases:".bright_green().bold());

            let databases = client.list_databases().await?;

            match format {
                OutputFormat::Table => {
                    let table = Table::new(&databases);
                    println!("{}", table);
                }
                OutputFormat::Json => {
                    let json = serde_json::to_string_pretty(&databases)?;
                    println!("{}", json);
                }
                OutputFormat::Csv => {
                    println!("Database Name,Owner,Encoding,Size,Description");
                    for db in databases {
                        println!(
                            "{},{},{},{},{}",
                            db.name, db.owner, db.encoding, db.size, db.description
                        );
                    }
                }
            }
        }

        DatabaseCommands::Create {
            name,
            owner,
            encoding,
        } => {
            if !confirm_action(&format!("Create database '{}'?", name))? {
                println!("{}", "Operation cancelled.".yellow());
                return Ok(());
            }

            client
                .create_database(name, owner.as_deref(), encoding)
                .await?;
            println!(
                "{}",
                format!("✅ Database '{}' created successfully!", name).green()
            );
        }

        DatabaseCommands::Drop { name, confirm } => {
            if !confirm
                || !confirm_action(&format!("Drop database '{}'? This cannot be undone!", name))?
            {
                println!("{}", "Operation cancelled.".yellow());
                return Ok(());
            }

            client.drop_database(name).await?;
            println!(
                "{}",
                format!("✅ Database '{}' dropped successfully!", name).green()
            );
        }

        DatabaseCommands::Info { name: _ } => {
            // This would show detailed database information
            execute_connect(client, format).await?;
        }
    }

    Ok(())
}

pub async fn execute_table_command(
    client: &PostgresClient,
    command: &TableCommands,
    format: &OutputFormat,
) -> Result<(), Box<dyn Error>> {
    match command {
        TableCommands::List {
            database: _,
            system,
        } => {
            println!("{}", "📋 Tables:".bright_green().bold());

            let tables = client.list_tables(*system).await?;

            match format {
                OutputFormat::Table => {
                    let table = Table::new(&tables);
                    println!("{}", table);
                }
                OutputFormat::Json => {
                    let json = serde_json::to_string_pretty(&tables)?;
                    println!("{}", json);
                }
                OutputFormat::Csv => {
                    println!("Schema,Table Name,Type,Row Count");
                    for table in tables {
                        println!(
                            "{},{},{},{}",
                            table.schema, table.table_name, table.table_type, table.row_count
                        );
                    }
                }
            }
        }

        TableCommands::Describe { table, database: _ } => {
            println!(
                "{}",
                format!("🔍 Table Structure: {}", table)
                    .bright_green()
                    .bold()
            );

            let columns = client.describe_table(table, None).await?;

            match format {
                OutputFormat::Table => {
                    let table = Table::new(&columns);
                    println!("{}", table);
                }
                OutputFormat::Json => {
                    let json = serde_json::to_string_pretty(&columns)?;
                    println!("{}", json);
                }
                OutputFormat::Csv => {
                    println!("Column Name,Data Type,Nullable,Default,Primary Key");
                    for col in columns {
                        println!(
                            "{},{},{},{},{}",
                            col.column_name,
                            col.data_type,
                            col.is_nullable,
                            col.default_value,
                            col.is_primary
                        );
                    }
                }
            }
        }

        TableCommands::Create { sql, database: _ } => {
            if !confirm_action("Execute CREATE TABLE statement?")? {
                println!("{}", "Operation cancelled.".yellow());
                return Ok(());
            }

            client.execute_query(sql).await?;
            println!("{}", "✅ Table created successfully!".green());
        }

        TableCommands::Drop {
            table,
            database: _,
            confirm,
        } => {
            if !confirm
                || !confirm_action(&format!("Drop table '{}'? This cannot be undone!", table))?
            {
                println!("{}", "Operation cancelled.".yellow());
                return Ok(());
            }

            client.drop_table(table).await?;
            println!(
                "{}",
                format!("✅ Table '{}' dropped successfully!", table).green()
            );
        }
    }

    Ok(())
}

pub async fn execute_crud_command(
    client: &PostgresClient,
    command: &CrudCommands,
    format: &OutputFormat,
) -> Result<(), Box<dyn Error>> {
    match command {
        CrudCommands::Create {
            table,
            data,
            database: _,
        } => {
            let json_data: Value =
                serde_json::from_str(data).map_err(|e| format!("Invalid JSON data: {}", e))?;

            let rows_affected = client.insert_data(table, &json_data).await?;
            println!(
                "{}",
                format!(
                    "✅ Inserted {} row(s) into table '{}'",
                    rows_affected, table
                )
                .green()
            );
        }

        CrudCommands::Read {
            table,
            filter,
            columns,
            limit,
            offset,
            order,
            database: _,
        } => {
            println!(
                "{}",
                format!("📖 Reading from table '{}'", table)
                    .bright_green()
                    .bold()
            );

            let rows = client
                .select_data(
                    table,
                    columns.as_deref(),
                    filter.as_deref(),
                    order.as_deref(),
                    *limit,
                    *offset,
                )
                .await?;

            if rows.is_empty() {
                println!("{}", "No data found.".yellow());
                return Ok(());
            }

            // Display results based on format
            match format {
                OutputFormat::Table => {
                    display_rows_as_table(&rows);
                }
                OutputFormat::Json => {
                    let json_rows = rows_to_json(&rows)?;
                    println!("{}", serde_json::to_string_pretty(&json_rows)?);
                }
                OutputFormat::Csv => {
                    display_rows_as_csv(&rows);
                }
            }
        }

        CrudCommands::Update {
            table,
            data,
            filter,
            database: _,
            confirm,
        } => {
            let json_data: Value =
                serde_json::from_str(data).map_err(|e| format!("Invalid JSON data: {}", e))?;

            if !confirm || !confirm_action(&format!("Update table '{}' WHERE {}?", table, filter))?
            {
                println!("{}", "Operation cancelled.".yellow());
                return Ok(());
            }

            let rows_affected = client.update_data(table, &json_data, filter).await?;
            println!(
                "{}",
                format!("✅ Updated {} row(s) in table '{}'", rows_affected, table).green()
            );
        }

        CrudCommands::Delete {
            table,
            filter,
            database: _,
            confirm,
        } => {
            if !confirm
                || !confirm_action(&format!("Delete from table '{}' WHERE {}?", table, filter))?
            {
                println!("{}", "Operation cancelled.".yellow());
                return Ok(());
            }

            let rows_affected = client.delete_data(table, filter).await?;
            println!(
                "{}",
                format!("✅ Deleted {} row(s) from table '{}'", rows_affected, table).green()
            );
        }
    }

    Ok(())
}

pub async fn execute_query(
    client: &PostgresClient,
    sql: &str,
    format: &OutputFormat,
) -> Result<(), Box<dyn Error>> {
    println!("{}", "🔧 Executing custom query...".bright_green().bold());

    let rows = client.execute_query(sql).await?;

    if rows.is_empty() {
        println!(
            "{}",
            "Query executed successfully. No rows returned.".green()
        );
        return Ok(());
    }

    match format {
        OutputFormat::Table => {
            display_rows_as_table(&rows);
        }
        OutputFormat::Json => {
            let json_rows = rows_to_json(&rows)?;
            println!("{}", serde_json::to_string_pretty(&json_rows)?);
        }
        OutputFormat::Csv => {
            display_rows_as_csv(&rows);
        }
    }

    Ok(())
}

pub async fn execute_interactive_mode(client: &PostgresClient) -> Result<(), Box<dyn Error>> {
    println!(
        "{}",
        "🎯 Entering interactive mode. Type 'help' for commands, 'exit' to quit."
            .bright_green()
            .bold()
    );

    loop {
        print!("postgres> ");
        io::stdout().flush()?;

        let mut input = String::new();
        io::stdin().read_line(&mut input)?;
        let input = input.trim();

        if input.is_empty() {
            continue;
        }

        match input.to_lowercase().as_str() {
            "exit" | "quit" | "\\q" => {
                println!("{}", "👋 Goodbye!".bright_green());
                break;
            }
            "help" | "\\h" => {
                print_interactive_help();
            }
            "\\l" => {
                // List databases
                let databases = client.list_databases().await?;
                let table = Table::new(&databases);
                println!("{}", table);
            }
            "\\d" => {
                // List tables
                let tables = client.list_tables(false).await?;
                let table = Table::new(&tables);
                println!("{}", table);
            }
            _ => {
                // Execute as SQL
                match client.execute_query(input).await {
                    Ok(rows) => {
                        if rows.is_empty() {
                            println!("{}", "Query executed successfully.".green());
                        } else {
                            display_rows_as_table(&rows);
                        }
                    }
                    Err(e) => {
                        println!("{}", format!("Error: {}", e).red());
                    }
                }
            }
        }
    }

    Ok(())
}

fn confirm_action(message: &str) -> Result<bool, Box<dyn Error>> {
    print!("{} (y/N): ", message);
    io::stdout().flush()?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;

    Ok(input.trim().to_lowercase() == "y" || input.trim().to_lowercase() == "yes")
}

fn print_interactive_help() {
    println!("{}", "Available commands:".bright_cyan().bold());
    println!("  {}  List databases", "\\l".bright_yellow());
    println!("  {}  List tables", "\\d".bright_yellow());
    println!("  {}  Show help", "\\h".bright_yellow());
    println!("  {}  Exit", "\\q".bright_yellow());
    println!("  {}  Execute any SQL query", "SQL".bright_yellow());
    println!();
    println!("Examples:");
    println!("  SELECT * FROM users LIMIT 5;");
    println!("  INSERT INTO users (name, email) VALUES ('John', 'john@example.com');");
    println!("  UPDATE users SET name = 'Jane' WHERE id = 1;");
}

use tokio_postgres::Row;

fn display_rows_as_table(rows: &[Row]) {
    if rows.is_empty() {
        return;
    }

    // Get column names
    let columns: Vec<String> = rows[0]
        .columns()
        .iter()
        .map(|col| col.name().to_string())
        .collect();

    // Print header
    println!("{}", columns.join(" | ").bright_blue().bold());
    println!("{}", "-".repeat(columns.len() * 15).dimmed());

    // Print rows
    for row in rows {
        let mut values = Vec::new();
        for (i, _col) in columns.iter().enumerate() {
            let value = get_column_value(row, i);
            values.push(value);
        }
        println!("{}", values.join(" | "));
    }

    println!();
    println!("{}", format!("({} rows)", rows.len()).dimmed());
}

fn display_rows_as_csv(rows: &[Row]) {
    if rows.is_empty() {
        return;
    }

    // Get column names
    let columns: Vec<String> = rows[0]
        .columns()
        .iter()
        .map(|col| col.name().to_string())
        .collect();

    // Print header
    println!("{}", columns.join(","));

    // Print rows
    for row in rows {
        let mut values = Vec::new();
        for (i, _col) in columns.iter().enumerate() {
            let value = get_column_value(row, i);
            values.push(format!("\"{}\"", value.replace("\"", "\"\"")));
        }
        println!("{}", values.join(","));
    }
}

fn rows_to_json(rows: &[Row]) -> Result<Value, Box<dyn Error>> {
    let mut json_rows = Vec::new();

    for row in rows {
        let mut json_row = serde_json::Map::new();

        for (i, column) in row.columns().iter().enumerate() {
            let value = get_column_value(row, i);
            json_row.insert(column.name().to_string(), Value::String(value));
        }

        json_rows.push(Value::Object(json_row));
    }

    Ok(Value::Array(json_rows))
}

fn get_column_value(row: &Row, index: usize) -> String {
    PostgresClient::get_column_value(row, index)
}
