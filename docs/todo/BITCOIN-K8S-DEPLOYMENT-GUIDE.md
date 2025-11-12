# Bitcoin Signal Demo - Kubernetes Deployment Guide

**Date**: 2025-11-12  
**Status**: ✅ **READY TO DEPLOY**  
**Purpose**: Deploy Bitcoin Signal Demo to Kubernetes and test through web interface

---

## 🎯 Overview

This guide shows you how to deploy the Bitcoin Signal Demo to Kubernetes and test it through the FKS web interface. The deployment uses images from DockerHub (`nuniesmith/fks`) and sets up port-forwarding for local access.

---

## 🚀 Quick Start

### Option 1: Automated Script (Recommended)

```bash
cd repo/main
./scripts/start-k8s-bitcoin-demo.sh
```

This script will:
1. ✅ Check prerequisites (kubectl, helm, minikube)
2. ✅ Start minikube cluster
3. ✅ Pull images from DockerHub
4. ✅ Deploy FKS platform to Kubernetes
5. ✅ Set up port-forwarding
6. ✅ Test services

### Option 2: Manual Deployment

```bash
# 1. Start minikube
minikube start --cpus=6 --memory=16384 --disk-size=50g --driver=docker
minikube addons enable ingress
minikube addons enable metrics-server

# 2. Set minikube Docker context
eval $(minikube docker-env)

# 3. Pull images from DockerHub
docker pull nuniesmith/fks:app-latest
docker pull nuniesmith/fks:data-latest
docker pull nuniesmith/fks:web-latest
docker pull nuniesmith/fks:api-latest
docker pull nuniesmith/fks:main-latest

# 4. Deploy with Helm
cd repo/main/k8s
helm upgrade --install fks-platform ./charts/fks-platform \
  --namespace fks-trading \
  --create-namespace \
  --set fks_app.enabled=true \
  --set fks_data.enabled=true \
  --set fks_web.enabled=true \
  --set fks_api.enabled=true \
  --set fks_main.enabled=true \
  --set postgresql.enabled=true \
  --set redis.enabled=true

# 5. Wait for pods to be ready
kubectl wait --for=condition=ready pod --all -n fks-trading --timeout=600s

# 6. Set up port-forwarding
kubectl port-forward -n fks-trading svc/fks-app 8002:8002 &
kubectl port-forward -n fks-trading svc/fks-data 8003:8003 &
kubectl port-forward -n fks-trading svc/fks-web 3001:3001 &
kubectl port-forward -n fks-trading svc/fks-api 8001:8001 &
kubectl port-forward -n fks-trading svc/fks-main 8000:8000 &
```

---

## 📊 Access URLs

### Web Interface
- **React Web UI**: http://localhost:3001
- **Django Admin**: http://localhost:8000/admin/

### API Services
- **fks_app (Signals)**: http://localhost:8002
- **fks_data (Data)**: http://localhost:8003
- **fks_api (Gateway)**: http://localhost:8001
- **fks_main (Main)**: http://localhost:8000

### Health Endpoints
```bash
# Test services
curl "http://localhost:8002/health"
curl "http://localhost:8003/health"
curl "http://localhost:8001/health"
curl "http://localhost:8000/health"
```

---

## 🧪 Test Bitcoin Signal Generation

### Via API
```bash
# Generate Bitcoin signal
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"

# Generate with specific strategy
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"

# Generate batch signals
curl "http://localhost:8002/api/v1/signals/batch?symbols=BTCUSDT&category=swing&use_ai=false"
```

### Via Web Interface
1. Open http://localhost:3001 in your browser
2. Navigate to "Signals" section
3. Select "Bitcoin" (BTCUSDT)
4. Select category (scalp, swing, long_term)
5. Click "Generate Signal"
6. Review signal details

---

## 📋 Verify Deployment

### Check Pod Status
```bash
kubectl get pods -n fks-trading
```

Expected output:
```
NAME                          READY   STATUS    RESTARTS   AGE
fks-app-xxx                   1/1     Running   0          5m
fks-data-xxx                  1/1     Running   0          5m
fks-web-xxx                   1/1     Running   0          5m
fks-api-xxx                   1/1     Running   0          5m
fks-main-xxx                  1/1     Running   0          5m
postgresql-xxx                1/1     Running   0          5m
redis-xxx                     1/1     Running   0          5m
```

### Check Services
```bash
kubectl get svc -n fks-trading
```

### Check Logs
```bash
# View fks_app logs
kubectl logs -n fks-trading -l app=fks-app -f

# View fks_data logs
kubectl logs -n fks-trading -l app=fks-data -f

# View fks_web logs
kubectl logs -n fks-trading -l app=fks-web -f
```

---

## 🔧 Troubleshooting

### Pods Not Starting
```bash
# Check pod status
kubectl describe pod -n fks-trading <pod-name>

# Check events
kubectl get events -n fks-trading --sort-by=.lastTimestamp

# Check logs
kubectl logs -n fks-trading <pod-name>
```

### Images Not Found
```bash
# Check if images exist on DockerHub
docker pull nuniesmith/fks:app-latest
docker pull nuniesmith/fks:data-latest

# If images don't exist, build them locally
cd repo/app
docker build -t nuniesmith/fks:app-latest .
docker tag nuniesmith/fks:app-latest nuniesmith/fks:app-latest
```

### Port-Forwarding Not Working
```bash
# Kill existing port-forwards
pkill -f "kubectl port-forward"

# Restart port-forwarding
kubectl port-forward -n fks-trading svc/fks-app 8002:8002 &
kubectl port-forward -n fks-trading svc/fks-data 8003:8003 &
kubectl port-forward -n fks-trading svc/fks-web 3001:3001 &
```

### Services Not Responding
```bash
# Check service endpoints
kubectl get endpoints -n fks-trading

# Test from inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://fks-app:8002/health
```

---

## 🎯 Next Steps

### 1. Test Signal Generation
```bash
# Generate Bitcoin signal
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"

# Expected response:
# {
#   "symbol": "BTCUSDT",
#   "signal_type": "BUY",
#   "entry_price": 103330.10,
#   "take_profit": 106946.65,
#   "stop_loss": 101263.50,
#   "confidence": 0.65,
#   "rationale": "MACD strong bullish momentum",
#   ...
# }
```

### 2. Access Web Interface
1. Open http://localhost:3001 in your browser
2. Navigate to "Signals" section
3. Generate Bitcoin signals
4. Review signal details
5. Approve/reject signals

### 3. Monitor Performance
```bash
# View pod metrics
kubectl top pods -n fks-trading

# View service metrics
kubectl top svc -n fks-trading
```

---

## 📚 Documentation

### Related Guides
- `BITCOIN-QUICK-START.md` - Quick start guide for Bitcoin signals
- `BITCOIN-DAILY-WORKFLOW.md` - Daily workflow guide
- `BITCOIN-COMPLETE-WORKFLOW-SUMMARY.md` - Complete workflow summary
- `K8S_QUICKSTART.md` - Kubernetes quick start guide

### API Documentation
- Signal Generation API: `http://localhost:8002/docs`
- Data API: `http://localhost:8003/docs`
- Main API: `http://localhost:8000/docs`

---

## ✅ Success Criteria

### Deployment
- ✅ All pods running
- ✅ All services accessible
- ✅ Port-forwarding working
- ✅ Health checks passing

### Signal Generation
- ✅ Bitcoin signals generating
- ✅ API endpoints working
- ✅ Web interface accessible
- ✅ Signals displaying correctly

---

## 🚀 Quick Commands

### Start Deployment
```bash
cd repo/main
./scripts/start-k8s-bitcoin-demo.sh
```

### Stop Deployment
```bash
# Stop port-forwarding
pkill -f "kubectl port-forward"

# Stop minikube
minikube stop
```

### Restart Deployment
```bash
# Restart pods
kubectl rollout restart deployment -n fks-trading

# Wait for pods to be ready
kubectl wait --for=condition=ready pod --all -n fks-trading --timeout=600s
```

### Clean Up
```bash
# Delete deployment
helm uninstall fks-platform -n fks-trading

# Delete namespace
kubectl delete namespace fks-trading

# Stop minikube
minikube stop
minikube delete
```

---

**Status**: ✅ **READY TO DEPLOY**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/start-k8s-bitcoin-demo.sh` to deploy and test!

---

**Happy Trading!** 🚀

