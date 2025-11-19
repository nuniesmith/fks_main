#!/bin/bash
# Clean up old replica sets with 0 replicas in fks-trading namespace

set -e

NAMESPACE="fks-trading"
DRY_RUN="${1:-}"

echo "=========================================="
echo "Cleaning up old ReplicaSets"
echo "=========================================="
echo ""

# Get all replica sets with 0 replicas
OLD_RS=$(kubectl get replicasets -n "$NAMESPACE" -o json | \
  jq -r '.items[] | select(.status.replicas == 0) | .metadata.name')

if [ -z "$OLD_RS" ]; then
  echo "✓ No old replica sets to clean up"
  exit 0
fi

COUNT=$(echo "$OLD_RS" | wc -l)
echo "Found $COUNT replica sets with 0 replicas:"
echo "$OLD_RS" | head -10
if [ "$COUNT" -gt 10 ]; then
  echo "... and $((COUNT - 10)) more"
fi
echo ""

if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "DRY RUN - Would delete the above replica sets"
  exit 0
fi

# Delete old replica sets
echo "Deleting old replica sets..."
echo "$OLD_RS" | while read -r rs; do
  if [ -n "$rs" ]; then
    echo "  Deleting $rs..."
    kubectl delete replicaset "$rs" -n "$NAMESPACE" --ignore-not-found=true
  fi
done

echo ""
echo "✓ Cleanup complete!"
echo ""
echo "Remaining replica sets:"
kubectl get replicasets -n "$NAMESPACE" --no-headers | wc -l

