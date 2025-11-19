# Deploying Signal Integration with run.sh

**Date**: 2025-11-12  
**Status**: ✅ Ready to Deploy

---

## Setup Complete

A symlink has been created from `repo/main/k8s` → `repo/k8s` so that `run.sh` can find all the Kubernetes manifests including the signal integration updates.

---

## Deployment Steps

### 1. Run the Management Script

```bash
cd /home/jordan/Nextcloud/code/repos/fks/repo/main
./run.sh
```

### 2. Select Option 8: Kubernetes Start

The script will:
- ✅ Check for minikube (install if needed)
- ✅ Start minikube
- ✅ Enable ingress addon
- ✅ Pull images from Docker Hub
- ✅ Create namespace `fks-trading`
- ✅ Apply manifests (including signal integration)
- ✅ Setup Kubernetes Dashboard

### 3. Follow the Prompts

When prompted:
- **"Run full setup script?"** → Choose `y` for complete setup, or `n` to apply manifests manually
- **"Enter Kubernetes namespace"** → Press Enter for default `fks-trading`

---

## What Gets Deployed

### Portfolio Service (with Signal Integration)
- ✅ `SIGNALS_DIR` environment variable
- ✅ Signals volume mount (`/app/signals`)
- ✅ Readiness probe configured
- ✅ All signal integration features enabled

### Web Service (with Portfolio Connection)
- ✅ `FKS_PORTFOLIO_URL` environment variable
- ✅ Can connect to portfolio service for signals

### All Other Services
- All 14 FKS services deployed
- Infrastructure (PostgreSQL, Redis)
- Ingress configuration
- Kubernetes Dashboard

---

## Verification After Deployment

### Check Pods
```bash
kubectl get pods -n fks-trading | grep -E "portfolio|web"
```

### Check Portfolio Service
```bash
# Check environment variables
kubectl exec -n fks-trading deployment/fks-portfolio -- env | grep SIGNALS_DIR

# Check volume mount
kubectl exec -n fks-trading deployment/fks-portfolio -- ls /app/signals

# Test API
kubectl port-forward -n fks-trading svc/fks-portfolio 8012:8012
curl "http://localhost:8012/api/signals/from-files?date=20251112"
```

### Check Web Service
```bash
# Check environment variables
kubectl exec -n fks-trading deployment/fks-web -- env | grep FKS_PORTFOLIO_URL

# Test dashboard
kubectl port-forward -n fks-trading svc/fks-web 8000:8000
curl "http://localhost:8000/signals/api/?date=20251112"
```

---

## Alternative: Manual Deployment

If you prefer to deploy manually without the interactive script:

```bash
# Start minikube
minikube start

# Enable ingress
minikube addons enable ingress

# Create namespace
kubectl create namespace fks-trading

# Apply manifests
cd /home/jordan/Nextcloud/code/repos/fks/repo/k8s
kubectl apply -f manifests/all-services.yaml
kubectl apply -f manifests/missing-services.yaml
kubectl apply -f ingress.yaml
```

---

## Troubleshooting

### Minikube Not Running
```bash
minikube start
```

### Images Not Found
The script will pull images from Docker Hub automatically. If some fail:
```bash
# Pull manually
docker pull nuniesmith/fks:portfolio-latest
docker pull nuniesmith/fks:web-latest
```

### Pods Not Starting
```bash
# Check pod events
kubectl describe pod <pod-name> -n fks-trading

# Check logs
kubectl logs <pod-name> -n fks-trading
```

---

## Next Steps After Deployment

1. **Verify Signal Integration**:
   - Test portfolio API
   - Test web dashboard
   - Verify lot size calculations

2. **Access Services**:
   - Web UI: `http://fkstrading.xyz` (or port-forward)
   - Dashboard: Use option 13 in run.sh menu

3. **Monitor**:
   - Check pod status: `kubectl get pods -n fks-trading`
   - View logs: `kubectl logs -f deployment/fks-portfolio -n fks-trading`

---

**Ready to deploy! Run `./run.sh` and select option 8.** 🚀

