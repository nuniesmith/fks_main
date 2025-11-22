/// FKS Main Orchestration Service
/// Rust-based API for Kubernetes orchestration and service management
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use kube::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tower_http::cors::CorsLayer;
use tracing::{info, error, warn};

mod config;
mod k8s;
mod monitor;
mod runsh;

use config::AppConfig;
use monitor::MonitorClient;
use runsh::RunShExecutor;

#[derive(Clone)]
struct AppState {
    #[allow(dead_code)]
    config: AppConfig,
    k8s_client: Option<Client>,
    monitor_client: MonitorClient,
    #[allow(dead_code)]
    service_registry: Arc<RwLock<HashMap<String, ServiceInfo>>>,
    runsh_executor: Option<Arc<RunShExecutor>>,
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
    // Set up panic hook to capture panics
    std::panic::set_hook(Box::new(|panic_info| {
        eprintln!("PANIC: {}", panic_info);
        if let Some(location) = panic_info.location() {
            eprintln!("Location: {}:{}:{}", location.file(), location.line(), location.column());
        }
        if let Some(s) = panic_info.payload().downcast_ref::<&str>() {
            eprintln!("Message: {}", s);
        }
    }));
    
    // Print to stderr immediately (before any initialization)
    // Use std::io::stderr().flush() to ensure output is written
    use std::io::Write;
    let _ = std::io::stderr().write_all(b"Starting FKS Main Orchestration Service...\n");
    let _ = std::io::stderr().flush();
    
    // Initialize tracing first (before any other operations)
    // Use stderr writer to ensure logs appear in docker logs
    if let Err(e) = tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .with_writer(std::io::stderr)
        .try_init() {
        let _ = std::io::stderr().write_all(format!("WARNING: Failed to initialize tracing: {:?}. Continuing anyway.\n", e).as_bytes());
        let _ = std::io::stderr().flush();
    }
    
    let _ = std::io::stderr().write_all(b"Tracing initialized\n");
    let _ = std::io::stderr().flush();
    
    // Initialize crypto provider for rustls (required for rustls 0.23+)
    if let Err(e) = rustls::crypto::ring::default_provider().install_default() {
        let msg = format!("WARNING: Failed to install crypto provider: {:?}. Continuing anyway.\n", e);
        let _ = std::io::stderr().write_all(msg.as_bytes());
        let _ = std::io::stderr().flush();
        // Don't fail - rustls might work without this in some cases
    }
    
    let _ = std::io::stderr().write_all(b"Crypto provider initialized\n");
    let _ = std::io::stderr().flush();
    info!("Starting FKS Main Orchestration Service");

    // Load configuration
    let _ = std::io::stderr().write_all(b"Loading configuration...\n");
    let _ = std::io::stderr().flush();
    let config = match AppConfig::load() {
        Ok(cfg) => {
            let msg = format!("Configuration loaded: monitor_url={}, port={}\n", cfg.monitor_url, cfg.service_port);
            let _ = std::io::stderr().write_all(msg.as_bytes());
            let _ = std::io::stderr().flush();
            info!("Configuration loaded: monitor_url={}", cfg.monitor_url);
            cfg
        }
        Err(e) => {
            let msg = format!("ERROR: Failed to load configuration: {}\n", e);
            let _ = std::io::stderr().write_all(msg.as_bytes());
            let _ = std::io::stderr().flush();
            error!("Failed to load configuration: {}", e);
            return Err(e);
        }
    };

    // Extract port before moving config
    let service_port = config.service_port;
    let monitor_url = config.monitor_url.clone();
    let msg = format!("Extracted service_port={}, monitor_url={}\n", service_port, monitor_url);
    let _ = std::io::stderr().write_all(msg.as_bytes());
    let _ = std::io::stderr().flush();

    // Initialize Kubernetes client
    let _ = std::io::stderr().write_all(b"Initializing Kubernetes client...\n");
    let _ = std::io::stderr().flush();
    let k8s_client = match Client::try_default().await {
        Ok(client) => {
            let _ = std::io::stderr().write_all(b"Kubernetes client initialized\n");
            let _ = std::io::stderr().flush();
            info!("Kubernetes client initialized");
            Some(client)
        }
        Err(e) => {
            let msg = format!("WARNING: Kubernetes client not available: {}. Running in non-K8s mode.\n", e);
            let _ = std::io::stderr().write_all(msg.as_bytes());
            let _ = std::io::stderr().flush();
            error!("Failed to initialize Kubernetes client: {}. Running in non-K8s mode.", e);
            None
        }
    };

    // Initialize monitor client
    let msg = format!("Initializing monitor client with URL: {}\n", monitor_url);
    let _ = std::io::stderr().write_all(msg.as_bytes());
    let _ = std::io::stderr().flush();
    let monitor_client = MonitorClient::new(&monitor_url);
    let _ = std::io::stderr().write_all(b"Monitor client initialized\n");
    let _ = std::io::stderr().flush();

    // Initialize run.sh executor
    let _ = std::io::stderr().write_all(b"Initializing run.sh executor...\n");
    let _ = std::io::stderr().flush();
    let runsh_executor = match RunShExecutor::new(None) {
        Ok(executor) => {
            let _ = std::io::stderr().write_all(b"run.sh executor initialized\n");
            let _ = std::io::stderr().flush();
            Some(Arc::new(executor))
        }
        Err(e) => {
            let msg = format!("WARNING: Failed to initialize run.sh executor: {}. Some features may not work.\n", e);
            let _ = std::io::stderr().write_all(msg.as_bytes());
            let _ = std::io::stderr().flush();
            warn!("Failed to initialize run.sh executor: {}. Some features may not work.", e);
            // Continue without run.sh executor - some endpoints will return errors
            None
        }
    };

    // Initialize app state
    let _ = std::io::stderr().write_all(b"Creating app state...\n");
    let _ = std::io::stderr().flush();
    let app_state = AppState {
        config,
        k8s_client,
        monitor_client,
        service_registry: Arc::new(RwLock::new(HashMap::new())),
        runsh_executor,
    };
    let _ = std::io::stderr().write_all(b"App state created\n");
    let _ = std::io::stderr().flush();

    // Build router
    let _ = std::io::stderr().write_all(b"Building router...\n");
    let _ = std::io::stderr().flush();
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
        .route("/api/v1/runsh/commands", get(list_runsh_commands))
        .route("/api/v1/runsh/execute", post(execute_runsh_command))
        .layer(CorsLayer::permissive())
        .with_state(app_state);
    let _ = std::io::stderr().write_all(b"Router built\n");
    let _ = std::io::stderr().flush();

    // Start server
    let msg = format!("Starting server on port {}...\n", service_port);
    let _ = std::io::stderr().write_all(msg.as_bytes());
    let _ = std::io::stderr().flush();
    let addr = format!("0.0.0.0:{}", service_port);
    info!("Listening on {}", addr);
    let msg = format!("FKS Main service listening on {}\n", addr);
    let _ = std::io::stderr().write_all(msg.as_bytes());
    let _ = std::io::stderr().flush();
    
    let listener = match tokio::net::TcpListener::bind(&addr).await {
        Ok(l) => {
            let msg = format!("Successfully bound to {}\n", addr);
            let _ = std::io::stderr().write_all(msg.as_bytes());
            let _ = std::io::stderr().flush();
            info!("Successfully bound to {}", addr);
            l
        }
        Err(e) => {
            let msg = format!("ERROR: Failed to bind to {}: {}\n", addr, e);
            let _ = std::io::stderr().write_all(msg.as_bytes());
            let _ = std::io::stderr().flush();
            error!("Failed to bind to {}: {}", addr, e);
            return Err(anyhow::anyhow!("Failed to bind to {}: {}", addr, e));
        }
    };
    
    let _ = std::io::stderr().write_all(b"Server starting...\n");
    let _ = std::io::stderr().flush();
    info!("Server starting...");
    let _ = std::io::stderr().write_all(b"FKS Main service is ready and accepting connections\n");
    let _ = std::io::stderr().write_all(b"Waiting for incoming connections...\n");
    let _ = std::io::stderr().flush();
    
    // Use spawn to ensure the server runs
    match axum::serve(listener, app).await {
        Ok(_) => {
            let _ = std::io::stderr().write_all(b"Server stopped normally\n");
            let _ = std::io::stderr().flush();
            Ok(())
        }
        Err(e) => {
            let msg = format!("ERROR: Server error: {}\n", e);
            let _ = std::io::stderr().write_all(msg.as_bytes());
            let _ = std::io::stderr().flush();
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
    State(_state): State<AppState>,
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
    State(_state): State<AppState>,
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

async fn list_runsh_commands(State(state): State<AppState>) -> Json<serde_json::Value> {
    let commands = match &state.runsh_executor {
        Some(executor) => executor.get_allowed_commands(),
        None => return Json(serde_json::json!({
            "error": "run.sh executor not available",
            "commands": []
        })),
    };
    let command_descriptions = vec![
        ("1", "Install Tools (Docker, Minikube, Helm, Trivy)"),
        ("2", "Build Base Images"),
        ("3", "Build Service Images"),
        ("4", "Start Services (Docker Compose)"),
        ("5", "Stop Services"),
        ("6", "Deploy to Kubernetes"),
        ("7", "Manage Venvs (Python services)"),
        ("8", "Commit & Push (All repos or services only)"),
        ("9", "Analyze Codebase"),
        ("10", "Check GitHub Actions Status"),
        ("11", "Sync/Pull Images"),
    ];

    let commands_list: Vec<serde_json::Value> = commands
        .iter()
        .filter_map(|cmd| {
            command_descriptions
                .iter()
                .find(|(id, _)| id == cmd)
                .map(|(id, desc)| {
                    serde_json::json!({
                        "id": id,
                        "description": desc
                    })
                })
        })
        .collect();

    Json(serde_json::json!({
        "commands": commands_list,
        "count": commands_list.len()
    }))
}

async fn execute_runsh_command(
    State(state): State<AppState>,
    Json(payload): Json<serde_json::Value>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let command = match payload.get("command").and_then(|v| v.as_str()) {
        Some(cmd) => cmd.to_string(),
        None => {
            return Err(StatusCode::BAD_REQUEST);
        }
    };

    let args = payload
        .get("args")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_str().map(|s| s.to_string()))
                .collect()
        })
        .unwrap_or_default();

    let timeout_seconds = payload
        .get("timeout_seconds")
        .and_then(|v| v.as_u64())
        .or(Some(300));

    let runsh_cmd = runsh::RunShCommand {
        command,
        args,
        timeout_seconds,
    };

    let executor = match &state.runsh_executor {
        Some(e) => e,
        None => {
            return Err(StatusCode::SERVICE_UNAVAILABLE);
        }
    };

    match executor.execute(runsh_cmd).await {
        Ok(response) => {
            let result = serde_json::json!({
                "success": response.success,
                "exit_code": response.exit_code,
                "stdout": response.stdout,
                "stderr": response.stderr,
                "duration_ms": response.duration_ms,
            });

            Ok(Json(result))
        }
        Err(e) => {
            error!("Failed to execute run.sh command: {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

