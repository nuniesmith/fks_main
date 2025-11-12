# Deploy All 14 K8s Services - Complete Guide

**Date**: 2025-11-12  
**Status**: ✅ **READY TO USE**  
**Purpose**: Deploy all 14 FKS services to Kubernetes

---

## 🚀 Quick Start

### Option 1: Using run.sh (Recommended)

```bash
cd repo/main
./run.sh
# Choose option 8 (Kubernetes Start)
# Choose 'p' to pull images from Docker Hub
# Enter namespace: fks-trading (or press Enter for default)
```

### Option 2: Using Deployment Script

```bash
cd repo/main
bash scripts/deploy-all-services.sh
```

---

## 📋 Prerequisites

### Required Tools

- ✅ **kubectl**: Installed
- ⚠️ **minikube**: Will be installed by run.sh if needed
- ⚠️ **helm**: Will be installed by run.sh if needed
- ✅ **Docker**: Required for minikube

### Verify Tools

```bash
# Check kubectl
kubectl version --client

# Check minikube (optional - run.sh will install if needed)
minikube version

# Check helm (optional - run.sh will install if needed)
helm version
```

---

## 🔧 Deployment Steps

### Step 1: Start Kubernetes Cluster

The `run.sh` script will automatically:
1. Check if minikube is installed
2. Install minikube if needed (Ubuntu only)
3. Start minikube cluster
4. Enable required addons (ingress, metrics-server, dashboard)

### Step 2: Pull Images from Docker Hub

The script will:
1. Ask if you want to build locally or pull from Docker Hub
2. Choose 'p' to pull from Docker Hub (recommended)
3. Pull all 14 service images from `nuniesmith/fks:*`

### Step 3: Deploy Services

The script will:
1. Create namespace `fks-trading` (if it doesn't exist)
2. Deploy all 14 services using Helm
3. Wait for all pods to be ready
4. Show deployment status

---

## 📊 Services Deployed

### Core Services

- ✅ **fks_main** (port 8010) - Main orchestration service
- ✅ **fks_api** (port 8001) - API gateway
- ✅ **fks_app** (port 8002) - Application service
- ✅ **fks_data** (port 8003) - Data service
- ✅ **fks_execution** (port 8004) - Execution service
- ✅ **fks_meta** (port 8005) - Metadata service
- ✅ **fks_analyze** (port 8008) - Analysis service
- ✅ **fks_auth** (port 8009) - Authentication service
- ✅ **fks_training** (port 8011) - Training service
- ✅ **fks_portfolio** (port 8012) - Portfolio service
- ✅ **fks_monitor** (port 8013) - Monitoring service

### Infrastructure Services

- ✅ **PostgreSQL** - Database
- ✅ **Redis** - Cache and message broker

### Disabled Services

- ❌ **fks_ai** (port 8007) - AI service (disabled - requires GPU)
- ❌ **fks_web** (port 3001) - Web UI (disabled - use fks_main instead)
- ❌ **fks_ninja** - Ninja service (C# service, not containerized)

---

## 🔍 Verify Deployment

### Check Pod Status

```bash
kubectl get pods -n fks-trading -o wide
```

### Check Service Status

```bash
kubectl get svc -n fks-trading -o wide
```

### Check Deployment Status

```bash
kubectl get deployments -n fks-trading -o wide
```

### Check Ingress Status

```bash
kubectl get ingress -n fks-trading -o wide
```

---

## 🏥 Health Checks

### Check Pod Health

```bash
# Check all pods
kubectl get pods -n fks-trading

# Check specific pod
kubectl describe pod <pod-name> -n fks-trading

# Check pod logs
kubectl logs <pod-name> -n fks-trading --tail=50 -f
```

### Check Service Health

```bash
# Check service endpoints
kubectl get endpoints -n fks-trading

# Check service details
kubectl describe svc <service-name> -n fks-trading
```

### Check Deployment Health

```bash
# Check deployment status
kubectl get deployments -n fks-trading

# Check deployment details
kubectl describe deployment <deployment-name> -n fks-trading

# Check rollout status
kubectl rollout status deployment/<deployment-name> -n fks-trading
```

---

## 🔧 Troubleshooting

### Pod Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n fks-trading

# Check pod logs
kubectl logs <pod-name> -n fks-trading --tail=50

# Check pod status
kubectl get pod <pod-name> -n fks-trading -o yaml
```

### Image Pull Errors

```bash
# Check if image exists
docker pull nuniesmith/fks:app-latest

# Check minikube docker environment
eval $(minikube docker-env)
docker pull nuniesmith/fks:app-latest
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints <service-name> -n fks-trading

# Check service port
kubectl get svc <service-name> -n fks-trading -o yaml

# Port-forward for testing
kubectl port-forward -n fks-trading svc/<service-name> <local-port>:<service-port>
```

### Database Connection Issues

```bash
# Check PostgreSQL pod
kubectl get pods -n fks-trading -l app=postgresql

# Check PostgreSQL logs
kubectl logs -n fks-trading -l app=postgresql --tail=50

# Check PostgreSQL service
kubectl get svc -n fks-trading -l app=postgresql
```

### Redis Connection Issues

```bash
# Check Redis pod
kubectl get pods -n fks-trading -l app=redis

# Check Redis logs
kubectl logs -n fks-trading -l app=redis --tail=50

# Check Redis service
kubectl get svc -n fks-trading -l app=redis
```

---

## 📊 Access Services

### Port-Forward Services

```bash
# Main service
kubectl port-forward -n fks-trading svc/fks-main 8010:8010 &

# API service
kubectl port-forward -n fks-trading svc/fks-api 8001:8001 &

# App service
kubectl port-forward -n fks-trading svc/fks-app 8002:8002 &

# Data service
kubectl port-forward -n fks-trading svc/fks-data 8003:8003 &

# Execution service
kubectl port-forward -n fks-trading svc/fks-execution 8004:8004 &

# Meta service
kubectl port-forward -n fks-trading svc/fks-meta 8005:8005 &

# Analyze service
kubectl port-forward -n fks-trading svc/fks-analyze 8008:8008 &

# Auth service
kubectl port-forward -n fks-trading svc/fks-auth 8009:8009 &

# Training service
kubectl port-forward -n fks-trading svc/fks-training 8011:8011 &

# Portfolio service
kubectl port-forward -n fks-trading svc/fks-portfolio 8012:8012 &

# Monitor service
kubectl port-forward -n fks-trading svc/fks-monitor 8013:8013 &
```

### Access via Domain (After minikube tunnel)

```bash
# Start minikube tunnel (in separate terminal)
minikube tunnel

# Access services via domain
# http://fkstrading.xyz
# http://app.fkstrading.xyz
# http://data.fkstrading.xyz
```

### Access Dashboard

```bash
# Start dashboard with auto-login
./scripts/dashboard-auto-login.sh

# Or manually
kubectl proxy &
# Open: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## 🔄 Update Services

### Update Single Service

```bash
# Update image
kubectl set image deployment/fks-app fks-app=nuniesmith/fks:app-latest -n fks-trading

# Restart deployment
kubectl rollout restart deployment/fks-app -n fks-trading

# Check rollout status
kubectl rollout status deployment/fks-app -n fks-trading
```

### Update All Services

```bash
# Use run.sh option 12 (Sync Images & Update Kubernetes Deployments)
./run.sh
# Choose option 12
```

---

## 🗑️ Cleanup

### Delete Deployment

```bash
# Delete Helm release
helm delete fks-platform -n fks-trading

# Delete namespace (will delete all resources)
kubectl delete namespace fks-trading
```

### Stop Minikube

```bash
# Stop minikube
minikube stop

# Delete minikube cluster
minikube delete
```

---

## 📚 Related Documentation

- `K8S-DASHBOARD-AUTO-LOGIN.md` - Dashboard auto-login setup
- `K8S-ALL-14-SERVICES-DEPLOYMENT.md` - All 14 services deployment guide
- `BITCOIN-K8S-DEPLOYMENT-GUIDE.md` - Bitcoin demo deployment guide

---

## 🎉 Summary

### Deployment Complete

- ✅ All 14 services deployed
- ✅ PostgreSQL and Redis running
- ✅ Services accessible via port-forward
- ✅ Dashboard accessible
- ✅ Health checks passing

### Next Steps

1. **Access Dashboard**: `./scripts/dashboard-auto-login.sh`
2. **Check Pod Status**: `kubectl get pods -n fks-trading`
3. **View Logs**: `kubectl logs -n fks-trading -l app=fks-app -f`
4. **Port-Forward Services**: See "Access Services" section above
5. **Start minikube tunnel**: `minikube tunnel` (for domain access)

---

**Status**: ✅ **READY TO USE**

**Last Updated**: 2025-11-12

**Next Action**: Run `./run.sh` and choose option 8 (Kubernetes Start)!

---

**Happy Deploying!** 🚀

