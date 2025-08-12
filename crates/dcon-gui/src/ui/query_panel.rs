use crate::state::{AppState, ConnectionState};
use gpui::prelude::FluentBuilder;
use gpui::*;

pub struct QueryPanel {
    state: Entity<AppState>,
    query_text: String,
}

#[derive(Clone, Debug, PartialEq)]
pub enum QueryPanelEvent {
    ExecuteQuery(String),
}

impl EventEmitter<QueryPanelEvent> for QueryPanel {}

impl QueryPanel {
    pub fn new(state: Entity<AppState>) -> Self {
        Self {
            state,
            query_text: "SELECT * FROM information_schema.tables LIMIT 10;".to_string(),
        }
    }

    fn render_query_editor(&self, cx: &mut Context<Self>) -> impl IntoElement {
        let state = self.state.read(cx);
        let is_connected = matches!(state.connection_state(), ConnectionState::Connected);

        div()
            .flex()
            .flex_col()
            .gap_3()
            .child(
                div()
                    .flex()
                    .items_center()
                    .justify_between()
                    .child(
                        div()
                            .text_sm()
                            .font_weight(FontWeight::BOLD)
                            .text_color(rgb(0xcccccc))
                            .child("SQL Query"),
                    )
                    .child(
                        div()
                            .px_3()
                            .py_1()
                            .bg(rgb(0x007acc))
                            .hover(|style| style.bg(rgb(0x0056b3)))
                            .rounded_md()
                            .text_sm()
                            .font_weight(FontWeight::MEDIUM)
                            .text_color(rgb(0xffffff))
                            .cursor_pointer()
                            .when(!is_connected || state.is_query_executing(), |div| {
                                div.bg(rgb(0x6c757d)).cursor_default()
                            })
                            .child(
                                div()
                                    .id("some_id")
                                    .bg(red())
                                    .text_color(white())
                                    .h_6()
                                    .child("Click Here")
                                    .on_click(cx.listener(move |this, _event, _window, cx| {
                                        // Check the state fresh within the closure to avoid lifetime issues
                                        let current_state = this.state.read(cx);
                                        let current_is_connected = matches!(current_state.connection_state(), ConnectionState::Connected);
                                        
                                        if current_is_connected && !current_state.is_query_executing() {
                                            cx.emit(QueryPanelEvent::ExecuteQuery(
                                                this.query_text.clone(),
                                            ));
                                        }
                                    })),
                            )
                            .child(if state.is_query_executing() {
                                "Executing..."
                            } else {
                                "Execute"
                            }),
                    ),
            )
            .child(
                // Query text area (simplified as a div for now)
                div()
                    .w_full()
                    .h(px(150.0))
                    .bg(rgb(0x1e1e1e))
                    .border_1()
                    .border_color(rgb(0x5a5a5a))
                    .rounded_md()
                    .p_3()
                    .text_sm()
                    .font_family("Monaco, 'Courier New', monospace")
                    .text_color(rgb(0xffffff))
                    .child(self.query_text.clone()),
            )
    }

    fn render_results(&self, cx: &mut Context<Self>) -> impl IntoElement {
        let state = self.state.read(cx);
        let results = state.query_results();

        div()
            .flex()
            .flex_col()
            .gap_3()
            .child(
                div()
                    .text_sm()
                    .font_weight(FontWeight::BOLD)
                    .text_color(rgb(0xcccccc))
                    .child("Results"),
            )
            .child(
                div()
                    .w_full()
                    .flex_1()
                    .bg(rgb(0x1e1e1e))
                    .border_1()
                    .border_color(rgb(0x5a5a5a))
                    .rounded_md()
                    .p_3()
                    .child(if let Some(results) = results {
                        div()
                            .text_sm()
                            .font_family("Monaco, 'Courier New', monospace")
                            .text_color(rgb(0xffffff))
                            .child(if results.is_empty() {
                                "No results".to_string()
                            } else {
                                // Format JSON results
                                serde_json::to_string_pretty(results)
                                    .unwrap_or_else(|_| "Error formatting results".to_string())
                            })
                    } else {
                        div()
                            .text_sm()
                            .text_color(rgb(0x999999))
                            .child("Execute a query to see results here")
                    }),
            )
    }
}

impl Render for QueryPanel {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .flex()
            .flex_col()
            .bg(rgb(0x1e1e1e))
            .p_4()
            .gap_4()
            .size_full()
            .child(
                // Query editor section
                div().flex().flex_col().child(self.render_query_editor(cx)),
            )
            .child(
                // Results section
                div()
                    .flex()
                    .flex_col()
                    .flex_1()
                    .child(self.render_results(cx)),
            )
    }
}