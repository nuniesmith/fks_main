# Bitcoin Signal Demo - Domain Deployment Guide (fkstrading.xyz)

**Date**: 2025-11-12  
**Status**: ✅ **READY TO DEPLOY**  
**Purpose**: Deploy Bitcoin Signal Demo to Kubernetes with fkstrading.xyz domain

---

## 🎯 Overview

This guide shows you how to deploy the Bitcoin Signal Demo to Kubernetes using your domain `fkstrading.xyz` which points to your Tailscale IP address `100.80.141.117`.

---

## 🚀 Quick Start

### Step 1: Deploy with Domain Configuration

```bash
cd repo/main
./scripts/deploy-bitcoin-demo-domain.sh
```

This script will:
1. ✅ Check prerequisites (kubectl, helm)
2. ✅ Install NGINX Ingress Controller (if needed)
3. ✅ Deploy FKS platform with domain configuration
4. ✅ Set up ingress for fkstrading.xyz
5. ✅ Wait for pods to be ready

### Step 2: Set Up Minikube Tunnel (Required)

Since you're using minikube, you need to expose the ingress controller to your Tailscale IP:

```bash
# Run in a separate terminal (keep it running)
minikube tunnel
```

This will:
- Create a route to services exposed via type LoadBalancer
- Make services accessible on your host machine's network interface
- Allow traffic from your Tailscale IP (100.80.141.117) to reach the services

**Note**: Keep this terminal running while you use the services.

### Step 3: Verify Deployment

```bash
# Check pod status
kubectl get pods -n fks-trading

# Check ingress
kubectl get ingress -n fks-trading

# Check services
kubectl get svc -n fks-trading

# Check ingress controller
kubectl get svc -n ingress-nginx ingress-nginx-controller
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

## 🔧 Manual Deployment

### Step 1: Install NGINX Ingress Controller

```bash
# Add Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --wait \
  --timeout 5m
```

### Step 2: Deploy FKS Platform

```bash
cd repo/main/k8s

# Deploy with domain configuration
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
  --wait \
  --timeout 10m
```

### Step 3: Set Up Minikube Tunnel

```bash
# Run in a separate terminal (keep it running)
minikube tunnel
```

### Step 4: Verify Deployment

```bash
# Check ingress
kubectl get ingress -n fks-trading

# Test services (use -k flag to skip SSL verification for now)
curl -k "http://fkstrading.xyz/health"
curl -k "http://app.fkstrading.xyz/health"
curl -k "http://app.fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
```

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

## 📋 DNS Configuration

### Domain Configuration

Your domain `fkstrading.xyz` should be configured with:

```
A Record:     fkstrading.xyz → 100.80.141.117
A Record:     api.fkstrading.xyz → 100.80.141.117
A Record:     app.fkstrading.xyz → 100.80.141.117
A Record:     data.fkstrading.xyz → 100.80.141.117
```

### Tailscale Configuration

Ensure your Tailscale IP (100.80.141.117) is accessible and routing traffic correctly.

---

## 🔧 Troubleshooting

### Services Not Accessible

If services are not accessible via domain:

1. **Check minikube tunnel is running**:
   ```bash
   # Check if tunnel is running
   ps aux | grep "minikube tunnel"
   
   # If not running, start it
   minikube tunnel
   ```

2. **Check ingress controller**:
   ```bash
   # Check ingress controller service
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   
   # Check ingress controller logs
   kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
   ```

3. **Check DNS resolution**:
   ```bash
   # Test DNS resolution
   nslookup fkstrading.xyz
   ping fkstrading.xyz
   ```

4. **Check ingress rules**:
   ```bash
   # Check ingress configuration
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

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Check ingress configuration
kubectl describe ingress -n fks-trading fks-platform-ingress
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
./scripts/deploy-bitcoin-demo-domain.sh
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

### View Logs
```bash
# View fks_app logs
kubectl logs -n fks-trading -l app=fks-app -f

# View fks_data logs
kubectl logs -n fks-trading -l app=fks-data -f

# View ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f
```

---

## 📚 Documentation

### Related Guides
- `BITCOIN-K8S-QUICK-START.md` - Quick start guide
- `BITCOIN-K8S-DEPLOYMENT-GUIDE.md` - Detailed deployment guide
- `BITCOIN-K8S-DEPLOYMENT-COMPLETE.md` - Deployment completion guide
- `BITCOIN-K8S-DOMAIN-SETUP.md` - Domain setup guide

### API Documentation
- Signal Generation API: http://app.fkstrading.xyz/docs
- Data API: http://data.fkstrading.xyz/docs
- Main API: http://fkstrading.xyz/docs

---

## 🎉 Summary

### Complete Workflow
1. **Deploy Platform**: Run `./scripts/deploy-bitcoin-demo-domain.sh`
2. **Set Up Tunnel**: Run `minikube tunnel` in a separate terminal
3. **Test Services**: Test health endpoints and signal generation
4. **Access Web Interface**: Open http://fkstrading.xyz in your browser
5. **Test Bitcoin Signals**: Generate and review Bitcoin signals

### Services Deployed
- ✅ **fks_app** (Signals) - http://app.fkstrading.xyz
- ✅ **fks_data** (Data) - http://data.fkstrading.xyz
- ✅ **fks_main** (Main) - http://fkstrading.xyz
- ✅ **fks_api** (Gateway) - http://api.fkstrading.xyz
- ✅ **PostgreSQL** - Database
- ✅ **Redis** - Cache

### Domain Configuration
- ✅ **Main Domain**: fkstrading.xyz
- ✅ **API Subdomain**: api.fkstrading.xyz
- ✅ **App Subdomain**: app.fkstrading.xyz
- ✅ **Data Subdomain**: data.fkstrading.xyz
- ✅ **Tailscale IP**: 100.80.141.117

---

**Status**: ✅ **READY TO DEPLOY**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/deploy-bitcoin-demo-domain.sh` and then `minikube tunnel`!

---

**Happy Trading!** 🚀

