use colored::*;

use tokio_postgres::Row;

/// Display database query results as a formatted table
pub fn display_rows_as_table(rows: &[Row]) {
    if rows.is_empty() {
        println!("{}", "No results found.".yellow());
        return;
    }

    // Create a simple table structure for display
    let first_row = &rows[0];
    let headers: Vec<String> = first_row.columns().iter().map(|col| col.name().to_string()).collect();
    
    // Convert rows to string vectors for table display
    let mut table_data = Vec::new();
    table_data.push(headers.clone()); // Add headers as first row
    
    for row in rows {
        let row_data: Vec<String> = (0..row.len())
            .map(|i| get_column_value(row, i))
            .collect();
        table_data.push(row_data);
    }
    
    // Create a simple table display
    println!();
    
    // Print headers
    let header_line = headers.join(" | ");
    println!("{}", header_line.bright_cyan().bold());
    println!("{}", "-".repeat(header_line.len()).bright_black());
    
    // Print data rows
    for row in rows {
        let row_values: Vec<String> = (0..row.len())
            .map(|i| get_column_value(row, i))
            .collect();
        println!("{}", row_values.join(" | "));
    }
    
    println!();
    println!("{}", format!("({} rows)", rows.len()).bright_black());
}

/// Extract column value from a PostgreSQL row and convert to string
pub fn get_column_value(row: &Row, index: usize) -> String {
    // Try to get the value as different types and convert to string
    if let Ok(val) = row.try_get::<_, Option<String>>(index) {
        val.unwrap_or_else(|| "NULL".to_string())
    } else if let Ok(val) = row.try_get::<_, Option<i64>>(index) {
        val.map(|v| v.to_string())
            .unwrap_or_else(|| "NULL".to_string())
    } else if let Ok(val) = row.try_get::<_, Option<i32>>(index) {
        val.map(|v| v.to_string())
            .unwrap_or_else(|| "NULL".to_string())
    } else if let Ok(val) = row.try_get::<_, Option<f64>>(index) {
        val.map(|v| v.to_string())
            .unwrap_or_else(|| "NULL".to_string())
    } else if let Ok(val) = row.try_get::<_, Option<f32>>(index) {
        val.map(|v| v.to_string())
            .unwrap_or_else(|| "NULL".to_string())
    } else if let Ok(val) = row.try_get::<_, Option<bool>>(index) {
        val.map(|v| v.to_string())
            .unwrap_or_else(|| "NULL".to_string())
    } else if let Ok(val) = row.try_get::<_, Option<chrono::NaiveDateTime>>(index) {
        val.map(|v| v.format("%Y-%m-%d %H:%M:%S").to_string())
            .unwrap_or_else(|| "NULL".to_string())
    } else if let Ok(val) = row.try_get::<_, Option<chrono::NaiveDate>>(index) {
        val.map(|v| v.format("%Y-%m-%d").to_string())
            .unwrap_or_else(|| "NULL".to_string())
    } else {
        "Unknown Type".to_string()
    }
}

/// Print help information for interactive mode
pub fn print_interactive_help() {
    println!();
    println!("{}", "📚 Interactive Commands:".bright_cyan().bold());
    println!("  {}  - List all databases", "\\l".bright_yellow());
    println!("  {}  - List all tables in current database", "\\d".bright_yellow());
    println!("  {}  - Show this help message", "\\h or help".bright_yellow());
    println!("  {}  - Exit interactive mode", "\\q, quit, or exit".bright_yellow());
    println!();
    println!("{}", "💡 You can also execute any SQL query directly.".bright_blue());
    println!("{}", "   Example: SELECT * FROM users LIMIT 5;".dimmed());
    println!();
}


