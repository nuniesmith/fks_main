/// Monitor client for communicating with fks_monitor service
use reqwest::Client;
use serde_json::Value;
use std::sync::Arc;
use std::time::Duration;

#[derive(Clone)]
pub struct MonitorClient {
    client: Arc<Client>,
    base_url: String,
}

impl MonitorClient {
    pub fn new(base_url: &str) -> Self {
        let client = match Client::builder()
            .timeout(Duration::from_secs(10))
            .build() {
            Ok(c) => c,
            Err(e) => {
                eprintln!("ERROR: Failed to create HTTP client: {}", e);
                // Use a dummy client that will fail on requests, but won't panic
                // This allows the service to start even if the HTTP client fails
                Client::builder()
                    .timeout(Duration::from_secs(1))
                    .build()
                    .unwrap_or_else(|_| {
                        eprintln!("CRITICAL: Cannot create HTTP client at all");
                        std::process::exit(1);
                    })
            }
        };

        Self {
            client: Arc::new(client),
            base_url: base_url.trim_end_matches('/').to_string(),
        }
    }

    pub async fn check_health(&self) -> anyhow::Result<Value> {
        let url = format!("{}/health", self.base_url);
        let response = self.client.get(&url).send().await?;
        response.json().await.map_err(Into::into)
    }

    pub async fn get_all_services(&self) -> anyhow::Result<Value> {
        let url = format!("{}/api/v1/services", self.base_url);
        let response = self.client.get(&url).send().await?;
        response.json().await.map_err(Into::into)
    }

    pub async fn get_service(&self, service_name: &str) -> anyhow::Result<Value> {
        let url = format!("{}/api/v1/services/{}", self.base_url, service_name);
        let response = self.client.get(&url).send().await?;
        response.json().await.map_err(Into::into)
    }

    pub async fn get_summary(&self) -> anyhow::Result<Value> {
        let url = format!("{}/api/v1/summary", self.base_url);
        let response = self.client.get(&url).send().await?;
        response.json().await.map_err(Into::into)
    }

    pub async fn get_metrics(&self) -> anyhow::Result<Value> {
        let url = format!("{}/api/v1/metrics", self.base_url);
        let response = self.client.get(&url).send().await?;
        response.json().await.map_err(Into::into)
    }

    pub async fn get_tests(&self) -> anyhow::Result<Value> {
        let url = format!("{}/api/v1/tests", self.base_url);
        let response = self.client.get(&url).send().await?;
        response.json().await.map_err(Into::into)
    }
}

