# Kubernetes Startup Fixes Applied

**Date**: 2025-11-12

## ✅ Fixes Applied

### 1. Fixed ImagePullBackOff Errors

**Problem**: Services were using `nuniesmith/fks:web-v9` which doesn't exist on Docker Hub.

**Fixed**: Updated all references to use `nuniesmith/fks:web-latest`:
- ✅ `fks-web` initContainer (line 195)
- ✅ `fks-web` container (line 232)
- ✅ `celery-worker` (line 606)
- ✅ `celery-beat` (line 664)
- ✅ `flower` (line 736)

**File**: `repo/k8s/manifests/all-services.yaml`

**Next Step**: Apply the changes:
```bash
kubectl apply -f repo/k8s/manifests/all-services.yaml -n fks-trading
```

This should fix:
- ✅ `fks-web` ImagePullBackOff
- ✅ `celery-worker` ImagePullBackOff
- ✅ `celery-beat` ImagePullBackOff
- ✅ `flower` ImagePullBackOff

---

### 2. Fixed Ingress Conflict

**Problem**: `dashboard-ingress-auto-login.yaml` conflicts with `dashboard-ingress.yaml` (same host/path).

**Fixed**: Updated `setup-local-k8s.sh` to skip the auto-login ingress deployment since it's non-critical and conflicts with the main ingress.

**File**: `repo/k8s/setup-local-k8s.sh`

**Result**: The main dashboard ingress at `dashboard.fkstrading.xyz` will work, and the conflict error will no longer appear.

---

## 🔍 Remaining Issues to Investigate

### CrashLoopBackOff Services

These services are still crashing and need investigation:

1. **fks-ai** - Check logs for startup errors
2. **fks-analyze** - Check logs for startup errors
3. **fks-execution** - Check logs for startup errors
4. **fks-main** - Check logs for startup errors
5. **fks-meta** - Check logs for startup errors
6. **fks-monitor** - Check logs for startup errors
7. **fks-portfolio** - Check logs for startup errors
8. **fks-training** - Check logs for startup errors
9. **tailscale-connector** - Check logs for startup errors

**Investigation Commands**:
```bash
# Check logs for each service
for service in fks-ai fks-analyze fks-execution fks-main fks-meta fks-monitor fks-portfolio fks-training; do
    echo "=== $service ==="
    kubectl logs -n fks-trading deployment/$service --previous --tail=50
    echo ""
done

# Check pod events
kubectl describe pod -n fks-trading <pod-name>
```

**Common Causes**:
- Missing environment variables
- Database connection failures
- Missing secrets
- Health check failures
- Resource constraints (CPU/memory)
- Missing dependencies (other services not ready)

---

## 📊 Expected Status After Fixes

After applying the image fixes:

| Service | Before | After (Expected) |
|---------|--------|------------------|
| fks-web | ❌ ImagePullBackOff | ✅ Should start |
| celery-worker | ❌ ImagePullBackOff | ✅ Should start |
| celery-beat | ❌ ImagePullBackOff | ✅ Should start |
| flower | ❌ ImagePullBackOff | ✅ Should start |
| fks-ai | ❌ CrashLoopBackOff | ⚠️ Needs investigation |
| fks-analyze | ❌ CrashLoopBackOff | ⚠️ Needs investigation |
| fks-execution | ❌ CrashLoopBackOff | ⚠️ Needs investigation |
| fks-main | ❌ CrashLoopBackOff | ⚠️ Needs investigation |
| fks-meta | ❌ CrashLoopBackOff | ⚠️ Needs investigation |
| fks-monitor | ❌ CrashLoopBackOff | ⚠️ Needs investigation |
| fks-portfolio | ❌ CrashLoopBackOff | ⚠️ Needs investigation |
| fks-training | ❌ CrashLoopBackOff | ⚠️ Needs investigation |

---

## 🚀 Next Steps

1. **Apply the fixes**:
   ```bash
   kubectl apply -f repo/k8s/manifests/all-services.yaml -n fks-trading
   ```

2. **Wait for pods to restart** (2-3 minutes):
   ```bash
   kubectl get pods -n fks-trading -w
   ```

3. **Check if ImagePullBackOff is resolved**:
   ```bash
   kubectl get pods -n fks-trading | grep -E "ImagePullBackOff|Init:ImagePullBackOff"
   ```
   Should return no results if fixed.

4. **Investigate CrashLoopBackOff services**:
   ```bash
   # Check logs for a specific service
   kubectl logs -n fks-trading deployment/fks-ai --previous
   
   # Check events
   kubectl describe pod -n fks-trading <pod-name>
   ```

5. **Check service dependencies**:
   - Ensure PostgreSQL is ready: `kubectl get pod postgres-0 -n fks-trading`
   - Ensure Redis is ready: `kubectl get pod -l app=redis -n fks-trading`
   - Some services may need these to be ready before starting

---

## 📝 Notes

- The timeout messages during deployment are normal - services take time to start
- Some services may need other services to be running first (dependency chain)
- Consider adding init containers or startup probes for services with dependencies
- The `fks-auth` service has restarted 4 times - investigate why

---

**Files Modified**:
- `repo/k8s/manifests/all-services.yaml` - Fixed image references
- `repo/k8s/setup-local-k8s.sh` - Fixed ingress conflict handling
- `repo/k8s/K8S_STARTUP_ISSUES.md` - Created analysis document
- `repo/k8s/FIXES_APPLIED.md` - This document

**Last Updated**: 2025-11-12

