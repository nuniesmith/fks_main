# Signal Integration - Kubernetes Deployment Ready ✅

**Date**: 2025-11-12  
**Status**: ✅ **Configuration Complete - Ready for Deployment**

---

## ✅ Configuration Complete

All Kubernetes manifests have been updated for signal integration:

### 1. Portfolio Service ✅
- **File**: `manifests/missing-services.yaml`
- **Environment Variables Added**:
  - `SIGNALS_DIR=/app/signals`
  - `PORT=8012`
  - `LOG_LEVEL=INFO`
  - `DATA_DIR=/app/data`
- **Volume Mount**: Signals directory mounted at `/app/signals` (read-only)
- **Health Probes**: Liveness and readiness probes configured

### 2. Web Service ✅
- **File**: `manifests/all-services.yaml`
- **Environment Variable Added**:
  - `FKS_PORTFOLIO_URL=http://fks-portfolio:8012`
- **Purpose**: Enables web service to connect to portfolio service for signal data

### 3. Signals Volume ✅
- **File**: `manifests/signals-volume.yaml` (NEW)
- **Components**:
  - PersistentVolume for signals directory
  - PersistentVolumeClaim for portfolio service
  - ConfigMap for signals configuration
- **Note**: Currently using `hostPath` directly; PV available as alternative

### 4. Ingress ✅
- **File**: `ingress.yaml`
- **Update**: Added documentation comment about signal routes
- **Routes**: Signals accessible at `/signals/dashboard/` and `/signals/api/`

---

## 🚀 Deployment Instructions

### Prerequisites
1. Kubernetes cluster running (minikube, Docker Desktop, k3s, etc.)
2. `kubectl` configured and connected to cluster
3. Namespace `fks-trading` exists (or will be created)

### Step 1: Start Kubernetes Cluster

**For Minikube:**
```bash
minikube start
```

**For Docker Desktop:**
- Enable Kubernetes in Docker Desktop settings

**For k3s:**
```bash
sudo systemctl start k3s
```

### Step 2: Verify Cluster

```bash
kubectl cluster-info
kubectl get nodes
```

### Step 3: Create Namespace (if needed)

```bash
kubectl create namespace fks-trading
```

### Step 4: Apply Manifests

```bash
cd /home/jordan/Nextcloud/code/repos/fks/repo/k8s

# Apply portfolio service (includes signal integration)
kubectl apply -f manifests/missing-services.yaml

# Apply web service (includes portfolio URL)
kubectl apply -f manifests/all-services.yaml

# Apply signals volume (optional - if using PV instead of hostPath)
kubectl apply -f manifests/signals-volume.yaml
```

### Step 5: Verify Deployment

```bash
# Check pods
kubectl get pods -n fks-trading | grep -E "portfolio|web"

# Check services
kubectl get svc -n fks-trading | grep -E "portfolio|web"

# Check portfolio pod logs
kubectl logs -n fks-trading -l app=fks-portfolio --tail=20

# Check web pod logs
kubectl logs -n fks-trading -l app=fks-web --tail=20
```

### Step 6: Test Signal Integration

```bash
# Port-forward portfolio service
kubectl port-forward -n fks-trading svc/fks-portfolio 8012:8012

# In another terminal, test API
curl "http://localhost:8012/api/signals/from-files?date=20251112" | jq '.'

# Port-forward web service
kubectl port-forward -n fks-trading svc/fks-web 8000:8000

# Test dashboard API
curl "http://localhost:8000/signals/api/?date=20251112" | jq '.'

# Open dashboard in browser
# http://localhost:8000/signals/dashboard/?date=20251112
```

---

## 🧪 Automated Testing

A test script is available to validate the deployment:

```bash
cd /home/jordan/Nextcloud/code/repos/fks/repo/k8s
./scripts/test-signal-integration.sh
```

**What it checks:**
- ✅ Cluster accessibility
- ✅ Namespace existence
- ✅ Manifest validation
- ✅ Service deployment status
- ✅ Environment variables
- ✅ Volume mounts
- ✅ Pod connectivity
- ✅ Signal file accessibility

---

## 📊 Verification Checklist

After deployment, verify:

- [ ] Portfolio service pod is running
- [ ] Portfolio service has `SIGNALS_DIR` env var
- [ ] Portfolio service has signals volume mounted
- [ ] Portfolio service can read signal files
- [ ] Web service pod is running
- [ ] Web service has `FKS_PORTFOLIO_URL` env var
- [ ] Web service can connect to portfolio service
- [ ] Signal API returns data: `curl http://localhost:8012/api/signals/from-files?date=20251112`
- [ ] Signal dashboard loads: `http://localhost:8000/signals/dashboard/`
- [ ] Lot size calculations work

---

## 🔧 Troubleshooting

### Cluster Not Running
```bash
# Minikube
minikube start

# Check status
minikube status
```

### Services Not Deploying
```bash
# Check pod events
kubectl describe pod <pod-name> -n fks-trading

# Check logs
kubectl logs <pod-name> -n fks-trading

# Check resource limits
kubectl top pod -n fks-trading
```

### Volume Mount Issues
```bash
# Verify host path exists
ls -la /home/jordan/Nextcloud/code/repos/fks/signals

# Check volume mount in pod
kubectl exec -n fks-trading <pod-name> -- ls -la /app/signals

# Check pod events
kubectl describe pod <pod-name> -n fks-trading | grep -A 10 Events
```

### Connection Issues
```bash
# Test DNS resolution
kubectl exec -n fks-trading <web-pod> -- nslookup fks-portfolio

# Test connectivity
kubectl exec -n fks-trading <web-pod> -- curl http://fks-portfolio:8012/health
```

---

## 📝 Files Modified/Created

### Modified Files
- `manifests/missing-services.yaml` - Added signal integration to portfolio service
- `manifests/all-services.yaml` - Added portfolio URL to web service
- `ingress.yaml` - Added signal route documentation

### New Files
- `manifests/signals-volume.yaml` - PersistentVolume configuration
- `scripts/test-signal-integration.sh` - Automated test script
- `SIGNAL_INTEGRATION_K8S.md` - Deployment guide
- `K8S_TEST_RESULTS.md` - Test results documentation
- `SIGNAL_INTEGRATION_DEPLOYMENT_READY.md` - This file

---

## 🎯 Next Steps

1. **Start Kubernetes cluster** (minikube, Docker Desktop, etc.)
2. **Run test script**: `./scripts/test-signal-integration.sh`
3. **Apply manifests**: Follow deployment instructions above
4. **Verify**: Check all items in verification checklist
5. **Test**: Access signal dashboard and verify functionality

---

## ✅ Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Portfolio Config | ✅ Complete | All env vars and volumes configured |
| Web Config | ✅ Complete | Portfolio URL configured |
| Signals Volume | ✅ Complete | PV/PVC manifests ready |
| Ingress Routes | ✅ Complete | Signal routes documented |
| Test Script | ✅ Complete | Automated validation available |
| Documentation | ✅ Complete | All guides created |

---

**🚀 Ready to Deploy! Start your Kubernetes cluster and apply the manifests.** ✅

