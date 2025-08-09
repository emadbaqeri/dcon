use serde::{Deserialize, Serialize};
use tabled::Tabled;

#[derive(Debug, Tabled, Serialize, Deserialize)]
pub struct DatabaseInfo {
    #[tabled(rename = "Database Name")]
    pub name: String,

    #[tabled(rename = "Owner")]
    pub owner: String,

    #[tabled(rename = "Encoding")]
    pub encoding: String,

    #[tabled(rename = "Size")]
    pub size: String,

    #[tabled(rename = "Description")]
    pub description: String,
}
