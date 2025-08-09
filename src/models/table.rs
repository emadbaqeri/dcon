use serde::{Deserialize, Serialize};
use tabled::Tabled;

#[derive(Debug, Tabled, Serialize, Deserialize)]
pub struct TableInfo {
    #[tabled(rename = "Schema")]
    pub schema: String,

    #[tabled(rename = "Table Name")]
    pub table_name: String,

    #[tabled(rename = "Table Type")]
    pub table_type: String,

    #[tabled(rename = "Row Count")]
    pub row_count: String,
}

#[derive(Debug, Tabled, Serialize, Deserialize)]
pub struct ColumnInfo {
    #[tabled(rename = "Column Name")]
    pub column_name: String,

    #[tabled(rename = "Data Type")]
    pub data_type: String,

    #[tabled(rename = "Is Nullable")]
    pub is_nullable: String,

    #[tabled(rename = "Default Value")]
    pub default_value: String,

    #[tabled(rename = "Primary Key")]
    pub is_primary: String,
}
