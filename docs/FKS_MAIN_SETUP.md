# FKS Main Orchestration Service - Setup Guide

**Purpose**: Rust-based API for Kubernetes orchestration and centralized control of all FKS services.

## 🎯 Overview

`fks_main` provides:
- **K8s Orchestration**: Control deployments, scaling, restarts
- **Service Management**: Unified API for all FKS services
- **Monitor Integration**: Consumes `fks_monitor` for data
- **Infrastructure Control**: Full K8s environment control

## 🚀 Quick Start

### 1. Build the Service

```bash
cd repo/core/main
cargo build --release
```

### 2. Run Locally

```bash
# Set environment variables
export MONITOR_URL=http://localhost:8009
export K8S_NAMESPACE=fks-trading

# Run
cargo run
```

### 3. Or Use Docker

```bash
docker-compose up --build
```

## 📡 API Endpoints

### Health & Status
- `GET /health` - Service health
- `GET /ready` - Readiness (checks monitor)
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
# Service
SERVICE_NAME=fks_main
SERVICE_PORT=8010

# Monitor Integration
MONITOR_URL=http://fks-monitor:8009

# Kubernetes
K8S_NAMESPACE=fks-trading

# Domain & TLS
DOMAIN=fkstrading.xyz
TLS_ENABLED=false
TLS_CERT_PATH=/app/certs/tls.crt
TLS_KEY_PATH=/app/certs/tls.key

# Logging
RUST_LOG=info
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
  nuniesmith/fks_main:latest
```

## 🔗 Integration

### With fks_monitor

`fks_main` consumes `fks_monitor` API:
- Service health status
- Metrics for scaling decisions
- Test results for deployment gates

### With Kubernetes

`fks_main` uses Kubernetes API for:
- Deployment management
- Pod scaling
- Service restarts
- Resource monitoring

### With fks_web

`fks_main` provides APIs for `fks_web`:
- Service status dashboard
- Deployment controls
- Health monitoring

## 🧪 Testing

```bash
# Run tests
cargo test

# With output
cargo test -- --nocapture
```

## 📚 Next Steps

1. **Setup K8s**: Run `./scripts/setup_k8s_local.sh`
2. **Deploy Services**: Use fks_main to orchestrate deployments
3. **Monitor**: fks_main will use fks_monitor for status

---

**Repository**: [nuniesmith/fks](https://github.com/nuniesmith/fks) (main repo)

