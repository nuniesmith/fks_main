# Bitcoin Signal Demo - Domain Deployment Instructions

**Date**: 2025-11-12  
**Status**: ✅ **READY TO DEPLOY**  
**Domain**: fkstrading.xyz  
**Tailscale IP**: 100.80.141.117

---

## 🎯 Quick Deployment Steps

### Step 1: Deploy Platform with Domain

```bash
cd repo/main
./scripts/deploy-fkstrading-bitcoin-demo.sh
```

This will:
1. ✅ Check prerequisites (kubectl, helm)
2. ✅ Install NGINX Ingress Controller (if needed)
3. ✅ Apply ingress configuration for fkstrading.xyz
4. ✅ Deploy FKS platform with domain configuration
5. ✅ Wait for pods to be ready

### Step 2: Set Up Minikube Tunnel (Required)

**Important**: Run this in a separate terminal and keep it running:

```bash
minikube tunnel
```

This exposes the ingress controller to your Tailscale IP (100.80.141.117).

### Step 3: Verify Deployment

```bash
# Check pod status
kubectl get pods -n fks-trading

# Check ingress
kubectl get ingress -n fks-trading

# Check services
kubectl get svc -n fks-trading
```

---

## 📊 Access URLs

### Web Interface
- **Main Dashboard**: http://fkstrading.xyz
- **Admin Panel**: http://fkstrading.xyz/admin/

### API Services
- **Main API**: http://fkstrading.xyz
- **API Gateway**: http://api.fkstrading.xyz
- **App Service (Signals)**: http://app.fkstrading.xyz
- **Data Service**: http://data.fkstrading.xyz

### Bitcoin Signal Demo
- **Generate Signal**: http://app.fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false
- **Health Check**: http://app.fkstrading.xyz/health
- **Data Service**: http://data.fkstrading.xyz/health

---

## 🧪 Test Bitcoin Signal Generation

### Via API

```bash
# Generate Bitcoin signal
curl -k "http://app.fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"

# Generate with specific strategy
curl -k "http://app.fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"

# Generate batch signals
curl -k "http://app.fkstrading.xyz/api/v1/signals/batch?symbols=BTCUSDT&category=swing&use_ai=false"
```

### Via Web Interface

1. Open http://fkstrading.xyz in your browser
2. Navigate to admin panel: http://fkstrading.xyz/admin/
3. Use API endpoints to generate signals
4. View signals in the dashboard

---

## 🔧 Manual Deployment (Alternative)

If the script doesn't work, you can deploy manually:

### Step 1: Install NGINX Ingress

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --wait \
  --timeout 5m
```

### Step 2: Apply Ingress Configuration

```bash
cd repo/main/k8s
kubectl apply -f ingress.yaml -n fks-trading
```

### Step 3: Deploy Platform

```bash
cd repo/main/k8s

helm upgrade --install fks-platform ./charts/fks-platform \
  --namespace fks-trading \
  --create-namespace \
  -f ./charts/fks-platform/values-fkstrading.yaml \
  --set fks_app.enabled=true \
  --set fks_data.enabled=true \
  --set fks_main.enabled=true \
  --set fks_api.enabled=true \
  --set fks_ai.enabled=false \
  --set fks_execution.enabled=false \
  --set fks_web.enabled=false \
  --set fks_ninja.enabled=false \
  --set postgresql.enabled=true \
  --set redis.enabled=true \
  --set ingress.enabled=false \
  --wait \
  --timeout 10m
```

### Step 4: Set Up Minikube Tunnel

```bash
# Run in a separate terminal (keep it running)
minikube tunnel
```

---

## 📋 DNS Configuration

### Domain Configuration

Your domain `fkstrading.xyz` should be configured with:

```
A Record:     fkstrading.xyz → 100.80.141.117
A Record:     api.fkstrading.xyz → 100.80.141.117
A Record:     app.fkstrading.xyz → 100.80.141.117
A Record:     data.fkstrading.xyz → 100.80.141.117
```

### Verify DNS

```bash
# Test DNS resolution
nslookup fkstrading.xyz
nslookup app.fkstrading.xyz
ping fkstrading.xyz
```

---

## 🔧 Troubleshooting

### Services Not Accessible

1. **Check minikube tunnel is running**:
   ```bash
   ps aux | grep "minikube tunnel"
   minikube tunnel  # Start if not running
   ```

2. **Check ingress controller**:
   ```bash
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
   ```

3. **Check DNS resolution**:
   ```bash
   nslookup fkstrading.xyz
   ping fkstrading.xyz
   ```

4. **Check ingress rules**:
   ```bash
   kubectl describe ingress -n fks-trading
   ```

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod -n fks-trading <pod-name>

# Check events
kubectl get events -n fks-trading --sort-by=.lastTimestamp

# Check logs
kubectl logs -n fks-trading <pod-name>
```

---

## ✅ Success Criteria

### Deployment
- ✅ All pods running
- ✅ Ingress controller running
- ✅ Ingress rules configured
- ✅ Minikube tunnel running
- ✅ Services accessible via domain

### Signal Generation
- ✅ Bitcoin signals generating
- ✅ API endpoints working
- ✅ Web interface accessible
- ✅ Signals displaying correctly

---

## 🚀 Quick Commands

### Deploy Platform
```bash
cd repo/main
./scripts/deploy-fkstrading-bitcoin-demo.sh
```

### Set Up Tunnel
```bash
# Run in a separate terminal (keep it running)
minikube tunnel
```

### Test Services
```bash
# Test health endpoints
curl -k "http://fkstrading.xyz/health"
curl -k "http://app.fkstrading.xyz/health"
curl -k "http://data.fkstrading.xyz/health"

# Test Bitcoin signal generation
curl -k "http://app.fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
```

### Check Status
```bash
# Pod status
kubectl get pods -n fks-trading

# Ingress status
kubectl get ingress -n fks-trading

# Service status
kubectl get svc -n fks-trading
```

---

**Status**: ✅ **READY TO DEPLOY**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/deploy-fkstrading-bitcoin-demo.sh` and then `minikube tunnel`!

---

**Happy Trading!** 🚀

