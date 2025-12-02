#!/bin/bash
# Direct patch script to add development volume mounts to fks-web deployment
# This patches the existing deployment without requiring Helm

set -e

NAMESPACE="fks-trading"
DEPLOYMENT="fks-web"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Adding development volume mounts to $DEPLOYMENT deployment..."

# Create patch file
PATCH_FILE=$(mktemp)
cat > "$PATCH_FILE" <<'EOF'
spec:
  template:
    spec:
      containers:
      - name: web
        volumeMounts:
        - name: dev-web-src
          mountPath: /app/src
        - name: dev-web-templates
          mountPath: /app/src/templates
      volumes:
      - name: dev-web-src
        hostPath:
          path: /mnt/fks-dev/web/src
          type: DirectoryOrCreate
      - name: dev-web-templates
        hostPath:
          path: /mnt/fks-dev/web/src/templates
          type: DirectoryOrCreate
EOF

# Apply patch
if kubectl patch deployment "$DEPLOYMENT" -n "$NAMESPACE" --patch-file "$PATCH_FILE"; then
    log_success "Successfully patched $DEPLOYMENT deployment"
    log_info "Waiting for rollout to complete..."
    kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout=120s
    log_success "Deployment updated with development mounts!"
    log_info ""
    log_info "Note: Make sure to run ./setup-dev-mounts.sh first to mount your code into Minikube"
else
    log_error "Failed to patch deployment"
    rm -f "$PATCH_FILE"
    exit 1
fi

rm -f "$PATCH_FILE"

