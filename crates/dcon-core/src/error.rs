use thiserror::Error;

/// Result type alias for dcon operations
pub type Result<T> = std::result::Result<T, DconError>;

/// Main error type for dcon operations
#[derive(Error, Debug)]
pub enum DconError {
    #[error("Database connection failed: {0}")]
    ConnectionFailed(String),

    #[error("Authentication failed: {0}")]
    AuthenticationFailed(String),

    #[error("Query execution failed: {0}")]
    QueryFailed(String),

    #[error("Database operation failed: {0}")]
    DatabaseOperationFailed(String),

    #[error("Table operation failed: {0}")]
    TableOperationFailed(String),

    #[error("Invalid connection configuration: {0}")]
    InvalidConfiguration(String),

    #[error("Network error: {0}")]
    NetworkError(String),

    #[error("Timeout error: {0}")]
    TimeoutError(String),

    #[error("Serialization error: {0}")]
    SerializationError(#[from] serde_json::Error),

    #[error("URL parsing error: {0}")]
    UrlParseError(#[from] url::ParseError),

    #[error("PostgreSQL error: {0}")]
    PostgresError(#[from] tokio_postgres::Error),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Unknown error: {0}")]
    Unknown(String),
}

impl DconError {
    /// Create a new connection failed error
    pub fn connection_failed<S: Into<String>>(msg: S) -> Self {
        Self::ConnectionFailed(msg.into())
    }

    /// Create a new query failed error
    pub fn query_failed<S: Into<String>>(msg: S) -> Self {
        Self::QueryFailed(msg.into())
    }

    /// Create a new database operation failed error
    pub fn database_operation_failed<S: Into<String>>(msg: S) -> Self {
        Self::DatabaseOperationFailed(msg.into())
    }

    /// Create a new table operation failed error
    pub fn table_operation_failed<S: Into<String>>(msg: S) -> Self {
        Self::TableOperationFailed(msg.into())
    }
}
