# ReplicaSet Cleanup Guide

**Issue**: Too many ReplicaSets (434+) cluttering the Kubernetes dashboard  
**Cause**: Kubernetes keeps old ReplicaSets for rollback purposes  
**Solution**: Clean up old ReplicaSets and set appropriate `revisionHistoryLimit`

---

## Why So Many ReplicaSets?

Kubernetes creates a new ReplicaSet every time a Deployment is updated:
- New Docker image
- Configuration change
- Environment variable update
- Any deployment update

By default, Kubernetes keeps **10 old ReplicaSets** per deployment for rollback purposes (`revisionHistoryLimit: 10`).

With 20+ deployments that have been updated many times, you can easily accumulate 200+ ReplicaSets.

---

## Quick Cleanup

### Option 1: Automated Script (Recommended)

```bash
cd /home/jordan/Nextcloud/code/repos/fks/repo/k8s

# Dry run first (see what would be deleted)
./scripts/cleanup-old-replicasets.sh --dry-run

# Actually delete old replica sets
./scripts/cleanup-old-replicasets.sh
```

### Option 2: Manual Cleanup

```bash
# Delete all replica sets with 0 replicas
kubectl get replicasets -n fks-trading -o json | \
  jq -r '.items[] | select(.status.replicas == 0) | .metadata.name' | \
  xargs -I {} kubectl delete replicaset {} -n fks-trading

# Or using kubectl directly
kubectl delete replicaset -n fks-trading \
  $(kubectl get replicasets -n fks-trading -o json | \
    jq -r '.items[] | select(.status.replicas == 0) | .metadata.name')
```

---

## Prevent Future Buildup

### Set Lower revisionHistoryLimit

Add to your deployment manifests:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fks-web
spec:
  revisionHistoryLimit: 3  # Keep only 3 old replica sets (default is 10)
  # ... rest of deployment
```

### Update Existing Deployments

```bash
# Set revisionHistoryLimit to 3 for all deployments
kubectl patch deployment -n fks-trading --all -p '{"spec":{"revisionHistoryLimit":3}}'
```

---

## Verify Cleanup

```bash
# Count remaining replica sets
kubectl get replicasets -n fks-trading --no-headers | wc -l

# List active replica sets (with pods)
kubectl get replicasets -n fks-trading | grep -v "0 /0"

# List old replica sets (no pods)
kubectl get replicasets -n fks-trading | grep "0 /0"
```

---

## Safe to Delete?

✅ **Safe to delete**:
- ReplicaSets with 0 replicas (no pods)
- Old ReplicaSets that are not the current one

❌ **Do NOT delete**:
- ReplicaSets with active pods
- The current ReplicaSet for each deployment

The cleanup script only deletes ReplicaSets with 0 replicas, which is safe.

---

## Expected Results

**Before**: 434+ ReplicaSets  
**After**: ~20-40 ReplicaSets (one per deployment, plus a few recent ones for rollback)

This will make the Kubernetes dashboard much cleaner and easier to navigate!

---

## Script Location

`repo/k8s/scripts/cleanup-old-replicasets.sh`

Run it whenever you notice too many ReplicaSets accumulating.

