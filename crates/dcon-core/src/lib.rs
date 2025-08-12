//! # dcon-core
//! 
//! Core library for dcon providing PostgreSQL database operations, models, and connection management.
//! This library is shared between the CLI and GUI implementations.

pub mod connection;
pub mod database;
pub mod models;
pub mod query;
pub mod error;

// Re-export commonly used types
pub use connection::PostgresClient;
pub use models::{ConnectionConfig, ConnectionInfo, DatabaseInfo, TableInfo, ColumnInfo};
pub use database::DatabaseOperations;
pub use error::{DconError, Result};

/// Version information
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
