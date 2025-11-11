# FKS Main Orchestration Service

Rust-based API service for Kubernetes orchestration and centralized control of all FKS services.

## 🎯 Purpose

`fks_main` provides:
- **K8s Orchestration**: Control deployments, scaling, and restarts
- **Service Management**: Unified API for managing all FKS services
- **Monitor Integration**: Consumes `fks_monitor` for health/metrics/test data
- **Infrastructure Control**: Full control of K8s environment for production

## 🏗️ Architecture

```
fks_monitor → fks_main (Rust API) → Kubernetes
     ↓              ↓                    ↓
  Health/      Orchestration        Deployments
  Metrics/     Control              Services
  Tests
```

## 🚀 Quick Start

### Development

```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Build
cargo build

# Run
cargo run
```

### Docker

```bash
# Build
docker build -t nuniesmith/fks_main:latest .

# Run
docker run -p 8010:8010 \
  -e MONITOR_URL=http://fks-monitor:8009 \
  -e K8S_NAMESPACE=fks-trading \
  nuniesmith/fks_main:latest
```

## 📡 API Endpoints

### Health & Status

- `GET /health` - Service health
- `GET /ready` - Readiness (checks monitor connection)
- `GET /live` - Liveness probe

### Service Management

- `GET /api/v1/services` - List all services (from monitor)
- `GET /api/v1/services/{name}` - Get service details
- `POST /api/v1/services/{name}/scale` - Scale service
- `POST /api/v1/services/{name}/restart` - Restart service

### Kubernetes

- `GET /api/v1/k8s/pods` - List all pods
- `GET /api/v1/k8s/deployments` - List all deployments

### Aggregated Views

- `GET /api/v1/summary` - System summary (from monitor)

## 🔧 Configuration

### Environment Variables

```bash
# Service Configuration
SERVICE_NAME=fks_main
SERVICE_PORT=8010

# Monitor Integration
MONITOR_URL=http://fks-monitor:8009

# Kubernetes
K8S_NAMESPACE=fks-trading

# Domain & TLS
DOMAIN=fkstrading.xyz
TLS_ENABLED=true
TLS_CERT_PATH=/app/certs/tls.crt
TLS_KEY_PATH=/app/certs/tls.key
```

## 🐳 Docker

### Build

```bash
docker build -t nuniesmith/fks_main:latest .
```

### Run

```bash
docker run -p 8010:8010 \
  -e MONITOR_URL=http://fks-monitor:8009 \
  -e K8S_NAMESPACE=fks-trading \
  -v $(pwd)/certs:/app/certs:ro \
  nuniesmith/fks_main:latest
```

## 🔗 Integration

### With fks_monitor

`fks_main` consumes the `fks_monitor` API for:
- Service health status
- Metrics for scaling decisions
- Test results for deployment gates

### With Kubernetes

`fks_main` uses the Kubernetes API for:
- Deployment management
- Pod scaling
- Service restarts
- Resource monitoring

### With fks_web

`fks_main` provides APIs that `fks_web` can consume for:
- Service status dashboard
- Deployment controls
- Health monitoring

## ☸️ Kubernetes

### Deployment

```bash
# Deploy using Helm
cd k8s/charts/fks-platform
helm install fks-platform . -n fks-trading --create-namespace

# Or using the unified start script
cd /home/jordan/Documents/code/fks
./start.sh --type k8s
```

### Configuration

The service is deployed as part of the FKS platform Helm chart:
- **Namespace**: `fks-trading`
- **Replicas**: 2 (configurable)
- **Port**: 8010
- **Image**: `nuniesmith/fks:main-latest`

### Health Checks

Kubernetes probes:
- **Liveness**: `GET /live` on port 8010
- **Readiness**: `GET /ready` on port 8010 (checks monitor connection)

### Service Account

The service requires a Kubernetes service account with permissions to:
- List and get pods
- List and get deployments
- Scale deployments
- Restart deployments

## 📚 Documentation

- [API Documentation](docs/API.md)
- [Kubernetes Integration](docs/K8S.md)
- [Deployment Guide](docs/DEPLOYMENT.md)

## 🔗 Integration

### Dependencies

- **fks_monitor** (port 8006): Health checks and metrics aggregation
- **Kubernetes API**: For orchestration and control

### Consumers

- **fks_web**: Consumes fks_main API for service management
- **Administrators**: Direct API access for orchestration

## 📊 Monitoring

### Health Check Endpoints

- `GET /health` - Service health
- `GET /ready` - Readiness (checks monitor connection)
- `GET /live` - Liveness probe

### Metrics

- Service orchestration operations
- Kubernetes API call latency
- Monitor API response times
- Deployment success/failure rates

### Logging

- Structured logging for all operations
- Kubernetes event tracking
- Monitor API interactions

---

**Repository**: [nuniesmith/fks_main](https://github.com/nuniesmith/fks_main)  
**Docker Image**: `nuniesmith/fks:main-latest`  
**Status**: Active
