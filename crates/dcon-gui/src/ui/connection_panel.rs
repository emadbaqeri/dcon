use gpui::*;
use gpui::prelude::FluentBuilder;
use dcon_core::ConnectionConfig;
use crate::state::{AppState, ConnectionState};

pub struct ConnectionPanel {
    state: Entity<AppState>,
    host: String,
    port: String,
    username: String,
    password: String,
    database: String,
}

#[derive(Clone, Debug, PartialEq)]
pub enum ConnectionPanelEvent {
    Connect(ConnectionConfig),
    Disconnect,
}

impl EventEmitter<ConnectionPanelEvent> for ConnectionPanel {}

impl ConnectionPanel {
    pub fn new(state: Entity<AppState>) -> Self {
        Self {
            state,
            host: "localhost".to_string(),
            port: "5432".to_string(),
            username: "postgres".to_string(),
            password: String::new(),
            database: "postgres".to_string(),
        }
    }

    fn render_connection_form(&self, cx: &mut Context<Self>) -> impl IntoElement {
        let connection_state = self.state.read(cx).connection_state();
        let is_connected = matches!(connection_state, ConnectionState::Connected);
        let is_connecting = matches!(connection_state, ConnectionState::Connecting);

        div()
            .flex()
            .flex_col()
            .p_4()
            .gap_3()
            .child(
                div()
                    .text_sm()
                    .font_weight(FontWeight::BOLD)
                    .text_color(rgb(0xcccccc))
                    .child("Database Connection")
            )
            .child(
                // Host input
                div()
                    .flex()
                    .flex_col()
                    .gap_1()
                    .child(
                        div()
                            .text_xs()
                            .text_color(rgb(0x999999))
                            .child("Host")
                    )
                    .child(
                        div()
                            .w_full()
                            .h(px(28.0))
                            .bg(rgb(0x3c3c3c))
                            .border_1()
                            .border_color(rgb(0x5a5a5a))
                            .rounded_md()
                            .px_2()
                            .py_1()
                            .text_sm()
                            .text_color(rgb(0xffffff))
                            .child(self.host.clone())
                    )
            )
            .child(
                // Connect/Disconnect button
                div()
                    .mt_4()
                    .child(
                        div()
                            .w_full()
                            .h(px(32.0))
                            .bg(if is_connected { rgb(0xdc3545) } else { rgb(0x007acc) })
                            .hover(|style| {
                                style.bg(if is_connected { rgb(0xc82333) } else { rgb(0x0056b3) })
                            })
                            .rounded_md()
                            .flex()
                            .items_center()
                            .justify_center()
                            .text_sm()
                            .font_weight(FontWeight::MEDIUM)
                            .text_color(rgb(0xffffff))
                            .cursor_pointer()
                            .when(is_connecting, |div| {
                                div.bg(rgb(0x6c757d))
                                    .cursor_default()
                            })
                            .on_mouse_down(MouseButton::Left, cx.listener(move |this, _event, _window, cx| {
                                if is_connecting {
                                    return;
                                }

                                if is_connected {
                                    cx.emit(ConnectionPanelEvent::Disconnect);
                                } else {
                                    let config = ConnectionConfig {
                                        host: this.host.clone(),
                                        port: this.port.parse().unwrap_or(5432),
                                        user: this.username.clone(),
                                        password: if this.password.is_empty() { None } else { Some(this.password.clone()) },
                                        database: this.database.clone(),
                                    };
                                    cx.emit(ConnectionPanelEvent::Connect(config));
                                }
                            }))
                            .child(
                                if is_connecting {
                                    "Connecting..."
                                } else if is_connected {
                                    "Disconnect"
                                } else {
                                    "Connect"
                                }
                            )
                    )
            )
    }
}

impl Render for ConnectionPanel {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .flex()
            .flex_col()
            .bg(rgb(0x252526))
            .border_b_1()
            .border_color(rgb(0x3e3e42))
            .child(self.render_connection_form(cx))
    }
}