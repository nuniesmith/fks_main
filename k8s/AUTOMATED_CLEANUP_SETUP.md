# Automated ReplicaSet Cleanup - Setup Complete ✅

**Date**: 2025-11-12  
**Status**: ✅ **Configured**

---

## What Was Set Up

A Kubernetes CronJob that automatically cleans up old ReplicaSets on a schedule.

### Components Created

1. **ConfigMap** (`replicaset-cleanup-script`)
   - Contains the cleanup script
   - Can be updated without recreating the CronJob

2. **ServiceAccount** (`replicaset-cleanup`)
   - Used by the CronJob to authenticate

3. **Role & RoleBinding**
   - Grants permissions to:
     - Get, list, and delete ReplicaSets
     - Get ConfigMaps (to read the script)

4. **CronJob** (`replicaset-cleanup`)
   - Runs weekly on Sunday at 2 AM
   - Uses `bitnami/kubectl` image
   - Keeps last 3 successful jobs for history
   - Prevents concurrent runs

---

## Schedule

**Default**: Every Sunday at 2 AM (`0 2 * * 0`)

### Schedule Options

You can change the schedule by editing the CronJob:

```bash
kubectl edit cronjob replicaset-cleanup -n fks-trading
```

**Common schedules**:
- `0 2 * * 0` - Weekly (Sunday 2 AM) - **Current**
- `0 3 * * *` - Daily (3 AM)
- `0 */6 * * *` - Every 6 hours
- `0 0 * * 0` - Weekly (Sunday midnight)

---

## Manual Execution

You can manually trigger the cleanup job:

```bash
# Create a one-time job from the CronJob
kubectl create job --from=cronjob/replicaset-cleanup manual-cleanup-$(date +%s) -n fks-trading

# Watch the job
kubectl get jobs -n fks-trading -l app=replicaset-cleanup -w

# Check logs
kubectl logs -n fks-trading job/manual-cleanup-<timestamp> -f
```

---

## Monitoring

### Check CronJob Status

```bash
# View CronJob
kubectl get cronjob replicaset-cleanup -n fks-trading

# View recent jobs
kubectl get jobs -n fks-trading -l app=replicaset-cleanup

# View job history
kubectl get jobs -n fks-trading -l app=replicaset-cleanup --sort-by=.metadata.creationTimestamp
```

### View Logs

```bash
# Get latest job
JOB=$(kubectl get jobs -n fks-trading -l app=replicaset-cleanup --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')

# View logs
kubectl logs -n fks-trading job/$JOB
```

---

## Alternative: Daily Cleanup

If you want more frequent cleanup, there's also a daily version available:

```bash
# Apply daily version (runs at 3 AM daily)
kubectl apply -f manifests/replicaset-cleanup-cronjob-daily.yaml

# Or disable weekly and enable daily
kubectl patch cronjob replicaset-cleanup -n fks-trading -p '{"spec":{"suspend":true}}'
kubectl apply -f manifests/replicaset-cleanup-cronjob-daily.yaml
```

---

## Updating the Script

To update the cleanup script:

1. Edit the script in `repo/k8s/scripts/cleanup-old-replicasets.sh`
2. Update the ConfigMap:
   ```bash
   kubectl create configmap replicaset-cleanup-script \
     --from-file=cleanup.sh=repo/k8s/scripts/cleanup-old-replicasets.sh \
     -n fks-trading \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

The next CronJob run will use the updated script.

---

## Verification

```bash
# Check CronJob is created
kubectl get cronjob replicaset-cleanup -n fks-trading

# Check RBAC is set up
kubectl get role,rolebinding,serviceaccount -n fks-trading | grep replicaset-cleanup

# Check ConfigMap exists
kubectl get configmap replicaset-cleanup-script -n fks-trading

# Test run manually
kubectl create job --from=cronjob/replicaset-cleanup test-cleanup-$(date +%s) -n fks-trading
kubectl logs -n fks-trading -l app=replicaset-cleanup --tail=50
```

---

## Troubleshooting

### CronJob Not Running

```bash
# Check if suspended
kubectl get cronjob replicaset-cleanup -n fks-trading -o jsonpath='{.spec.suspend}'

# Unsuspend if needed
kubectl patch cronjob replicaset-cleanup -n fks-trading -p '{"spec":{"suspend":false}}'
```

### Permission Issues

```bash
# Check ServiceAccount
kubectl get serviceaccount replicaset-cleanup -n fks-trading

# Check RoleBinding
kubectl describe rolebinding replicaset-cleanup -n fks-trading

# Test permissions
kubectl auth can-i delete replicasets --as=system:serviceaccount:fks-trading:replicaset-cleanup -n fks-trading
```

### Job Failing

```bash
# Get failed jobs
kubectl get jobs -n fks-trading -l app=replicaset-cleanup --field-selector status.successful!=1

# View logs
kubectl logs -n fks-trading job/<job-name>
```

---

## Files Created

- `manifests/replicaset-cleanup-cronjob.yaml` - Main CronJob (weekly)
- `manifests/replicaset-cleanup-cronjob-daily.yaml` - Alternative (daily)
- `AUTOMATED_CLEANUP_SETUP.md` - This documentation

---

## Summary

✅ **CronJob created** - Runs weekly on Sunday at 2 AM  
✅ **RBAC configured** - Proper permissions set  
✅ **ConfigMap created** - Script stored in cluster  
✅ **Automatic cleanup** - No manual intervention needed

**Your ReplicaSets will now be automatically cleaned up!** 🎉

