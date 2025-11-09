/// FKS Main Orchestration Service
/// Rust-based API for Kubernetes orchestration and service management
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
    routing::{get, post, delete},
    Router,
};
use kube::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tower_http::cors::CorsLayer;
use tracing::{info, error};

mod config;
mod k8s;
mod monitor;

use config::AppConfig;
use monitor::MonitorClient;

#[derive(Clone)]
struct AppState {
    config: AppConfig,
    k8s_client: Option<Client>,
    monitor_client: MonitorClient,
    service_registry: Arc<RwLock<HashMap<String, ServiceInfo>>>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct ServiceInfo {
    name: String,
    namespace: String,
    status: String,
    replicas: u32,
    ready_replicas: u32,
    last_updated: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize crypto provider for rustls (required for rustls 0.23+)
    rustls::crypto::ring::default_provider()
        .install_default()
        .map_err(|e| anyhow::anyhow!("Failed to install crypto provider: {:?}", e))?;
    
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    info!("Starting FKS Main Orchestration Service");

    // Load configuration
    let config = AppConfig::load()?;
    info!("Configuration loaded: monitor_url={}", config.monitor_url);

    // Initialize Kubernetes client
    let k8s_client = match Client::try_default().await {
        Ok(client) => {
            info!("Kubernetes client initialized");
            Some(client)
        }
        Err(e) => {
            error!("Failed to initialize Kubernetes client: {}. Running in non-K8s mode.", e);
            None
        }
    };

    // Initialize monitor client
    let monitor_client = MonitorClient::new(&config.monitor_url);

    // Initialize app state
    let app_state = AppState {
        config,
        k8s_client,
        monitor_client,
        service_registry: Arc::new(RwLock::new(HashMap::new())),
    };

    // Build router
    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health))
        .route("/ready", get(ready))
        .route("/live", get(live))
        .route("/api/v1/services", get(list_services))
        .route("/api/v1/services/{name}", get(get_service))
        .route("/api/v1/services/{name}/scale", post(scale_service))
        .route("/api/v1/services/{name}/restart", post(restart_service))
        .route("/api/v1/summary", get(get_summary))
        .route("/api/v1/k8s/pods", get(list_pods))
        .route("/api/v1/k8s/deployments", get(list_deployments))
        .layer(CorsLayer::permissive())
        .with_state(app_state);

    // Start server
    let addr = "0.0.0.0:8010";
    info!("Listening on {}", addr);
    
    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn root() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "service": "fks_main",
        "version": "1.0.0",
        "status": "operational",
        "description": "FKS Main Orchestration Service - K8s control and service management"
    }))
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "fks_main"
    }))
}

async fn ready(State(state): State<AppState>) -> Json<serde_json::Value> {
    // Check if monitor is reachable
    let monitor_ready = state.monitor_client.check_health().await.is_ok();
    
    Json(serde_json::json!({
        "status": if monitor_ready { "ready" } else { "not_ready" },
        "service": "fks_main",
        "monitor_connected": monitor_ready
    }))
}

async fn live() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "alive",
        "service": "fks_main"
    }))
}

async fn list_services(State(state): State<AppState>) -> Json<serde_json::Value> {
    // Get services from monitor
    match state.monitor_client.get_all_services().await {
        Ok(services) => {
            let count = if let Some(arr) = services.as_array() {
                arr.len()
            } else if let Some(obj) = services.as_object() {
                obj.len()
            } else {
                0
            };
            Json(serde_json::json!({
                "services": services,
                "count": count
            }))
        },
        Err(e) => {
            error!("Error fetching services from monitor: {}", e);
            Json(serde_json::json!({
                "error": format!("Failed to fetch services: {}", e),
                "services": []
            }))
        }
    }
}

async fn get_service(
    Path(name): Path<String>,
    State(state): State<AppState>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    match state.monitor_client.get_service(&name).await {
        Ok(service) => Ok(Json(serde_json::json!(service))),
        Err(_) => Err(StatusCode::NOT_FOUND),
    }
}

async fn scale_service(
    Path(name): Path<String>,
    State(state): State<AppState>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    // This would use k8s client to scale deployments
    // For now, return a placeholder
    Ok(Json(serde_json::json!({
        "status": "scaling",
        "service": name,
        "message": "Scale operation queued"
    })))
}

async fn restart_service(
    Path(name): Path<String>,
    State(state): State<AppState>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    // This would use k8s client to restart deployments
    Ok(Json(serde_json::json!({
        "status": "restarting",
        "service": name,
        "message": "Restart operation queued"
    })))
}

async fn get_summary(State(state): State<AppState>) -> Json<serde_json::Value> {
    match state.monitor_client.get_summary().await {
        Ok(summary) => Json(serde_json::json!(summary)),
        Err(e) => {
            error!("Error fetching summary: {}", e);
            Json(serde_json::json!({
                "error": format!("Failed to fetch summary: {}", e)
            }))
        }
    }
}

async fn list_pods(State(state): State<AppState>) -> Json<serde_json::Value> {
    // This would list K8s pods
    if state.k8s_client.is_none() {
        return Json(serde_json::json!({
            "error": "Kubernetes client not available",
            "pods": []
        }));
    }
    
    Json(serde_json::json!({
        "pods": [],
        "message": "K8s integration coming soon"
    }))
}

async fn list_deployments(State(state): State<AppState>) -> Json<serde_json::Value> {
    // This would list K8s deployments
    if state.k8s_client.is_none() {
        return Json(serde_json::json!({
            "error": "Kubernetes client not available",
            "deployments": []
        }));
    }
    
    Json(serde_json::json!({
        "deployments": [],
        "message": "K8s integration coming soon"
    }))
}

