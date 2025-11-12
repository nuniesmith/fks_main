# Bitcoin Signal Demo - Kubernetes Quick Start

**Date**: 2025-11-12  
**Status**: ✅ **READY TO DEPLOY**  
**Purpose**: Quick start guide to deploy Bitcoin Signal Demo to Kubernetes using run.sh

---

## 🚀 Quick Start (Using run.sh)

### Step 1: Start Kubernetes

```bash
cd repo/main
./run.sh
```

Select option **8** (Kubernetes Start)

This will:
1. ✅ Check prerequisites (kubectl, helm, minikube)
2. ✅ Start minikube cluster
3. ✅ Pull images from DockerHub (`nuniesmith/fks`)
4. ✅ Set up Kubernetes namespace
5. ✅ Deploy FKS platform

### Step 2: Deploy FKS Platform

After minikube is started, deploy the platform using Helm:

```bash
cd repo/main/k8s

# Deploy with Helm
helm upgrade --install fks-platform ./charts/fks-platform \
  --namespace fks-trading \
  --create-namespace \
  --set fks_app.enabled=true \
  --set fks_data.enabled=true \
  --set fks_main.enabled=true \
  --set fks_api.enabled=true \
  --set fks_ai.enabled=false \
  --set fks_execution.enabled=false \
  --set fks_web.enabled=false \
  --set postgresql.enabled=true \
  --set redis.enabled=true \
  --wait \
  --timeout 10m
```

### Step 3: Set Up Port-Forwarding

```bash
# Set up port-forwarding for services
kubectl port-forward -n fks-trading svc/fks-app 8002:8002 &
kubectl port-forward -n fks-trading svc/fks-data 8003:8003 &
kubectl port-forward -n fks-trading svc/fks-main 8000:8000 &
kubectl port-forward -n fks-trading svc/fks-api 8001:8001 &
```

### Step 4: Test Services

```bash
# Test health endpoints
curl "http://localhost:8002/health"  # fks_app
curl "http://localhost:8003/health"  # fks_data
curl "http://localhost:8000/health"  # fks_main
curl "http://localhost:8001/health"  # fks_api

# Test Bitcoin signal generation
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
```

---

## 📊 Access URLs

### API Services
- **fks_app (Signals)**: http://localhost:8002
- **fks_data (Data)**: http://localhost:8003
- **fks_main (Main)**: http://localhost:8000
- **fks_api (Gateway)**: http://localhost:8001

### Web Interface

The web interface is served by `fks_main` on port 8000:

- **Main Dashboard**: http://localhost:8000
- **Admin Panel**: http://localhost:8000/admin/
- **API Docs**: http://localhost:8000/docs

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

1. Open http://localhost:8000 in your browser
2. Navigate to admin panel: http://localhost:8000/admin/
3. Use API endpoints to generate signals
4. View signals in the dashboard

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
fks-main-xxx                  1/1     Running   0          5m
fks-api-xxx                   1/1     Running   0          5m
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

# View fks_main logs
kubectl logs -n fks-trading -l app=fks-main -f
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

If images don't exist on DockerHub, you can:

1. **Pull images manually**:
```bash
eval $(minikube docker-env)
docker pull nuniesmith/fks:app-latest
docker pull nuniesmith/fks:data-latest
docker pull nuniesmith/fks:main-latest
docker pull nuniesmith/fks:api-latest
```

2. **Build images locally**:
```bash
cd repo/app
docker build -t nuniesmith/fks:app-latest .
docker tag nuniesmith/fks:app-latest nuniesmith/fks:app-latest
```

3. **Use run.sh to pull images**:
```bash
cd repo/main
./run.sh
# Select option 11 (Pull Images from Docker Hub - Minikube)
```

### Port-Forwarding Not Working

```bash
# Kill existing port-forwards
pkill -f "kubectl port-forward"

# Restart port-forwarding
kubectl port-forward -n fks-trading svc/fks-app 8002:8002 &
kubectl port-forward -n fks-trading svc/fks-data 8003:8003 &
kubectl port-forward -n fks-trading svc/fks-main 8000:8000 &
kubectl port-forward -n fks-trading svc/fks-api 8001:8001 &
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

1. Open http://localhost:8000 in your browser
2. Navigate to admin panel: http://localhost:8000/admin/
3. Use API endpoints to generate signals
4. View signals in the dashboard

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
- `BITCOIN-K8S-DEPLOYMENT-GUIDE.md` - Detailed deployment guide

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
./run.sh
# Select option 8 (Kubernetes Start)
```

### Deploy Platform
```bash
cd repo/main/k8s
helm upgrade --install fks-platform ./charts/fks-platform \
  --namespace fks-trading \
  --create-namespace \
  --set fks_app.enabled=true \
  --set fks_data.enabled=true \
  --set fks_main.enabled=true \
  --set fks_api.enabled=true \
  --set postgresql.enabled=true \
  --set redis.enabled=true \
  --wait \
  --timeout 10m
```

### Set Up Port-Forwarding
```bash
kubectl port-forward -n fks-trading svc/fks-app 8002:8002 &
kubectl port-forward -n fks-trading svc/fks-data 8003:8003 &
kubectl port-forward -n fks-trading svc/fks-main 8000:8000 &
kubectl port-forward -n fks-trading svc/fks-api 8001:8001 &
```

### Test Services
```bash
curl "http://localhost:8002/health"
curl "http://localhost:8003/health"
curl "http://localhost:8000/health"
curl "http://localhost:8001/health"
curl "http://localhost:8002/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
```

### Stop Deployment
```bash
# Stop port-forwarding
pkill -f "kubectl port-forward"

# Stop minikube
minikube stop
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

## 🎉 Summary

### Complete Workflow
1. **Start Kubernetes**: Use `./run.sh` option 8
2. **Deploy Platform**: Use Helm to deploy FKS platform
3. **Set Up Port-Forwarding**: Forward services to localhost
4. **Test Services**: Test health endpoints and signal generation
5. **Access Web Interface**: Access web interface at http://localhost:8000

### Services Deployed
- ✅ **fks_app** (Signals) - Port 8002
- ✅ **fks_data** (Data) - Port 8003
- ✅ **fks_main** (Main) - Port 8000
- ✅ **fks_api** (Gateway) - Port 8001
- ✅ **PostgreSQL** - Database
- ✅ **Redis** - Cache

### Images Used
- `nuniesmith/fks:app-latest`
- `nuniesmith/fks:data-latest`
- `nuniesmith/fks:main-latest`
- `nuniesmith/fks:api-latest`

---

**Status**: ✅ **READY TO DEPLOY**

**Last Updated**: 2025-11-12

**Next Action**: Run `./run.sh` and select option 8 to start Kubernetes!

---

**Happy Trading!** 🚀

