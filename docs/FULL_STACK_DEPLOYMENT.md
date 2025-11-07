# FKS Trading Platform - Full Stack Deployment Guide

**Date**: November 6, 2025  
**Status**: Ready for deployment with Tailscale networking

---

## Overview

Complete Kubernetes deployment of FKS Trading Platform with:
- **Django Web UI** - Main trading interface
- **PostgreSQL + TimescaleDB** - Time-series database with vector extensions
- **Redis** - Caching and Celery message broker
- **Microservices**: API, App, Data, AI, Execution
- **Celery** - Distributed task queue (workers + beat scheduler)
- **Monitoring**: Prometheus, Grafana, Alertmanager
- **Tailscale Networking** - Secure access via 100.116.135.8

---

## Quick Start

```bash
# 1. Build Docker images (if not already built)
cd /home/jordan/Documents/code/fks
./scripts/build-docker-images.sh

# 2. Deploy all services to Kubernetes
./k8s/scripts/deploy-all-services.sh

# 3. Wait for pods to be ready
kubectl get pods -n fks-trading -w

# 4. Access services
# Via Tailscale network (100.116.135.8):
https://fkstrading.xyz             # Web UI
https://api.fkstrading.xyz         # API
https://grafana.fkstrading.xyz     # Monitoring
https://flower.fkstrading.xyz      # Celery monitoring

# Via local port forwarding:
/tmp/fks-port-forward.sh
```

---

## Architecture

### Service Topology

```
┌─────────────────────────────────────────────────────────┐
│                  Tailscale Network                       │
│              (IP: 100.116.135.8)                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              NGINX Ingress Controller                    │
│    (TLS termination, routing, rate limiting)            │
└──┬────┬────┬────┬────┬────┬────┬────────────────────────┘
   │    │    │    │    │    │    │
   ▼    ▼    ▼    ▼    ▼    ▼    ▼
┌────┬────┬────┬────┬────┬────┬────────┐
│Web │API │Graf│Prom│Alrt│Flwr│Exec    │  (Services)
│8000│8001│3000│9090│9093│5555│8000    │  (Ports)
└─┬──┴──┬─┴────┴────┴────┴────┴────────┘
  │     │
  │     └──────────────┐
  │                    │
  ▼                    ▼
┌──────────┐     ┌──────────┐
│PostgreSQL│◄────┤  Redis   │
│TimescaleDB│    │ (Celery) │
│(5432)    │    │  (6379)  │
└──────────┘    └──────────┘
  │                    │
  │                    │
  └─────┬──────────────┘
        │
        ▼
  ┌─────────────────┐
  │  Celery Workers │
  │  (background    │
  │   tasks)        │
  └─────────────────┘
```

### Services Breakdown

| Service | Port | Purpose | Replicas | Resources |
|---------|------|---------|----------|-----------|
| **web** | 8000 | Django UI (Gunicorn 4 workers) | 2 | 512Mi-1Gi RAM |
| **fks-api** | 8001 | REST API for trading operations | 2 | Default |
| **fks-app** | 8002 | Application logic service | 2 | Default |
| **fks-data** | 8003 | Data ingestion/processing | 2 | Default |
| **fks-ai** | 8007 | Multi-agent AI (LangGraph) | 1 | 2-4Gi RAM |
| **fks-execution** | 8000 | Order execution (CCXT) | 1 | Default |
| **postgres** | 5432 | TimescaleDB with pgvector | 1 | 100Gi PVC |
| **redis** | 6379 | Cache + Celery broker | 1 | 10Gi PVC |
| **celery-worker** | - | Background tasks | 2 | Default |
| **celery-beat** | - | Scheduled tasks | 1 | Default |
| **flower** | 5555 | Celery monitoring UI | 1 | Default |
| **prometheus** | 9090 | Metrics collection | 1 | 50Gi PVC |
| **grafana** | 3000 | Metrics visualization | 1 | 10Gi PVC |
| **alertmanager** | 9093 | Alert routing (Slack) | 1 | Default |

---

## Deployment Steps

### Step 1: Prerequisites

```bash
# Verify minikube is running
minikube status

# Verify kubectl access
kubectl cluster-info

# Verify Tailscale is configured
ip addr show tailscale0
# Should show: 100.116.135.8

# Verify namespace exists
kubectl get namespace fks-trading
```

### Step 2: Build Docker Images

```bash
cd /home/jordan/Documents/code/fks

# Build all service images
./scripts/build-docker-images.sh

# Verify images were built
docker images | grep fks

# Verify images loaded into minikube
minikube image ls | grep fks
```

**Expected images**:
- `nuniesmith/fks:web-latest` - Django web UI
- `nuniesmith/fks:api-latest` - API service
- `nuniesmith/fks:app-latest` - App service
- `nuniesmith/fks:data-latest` - Data service
- `nuniesmith/fks:ai-latest` - AI service

### Step 3: Configure Secrets

```bash
cd /home/jordan/Documents/code/fks/k8s/manifests

# Copy template
cp fks-secrets.yaml.template fks-secrets.yaml

# Edit with actual values
nano fks-secrets.yaml

# Required secrets:
# - postgres-user, postgres-password
# - django-secret-key (generate: python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
# - Optional: openai-api-key, slack-webhook-url, exchange API keys

# Apply secrets
kubectl apply -f fks-secrets.yaml

# Verify
kubectl get secret fks-secrets -n fks-trading
```

### Step 4: Deploy All Services

```bash
# Run automated deployment
./k8s/scripts/deploy-all-services.sh

# Script will:
# 1. Check prerequisites (kubectl, cluster, secrets)
# 2. Deploy PostgreSQL and Redis (stateful services)
# 3. Wait for database to be ready
# 4. Deploy Django web with migrations
# 5. Deploy microservices (api, app, data, ai)
# 6. Deploy Celery workers
# 7. Configure Tailscale ingress
# 8. Update /etc/hosts with Tailscale IP
```

### Step 5: Verify Deployment

```bash
# Watch pods come up
kubectl get pods -n fks-trading -w

# Expected state (all Running):
# postgres-0                  1/1     Running
# redis-xxx                   1/1     Running
# fks-web-xxx                 1/1     Running   (2 replicas)
# fks-api-xxx                 1/1     Running   (2 replicas)
# fks-app-xxx                 1/1     Running   (2 replicas)
# fks-data-xxx                1/1     Running   (2 replicas)
# fks-ai-xxx                  1/1     Running
# celery-worker-xxx           1/1     Running   (2 replicas)
# celery-beat-xxx             1/1     Running
# flower-xxx                  1/1     Running
# prometheus-xxx              1/1     Running
# grafana-xxx                 1/1     Running
# alertmanager-xxx            1/1     Running

# Check services
kubectl get svc -n fks-trading

# Check ingress
kubectl get ingress -n fks-trading

# Check PVCs
kubectl get pvc -n fks-trading
# Should show: postgres-data (100Gi), redis-data (10Gi)
```

---

## Access Services

### Option 1: Via Tailscale Network (Recommended)

**Prerequisites**: `minikube tunnel` running in separate terminal

```bash
# Terminal 1: Run tunnel (requires sudo password)
minikube tunnel

# Terminal 2: Access services via browser
https://fkstrading.xyz             # Web UI
https://api.fkstrading.xyz         # API docs
https://grafana.fkstrading.xyz     # Grafana (admin/admin)
https://prometheus.fkstrading.xyz  # Prometheus
https://alertmanager.fkstrading.xyz # Alertmanager
https://flower.fkstrading.xyz      # Celery monitoring
https://execution.fkstrading.xyz   # Execution webhooks
```

**Note**: Accept self-signed certificate warnings in browser (or install `/tmp/fks-certs/tls.crt` as trusted CA).

### Option 2: Via Port Forwarding (Local Development)

```bash
# Use helper script
/tmp/fks-port-forward.sh

# Or manually:
kubectl port-forward -n fks-trading svc/web 8000:8000 &
kubectl port-forward -n fks-trading svc/fks-api 8001:8001 &
kubectl port-forward -n fks-trading svc/grafana 3000:3000 &
kubectl port-forward -n fks-trading svc/prometheus 9090:9090 &
kubectl port-forward -n fks-trading svc/flower 5555:5555 &

# Access via localhost:
http://localhost:8000   # Web UI
http://localhost:8001   # API
http://localhost:3000   # Grafana
http://localhost:9090   # Prometheus
http://localhost:5555   # Flower
```

---

## Configuration

### Environment Variables

All services read configuration from:
1. **Secrets** (`fks-secrets`): Database credentials, API keys
2. **ConfigMap** (in manifests): Service URLs, Redis connections
3. **Environment**: Hardcoded in deployment manifests

**Key variables**:
```yaml
POSTGRES_HOST: db
POSTGRES_PORT: 5432
POSTGRES_DB: trading_db
REDIS_URL: redis://redis:6379/<db_number>
CELERY_BROKER_URL: redis://redis:6379/0
DJANGO_SETTINGS_MODULE: services.web.src.django.settings
```

### Database Configuration

**PostgreSQL** (TimescaleDB with pgvector):
- User: From `fks-secrets.postgres-user`
- Password: From `fks-secrets.postgres-password`
- Database: `trading_db`
- Extensions: `timescaledb`, `vector`
- Authentication: SCRAM-SHA-256
- Persistent: 100Gi PVC

**Redis**:
- Append-only file (AOF) enabled
- Max memory: 512MB
- Eviction: allkeys-lru
- Persistent: 10Gi PVC

### Service Discovery

Services communicate via Kubernetes DNS:
```
db.fks-trading.svc.cluster.local:5432
redis.fks-trading.svc.cluster.local:6379
web.fks-trading.svc.cluster.local:8000
fks-api.fks-trading.svc.cluster.local:8001
...
```

Short form within namespace: `db`, `redis`, `web`, etc.

---

## Monitoring

### Prometheus Metrics

**Targets**:
- All FKS services expose `/metrics` endpoint
- Node exporters for system metrics
- PostgreSQL exporter (if deployed)
- Redis exporter (if deployed)

**Access**: https://prometheus.fkstrading.xyz

### Grafana Dashboards

**Pre-configured dashboards**:
- Execution Pipeline (16 panels) - `/monitoring/grafana/dashboards/execution_pipeline.json`
- Kubernetes cluster monitoring
- Service health overview

**Access**: https://grafana.fkstrading.xyz (admin/admin)

**Add datasource**:
1. Configuration → Data Sources → Add Prometheus
2. URL: `http://prometheus:9090`
3. Save & Test

### Alertmanager

**Alerts route to Slack** (if webhook configured in secrets):
- **Critical**: Circuit breaker, high order failures, security issues
- **Warning**: High latency, validation failures, rate limits
- **Info**: Data quality, confidence filtering

**Access**: https://alertmanager.fkstrading.xyz

### Celery Monitoring (Flower)

**Features**:
- Real-time worker monitoring
- Task history and statistics
- Worker resource usage
- Task routing visualization

**Access**: https://flower.fkstrading.xyz

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n fks-trading

# Describe pod for events
kubectl describe pod <pod-name> -n fks-trading

# Check logs
kubectl logs <pod-name> -n fks-trading

# For init container failures (migrations):
kubectl logs <pod-name> -c migrate -n fks-trading
```

**Common issues**:
- **ImagePullBackOff**: Image not in minikube cache → Run `minikube image load <image>`
- **CrashLoopBackOff**: Check logs for errors, verify secrets exist
- **Pending**: PVC not bound → Check `kubectl get pvc -n fks-trading`

### Database Connection Errors

```bash
# Verify PostgreSQL is running
kubectl get pods -n fks-trading -l app=postgres

# Check PostgreSQL logs
kubectl logs -n fks-trading -l app=postgres

# Test connection from another pod
kubectl run -it --rm psql-test --image=postgres:16 --restart=Never -n fks-trading -- \
  psql -h db -U trading_user -d trading_db

# Verify secrets
kubectl get secret fks-secrets -n fks-trading -o yaml
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress status
kubectl get ingress -n fks-trading
kubectl describe ingress fks-ingress-tailscale -n fks-trading

# Verify minikube tunnel is running
# (requires separate terminal with sudo)
minikube tunnel

# Test DNS resolution
ping fkstrading.xyz
# Should resolve to 100.116.135.8 or minikube IP

# Check /etc/hosts
grep fkstrading /etc/hosts
```

### Celery Workers Not Processing Tasks

```bash
# Check worker logs
kubectl logs -n fks-trading -l app=celery-worker

# Check Redis connectivity
kubectl exec -it -n fks-trading deployment/redis -- redis-cli ping

# Verify Celery broker URL
kubectl exec -it -n fks-trading deployment/fks-web -- env | grep CELERY

# Use Flower to inspect workers
# Access: https://flower.fkstrading.xyz
```

### Performance Issues

```bash
# Check resource usage
kubectl top pods -n fks-trading
kubectl top nodes

# Increase resources (edit deployment):
kubectl edit deployment fks-ai -n fks-trading
# Update resources.limits.memory, resources.limits.cpu

# Scale replicas
kubectl scale deployment fks-web --replicas=4 -n fks-trading

# Check HPA status (if configured)
kubectl get hpa -n fks-trading
```

---

## Maintenance

### Update Service

```bash
# Build new image
docker build -f docker/Dockerfile.api -t nuniesmith/fks:api-v2 .

# Load into minikube
minikube image load nuniesmith/fks:api-v2

# Update deployment
kubectl set image deployment/fks-api api=nuniesmith/fks:api-v2 -n fks-trading

# Watch rollout
kubectl rollout status deployment/fks-api -n fks-trading

# Rollback if needed
kubectl rollout undo deployment/fks-api -n fks-trading
```

### Database Backup

```bash
# Backup PostgreSQL
kubectl exec -n fks-trading postgres-0 -- pg_dump -U trading_user trading_db > backup.sql

# Restore
cat backup.sql | kubectl exec -i -n fks-trading postgres-0 -- psql -U trading_user trading_db
```

### View Logs

```bash
# Real-time logs
kubectl logs -f deployment/fks-web -n fks-trading

# Last 100 lines
kubectl logs --tail=100 deployment/fks-api -n fks-trading

# All containers in pod
kubectl logs <pod-name> --all-containers -n fks-trading

# Logs from specific time
kubectl logs --since=1h deployment/fks-data -n fks-trading
```

### Restart Service

```bash
# Restart deployment (recreates pods)
kubectl rollout restart deployment/fks-web -n fks-trading

# Delete pod (auto-recreated by deployment)
kubectl delete pod <pod-name> -n fks-trading
```

---

## Production Checklist

### Before Deployment

- [ ] **Secrets configured** with strong passwords (not defaults)
- [ ] **Django SECRET_KEY** generated (50+ characters)
- [ ] **Database backups** configured
- [ ] **Monitoring alerts** tested (Slack integration working)
- [ ] **TLS certificates** from Let's Encrypt (not self-signed)
- [ ] **Resource limits** set appropriately for production load
- [ ] **Horizontal Pod Autoscaling** configured and tested
- [ ] **PersistentVolumes** use production storage class (not hostPath)
- [ ] **Ingress rate limiting** configured (default: 100 req/s)
- [ ] **All health checks** passing (`/health`, `/ready` endpoints)

### After Deployment

- [ ] **All pods Running** (`kubectl get pods -n fks-trading`)
- [ ] **Services accessible** via ingress URLs
- [ ] **Database migrations** applied successfully
- [ ] **Celery workers** connected and processing tasks
- [ ] **Prometheus** scraping all targets
- [ ] **Grafana dashboards** displaying data
- [ ] **Alertmanager** routing alerts to Slack
- [ ] **Load testing** completed (>80 req/s throughput)
- [ ] **Backup/restore** tested
- [ ] **Disaster recovery plan** documented

### Security Hardening

- [ ] **Network policies** to restrict pod-to-pod traffic
- [ ] **Pod security policies** enforced (non-root containers)
- [ ] **RBAC** configured (least privilege for service accounts)
- [ ] **Secrets** stored in external vault (Vault, AWS Secrets Manager)
- [ ] **Image scanning** for vulnerabilities (Trivy, Clair)
- [ ] **Audit logging** enabled for K8s API
- [ ] **mTLS** between services (Istio, Linkerd)
- [ ] **WAF** in front of ingress (CloudFlare, AWS WAF)

---

## Files Created

| File | Purpose |
|------|---------|
| `/k8s/manifests/all-services.yaml` | Complete service definitions (14 services) |
| `/k8s/manifests/fks-secrets.yaml.template` | Secrets template (copy and edit) |
| `/k8s/manifests/ingress-tailscale.yaml` | Ingress for Tailscale network access |
| `/k8s/scripts/deploy-all-services.sh` | Automated deployment script |
| `/scripts/build-docker-images.sh` | Docker image build automation |
| `/tmp/fks-port-forward.sh` | Port forwarding helper |

---

## Next Steps

1. **Build images**: `./scripts/build-docker-images.sh`
2. **Deploy services**: `./k8s/scripts/deploy-all-services.sh`
3. **Access Web UI**: https://fkstrading.xyz (after `minikube tunnel`)
4. **Configure monitoring**: Import Grafana dashboards from `/monitoring/grafana/dashboards/`
5. **Test execution pipeline**: Send test webhook to https://execution.fkstrading.xyz
6. **Production migration**: Move to cloud K8s (GKE/EKS/AKS), configure Let's Encrypt, DNS

---

**Documentation**: /home/jordan/Documents/code/fks/docs/FULL_STACK_DEPLOYMENT.md  
**Last Updated**: November 6, 2025  
**Status**: Ready for deployment ✅
