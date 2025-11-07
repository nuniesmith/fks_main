#!/bin/bash
# Build FKS Docker images in Minikube's Docker daemon
# This allows Kubernetes to use local images without a registry

set -e

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Building FKS Images for Minikube                    ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Configure Docker to use minikube's daemon
echo "📦 Configuring Docker to use minikube's daemon..."
eval $(minikube -p minikube docker-env)

# Change to project root
cd /home/jordan/Documents/fks

echo ""
echo "🔨 Building images..."
echo ""

# Build each service
build_image() {
    local dockerfile=$1
    local image_name=$2
    
    echo "  Building $image_name..."
    if [ -f "$dockerfile" ]; then
        docker build -f "$dockerfile" -t "fks/$image_name:latest" . > /tmp/docker-build-$image_name.log 2>&1
        if [ $? -eq 0 ]; then
            echo "    ✅ $image_name built successfully"
        else
            echo "    ❌ $image_name build failed (see /tmp/docker-build-$image_name.log)"
            return 1
        fi
    else
        echo "    ⚠️  $dockerfile not found, skipping"
    fi
}

# Build all images
build_image "docker/Dockerfile" "main"
build_image "docker/Dockerfile.api" "api"
build_image "docker/Dockerfile.app" "app"
build_image "docker/Dockerfile.ai" "ai"
build_image "docker/Dockerfile.data" "data"
build_image "docker/Dockerfile.execution" "execution"
build_image "docker/Dockerfile.ninja" "ninja"
build_image "docker/Dockerfile.web_ui" "web"

# Try to build MT5 if it exists
if [ -f "docker/Dockerfile.mt5" ]; then
    build_image "docker/Dockerfile.mt5" "mt5"
else
    echo "  ⚠️  MT5 Dockerfile not found, using main image as fallback"
    docker tag fks/main:latest fks/mt5:latest
fi

echo ""
echo "🔄 Updating Kubernetes deployments..."
echo ""

# Update imagePullPolicy to Never (use local images)
deployments=("fks-main" "fks-api" "fks-app" "fks-ai" "fks-data" "fks-execution" "fks-ninja" "fks-mt5" "fks-web")

for deployment in "${deployments[@]}"; do
    echo "  Patching $deployment..."
    kubectl patch deployment "$deployment" -n fks-trading \
        -p '{"spec":{"template":{"spec":{"containers":[{"name":"'$deployment'","imagePullPolicy":"Never"}]}}}}' \
        > /dev/null 2>&1 || echo "    ⚠️  Warning: Could not patch $deployment"
done

echo ""
echo "🔄 Restarting deployments..."
kubectl rollout restart deployment -n fks-trading

echo ""
echo "⏳ Waiting for rollout to complete (this may take a few minutes)..."
sleep 5

echo ""
echo "📊 Deployment status:"
kubectl get pods -n fks-trading

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Images built and deployments restarted!             ║"
echo "║  Wait 1-2 minutes for pods to start                  ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "💡 To monitor progress: kubectl get pods -n fks-trading --watch"
echo ""
