/// Prometheus metrics setup for Axum services.
///
/// This module provides standardized Prometheus metrics for all FKS Rust/Axum services,
/// following the mandatory metrics standard defined in METRICS_STANDARD.md.
///
/// Usage:
///     use crate::metrics::setup_prometheus_metrics;
///
///     let (prometheus_layer, metric_handle) = setup_prometheus_metrics("fks_main", "1.0.0");
///     let app = Router::new()
///         .route("/metrics", get(|| async move { metric_handle.render() }))
///         .layer(prometheus_layer);

use axum_prometheus::PrometheusMetricLayer;
use prometheus::{Gauge, IntGaugeVec, Registry, Encoder, TextEncoder};
use std::env;

/// Set up Prometheus metrics for an Axum application.
///
/// Returns a tuple of (PrometheusMetricLayer, MetricHandle) that can be used
/// to instrument the router and expose metrics.
///
/// # Arguments
///
/// * `service_name` - Name of the service (e.g., "fks_main")
/// * `version` - Service version (e.g., "1.0.0")
///
/// # Example
///
/// ```rust
/// use axum::{Router, routing::get};
/// use crate::metrics::setup_prometheus_metrics;
///
/// let (prometheus_layer, metric_handle) = setup_prometheus_metrics("fks_main", "1.0.0");
///
/// let app = Router::new()
///     .route("/metrics", get(|| async move {
///         metric_handle.render()
///     }))
///     .layer(prometheus_layer);
/// ```
pub fn setup_prometheus_metrics(
    service_name: impl Into<String>,
    version: impl Into<String>,
) -> (PrometheusMetricLayer, MetricHandle) {
    let service_name: String = service_name.into();
    let version: String = version.into();
    // Create Prometheus metric layer for HTTP metrics
    let (prometheus_layer, metric_handle) = PrometheusMetricLayer::pair();

    // Get build information from environment
    let commit = env::var("GIT_COMMIT")
        .or_else(|_| env::var("COMMIT_SHA"))
        .unwrap_or_else(|_| "unknown".to_string());
    let build_date = env::var("BUILD_DATE")
        .or_else(|_| env::var("BUILD_TIMESTAMP"))
        .unwrap_or_else(|_| "unknown".to_string());

    // Create registry for custom metrics
    let registry = Registry::new();

    // Build info metric (always 1, used for filtering/grouping)
    let build_info = Gauge::with_opts(
        prometheus::opts!(
            "fks_build_info",
            "Build information for FKS service"
        )
        .const_label("service", &service_name)
        .const_label("version", &version)
        .const_label("commit", &commit[..commit.len().min(8)])
        .const_label("build_date", &build_date),
    )
    .expect("Failed to create build_info metric");
    build_info.set(1.0);
    registry
        .register(Box::new(build_info))
        .expect("Failed to register build_info metric");

    // Service health metric (1=healthy, 0=unhealthy)
    let service_health = IntGaugeVec::new(
        prometheus::opts!("fks_service_health", "Service health status (1=healthy, 0=unhealthy)"),
        &["service"],
    )
    .expect("Failed to create service_health metric");
    service_health.with_label_values(&[&service_name]).set(1);
    registry
        .register(Box::new(service_health))
        .expect("Failed to register service_health metric");

    // Create metric handle that includes custom metrics
    // Store render closure since MetricHandle type is not exported
    let render_closure = {
        let handle = metric_handle;
        Box::new(move || handle.render()) as Box<dyn Fn() -> String + Send + Sync>
    };
    let handle = MetricHandle {
        registry,
        render_fn: render_closure,
    };

    (prometheus_layer, handle)
}

/// Handle for rendering Prometheus metrics.
///
/// Combines axum-prometheus metrics with custom FKS metrics.
pub struct MetricHandle {
    registry: Registry,
    render_fn: Box<dyn Fn() -> String + Send + Sync>,
}

impl MetricHandle {
    /// Render all metrics in Prometheus text format.
    pub fn render(&self) -> String {
        let mut output = String::new();

        // Render axum-prometheus metrics (HTTP metrics)
        output.push_str(&(self.render_fn)());

        // Render custom FKS metrics (build info, service health)
        let encoder = TextEncoder::new();
        let metric_families = self.registry.gather();
        let mut buffer = Vec::new();
        if let Err(e) = encoder.encode(&metric_families, &mut buffer) {
            tracing::warn!("Failed to encode custom metrics: {}", e);
            return output;
        }
        if let Ok(metrics_text) = String::from_utf8(buffer) {
            output.push_str(&metrics_text);
        }

        output
    }
}

/// Update the service health metric.
///
/// # Arguments
///
/// * `service_name` - Name of the service
/// * `is_healthy` - True if service is healthy, False otherwise
///
/// Note: This requires access to the metric handle. In practice, you'll want
/// to store the metric handle in your app state or use a global registry.
pub fn update_service_health(service_name: &str, is_healthy: bool) {
    // This is a simplified version - in practice, you'd want to store
    // the metric in app state or use a global registry
    let service_health = IntGaugeVec::new(
        prometheus::opts!("fks_service_health", "Service health status (1=healthy, 0=unhealthy)"),
        &["service"],
    )
    .expect("Failed to create service_health metric");
    service_health
        .with_label_values(&[service_name])
        .set(if is_healthy { 1 } else { 0 });
}
