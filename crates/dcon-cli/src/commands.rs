use crate::cli::{CrudCommands, DatabaseCommands, OutputFormat, TableCommands};
use crate::output::{display_rows_as_table, print_interactive_help};
use colored::*;
use dcon_core::{DatabaseOperations, PostgresClient};
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
            println!("{table}");
        }
        OutputFormat::Json => {
            let json = serde_json::to_string_pretty(&conn_info)?;
            println!("{json}");
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
                    println!("{table}");
                }
                OutputFormat::Json => {
                    let json = serde_json::to_string_pretty(&databases)?;
                    println!("{json}");
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

        DatabaseCommands::Create { name, owner, encoding } => {
            println!(
                "{}",
                format!("🏗️ Creating database '{name}'...").bright_blue()
            );

            client.create_database(name, owner.as_deref(), encoding).await?;

            println!(
                "{}",
                format!("✅ Database '{name}' created successfully!").green()
            );
        }

        DatabaseCommands::Drop { name, confirm } => {
            if !confirm {
                print!("Are you sure you want to drop database '{name}'? (y/N): ");
                io::stdout().flush()?;
                let mut input = String::new();
                io::stdin().read_line(&mut input)?;
                if !input.trim().to_lowercase().starts_with('y') {
                    println!("{}", "❌ Operation cancelled.".yellow());
                    return Ok(());
                }
            }

            println!(
                "{}",
                format!("🗑️ Dropping database '{name}'...").bright_red()
            );

            client.drop_database(name).await?;

            println!(
                "{}",
                format!("✅ Database '{name}' dropped successfully!").green()
            );
        }

        DatabaseCommands::Info { name } => {
            let db_info = client.get_database_info(name.as_deref()).await?;
            
            println!("{}", "ℹ️ Database Information:".bright_cyan().bold());
            
            match format {
                OutputFormat::Table => {
                    let table = Table::new(&[db_info]);
                    println!("{table}");
                }
                OutputFormat::Json => {
                    let json = serde_json::to_string_pretty(&db_info)?;
                    println!("{json}");
                }
                OutputFormat::Csv => {
                    println!("Database Name,Owner,Encoding,Size,Description");
                    println!(
                        "{},{},{},{},{}",
                        db_info.name, db_info.owner, db_info.encoding, db_info.size, db_info.description
                    );
                }
            }
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
        TableCommands::List { system, .. } => {
            println!("{}", "📋 Available Tables:".bright_green().bold());

            let tables = client.list_tables(*system).await?;

            match format {
                OutputFormat::Table => {
                    let table = Table::new(&tables);
                    println!("{table}");
                }
                OutputFormat::Json => {
                    let json = serde_json::to_string_pretty(&tables)?;
                    println!("{json}");
                }
                OutputFormat::Csv => {
                    println!("Schema,Table Name,Table Type,Row Count");
                    for table in tables {
                        println!(
                            "{},{},{},{}",
                            table.schema, table.table_name, table.table_type, table.row_count
                        );
                    }
                }
            }
        }

        TableCommands::Describe { table, .. } => {
            println!(
                "{}",
                format!("🔍 Table Structure for '{table}':").bright_cyan().bold()
            );

            let columns = client.describe_table(table).await?;

            match format {
                OutputFormat::Table => {
                    let table = Table::new(&columns);
                    println!("{table}");
                }
                OutputFormat::Json => {
                    let json = serde_json::to_string_pretty(&columns)?;
                    println!("{json}");
                }
                OutputFormat::Csv => {
                    println!("Column Name,Data Type,Is Nullable,Default Value,Primary Key");
                    for col in columns {
                        println!(
                            "{},{},{},{},{}",
                            col.column_name, col.data_type, col.is_nullable, col.default_value, col.is_primary
                        );
                    }
                }
            }
        }

        TableCommands::Create { sql, .. } => {
            println!("{}", "🏗️ Creating table...".bright_blue());
            
            let rows = client.execute_query(sql).await?;
            
            if rows.is_empty() {
                println!("{}", "✅ Table created successfully!".green());
            } else {
                display_rows_as_table(&rows);
            }
        }

        TableCommands::Drop { table, .. } => {
            println!(
                "{}",
                format!("🗑️ Dropping table '{table}'...").bright_red()
            );

            let sql = format!("DROP TABLE \"{}\"", table.replace("\"", "\"\""));
            client.execute_query(&sql).await?;

            println!(
                "{}",
                format!("✅ Table '{table}' dropped successfully!").green()
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
    println!("{}", "🔧 Executing query...".cyan());
    
    let rows = client.execute_query(sql).await?;

    if rows.is_empty() {
        println!("{}", "Query executed successfully.".green());
    } else {
        match format {
            OutputFormat::Table => {
                display_rows_as_table(&rows);
            }
            OutputFormat::Json => {
                let json_rows = client.execute_query_json(sql).await?;
                let json = serde_json::to_string_pretty(&json_rows)?;
                println!("{json}");
            }
            OutputFormat::Csv => {
                if let Some(first_row) = rows.first() {
                    // Print headers
                    let headers: Vec<String> = first_row.columns().iter().map(|col| col.name().to_string()).collect();
                    println!("{}", headers.join(","));
                    
                    // Print data rows
                    for row in &rows {
                        let values: Vec<String> = (0..row.len())
                            .map(|i| {
                                // Simple string conversion for CSV
                                row.try_get::<_, Option<String>>(i)
                                    .unwrap_or(None)
                                    .unwrap_or_else(|| "NULL".to_string())
                            })
                            .collect();
                        println!("{}", values.join(","));
                    }
                }
            }
        }
    }

    Ok(())
}

pub async fn execute_crud_command(
    _client: &PostgresClient,
    _command: &CrudCommands,
    _format: &OutputFormat,
) -> Result<(), Box<dyn Error>> {
    // TODO: Implement CRUD operations using the core library
    println!("{}", "CRUD operations not yet implemented in the new architecture".yellow());
    Ok(())
}

pub async fn execute_interactive_mode(client: &PostgresClient) -> Result<(), Box<dyn Error>> {
    println!("{}", "🚀 Interactive Mode - Type 'help' for commands, 'exit' to quit".bright_green().bold());
    print_interactive_help();

    loop {
        print!("dcon> ");
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
                println!("{table}");
            }
            "\\d" => {
                // List tables
                let tables = client.list_tables(false).await?;
                let table = Table::new(&tables);
                println!("{table}");
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
                        println!("{}", format!("Error: {e}").red());
                    }
                }
            }
        }
    }

    Ok(())
}
