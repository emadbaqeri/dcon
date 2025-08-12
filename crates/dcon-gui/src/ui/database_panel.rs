use crate::state::{AppState, ConnectionState};
use gpui::prelude::FluentBuilder;
use gpui::prelude::*;
use gpui::*;

pub struct DatabasePanel {
    state: Entity<AppState>,
}

#[derive(Clone, Debug, PartialEq)]
pub enum DatabasePanelEvent {
    RefreshDatabases,
    RefreshTables,
    SelectDatabase(String),
    SelectTable(String),
}

impl EventEmitter<DatabasePanelEvent> for DatabasePanel {}

impl DatabasePanel {
    pub fn new(state: Entity<AppState>) -> Self {
        Self { state }
    }

    fn render_database_list(&self, cx: &mut Context<Self>) -> impl IntoElement {
        let state = self.state.read(cx);
        let databases = state.databases();
        let is_connected = matches!(state.connection_state(), ConnectionState::Connected);

        div()
            .flex()
            .flex_col()
            .gap_2()
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
                            .child("Databases"),
                    )
                    .child(
                        div()
                            .w(px(20.0))
                            .h(px(20.0))
                            .bg(rgb(0x007acc))
                            .hover(|style| style.bg(rgb(0x0056b3)))
                            .rounded_sm()
                            .flex()
                            .items_center()
                            .justify_center()
                            .text_xs()
                            .text_color(rgb(0xffffff))
                            .cursor_pointer()
                            .when(!is_connected, |div| div.bg(rgb(0x6c757d)).cursor_default())
                            .on_mouse_down(
                                MouseButton::Left,
                                cx.listener(move |this, _event, _window, cx| {
                                    let current_state = this.state.read(cx);
                                    let current_is_connected = matches!(
                                        current_state.connection_state(),
                                        ConnectionState::Connected
                                    );
                                    if current_is_connected {
                                        cx.emit(DatabasePanelEvent::RefreshDatabases);
                                    }
                                }),
                            )
                            .child("↻"),
                    ),
            )
            .child(
                div()
                    .flex()
                    .flex_col()
                    .gap_1()
                    .max_h(px(200.0))
                    .children(databases.iter().map(|db| {
                        let db_name = db.name.clone();
                        div()
                            .flex()
                            .items_center()
                            .p_2()
                            .rounded_sm()
                            .hover(|style| style.bg(rgb(0x3e3e42)))
                            .cursor_pointer()
                            .text_sm()
                            .text_color(rgb(0xffffff))
                            .on_mouse_down(
                                MouseButton::Left,
                                cx.listener(move |_this, _event, _window, cx| {
                                    cx.emit(DatabasePanelEvent::SelectDatabase(db_name.clone()));
                                }),
                            )
                            .child(
                                div()
                                    .flex()
                                    .items_center()
                                    .gap_2()
                                    .child("🗄")
                                    .child(db.name.clone()),
                            )
                    })),
            )
    }

    fn render_table_list(&self, cx: &mut Context<Self>) -> impl IntoElement {
        let state = self.state.read(cx);
        let tables = state.tables();
        let is_connected = matches!(state.connection_state(), ConnectionState::Connected);

        div()
            .flex()
            .flex_col()
            .gap_2()
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
                            .child("Tables"),
                    )
                    .child(
                        div()
                            .w(px(20.0))
                            .h(px(20.0))
                            .bg(rgb(0x007acc))
                            .hover(|style| style.bg(rgb(0x0056b3)))
                            .rounded_sm()
                            .flex()
                            .items_center()
                            .justify_center()
                            .text_xs()
                            .text_color(rgb(0xffffff))
                            .cursor_pointer()
                            .when(!is_connected, |div| div.bg(rgb(0x6c757d)).cursor_default())
                            .on_mouse_down(
                                MouseButton::Left,
                                cx.listener(move |this, _event, _window, cx| {
                                    let current_state = this.state.read(cx);
                                    let current_is_connected = matches!(
                                        current_state.connection_state(),
                                        ConnectionState::Connected
                                    );
                                    if current_is_connected {
                                        cx.emit(DatabasePanelEvent::RefreshTables);
                                    }
                                }),
                            )
                            .child("↻"),
                    ),
            )
            .child(
                div()
                    .flex()
                    .flex_col()
                    .gap_1()
                    .max_h(px(300.0))
                    .children(tables.iter().map(|table| {
                        let table_name = format!("{}.{}", table.schema, table.table_name);
                        div()
                            .flex()
                            .items_center()
                            .p_2()
                            .rounded_sm()
                            .hover(|style| style.bg(rgb(0x3e3e42)))
                            .cursor_pointer()
                            .text_sm()
                            .text_color(rgb(0xffffff))
                            .child(
                                div()
                                    .id("some_id")
                                    .bg(red())
                                    .text_color(white())
                                    .h_6()
                                    .child("Click Here")
                                    .on_click(cx.listener(move |_this, _event, _window, cx| {
                                        cx.emit(DatabasePanelEvent::SelectTable(
                                            table_name.clone(),
                                        ));
                                    })),
                            )
                            .child(
                                div()
                                    .flex()
                                    .items_center()
                                    .gap_2()
                                    .child("📋")
                                    .child(format!("{}.{}", table.schema, table.table_name)),
                            )
                    })),
            )
    }
}

impl Render for DatabasePanel {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .flex()
            .flex_col()
            .bg(rgb(0x252526))
            .p_4()
            .gap_4()
            .child(self.render_database_list(cx))
            .child(self.render_table_list(cx))
    }
}
