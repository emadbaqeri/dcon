use gpui::*;
use crate::state::{AppState, ConnectionState};

pub struct StatusBar {
    state: Entity<AppState>,
}

#[derive(Clone, Debug, PartialEq)]
pub enum StatusBarEvent {}

impl EventEmitter<StatusBarEvent> for StatusBar {}

impl StatusBar {
    pub fn new(state: Entity<AppState>) -> Self {
        Self { state }
    }

    fn render_connection_status(&self, cx: &mut Context<Self>) -> impl IntoElement {
        let state = self.state.read(cx);
        let connection_state = state.connection_state();

        let (status_text, status_color) = match connection_state {
            ConnectionState::Disconnected => ("Disconnected", rgb(0xdc3545)),
            ConnectionState::Connecting => ("Connecting...", rgb(0xffc107)),
            ConnectionState::Connected => ("Connected", rgb(0x28a745)),
            ConnectionState::Error(_) => ("Something Went Wrong!", rgb(0xdc3545)),
        };

        div()
            .flex()
            .items_center()
            .gap_2()
            .child(
                div()
                    .w(px(8.0))
                    .h(px(8.0))
                    .bg(status_color)
                    .rounded_full()
            )
            .child(
                div()
                    .text_sm()
                    .text_color(rgb(0xffffff))
                    .child(status_text)
            )
    }

    fn render_database_info(&self, cx: &mut Context<Self>) -> impl IntoElement {
        let state = self.state.read(cx);
        
        if let Some(client) = state.client() {
            let config = client.config();
            div()
                .flex()
                .items_center()
                .gap_2()
                .child(
                    div()
                        .text_sm()
                        .text_color(rgb(0xcccccc))
                        .child(format!("{}@{}:{}/{}", 
                            config.user, 
                            config.host, 
                            config.port, 
                            config.database
                        ))
                )
        } else {
            div()
                .text_sm()
                .text_color(rgb(0x999999))
                .child("No connection")
        }
    }

    fn render_status_message(&self, cx: &mut Context<Self>) -> impl IntoElement {
        let state = self.state.read(cx);

        div()
            .flex()
            .items_center()
            .child(
                div()
                    .text_sm()
                    .text_color(rgb(0xffffff))
                    .child(state.status_message().to_string())
            )
    }
}

impl Render for StatusBar {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .flex()
            .items_center()
            .justify_between()
            .w_full()
            .h(px(28.0))
            .bg(rgb(0x007acc))
            .px_4()
            .py_1()
            .border_t_1()
            .border_color(rgb(0x3e3e42))
            .child(
                // Left section - connection status and database info
                div()
                    .flex()
                    .items_center()
                    .gap_4()
                    .child(self.render_connection_status(cx))
                    .child(self.render_database_info(cx))
            )
            .child(
                // Right section - status message
                div()
                    .flex()
                    .items_center()
                    .child(self.render_status_message(cx))
            )
    }
}
