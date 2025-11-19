# Ingress 503 Error - Fix Applied

**Date**: 2025-11-12  
**Issue**: Domain returning 503 Service Temporarily Unavailable  
**Status**: ✅ **Fixed**

---

## Root Cause

The 503 error was caused by two issues:

1. **Ingress Configuration**: 
   - Service name mismatch: Ingress was looking for `fks-web` but service is named `web`
   - Port mismatch: Ingress was pointing to port `3001` but service runs on port `8000`

2. **Health Check Logic**:
   - Health endpoint was returning 503 because Prometheus and Grafana (monitoring services) were unavailable
   - This caused readiness probes to fail
   - No endpoints were created for the service
   - Ingress had no backend to route to → 503 error

---

## Fixes Applied

### 1. Ingress Configuration ✅

**File**: `repo/k8s/ingress.yaml`

**Changed**:
```yaml
# Before
service:
  name: fks-web
  port:
    number: 3001

# After  
service:
  name: web
  port:
    number: 8000
```

**Applied**: ✅ `kubectl apply -f ingress.yaml`

### 2. Health Check Logic ✅

**File**: `repo/web/src/health.py`

**Changes**:
1. Marked Prometheus and Grafana as optional services
2. Updated health check logic to return 200 if core services (database, redis, celery) are healthy, even if optional monitoring services are down

**Code Changes**:
```python
# Mark as optional
services["prometheus"] = self._check_service(
    "http://fks-platform-prometheus-server/-/healthy", "Prometheus", optional=True
)
services["grafana"] = self._check_service(
    "http://fks-platform-grafana/api/health", "Grafana", optional=True
)

# Return 200 if core services healthy
core_services = ["database", "redis", "celery"]
core_healthy = all(
    services.get(svc, {}).get("status") == "healthy"
    for svc in core_services
)
status=200 if core_healthy else 503
```

**Committed & Pushed**: ✅ Changes committed and pushed to trigger GitHub Actions build

---

## Next Steps

### 1. Wait for Docker Image Build

GitHub Actions will build and push the new image:
- Repository: `nuniesmith/fks_web`
- Image: `nuniesmith/fks:web-latest`
- Check status: https://github.com/nuniesmith/fks_web/actions

### 2. Update Deployment

Once the image is built (usually 5-10 minutes):

```bash
# Option 1: Restart deployment (will pull new image)
kubectl rollout restart deployment/fks-web -n fks-trading

# Option 2: Update image manually
kubectl set image deployment/fks-web web=nuniesmith/fks:web-latest -n fks-trading
kubectl rollout restart deployment/fks-web -n fks-trading
```

### 3. Verify Fix

```bash
# Check pod status
kubectl get pods -n fks-trading -l app=fks-web

# Check endpoints (should have IPs now)
kubectl get endpoints -n fks-trading web

# Test health endpoint
kubectl port-forward -n fks-trading svc/web 8000:8000
curl http://localhost:8000/health

# Test domain
curl http://fkstrading.xyz
```

---

## Temporary Workaround

If you need the domain working immediately while waiting for the image build:

### Option 1: Use /ready endpoint for probes

Update the deployment to use `/ready` instead of `/health`:

```bash
kubectl patch deployment fks-web -n fks-trading -p '{"spec":{"template":{"spec":{"containers":[{"name":"web","readinessProbe":{"httpGet":{"path":"/ready"}}}]}}}}'
```

### Option 2: Disable health checks temporarily

```bash
kubectl patch deployment fks-web -n fks-trading -p '{"spec":{"template":{"spec":{"containers":[{"name":"web","readinessProbe":null,"livenessProbe":null}]}}}}'
```

**Note**: Only use these as temporary workarounds. The proper fix is in the code.

---

## Verification Checklist

After applying the fix:

- [ ] Ingress service name matches actual service (`web`)
- [ ] Ingress port matches service port (`8000`)
- [ ] Web pods are in Ready state (`1/1`)
- [ ] Endpoints have IP addresses
- [ ] Health endpoint returns 200 (not 503)
- [ ] Domain is accessible
- [ ] Signal dashboard loads

---

## Summary

✅ **Ingress fixed** - Service name and port corrected  
✅ **Health check fixed** - Prometheus/Grafana marked as optional  
✅ **Code committed** - Changes pushed to trigger build  
⏳ **Waiting for build** - GitHub Actions building new image  
⏳ **Deployment update** - Will restart after build completes

**The domain should work once the new image is deployed!** 🚀

