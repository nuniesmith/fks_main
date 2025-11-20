#!/bin/bash
# Stop development volume mounts in Minikube

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

log_info "Stopping development volume mounts..."

# Stop web mount
if [ -f /tmp/minikube-mount-web.pid ]; then
    PID=$(cat /tmp/minikube-mount-web.pid)
    if kill "$PID" 2>/dev/null; then
        log_success "Stopped web mount (PID: $PID)"
    else
        log_warning "Web mount process not found (PID: $PID)"
    fi
    rm -f /tmp/minikube-mount-web.pid
fi

# Stop API mount
if [ -f /tmp/minikube-mount-api.pid ]; then
    PID=$(cat /tmp/minikube-mount-api.pid)
    if kill "$PID" 2>/dev/null; then
        log_success "Stopped API mount (PID: $PID)"
    else
        log_warning "API mount process not found (PID: $PID)"
    fi
    rm -f /tmp/minikube-mount-api.pid
fi

# Stop app mount
if [ -f /tmp/minikube-mount-app.pid ]; then
    PID=$(cat /tmp/minikube-mount-app.pid)
    if kill "$PID" 2>/dev/null; then
        log_success "Stopped app mount (PID: $PID)"
    else
        log_warning "App mount process not found (PID: $PID)"
    fi
    rm -f /tmp/minikube-mount-app.pid
fi

log_success "All development mounts stopped"

