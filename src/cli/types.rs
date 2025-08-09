use clap::{Parser, Subcommand};

#[derive(Clone, Parser)]
pub enum OutputFormat {
    Table,
    Json,
    Csv,
}

impl std::fmt::Display for OutputFormat {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OutputFormat::Table => write!(f, "table"),
            OutputFormat::Json => write!(f, "json"),
            OutputFormat::Csv => write!(f, "csv"),
        }
    }
}

impl std::str::FromStr for OutputFormat {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "table" => Ok(OutputFormat::Table),
            "json" => Ok(OutputFormat::Json),
            "csv" => Ok(OutputFormat::Csv),
            _ => Err(format!("Invalid output format: {s}")),
        }
    }
}

#[derive(Subcommand)]
pub enum Commands {
    /// Connect to PostgreSQL and show connection info
    Connect,

    /// Database Operations
    #[command(subcommand)]
    Database(DatabaseCommands),

    /// Table Operations
    #[command(subcommand)]
    Table(TableCommands),

    /// CRUD Operations
    #[command(subcommand)]
    Crud(CrudCommands),

    /// Execute a Custom SQL Query
    Query {
        /// SQL Query to Execute
        #[arg(short, long)]
        sql: String,

        /// Target Database (overrides global database)
        #[arg(short, long)]
        database: Option<String>,
    },

    /// Interactive Mode
    Interactive {
        /// Target Database
        #[arg(short, long)]
        database: Option<String>,
    },
}

#[derive(Subcommand)]
pub enum DatabaseCommands {
    /// List all databases
    List,

    /// Create a new Database
    Create {
        /// Database name
        #[arg(short, long)]
        name: String,

        /// Database owner
        #[arg(short, long)]
        owner: Option<String>,

        /// Database Encoding
        #[arg(short, long, default_value = "UTF8")]
        encoding: String,
    },

    /// Drop a database
    Drop {
        /// Database name
        #[arg(short, long)]
        name: String,

        /// Skip confirmation prompt
        #[arg(long)]
        confirm: bool,
    },

    /// Show database Information
    Info {
        /// Database name (uses current if not specified)
        #[arg(short, long)]
        name: Option<String>,
    },
}

#[derive(Subcommand)]
pub enum TableCommands {
    /// List all tables in database
    List {
        /// Target Database (overrides global database)
        #[arg(short, long)]
        database: Option<String>,

        /// Include system tables
        #[arg(long)]
        system: bool,
    },

    /// Describe table structure
    Describe {
        /// Table name
        #[arg(short, long)]
        table: String,

        /// Target Database (overrides global database)
        #[arg(short, long)]
        database: Option<String>,
    },

    /// Create a new table
    Create {
        /// SQL CREATE TABLE statement
        #[arg(short, long)]
        sql: String,

        /// Target Database (overrides global database)
        #[arg(short, long)]
        database: Option<String>,
    },

    Drop {
        /// Table name
        #[arg(long, short)]
        table: String,

        /// Target Database (overrides global database)
        #[arg(short, long)]
        database: Option<String>,

        /// Skip confirmation prompt
        #[arg(long)]
        confirm: bool,
    },
}

#[derive(Subcommand)]
pub enum CrudCommands {
    /// Create/Insert Data
    Create {
        /// Table name
        #[arg(short, long)]
        table: String,

        /// JSON data to insert
        #[arg(short, long)]
        data: String,

        /// Target Database (overrides global database)
        #[arg(short, long)]
        database: Option<String>,
    },

    /// Read/Select Data
    Read {
        /// Table name
        #[arg(short, long)]
        table: String,

        /// WHERE clause filter
        #[arg(short, long)]
        filter: Option<String>,

        /// Columns to select (comma-separated)
        #[arg(short, long)]
        columns: Option<String>,

        /// Limit number of rows
        #[arg(short, long)]
        limit: Option<i64>,

        /// Offset for pagination
        #[arg(short, long)]
        offset: Option<i64>,

        /// ORDER BY clause
        #[arg(short = 'o', long)]
        order: Option<String>,

        /// Target Database (overrides global database)
        #[arg(short, long)]
        database: Option<String>,
    },

    /// Update data
    Update {
        /// Table name
        #[arg(short, long)]
        table: String,

        /// JSON data with new values
        #[arg(short, long)]
        data: String,

        /// WHERE clause (required for safety)
        #[arg(short, long)]
        filter: String,

        /// Target Database (overrides global database)
        #[arg(short, long)]
        database: Option<String>,

        /// Skip confirmation prompt
        #[arg(long)]
        confirm: bool,
    },

    /// Delete Data
    Delete {
        /// Table name
        #[arg(short, long)]
        table: String,

        /// WHERE clause (required for safety)
        #[arg(short, long)]
        filter: String,

        /// Target Database (overrides global database)
        #[arg(short, long)]
        database: Option<String>,

        /// Skip confirmation prompt
        #[arg(long)]
        confirm: bool,
    },
}
