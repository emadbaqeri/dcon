use dcon_core::{ConnectionConfig, DatabaseOperations, PostgresClient};
use futures::FutureExt;
use gpui::*;
use std::sync::Arc;

use crate::state::{AppState, ConnectionState};
use crate::ui::{ConnectionPanel, DatabasePanel, QueryPanel, StatusBar};

pub struct DconApp {
    state: Entity<AppState>,
    connection_panel: Entity<ConnectionPanel>,
    database_panel: Entity<DatabasePanel>,
    query_panel: Entity<QueryPanel>,
    status_bar: Entity<StatusBar>,
}

#[derive(Clone, Debug, PartialEq)]
pub enum DconAppEvent {}

impl EventEmitter<DconAppEvent> for DconApp {}

impl DconApp {
    pub fn new(cx: &mut Context<Self>) -> Self {
        let state = cx.new(|_cx| AppState::new());

        let connection_panel = cx.new(|_cx| ConnectionPanel::new(state.clone()));
        let database_panel = cx.new(|_cx| DatabasePanel::new(state.clone()));
        let query_panel = cx.new(|_cx| QueryPanel::new(state.clone()));
        let status_bar = cx.new(|_cx| StatusBar::new(state.clone()));

        Self {
            state,
            connection_panel,
            database_panel,
            query_panel,
            status_bar,
        }
    }

    pub fn connect_to_database(&mut self, config: ConnectionConfig, cx: &mut Context<Self>) {

        cx.spawn(async move |dcon, cx| {
            dcon.update(cx, |dcon, cx| {
                dcon.state.update(cx, |dcon_state, cx| {
                    dcon_state.set_connection_state(ConnectionState::Connecting);
                    cx.notify();
                })
            }).ok();

            match PostgresClient::new(&config).await {
                Ok(client) => {
                    dcon.update(cx, |dcon, cx| {
                        dcon.state.update(cx, |dcon_state, cx| {
                            dcon_state.set_client(Some(Arc::new(client)));
                            dcon_state.set_connection_state(ConnectionState::Connected);
                            dcon_state.set_status_message(format!("Connected Successfully"));
                            cx.notify();
                        })
                    })
                },
                Err(e) => {
                    dcon.update(cx, |dcon, cx| {
                        dcon.state.update(cx, |dcon_state, cx| {
                            dcon_state.set_connection_state(ConnectionState::Disconnected);
                            dcon_state.set_status_message(format!("Connection Failed! {}", e));
                            cx.notify();
                        })
                    })
                }
            }
        }).detach();
    }

    pub fn disconnect(&mut self, cx: &mut Context<Self>) {

        self.state.update(cx, |state, cx| {
            state.set_client(None);
            state.set_connection_state(ConnectionState::Disconnected);
            state.set_status_message("Disconnected".to_string());
            cx.notify();
        });
    }

    // pub fn refresh_databases(&mut self, cx: &mut Context<Self>) {

    //     let client = self.state.read(cx).clone().client();
    //     cx.spawn(async move |dcon, cx| {
    //         if let Some(client) = client {
    //             match client.list_databases().await {
    //                 Ok(databases) => {
    //                     dcon.update(cx, |dcon, cx|{
    //                         dcon.state.update(cx, |dcon_state, cx| {
    //                         dcon_state.set_databases(databases);
    //                         dcon_state.set_status_message("Databases refreshed".to_string());
    //                         cx.notify()
    //                         })
    //                     }).ok();
    //                 }
    //                 Err(e) => {
    //                     dcon.update(cx, |dcon, cx| {
    //                         dcon.state.update(cx, |dcon_state, cx| {
    //                         dcon_state.set_status_message(format!("Failed to refresh databases: {}", e));
    //                         cx.notify();
    //                         })
    //                     }).ok();
    //                 }
    //             }
    //         }
    //     })
    //     .detach();
    // }

    // pub fn refresh_tables(&mut self, cx: &mut Context<Self>) {
    //     let state = self.state.clone();

    //     cx.spawn(|_, mut cx| async move {
    //         let client = state
    //             .read_with(cx, |state, _cx| state.client().cloned())
    //             .ok()
    //             .flatten();

    //         if let Some(client) = client {
    //             match client.list_tables(false).await {
    //                 Ok(tables) => {
    //                     let _ = state.update(cx, |state, cx| {
    //                         state.set_tables(tables);
    //                         state.set_status_message("Tables refreshed".to_string());
    //                         cx.notify();
    //                     });
    //                 }
    //                 Err(e) => {
    //                     let _ = state.update(cx, |state, cx| {
    //                         state.set_status_message(format!("Failed to refresh tables: {}", e));
    //                         cx.notify();
    //                     });
    //                 }
    //             }
    //         }
    //     })
    //     .detach();
    // }

    // pub fn execute_query(&mut self, sql: String, cx: &mut Context<Self>) {
    //     let state = self.state.clone();

    //     cx.spawn(|_, mut cx| async move {
    //         let client = state
    //             .read_with(cx, |state, _cx| state.client().cloned())
    //             .ok()
    //             .flatten();

    //         if let Some(client) = client {
    //             let _ = state.update(cx, |state, cx| {
    //                 state.set_query_executing(true);
    //                 state.set_status_message("Executing query...".to_string());
    //                 cx.notify();
    //             });

    //             match client.execute_query_json(&sql).await {
    //                 Ok(results) => {
    //                     let _ = state.update(cx, |state, cx| {
    //                         state.set_query_results(Some(results));
    //                         state.set_query_executing(false);
    //                         state.set_status_message("Query executed successfully".to_string());
    //                         cx.notify();
    //                     });
    //                 }
    //                 Err(e) => {
    //                     let _ = state.update(cx, |state, cx| {
    //                         state.set_query_executing(false);
    //                         state.set_status_message(format!("Query failed: {}", e));
    //                         cx.notify();
    //                     });
    //                 }
    //             }
    //         }
    //     })
    //     .detach();
    // }
}

impl Render for DconApp {
    fn render(&mut self, _window: &mut Window, _cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .flex()
            .flex_col()
            .size_full()
            .bg(rgb(0x1e1e1e))
            .text_color(rgb(0xffffff))
            .child(
                // Main content area
                div()
                    .flex()
                    .flex_row()
                    .flex_1()
                    .child(
                        // Left sidebar
                        div()
                            .flex()
                            .flex_col()
                            .w(px(300.0))
                            .bg(rgb(0x252526))
                            .border_r_1()
                            .border_color(rgb(0x3e3e42))
                            .child(self.connection_panel.clone())
                            .child(self.database_panel.clone()),
                    )
                    .child(
                        // Main content area
                        div()
                            .flex()
                            .flex_col()
                            .flex_1()
                            .child(self.query_panel.clone()),
                    ),
            )
            .child(self.status_bar.clone())
    }
}
