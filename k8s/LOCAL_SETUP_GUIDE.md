# FKS Trading Platform - Local Kubernetes Setup Guide

This guide explains how to set up the FKS Trading Platform on a local Kubernetes cluster with automatic image pulling from Docker Hub, domain routing, and dashboard auto-login.

## 🎯 What Was Set Up

### 1. Ingress Configuration
- **fkstrading.xyz** → Routes to `fks-web` (Django Web Interface) at root path
- **dashboard.fkstrading.xyz** → Routes to Kubernetes Dashboard
- All other services accessible via subdomain or path routing

### 2. Service Deployments
All 14 FKS services are configured to pull from Docker Hub:
- `nuniesmith/fks:web-latest`
- `nuniesmith/fks:api-latest`
- `nuniesmith/fks:app-latest`
- `nuniesmith/fks:data-latest`
- `nuniesmith/fks:ai-latest`
- `nuniesmith/fks:execution-latest`
- `nuniesmith/fks:portfolio-latest`
- `nuniesmith/fks:analyze-latest`
- `nuniesmith/fks:training-latest`
- `nuniesmith/fks:monitor-latest`
- `nuniesmith/fks:auth-latest`
- `nuniesmith/fks:meta-latest`
- `nuniesmith/fks:ninja-latest`
- `nuniesmith/fks:main-latest`

### 3. Kubernetes Dashboard
- Auto-login service account created
- Token automatically generated and saved
- Ingress configured for dashboard.fkstrading.xyz

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster running (minikube, Docker Desktop, or local cluster)
- kubectl configured and connected
- NGINX Ingress Controller installed
- DNS or /etc/hosts configured for fkstrading.xyz

### Run Setup Script

```bash
cd repo/main/k8s
./setup-local-k8s.sh
```

The script will:
1. Create namespace `fks-trading`
2. Create secrets (PostgreSQL, Redis, Django)
3. Deploy infrastructure (PostgreSQL, Redis)
4. Deploy all 14 FKS services
5. Deploy ingress configuration
6. Set up Kubernetes Dashboard
7. Generate and save dashboard token

### Manual Setup (Alternative)

```bash
# 1. Create namespace
kubectl create namespace fks-trading

# 2. Create secrets
kubectl create secret generic fks-secrets \
  --from-literal=postgres-user=fks_user \
  --from-literal=postgres-password=$(openssl rand -base64 32) \
  --from-literal=redis-password=$(openssl rand -base64 32) \
  --from-literal=django-secret-key=$(openssl rand -base64 64) \
  -n fks-trading

# 3. Deploy services
kubectl apply -f manifests/all-services.yaml -n fks-trading
kubectl apply -f manifests/missing-services.yaml -n fks-trading

# 4. Deploy ingress
kubectl apply -f ingress.yaml -n fks-trading

# 5. Setup dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl apply -f manifests/dashboard-admin.yaml -n kubernetes-dashboard
kubectl apply -f manifests/dashboard-ingress.yaml
```

## 🌐 Domain Configuration

### Local Development

Add to `/etc/hosts` (Linux/Mac) or `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
127.0.0.1 fkstrading.xyz
127.0.0.1 dashboard.fkstrading.xyz
127.0.0.1 api.fkstrading.xyz
127.0.0.1 web.fkstrading.xyz
```

### Get Cluster IP

```bash
# For minikube
minikube ip

# For Docker Desktop
kubectl get ingress -n fks-trading

# For other clusters
kubectl get nodes -o wide
```

Update `/etc/hosts` with the actual cluster IP instead of 127.0.0.1.

## 📊 Access Services

### Web Interface
- **URL**: http://fkstrading.xyz
- **Service**: fks-web (Django)
- **Port**: 3001

### Kubernetes Dashboard
- **URL**: http://dashboard.fkstrading.xyz
- **Token**: Saved in `k8s/dashboard-token.txt`

To get token manually:
```bash
kubectl -n kubernetes-dashboard create token admin-user --duration=8760h
```

### Other Services
- **API**: http://api.fkstrading.xyz or http://fkstrading.xyz/api
- **App**: http://app.fkstrading.xyz or http://fkstrading.xyz/app
- **Data**: http://data.fkstrading.xyz or http://fkstrading.xyz/data
- **Portfolio**: http://fkstrading.xyz/portfolio
- **Monitor**: http://fkstrading.xyz/monitor

## 🔍 Verify Deployment

```bash
# Check all pods
kubectl get pods -n fks-trading

# Check services
kubectl get services -n fks-trading

# Check ingress
kubectl get ingress -n fks-trading

# View logs
kubectl logs -n fks-trading -l app=fks-web -f

# Check dashboard
kubectl get pods -n kubernetes-dashboard
```

## 🔧 Troubleshooting

### Services Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n fks-trading

# Check logs
kubectl logs <pod-name> -n fks-trading

# Check events
kubectl get events -n fks-trading --sort-by='.lastTimestamp'
```

### Images Not Pulling

```bash
# Check if images exist on Docker Hub
docker pull nuniesmith/fks:web-latest

# Force image pull
kubectl set image deployment/fks-web web=nuniesmith/fks:web-latest -n fks-trading
kubectl rollout restart deployment/fks-web -n fks-trading
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress status
kubectl describe ingress fks-platform-ingress -n fks-trading

# Test from inside cluster
kubectl run test-curl --rm -it --image=curlimages/curl:latest -- \
  curl http://fks-web.fks-trading.svc.cluster.local:3001/health
```

### Dashboard Token Issues

```bash
# Regenerate token
kubectl -n kubernetes-dashboard delete secret admin-user-secret
kubectl apply -f manifests/dashboard-admin.yaml -n kubernetes-dashboard
kubectl -n kubernetes-dashboard create token admin-user --duration=8760h
```

## 📝 Files Created/Updated

### Updated Files
- `ingress.yaml` - Routes fkstrading.xyz root to fks-web
- `setup-local-k8s.sh` - Complete setup script

### New Files
- `manifests/missing-services.yaml` - Missing service deployments (portfolio, monitor, auth, execution, meta, ninja, analyze, training, main)
- `manifests/dashboard-auto-login.yaml` - Dashboard auto-login configuration
- `manifests/dashboard-ingress-auto-login.yaml` - Dashboard ingress with auto-login service

## 🎯 Next Steps

1. **Update /etc/hosts** with your cluster IP
2. **Run setup script**: `./setup-local-k8s.sh`
3. **Access web interface**: http://fkstrading.xyz
4. **Access dashboard**: http://dashboard.fkstrading.xyz
5. **Monitor services**: `kubectl get pods -n fks-trading -w`

## 📚 Additional Resources

- [Kubernetes Dashboard Documentation](https://github.com/kubernetes/dashboard)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [FKS Project Context Guide](../../AI_CONTEXT_GUIDE.md)

---

**Status**: ✅ Ready for local deployment  
**Last Updated**: 2025-11-12

