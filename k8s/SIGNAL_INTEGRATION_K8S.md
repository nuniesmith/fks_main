# Signal Integration - Kubernetes Deployment Guide

**Date**: 2025-11-12  
**Status**: ✅ Configuration Complete

---

## 📋 Summary

Updated Kubernetes deployments to support signal integration:
- ✅ Portfolio service: Added `SIGNALS_DIR` env var and volume mount
- ✅ Web service: Added `FKS_PORTFOLIO_URL` env var
- ✅ Signals volume: Created PersistentVolume configuration
- ✅ Ingress: Documented signal routes

---

## 🔧 Changes Made

### 1. Portfolio Service (`manifests/missing-services.yaml`)

**Added Environment Variables:**
```yaml
- name: SIGNALS_DIR
  value: "/app/signals"
- name: PORT
  value: "8012"
- name: LOG_LEVEL
  value: "INFO"
- name: DATA_DIR
  value: "/app/data"
```

**Added Volume Mount:**
```yaml
volumeMounts:
- name: signals
  mountPath: /app/signals
  readOnly: true
volumes:
- name: signals
  hostPath:
    path: /home/jordan/Nextcloud/code/repos/fks/signals
    type: Directory
```

**Added Readiness Probe:**
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8012
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
```

### 2. Web Service (`manifests/all-services.yaml`)

**Added Environment Variable:**
```yaml
- name: FKS_PORTFOLIO_URL
  value: "http://fks-portfolio:8012"
```

This allows the web service to connect to the portfolio service for signal data.

### 3. Signals Volume (`manifests/signals-volume.yaml`)

Created a new manifest file with:
- PersistentVolume for signals directory
- PersistentVolumeClaim for portfolio service
- ConfigMap for signals configuration

**Note**: Currently using `hostPath` directly in the portfolio deployment. The PersistentVolume is available as an alternative for production use.

### 4. Ingress (`ingress.yaml`)

Added comment documenting that signal routes are accessible through the web service:
- `/signals/dashboard/` - Signal dashboard UI
- `/signals/api/` - Signal API endpoint

---

## 🚀 Deployment Steps

### 1. Apply Signals Volume (Optional)

If using PersistentVolume instead of hostPath:

```bash
kubectl apply -f repo/k8s/manifests/signals-volume.yaml
```

### 2. Update Portfolio Service

```bash
kubectl apply -f repo/k8s/manifests/missing-services.yaml
```

### 3. Update Web Service

```bash
kubectl apply -f repo/k8s/manifests/all-services.yaml
```

### 4. Verify Deployment

```bash
# Check portfolio service
kubectl get pods -n fks-trading | grep portfolio
kubectl logs -n fks-trading deployment/fks-portfolio | tail -20

# Check web service
kubectl get pods -n fks-trading | grep web
kubectl logs -n fks-trading deployment/fks-web | tail -20

# Verify volume mount
kubectl exec -n fks-trading deployment/fks-portfolio -- ls -la /app/signals
```

### 5. Test Signal Integration

```bash
# Port-forward portfolio service
kubectl port-forward -n fks-trading svc/fks-portfolio 8012:8012

# Test API
curl "http://localhost:8012/api/signals/from-files?date=20251112" | jq '.'

# Port-forward web service
kubectl port-forward -n fks-trading svc/fks-web 8000:8000

# Test dashboard
curl "http://localhost:8000/signals/api/?date=20251112" | jq '.'
```

---

## 🔍 Verification Checklist

- [ ] Portfolio service pod is running
- [ ] Portfolio service has signals volume mounted
- [ ] Portfolio service can read signal files
- [ ] Web service pod is running
- [ ] Web service has `FKS_PORTFOLIO_URL` env var set
- [ ] Web service can connect to portfolio service
- [ ] Signal dashboard is accessible via ingress
- [ ] Signal API returns data correctly
- [ ] Lot size calculations work

---

## 📊 Service Configuration

### Portfolio Service
- **Service Name**: `fks-portfolio`
- **Port**: `8012`
- **Signals Directory**: `/app/signals` (mounted from host)
- **Health Endpoint**: `/health`
- **Readiness Endpoint**: `/ready`

### Web Service
- **Service Name**: `fks-web` (or `web`)
- **Port**: `8000`
- **Portfolio URL**: `http://fks-portfolio:8012`
- **Signal Routes**:
  - `/signals/dashboard/` - Dashboard UI
  - `/signals/api/` - API endpoint
  - `/signals/detail/<symbol>/` - Signal detail

---

## 🔧 Troubleshooting

### Portfolio Service Can't Read Signals

**Check volume mount:**
```bash
kubectl exec -n fks-trading deployment/fks-portfolio -- ls -la /app/signals
```

**Check environment variable:**
```bash
kubectl exec -n fks-trading deployment/fks-portfolio -- env | grep SIGNALS_DIR
```

**Check host path exists:**
```bash
ls -la /home/jordan/Nextcloud/code/repos/fks/signals
```

### Web Service Can't Connect to Portfolio

**Check service exists:**
```bash
kubectl get svc -n fks-trading | grep portfolio
```

**Check DNS resolution:**
```bash
kubectl exec -n fks-trading deployment/fks-web -- nslookup fks-portfolio
```

**Test connection:**
```bash
kubectl exec -n fks-trading deployment/fks-web -- curl http://fks-portfolio:8012/health
```

### Signals Not Showing in Dashboard

**Check portfolio API:**
```bash
kubectl port-forward -n fks-trading svc/fks-portfolio 8012:8012
curl "http://localhost:8012/api/signals/from-files?date=20251112"
```

**Check web service logs:**
```bash
kubectl logs -n fks-trading deployment/fks-web | grep -i signal
```

**Check ingress routing:**
```bash
kubectl get ingress -n fks-trading
kubectl describe ingress fks-platform-ingress -n fks-trading
```

---

## 📝 Notes

1. **HostPath vs PersistentVolume**: Currently using `hostPath` for simplicity. For production, consider using PersistentVolume with proper storage class.

2. **Service Names**: The web service is named `web` in `all-services.yaml` but referenced as `fks-web` in ingress. Ensure service names match or update accordingly.

3. **Read-Only Mount**: Signals volume is mounted read-only in portfolio service, which is appropriate since signals are generated externally.

4. **Network Policy**: Consider adding network policies to restrict access between services if needed.

---

## 🎯 Next Steps

1. **Test in K8s**: Deploy and verify signal integration works
2. **Production Volume**: Switch to PersistentVolume for production
3. **Monitoring**: Add Prometheus metrics for signal API
4. **Documentation**: Update main K8s README with signal integration

---

**Configuration Complete! Ready for deployment.** ✅

