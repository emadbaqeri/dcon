use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "cli-table", derive(tabled::Tabled))]
pub struct TableInfo {
    #[cfg_attr(feature = "cli-table", tabled(rename = "Schema"))]
    pub schema: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Table Name"))]
    pub table_name: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Table Type"))]
    pub table_type: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Row Count"))]
    pub row_count: String,
}

impl TableInfo {
    pub fn new(
        schema: String,
        table_name: String,
        table_type: String,
        row_count: String,
    ) -> Self {
        Self {
            schema,
            table_name,
            table_type,
            row_count,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "cli-table", derive(tabled::Tabled))]
pub struct ColumnInfo {
    #[cfg_attr(feature = "cli-table", tabled(rename = "Column Name"))]
    pub column_name: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Data Type"))]
    pub data_type: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Is Nullable"))]
    pub is_nullable: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Default Value"))]
    pub default_value: String,
    #[cfg_attr(feature = "cli-table", tabled(rename = "Primary Key"))]
    pub is_primary: String,
}

impl ColumnInfo {
    pub fn new(
        column_name: String,
        data_type: String,
        is_nullable: String,
        default_value: String,
        is_primary: String,
    ) -> Self {
        Self {
            column_name,
            data_type,
            is_nullable,
            default_value,
            is_primary,
        }
    }
}
