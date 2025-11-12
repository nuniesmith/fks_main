# Bitcoin Signal Demo - Kubernetes Deployment Complete ✅

**Date**: 2025-11-12  
**Status**: ✅ **KUBERNETES STARTED - READY TO DEPLOY**  
**Purpose**: Complete the deployment after k8s is started

---

## 🎉 Current Status

✅ **Kubernetes Started**: Minikube cluster is running  
✅ **Images Pulled**: 13/14 services synced from DockerHub  
⚠️ **Ninja Service**: Image not found (expected - C# NinjaTrader app)  
✅ **Basic Manifests Applied**: Initial Kubernetes resources created

---

## 🚀 Next Steps: Deploy FKS Platform

### Step 1: Deploy with Helm

```bash
cd repo/main/k8s

# Deploy FKS platform
helm upgrade --install fks-platform ./charts/fks-platform \
  --namespace fks-trading \
  --create-namespace \
  --wait \
  --timeout 10m \
  --set fks_app.enabled=true \
  --set fks_data.enabled=true \
  --set fks_main.enabled=true \
  --set fks_api.enabled=true \
  --set fks_ai.enabled=false \
  --set fks_execution.enabled=false \
  --set fks_web.enabled=false \
  --set fks_ninja.enabled=false \
  --set postgresql.enabled=true \
  --set redis.enabled=true
```

### Step 2: Wait for Pods to be Ready

```bash
# Check pod status
kubectl get pods -n fks-trading

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n fks-trading --timeout=600s
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

### Web Interface
- **Main Dashboard**: http://localhost:8000
- **Admin Panel**: http://localhost:8000/admin/

### API Services
- **fks_app (Signals)**: http://localhost:8002
- **fks_data (Data)**: http://localhost:8003
- **fks_api (Gateway)**: http://localhost:8001
- **fks_main (Main)**: http://localhost:8000

---

## 🔧 Quick Commands

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

### Check Status
```bash
# Pod status
kubectl get pods -n fks-trading

# Service status
kubectl get svc -n fks-trading

# View logs
kubectl logs -n fks-trading -l app=fks-app -f
kubectl logs -n fks-trading -l app=fks-data -f
```

### Port-Forwarding
```bash
# Start port-forwarding
kubectl port-forward -n fks-trading svc/fks-app 8002:8002 &
kubectl port-forward -n fks-trading svc/fks-data 8003:8003 &
kubectl port-forward -n fks-trading svc/fks-main 8000:8000 &
kubectl port-forward -n fks-trading svc/fks-api 8001:8001 &

# Stop port-forwarding
pkill -f "kubectl port-forward"
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

### Services Not Responding
```bash
# Check service endpoints
kubectl get endpoints -n fks-trading

# Test from inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://fks-app:8002/health
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

## 🎯 Next Actions

1. **Deploy Platform**: Run the Helm command above
2. **Set Up Port-Forwarding**: Use the kubectl commands above
3. **Test Services**: Test health endpoints and signal generation
4. **Access Web Interface**: Open http://localhost:8000 in your browser
5. **Test Bitcoin Signals**: Generate and review Bitcoin signals

---

**Status**: ✅ **READY TO DEPLOY**

**Last Updated**: 2025-11-12

**Next Action**: Run the Helm deployment command to complete the setup!

---

**Happy Trading!** 🚀

