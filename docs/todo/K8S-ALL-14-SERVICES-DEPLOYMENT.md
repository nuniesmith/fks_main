# Kubernetes - All 14 Services Deployment Guide

**Date**: 2025-11-12  
**Status**: ✅ **READY TO DEPLOY**  
**Purpose**: Deploy all 14 FKS services to Kubernetes and ensure they're running healthily

---

## 🎯 Overview

This guide shows you how to deploy all 14 FKS services to Kubernetes and ensure they're all running and healthy.

---

## 📋 All 14 Services

### Core Services
1. **fks_main** - Main orchestrator (Django, port 8000)
2. **fks_api** - API gateway (FastAPI, port 8001)
3. **fks_app** - Application service (FastAPI, port 8002)
4. **fks_data** - Data service (Flask, port 8003)
5. **fks_execution** - Execution service (Rust, port 8004)
6. **fks_meta** - Metadata service (Rust, port 8005)
7. **fks_ai** - AI/ML service (FastAPI, port 8007) - *Disabled (requires GPU)*
8. **fks_analyze** - Analysis service (FastAPI, port 8008)
9. **fks_auth** - Authentication service (Rust, port 8009)
10. **fks_training** - Training service (FastAPI, port 8011)
11. **fks_portfolio** - Portfolio service (FastAPI, port 8012)
12. **fks_monitor** - Monitoring service (FastAPI, port 8013)
13. **fks_web** - Web UI (Django, port 3001) - *Disabled (use fks_main instead)*
14. **fks_ninja** - NinjaTrader service (C#, port 8005) - *Disabled (no Docker image)*

### Infrastructure Services
- **PostgreSQL** - Database (TimescaleDB)
- **Redis** - Cache and message broker

---

## 🚀 Quick Deployment

### Step 1: Review and Deploy All Services

```bash
cd repo/main
./scripts/review-deploy-all-services.sh
```

This script will:
1. ✅ Check prerequisites (kubectl, helm)
2. ✅ Start Kubernetes cluster (minikube) if not running
3. ✅ Install NGINX Ingress Controller (if needed)
4. ✅ Apply ingress configuration for fkstrading.xyz
5. ✅ Review current deployment status
6. ✅ Deploy all 14 services via Helm
7. ✅ Wait for pods to be ready
8. ✅ Check pod and service health
9. ✅ Fix common issues
10. ✅ Show comprehensive summary

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
- ✅ **fks_main** - Main orchestrator (port 8000)
- ✅ **fks_api** - API gateway (port 8001)
- ✅ **fks_app** - Application service (port 8002)
- ✅ **fks_data** - Data service (port 8003)
- ✅ **fks_execution** - Execution service (port 8004)
- ✅ **fks_meta** - Metadata service (port 8005)
- ✅ **fks_analyze** - Analysis service (port 8008)
- ✅ **fks_auth** - Authentication service (port 8009)
- ✅ **fks_training** - Training service (port 8011)
- ✅ **fks_portfolio** - Portfolio service (port 8012)
- ✅ **fks_monitor** - Monitoring service (port 8013)
- ✅ **postgresql** - Database
- ✅ **redis** - Cache

### Currently Disabled
- ❌ **fks_ai** - AI/ML service (requires GPU)
- ❌ **fks_web** - Web UI (use fks_main instead)
- ❌ **fks_ninja** - NinjaTrader service (no Docker image, C# app)

---

## 🔧 Service Configuration

### Service Ports
- **fks_main**: 8000
- **fks_api**: 8001
- **fks_app**: 8002
- **fks_data**: 8003
- **fks_execution**: 8004
- **fks_meta**: 8005
- **fks_ai**: 8007 (disabled)
- **fks_analyze**: 8008
- **fks_auth**: 8009
- **fks_training**: 8011
- **fks_portfolio**: 8012
- **fks_monitor**: 8013
- **fks_web**: 3001 (disabled)
- **fks_ninja**: 8005 (disabled)

### Service Dependencies
- **fks_app** depends on: fks_data, fks_api
- **fks_api** depends on: fks_data, fks_auth
- **fks_execution** depends on: fks_api, fks_data
- **fks_meta** depends on: fks_execution, fks_data
- **fks_analyze** depends on: fks_data, fks_ai
- **fks_portfolio** depends on: fks_data, fks_ai
- **fks_monitor** depends on: all services
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
kubectl port-forward -n fks-trading svc/fks-auth 8009:8009 &
kubectl port-forward -n fks-trading svc/fks-portfolio 8012:8012 &
kubectl port-forward -n fks-trading svc/fks-monitor 8013:8013 &
kubectl port-forward -n fks-trading svc/fks-meta 8005:8005 &
kubectl port-forward -n fks-trading svc/fks-analyze 8008:8008 &
kubectl port-forward -n fks-trading svc/fks-training 8011:8011 &

# Test health endpoints
curl http://localhost:8002/health  # fks_app
curl http://localhost:8003/health  # fks_data
curl http://localhost:8000/health  # fks_main
curl http://localhost:8001/health  # fks_api
curl http://localhost:8009/health  # fks_auth
curl http://localhost:8012/health  # fks_portfolio
curl http://localhost:8013/health  # fks_monitor
curl http://localhost:8005/health  # fks_meta
curl http://localhost:8008/health  # fks_analyze
curl http://localhost:8011/health  # fks_training
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
docker pull nuniesmith/fks:auth-latest
docker pull nuniesmith/fks:portfolio-latest
docker pull nuniesmith/fks:monitor-latest
docker pull nuniesmith/fks:meta-latest
docker pull nuniesmith/fks:analyze-latest
docker pull nuniesmith/fks:training-latest

# If using minikube, load images into minikube
minikube image load nuniesmith/fks:app-latest
minikube image load nuniesmith/fks:data-latest
minikube image load nuniesmith/fks:main-latest
minikube image load nuniesmith/fks:auth-latest
minikube image load nuniesmith/fks:portfolio-latest
minikube image load nuniesmith/fks:monitor-latest
minikube image load nuniesmith/fks:meta-latest
minikube image load nuniesmith/fks:analyze-latest
minikube image load nuniesmith/fks:training-latest
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
./scripts/review-deploy-all-services.sh
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
kubectl logs -n fks-trading -l app=fks-api -f
kubectl logs -n fks-trading -l app=fks-auth -f
kubectl logs -n fks-trading -l app=fks-portfolio -f
kubectl logs -n fks-trading -l app=fks-monitor -f
kubectl logs -n fks-trading -l app=fks-meta -f
kubectl logs -n fks-trading -l app=fks-analyze -f
kubectl logs -n fks-trading -l app=fks-training -f
```

### Port-Forward Services
```bash
# Port-forward all services
kubectl port-forward -n fks-trading svc/fks-app 8002:8002 &
kubectl port-forward -n fks-trading svc/fks-data 8003:8003 &
kubectl port-forward -n fks-trading svc/fks-main 8000:8000 &
kubectl port-forward -n fks-trading svc/fks-api 8001:8001 &
kubectl port-forward -n fks-trading svc/fks-auth 8009:8009 &
kubectl port-forward -n fks-trading svc/fks-portfolio 8012:8012 &
kubectl port-forward -n fks-trading svc/fks-monitor 8013:8013 &
kubectl port-forward -n fks-trading svc/fks-meta 8005:8005 &
kubectl port-forward -n fks-trading svc/fks-analyze 8008:8008 &
kubectl port-forward -n fks-trading svc/fks-training 8011:8011 &
```

### Restart Services
```bash
# Restart all deployments
kubectl rollout restart deployment -n fks-trading

# Restart specific deployment
kubectl rollout restart deployment/fks-app -n fks-trading
kubectl rollout restart deployment/fks-data -n fks-trading
kubectl rollout restart deployment/fks-main -n fks-trading
```

---

## 📚 Documentation

### Related Guides
- `BITCOIN-FKSTRADING-DEPLOYMENT-READY.md` - Domain deployment guide
- `K8S-DASHBOARD-SETUP.md` - Kubernetes dashboard setup
- `BITCOIN-K8S-QUICK-START.md` - Kubernetes quick start
- `K8S-ALL-SERVICES-DEPLOYMENT.md` - All services deployment guide

### API Documentation
- Signal Generation API: http://app.fkstrading.xyz/docs
- Data API: http://data.fkstrading.xyz/docs
- Main API: http://fkstrading.xyz/docs
- Auth API: http://auth.fkstrading.xyz/docs
- Portfolio API: http://portfolio.fkstrading.xyz/docs
- Monitor API: http://monitor.fkstrading.xyz/docs

---

## 🎉 Summary

### Complete Workflow
1. **Review and Deploy All Services**: Run `./scripts/review-deploy-all-services.sh`
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
- ✅ **fks_meta** - Metadata service
- ✅ **fks_analyze** - Analysis service
- ✅ **fks_auth** - Authentication service
- ✅ **fks_training** - Training service
- ✅ **fks_portfolio** - Portfolio service
- ✅ **fks_monitor** - Monitoring service
- ✅ **PostgreSQL** - Database
- ✅ **Redis** - Cache

### Services Disabled
- ❌ **fks_ai** - AI/ML service (requires GPU)
- ❌ **fks_web** - Web UI (use fks_main instead)
- ❌ **fks_ninja** - NinjaTrader service (no Docker image, C# app)

### Domain Configuration
- ✅ **Main Domain**: fkstrading.xyz
- ✅ **API Subdomain**: api.fkstrading.xyz
- ✅ **App Subdomain**: app.fkstrading.xyz
- ✅ **Data Subdomain**: data.fkstrading.xyz
- ✅ **Auth Subdomain**: auth.fkstrading.xyz
- ✅ **Portfolio Subdomain**: portfolio.fkstrading.xyz
- ✅ **Monitor Subdomain**: monitor.fkstrading.xyz
- ✅ **Meta Subdomain**: meta.fkstrading.xyz
- ✅ **Analyze Subdomain**: analyze.fkstrading.xyz
- ✅ **Training Subdomain**: training.fkstrading.xyz
- ✅ **Execution Subdomain**: execution.fkstrading.xyz
- ✅ **Tailscale IP**: 100.80.141.117

---

**Status**: ✅ **READY TO DEPLOY**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/review-deploy-all-services.sh` and then `minikube tunnel`!

---

**Happy Trading!** 🚀

