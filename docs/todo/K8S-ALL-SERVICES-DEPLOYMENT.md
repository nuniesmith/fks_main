# Kubernetes - All 14 Services Deployment Guide

**Date**: 2025-11-12  
**Status**: ✅ **READY TO DEPLOY**  
**Purpose**: Deploy all 14 FKS services to Kubernetes and ensure they're running healthily

---

## 🎯 Overview

This guide shows you how to deploy all 14 FKS services to Kubernetes and ensure they're all running and healthy.

---

## 📋 Expected Services (14 Total)

### Core Services
1. **fks_main** - Main orchestrator (Django, port 8000/8010)
2. **fks_api** - API gateway (FastAPI, port 8001)
3. **fks_app** - Application service (FastAPI, port 8002)
4. **fks_data** - Data service (Flask, port 8003)
5. **fks_auth** - Authentication service (FastAPI, port 8009)
6. **fks_portfolio** - Portfolio service (FastAPI, port 8010)
7. **fks_monitor** - Monitoring service (FastAPI, port 8011)
8. **fks_meta** - Metadata service (FastAPI, port 8005)
9. **fks_analyze** - Analysis service (FastAPI, port 8008)
10. **fks_training** - Training service (FastAPI, port 8012)

### Additional Services
11. **fks_ai** - AI/ML service (FastAPI, port 8007) - *Disabled (requires GPU)*
12. **fks_execution** - Execution service (Rust, port 8004) - *Enabled (may have issues)*
13. **fks_web** - Web UI (Django, port 3001) - *Enabled*
14. **fks_ninja** - NinjaTrader service (C#, port 8005) - *Disabled (no Docker image)*

### Infrastructure Services
- **PostgreSQL** - Database (TimescaleDB)
- **Redis** - Cache and message broker

---

## 🚀 Quick Deployment

### Step 1: Deploy All Services

```bash
cd repo/main
./scripts/deploy-all-14-services.sh
```

This script will:
1. ✅ Check prerequisites (kubectl, helm)
2. ✅ Start Kubernetes cluster (minikube) if not running
3. ✅ Install NGINX Ingress Controller (if needed)
4. ✅ Apply ingress configuration for fkstrading.xyz
5. ✅ Deploy all services via Helm
6. ✅ Wait for pods to be ready
7. ✅ Check pod and service health
8. ✅ Fix common issues
9. ✅ Test service endpoints

### Step 2: Verify Deployment

```bash
# Check pod status
kubectl get pods -n fks-trading

# Check service status
kubectl get svc -n fks-trading

# Check deployment status
kubectl get deployments -n fks-trading

# Check ingress status
kubectl get ingress -n fks-trading
```

### Step 3: Set Up Minikube Tunnel (Required)

**Important**: Run this in a separate terminal and keep it running:

```bash
minikube tunnel
```

This exposes the ingress controller to your Tailscale IP (100.80.141.117).

---

## 📊 Service Status

### Currently Enabled in Helm Chart
- ✅ **fks_main** - Main orchestrator
- ✅ **fks_api** - API gateway
- ✅ **fks_app** - Application service
- ✅ **fks_data** - Data service
- ✅ **fks_execution** - Execution service
- ✅ **fks_web** - Web UI
- ✅ **postgresql** - Database
- ✅ **redis** - Cache

### Currently Disabled
- ❌ **fks_ai** - AI/ML service (requires GPU)
- ❌ **fks_ninja** - NinjaTrader service (no Docker image, C# app)

### Not Yet in Helm Chart
- ⚠️ **fks_auth** - Authentication service
- ⚠️ **fks_portfolio** - Portfolio service
- ⚠️ **fks_monitor** - Monitoring service
- ⚠️ **fks_meta** - Metadata service
- ⚠️ **fks_analyze** - Analysis service
- ⚠️ **fks_training** - Training service

---

## 🔧 Service Configuration

### Service Ports
- **fks_main**: 8000/8010
- **fks_api**: 8001
- **fks_app**: 8002
- **fks_data**: 8003
- **fks_execution**: 8004
- **fks_meta**: 8005
- **fks_ai**: 8007
- **fks_analyze**: 8008
- **fks_auth**: 8009
- **fks_portfolio**: 8010
- **fks_monitor**: 8011
- **fks_training**: 8012
- **fks_web**: 3001

### Service Dependencies
- **fks_app** depends on: fks_data, fks_api
- **fks_api** depends on: fks_data, fks_auth
- **fks_execution** depends on: fks_api, fks_data
- **fks_meta** depends on: fks_execution, fks_data
- **fks_analyze** depends on: fks_data, fks_ai
- **fks_portfolio** depends on: fks_api, fks_data
- **fks_monitor** depends on: fks_api, fks_data
- **fks_training** depends on: fks_data, fks_ai

---

## 🧪 Testing Services

### Test Health Endpoints

```bash
# Port-forward services
kubectl port-forward -n fks-trading svc/fks-app 8002:8002 &
kubectl port-forward -n fks-trading svc/fks-data 8003:8003 &
kubectl port-forward -n fks-trading svc/fks-main 8000:8000 &
kubectl port-forward -n fks-trading svc/fks-api 8001:8001 &

# Test health endpoints
curl http://localhost:8002/health  # fks_app
curl http://localhost:8003/health  # fks_data
curl http://localhost:8000/health  # fks_main
curl http://localhost:8001/health  # fks_api
```

### Test Bitcoin Signal Generation

```bash
# Test signal generation
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
```

---

## 🔧 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n fks-trading

# Check pod events
kubectl describe pod <pod-name> -n fks-trading

# Check pod logs
kubectl logs <pod-name> -n fks-trading

# Check all pod logs
kubectl logs -n fks-trading --all-containers=true --tail=50
```

### ImagePullBackOff

```bash
# Check if images exist
docker pull nuniesmith/fks:app-latest
docker pull nuniesmith/fks:data-latest
docker pull nuniesmith/fks:main-latest

# If using minikube, load images into minikube
minikube image load nuniesmith/fks:app-latest
minikube image load nuniesmith/fks:data-latest
minikube image load nuniesmith/fks:main-latest
```

### CrashLoopBackOff

```bash
# Check pod logs
kubectl logs <pod-name> -n fks-trading

# Check pod events
kubectl describe pod <pod-name> -n fks-trading

# Check resource limits
kubectl describe pod <pod-name> -n fks-trading | grep -A 5 "Limits"
```

### Services Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n fks-trading

# Check service details
kubectl describe svc <service-name> -n fks-trading

# Check ingress
kubectl get ingress -n fks-trading
kubectl describe ingress -n fks-trading
```

---

## 📋 Health Checks

### Pod Health

```bash
# Check all pods
kubectl get pods -n fks-trading

# Check pod health
kubectl get pods -n fks-trading -o wide

# Check pod status
kubectl get pods -n fks-trading -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

### Service Health

```bash
# Check all services
kubectl get svc -n fks-trading

# Check service endpoints
kubectl get endpoints -n fks-trading

# Check service details
kubectl describe svc -n fks-trading
```

### Deployment Health

```bash
# Check all deployments
kubectl get deployments -n fks-trading

# Check deployment status
kubectl get deployments -n fks-trading -o wide

# Check deployment details
kubectl describe deployment -n fks-trading
```

---

## 🚀 Quick Commands

### Deploy All Services
```bash
cd repo/main
./scripts/deploy-all-14-services.sh
```

### Check Status
```bash
# Pod status
kubectl get pods -n fks-trading

# Service status
kubectl get svc -n fks-trading

# Deployment status
kubectl get deployments -n fks-trading

# Ingress status
kubectl get ingress -n fks-trading
```

### View Logs
```bash
# View logs for all pods
kubectl logs -n fks-trading --all-containers=true -f

# View logs for specific service
kubectl logs -n fks-trading -l app=fks-app -f
kubectl logs -n fks-trading -l app=fks-data -f
kubectl logs -n fks-trading -l app=fks-main -f
```

### Port-Forward Services
```bash
# Port-forward all services
kubectl port-forward -n fks-trading svc/fks-app 8002:8002 &
kubectl port-forward -n fks-trading svc/fks-data 8003:8003 &
kubectl port-forward -n fks-trading svc/fks-main 8000:8000 &
kubectl port-forward -n fks-trading svc/fks-api 8001:8001 &
```

### Restart Services
```bash
# Restart all deployments
kubectl rollout restart deployment -n fks-trading

# Restart specific deployment
kubectl rollout restart deployment/fks-app -n fks-trading
kubectl rollout restart deployment/fks-data -n fks-trading
```

---

## 📚 Documentation

### Related Guides
- `BITCOIN-FKSTRADING-DEPLOYMENT-READY.md` - Domain deployment guide
- `K8S-DASHBOARD-SETUP.md` - Kubernetes dashboard setup
- `BITCOIN-K8S-QUICK-START.md` - Kubernetes quick start

### API Documentation
- Signal Generation API: http://app.fkstrading.xyz/docs
- Data API: http://data.fkstrading.xyz/docs
- Main API: http://fkstrading.xyz/docs

---

## 🎉 Summary

### Complete Workflow
1. **Deploy All Services**: Run `./scripts/deploy-all-14-services.sh`
2. **Set Up Tunnel**: Run `minikube tunnel` in a separate terminal
3. **Verify Deployment**: Check pod, service, and deployment status
4. **Test Services**: Test health endpoints and signal generation
5. **Monitor Health**: Use Kubernetes dashboard to monitor services

### Services Deployed
- ✅ **fks_main** - Main orchestrator
- ✅ **fks_api** - API gateway
- ✅ **fks_app** - Application service
- ✅ **fks_data** - Data service
- ✅ **fks_execution** - Execution service
- ✅ **fks_web** - Web UI
- ✅ **PostgreSQL** - Database
- ✅ **Redis** - Cache

### Services to Add
- ⚠️ **fks_auth** - Authentication service
- ⚠️ **fks_portfolio** - Portfolio service
- ⚠️ **fks_monitor** - Monitoring service
- ⚠️ **fks_meta** - Metadata service
- ⚠️ **fks_analyze** - Analysis service
- ⚠️ **fks_training** - Training service

---

**Status**: ✅ **READY TO DEPLOY**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/deploy-all-14-services.sh` and then `minikube tunnel`!

---

**Happy Trading!** 🚀

