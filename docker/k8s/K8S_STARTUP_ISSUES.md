# Kubernetes Startup Issues Analysis

**Date**: 2025-11-12  
**Status**: Multiple services failing to start

## 🔴 Critical Issues

### 1. ImagePullBackOff Errors

**Affected Services**:
- `celery-beat` - Using `nuniesmith/fks:web-v9` (image not found)
- `celery-worker` - Using `nuniesmith/fks:web-v9` (image not found)
- `flower` - Using `nuniesmith/fks:web-v9` (image not found)
- `fks-web` (initContainer) - Using `nuniesmith/fks:web-v9` (image not found)

**Root Cause**: The manifests are using `nuniesmith/fks:web-v9` but this image doesn't exist on Docker Hub. The correct image should be `nuniesmith/fks:web-latest`.

**Fix**: Update `all-services.yaml` to use `web-latest` instead of `web-v9`.

---

### 2. CrashLoopBackOff Errors

**Affected Services**:
- `fks-ai` - Crashing repeatedly
- `fks-analyze` - Crashing repeatedly
- `fks-execution` - Crashing repeatedly
- `fks-main` - Crashing repeatedly
- `fks-meta` - Crashing repeatedly
- `fks-monitor` - Crashing repeatedly
- `fks-portfolio` - Crashing repeatedly
- `fks-training` - Crashing repeatedly
- `tailscale-connector` - Crashing repeatedly

**Possible Causes**:
1. **Missing environment variables** - Services may need database URLs, API keys, etc.
2. **Health check failures** - Services may be failing health checks
3. **Missing dependencies** - Services may need other services to be running first
4. **Configuration errors** - Invalid config values
5. **Resource constraints** - Not enough CPU/memory

**Investigation Needed**: Check pod logs to identify specific errors:
```bash
kubectl logs -n fks-trading <pod-name> --previous
kubectl describe pod -n fks-trading <pod-name>
```

---

### 3. Ingress Conflict

**Error**: 
```
Error from server (BadRequest): error when creating "/home/jordan/Nextcloud/code/repos/fks/repo/main/k8s/manifests/dashboard-ingress-auto-login.yaml": admission webhook "validate.nginx.ingress.kubernetes.io" denied the request: host "dashboard.fkstrading.xyz" and path "/" is already defined in ingress kubernetes-dashboard/kubernetes-dashboard-ingress
```

**Root Cause**: The `dashboard-ingress-auto-login.yaml` is trying to create an ingress with the same host and path as the existing `kubernetes-dashboard-ingress`.

**Fix**: Either:
1. Remove the auto-login ingress (non-critical)
2. Use a different host/path for the auto-login ingress
3. Merge the configurations into a single ingress

---

## ✅ Working Services

These services are running successfully:
- ✅ `fks-api` (2/2 pods running)
- ✅ `fks-app` (2/2 pods running)
- ✅ `fks-auth` (1/1 pod running, but with 4 restarts - needs investigation)
- ✅ `fks-data` (2/2 pods running)
- ✅ `fks-ninja` (1/1 pod running)
- ✅ `postgres-0` (1/1 pod running)
- ✅ `redis` (1/1 pod running)

---

## 🔧 Immediate Fixes Required

### Fix 1: Update Web Image References

**File**: `repo/k8s/manifests/all-services.yaml`

**Changes needed**:
- Line 195: Change `nuniesmith/fks:web-v9` → `nuniesmith/fks:web-latest`
- Line 232: Change `nuniesmith/fks:web-v9` → `nuniesmith/fks:web-latest`
- Line 606: Change `nuniesmith/fks:web-v9` → `nuniesmith/fks:web-latest` (celery-worker)
- Line 664: Change `nuniesmith/fks:web-v9` → `nuniesmith/fks:web-latest` (celery-beat)
- Line 736: Change `nuniesmith/fks:web-v9` → `nuniesmith/fks:web-latest` (flower)

### Fix 2: Investigate CrashLoopBackOff Services

**Commands to run**:
```bash
# Check logs for each failing service
kubectl logs -n fks-trading deployment/fks-ai --previous
kubectl logs -n fks-trading deployment/fks-analyze --previous
kubectl logs -n fks-trading deployment/fks-execution --previous
kubectl logs -n fks-trading deployment/fks-main --previous
kubectl logs -n fks-trading deployment/fks-meta --previous
kubectl logs -n fks-trading deployment/fks-monitor --previous
kubectl logs -n fks-trading deployment/fks-portfolio --previous
kubectl logs -n fks-trading deployment/fks-training --previous

# Check pod events
kubectl describe pod -n fks-trading <pod-name>
```

### Fix 3: Remove or Fix Dashboard Auto-Login Ingress

**Option A**: Remove it (simplest)
```bash
kubectl delete -f repo/k8s/manifests/dashboard-ingress-auto-login.yaml
```

**Option B**: Fix the conflict by using a different path or removing the duplicate ingress definition.

---

## 📊 Service Status Summary

| Service | Status | Issue | Priority |
|---------|--------|-------|----------|
| fks-api | ✅ Running | None | - |
| fks-app | ✅ Running | None | - |
| fks-auth | ⚠️ Running | 4 restarts | Medium |
| fks-data | ✅ Running | None | - |
| fks-ninja | ✅ Running | None | - |
| fks-web | ❌ Failed | ImagePullBackOff | **High** |
| celery-worker | ❌ Failed | ImagePullBackOff | **High** |
| celery-beat | ❌ Failed | ImagePullBackOff | **High** |
| flower | ❌ Failed | ImagePullBackOff | **High** |
| fks-ai | ❌ Failed | CrashLoopBackOff | **High** |
| fks-analyze | ❌ Failed | CrashLoopBackOff | **High** |
| fks-execution | ❌ Failed | CrashLoopBackOff | **High** |
| fks-main | ❌ Failed | CrashLoopBackOff | **High** |
| fks-meta | ❌ Failed | CrashLoopBackOff | **High** |
| fks-monitor | ❌ Failed | CrashLoopBackOff | **High** |
| fks-portfolio | ❌ Failed | CrashLoopBackOff | **High** |
| fks-training | ❌ Failed | CrashLoopBackOff | **High** |
| postgres | ✅ Running | None | - |
| redis | ✅ Running | None | - |

---

## 🚀 Next Steps

1. **Fix image references** (5 minutes)
   - Update `all-services.yaml` to use `web-latest`
   - Apply changes: `kubectl apply -f repo/k8s/manifests/all-services.yaml`

2. **Investigate crashes** (30-60 minutes)
   - Check logs for each failing service
   - Identify common patterns (database connection, missing env vars, etc.)
   - Fix configuration issues

3. **Fix ingress conflict** (5 minutes)
   - Remove or fix the dashboard auto-login ingress

4. **Verify fixes** (10 minutes)
   - Wait for pods to restart
   - Check pod status: `kubectl get pods -n fks-trading`
   - Verify services are accessible

---

## 📝 Notes

- The timeout messages are expected - services are still starting up
- Some services may need other services to be running first (dependency chain)
- Consider adding init containers or startup probes for services with dependencies
- The `fks-auth` service has restarted 4 times - investigate why

---

**Last Updated**: 2025-11-12

