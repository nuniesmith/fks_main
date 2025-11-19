#!/bin/bash
# Script to update web service with latest image from DockerHub
# This pulls the image built by GitHub Actions after a push to main

set -e

echo "🔄 Updating FKS Web Service from DockerHub"
echo "==========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "k8s/manifests/all-services.yaml" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Get the latest commit SHA (short form)
COMMIT_SHA=$(git rev-parse --short HEAD)
echo "📝 Current commit: $COMMIT_SHA"
echo ""

# Available image tags from GitHub Actions:
# - nuniesmith/fks:web-main (latest on main branch)
# - nuniesmith/fks:web-main-{sha} (specific commit)
# - nuniesmith/fks:web-latest (alias for web-main)

echo "🐳 Pulling latest web image from DockerHub..."
docker pull nuniesmith/fks:web-main
echo ""

echo "📦 Loading image into minikube..."
minikube image load nuniesmith/fks:web-main
echo ""

echo "🔧 Updating Kubernetes deployment..."
# Update the image in all-services.yaml (if needed)
# For now, we'll just restart the deployment to pull new image

# Set image for all web-related deployments
kubectl set image deployment/fks-web web=nuniesmith/fks:web-main:latest -n fks-trading
kubectl set image deployment/celery-worker worker=nuniesmith/fks:web-main:latest -n fks-trading
kubectl set image deployment/celery-beat beat=nuniesmith/fks:web-main:latest -n fks-trading
kubectl set image deployment/flower flower=nuniesmith/fks:web-main:latest -n fks-trading

echo ""
echo "⏳ Waiting for rollout to complete..."
kubectl rollout status deployment/fks-web -n fks-trading --timeout=300s
kubectl rollout status deployment/celery-worker -n fks-trading --timeout=300s
kubectl rollout status deployment/celery-beat -n fks-trading --timeout=300s
kubectl rollout status deployment/flower -n fks-trading --timeout=300s

echo ""
echo "✅ Update complete!"
echo ""
echo "📊 Current pod status:"
kubectl get pods -n fks-trading | grep -E "NAME|web|celery|flower"
echo ""
echo "🧪 Testing health endpoint..."
sleep 5
kubectl exec -it deployment/fks-web -n fks-trading -- curl -s http://localhost:8000/health | head -10 || echo "Health check pending..."
echo ""
echo "🎯 Web UI should now be accessible at:"
echo "   https://fkstrading.xyz"
echo "   https://fkstrading.xyz/admin/"
