use std::sync::Arc;
use dcon_core::{PostgresClient, DatabaseInfo, TableInfo};
use serde_json::Value;

#[derive(Debug, Clone, PartialEq)]
pub enum ConnectionState {
    Disconnected,
    Connecting,
    Connected,
    Error(String),
}

#[derive(Debug, Clone, PartialEq)]
pub enum ViewState {
    Connection,
    Databases,
    Tables,
    Query,
}

pub struct AppState {
    // Connection state
    client: Option<Arc<PostgresClient>>,
    connection_state: ConnectionState,
    
    // Data state
    databases: Vec<DatabaseInfo>,
    tables: Vec<TableInfo>,
    selected_database: Option<String>,
    selected_table: Option<String>,
    
    // Query state
    current_query: String,
    query_results: Option<Vec<Value>>,
    query_executing: bool,
    
    // UI state
    current_view: ViewState,
    status_message: String,
    
    // Connection form state
    connection_host: String,
    connection_port: String,
    connection_user: String,
    connection_password: String,
    connection_database: String,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            client: None,
            connection_state: ConnectionState::Disconnected,
            databases: Vec::new(),
            tables: Vec::new(),
            selected_database: None,
            selected_table: None,
            current_query: String::new(),
            query_results: None,
            query_executing: false,
            current_view: ViewState::Connection,
            status_message: "Ready".to_string(),
            connection_host: "localhost".to_string(),
            connection_port: "5432".to_string(),
            connection_user: "postgres".to_string(),
            connection_password: String::new(),
            connection_database: "postgres".to_string(),
        }
    }

    // Connection state getters/setters
    pub fn client(&self) -> Option<&Arc<PostgresClient>> {
        self.client.as_ref()
    }

    pub fn set_client(&mut self, client: Option<Arc<PostgresClient>>) {
        self.client = client;
    }

    pub fn connection_state(&self) -> &ConnectionState {
        &self.connection_state
    }

    pub fn set_connection_state(&mut self, state: ConnectionState) {
        self.connection_state = state;
    }

    pub fn is_connected(&self) -> bool {
        matches!(self.connection_state, ConnectionState::Connected)
    }

    // Data state getters/setters
    pub fn databases(&self) -> &[DatabaseInfo] {
        &self.databases
    }

    pub fn set_databases(&mut self, databases: Vec<DatabaseInfo>) {
        self.databases = databases;
    }

    pub fn tables(&self) -> &[TableInfo] {
        &self.tables
    }

    pub fn set_tables(&mut self, tables: Vec<TableInfo>) {
        self.tables = tables;
    }

    pub fn selected_database(&self) -> Option<&str> {
        self.selected_database.as_deref()
    }

    pub fn set_selected_database(&mut self, database: Option<String>) {
        self.selected_database = database;
    }

    pub fn selected_table(&self) -> Option<&str> {
        self.selected_table.as_deref()
    }

    pub fn set_selected_table(&mut self, table: Option<String>) {
        self.selected_table = table;
    }

    // Query state getters/setters
    pub fn current_query(&self) -> &str {
        &self.current_query
    }

    pub fn set_current_query(&mut self, query: String) {
        self.current_query = query;
    }

    pub fn query_results(&self) -> Option<&[Value]> {
        self.query_results.as_deref()
    }

    pub fn set_query_results(&mut self, results: Option<Vec<Value>>) {
        self.query_results = results;
    }

    pub fn is_query_executing(&self) -> bool {
        self.query_executing
    }

    pub fn set_query_executing(&mut self, executing: bool) {
        self.query_executing = executing;
    }

    // UI state getters/setters
    pub fn current_view(&self) -> &ViewState {
        &self.current_view
    }

    pub fn set_current_view(&mut self, view: ViewState) {
        self.current_view = view;
    }

    pub fn status_message(&self) -> &str {
        &self.status_message
    }

    pub fn set_status_message(&mut self, message: String) {
        self.status_message = message;
    }

    // Connection form getters/setters
    pub fn connection_host(&self) -> &str {
        &self.connection_host
    }

    pub fn set_connection_host(&mut self, host: String) {
        self.connection_host = host;
    }

    pub fn connection_port(&self) -> &str {
        &self.connection_port
    }

    pub fn set_connection_port(&mut self, port: String) {
        self.connection_port = port;
    }

    pub fn connection_user(&self) -> &str {
        &self.connection_user
    }

    pub fn set_connection_user(&mut self, user: String) {
        self.connection_user = user;
    }

    pub fn connection_password(&self) -> &str {
        &self.connection_password
    }

    pub fn set_connection_password(&mut self, password: String) {
        self.connection_password = password;
    }

    pub fn connection_database(&self) -> &str {
        &self.connection_database
    }

    pub fn set_connection_database(&mut self, database: String) {
        self.connection_database = database;
    }

    // Helper methods
    pub fn get_connection_config(&self) -> Result<dcon_core::ConnectionConfig, String> {
        let port = self.connection_port.parse::<u16>()
            .map_err(|_| "Invalid port number".to_string())?;

        Ok(dcon_core::ConnectionConfig::new(
            self.connection_host.clone(),
            port,
            self.connection_user.clone(),
            if self.connection_password.is_empty() {
                None
            } else {
                Some(self.connection_password.clone())
            },
            self.connection_database.clone(),
        ))
    }
}
