# Bitcoin Signal Demo - fkstrading.xyz Deployment Ready ✅

**Date**: 2025-11-12  
**Status**: ✅ **READY TO DEPLOY**  
**Domain**: fkstrading.xyz  
**Tailscale IP**: 100.80.141.117

---

## 🎉 Deployment Ready!

Your Bitcoin Signal Demo is ready to be deployed to Kubernetes with your domain `fkstrading.xyz`. All configuration files and scripts have been created and are ready to use.

---

## 🚀 Deployment Steps

### Step 1: Deploy Platform with Domain

```bash
cd repo/main
./scripts/setup-fkstrading-domain.sh
```

This script will:
1. ✅ Check prerequisites (kubectl, helm)
2. ✅ Install NGINX Ingress Controller (if needed)
3. ✅ Apply ingress configuration for fkstrading.xyz
4. ✅ Deploy FKS platform
5. ✅ Wait for pods to be ready

### Step 2: Set Up Minikube Tunnel (Required)

**Important**: Run this in a separate terminal and keep it running:

```bash
minikube tunnel
```

This exposes the ingress controller to your Tailscale IP (100.80.141.117).

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

### Step 4: Test Services

```bash
# Test health endpoints
curl -k "http://fkstrading.xyz/health"
curl -k "http://app.fkstrading.xyz/health"
curl -k "http://data.fkstrading.xyz/health"

# Test Bitcoin signal generation
curl -k "http://app.fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
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

### Path-Based Routing (on main domain)
- **Signals API**: http://fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false
- **Data API**: http://fkstrading.xyz/api/v1/data/price?symbol=BTCUSDT

---

## 🧪 Test Bitcoin Signal Generation

### Via API (Subdomain)

```bash
# Generate Bitcoin signal
curl -k "http://app.fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"

# Generate with specific strategy
curl -k "http://app.fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&strategy=rsi&use_ai=false"

# Generate batch signals
curl -k "http://app.fkstrading.xyz/api/v1/signals/batch?symbols=BTCUSDT&category=swing&use_ai=false"
```

### Via API (Path-Based)

```bash
# Generate Bitcoin signal (via main domain)
curl -k "http://fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"

# Get market data
curl -k "http://fkstrading.xyz/api/v1/data/price?symbol=BTCUSDT"
curl -k "http://fkstrading.xyz/api/v1/data/ohlcv?symbol=BTCUSDT&interval=1h&limit=100"
```

### Via Web Interface

1. Open http://fkstrading.xyz in your browser
2. Navigate to admin panel: http://fkstrading.xyz/admin/
3. Use API endpoints to generate signals
4. View signals in the dashboard

---

## 📋 Configuration Summary

### Domain Configuration
- **Main Domain**: fkstrading.xyz
- **API Subdomain**: api.fkstrading.xyz
- **App Subdomain**: app.fkstrading.xyz
- **Data Subdomain**: data.fkstrading.xyz
- **Tailscale IP**: 100.80.141.117

### Ingress Configuration
- **File**: `repo/main/k8s/ingress.yaml`
- **Routes**: 
  - Main domain: fkstrading.xyz → fks-main (port 8000)
  - Subdomain: app.fkstrading.xyz → fks-app (port 8002)
  - Subdomain: data.fkstrading.xyz → fks-data (port 8003)
  - Subdomain: api.fkstrading.xyz → fks-api (port 8001)
  - Path-based: fkstrading.xyz/api/v1/signals → fks-app
  - Path-based: fkstrading.xyz/api/v1/data → fks-data

### Helm Values
- **File**: `repo/main/k8s/charts/fks-platform/values-fkstrading.yaml`
- **Domain**: fkstrading.xyz
- **Services**: fks_app, fks_data, fks_main, fks_api enabled
- **ALLOWED_HOSTS**: fkstrading.xyz,*.fkstrading.xyz,localhost,127.0.0.1,100.80.141.117

### Deployment Script
- **File**: `repo/main/scripts/setup-fkstrading-domain.sh`
- **Purpose**: Complete deployment with domain configuration
- **Usage**: `./scripts/setup-fkstrading-domain.sh`

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

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Check ingress configuration
kubectl describe ingress -n fks-trading fks-platform-ingress
kubectl describe ingress -n fks-trading fks-platform-ingress-multi
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
./scripts/setup-fkstrading-domain.sh
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
curl -k "http://fkstrading.xyz/api/v1/signals/latest/BTCUSDT?category=swing&use_ai=false"
```

### Check Status
```bash
# Pod status
kubectl get pods -n fks-trading

# Ingress status
kubectl get ingress -n fks-trading

# Service status
kubectl get svc -n fks-trading

# Ingress controller status
kubectl get svc -n ingress-nginx ingress-nginx-controller
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
- `BITCOIN-DOMAIN-DEPLOYMENT-GUIDE.md` - Domain deployment guide
- `BITCOIN-DOMAIN-DEPLOYMENT-COMPLETE.md` - Domain deployment complete
- `BITCOIN-FKSTRADING-DOMAIN-SETUP.md` - fkstrading.xyz domain setup
- `BITCOIN-DOMAIN-DEPLOYMENT-INSTRUCTIONS.md` - Domain deployment instructions
- `BITCOIN-DOMAIN-QUICK-START.md` - Domain quick start
- `BITCOIN-FKSTRADING-DEPLOYMENT-READY.md` - This file

### API Documentation
- Signal Generation API: http://app.fkstrading.xyz/docs
- Data API: http://data.fkstrading.xyz/docs
- Main API: http://fkstrading.xyz/docs

---

## 🎉 Summary

### Complete Workflow
1. **Deploy Platform**: Run `./scripts/setup-fkstrading-domain.sh`
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

### Configuration Files
- ✅ **Helm Values**: `repo/main/k8s/charts/fks-platform/values-fkstrading.yaml`
- ✅ **Deployment Script**: `repo/main/scripts/setup-fkstrading-domain.sh`
- ✅ **Ingress Configuration**: `repo/main/k8s/ingress.yaml`
- ✅ **Documentation**: Complete deployment guides

---

## 🎯 Next Steps

1. **Deploy Platform**: Run `./scripts/setup-fkstrading-domain.sh`
2. **Set Up Tunnel**: Run `minikube tunnel` in a separate terminal
3. **Test Services**: Test health endpoints and signal generation
4. **Access Web Interface**: Open http://fkstrading.xyz in your browser
5. **Test Bitcoin Signals**: Generate and review Bitcoin signals

---

**Status**: ✅ **READY TO DEPLOY**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/setup-fkstrading-domain.sh` and then `minikube tunnel`!

---

**Happy Trading!** 🚀

