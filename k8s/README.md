# FKS Trading Platform - Kubernetes

Production-grade Kubernetes deployment for the FKS Trading Platform.

**GitHub Repository**: [nuniesmith/fks_k8s](https://github.com/nuniesmith/fks_k8s)

## 📁 Structure

```
k8s/
├── charts/
│   └── fks-platform/          # Main Helm chart
│       ├── Chart.yaml         # Chart metadata
│       ├── values.yaml        # Configuration values
│       └── templates/         # K8s resource templates
│
├── manifests/                 # Raw K8s YAML files
│   ├── all-services.yaml     # All service deployments
│   ├── dashboard-admin.yaml  # Dashboard admin user
│   ├── dev-volumes.yaml      # Development volumes
│   └── ...
│
├── scripts/                   # Deployment and utility scripts
│   ├── deploy.sh             # Main deployment script
│   ├── setup-local-k8s.sh   # Local K8s setup
│   └── ...
│
└── monitoring/                # Monitoring configurations
    └── slo-rules.yaml        # SLO definitions
```

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (minikube, Docker Desktop, or cloud)
- kubectl installed
- Helm 3.x installed (optional, for Helm charts)

### Local Setup (Minikube)

```bash
# Run the setup script
./setup-local-k8s.sh

# Or manually
kubectl apply -f manifests/all-services.yaml -n fks-trading
```

### Production Deployment

```bash
# Using Helm (recommended)
helm install fks-platform ./charts/fks-platform \
  --namespace fks-trading \
  --create-namespace

# Or using kubectl
kubectl apply -f manifests/all-services.yaml -n fks-trading
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

| Service | Port | Description |
|---------|------|-------------|
| fks_main | 8010 | Main orchestration service |
| fks_api | 8001 | API gateway |
| fks_app | 8002 | Business logic service |
| fks_data | 8003 | Data service |
| fks_execution | 8004 | Execution engine |
| fks_ai | 8007 | AI/ML service |
| fks_portfolio | 8012 | Portfolio management |
| fks_web | 8000 | Web interface |

**Infrastructure**:
- PostgreSQL - StatefulSet with persistent storage
- Redis - StatefulSet with persistent storage
- Prometheus - Metrics collection
- Grafana - Monitoring dashboards

## 🔧 Configuration

### Environment Variables

Edit `manifests/secrets.yaml.template` and create your secrets:

```bash
# Create secrets
kubectl create secret generic fks-secrets \
  -n fks-trading \
  --from-literal=postgres-password=$(openssl rand -base64 32) \
  --from-literal=redis-password=$(openssl rand -base64 32)
```

### Customize Resources

Edit `manifests/all-services.yaml` or Helm values files to adjust:
- Resource limits
- Replica counts
- Environment variables
- Volume mounts

## 🌐 Access Services

### Local Development

```bash
# Port-forward to access services
kubectl port-forward -n fks-trading svc/fks-main 8010:8010
kubectl port-forward -n fks-trading svc/fks-web 8000:8000

# Access
# http://localhost:8010 - FKS Main
# http://localhost:8000 - Web UI
```

### Production (with Ingress)

The `ingress.yaml` file configures NGINX Ingress for external access.

## 📈 Monitoring

### Kubernetes Dashboard

```bash
# Access dashboard
./scripts/open-dashboard.sh

# Or manually
kubectl proxy
# Then visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### Grafana Dashboards

```bash
# Port-forward Grafana
kubectl port-forward -n fks-trading svc/grafana 3000:80
# Access: http://localhost:3000
```

## 🔐 Security

### Secrets Management

**Important**: Never commit actual secrets to git. Use:
- `secrets.yaml.template` as a reference
- Kubernetes secrets
- External secret managers (Vault, AWS Secrets Manager, etc.)

The `.gitignore` file excludes sensitive files like `dashboard-token.txt`.

## 🔄 Operations

### Update Services

```bash
# Update a specific service
kubectl set image deployment/fks-main \
  fks-main=nuniesmith/fks:main-latest \
  -n fks-trading

# Watch rollout
kubectl rollout status deployment/fks-main -n fks-trading
```

### Scale Services

```bash
# Scale a service
kubectl scale deployment fks-app --replicas=3 -n fks-trading
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

# Shell into pod
kubectl exec -it <pod-name> -n fks-trading -- /bin/bash
```

### Health Checks

```bash
# Test service from inside cluster
kubectl run test-curl --rm -it --image=curlimages/curl:latest -- \
  curl http://fks-main.fks-trading.svc.cluster.local:8010/health
```

## 📚 Documentation

- **Local Setup Guide**: [LOCAL_SETUP_GUIDE.md](LOCAL_SETUP_GUIDE.md)
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Testing Guide**: [TESTING.md](TESTING.md)
- **Deployment Fixes**: [K8S_DEPLOYMENT_FIXES.md](K8S_DEPLOYMENT_FIXES.md)

## 🗑️ Cleanup

### Uninstall

```bash
# Delete all resources
kubectl delete -f manifests/all-services.yaml -n fks-trading

# Or delete namespace (removes everything)
kubectl delete namespace fks-trading
```

---

**Repository**: [nuniesmith/fks_k8s](https://github.com/nuniesmith/fks_k8s)  
**Status**: ✅ Production Ready  
**Last Updated**: 2025-11-12
