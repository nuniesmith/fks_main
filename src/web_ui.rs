/// Simple web UI module for FKS Main
/// Provides a lightweight HTML interface separate from fks_web
use axum::{
    extract::State,
    response::{Html, Json},
    routing::get,
    Router,
};
use serde_json::json;

use crate::AppState;

/// Serve the main dashboard HTML
pub async fn dashboard_html(_state: State<AppState>) -> Html<&'static str> {
    Html(include_str!("static/index.html"))
}

/// Serve the API status JSON
pub async fn api_status(state: State<AppState>) -> Json<serde_json::Value> {
    // Check monitor connection
    let monitor_ready = state.monitor_client.check_health().await.is_ok();
    let k8s_available = state.k8s_client.is_some();
    
    Json(json!({
        "service": "fks_main",
        "status": "operational",
        "monitor_connected": monitor_ready,
        "k8s_available": k8s_available,
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

/// Add web UI routes to the router
pub fn add_web_ui_routes(router: Router<AppState>) -> Router<AppState> {
    router
        .route("/ui", get(dashboard_html))
        .route("/ui/api/status", get(api_status))
}
