use serde::{Deserialize, Serialize};
use crate::error::{DconError, Result};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ConnectionConfig {
    pub host: String,
    pub port: u16,
    pub user: String,
    pub password: Option<String>,
    pub database: String,
}

impl ConnectionConfig {
    /// Create a new connection configuration
    pub fn new(
        host: String,
        port: u16,
        user: String,
        password: Option<String>,
        database: String,
    ) -> Self {
        Self {
            host,
            port,
            user,
            password,
            database,
        }
    }

    /// Convert to PostgreSQL connection string
    pub fn to_connection_string(&self) -> String {
        let mut conn_str = format!(
            "host={} port={} user={} dbname={}",
            self.host, self.port, self.user, self.database
        );

        if let Some(password) = &self.password {
            conn_str.push_str(&format!(" password={password}"));
        }

        conn_str
    }

    /// Parse from connection URL
    pub fn from_url(url: &str) -> Result<Self> {
        let parsed_url = url::Url::parse(url)?;

        if parsed_url.scheme() != "postgresql" && parsed_url.scheme() != "postgres" {
            return Err(DconError::InvalidConfiguration(
                "URL must use postgresql:// or postgres:// scheme".to_string(),
            ));
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

        Ok(Self {
            host,
            port,
            user,
            password,
            database,
        })
    }

    /// Validate the connection configuration
    pub fn validate(&self) -> Result<()> {
        if self.host.is_empty() {
            return Err(DconError::InvalidConfiguration("Host cannot be empty".to_string()));
        }
        if self.user.is_empty() {
            return Err(DconError::InvalidConfiguration("User cannot be empty".to_string()));
        }
        if self.database.is_empty() {
            return Err(DconError::InvalidConfiguration("Database cannot be empty".to_string()));
        }
        Ok(())
    }
}

impl Default for ConnectionConfig {
    fn default() -> Self {
        Self {
            host: "localhost".to_string(),
            port: 5432,
            user: "postgres".to_string(),
            password: None,
            database: "postgres".to_string(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[cfg_attr(feature = "cli-table", derive(tabled::Tabled))]
pub struct ConnectionInfo {
    #[cfg_attr(feature = "cli-table", tabled(rename = "Property"))]
    pub property: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Value"))]
    pub value: String,
}

impl ConnectionInfo {
    pub fn new(property: String, value: String) -> Self {
        Self { property, value }
    }
}
