#!/bin/bash
# Deploy service to Kubernetes via SSH jump server
# Usage: ./deploy-service.sh <service-name> <image> [namespace] [deployment-name] [container-name]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
JUMP_SERVER="${JUMP_SERVER:-github.fkstrading.xyz}"
JUMP_USER="${JUMP_USER:-root}"
K8S_HOST="${K8S_HOST:-}"  # Tailscale IP or hostname
K8S_USER="${K8S_USER:-root}"
NAMESPACE="${NAMESPACE:-fks-trading}"

# Parameters
SERVICE_NAME="${1:-}"
IMAGE="${2:-}"
NAMESPACE="${3:-$NAMESPACE}"
DEPLOYMENT_NAME="${4:-}"
CONTAINER_NAME="${5:-}"

# Validate parameters
if [ -z "$SERVICE_NAME" ] || [ -z "$IMAGE" ]; then
    echo -e "${RED}❌ Usage: $0 <service-name> <image> [namespace] [deployment-name] [container-name]${NC}"
    echo "   Example: $0 api nuniesmith/fks:api-latest"
    exit 1
fi

# Set defaults
if [ -z "$DEPLOYMENT_NAME" ]; then
    DEPLOYMENT_NAME="fks-$SERVICE_NAME"
fi
if [ -z "$CONTAINER_NAME" ]; then
    CONTAINER_NAME="$DEPLOYMENT_NAME"
fi

echo -e "${GREEN}🚀 Deploying $SERVICE_NAME to Kubernetes${NC}"
echo "   Image: $IMAGE"
echo "   Deployment: $DEPLOYMENT_NAME"
echo "   Container: $CONTAINER_NAME"
echo "   Namespace: $NAMESPACE"
echo "   Jump Server: $JUMP_SERVER"
if [ -n "$K8S_HOST" ]; then
    echo "   K8s Host: $K8S_HOST"
fi
echo ""

# Function to run kubectl command
run_kubectl() {
    local cmd="$1"
    if [ -n "$K8S_HOST" ]; then
        # SSH into K8s server via jump server
        ssh -o ProxyJump=$JUMP_USER@$JUMP_SERVER $K8S_USER@$K8S_HOST "$cmd"
    else
        # Run kubectl on jump server
        ssh $JUMP_USER@$JUMP_SERVER "$cmd"
    fi
}

# Check if deployment exists
echo "📋 Checking if deployment exists..."
if run_kubectl "kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Deployment $DEPLOYMENT_NAME exists${NC}"
    
    # Get current image
    CURRENT_IMAGE=$(run_kubectl "kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}'" 2>/dev/null || echo "")
    if [ -n "$CURRENT_IMAGE" ]; then
        echo "   Current image: $CURRENT_IMAGE"
    fi
    echo "   New image: $IMAGE"
    
    # Update deployment
    echo ""
    echo "🔄 Updating deployment..."
    if run_kubectl "kubectl set image deployment/$DEPLOYMENT_NAME $CONTAINER_NAME=$IMAGE -n $NAMESPACE"; then
        echo -e "${GREEN}✅ Image updated${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to update image, trying alternative method...${NC}"
        # Try patching deployment
        PATCH_JSON="{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$CONTAINER_NAME\",\"image\":\"$IMAGE\"}]}}}}"
        if run_kubectl "kubectl patch deployment $DEPLOYMENT_NAME -n $NAMESPACE -p '$PATCH_JSON'"; then
            echo -e "${GREEN}✅ Image updated via patch${NC}"
        else
            echo -e "${RED}❌ Failed to update deployment${NC}"
            exit 1
        fi
    fi
    
    # Restart deployment to ensure new image is pulled
    echo ""
    echo "🔄 Restarting deployment..."
    if run_kubectl "kubectl rollout restart deployment/$DEPLOYMENT_NAME -n $NAMESPACE"; then
        echo -e "${GREEN}✅ Deployment restart triggered${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to restart deployment, but image update may have worked${NC}"
    fi
    
    # Wait for rollout
    echo ""
    echo "⏳ Waiting for rollout to complete..."
    if run_kubectl "kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=300s"; then
        echo -e "${GREEN}✅ Rollout completed successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Rollout timeout, but deployment may still be updating${NC}"
    fi
    
    # Show deployment status
    echo ""
    echo "📊 Deployment status:"
    run_kubectl "kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE"
    echo ""
    echo "📊 Pod status:"
    run_kubectl "kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME" || \
    run_kubectl "kubectl get pods -n $NAMESPACE | grep $SERVICE_NAME" || \
    echo "   (No pods found with app=$SERVICE_NAME label)"
    
else
    echo -e "${RED}❌ Deployment $DEPLOYMENT_NAME not found in namespace $NAMESPACE${NC}"
    echo ""
    echo "Available deployments:"
    run_kubectl "kubectl get deployments -n $NAMESPACE" || true
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"

