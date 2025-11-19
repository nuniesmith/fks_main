#!/bin/bash
# Script to update deployments after Docker images are rebuilt
# Run this after GitHub Actions builds complete

set -e

NAMESPACE="fks-trading"

echo "=========================================="
echo "Updating Deployments with New Images"
echo "=========================================="
echo ""

# Services that were fixed
SERVICES=(
    "fks-meta"
    "fks-monitor"
    "fks-ai"
    "fks-analyze"
    "fks-training"
)

echo "Restarting deployments to pull new images..."
echo ""

for service in "${SERVICES[@]}"; do
    echo "  Restarting $service..."
    kubectl rollout restart deployment/$service -n $NAMESPACE
done

echo ""
echo "Waiting for rollouts to complete..."
echo ""

for service in "${SERVICES[@]}"; do
    echo "  Waiting for $service..."
    kubectl rollout status deployment/$service -n $NAMESPACE --timeout=300s || echo "    ⚠️  $service rollout timed out or failed"
done

echo ""
echo "=========================================="
echo "Checking Service Status"
echo "=========================================="
echo ""

kubectl get pods -n $NAMESPACE -l 'app in (fks-meta,fks-monitor,fks-ai,fks-analyze,fks-training)'

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="

