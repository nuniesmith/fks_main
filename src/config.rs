/// Configuration management for FKS Main service
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub service_name: String,
    pub service_port: u16,
    pub monitor_url: String,
    pub k8s_namespace: String,
    pub domain: String,
    pub tls_enabled: bool,
    pub cert_path: Option<String>,
    pub key_path: Option<String>,
}

impl AppConfig {
    pub fn load() -> anyhow::Result<Self> {
        dotenv::dotenv().ok();

        Ok(Self {
            service_name: env::var("SERVICE_NAME").unwrap_or_else(|_| "fks_main".to_string()),
            service_port: env::var("SERVICE_PORT")
                .unwrap_or_else(|_| "8010".to_string())
                .parse()
                .unwrap_or(8010),
            monitor_url: env::var("MONITOR_URL")
                .unwrap_or_else(|_| "http://fks-monitor:8009".to_string()),
            k8s_namespace: env::var("K8S_NAMESPACE").unwrap_or_else(|_| "fks-trading".to_string()),
            domain: env::var("DOMAIN").unwrap_or_else(|_| "fkstrading.xyz".to_string()),
            tls_enabled: env::var("TLS_ENABLED")
                .unwrap_or_else(|_| "false".to_string())
                .parse()
                .unwrap_or(false),
            cert_path: env::var("TLS_CERT_PATH").ok(),
            key_path: env::var("TLS_KEY_PATH").ok(),
        })
    }
}

