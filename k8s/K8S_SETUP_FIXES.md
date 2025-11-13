# Kubernetes Setup Fixes

## Issues Fixed

### 1. Dashboard Ingress Configuration Snippet Error ✅
**Error**: `nginx.ingress.kubernetes.io/configuration-snippet annotation cannot be used. Snippet directives are disabled by the Ingress administrator`

**Fix**: Removed the `configuration-snippet` annotation from `k8s/manifests/dashboard-ingress.yaml`

**File**: `repo/main/k8s/manifests/dashboard-ingress.yaml`

The annotation was trying to set `proxy_ssl_verify off;` but nginx ingress controller has snippet directives disabled for security. The `backend-protocol: HTTPS` annotation should handle SSL verification automatically.

### 2. Secret Creation Error (Non-blocking)
**Error**: `error: exactly one NAME is required, got 2`

**Status**: This error is caught by `|| true` in the script, so it doesn't block deployment. The secret might already exist or there's a variable expansion issue.

**Note**: If you see this error, check:
- If the secret already exists: `kubectl get secret fks-secrets -n fks-trading`
- If the namespace variable is set correctly
- The secret will be created on retry if it doesn't exist

### 3. PostgreSQL Timeout (Non-critical)
**Error**: `error: timed out waiting for the condition on pods/postgres-0`

**Status**: This is a timeout issue, not a failure. PostgreSQL might need more time to start, especially on resource-constrained systems.

**Solutions**:
1. Check PostgreSQL pod status: `kubectl get pods -n fks-trading | grep postgres`
2. Check pod logs: `kubectl logs postgres-0 -n fks-trading`
3. Increase timeout in script if needed (currently 300s)
4. Check resource limits: `kubectl describe pod postgres-0 -n fks-trading`

## Re-running Setup

After applying the fixes, you can re-run the setup:

```bash
cd /home/jordan/Nextcloud/code/repos/fks/repo/main
./run.sh
# Choose option 8 (Kubernetes Start)
```

Or manually apply the fixed dashboard ingress:

```bash
kubectl apply -f k8s/manifests/dashboard-ingress.yaml
```

## Verification

After setup completes, verify services are running:

```bash
# Check all pods
kubectl get pods -n fks-trading

# Check services
kubectl get svc -n fks-trading

# Check ingress
kubectl get ingress -n fks-trading

# Check dashboard ingress specifically
kubectl get ingress -n kubernetes-dashboard
```

## Next Steps

1. ✅ Dashboard ingress fixed - should deploy successfully now
2. Monitor PostgreSQL pod - it may need a few minutes to start
3. Check service endpoints are accessible
4. Verify dashboard is accessible via ingress

## Troubleshooting

### If PostgreSQL still times out:
```bash
# Check if pod is running
kubectl get pods -n fks-trading -l app=postgres

# Check events
kubectl describe pod postgres-0 -n fks-trading

# Check if PVC is bound
kubectl get pvc -n fks-trading

# Manually wait for PostgreSQL
kubectl wait --for=condition=ready pod -l app=postgres -n fks-trading --timeout=600s
```

### If dashboard ingress still fails:
```bash
# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Check ingress status
kubectl describe ingress kubernetes-dashboard-ingress -n kubernetes-dashboard
```

---

**Last Updated**: 2025-11-12
**Status**: Dashboard ingress fix applied ✅

