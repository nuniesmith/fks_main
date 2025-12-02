#!/bin/bash
# Setup script for development volume mounts in Minikube
# This script mounts your local code directories into Minikube for hot-reloading

set -e

REPO_ROOT="/home/jordan/Nextcloud/code/repos/fks"
MINIKUBE_MOUNT_BASE="/mnt/fks-dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if minikube is running
if ! minikube status &>/dev/null; then
    log_error "Minikube is not running. Please start minikube first: minikube start"
    exit 1
fi

log_info "Setting up development volume mounts for Minikube..."
log_info "This will mount your local code directories into Minikube for hot-reloading"

# Create mount points in minikube
log_info "Creating mount points in Minikube VM..."

# Web service mounts
if [ -d "$REPO_ROOT/repo/web" ]; then
    log_info "Mounting web service code..."
    minikube mount "$REPO_ROOT/repo/web/src:$MINIKUBE_MOUNT_BASE/web/src" &
    WEB_MOUNT_PID=$!
    log_success "Web service code mounted (PID: $WEB_MOUNT_PID)"
    echo "$WEB_MOUNT_PID" > /tmp/minikube-mount-web.pid
else
    log_warning "Web service directory not found: $REPO_ROOT/repo/web"
fi

# API service mounts (if exists)
if [ -d "$REPO_ROOT/repo/api" ]; then
    log_info "Mounting API service code..."
    minikube mount "$REPO_ROOT/repo/api/src:$MINIKUBE_MOUNT_BASE/api/src" &
    API_MOUNT_PID=$!
    log_success "API service code mounted (PID: $API_MOUNT_PID)"
    echo "$API_MOUNT_PID" > /tmp/minikube-mount-api.pid
fi

# App service mounts (if exists)
if [ -d "$REPO_ROOT/repo/app" ]; then
    log_info "Mounting app service code..."
    minikube mount "$REPO_ROOT/repo/app/src:$MINIKUBE_MOUNT_BASE/app/src" &
    APP_MOUNT_PID=$!
    log_success "App service code mounted (PID: $APP_MOUNT_PID)"
    echo "$APP_MOUNT_PID" > /tmp/minikube-mount-app.pid
fi

log_success "Development mounts setup complete!"
log_info "Mount processes are running in the background"
log_info "To stop mounts, run: ./stop-dev-mounts.sh"
log_info ""
log_info "Next steps:"
log_info "1. Apply the updated Helm chart with dev values:"
log_info "   helm upgrade --install fks-platform ./docker/k8s/charts/fks-platform \\"
log_info "     -n fks-trading --create-namespace -f ./docker/k8s/charts/fks-platform/values-dev.yaml"
log_info ""
log_info "2. Or patch existing deployments with:"
log_info "   kubectl patch deployment fks-web -n fks-trading --patch-file dev-mount-patch.yaml"

