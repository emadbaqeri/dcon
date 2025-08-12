use std::error::Error;

use clap::Parser;
use colored::*;
use dcon_core::{ConnectionConfig, PostgresClient};

mod cli;
mod commands;
mod output;

use cli::{Commands, OutputFormat};

use crate::{
    cli::{CrudCommands, TableCommands},
    commands::{
        execute_connect, execute_crud_command, execute_database_command,
        execute_interactive_mode, execute_query, execute_table_command,
    },
};

#[derive(Parser)]
#[command(name = "dcon")]
#[command(about = "A PostgreSQL CLI Tool for Database Operations")]
#[command(version = env!("CARGO_PKG_VERSION"))]
pub struct Cli {
    /// Database Host
    #[arg(short = 'H', long, default_value = "localhost")]
    pub host: String,

    /// Database Port
    #[arg(short = 'P', long, default_value = "5432")]
    pub port: u16,

    /// Username
    #[arg(short, long, default_value = "postgres")]
    pub user: String,

    /// Password (will prompt if not provided)
    #[arg(long)]
    pub password: Option<String>,

    /// Database Name
    #[arg(short, long, default_value = "postgres")]
    pub database: String,

    /// Full connection URL (overrides other connection options)
    #[arg(long)]
    pub url: Option<String>,

    /// Output format
    #[arg(long, default_value = "table")]
    pub format: OutputFormat,

    /// Disable colored output
    #[arg(long)]
    pub no_color: bool,

    #[command(subcommand)]
    pub command: Commands,
}

fn print_banner() {
    println!(
        "{}",
        r#"
╔══════════════════════════════════════════════════════════════╗
║                  🐘 PostgreSQL CLI Tool                     ║
║                     Database Management                     ║
╚══════════════════════════════════════════════════════════════╝
    "#
        .bright_magenta()
    );
}

fn get_connection_config(cli: &Cli) -> Result<ConnectionConfig, Box<dyn Error>> {
    if let Some(url) = &cli.url {
        ConnectionConfig::from_url(url).map_err(|e| e.into())
    } else {
        let password = if let Some(pwd) = &cli.password {
            Some(pwd.clone())
        } else {
            // In a real implementation, you'd use a secure password prompt here
            // For now, we'll use a default or prompt
            use std::io::{self, Write};
            print!("Enter password: ");
            io::stdout().flush()?;
            let mut password = String::new();
            io::stdin().read_line(&mut password)?;
            let password = password.trim().to_string();
            if password.is_empty() {
                None
            } else {
                Some(password)
            }
        };

        Ok(ConnectionConfig::new(
            cli.host.clone(),
            cli.port,
            cli.user.clone(),
            password,
            cli.database.clone(),
        ))
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let cli = Cli::parse();

    if !cli.no_color {
        print_banner();
    }

    let config = get_connection_config(&cli)?;

    match &cli.command {
        Commands::Connect => {
            let client = PostgresClient::new(&config).await?;
            execute_connect(&client, &cli.format).await?;
        }

        Commands::Database(db_cmd) => {
            let client = PostgresClient::new(&config).await?;
            execute_database_command(&client, db_cmd, &cli.format).await?;
        }

        Commands::Table(table_cmd) => {
            let mut target_config = config.clone();
            if let Some(db_name) = get_database_from_table_command(table_cmd) {
                target_config.database = db_name;
            }
            let client = PostgresClient::new(&target_config).await?;
            execute_table_command(&client, table_cmd, &cli.format).await?;
        }

        Commands::Crud(crud_cmd) => {
            let mut target_config = config.clone();
            if let Some(db_name) = get_database_from_crud_command(crud_cmd) {
                target_config.database = db_name;
            }
            let client = PostgresClient::new(&target_config).await?;
            execute_crud_command(&client, crud_cmd, &cli.format).await?;
        }

        Commands::Query { sql, database } => {
            let mut target_config = config.clone();
            if let Some(db_name) = database {
                target_config.database.clone_from(db_name);
            }
            let client = PostgresClient::new(&target_config).await?;
            execute_query(&client, sql, &cli.format).await?;
        }

        Commands::Interactive { database } => {
            let mut target_config = config.clone();
            if let Some(db_name) = database {
                target_config.database.clone_from(db_name);
            }
            let client = PostgresClient::new(&target_config).await?;
            execute_interactive_mode(&client).await?;
        }
    }

    Ok(())
}

// Helper functions to extract database names from commands
fn get_database_from_table_command(cmd: &TableCommands) -> Option<String> {
    match cmd {
        TableCommands::List { database, .. }
        | TableCommands::Describe { database, .. }
        | TableCommands::Create { database, .. }
        | TableCommands::Drop { database, .. } => database.clone(),
    }
}

fn get_database_from_crud_command(cmd: &CrudCommands) -> Option<String> {
    match cmd {
        CrudCommands::Create { database, .. }
        | CrudCommands::Read { database, .. }
        | CrudCommands::Update { database, .. }
        | CrudCommands::Delete { database, .. } => database.clone(),
    }
}
