# FKS Trading Platform - Kubernetes

Production-grade Kubernetes deployment for the FKS Trading Platform.

## 📁 Structure

```
k8s/
├── charts/
│   └── fks-platform/          # Main Helm chart
│       ├── Chart.yaml         # Chart metadata
│       ├── values.yaml        # Configuration values
│       └── templates/         # K8s resource templates
│           ├── deployment.yaml      # All 8 microservices
│           ├── service.yaml         # Service definitions
│           ├── hpa.yaml             # Horizontal Pod Autoscalers
│           ├── ingress.yaml         # NGINX Ingress
│           ├── configmap.yaml       # Configuration
│           └── secrets.yaml         # Secret templates
│
├── manifests/                 # Raw K8s YAML files (future)
│   └── (for kubectl apply -f)
│
└── scripts/
    └── deploy.sh              # Automated deployment script
```

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (minikube, Docker Desktop, or cloud)
- kubectl installed
- Helm 3.x installed

### Deploy Everything

```bash
# One-command deployment
./k8s/scripts/deploy.sh deploy

# Or step-by-step
kubectl create namespace fks-trading
helm install fks-platform ./k8s/charts/fks-platform \
  --namespace fks-trading \
  --create-namespace
```

### Verify Deployment

```bash
# Check all resources
kubectl get all -n fks-trading

# Check pod status
kubectl get pods -n fks-trading

# View logs
kubectl logs -n fks-trading -l app=fks-main -f
```

## 📊 Services Deployed

| Service | Port | Replicas | Auto-Scaling |
|---------|------|----------|--------------|
| fks_main | 8000 | 2 | 2-10 (HPA) |
| fks_api | 8001 | 2 | 2-8 (HPA) |
| fks_app | 8002 | 2 | 2-8 (HPA) |
| fks_ai | 8007 | 1 | 1-10 (HPA + GPU) |
| fks_data | 8003 | 2 | 2-4 (HPA) |
| fks_execution | 8004 | 1 | VPA (vertical) |
| fks_ninja | 8005 | 1 | Manual |
| fks_mt5 | 8006 | 1 | Manual |
| fks_web | 3001 | 2 | Manual |

**Infrastructure**:
- PostgreSQL (TimescaleDB) - StatefulSet with HA
- Redis + Sentinel - StatefulSet with HA
- Prometheus - Metrics collection
- Grafana - Monitoring dashboards

## 🔧 Configuration

### Customize Resources

Edit `k8s/charts/fks-platform/values.yaml`:

```yaml
# Example: Scale AI service
fks_ai:
  replicaCount: 3
  resources:
    limits:
      cpu: 8000m
      memory: 16Gi
```

Apply changes:

```bash
helm upgrade fks-platform ./k8s/charts/fks-platform \
  -n fks-trading \
  -f k8s/charts/fks-platform/values.yaml
```

### Environment-Specific Values

Create environment-specific files:

```bash
# Production
k8s/charts/fks-platform/values-prod.yaml

# Staging
k8s/charts/fks-platform/values-staging.yaml

# Deploy with specific values
helm install fks-platform ./k8s/charts/fks-platform \
  -n fks-trading \
  -f k8s/charts/fks-platform/values-prod.yaml
```

## 🌐 Access Services

### Local Development

```bash
# Port-forward to access services
kubectl port-forward -n fks-trading svc/fks-main 8000:8000
kubectl port-forward -n fks-trading svc/fks-web 3001:3001
kubectl port-forward -n fks-trading svc/grafana 3000:80

# Access
# http://localhost:8000 - FKS Main
# http://localhost:3001 - Web UI
# http://localhost:3000 - Grafana
```

### Production (with Ingress)

```bash
# Get external IP
kubectl get ingress -n fks-trading

# Access via domain (after DNS setup)
# https://fks-trading.com
# https://api.fks-trading.com
# https://web.fks-trading.com
```

## 📈 Monitoring

### Grafana Dashboards

```bash
# Get admin password
kubectl get secret fks-secrets -n fks-trading \
  -o jsonpath='{.data.grafana-admin-password}' | base64 -d

# Access Grafana
kubectl port-forward -n fks-trading svc/grafana 3000:80
# Login: admin / <password>
```

### Prometheus Metrics

```bash
# Access Prometheus
kubectl port-forward -n fks-trading svc/prometheus-server 9090:80
# http://localhost:9090
```

## 🔐 Security

### Secrets Management

```bash
# View secrets (encoded)
kubectl get secret fks-secrets -n fks-trading -o yaml

# Create/update secrets
kubectl create secret generic fks-secrets \
  -n fks-trading \
  --from-literal=postgres-password=$(openssl rand -base64 32) \
  --from-literal=redis-password=$(openssl rand -base64 32) \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new secrets
kubectl rollout restart deployment -n fks-trading
```

**Production**: Use sealed-secrets, external-secrets, or Vault instead of plain secrets.

## 🔄 Operations

### Scale Services

```bash
# Manual scaling
kubectl scale deployment fks-app --replicas=5 -n fks-trading

# Update HPA
kubectl patch hpa fks-app-hpa -n fks-trading \
  -p '{"spec":{"minReplicas":5}}'
```

### Rolling Updates

```bash
# Update image
kubectl set image deployment/fks-main \
  fks-main=fks/main:v1.1.0 \
  -n fks-trading

# Watch rollout
kubectl rollout status deployment/fks-main -n fks-trading

# Rollback
kubectl rollout undo deployment/fks-main -n fks-trading
```

### Backup Database

```bash
# PostgreSQL backup
kubectl exec -n fks-trading fks-platform-postgresql-0 -- \
  pg_dump -U fks_user fks_db > backup-$(date +%Y%m%d).sql
```

## 🐛 Troubleshooting

### Common Commands

```bash
# Check pod status
kubectl get pods -n fks-trading

# Describe pod (shows events)
kubectl describe pod <pod-name> -n fks-trading

# View logs
kubectl logs <pod-name> -n fks-trading

# Previous logs (if crashed)
kubectl logs <pod-name> -n fks-trading --previous

# Shell into pod
kubectl exec -it <pod-name> -n fks-trading -- /bin/bash

# Delete and recreate pod
kubectl delete pod <pod-name> -n fks-trading
```

### Health Checks

```bash
# Test service from inside cluster
kubectl run test-curl --rm -it --image=curlimages/curl:latest -- \
  curl http://fks-main.fks-trading.svc.cluster.local:8000/health
```

## 🗑️ Cleanup

### Uninstall

```bash
# Uninstall Helm release
helm uninstall fks-platform -n fks-trading

# Delete namespace (removes everything)
kubectl delete namespace fks-trading

# Or use the script
./k8s/scripts/deploy.sh uninstall
```

## 📚 Documentation

- **Deployment Guide**: [docs/K8S_DEPLOYMENT_GUIDE.md](../docs/K8S_DEPLOYMENT_GUIDE.md)
- **Phase 8 Plan**: [docs/PHASE_8_PRODUCTION_SCALING.md](../docs/PHASE_8_PRODUCTION_SCALING.md)
- **Helm Chart**: [charts/fks-platform/README.md](charts/fks-platform/README.md)

## ✅ Next Steps

- [x] Phase 8.1: Kubernetes Migration (THIS)
- [ ] Phase 8.2: Auto-Scaling Optimization
- [ ] Phase 8.3: Multi-Region Deployment
- [ ] Phase 8.4: Advanced Monitoring (Jaeger, ELK)
- [ ] Phase 8.5: TimeCopilot Integration

---

**Created**: November 2, 2025  
**Phase**: 8.1 - Kubernetes Migration  
**Status**: 🚧 IN PROGRESS
