use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "cli-table", derive(tabled::Tabled))]
pub struct DatabaseInfo {
    #[cfg_attr(feature = "cli-table", tabled(rename = "Database Name"))]
    pub name: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Owner"))]
    pub owner: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Encoding"))]
    pub encoding: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Size"))]
    pub size: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Description"))]
    pub description: String,
}

impl DatabaseInfo {
    pub fn new(
        name: String,
        owner: String,
        encoding: String,
        size: String,
        description: String,
    ) -> Self {
        Self {
            name,
            owner,
            encoding,
            size,
            description,
        }
    }
}
