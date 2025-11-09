# FKS Monitor Service - Setup Guide

**Purpose**: Centralized monitoring service that aggregates health, metrics, and test results from all FKS services.

## 🎯 Overview

`fks_monitor` is the single source of truth for:
- **Health Status**: All FKS services' `/health`, `/ready`, `/live` endpoints
- **Metrics**: Prometheus metrics from services and Grafana
- **Test Results**: Test status and coverage from all repos
- **Service Discovery**: Registry of all FKS services

## 🚀 Quick Start

### 1. Start the Service

```bash
cd repo/tools/monitor
./start.sh
```

Or manually:
```bash
docker-compose up --build
```

### 2. Verify It's Running

```bash
# Check health
curl http://localhost:8009/health

# Check services
curl http://localhost:8009/api/v1/services

# Get summary
curl http://localhost:8009/api/v1/summary
```

### 3. Access Monitoring

- **Monitor API**: http://localhost:8009
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)

## 📡 API Endpoints

### Health Checks
- `GET /health` - Monitor service health
- `GET /ready` - Readiness check
- `GET /live` - Liveness probe

### Service Monitoring
- `GET /api/v1/services` - List all services
- `GET /api/v1/services/{name}` - Get service status
- `GET /api/v1/services/{name}/metrics` - Get service metrics
- `GET /api/v1/services/{name}/tests` - Get service test results
- `POST /api/v1/services/register` - Register new service

### Aggregated Views
- `GET /api/v1/summary` - Overall system health
- `GET /api/v1/metrics` - All metrics
- `GET /api/v1/tests` - All test results

### Prometheus
- `GET /metrics` - Prometheus-compatible metrics

## 🔧 Configuration

### Service Registry

Edit `config/services.yaml` to add/remove services:

```yaml
services:
  fks_api:
    name: fks_api
    health_url: http://fks-api:8001/health
    ready_url: http://fks-api:8001/ready
    live_url: http://fks-api:8001/live
    port: 8001
```

### Environment Variables

```bash
# Service Configuration
MONITOR_PORT=8009
MONITOR_HOST=0.0.0.0

# Prometheus & Grafana
PROMETHEUS_URL=http://prometheus:9090
GRAFANA_URL=http://grafana:3000

# Update Intervals
HEALTH_CHECK_INTERVAL=30  # seconds
METRICS_UPDATE_INTERVAL=60  # seconds
TEST_CHECK_INTERVAL=300  # seconds

# Google AI API (optional, for test analysis)
GOOGLE_AI_API_KEY=your_key_here
```

## 🔗 Integration with fks_main

`fks_main` (Rust API) consumes `fks_monitor`:

```rust
// Example usage in fks_main
let monitor = MonitorClient::new("http://fks-monitor:8009");
let services = monitor.get_all_services().await?;
let summary = monitor.get_summary().await?;
```

## 📊 What Gets Monitored

### Health Checks
- Polls `/health`, `/ready`, `/live` from all services
- Updates every 30 seconds (configurable)
- Tracks response times and status codes

### Metrics
- Scrapes Prometheus metrics
- Aggregates Grafana dashboard data
- Updates every 60 seconds

### Tests
- Checks test status from services
- Aggregates coverage reports
- Updates every 5 minutes

## 🐳 Docker

### Build

```bash
docker build -t nuniesmith/fks_monitor:latest .
```

### Run

```bash
docker run -p 8009:8009 \
  -e PROMETHEUS_URL=http://prometheus:9090 \
  -e GRAFANA_URL=http://grafana:3000 \
  -v $(pwd)/config:/app/config:ro \
  nuniesmith/fks_monitor:latest
```

## 🧪 Testing

```bash
# Run tests
pytest tests/ -v

# With coverage
pytest tests/ --cov=src --cov-report=html
```

## 📚 Next Steps

1. **Configure Services**: Update `config/services.yaml` with all FKS services
2. **Start Monitoring**: Run `./start.sh` or `docker-compose up`
3. **Integrate with fks_main**: fks_main will consume monitor API
4. **View Dashboards**: Access Grafana at http://localhost:3000

---

**Repository**: [nuniesmith/fks_monitor](https://github.com/nuniesmith/fks_monitor)

