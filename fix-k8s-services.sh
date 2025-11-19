#!/usr/bin/env bash
set -euo pipefail

# Fix K8s Services - Rebuild and redeploy failing services
# This script identifies failing pods, rebuilds their images, loads into Minikube, and restarts them

NAMESPACE="fks-trading"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║        FKS K8s Service Fix • fkstrading.xyz              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Get failing services
echo "[1/5] Identifying failing services..."
FAILING_SERVICES=$(kubectl get pods -n "$NAMESPACE" -o json | \
  jq -r '.items[] | select(.status.phase != "Running" or 
    (.status.containerStatuses[]? | select(.ready == false))) | 
    .metadata.labels.app // .metadata.name' | \
  sed 's/^fks-//' | sed 's/^celery-.*/web/' | sort -u)

echo "Failing services:"
echo "$FAILING_SERVICES" | sed 's/^/  - /'
echo ""

# For each failing service, check the error
echo "[2/5] Analyzing failures..."
for service in $FAILING_SERVICES; do
  echo "=== $service ==="
  POD=$(kubectl get pods -n "$NAMESPACE" -l "app=fks-$service" -o name 2>/dev/null | head -1 || \
        kubectl get pods -n "$NAMESPACE" -l "app=$service" -o name 2>/dev/null | head -1)
  if [ -n "$POD" ]; then
    kubectl logs -n "$NAMESPACE" "$POD" --tail=5 2>&1 | grep -E "(Error|ModuleNotFoundError|No such file)" || echo "  (Check full logs)"
  fi
  echo ""
done

# Ask for confirmation
read -p "Do you want to rebuild and redeploy these services? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Aborted."
  exit 0
fi

# Rebuild images
echo "[3/5] Rebuilding Docker images..."
for service in $FAILING_SERVICES; do
  if [ "$service" = "celery-worker" ] || [ "$service" = "celery-beat" ] || [ "$service" = "flower" ]; then
    service="web"  # These use the web image
  fi
  
  SERVICE_DIR="$REPO_DIR/$service"
  if [ ! -d "$SERVICE_DIR" ]; then
    echo "  ⚠  Service directory not found: $SERVICE_DIR (skipping)"
    continue
  fi
  
  echo "  → Building $service..."
  cd "$SERVICE_DIR"
  
  if [ -f "Dockerfile" ]; then
    docker build -t "nuniesmith/fks:${service}-latest" . 2>&1 | tail -3
    echo "    ✓ Built nuniesmith/fks:${service}-latest"
  else
    echo "    ⚠  No Dockerfile found (skipping)"
  fi
done
echo ""

# Load images into Minikube
echo "[4/5] Loading images into Minikube..."
for service in $FAILING_SERVICES; do
  if [ "$service" = "celery-worker" ] || [ "$service" = "celery-beat" ] || [ "$service" = "flower" ]; then
    service="web"
  fi
  
  IMAGE="nuniesmith/fks:${service}-latest"
  if docker image inspect "$IMAGE" &>/dev/null; then
    echo "  → Loading $IMAGE..."
    minikube image load "$IMAGE" 2>&1 | grep -E "(Loaded|already)" || echo "    ✓ Loaded"
  fi
done
echo ""

# Restart deployments
echo "[5/5] Restarting deployments..."
for service in $FAILING_SERVICES; do
  DEPLOYMENT="fks-$service"
  if kubectl get deployment -n "$NAMESPACE" "$DEPLOYMENT" &>/dev/null; then
    echo "  → Restarting $DEPLOYMENT..."
    kubectl rollout restart deployment "$DEPLOYMENT" -n "$NAMESPACE"
  else
    # Try without fks- prefix
    if kubectl get deployment -n "$NAMESPACE" "$service" &>/dev/null; then
      echo "  → Restarting $service..."
      kubectl rollout restart deployment "$service" -n "$NAMESPACE"
    fi
  fi
done
echo ""

echo "✓ Fix process complete!"
echo ""
echo "Wait a few moments, then check status with:"
echo "  kubectl get pods -n fks-trading"
echo ""
echo "Or use the dashboard:"
echo "  ./k8s/access-dashboard.sh"
