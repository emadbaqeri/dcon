use serde::{Deserialize, Serialize};
use tabled::Tabled;

#[derive(Debug, Clone)]
pub struct ConnectionConfig {
    pub host: String,
    pub port: u16,
    pub user: String,
    pub password: Option<String>,
    pub database: String,
}

impl ConnectionConfig {
    pub fn to_connection_string(&self) -> String {
        let mut conn_str = format!(
            "host={} port={} user={} dbname={}",
            self.host, self.port, self.user, self.database
        );

        if let Some(password) = &self.password {
            conn_str.push_str(&format!(" password={}", password));
        }

        conn_str
    }
}

#[derive(Debug, Serialize, Deserialize, Tabled)]
pub struct ConnectionInfo {
    #[tabled(rename = "Property")]
    pub property: String,
    #[tabled(rename = "Value")]
    pub value: String,
}
