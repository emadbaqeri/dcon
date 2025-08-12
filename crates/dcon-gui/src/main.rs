use gpui::*;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod app;
mod state;
mod ui;

use app::DconApp;

fn main() {
    // Initialize tracing for logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "dcon_gui=debug,info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    tracing::info!("Starting dcon GUI application");

    // Create and run the GPUI application
    Application::new().run(|app: &mut App| {
        // Set up window options with proper title and size
        let window_options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds {
                origin: Point {
                    x: px(100.0),
                    y: px(100.0),
                },
                size: Size {
                    width: px(1200.0),
                    height: px(800.0),
                },
            })),
            titlebar: Some(TitlebarOptions {
                title: Some("dcon - PostgreSQL Database Manager".into()),
                appears_transparent: false,
                traffic_light_position: None,
            }),
            window_min_size: Some(Size {
                width: px(800.0),
                height: px(600.0),
            }),
            kind: WindowKind::Normal,
            is_movable: true,
            display_id: None,
            focus: true,
            show: true,
            window_background: WindowBackgroundAppearance::default(),
            app_id: None,
            window_decorations: Some(WindowDecorations::Server),
        };

        // Open the main application window
        app.open_window(window_options, |_window, app| {
            app.new(|cx| DconApp::new(cx))
        })
        .unwrap_or_else(|err| {
            tracing::error!("Failed to open application window: {}", err);
            panic!("Failed to open application window: {}", err);
        });

        tracing::info!("dcon GUI application window opened successfully");
    });
}
