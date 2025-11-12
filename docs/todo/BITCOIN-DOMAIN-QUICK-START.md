# Bitcoin Signal Demo - Domain Quick Start (fkstrading.xyz)

**Date**: 2025-11-12  
**Status**: ✅ **READY TO DEPLOY**  
**Domain**: fkstrading.xyz  
**Tailscale IP**: 100.80.141.117

---

## 🚀 Quick Start (3 Steps)

### Step 1: Deploy Platform

```bash
cd repo/main
./scripts/setup-fkstrading-domain.sh
```

This will:
1. ✅ Install NGINX Ingress Controller (if needed)
2. ✅ Apply ingress configuration for fkstrading.xyz
3. ✅ Deploy FKS platform
4. ✅ Wait for pods to be ready

### Step 2: Set Up Minikube Tunnel (Required)

**Important**: Run this in a separate terminal and keep it running:

```bash
minikube tunnel
```

This exposes the ingress controller to your Tailscale IP (100.80.141.117).

### Step 3: Test Services

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
- `BITCOIN-DOMAIN-QUICK-START.md` - This file

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

---

**Status**: ✅ **READY TO DEPLOY**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/setup-fkstrading-domain.sh` and then `minikube tunnel`!

---

**Happy Trading!** 🚀

