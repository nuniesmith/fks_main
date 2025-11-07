# Kubernetes Deployment Guide - FKS Trading Platform

**Phase 8.1: Kubernetes Migration**  
**Status**: 🚧 IN PROGRESS  
**Date**: November 2, 2025

---

## 📋 Overview

This guide walks through deploying the FKS Trading Platform to Kubernetes, migrating from Docker Compose to production-grade orchestration.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐      ┌─────────────────┐              │
│  │ Ingress (NGINX) │      │  cert-manager   │              │
│  │  SSL/TLS/Rate   │      │  (Let's Encrypt)│              │
│  └────────┬────────┘      └─────────────────┘              │
│           │                                                  │
│  ┌────────▼──────────────────────────────────────────────┐ │
│  │              FKS Platform Namespace                    │ │
│  ├────────────────────────────────────────────────────────┤ │
│  │                                                         │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │ │
│  │  │fks_main  │  │ fks_api  │  │ fks_app  │            │ │
│  │  │(2 pods)  │  │(2 pods)  │  │(2 pods)  │            │ │
│  │  └──────────┘  └──────────┘  └──────────┘            │ │
│  │                                                         │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │ │
│  │  │ fks_ai   │  │fks_data  │  │fks_exec  │            │ │
│  │  │(1-10 GPU)│  │(2 pods)  │  │(1 pod VPA)│           │ │
│  │  └──────────┘  └──────────┘  └──────────┘            │ │
│  │                                                         │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │ │
│  │  │fks_ninja │  │ fks_mt5  │  │ fks_web  │            │ │
│  │  │(1 pod)   │  │(1 pod)   │  │(2 pods)  │            │ │
│  │  └──────────┘  └──────────┘  └──────────┘            │ │
│  │                                                         │ │
│  │  ┌─────────────────────────────────────┐              │ │
│  │  │  StatefulSets (Persistent Data)     │              │ │
│  │  ├─────────────────────────────────────┤              │ │
│  │  │  PostgreSQL (TimescaleDB)           │              │ │
│  │  │  - Primary + Replica (HA)           │              │ │
│  │  │  - 50Gi PersistentVolume            │              │ │
│  │  ├─────────────────────────────────────┤              │ │
│  │  │  Redis + Sentinel                   │              │ │
│  │  │  - Master + Replicas (HA)           │              │ │
│  │  │  - 8Gi PersistentVolume             │              │ │
│  │  └─────────────────────────────────────┘              │ │
│  │                                                         │ │
│  │  ┌─────────────────────────────────────┐              │ │
│  │  │  Monitoring Stack                   │              │ │
│  │  ├─────────────────────────────────────┤              │ │
│  │  │  Prometheus (metrics)               │              │ │
│  │  │  Grafana (dashboards)               │              │ │
│  │  └─────────────────────────────────────┘              │ │
│  │                                                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Prerequisites

### Required Tools

```bash
# Kubernetes cluster (choose one)
# - Docker Desktop K8s (local)
# - minikube (local)
# - GKE/EKS/AKS (cloud)

# kubectl
brew install kubectl  # macOS
# or: sudo apt-get install kubectl  # Linux

# Helm 3.x
brew install helm  # macOS
# or: sudo apt-get install helm  # Linux

# Verify installation
kubectl version --client
helm version
```

### Cluster Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| Nodes | 3 | 5+ |
| CPU per node | 4 cores | 8 cores |
| RAM per node | 8 GB | 16 GB |
| Storage | 100 GB | 500 GB |
| GPU nodes | 0 | 1+ (for fks_ai) |

### Local Development (minikube)

```bash
# Start minikube with sufficient resources
minikube start \
  --cpus=4 \
  --memory=8192 \
  --disk-size=50g \
  --driver=docker

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

---

## 🚀 Quick Start

### 1. One-Command Deployment

```bash
# Make deploy script executable
chmod +x k8s/scripts/deploy.sh

# Deploy everything
./k8s/scripts/deploy.sh deploy
```

This script will:
- ✅ Create namespace `fks-trading`
- ✅ Generate secure secrets
- ✅ Add Helm repositories
- ✅ Install cert-manager (SSL/TLS)
- ✅ Install NGINX Ingress
- ✅ Deploy all 8 microservices
- ✅ Deploy PostgreSQL + Redis
- ✅ Deploy Prometheus + Grafana
- ✅ Verify deployment

### 2. Manual Step-by-Step

If you prefer manual control:

```bash
# 1. Create namespace
kubectl create namespace fks-trading

# 2. Add Helm repos
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 3. Generate secrets
kubectl create secret generic fks-secrets \
  -n fks-trading \
  --from-literal=postgres-password=$(openssl rand -base64 32) \
  --from-literal=redis-password=$(openssl rand -base64 32) \
  --from-literal=django-secret-key=$(openssl rand -base64 64)

# 4. Install FKS Platform
helm install fks-platform ./k8s/charts/fks-platform \
  --namespace fks-trading \
  --create-namespace \
  --wait

# 5. Verify
kubectl get all -n fks-trading
```

---

## 📊 Verify Deployment

### Check Pod Status

```bash
# All pods should show "Running"
kubectl get pods -n fks-trading

# Expected output:
# NAME                            READY   STATUS    RESTARTS   AGE
# fks-main-xxxx                   1/1     Running   0          2m
# fks-api-xxxx                    1/1     Running   0          2m
# fks-app-xxxx                    1/1     Running   0          2m
# fks-ai-xxxx                     1/1     Running   0          2m
# fks-data-xxxx                   1/1     Running   0          2m
# fks-execution-xxxx              1/1     Running   0          2m
# fks-platform-postgresql-0       1/1     Running   0          2m
# fks-platform-redis-master-0     1/1     Running   0          2m
```

### Check Services

```bash
kubectl get svc -n fks-trading

# Should see all 8 services + databases
```

### Check HPA (Auto-Scaling)

```bash
kubectl get hpa -n fks-trading

# Should show HPAs for scalable services
# TARGETS column shows current CPU/memory usage
```

### Check Logs

```bash
# View logs for a specific service
kubectl logs -n fks-trading -l app=fks-main -f

# View logs for AI service
kubectl logs -n fks-trading -l app=fks-ai -f --tail=50
```

---

## 🌐 Access Services

### Local Development (minikube/Docker Desktop)

Use port-forwarding to access services:

```bash
# FKS Main (orchestrator)
kubectl port-forward -n fks-trading svc/fks-main 8000:8000
# Access: http://localhost:8000

# FKS Web UI
kubectl port-forward -n fks-trading svc/fks-web 3001:3001
# Access: http://localhost:3001

# Grafana
kubectl port-forward -n fks-trading svc/grafana 3000:80
# Access: http://localhost:3000

# Prometheus
kubectl port-forward -n fks-trading svc/prometheus-server 9090:80
# Access: http://localhost:9090

# PostgreSQL (for debugging)
kubectl port-forward -n fks-trading svc/fks-platform-postgresql 5432:5432
# Access: postgresql://fks_user@localhost:5432/fks_db
```

### Cloud Deployment (with LoadBalancer)

```bash
# Get external IP
kubectl get ingress -n fks-trading

# Output will show external IPs/domains
# NAME                   HOSTS                  ADDRESS         PORTS
# fks-platform-ingress   fks-trading.com        35.x.x.x        80, 443
```

---

## ⚙️ Configuration

### Customize Values

Edit `k8s/charts/fks-platform/values.yaml`:

```yaml
# Example: Increase fks_ai replicas
fks_ai:
  replicaCount: 3  # Instead of 1
  autoscaling:
    minReplicas: 2
    maxReplicas: 20

# Example: Change resource limits
fks_app:
  resources:
    limits:
      cpu: 4000m  # 4 CPUs
      memory: 4Gi  # 4GB RAM
```

### Apply Changes

```bash
# Upgrade deployment with new values
helm upgrade fks-platform ./k8s/charts/fks-platform \
  -n fks-trading \
  -f k8s/charts/fks-platform/values.yaml

# Or modify specific values
helm upgrade fks-platform ./k8s/charts/fks-platform \
  -n fks-trading \
  --set fks_ai.replicaCount=5
```

---

## 🔐 Security

### Secrets Management

**⚠️ CRITICAL**: Never commit secrets to Git!

```bash
# View current secrets (base64 encoded)
kubectl get secret fks-secrets -n fks-trading -o yaml

# Decode a secret
kubectl get secret fks-secrets -n fks-trading \
  -o jsonpath='{.data.postgres-password}' | base64 -d

# Update a secret
kubectl create secret generic fks-secrets \
  -n fks-trading \
  --from-literal=postgres-password="NEW_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new secrets
kubectl rollout restart deployment -n fks-trading
```

### Production Secret Management

Use one of these instead of plain Kubernetes Secrets:

1. **Sealed Secrets** (GitOps-friendly)
```bash
# Install sealed-secrets controller
helm install sealed-secrets sealed-secrets \
  --repo https://bitnami-labs.github.io/sealed-secrets \
  --namespace kube-system

# Create sealed secret
kubectl create secret generic fks-secrets \
  --from-literal=postgres-password=$(openssl rand -base64 32) \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > sealed-secret.yaml

# Commit sealed-secret.yaml to Git (safe)
```

2. **External Secrets Operator** (AWS/Azure/GCP)
3. **HashiCorp Vault**
4. **SOPS (Secrets OPerationS)**

---

## 📈 Monitoring

### Grafana Dashboards

```bash
# Get Grafana admin password
kubectl get secret fks-secrets -n fks-trading \
  -o jsonpath='{.data.grafana-admin-password}' | base64 -d

# Access Grafana
kubectl port-forward -n fks-trading svc/grafana 3000:80
# Login: admin / <password from above>
```

Pre-configured dashboards:
- **System Overview**: All services health
- **Trading Metrics**: Trades, PnL, signals
- **AI Performance**: Inference time, accuracy
- **Database**: PostgreSQL queries, connections

### Prometheus Queries

```bash
# Access Prometheus UI
kubectl port-forward -n fks-trading svc/prometheus-server 9090:80

# Example queries:
# - Pod CPU: rate(container_cpu_usage_seconds_total[5m])
# - Pod Memory: container_memory_usage_bytes
# - Request rate: rate(http_requests_total[5m])
```

---

## 🧪 Testing

### Smoke Tests

```bash
# Test health endpoints
for service in fks-main fks-api fks-app fks-ai fks-data; do
  echo "Testing $service..."
  kubectl run test-curl --rm -it --image=curlimages/curl:latest -- \
    curl -f http://$service.fks-trading.svc.cluster.local:800X/health
done

# Expected: All return HTTP 200
```

### Load Testing

```bash
# Install k6
brew install k6

# Run load test (create test script first)
k6 run tests/load/api_test.js \
  --vus 100 \
  --duration 5m
```

Example k6 script (`tests/load/api_test.js`):

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  vus: 100,
  duration: '5m',
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% < 500ms
    http_req_failed: ['rate<0.01'],   // Error rate < 1%
  },
};

export default function () {
  const res = http.get('http://fks-api.fks-trading.svc.cluster.local:8001/health');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
```

---

## 🔄 Operations

### Rolling Updates

```bash
# Update image for a service
kubectl set image deployment/fks-main \
  fks-main=fks/main:v1.1.0 \
  -n fks-trading

# Watch rollout
kubectl rollout status deployment/fks-main -n fks-trading

# Rollback if needed
kubectl rollout undo deployment/fks-main -n fks-trading
```

### Scaling

```bash
# Manual scaling
kubectl scale deployment fks-app --replicas=5 -n fks-trading

# HPA will override manual scaling, so update HPA instead:
kubectl patch hpa fks-app-hpa -n fks-trading \
  -p '{"spec":{"minReplicas":5,"maxReplicas":15}}'
```

### Database Backup

```bash
# Backup PostgreSQL
kubectl exec -n fks-trading fks-platform-postgresql-0 -- \
  pg_dump -U fks_user fks_db > backup-$(date +%Y%m%d).sql

# Restore
cat backup-20251102.sql | \
  kubectl exec -i -n fks-trading fks-platform-postgresql-0 -- \
  psql -U fks_user -d fks_db
```

---

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n fks-trading

# Check logs
kubectl logs <pod-name> -n fks-trading --previous

# Common issues:
# 1. ImagePullBackOff: Check image name/tag
# 2. CrashLoopBackOff: Check application logs
# 3. Pending: Insufficient resources
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n fks-trading

# Test from inside cluster
kubectl run test-pod --rm -it --image=busybox -- \
  wget -O- http://fks-main.fks-trading.svc.cluster.local:8000/health

# Check network policies
kubectl get networkpolicy -n fks-trading
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
kubectl run pg-test --rm -it --image=postgres:14 -- \
  psql postgresql://fks_user:PASSWORD@fks-platform-postgresql:5432/fks_db

# Test Redis connection
kubectl run redis-test --rm -it --image=redis:7 -- \
  redis-cli -h fks-platform-redis-master -a PASSWORD ping
```

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [HPA Guide](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/)

---

## ✅ Next Steps

1. ✅ Phase 8.1 Complete: K8s deployment
2. 🚧 Phase 8.2: Auto-scaling optimization
3. 🚧 Phase 8.3: Multi-region deployment
4. 🚧 Phase 8.4: Advanced monitoring

---

**Created**: November 2, 2025  
**Status**: 🚧 IN PROGRESS  
**Phase**: 8.1 - Kubernetes Migration
