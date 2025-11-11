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
    // Print to stderr immediately (before any initialization)
    eprintln!("Starting FKS Main Orchestration Service...");
    
    // Initialize tracing first (before any other operations)
    // Use stderr writer to ensure logs appear in docker logs
    if let Err(e) = tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .with_writer(std::io::stderr)
        .try_init() {
        eprintln!("WARNING: Failed to initialize tracing: {:?}. Continuing anyway.", e);
    }
    
    eprintln!("Tracing initialized");
    
    // Initialize crypto provider for rustls (required for rustls 0.23+)
    if let Err(e) = rustls::crypto::ring::default_provider().install_default() {
        eprintln!("WARNING: Failed to install crypto provider: {:?}. Continuing anyway.", e);
        // Don't fail - rustls might work without this in some cases
    }
    
    eprintln!("Crypto provider initialized");
    info!("Starting FKS Main Orchestration Service");

    // Load configuration
    eprintln!("Loading configuration...");
    let config = match AppConfig::load() {
        Ok(cfg) => {
            eprintln!("Configuration loaded: monitor_url={}, port={}", cfg.monitor_url, cfg.service_port);
            info!("Configuration loaded: monitor_url={}", cfg.monitor_url);
            cfg
        }
        Err(e) => {
            error!("Failed to load configuration: {}", e);
            eprintln!("ERROR: Failed to load configuration: {}", e);
            return Err(e);
        }
    };

    // Extract port before moving config
    let service_port = config.service_port;
    let monitor_url = config.monitor_url.clone();
    eprintln!("Extracted service_port={}, monitor_url={}", service_port, monitor_url);

    // Initialize Kubernetes client
    eprintln!("Initializing Kubernetes client...");
    let k8s_client = match Client::try_default().await {
        Ok(client) => {
            eprintln!("Kubernetes client initialized");
            info!("Kubernetes client initialized");
            Some(client)
        }
        Err(e) => {
            eprintln!("WARNING: Kubernetes client not available: {}. Running in non-K8s mode.", e);
            error!("Failed to initialize Kubernetes client: {}. Running in non-K8s mode.", e);
            None
        }
    };

    // Initialize monitor client
    eprintln!("Initializing monitor client with URL: {}", monitor_url);
    let monitor_client = MonitorClient::new(&monitor_url);
    eprintln!("Monitor client initialized");

    // Initialize app state
    eprintln!("Creating app state...");
    let app_state = AppState {
        config,
        k8s_client,
        monitor_client,
        service_registry: Arc::new(RwLock::new(HashMap::new())),
    };
    eprintln!("App state created");

    // Build router
    eprintln!("Building router...");
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
    eprintln!("Starting server on port {}...", service_port);
    let addr = format!("0.0.0.0:{}", service_port);
    info!("Listening on {}", addr);
    eprintln!("FKS Main service listening on {}", addr);
    
    let listener = match tokio::net::TcpListener::bind(&addr).await {
        Ok(l) => {
            eprintln!("Successfully bound to {}", addr);
            info!("Successfully bound to {}", addr);
            l
        }
        Err(e) => {
            eprintln!("ERROR: Failed to bind to {}: {}", addr, e);
            error!("Failed to bind to {}: {}", addr, e);
            return Err(anyhow::anyhow!("Failed to bind to {}: {}", addr, e));
        }
    };
    
    eprintln!("Server starting...");
    info!("Server starting...");
    eprintln!("FKS Main service is ready and accepting connections");
    eprintln!("Waiting for incoming connections...");
    
    // Use spawn to ensure the server runs
    match axum::serve(listener, app).await {
        Ok(_) => {
            eprintln!("Server stopped normally");
            Ok(())
        }
        Err(e) => {
            eprintln!("ERROR: Server error: {}", e);
            error!("Server error: {}", e);
            Err(anyhow::anyhow!("Server error: {}", e))
        }
    }
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

