use std::error::Error;

use clap::Parser;
use colored::*;
use url::Url;

mod cli;
mod db;
mod models;

use cli::{Commands, OutputFormat};
use models::connection::ConnectionConfig;

use crate::{
    cli::{
        commands::{
            execute_connect, execute_crud_command, execute_database_command,
            execute_interactive_mode, execute_query, execute_table_command,
        },
        CrudCommands, TableCommands,
    },
    db::client::PostgresClient,
};

#[derive(Parser)]
#[command(name = "pgres_cli")]
#[command(about = "A PostgreSQL CLI Tool for Database Operations")]
#[command(version = "0.0.1")]
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

fn parse_connection_url(url: &str) -> Result<ConnectionConfig, Box<dyn std::error::Error>> {
    let parsed_url = Url::parse(url).unwrap();

    if parsed_url.scheme() != "postgresql" && parsed_url.scheme() != "postgres" {
        return Err("URL must use postgresql:// or postgres:// scheme".into());
    }

    let host = parsed_url.host_str().unwrap_or("localhost").to_string();
    let port = parsed_url.port().unwrap_or(5432);
    let user = if parsed_url.username().is_empty() {
        "postgres".to_string()
    } else {
        parsed_url.username().to_string()
    };
    let password = parsed_url.password().map(std::string::ToString::to_string);
    let database = parsed_url.path().trim_start_matches('/');
    let database = if database.is_empty() {
        "postgres".to_string()
    } else {
        database.to_string()
    };

    Ok(ConnectionConfig {
        host,
        port,
        user,
        password,
        database,
    })
}

fn get_connection_config(cli: &Cli) -> Result<ConnectionConfig, Box<dyn Error>> {
    if let Some(url) = &cli.url {
        parse_connection_url(url)
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

        Ok(ConnectionConfig {
            host: cli.host.clone(),
            port: cli.port,
            user: cli.user.clone(),
            password,
            database: cli.database.clone(),
        })
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
